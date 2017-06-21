function result = copySlice(obj, sliceNumberFrom, sliceNumberTo, orient)
% function result = copySlice(obj, sliceNumberFrom, sliceNumberTo, orient)
% Copy specified slice from one part of the dataset to another
%
% Parameters:
% sliceNumberFrom: index of the source slice
% sliceNumberTo: index of the destination slice
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
% @code obj.mibModel.I{obj.mibModel.Id}.copySlice(3, 10); // call from mibController; copy slice 3 to slice 10 @endcode

% Copyright (C) 17.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 

if nargin < 4; orient = obj.orientation; end;
if isnan(orient); orient = obj.orientation; end;
if orient==0; orient = obj.orientation; end;

result = 0;
maxSliceNumber = size(obj.img{1}, orient);
if sliceNumberFrom > maxSliceNumber || sliceNumberTo > maxSliceNumber || sliceNumberFrom < 1 || sliceNumberTo < 1
    msgbox(sprintf('The slice numbers should be between 1 and %d!', maxSliceNumber), 'Wrong slice number', 'error', 'modal');
    return;
end

h = waitbar(0, sprintf('Copy slice %d -> %d\nPlease wait...', sliceNumberFrom, sliceNumberTo), 'Name', 'Copy the slice...');
maxT = size(obj.img{1},5);
maxZ = size(obj.img{1},4);
maxH = size(obj.img{1},1);
maxW = size(obj.img{1},2);

% delete slice from obj.img
if orient == 4     % xy orientation
    obj.img{1}(:, :, :, sliceNumberTo, :) = obj.img{1}(:, :, :, sliceNumberFrom, :);
elseif orient == 1     % zx orientation
    obj.img{1}(sliceNumberTo, :, :, :, :) = obj.img{1}(sliceNumberFrom, :, :, :, :);
elseif orient == 2     % zy orientation
    obj.img{1}(:, sliceNumberTo, :, :, :) = obj.img{1}(:, sliceNumberFrom, :, :, :);
elseif orient == 5     % t orientation
    obj.img{1}(:, :, :, :, sliceNumberTo) = obj.img{1}(:, :, :, :, sliceNumberFrom);
end
waitbar(0.3, h);

% delete slice from selection
if ~isnan(obj.selection{1}(1))
    if orient == 4     % xy orientation
        obj.selection{1}(:, :, sliceNumberTo, :) = obj.selection{1}(:, :, sliceNumberFrom, :);
    elseif orient == 1     % zx orientation
        obj.selection{1}(sliceNumberTo, :, :, :) = obj.selection{1}(sliceNumberFrom, :, :, :);
    elseif orient == 2     % zy orientation
        obj.selection{1}(:, sliceNumberTo, :, :) = obj.selection{1}(:, sliceNumberFrom, :, :);
    elseif orient == 5     % t orientation
        obj.selection{1}(:, :, :, sliceNumberTo) = obj.selection{1}(:, :, :, sliceNumberFrom);        
    end
end
waitbar(0.5, h);

% delete slice from model
if ~isnan(obj.model{1}(1))
    if orient == 4     % xy orientation
        obj.model{1}(:, :, sliceNumberTo, :) = obj.model{1}(:, :, sliceNumberFrom, :);
    elseif orient == 1     % zx orientation
        obj.model{1}(sliceNumberTo, :, :, :) = obj.model{1}(sliceNumberFrom, :, :, :);
    elseif orient == 2     % zy orientation
        obj.model{1}(:, sliceNumberTo, :, :) = obj.model{1}(:, sliceNumberFrom, :, :);
    elseif orient == 5     % t orientation
        obj.model{1}(:, :, :, sliceNumberTo) = obj.model{1}(:, :, :, sliceNumberFrom);        
    end
end
waitbar(0.7, h);

% delete slice from mask
if ~isnan(obj.maskImg{1}(1))
    if orient == 4     % xy orientation
        obj.maskImg{1}(:, :, sliceNumberTo, :) = obj.maskImg{1}(:, :, sliceNumberFrom, :);
    elseif orient == 1     % zx orientation
        obj.maskImg{1}(sliceNumberTo, :, :, :) = obj.maskImg{1}(sliceNumberFrom, :, :, :);
    elseif orient == 2     % zy orientation
        obj.maskImg{1}(:, sliceNumberTo, :, :) = obj.maskImg{1}(:, sliceNumberFrom, :, :);
    elseif orient == 5     % t orientation
        obj.maskImg{1}(:, :, :, sliceNumberTo) = obj.maskImg{1}(:, :, :, sliceNumberFrom);        
    end
end
waitbar(0.9, h);

% update the log list
log_text = sprintf('Copy slice: %d->%d, Orient: %d', sliceNumberFrom, sliceNumberTo, orient);
obj.updateImgInfo(log_text);

waitbar(1, h);
delete(h);
result = 1;
end