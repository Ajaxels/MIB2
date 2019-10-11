function moveSelectionToModelDataset(obj, action_type, options)
% function moveSelectionToModelDataset(obj, action_type, options)
% Move the Selection layer to the Model layer
%
% This is one of the specific functions to move datasets between the layers.
% Allows faster move of complete datasets between the layers 
%
% Parameters:
% action_type: a type of the desired action
% - ''add'' - add selection to the selected material (@em Add @em to)
% - ''remove'' - remove selection from the model
% - ''replace'' - replace the selected (@em Add @em to) material with selection
% options: a structure with additional paramters
% @li @b .contSelIndex    - index of the @em Select @em from material
% @li @b .contAddIndex    - index of the @em Add @em to material
% @li @b .selected_sw     - optional override switch [0 / 1] to limit actions to the selected @em Select @em from material only, otherwise
%       obj.fixSelectionToMaterial value is used
% @li @b .maskedAreaSw    - optional override switch [0 / 1] to limit actions to the masked areas, otherwise
%       obj.fixSelectionToMask value is used
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
% options.maskedAreaSw = obj.mibView.handles.mibMaskedAreaCheck.Value;
% @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.moveSelectionToModelDataset('add', options);     // call from mibController, add selection to model  @endcode
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
if ~isfield(options, 'maskedAreaSw'); options.maskedAreaSw = obj.fixSelectionToMask; end

if ~isfield(options, 'level'); options.level = 1; end

% % filter the obj_type_from depending on selected_sw and/or maskedAreaSw states
imgTemp = NaN; % a temporal variable to keep modified version of dataset when selected_sw and/or maskedAreaSw are on
if obj.modelType == 63      % uint6 type of the model
    if options.selected_sw && obj.modelExist && options.maskedAreaSw==0
        imgTemp = bitand(uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex), bitand(obj.model{options.level}, 128)/128);   % intersection of material and selection
    elseif options.maskedAreaSw && options.selected_sw == 0  % when only masked area selected
        imgTemp = bitand(bitand(obj.model{options.level}, 128)/128, bitand(obj.model{options.level}, 64)/64);     % intersection of selection and mask
    elseif options.selected_sw && obj.modelExist && options.maskedAreaSw==1
        imgTemp = bitand(uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex), bitand(obj.model{options.level}, 128)/128);  % intersection of material and selection
        imgTemp = bitand(imgTemp, bitand(obj.model{options.level}, 64)/64);    % additional intersection with mask
    end
else            % uint8 type of the model
    if options.selected_sw && obj.modelExist && options.maskedAreaSw==0
        obj.selection{options.level}(obj.model{options.level} ~= options.contSelIndex) = 0;   % decrease selection
    elseif options.maskedAreaSw && options.selected_sw == 0  % when only masked area selected
        obj.selection{options.level} = bitand(obj.selection{options.level}, obj.maskImg{options.level});   % decrease selection
    elseif options.selected_sw && obj.modelExist && options.maskedAreaSw==1
        obj.selection{options.level} = bitand(obj.selection{options.level}, obj.maskImg{options.level});   % decrease selection
        obj.selection{options.level}(obj.model{options.level} ~= options.contSelIndex) = 0;   % decrease selection
    end
end

switch action_type
    case 'add'  % add selection to model
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                M = bitand(obj.model{options.level}, 64);  % store existing mask
                obj.model{options.level}(bitand(obj.model{options.level}, 128) > 0) = options.contAddIndex;   % populating material
                obj.model{options.level} = bitor(obj.model{options.level}, M);    % populating the mask
                obj.model{options.level} = bitset(obj.model{options.level}, 8, 0); % clear selection
            else     % add layers for the selected or masked areas only
                M = bitand(obj.model{options.level}, 64);  % store existing mask
                obj.model{options.level} = bitset(obj.model{options.level}, 8, 0); % clear selection
                obj.model{options.level}(imgTemp==1) = options.contAddIndex;   % populating material
                obj.model{options.level} = bitor(obj.model{options.level}, M);    % populating the mask
            end
        else    % uint8 type of the model
            obj.model{options.level}(obj.selection{options.level}==1) = options.contAddIndex;
            obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
        end
    case 'remove'   % subtract selection from model
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                M = bitand(obj.model{options.level}, 64);  % store existing mask
                obj.model{options.level}(bitand(obj.model{options.level}, 128) > 0) = 0;   % removing material
                obj.model{options.level} = bitor(obj.model{options.level}, M);    % populating the mask
                obj.model{options.level} = bitset(obj.model{options.level}, 8, 0); % clear selection
            else     % add layers for the selected or masked areas only
                M = bitand(obj.model{options.level}, 64);  % store existing mask
                obj.model{options.level} = bitset(obj.model{options.level}, 8, 0); % clear selection
                obj.model{options.level}(imgTemp==1) = 0;   % populating material
                obj.model{options.level} = bitor(obj.model{options.level}, M);    % populating the mask
            end
        else    % uint8 type of the model
            obj.model{options.level}(obj.selection{options.level}==1) = 0;
            obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
        end
    case 'replace'  % replace model with selection
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                M = bitand(obj.model{options.level}, 64);  % store existing mask
                imgTemp = bitset(obj.model{options.level}, 7, 0);  % clear mask
                imgTemp = bitset(imgTemp, 8, 0);    % clear selection
                imgTemp(imgTemp==options.contAddIndex) = 0;     % clear destination material
                imgTemp(bitand(obj.model{options.level}, 128) == 128) = options.contAddIndex;  % populate destination material
                obj.model{options.level} = bitor(imgTemp, M);  % populate mask
            else     % add layers for the selected or masked areas only
                M = bitand(obj.model{options.level}, 64);  % store existing mask
                obj.model{options.level} = bitand(obj.model{options.level}, 63); % clear selection and mask
                obj.model{options.level}(obj.model{options.level}==options.contAddIndex) = 0;     % clear destination material
                obj.model{options.level}(imgTemp==1) = options.contAddIndex;  % populate destination material
                obj.model{options.level} = bitor(obj.model{options.level}, M);    % populating the mask
            end
        else
            obj.model{options.level}(obj.model{options.level}==options.contAddIndex) = 0;     % clear destination material
            obj.model{options.level}(obj.selection{options.level}==1) = options.contAddIndex;     % populate destination material
            obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
        end
end
end