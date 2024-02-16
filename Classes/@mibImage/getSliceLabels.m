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

function [labelsList, labelValues, labelPositions, indices] = getSliceLabels(obj, sliceNumber, timePoint, options)
% [labelsList, labelValues, labelPositions, indices] = getSliceLabels(obj, sliceNumber, timePoint, options)
% Get list of labels (mibImage.hLabels) shown at the specified slice
%
% Parameters:
% sliceNumber: [@em optional], a slice number to get labels
% timePoint: [@em optional], a time point to get the labels
% options: [@em optional], structure with additional parameters
%       -> .blockModeSwitch: [@em optional], optionally return labels that are seen only in the current view
%       -> .shiftCoordinates: [@em optional], shift coordinates so that they are corrected relative to the crop introduces by blockModeSwitch
%       
%
% Return values:
% labelsList:   a cell array with labels
% labelPositions:   a matrix with coordinates of the labels [labelIndex, z x y]
% indices:  indices of the labels

%|
% @b Examples:
% @code [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(15); // call from mibController; get all labels from the slice 15 @endcode
% @code [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(); // call from mibController;  get all labels from the currently shown slice @endcode

if nargin < 4; options = struct(); end
if nargin < 3; timePoint = obj.slices{5}(1); end
if nargin < 2; sliceNumber = obj.slices{obj.orientation}(1); end

if obj.orientation == 4   % xy
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels(sliceNumber, NaN, NaN, timePoint);
elseif obj.orientation == 1   % zx
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels(NaN, NaN, sliceNumber, timePoint);
elseif obj.orientation == 2   % zy
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels(NaN, sliceNumber, NaN, timePoint);
end

% additionally remove points that are not visible in the current view 
if isfield(options, 'blockModeSwitch') && options.blockModeSwitch
    if obj.orientation == 4     % get ids of the correct vectors in the matrix, depending on orientation
        xId = 2;
        yId = 3;
    elseif obj.orientation == 1
        xId = 1;
        yId = 2;
    elseif obj.orientation == 2
        xId = 1;
        yId = 3;
    end
    % filter points to return only the points visible in the view
    pntIndices = labelPositions(:,xId) >= obj.axesX(1) & labelPositions(:,xId) <= obj.axesX(2) & ...
        labelPositions(:,yId) >= obj.axesY(1) & labelPositions(:,yId) <= obj.axesY(2);

    % trim the list
    labelsList = labelsList(pntIndices);
    labelValues = labelValues(pntIndices);
    labelPositions = labelPositions(pntIndices, :);
    indices = indices(pntIndices);

    resizeSwitch = false;
    magnificationFactor = 1;
    if isfield(options, 'shiftCoordinates') && options.shiftCoordinates
        if resizeSwitch == 0     % this needed for snapshots
            labelPositions(:,xId) = ceil((labelPositions(:,xId) - max([0 floor(obj.axesX(1))])) );     % - .999/obj.magFactor subtract 1 pixel to put a marker to the left-upper corner of the pixel
            labelPositions(:,yId) = ceil((labelPositions(:,yId) - max([0 floor(obj.axesY(1))])) );
        else
            labelPositions(:,xId) = ceil((labelPositions(:,xId) - max([0 floor(obj.axesX(1))])) / magnificationFactor);% - .999/obj.magFactor);     % - .999/obj.magFactor subtract 1 pixel to put a marker to the left-upper corner of the pixel
            labelPositions(:,yId) = ceil((labelPositions(:,yId) - max([0 floor(obj.axesY(1))])) / magnificationFactor);% - .999/obj.magFactor);
        end
    end
end