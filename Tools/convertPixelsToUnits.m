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