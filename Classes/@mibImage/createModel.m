function createModel(obj, modelType, modelMaterialNames)
% function createModel(obj, model_type, modelMaterialNames)
% Create an empty model: allocate memory for a new model
%
% This function reinitialize mibImage.model variable (@em NaN when no model present) with an empty matrix
% [mibImage.height, mibImage.width, mibImage.depth, mibImage.time] of the defined type class
%
% Parameters:
% modelType: [@em optional] a number that defines type of the model (when @em NaN - use default model type)
% - @b 63 - a segmentation model with up to 63 materials; the 'Model', 'Mask' and 'Selection' layers stored in the same matrix, to decrease memory consumption;
% - @b 255 - a segmentation model with up to 255 materials; the 'Model', 'Mask' and 'Selection' layers stored in separate matrices;
% - @b 65535 - a segmentation model with up to 65535 materials; the 'Model', 'Mask' and 'Selection' layers stored in separate matrices;
% - @b 4294967295 - a segmentation model with up to 4294967295 materials; the 'Model', 'Mask' and 'Selection' layers stored in separate matrices;
% - @b 127 - a model layer that has intensities from -128 to 127.
% - @b 32767 - a model layer that has intensities from -32768 to 32767.
% modelMaterialNames: [@em optional] a cell array with names of materials, this parameter is not used for modelType > 255

%
% Return values:
%

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.createModel(63);  // call from mibController; allocate space for a new Model layer, type 63 @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.createModel(NaN, {'Material1','Material2'});  // call from mibController; allocate space for a new Model of the default type and assign 2 materials @endcode
% @code obj.mibModel.getImageMethod('createModel', NaN, 63); // call from mibController via a wrapper function getImageMethod @endcode

% Copyright (C) 28.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 3; modelMaterialNames = []; end
if nargin < 2; modelType = NaN; end

if isnan(modelType); modelType = obj.modelType; end

if modelType == 63
    if obj.modelType==63
        obj.model{1} = bitand(obj.model{1}, 192);
    else
        if ~isnan(obj.selection{1}(1))
            obj.model{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8');
            obj.model{1}(obj.selection{1}==1) = bitset(obj.model{1}(obj.selection{1}==1), 8, 1);    % generate selection layer
            if obj.maskExist == 1
                obj.model{1}(obj.maskImg{1}==1) = bitset(obj.model{1}(obj.maskImg{1}==1), 7, 1);    % generate mask layer
            end
            obj.maskImg{1} = NaN;
            obj.selection{1} = NaN;
        end
    end
else
    if obj.modelType==63
        if ~isnan(obj.model{1}(1))     % convert when the layers are present
            obj.selection{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8');
            obj.selection{1} = bitand(obj.model{1}, 128)/128;     % generate selection
            if obj.maskExist
                %obj.maskImg{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8');
                obj.maskImg{1} = bitand(obj.model{1}, 64)/64;     % generate mask
            end
        end
    end
    if modelType == 255
        obj.model{1} = zeros([obj.height, obj.width, obj.depth, obj.time], 'uint8');
    elseif modelType == 127
        obj.model{1} = zeros([obj.height, obj.width, obj.depth, obj.time],'int8');
    elseif modelType == 32767
        obj.model{1} = zeros([obj.height, obj.width, obj.depth, obj.time],'int16');
    elseif modelType == 65535
        obj.model{1} = zeros([obj.height, obj.width, obj.depth, obj.time], 'uint16');
        obj.modelMaterialColors = rand(65535,3);    % generate vector for colors
    elseif modelType == 4294967295
        obj.model{1} = zeros([obj.height, obj.width, obj.depth, obj.time], 'uint32');
        obj.modelMaterialColors = rand(65535,3);    % generate vector for colors
    end
end

obj.modelExist = 1;
obj.modelVariable = 'mibModel';
%[pathstr, name] = fileparts(obj.meta('Filename'));
obj.modelFilename = [];
obj.modelType = modelType;
if modelType < 256
    if ~isempty(modelMaterialNames)
        if size(modelMaterialNames,1) < size(modelMaterialNames,2)
            obj.modelMaterialNames = modelMaterialNames';
        else
            obj.modelMaterialNames = modelMaterialNames;
        end
    else
        obj.modelMaterialNames = {};
    end
    obj.selectedMaterial = 2;
    obj.selectedAddToMaterial = 2;
else
    obj.modelMaterialNames = {'1', '2'}';
    obj.selectedMaterial = 3;
    obj.selectedAddToMaterial = 3;
end

obj.hLabels.clearContents();    % clear labels
end