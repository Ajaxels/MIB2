function moveView(obj, x, y, orient)
% function moveView(obj, x, y, orient)
% Center the image view at the provided coordinates: x, y
%
% Parameters:
% x: - X coordinate of the window center, or index of the point
% y: - [@em optional] Y coordinate of the window center, can be @e NaN
% orient: - [@em optional] define orientation of the point, default is the currently shown orientation
% @li when @b 0 (@b default) assumes that the points are taken at the current orientation (obj.orientation)
% @li when @b 1 assumes that the points are taken at the zx orientation
% @li when @b 2 assumes that the points are taken at the zy orientation
% @li when @b 3 not used
% @li when @b 4 assumes that the points are taken at the yx orientation
% @li when @b 5 not used
%
% Return values:

%| 
% @b Examples:
% @code obj.moveView(50, 75);     // call from mibController, center the view at the pixel 50, 75 @endcode

% Copyright (C) 10.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 16.08.2017, IB, updated to use updateSlicesStructure method

if nargin < 4; orient = 0; end
if nargin < 3; y = NaN; end
    
if orient == 0; orient = obj.orientation; end

if isnan(y)     % generate y from the point index
    getDataOptions.blockModeSwitch = 0;
    [img_height, img_width, ~, img_depth] = obj.getDatasetDimensions('image', orient, NaN, getDataOptions);
    [y, x, ~] = ind2sub([img_height img_width img_depth], x);
end

axesX = [x - diff(obj.axesX)/2 x + diff(obj.axesX)/2];
axesY = [y - diff(obj.axesY)/2 y + diff(obj.axesY)/2];
obj.updateSlicesStructure(axesX, axesY);

end