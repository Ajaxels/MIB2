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

function [x, y, z] = convertPixelsToUnits(obj, x, y, z)
% function [x, y, z] = convertPixelToUnits(obj, x, y, z)
% convert pixel with x, y, z coordinate to the physical imaging units
%
% Parameters:
% x: -> x - coordinate in pixels
% y: -> y - coordinate in pixels
% z: -> z - coordinate in pixels
% 
% Return values:
% x: -> x - coordinate in physical units, i.e. um
% y: -> y - coordinate in physical units, i.e. um
% z: -> z - coordinate in physical units, i.e. um
%
% @note See also similar function in the Tools\convertPixelsToUnits

%| 
% @b Examples
% @code 
% [xUnits, xUnits, xUnits] = obj.mibModel.I{obj.mibModel.Id}.convertPixelsToUnits(xPixel, xPixel, xPixel); 
% @endcode

if nargin < 4; error('missing parameters'); end

bb = obj.getBoundingBox();
if obj.orientation == 4     % yx
    x = x*obj.pixSize.x + bb(1);
    y = y*obj.pixSize.y + bb(3);
    z = z*obj.pixSize.z + bb(5) - obj.pixSize.z;
elseif obj.orientation == 1     % xz
    x = x*obj.pixSize.x + bb(1);
    y = y*obj.pixSize.y + bb(3) - obj.pixSize.y;
    z = z*obj.pixSize.z + bb(5);
elseif obj.orientation == 2     % yz
    x = x*obj.pixSize.x + bb(1) - obj.pixSize.x;
    y = y*obj.pixSize.y + bb(3);
    z = z*obj.pixSize.z + bb(5);
end

%x = (x - bb(1) + obj.pixSize.x/2)/obj.pixSize.x;
%y = (y - bb(3) + obj.pixSize.y/2)/obj.pixSize.y;
%z = (z - bb(5) + obj.pixSize.z/2)/obj.pixSize.z;

end