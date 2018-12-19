function [x, y, z] = convertUnitsToPixels(obj, x, y, z)
% function [x, y, z] = convertUnitsToPixels(obj, x, y, z)
% convert coordinate with x, y, z in physical units to pixels
%
% Parameters:
% x: -> x - coordinate in physical units
% y: -> y - coordinate in physical units
% z: -> z - coordinate in physical units
% 
% Return values:
% x: -> x - coordinate in pixels
% y: -> y - coordinate in pixels
% z: -> z - coordinate in pixels

%| 
% @b Examples:
% @code 
% [xPixel, xPixel, xPixel] = obj.mibModel.I{obj.mibModel.Id}.convertUnitsToPixels(xUnits, xUnits, xUnits); 
% @endcode

if nargin < 4; error('missing parameters'); end

bb = obj.getBoundingBox();
if obj.orientation == 4     % yx
    x = (x - bb(1))/obj.pixSize.x;
    y = (y - bb(3))/obj.pixSize.y;
    z = (z - bb(5) + obj.pixSize.z)/obj.pixSize.z;
elseif obj.orientation == 1     % xz
    x = (x - bb(1))/obj.pixSize.x;
    y = (y - bb(3) + obj.pixSize.y)/obj.pixSize.y;
    z = (z - bb(5))/obj.pixSize.z;
elseif obj.orientation == 2     % yz
    x = (x - bb(1) + obj.pixSize.x)/obj.pixSize.x;
    y = (y - bb(3))/obj.pixSize.y;
    z = (z - bb(5))/obj.pixSize.z;
end

%x = x*obj.pixSize.x + bb(1) - obj.pixSize.x/2;
%y = y*obj.pixSize.y + bb(3) - obj.pixSize.y/2;
%z = z*obj.pixSize.z + bb(5) - obj.pixSize.z/2;

end