function convertModel(obj, type)
% function convertModel(obj, type)
% Convert model from obj.modelType==63 to obj.modelType==255 and other way around
%
% @note The current type is defined with obj.modelType
%
% Parameters:
% type: [optional] a double with type of a new model: 
% @li 63 - model with 63 materials, the fastest to use, utilize less memory
% @li 255 - model with 255 materials, the slower to use, utilize x2 more memory than 63-material type
% @li 65535 - model with 65535 materials, utilize x2 more memory than 255-material type
% @li 4294967295 - model with 4294967295 materials, utilize x2 more memory than 65535-material type
% @li 2.4 - detect all 2D objects (connectivity 4) in all materials of the current model and generate a new model, where each object has an unique index
% @li 2.8 - detect all 2D objects (connectivity 8) in all materials of the current model and generate a new model, where each object has an unique index
% @li 3.6 - detect all 3D objects (connectivity 6) in all materials of the current model and generate a new model, where each object has an unique index
% @li 3.26 - detect all 3D objects (connectivity 26) in all materials of the current model and generate a new model, where each object has an unique index
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
% 26.03.2022, IB added 2.4, 2.6, 3.8, 3.26 model types

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

if type < 4     % types 2.4, 2.8, 3.6, 3.26
    if obj.modelType > 256
        errordlg('Generation of models with indexed objects is only implemented for models with 63 and 255 materials', 'Wrong input model type');
        return;
    end
end

switch type
    case 2.4
        modelText = 'indexed objects 2D/4';
    case 2.8
        modelText = 'indexed objects 2D/8';
    case 3.6
        modelText = 'indexed objects 3D/6';
    case 3.26
        modelText = 'indexed objects 3D/26';
    otherwise
        modelText = sprintf('%d', type);
end
wb = waitbar(0, sprintf('Converting the model to the "%s" type\n\nPlease wait...', modelText), 'Name', 'Converting the model', 'WindowStyle', 'modal');

if type < 4     % index objects in models with 63 or 255 materials
    % define connectivity parameter
    if type == 2.4
        conn = 4;
    elseif type == 2.8
        conn = 8;
    elseif type == 3.6
        conn = 6;
    else
        conn = 26;
    end
    
    % first convert model to 255
    if obj.modelType == 63
        obj.convertModel(255);
    end
    
    noMaterials = numel(obj.modelMaterialNames);
    getDataOptions.blockModeSwitch = 0;
    % allocate space
    newModel = zeros([obj.height, obj.width, obj.depth, obj.time], 'uint16');
    newModelType = 65535;
    for t=1:obj.time
        getDataOptions.t = t;
        if type < 3     % 2D objects
            for z = 1:obj.depth
                getDataOptions.z = z;
                CC = struct();
                CC.Connectivity = conn;
                CC.ImageSize = [obj.height, obj.width];
                CC.NumObjects = 0;
                CC.PixelIdxList = {};
                for matId = 1:noMaterials
                    img = obj.getData('model', 4, matId, getDataOptions); 
                    CC2 = bwconncomp(img, conn);
                    CC.NumObjects = CC.NumObjects + CC2.NumObjects;
                    CC.PixelIdxList = [CC.PixelIdxList, CC2.PixelIdxList];
                end
                if CC.NumObjects > 65535
                    newModel = uint32(newModel); 
                    newModelType = 4294967295;
                end
                newModel(:, :, z, t) = labelmatrix(CC);
            end
        else            % 3D objects
            CC = struct();
            CC.Connectivity = conn;
            CC.ImageSize = [obj.height, obj.width];
            CC.NumObjects = 0;
            CC.PixelIdxList = {};
            for matId = 1:noMaterials
                img = obj.getData('model', 4, matId, getDataOptions);
                CC2 = bwconncomp(img, conn);
                CC.NumObjects = CC.NumObjects + CC2.NumObjects;
                CC.PixelIdxList = [CC.PixelIdxList, CC2.PixelIdxList];
            end
            if CC.NumObjects > 65535
                newModel = uint32(newModel);
                newModelType = 4294967295;
            end
            dummyModel = zeros([obj.height, obj.width, obj.depth], class(newModel));
            for objId = 1:CC.NumObjects
                dummyModel(CC.PixelIdxList{objId}) = objId;
            end
            newModel(:, :, :, t) = dummyModel;
        end
    end
    obj.model{1} = newModel;
    obj.modelType = newModelType;
elseif type == 63     % convert from 255 to 63
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
if type < 4
    obj.modelMaterialNames = {'1', '2'}';
    obj.modelMaterialColors = rand(65535,3);    % generate vector for colors
    obj.selectedMaterial = 3;
    obj.selectedAddToMaterial = 3;
elseif type < 256
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
    obj.modelType = type;
else
    if obj.modelType < 256 % from 8bit to 65535
        obj.modelMaterialNames = {'1', '2'}';
        obj.modelMaterialColors = rand(65535,3);    % generate vector for colors
    end
    obj.selectedMaterial = 3;
    obj.selectedAddToMaterial = 3;
    obj.modelType = type;
end

waitbar(1, wb);
delete(wb);
drawnow;    % otherwise im_browser crashes after model convertion when leaving the preferences dialog
end