function result = deleteSlice(obj, sliceNumber, orient)
% function result = deleteSlice(obj, sliceNumber, orient)
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
%
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
% 

if nargin < 3; orient = obj.orientation; end;
if isnan(orient); orient = obj.orientation; end;
if orient==0; orient = obj.orientation; end;

result = 0;
maxSliceNumber = size(obj.img{1}, orient);
if sliceNumber > maxSliceNumber
    msgbox(sprintf('The maximal slice number is %d!', maxSliceNumber), 'Wrong slice number', 'error', 'modal');
    return;
end

h = waitbar(0, sprintf('Deleting slice number(s) %s\nPlease wait...', num2str(sliceNumber)), 'Name', 'Deleting the slice...');
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
waitbar(0.3, h);

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
waitbar(0.5, h);

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
waitbar(0.7, h);

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
waitbar(0.9, h);
% update obj.height, obj.width, etc
obj.height = size(obj.img{1}, 1);
obj.width = size(obj.img{1}, 2);
obj.depth = size(obj.img{1}, 4);
obj.time = size(obj.img{1}, 5);
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

waitbar(1, h);
delete(h);
result = 1;
end