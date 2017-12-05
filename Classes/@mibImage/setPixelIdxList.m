function result = setPixelIdxList(obj, type, dataset, PixelIdxList, options)
% result = setPixelIdxList(obj, type, dataset, PixelIdxList, options)
% Set dataset
%
% Parameters:
% type: type of the dataset to update, 'image' (not implemented), 'model','mask', 'selection', or 'everything' ('model','mask' and 'selection' for imageData.model_type==''uint6'' only)
% dataset: a vector with values
% PixelIdxList: indices of pixels that have to be updated (calculated for the full dataset in the XY orientation)
% options: [@em optional], a structure with extra parameters @b NOT @b USED
% @li .z -> [@em optional], z coordinate, when missing use the currently shown
% @li .t -> [@em optional], time point, when missing use the currently shown
%
% Return values:
% result: -> @b 1 - success, @b 0 - error

%|
% @b Examples:
% @code
% I = cell2mat(obj.mibModel.getData3D('mask'));      // get current mask 3D
% CC = bwconncomp(I, 26);   // detect objects
% val = zeros([numel(CC.PixelIdxList{1}), 1], 'uint8')+1;  // set the values for the detected object 1
% obj.mibModel.I{obj.mibModel.Id}.setPixelIdxList('selection', val, CC.PixelIdxList{1});    // move to the selection layer
% @endcode

% Copyright (C) 06.09.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
result = 0;
if nargin < 5; options = struct(); end
if nargin < 4; error('prog:input', 'Missing parameters!!!\nShould be at least 3:\nresult = obj.mibModel.I{obj.mibModel.Id}.setPixelIdxList(type, dataset, setPixelIdxList, options)'); end

if obj.modelType > 63  % uint8/int8 type of the model
    if strcmp(type,'image')
        error('not implemented!')
        %obj.img{1}(:,:,col_channel,:,:) = dataset;
    elseif strcmp(type,'model')
        obj.model{1}(PixelIdxList) = dataset;
        obj.modelExist = 1;
    elseif strcmp(type,'mask')
        obj.maskImg{1}(PixelIdxList) = dataset;
        obj.maskExist = 1;
    elseif strcmp(type,'selection')
        obj.selection{1}(PixelIdxList) = dataset;
    end
else        % ************ uint6 model type
    % the following part of the code is broken into two sections because it is faster
    if strcmp(type,'image')
        error('not implemented!')
        %obj.img{1}(:,:,col_channel,:,:) = dataset;
    else    % set all other layers: model, mask, selection
        switch type
            case 'model'
                obj.model{1}(PixelIdxList) = bitand(obj.model{1}(PixelIdxList), 192); % clear current model
                obj.model{1}(PixelIdxList) = bitor(obj.model{1}(PixelIdxList), dataset); % clear current model
            case 'mask'
                obj.model{1}(PixelIdxList) = bitset(obj.model{1}(PixelIdxList), 7, dataset);
                obj.maskExist = 1;
            case 'selection'
                obj.model{1}(PixelIdxList) = bitset(obj.model{1}(PixelIdxList), 8, dataset);
            case 'everything'
                obj.model{1}(PixelIdxList) = dataset;
        end
    end
end

result = 1;
end
