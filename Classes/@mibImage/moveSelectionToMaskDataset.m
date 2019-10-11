function moveSelectionToMaskDataset(obj, action_type, options)
% function moveSelectionToMaskDataset(obj, action_type, options)
% Move the Selection layer to the Mask layer.
%
% This is one of the specific function to move datasets between the layers.
% Allows faster move of complete datasets between the layers 
%
% Parameters:
% action_type: a type of the desired action
% - ''add'' - add selection to mask
% - ''remove'' - remove selection from mask
% - ''replace'' - replace mask with selection
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
% @code obj.mibModel.I{obj.mibModel.Id}.moveSelectionToMaskDataset('add', options);     // add selection to mask  @endcode
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

% % filter the obj_type_from depending on elected_sw and/or maskedAreaSw states
imgTemp = NaN; % a temporal variable to keep modified version of dataset when selected_sw and/or maskedAreaSw are on
if obj.modelType == 63      % uint6 type of the model
    if options.selected_sw && obj.modelExist && options.maskedAreaSw==0
        imgTemp = bitand(uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex), bitand(obj.model{options.level}, 128)/128);   % intersection of material and selection
    elseif options.maskedAreaSw && options.selected_sw == 0  % when only masked area selected
        if strcmp(action_type, 'add'); return; end
        if strcmp(action_type, 'replace')
            imgTemp = bitand(bitand(obj.model{options.level}, 64)/64, bitand(obj.model{options.level}, 128)/128);     % intersection of mask and selection
        end
    elseif options.selected_sw && obj.modelExist && options.maskedAreaSw==1
        if strcmp(action_type, 'add'); return; end
        imgTemp = bitand(uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex), bitand(obj.model{options.level}, 128)/128); % intersection of material and selection
        imgTemp = bitand(imgTemp, bitand(obj.model{options.level}, 64)/64);    % additional intersection with mask
    end
else            % uint8 type of the model
    if options.selected_sw && obj.modelExist && options.maskedAreaSw==0
        %imgTemp = obj.model{options.level};
        %imgTemp(imgTemp ~= options.contSelIndex) = 0;
        imgTemp = obj.getData('model', 4, options.contSelIndex);  % get selected material
        imgTemp = bitand(obj.selection{options.level}, imgTemp);   % generate intersection between the material and selection
    end
    if options.maskedAreaSw && options.selected_sw == 0     % when only masked area selected
        if strcmp(action_type, 'add'); return; end
        if strcmp(action_type, 'replace')
            imgTemp = bitand(obj.selection{options.level}, obj.maskImg{options.level});
        end
    end
    if options.selected_sw && obj.modelExist && options.maskedAreaSw==1
        if strcmp(action_type, 'add'); return; end
        %imgTemp = obj.model{options.level};
        %imgTemp(imgTemp ~= options.contSelIndex) = 0;
        imgTemp = obj.getData('model', 4, options.contSelIndex);  % get selected material
        imgTemp = bitand(bitand(imgTemp, obj.maskImg{options.level}), obj.selection{options.level}); % generate intersection between the material, selection and mask
    end
end

switch action_type
    case 'add'  % add selection to mask
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level} = bitor(obj.model{options.level}, bitand(obj.model{options.level}, 128)/2);     % copy selection to mask
                obj.model{options.level} = bitand(obj.model{options.level}, 127); % clear selection
            else     % add layers for the selected or masked areas only
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*64);
                obj.model{options.level} = bitand(obj.model{options.level}, 127); % clear selection
            end
        else    % uint8 type of the model
            if obj.maskExist == 0   % if mask is not present allocate space for it
                obj.maskImg{options.level} = zeros(size(obj.selection{options.level}),'uint8');
            end
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.maskImg{options.level} = bitor(obj.selection{options.level}, obj.maskImg{options.level});    % copy selection to mask
                obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
            else     % add layers for the selected or masked areas only
                obj.maskImg{options.level} = bitor(obj.maskImg{options.level}, imgTemp);  % copy selection to mask
                obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
            end
        end
    case 'remove'   % subtract selection from mask
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                %obj.model{options.level}(bitand(obj.model{options.level}, 128)==128) = bitand(obj.model{options.level}(bitand(obj.model{options.level}, 128)==128), 63);
                %obj.model{options.level}(obj.model{options.level}>127) = bitand(obj.model{options.level}(obj.model{options.level}>127), 63); %this code is x2 slower, than the code below (1.8 vs 0.8 sec)
                imgTemp = bitget(obj.model{options.level}, 7);
                imgTemp = imgTemp - bitget(obj.model{options.level}, 8); % mask - selection
                obj.model{options.level} = bitand(obj.model{options.level}, 63); % clear selection and mask
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*64); % set mask
            else     % add layers for the selected or masked areas only
                imgTemp = bitand(obj.model{options.level}, 64)/64 - imgTemp;
                obj.model{options.level} = bitand(obj.model{options.level}, 63); % clear selection and mask
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*64);  % set mask
            end
        else
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.maskImg{options.level} = obj.maskImg{options.level} - obj.selection{options.level};
            else     % add layers for the selected or masked areas only
                obj.maskImg{options.level}  = obj.maskImg{options.level} - imgTemp;
            end
            obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
        end
    case 'replace'  % replace selection with mask
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                imgTemp = bitget(obj.model{options.level}, 8);
                obj.model{options.level} = bitand(obj.model{options.level}, 63); % clear selection and mask
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*64);  % set mask
            else     % add layers for the selected or masked areas only
                obj.model{options.level} = bitand(obj.model{options.level}, 63); % clear selection and mask
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*64);  % set mask
            end
        else
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.maskImg{options.level} = obj.selection{options.level};
            else     % add layers for the selected or masked areas only
                obj.maskImg{options.level} = imgTemp;
            end
            obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
        end
end
obj.maskExist = 1;
end