function moveModelToMaskDataset(obj, action_type, options)
% function moveModelToMaskDataset(obj, action_type, options)
% Move the selected Material to the Mask layer
%
% This is one of the specific functions to move datasets between the layers.
% Allows faster move of complete datasets between the layers 
%
% Parameters:
% action_type: a type of the desired action
% - ''add'' - add the selected material (@em Select @em from) to mask
% - ''remove'' - remove the selected material (@em Select @em from) from mask
% - ''replace'' - replace mask with the selected (@em Select @em from) material
% options: a structure with additional paramters
% @li @b .contSelIndex    - index of the @em Select @em from material
% @li @b .contAddIndex    - index of the @em Add @em to material
%
% Return values:

%| 
% @b Examples:
% @code 
% userData = obj.mibView.handles.mibSegmentationTable.UserData;     // call from mibController, get user data structure 
% options.contSelIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex(); // index of the selected material
% options.contAddIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'); // index of the target material
% @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.moveModelToMaskDataset('add', options);     // call from mibController, add material to mask @endcode
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

if ~isfield(options, 'level'); options.level = 1; end

switch action_type
    case 'add'  % add material to selection
        if obj.modelType == 63
            imgTemp = uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex)*64;   % get material and set it as mask
            obj.model{options.level} = bitor(obj.model{options.level}, imgTemp);
        else    % uint8 type of the model
            obj.maskImg{options.level}(obj.model{options.level} == options.contSelIndex) = 1;
        end
    case 'remove'   % subtract material from selection
        if obj.modelType == 63
            imgTemp = uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex)*64;   % get material and set it as selection
            obj.model{options.level} = obj.model{options.level} - bitand(obj.model{options.level}, imgTemp);
        else    % uint8 type of the model
            obj.maskImg{options.level} = obj.maskImg{options.level} - uint8(obj.model{options.level}==options.contSelIndex);
        end
    case 'replace'  % replace selection with material
        if obj.modelType == 63
            obj.model{options.level} = bitset(obj.model{options.level}, 7, 0);    % clear mask
            imgTemp = uint8(bitand(obj.model{options.level}, 63)==options.contSelIndex)*64;   % get material and set it as selection
            obj.model{options.level} = bitor(obj.model{options.level}, imgTemp);
        else
            obj.maskImg{options.level} = zeros(size(obj.selection{options.level}), class(obj.selection{options.level}));     % clear selection
            obj.maskImg{options.level} = uint8(obj.model{options.level}==options.contSelIndex);
        end
end
end