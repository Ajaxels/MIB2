function moveMaskToSelectionDataset(obj, action_type, options)
% function moveMaskToSelectionDataset(obj, action_type, options)
% Move the Mask layer to the Selection layer.
%
% This is one of the specific functions to move datasets between the layers.
% Allows faster move of complete datasets between the layers 
%
% Parameters:
% action_type: a type of the desired action
% - ''add'' - add mask to selection
% - ''remove'' - remove mask from selection
% - ''replace'' - replace selection with mask
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
% @code obj.mibModel.I{obj.mibModel.Id}.moveMaskToSelectionDataset('add', options);     // call from mibController, add mask to selection  @endcode
% @attention @b NOT @b sensitive to the blockModeSwitch
% @attention @b NOT @b sensitive to the shown ROI

% Copyright (C) 18.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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

% swap options.contSelIndex and options.contAddIndex when selecting
% mask with fix selection to material switch
if options.selected_sw && options.contSelIndex == -1
    options.contSelIndex = options.contAddIndex;
end

% % filter the obj_type_from depending on selected_sw 
imgTemp = NaN; % a temporal variable to keep modified version of dataset when selected_sw
if obj.modelType == 63      % uint6 type of the model
    if options.selected_sw && obj.modelExist 
        id = bitset(options.contSelIndex, 7, 1);    % generate id with the 7bit = 1 (mask)
        imgTemp = bitset(obj.model{options.level}, 8, 0);  % generate temp variable as model, but without the selection; faster than: imgTemp = bitand(obj.model{options.level}, 127);
        imgTemp(imgTemp == id) = 128;   % set selection to the intersection of material and mask
    end
else            % uint8 type of the model
    if options.selected_sw && obj.modelExist 
        imgTemp = obj.getData('model', 4, options.contSelIndex);  % get selected material
        imgTemp = bitand(obj.maskImg{options.level}, imgTemp);   % generate intersection between the material and mask
    end
end

switch action_type
    case 'add'  % add mask to selection
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level} = bitor(obj.model{options.level}, bitand(obj.model{options.level}, 64)*2);     % copy selection to mask
            else     % add layers for the selected or masked areas only
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp);
            end
        else    % uint8 type of the model
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.selection{options.level} = bitor(obj.selection{options.level}, obj.maskImg{options.level});    % copy selection to mask
            else     % add layers for the selected or masked areas only
                obj.selection{options.level} = bitor(obj.selection{options.level}, imgTemp);  % copy selection to mask
            end
        end
    case 'remove'   % subtract selection from mask
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                imgTemp = bitget(obj.model{options.level}, 8);     % get selection
                imgTemp = imgTemp - bitget(obj.model{options.level}, 7); % selection - mask
                obj.model{options.level} = bitand(obj.model{options.level}, 127); % clear selection 
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*128); % set selection
            else     % add layers for the selected or masked areas only
                imgTemp = bitand(obj.model{options.level}, 128) - imgTemp;
                obj.model{options.level} = bitand(obj.model{options.level}, 127); % clear selection 
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*128);  % set selection
            end
        else
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.selection{options.level} = obj.selection{options.level} - obj.maskImg{options.level};
            else     % add layers for the selected or masked areas only
                obj.selection{options.level}  = obj.selection{options.level} - imgTemp;
            end
        end
    case 'replace'  % replace selection with mask
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                imgTemp = bitget(obj.model{options.level}, 7);     % get mask
                obj.model{options.level} = bitand(obj.model{options.level}, 127); % clear selection 
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*128);  % set selection
            else     % add layers for the selected or masked areas only
                obj.model{options.level} = bitand(obj.model{options.level}, 127); % clear selection 
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp);  % set selection
            end
        else
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.selection{options.level} = obj.maskImg{options.level};
            else     % add layers for the selected or masked areas only
                obj.selection{options.level} = imgTemp;
            end
        end
end
end