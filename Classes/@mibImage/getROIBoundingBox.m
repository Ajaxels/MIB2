function bb = getROIBoundingBox(obj, roiIndex)
% function bb = getROIBoundingBox(obj, roiIndex)
% return the bounding box info for the ROI at the current orientation
% 
% Parameters:
% roiIndex: [@em optional] index of ROI to return the bounding box
% 
% Return values:
% bb: a vector with the bounding box in format: bb = [minX, maxX, minY, maxY, minZ, maxZ]
%

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.getROIBoundingBox(); // call from mibController class; return the bounding box of the selected ROI @endcode

if nargin < 2; roiIndex = obj.selectedROI; end;
if roiIndex < 0; bb = []; return; end;

options.blockModeSwitch = 0;
[height, width, color, thick] = obj.getDatasetDimensions('image', 4, NaN, options);
mask = obj.hROI.returnMask(roiIndex, NaN, NaN, obj.hROI.Data(roiIndex).orientation);
STATS = regionprops(mask, 'BoundingBox');

if numel(STATS) == 0; bb(1:6) = [NaN NaN NaN NaN NaN NaN]; return; end

if obj.hROI.Data(roiIndex).orientation == 4
    bb(1) = ceil(STATS.BoundingBox(1));
    bb(2) = ceil(STATS.BoundingBox(1))+ceil(STATS.BoundingBox(3)) - 1;
    bb(3) = ceil(STATS.BoundingBox(2));
    bb(4) = ceil(STATS.BoundingBox(2))+ceil(STATS.BoundingBox(4)) - 1;
    bb(5) = 1;
    bb(6) = thick;
elseif obj.hROI.Data(roiIndex).orientation == 1
    bb(5) = ceil(STATS.BoundingBox(1));
    bb(6) = ceil(STATS.BoundingBox(1))+ceil(STATS.BoundingBox(3)) - 1;
    bb(1) = ceil(STATS.BoundingBox(2));
    bb(2) = ceil(STATS.BoundingBox(2))+ceil(STATS.BoundingBox(4)) - 1;
   
    bb(3) = 1;
    bb(4) = height;
elseif obj.hROI.Data(roiIndex).orientation == 2
    bb(5) = ceil(STATS.BoundingBox(1));
    bb(6) = ceil(STATS.BoundingBox(1))+ceil(STATS.BoundingBox(3)) - 1;
    bb(3) = ceil(STATS.BoundingBox(2));
    bb(4) = ceil(STATS.BoundingBox(2))+ceil(STATS.BoundingBox(4)) - 1;
    bb(1) = 1;
    bb(2) = width;
end
end