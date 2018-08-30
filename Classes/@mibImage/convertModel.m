function convertModel(obj, type)
% function convertModel(obj, type)
% Convert model from obj.modelType==63 to obj.modelType==255 and other way around
%
% @note The current type is defined with obj.modelType
%
% Parameters:
% type: [optional] a double with type of a new model: 63 (63 materials
% max), 255 (255 materials max), 65535 (65535 materials max), 4294967295 (4294967295 materials max)
%
% Return values:
%

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.convertModel(255);  // convert model to the obj.modelType==255 type @endcode

% Copyright (C) 12.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 04.12.2017, IB, added 4294967295 materials

% check for the virtual stacking mode and close the controller
if obj.Virtual.virtual == 1
    toolname = 'models are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

if nargin < 2
    if obj.modelType == 255
        type = 63;
    else
        type = 255;
    end
end
if type == obj.modelType; return; end

if obj.modelExist == 0
    errordlg('Model is not present, create an empty model first', 'Missing a model');
    return;
end

wb = waitbar(0, sprintf('Converting the model to the "%d" type\n\nPlease wait...', type), 'Name', 'Converting the model', 'WindowStyle', 'modal');
if type == 63     % convert from 255 to 63
    if ~isnan(obj.selection{1}(1))
        if isnan(obj.model{1}(1)); obj.model{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8'); end; % create new model
        if obj.modelType > 255
            obj.model{1} = uint8(obj.model{1});
        end
        obj.model{1}(obj.selection{1}==1) = bitset(obj.model{1}(obj.selection{1}==1), 8, 1);    % generate selection layer
        waitbar(0.4, wb);
        if obj.maskExist == 1
            obj.model{1}(obj.maskImg{1}==1) = bitset(obj.model{1}(obj.maskImg{1}==1), 7, 1);    % generate mask layer
        end
        waitbar(0.8, wb);
        obj.maskExist = 1;
        obj.maskImg{1} = NaN;
        obj.selection{1} = NaN;
    end
    waitbar(1, wb);
else                        % convert from 63 to 255
    waitbar(0.3, wb);
    if ~isnan(obj.model{1}(1))     % convert when the layers are present
        if obj.modelType == 63
            obj.selection{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8');
            obj.maskImg{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8');
            obj.selection{1} = bitand(obj.model{1}, 128)/128;     % generate selection
            obj.maskImg{1} = bitand(obj.model{1}, 64)/64;     % generate mask
            waitbar(0.6, wb);
            obj.model{1} = bitand(obj.model{1}, 63);  % clear mask and selection from the model
        end
        
        switch type
            case 255
                obj.model{1} = uint8(obj.model{1});
            case 65535
                obj.model{1} = uint16(obj.model{1});
            case 4294967295
                obj.model{1} = uint32(obj.model{1});
        end
        obj.maskExist = 1;
    end
end
waitbar(0.9, wb, sprintf('Updating materials\nPlease wait...'));
if type < 256
    if obj.modelType > 255  % from 65535 to 8bit
        if type == 63
            maxMaterialIndex = max(obj.model{1}(obj.model{1}<64));
        else
            maxMaterialIndex = max(obj.model{1}(:));
        end
        if maxMaterialIndex > 0
            obj.modelMaterialNames = cell(maxMaterialIndex, 1);
            for i=1:maxMaterialIndex
                obj.modelMaterialNames(i,1) = cellstr(num2str(i));
            end
        end
    end
    obj.selectedMaterial = 2;
    obj.selectedAddToMaterial = 2;
else
    if obj.modelType < 256 % from 8bit to 65535
        obj.modelMaterialNames = {'1', '2'}';
        obj.modelMaterialColors = rand(65535,3);    % generate vector for colors
    end
    obj.selectedMaterial = 3;
    obj.selectedAddToMaterial = 3;
end

obj.modelType = type;
waitbar(1, wb);
delete(wb);
drawnow;    % otherwise im_browser crashes after model convertion when leaving the preferences dialog
end