function result = deleteSlice(obj, sliceNumber, orient, options)
% function result = deleteSlice(obj, sliceNumber, orient, options)
% Delete specified slice from the dataset.
%
% Parameters:
% sliceNumber: the number of the slice to delete
% orient: [@em optional], can be @em NaN (current orientation)
% @li when @b 0 (@b default) remove slice from the current orientation (obj.orientation)
% @li when @b 1 remove slice from the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 remove slice from the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 remove slice from the yx configuration: [y,x,c,z,t]
% @li when @b 5 remove slice from the t configuration
% options: an optional structure with additional paramters
%   .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
% Return values:
% result: result of the function, @b 0 fail, @b 1 success

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.deleteSlice(3); // call from mibController; delete the 3rd slice from the dataset @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.deleteSlice(10, 5); // call from mibController; delete the 10th time frame from the dataset @endcode

% Copyright (C) 02.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 17.05.2019, added extra options

if nargin < 4; options = struct; end
if nargin < 3; orient = obj.orientation; end
if isnan(orient); orient = obj.orientation; end
if orient==0; orient = obj.orientation; end

if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

result = 0;
maxSliceNumber = size(obj.img{1}, orient);
if sliceNumber > maxSliceNumber
    msgbox(sprintf('The maximal slice number is %d!', maxSliceNumber), 'Wrong slice number', 'error', 'modal');
    return;
end

if options.showWaitbar; wb = waitbar(0, sprintf('Deleting slice number(s) %s\nPlease wait...', num2str(sliceNumber)), 'Name', 'Deleting the slice...'); end
maxT = size(obj.img{1},5);
maxZ = size(obj.img{1},4);
maxH = size(obj.img{1},1);
maxW = size(obj.img{1},2);

% delete slice from obj.img
if orient == 4     % xy orientation
    indexList = setdiff(1:maxZ, sliceNumber);
    obj.img{1}=obj.img{1}(:, :, :, indexList, :);
elseif orient == 1     % zx orientation
    indexList = setdiff(1:maxH, sliceNumber);
    obj.img{1}=obj.img{1}(indexList, :, :, :, :);
elseif orient == 2     % zy orientation
    indexList = setdiff(1:maxW, sliceNumber);
    obj.img{1}=obj.img{1}(:, indexList, :, :, :);
elseif orient == 5     % t orientation
    indexList = setdiff(1:maxT, sliceNumber);
    obj.img{1}=obj.img{1}(:, :, :, :, indexList);
end
if options.showWaitbar; waitbar(0.3, wb); end

% delete slice from selection
if ~isnan(obj.selection{1}(1))
    if orient == 4     % xy orientation
        obj.selection{1} = obj.selection{1}(:, :, indexList, :);
    elseif orient == 1     % zx orientation
        obj.selection{1} = obj.selection{1}(indexList, :, :, :);
    elseif orient == 2     % zy orientation
        obj.selection{1} = obj.selection{1}(:, indexList, :, :);
    elseif orient == 5     % t orientation
        obj.selection{1}=obj.selection{1}(:, :, :, indexList);
    end
end
if options.showWaitbar; waitbar(0.5, wb); end

% delete slice from model
if ~isnan(obj.model{1}(1))
    if orient == 4     % xy orientation
        obj.model{1} = obj.model{1}(:,:,indexList,:);
    elseif orient == 1     % zx orientation
        obj.model{1} = obj.model{1}(indexList,:,:,:);
    elseif orient == 2     % zy orientation
        obj.model{1} = obj.model{1}(:,indexList,:,:);
    elseif orient == 5     % t orientation
        obj.model{1}=obj.model{1}(:,:,:,indexList);        
    end
end

% shift labels
[labelsList, labelValue, labelPositions, indices] = obj.hLabels.getLabels();   % [labelIndex, z x y t]
if numel(labelsList) > 0 
    for sliceId = numel(sliceNumber):-1:1
        currSlice = sliceNumber(sliceId);
        if orient == 4     % xy orientation
            labelPositions(labelPositions(:,1)>=currSlice,1) = labelPositions(labelPositions(:,1)>=currSlice,1)-1;
        elseif orient == 1     % zx orientation
            labelPositions(labelPositions(:,3)>=currSlice,3) = labelPositions(labelPositions(:,3)>=currSlice,3)-1;
        elseif orient == 2     % zy orientation
            labelPositions(labelPositions(:,2)>=currSlice,2) = labelPositions(labelPositions(:,2)>=currSlice,2)-1;
        elseif orient == 5     % t orientation
            labelPositions(labelPositions(:,4)>=currSlice,4) = labelPositions(labelPositions(:,4)>=currSlice,4)-1;       
        end
    end
    obj.hLabels.replaceLabels(labelsList, labelPositions, labelValue);
end
if options.showWaitbar; waitbar(0.7, wb); end

% delete slice from mask
if ~isnan(obj.maskImg{1}(1))
    if orient == 4     % xy orientation
        obj.maskImg{1} = obj.maskImg{1}(:,:,indexList,:);
    elseif orient == 1     % zx orientation
        obj.maskImg{1} = obj.maskImg{1}(indexList,:,:,:);
    elseif orient == 2     % zy orientation
        obj.maskImg{1} = obj.maskImg{1}(:,indexList,:,:);
    elseif orient == 5     % t orientation
        obj.maskImg{1} = obj.maskImg{1}(:,:,:,indexList); 
    end
end
if options.showWaitbar; waitbar(0.9, wb); end
% update obj.height, obj.width, etc
obj.height = size(obj.img{1}, 1);
obj.width = size(obj.img{1}, 2);
obj.depth = size(obj.img{1}, 4);
obj.time = size(obj.img{1}, 5);
obj.dim_yxczt = [obj.height, obj.width, obj.colors, obj.depth, obj.time];

obj.meta('Height') = size(obj.img{1}, 1);
obj.meta('Width') = size(obj.img{1}, 2);
obj.meta('Depth') = size(obj.img{1}, 4);
obj.meta('Time') = size(obj.img{1}, 5);

% update I.slices
currSlices = obj.slices;

if orient < 5
    % update I.slices
    obj.slices{1} = [1, obj.height];
    obj.slices{2} = [1, obj.width];
    obj.slices{3} = obj.slices{3};
    obj.slices{4} = [1, size(obj.depth,4)];
    obj.slices{5} = [min([obj.slices{5}(1) obj.time]) min([obj.slices{5}(2) obj.time])];
    
    if currSlices{orient}(1) > size(obj.img{1}, orient)
        obj.slices{orient} = [size(obj.img{1}, orient) size(obj.img{1}, orient)];
    else
        obj.slices{orient} = currSlices{orient};
    end
    
    obj.current_yxz(1) = min([obj.current_yxz(1) obj.height]);
    obj.current_yxz(2) = min([obj.current_yxz(2) obj.width]);
    obj.current_yxz(3) = min([obj.current_yxz(3) obj.depth]);
    
    % update bounding box
    obj.updateBoundingBox();
    
    % update SliceName key in the img_info
    if isKey(obj.meta, 'SliceName')
        sliceNames = obj.meta('SliceName');
        if numel(obj.meta('SliceName')) > 1
            sliceNames(sliceNumber) = [];
            obj.meta('SliceName') = sliceNames;
        end
    end
else
    obj.slices{5} = [min([obj.slices{5}(1) obj.time]) min([obj.slices{5}(2) obj.time])];
end
% update the log list
log_text = sprintf('Delete slice: %s, Orient: %d', num2str(sliceNumber), orient);
obj.updateImgInfo(log_text);

if options.showWaitbar 
    waitbar(1, wb);
    delete(wb);
end
result = 1;
end