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

function result = setData4D(obj, type, dataset, orient, col_channel, options)
% result = setData4D(obj, type, dataset, orient, col_channel, options)
% Set complete 4D dataset with colors [height:width:colors:depth:time]
%
% Parameters:
% type: type of the dataset to update, 'image', 'model','mask', 'selection', or 'everything' ('model','mask' and 'selection' for imageData.model_type==''uint6'' only)
% dataset: 4D or 5D stack. 
% @li if options.roiId is @b not @b used, @em dataset can be either a cell ({1}[1:height, 1:width, 1:colors, 1:depth, 1:time]; for all other types: {1}[1:height, 1:width, 1:depth, 1:time]) or a matrix ([1:height, 1:width, 1:colors, 1:depth, 1:time]; for all other types: [1:height, 1:width, 1:depth, 1:time])
% @li if options.roiId is @b used, @em dataset should be a cell array ({roiId}[1:height, 1:width, 1:colors, 1:depth, 1:time]; for all other types: {roiId}[1:height, 1:width, 1:depth, 1:time])
% orient: [@em optional], can be @em NaN
% @li when @b 0 (@b default) updates the dataset transposed from the current orientation (obj.orientation)
% @li when @b 1 updates transposed dataset from the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 updates transposed dataset from the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 updates original dataset from the yx configuration: [y,x,c,z,t]
% @li when @b 5 not used
% col_channel: [@em optional],
% @li when @b type is 'image', @b col_channel is a vector with color numbers to take, when @b NaN [@e default] take the colors
% selected in the imageData.slices{3} variable, when @b 0 - take all colors of the dataset.
% @li when @b type is 'model' @b col_channel may be @em NaN - to take all materials of the model or an integer to take specific material. In the later case the selected material will have index = 1.
% options: [@em optional], a structure with extra parameters
% @li .blockModeSwitch -> override the block mode switch mibImage.blockModeSwitch; use or not the block mode (@b 0 - return full dataset, @b 1 - return only the shown part)
% @li .roiId -> use or not the ROI mode  (@b when @b missing  or less than 0, update full dataset, without ROI; @b 0 - update all ROIs of dataset, @b Index - update ROI with the index, @b [] - currently selected) (@b Attention: see also fillBg parameter!)
% @li .fillBg -> when @b 1 -> keep the background from @b slice; when @b NaN or @b[] [@b default] -> crop @b slice with respect to the ROI shape
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose, height (sets .blockModeSwitch to 0)
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose, width (sets .blockModeSwitch to 0)
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth (sets .blockModeSwitch to 0)
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
% @li .level -> [@em optional], index of image level from the image pyramid
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
% @li .replaceDatasetSwitch -> [@em optional], force to replace dataset completely with a new dataset
% @li .keepModel -> [@em optional], do not resize the model/selection
% layers when type='image' and submitting complete dataset; as result the selection/model layers have to be
% modified manually layer. Used in mibResampleController. Default = 1;
%
% Return values:
% result: -> @b 1 - success, @b 0 - error

%|
% @b Examples:
% @code obj.mibModel.setData4D('image', dataset);      // Call from mibController: update the complete dataset in the shown orientation @endcode
% @code obj.mibModel.setData4D('image', dataset, NaN, NaN, options.blockModeSwitch=1); // Call from mibController: update the croped to the viewing window dataset, with shown colors @endcode
% @code obj.mibModel.setData4D('image', dataset, 4, 2); // Call from mibController: update complete dataset in the XY orientation with only second color channel @endcode
% @attention @b sensitive to the @code mibGUI.handles.toolbarBlockModeSwitch; if the blockMode should be disabled use options.blockModeSwitch=0 @endcode
% @attention @b not @b sensitive to the shown ROI, if areas under ROIs are required use options.roiId and options.fillBg parameters

% Updates
% 16.08.2017, IB added forcing of the block mode off, when x, y, or z parameter is present in options

result = 0;
if nargin < 6; options=struct(); end
if nargin < 5; col_channel = NaN; end
if nargin < 4; orient = NaN; end

if ~isfield(options, 'id'); options.id = obj.Id; end
if ~isfield(options, 'fillBg'); options.fillBg = NaN; end
if ~isfield(options, 'blockModeSwitch')
    if isfield(options, 'x') || isfield(options, 'y') || isfield(options, 'z')
        options.blockModeSwitch = 0; 
    else
        options.blockModeSwitch = obj.getImageProperty('blockModeSwitch'); 
    end
end
if ~isfield(options, 'roiId');    options.roiId = -1;  end
if isempty(options.roiId)
    options.roiId = obj.I{options.id}.selectedROI;
end
if options.blockModeSwitch == 1; options.roiId = -1; end   % turn off the ROI mode, when the block mode is on

% setting default values for the orientation
if orient == 0 || isnan(orient); orient=obj.I{options.id}.orientation; end

if strcmp(type,'image')
    if isnan(col_channel); col_channel=obj.I{options.id}.slices{3}; end
    if col_channel(1) == 0 
        col_channel = 1:min([obj.I{options.id}.colors size(dataset, 3)]); 
    end
end

if isfield(options, 'blockModeSwitch')
    if options.blockModeSwitch == 1
        [axesX, axesY] = obj.getAxesLimits(options.id);
        options.x = ceil(axesX);
        options.y = ceil(axesY);
    end
end

if options.roiId >= 0
    if strcmp(type,'image')
        typeIsImage = 1; 
        timeDimIndex = 5;
    else
        typeIsImage = 0; 
        timeDimIndex = 4;
    end
    
    % get indices of ROI
    if options.roiId == 0
        [~, options.roiId] = obj.I{options.id}.hROI.getNumberOfROI(orient);  % get number of ROI for the selected orientation
    end
    roiId2 = 1;
    for roiId = options.roiId
        mask = obj.I{options.id}.hROI.returnMask(roiId);
        bb = obj.I{options.id}.hROI.getBoundingBox(roiId);
        options.x = [bb(1), bb(2)];
        options.y = [bb(3), bb(4)];
        
        if ~isnan(options.fillBg)
            result = obj.I{options.id}.setData(type, dataset{roiId2}, orient, col_channel, options);
        else
            % crop mask to its bounding box
            mask = mask(max([1 bb(3)]):bb(4), max([1 bb(1)]):bb(2));
            mask = repmat(mask,[1, 1, size(dataset{roiId2},3), size(dataset{roiId2},4)]);
            
            setTime = options.t(1);
            for timePnt = 1:size(dataset{roiId2}, timeDimIndex)
                options.t = [setTime+timePnt-1, setTime+timePnt-1];
                sliceTemp = obj.I{options.id}.getData(type, orient, col_channel, options);     % get current dataset
                if typeIsImage
                    datasetTemp = dataset{roiId2}(:,:,:,:,timePnt);
                else
                    datasetTemp = dataset{roiId2}(:,:,:,timePnt);
                end
                sliceTemp(mask==1) = datasetTemp(mask==1);
                result = obj.I{options.id}.setData(type, sliceTemp, orient, col_channel, options);
            end
        end
        roiId2 = roiId2 + 1;
    end
else
    if iscell(dataset)
        result = obj.I{options.id}.setData(type, dataset{1}, orient, col_channel, options);
    else
        result = obj.I{options.id}.setData(type, dataset, orient, col_channel, options);
    end
end
end