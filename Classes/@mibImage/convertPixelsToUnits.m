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