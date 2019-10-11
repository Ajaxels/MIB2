function moveMaskToModelDataset(obj, action_type, options)
% function moveMaskToModelDataset(obj, action_type, options)
% Move the Mask layer to the Model layer
%
% This is one of the specific functions to move datasets between the layers.
% Allows faster move of complete datasets between the layers 
%
% Parameters:
% action_type: a type of the desired action
% - ''add'' - add mask to the selected material (@em Add @em to)
% - ''remove'' - remove mask from the model
% - ''replace'' - replace the selected (@em Add @em to) material with mask
% options: a structure with additional paramters
% @li @b .contSelIndex    - index of the @em Select @em from material
% @li @b .contAddIndex    - index of the @em Add @em to material
% @li @b .selected_sw     - optional override switch [0 / 1] to limit actions to the selected @em Select @em from material only, otherwise
%       obj.fixSelectionToMaterial value is used
% @li @b .level -> [@em optional], index of image level from the image pyramid, default = 1
%
% Return values:

%| 
% @b Examples:
% @code 
% userData = obj.mibView.handles.mibSegmentationTable.UserData;     // call from mibController, get user data structure 
% options.contSelIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex(); // index of the selected material
% options.contAddIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'); // index of the target material
% options.selected_sw = obj.mibView.handles.mibSegmSelectedOnlyCheck.Value;   // when 1- limit selection to the selected material
% @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.moveMaskToModelDataset('add', options);     // call from mibController, add mask to model  @endcode
% @attention @b NOT @b sensitive to the blockModeSwitch
% @attention @b NOT @b sensitive to the shown ROI

% Copyright (C) 07.08.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

% remove fields that are not compatible with this function
if isfield(options, 'x'); options = rmfield(options, 'x'); end
if isfield(options, 'y'); options = rmfield(options, 'y'); end
if isfield(options, 'z'); options = rmfield(options, 'z'); end
if isfield(options, 't'); options = rmfield(options, 't'); end
if ~isfield(options, 'contSelIndex'); options.contSelIndex = obj.getSelectedMaterialIndex(); end
if ~isfield(options, 'contAddIndex'); options.contAddIndex = obj.getSelectedMaterialIndex('AddTo'); end
if ~isfield(options, 'selected_sw'); options.selected_sw = obj.fixSelectionToMaterial; end

if ~isfield(options, 'level'); options.level = 1; end

if obj.modelExist == 0
    errordlg(sprintf('!!! Error !!!\n\nThe model is not yet created!\nPlease make the model first and try again\n(Segmentation panel -> Create)'), 'Missing model');
    return;
end

% % filter the obj_type_from depending on selected_sw 
imgTemp = NaN; % a temporal variable to keep modified version of dataset when selected_sw
if obj.modelType == 63      % uint6 type of the model
    if options.selected_sw && obj.modelExist 
        imgTemp = bitand(uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex), bitand(obj.model{options.level}, 64)/64);   % intersection of material and selection
    end
else            % uint8 type of the model
    if options.selected_sw && obj.modelExist 
        imgTemp = obj.getData('model', 4, options.contSelIndex);  % get selected material
        imgTemp = bitand(obj.maskImg{options.level}, imgTemp);   % generate intersection between the material and mask
    end
end

switch action_type
    case 'add'  % add mask to model
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level}(bitand(obj.model{options.level}, 64) == 64) = bitand(obj.model{options.level}(bitand(obj.model{options.level}, 64) == 64), 192);    % % clear contents of the area where to add, 192 = 11000000
                obj.model{options.level}(bitand(obj.model{options.level}, 64) == 64) = bitor(obj.model{options.level}(bitand(obj.model{options.level}, 64) == 64), options.contAddIndex);    % % add new material, options.contAddIndex - index of a Material to add
            else     % add layers for the selected or masked areas only
                obj.model{options.level}(imgTemp==1) = bitand(obj.model{options.level}(imgTemp==1), 192);    % % clear contents of the area where to add, 192 = 11000000    
                obj.model{options.level}(imgTemp==1) = bitor(obj.model{options.level}(imgTemp==1), options.contAddIndex);    % % add new material, options.contAddIndex - index of a Material to add
            end
        else    % uint8 type of the model
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level}(obj.maskImg{options.level}==1) = options.contAddIndex;
            else
                obj.model{options.level}(imgTemp==1) = options.contAddIndex;
            end
        end
    case 'remove'   % subtract selection from mask
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level}(bitand(obj.model{options.level}, 64) == 64) = ...
                    bitand(obj.model{options.level}(bitand(obj.model{options.level}, 64) == 64), 192);    % 192 = 11000000
            else     % add layers for the selected or masked areas only
                obj.model{options.level}(imgTemp==1) = ...
                    bitand(obj.model{options.level}(imgTemp==1), 192);    % 192 = 11000000
            end
        else    % uint8 type of the model
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level}(obj.maskImg{options.level}==1) = 0;
            else
                obj.model{options.level}(imgTemp==1) = 0;
            end
            
        end
    case 'replace'  % replace selection with mask
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                M = bitshift(bitshift(obj.model{options.level}, -6), 6);     % store mask and selection
                obj.model{options.level}(bitand(obj.model{options.level}, options.contAddIndex)==options.contAddIndex) = ...
                    bitand(obj.model{options.level}(bitand(obj.model{options.level}, options.contAddIndex)==options.contAddIndex), 192);  % 192 = 11000000 clear destination material
                obj.model{options.level}(bitand(M, 64) == 64) = options.contAddIndex;   % set new destination material
                obj.model{options.level} = bitor(obj.model{options.level}, M);  % restore mask and selection
            else     % add layers for the selected or masked areas only
                M = bitshift(bitshift(obj.model{options.level}, -6), 6);     % store mask and selection
                obj.model{options.level}(bitand(obj.model{options.level}, options.contAddIndex)==options.contAddIndex) = ...
                    bitand(obj.model{options.level}(bitand(obj.model{options.level}, options.contAddIndex)==options.contAddIndex), 192);  % 192 = 11000000 clear destination material
                obj.model{options.level}(imgTemp==1) = options.contAddIndex;   % set new destination material
                obj.model{options.level} = bitor(obj.model{options.level}, M);  % restore mask and selection
            end
        else
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level}(obj.model{options.level}==options.contAddIndex) = 0;     % clear destination material
                obj.model{options.level}(obj.maskImg{options.level}==1) = options.contAddIndex;     % populate destination material
            else
                obj.model{options.level}(imgTemp==1) = 0;     % clear destination material
                obj.model{options.level}(imgTemp==1) = options.contAddIndex;     % populate destination material
            end
            
        end
end
end