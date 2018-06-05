function [labelsList, labelValues, labelPositions, indices] = getSliceLabels(obj, sliceNumber, timePoint)
% [labelsList, labelValues, labelPositions, indices] = getSliceLabels(obj, sliceNumber, timePoint)
% Get list of labels (mibImage.hLabels) shown at the specified slice
%
% Parameters:
% sliceNumber: [@em optional], a slice number to get labels
% timePoint: [@em optional], a time point to get the labels
%
% Return values:
% labelsList:   a cell array with labels
% labelPositions:   a matrix with coordinates of the labels [labelIndex, z x y]
% indices:  indices of the labels

%|
% @b Examples:
% @code [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(15); // call from mibController; get all labels from the slice 15 @endcode
% @code [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(); // call from mibController;  get all labels from the currently shown slice @endcode
if nargin < 3
    timePoint = obj.slices{5}(1);
end
if nargin < 2
    sliceNumber = obj.slices{obj.orientation}(1);
end

if obj.orientation == 4   % xy
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels(sliceNumber, NaN, NaN, timePoint);
elseif obj.orientation == 1   % zx
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels(NaN, NaN, sliceNumber, timePoint);
elseif obj.orientation == 2   % zy
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels(NaN, sliceNumber, NaN, timePoint);
end
end