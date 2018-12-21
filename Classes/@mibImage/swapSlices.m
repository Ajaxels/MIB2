function result = swapSlices(obj, sliceNumberFrom, sliceNumberTo, orient)
% function result = swapSlices(obj, sliceNumberFrom, sliceNumberTo, orient)
% Swap specified slices 
%
% Parameters:
% sliceNumberFrom: indeces of the source slice
% sliceNumberTo: indeces of the destination slice
% orient: [@em optional], can be @em NaN (current orientation)
% @li when @b 0 (@b default) the current orientation (obj.orientation)
% @li when @b 1 the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 the yx configuration: [y,x,c,z,t]
% @li when @b 5 the t configuration
%
% Return values:
% result: result of the function, @b 0 fail, @b 1 success

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.swapSlices([3, 4], [10, 11]); // call from mibController; swap slices 3 & 4 with 10 & 11 @endcode

% Copyright (C) 21.12.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 

if nargin < 4; orient = obj.orientation; end
if isnan(orient); orient = obj.orientation; end
if orient==0; orient = obj.orientation; end

result = 0;

if numel(sliceNumberFrom) ~= numel(sliceNumberTo)
    errordlg(sprintf('!!! Error !!!\n\nNumber of slices should be the same!'), 'Wrong number of slices');
    return;
end

maxSliceNumber = size(obj.img{1}, orient);
if max(sliceNumberFrom) > maxSliceNumber || max(sliceNumberTo) > maxSliceNumber || min(sliceNumberFrom) < 1 || min(sliceNumberTo) < 1
    msgbox(sprintf('The slice numbers should be between 1 and %d!', maxSliceNumber), 'Wrong slice index', 'error', 'modal');
    return;
end

h = waitbar(0, sprintf('Swapping slices %s -> %s\nPlease wait...', num2str(sliceNumberFrom), num2str(sliceNumberTo)), 'Name', 'Swapping slices...');
maxT = obj.dim_yxczt(5); 
maxZ = obj.dim_yxczt(4);
maxH = obj.dim_yxczt(1);
maxW = obj.dim_yxczt(2);

% delete slice from obj.img
if orient == 4     % xy orientation
    slices1 = obj.img{1}(:, :, :, sliceNumberTo, :);
    slices2 = obj.img{1}(:, :, :, sliceNumberFrom, :);
    obj.img{1}(:, :, :, sliceNumberTo, :) = slices2;
    obj.img{1}(:, :, :, sliceNumberFrom, :) = slices1;
elseif orient == 1     % zx orientation
    slices1 = obj.img{1}(sliceNumberTo, :, :, :, :);
    slices2 = obj.img{1}(sliceNumberFrom, :, :, :, :);
    obj.img{1}(sliceNumberTo, :, :, :, :) = slices2;
    obj.img{1}(sliceNumberFrom, :, :, :, :) = slices1;
elseif orient == 2     % zy orientation
    slices1 = obj.img{1}(:, sliceNumberTo, :, :, :);
    slices2 = obj.img{1}(:, sliceNumberFrom, :, :, :);
    obj.img{1}(:, sliceNumberTo, :, :, :) = slices2;
    obj.img{1}(:, sliceNumberFrom, :, :, :) = slices1;
elseif orient == 5     % t orientation
    slices1 = obj.img{1}(:, :, :, :, sliceNumberTo);
    slices2 = obj.img{1}(:, :, :, :, sliceNumberFrom);
    obj.img{1}(:, :, :, :, sliceNumberTo) = slices2;
    obj.img{1}(:, :, :, :, sliceNumberFrom) = slices1;
end
waitbar(0.3, h);

% delete slice from selection
if ~isnan(obj.selection{1}(1))
    if orient == 4     % xy orientation
        slices1 = obj.selection{1}(:, :, sliceNumberTo, :);
        slices2 = obj.selection{1}(:, :, sliceNumberFrom, :);
        obj.selection{1}(:, :, sliceNumberTo, :) = slices2;
        obj.selection{1}(:, :, sliceNumberFrom, :) = slices1;
    elseif orient == 1     % zx orientation
        slices1 = obj.selection{1}(sliceNumberTo, :, :, :);
        slices2 = obj.selection{1}(sliceNumberFrom, :, :, :);
        obj.selection{1}(sliceNumberTo, :, :, :) = slices2;
        obj.selection{1}(sliceNumberFrom, :, :, :) = slices1;
    elseif orient == 2     % zy orientation
        slices1 = obj.selection{1}(:, sliceNumberTo, :, :);
        slices2 = obj.selection{1}(:, sliceNumberFrom, :, :);
        obj.selection{1}(:, sliceNumberTo, :, :) = slices2;
        obj.selection{1}(:, sliceNumberFrom, :, :) = slices1;
    elseif orient == 5     % t orientation
        slices1 = obj.selection{1}(:, :, :, sliceNumberTo);
        slices2 = obj.selection{1}(:, :, :, sliceNumberFrom);
        obj.selection{1}(:, :, :, sliceNumberTo) = slices2;
        obj.selection{1}(:, :, :, sliceNumberFrom) = slices1;
    end
end
waitbar(0.5, h);

% delete slice from model
if ~isnan(obj.model{1}(1))
    if orient == 4     % xy orientation
        slices1 = obj.model{1}(:, :, sliceNumberTo, :);
        slices2 = obj.model{1}(:, :, sliceNumberFrom, :);
        obj.model{1}(:, :, sliceNumberTo, :) = slices2;
        obj.model{1}(:, :, sliceNumberFrom, :) = slices1;
    elseif orient == 1     % zx orientation
        slices1 = obj.model{1}(sliceNumberTo, :, :, :);
        slices2 = obj.model{1}(sliceNumberFrom, :, :, :);
        obj.model{1}(sliceNumberTo, :, :, :) = slices2;
        obj.model{1}(sliceNumberFrom, :, :, :) = slices1;
    elseif orient == 2     % zy orientation
        slices1 = obj.model{1}(:, sliceNumberTo, :, :);
        slices2 = obj.model{1}(:, sliceNumberFrom, :, :);
        obj.model{1}(:, sliceNumberTo, :, :) = slices2;
        obj.model{1}(:, sliceNumberFrom, :, :) = slices1;
    elseif orient == 5     % t orientation
        slices1 = obj.model{1}(:, :, :, sliceNumberTo);
        slices2 = obj.model{1}(:, :, :, sliceNumberFrom);
        obj.model{1}(:, :, :, sliceNumberTo) = slices2;
        obj.model{1}(:, :, :, sliceNumberFrom) = slices1;       
    end
end
waitbar(0.7, h);

% delete slice from mask
if ~isnan(obj.maskImg{1}(1))
    if orient == 4     % xy orientation
        slices1 = obj.maskImg{1}(:, :, sliceNumberTo, :);
        slices2 = obj.maskImg{1}(:, :, sliceNumberFrom, :);
        obj.maskImg{1}(:, :, sliceNumberTo, :) = slices2;
        obj.maskImg{1}(:, :, sliceNumberFrom, :) = slices1;
    elseif orient == 1     % zx orientation
        slices1 = obj.maskImg{1}(sliceNumberTo, :, :, :);
        slices2 = obj.maskImg{1}(sliceNumberFrom, :, :, :);
        obj.maskImg{1}(sliceNumberTo, :, :, :) = slices2;
        obj.maskImg{1}(sliceNumberFrom, :, :, :) = slices1;
    elseif orient == 2     % zy orientation
        slices1 = obj.maskImg{1}(:, sliceNumberTo, :, :);
        slices2 = obj.maskImg{1}(:, sliceNumberFrom, :, :);
        obj.maskImg{1}(:, sliceNumberTo, :, :) = slices2;
        obj.maskImg{1}(:, sliceNumberFrom, :, :) = slices1;
    elseif orient == 5     % t orientation
        slices1 = obj.maskImg{1}(:, :, :, sliceNumberTo);
        slices2 = obj.maskImg{1}(:, :, :, sliceNumberFrom);
        obj.maskImg{1}(:, :, :, sliceNumberTo) = slices2;
        obj.maskImg{1}(:, :, :, sliceNumberFrom) = slices1;             
    end
end
waitbar(0.9, h);

% update the log list
log_text = sprintf('Swap slices: %s->%s, Orient: %d', num2str(sliceNumberFrom), num2str(sliceNumberTo), orient);
obj.updateImgInfo(log_text);

waitbar(1, h);
delete(h);
result = 1;
end