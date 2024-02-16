% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function transpose(obj, new_orient)
% function transpose(obj, new_orient)
% Change orientation of the image to the XY, XZ, or YZ plane.
%
% @note This function updates only the imageData.slices and imageData.orientation variables and do not rearrange the actual datasets.
%
% Parameters:
% new_orient: a desired orientation:
% @li @b 1 -> XZ plane
% @li @b 2 -> YZ plane
% @li @b 3 -> YX plane
%
% Return values:

%| 
% @b Examples:
% @code mibImage.transpose(1);      // transpose to the XZ plane  @endcode

% Updates
% 


if obj.orientation == 1 % xz     % remember index of the slice
    obj.current_yxz(1) = obj.slices{1}(1);
elseif obj.orientation == 2 % yz
    obj.current_yxz(2) = obj.slices{2}(1);
elseif obj.orientation == 4 % yx
    obj.current_yxz(3) = obj.slices{4}(1);
end

switch new_orient
    case 4  %'yx'
        obj.orientation = 4; % ('yx';
        obj.slices{1} = [1, obj.height];
        obj.slices{2} = [1, obj.width];
        obj.slices{4} = [obj.current_yxz(3), obj.current_yxz(3)];
    case 1 %'xz'
        obj.orientation = 1; %'xz';
        obj.slices{1} = [obj.current_yxz(1), obj.current_yxz(1)];
        obj.slices{2} = [1, obj.width];
        obj.slices{4} = [1, obj.depth];
    case 2 %'yz'
        obj.orientation = 2; %'yz';
        obj.slices{1} = [1, obj.height];
        obj.slices{2} = [obj.current_yxz(2), obj.current_yxz(2)];
        obj.slices{4} = [1, obj.depth];
end
end