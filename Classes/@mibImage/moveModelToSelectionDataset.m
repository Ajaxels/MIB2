function moveModelToSelectionDataset(obj, action_type, options)
% function moveModelToSelectionDataset(obj, action_type, options)
% Move the selected Material to the Selection layer
%
% This is one of the specific functions to move datasets between the layers.
% Allows faster move of complete datasets between the layers than using of
% ib_getDataset.m / ib_setDataset.m functions.
%
% Parameters:
% action_type: a type of the desired action
% - ''add'' - add the selected material (@em Select @em from) to selection
% - ''remove'' - remove the selected material (@em Select @em from) from selection
% - ''replace'' - replace selection with the selected (@em Select @em from) material
% options: a structure with additional paramters
% @li @b .contSelIndex    - index of the @em Select @em from material
% @li @b .contAddIndex    - index of the @em Add @em to material
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
% options.maskedAreaSw = obj.mibView.handles.mibMaskedAreaCheck.Value;
% @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.moveModelToSelectionDataset('add', options);     // call from mibController; add material to selection @endcode
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
if ~isfield(options, 'maskedAreaSw'); options.maskedAreaSw = obj.fixSelectionToMask; end

if ~isfield(options, 'level'); options.level = 1; end

% % filter the obj_type_from depending on elected_sw and/or maskedAreaSw states
imgTemp = NaN; % a temporal variable to keep modified version of dataset when maskedAreaSw are on
if obj.modelType == 63      % uint6 type of the model
    if options.maskedAreaSw==1
        imgTemp = bitand(uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex), bitand(obj.model{options.level}, 64)/64);  % intersection of material and selection
    end
else            % uint8 type of the model
    if options.maskedAreaSw==1
        imgTemp = bitand(obj.maskImg{options.level}, uint8(obj.model{options.level}==options.contSelIndex));
    end
end

switch action_type
    case 'add'  % add material to selection
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                imgTemp = uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex)*128;   % get material and set it as selection
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp);  
            else     % add layers for the selected or masked areas only
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*128);
            end
        else    % uint8 type of the model
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.selection{options.level}(obj.model{options.level} == options.contSelIndex) = 1;
            else
                obj.selection{options.level} = bitor(obj.selection{options.level}, imgTemp);
            end
        end
    case 'remove'   % subtract material from selection
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                imgTemp = uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex)*128;   % get material and set it as selection
                obj.model{options.level} = obj.model{options.level} - bitand(obj.model{options.level}, imgTemp); 
            else     % add layers for the selected or masked areas only
                obj.model{options.level} = obj.model{options.level} - bitand(obj.model{options.level}, imgTemp*128); 
            end
        else    % uint8 type of the model
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.selection{options.level} = obj.selection{options.level} - uint8(obj.model{options.level}==options.contSelIndex);
            else
                obj.selection{options.level} = obj.selection{options.level} - imgTemp;
            end
        end
    case 'replace'  % replace selection with material
        if obj.modelType == 63
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.model{options.level} = bitset(obj.model{options.level}, 8, 0);    % clear selection
                imgTemp = uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex)*128;   % get material and set it as selection
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp);
            else     % add layers for the selected or masked areas only
                obj.model{options.level} = bitset(obj.model{options.level}, 8, 0);    % clear selection
                obj.model{options.level} = bitor(obj.model{options.level}, imgTemp*128);
            end
        else
            obj.selection{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
            if isnan(imgTemp(1))    % add layers for the whole dataset
                obj.selection{options.level} = uint8(obj.model{options.level}==options.contSelIndex);
            else
                obj.selection{options.level} = imgTemp;
            end
            
        end
end
end