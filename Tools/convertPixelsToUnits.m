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

function [x, y, z] = convertPixelsToUnits(x, y, z, bb, pixSize, orientation)
% function [x, y, z] = convertPixelToUnits(x, y, z, bb, pixSize, orientation)
% convert pixel with x, y, z coordinate to the physical imaging units
% 
%
% Parameters:
% x: -> x - coordinate in pixels
% y: -> y - coordinate in pixels
% z: -> z - coordinate in pixels
% bb: a vector with the bounding box of the dataset
% pixSize: a structure with the voxel sizes
% orientation: a number with the orientation of the dataset, 4 for xy
%
% Return values:
% x: -> x - coordinate in physical units, i.e. um
% y: -> y - coordinate in physical units, i.e. um
% z: -> z - coordinate in physical units, i.e. um
%
% @note See also mibImage.convertPixelsToUnits, this is a copy of the same
% function taken away from the class

%| 
% @b Examples:
% @code 
% [xUnits, xUnits, xUnits] = convertPixelsToUnits(xPixel, xPixel, xPixel, obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(), obj.mibModel.I{obj.mibModel.Id}.pixSize, obj.mibModel.I{obj.mibModel.Id}.orientation); 
% @endcode

if nargin < 6; error('missing parameters'); end

if orientation == 4     % yx
    x = x*pixSize.x + bb(1);
    y = y*pixSize.y + bb(3);
    z = z*pixSize.z + bb(5) - pixSize.z;
elseif obj.orientation == 1     % xz
    x = x*pixSize.x + bb(1);
    y = y*pixSize.y + bb(3) - pixSize.y;
    z = z*pixSize.z + bb(5);
elseif obj.orientation == 2     % yz
    x = x*pixSize.x + bb(1) - pixSize.x;
    y = y*pixSize.y + bb(3);
    z = z*pixSize.z + bb(5);
end

end