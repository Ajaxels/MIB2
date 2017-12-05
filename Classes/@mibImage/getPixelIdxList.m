function dataset = getPixelIdxList(obj, type, PixelIdxList, options)
% dataset = getPixelIdxList(obj, type, PixelIdxList, options)
% Get dataset from the list of pixel indices
%
% Parameters:
% type: type of the dataset to update, 'image' (not implemented), 'model', 'mask', 'selection', or 'everything' ('model', 'mask' and 'selection' for imageData.model_type==''uint6'' only)
% PixelIdxList: indices of pixels that have to be updated (calculated for the full dataset in the XY orientation)
% options: [@em optional], a structure with extra parameters @b NOT @b USED
% @li .z -> [@em optional], z coordinate, when missing use the currently shown
% @li .t -> [@em optional], time point, when missing use the currently shown
%
% Return values:
% dataset: a vector with values

%|
% @b Examples:
% @code
% I = cell2mat(obj.mibModel.getData3D('mask'));      // get current mask 3D
% CC = bwconncomp(I, 26);   // detect objects
% list = obj.mibModel.I{obj.mibModel.Id}.setPixelIdxList('selection', CC.PixelIdxList{1});    // get list of values for the Selection layer inside the mask layer
% @endcode

% Copyright (C) 27.11.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
dataset = [];
if nargin < 4; options = struct(); end
if nargin < 3; error('prog:input', 'Missing parameters!!!\nShould be at least 3:\ndataset = obj.mibModel.I{obj.mibModel.Id}.setPixelIdxList(type, setPixelIdxList, options)'); end

if obj.modelType > 63  % uint8/int8 type of the model
    if strcmp(type,'image')
        error('not implemented!')
        %obj.img{1}(:,:,col_channel,:,:) = dataset;
    elseif strcmp(type,'model')
        if obj.modelExist == 1
            dataset = obj.model{1}(PixelIdxList);
        end
    elseif strcmp(type,'mask')
        if obj.maskExist == 1
            dataset = obj.maskImg{1}(PixelIdxList);
        end
    elseif strcmp(type,'selection')
        dataset = obj.selection{1}(PixelIdxList);
    end
else        % ************ uint6 model type
    % the following part of the code is broken into two sections because it is faster
    if strcmp(type,'image')
        error('not implemented!')
        %obj.img{1}(:,:,col_channel,:,:) = dataset;
    else    % set all other layers: model, mask, selection
        switch type
            case 'model'
                if obj.modelExist == 1
                    dataset = bitand(obj.model{1}(PixelIdxList), 63);
                end
            case 'mask'
                if obj.maskExist == 1
                    dataset = bitget(obj.model{1}(PixelIdxList), 7);
                end
            case 'selection'
                dataset = bitget(obj.model{1}(PixelIdxList), 8);
            case 'everything'
                dataset = obj.model{1}(PixelIdxList);
        end
    end
end
end
