function result = setData3D(obj, type, dataset, time, orient, col_channel, options)
% function result = setData3D(obj, type, dataset, time, orient, col_channel, options)
% set the 3D dataset with colors: height:width:colors:depth to the dataset
%
% Parameters:
% type: type of the dataset to set, 'image', 'model','mask', 'selection', 'custom' ('custom' indicates to use custom_img as the dataset), 'everything'('model','mask' and 'selection' for imageData.model_type==''uint6'' only)
% dataset: a 3D image with colors
% @li if options.roiId is @b not @b used, @em dataset can be either a cell ({1}[1:height, 1:width, 1:colors, 1:depth]; for all other types: {1}[1:height, 1:width, 1:depth]) or a matrix ([1:height, 1:width, 1:colors, 1:depth]; for all other types: [1:height, 1:width, 1:depth])
% @li if options.roiId is @b used, @em dataset should be a cell array ({roiId}[1:height, 1:width, 1:colors, 1:depth]; for all other types: {roiId}[1:height, 1:width, 1:depth])
% time: [@em optional], an index of the time point to show, when @em NaN gets the dataset for the current time point
% orient: [@em optional], can be @em NaN 
% @li when @b 0 (@b default) updates the dataset transposed from the current orientation (obj.orientation)
% @li when @b 1 returns transposed dataset from the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 returns transposed dataset from the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 returns original dataset from the yx configuration: [y,x,c,z,t]
% @li when @b 5 not used
% col_channel: [@em optional], can be @e NaN
% @li when @b type is 'image', col_channel is a vector with color numbers to take, when @b NaN [@e default] take the colors
% selected in the imageData.slices{3} variable, when @b 0 - take all colors of the dataset.
% @li when @b type is 'model' col_channel may be @em NaN - to take all materials of the model or an integer to take specific material. In the later case the selected material in @b slice will have index = 1.
% options: [@em optional], a structure with extra parameters
% @li .blockModeSwitch -> override the block mode switch mibImage.blockModeSwitch; use or not the block mode (@b 0 - update full dataset, @b 1 - update only the shown part)
% @li .roiId -> use or not the ROI mode  (@b when @b missing or less than 0, update full dataset, without ROI; @b 0 - update all ROIs of dataset, @b Index - update ROI with the index, @b [] - currently selected) (@b Attention: see also fillBg parameter!)
% @li .fillBg -> when @b 1 -> keep the background from @b slice; when @b NaN or @b[] [@b default] -> crop @b slice with respect to the ROI shape
% @li .y -> [@em optional], [ymin, ymax] of the part of the dataset to take (sets .blockModeSwitch to 0)
% @li .x -> [@em optional], [xmin, xmax] of the part of the dataset to take (sets .blockModeSwitch to 0)
% @li .z -> [@em optional], [zmin, zmax] of the part of the dataset to take (sets .blockModeSwitch to 0)
% @li .level -> [@em optional], index of image level from the image pyramid
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
% @li .PixelIdxList -> [@em optional], indices of pixels that have to be updated (calculated for the current 3D stack of the dataset in the XY
% orientation), when used all other parameters are not considered also in this case @b dataset should be a vector. [@b not @b implemented @b for @b 'images'
%
% Return values:
% result: -> @b 1 - success, @b 0 - error

%| 
% @b Examples:
% @code dataset = obj.mibModel.setData3D('image', dataset);      // Call from mibController: set the 4D dataset for the current time point, in the shown orientation  @endcode
% @code dataset = obj.mibModel.setData3D('image', dataset, 5, 4); // Call from mibController: set the 4D dataset for the 5-th time point in the XY orientation @endcode
% @code dataset = obj.mibModel.setData3D('selection', dataset, 5, 1, 2); // Call from mibController: set the 5-th timepoint in the the XZ-orientation, color channel=2 @endcode
% @code dataset = obj.mibModel.setData3D('image', dataset, [], 4);      // Call from mibController: set the 4D dataset for the current time point in the XY orientation  @endcode
% @attention @b sensitive to the @code mibGUI.handles.toolbarBlockModeSwitch; if the blockMode should be disabled use options.blockModeSwitch=0 @endcode
% @attention @b not @b sensitive to the shown ROI, if areas under ROIs are required use options.roiId and options.fillBg parameters

% Copyright (C) 06.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 16.08.2017, IB added forcing of the block mode off, when x, y, or z parameter is present in options

if nargin < 7; options = struct();  end
if nargin < 6; col_channel = NaN;   end
if nargin < 5; orient = NaN; end
if nargin < 4; time = NaN; end

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
    options.roiId = obj.I{obj.Id}.selectedROI;
end
if options.blockModeSwitch == 1; options.roiId = -1; end   % turn off the ROI mode, when the block mode is on

if isnan(time); time = obj.I{options.id}.slices{5}(1); end
if orient == 0 || isnan(orient); orient=obj.I{options.id}.orientation; end

if isfield(options, 'PixelIdxList')
    if strcmp(type, 'image'); errordlg(sprintf('!!! Error !!!\n\nmibImage.setData3D: the PixelIdxList parameter is not compatible with the the Image layer'), 'Syntax error!'); return; end
    if time > 1     % shift the indices to the choosen time point
        options.PixelIdxList = options.PixelIdxList + ...
            obj.I{options.id}.width*obj.I{options.id}.height*obj.I{options.id}.depth*(time-1);
    end
    result = obj.I{options.id}.setPixelIdxList(type, dataset, options.PixelIdxList);
    return;
end

if strcmp(type,'image')
    if isnan(col_channel); col_channel=obj.I{options.id}.slices{3}; end
    if col_channel(1) == 0;  col_channel = 1:obj.I{options.id}.colors; end
end

if isfield(options, 'blockModeSwitch')
    if options.blockModeSwitch == 1
        [axesX, axesY] = obj.getAxesLimits(options.id);
        options.x = ceil(axesX);
        options.y = ceil(axesY);
    end
end

options.t = [time time];   % define the time point

if options.roiId >= 0
    typeIsImage = 0; 
    if strcmp(type,'image'); typeIsImage = 1; end
    
    % get indices of ROI
    if options.roiId == 0
        [~, options.roiId] = obj.I{obj.Id}.hROI.getNumberOfROI(orient);  % get number of ROI for the selected orientation
    end
    roiId2 = 1;
    for roiId = options.roiId
        mask = obj.I{obj.Id}.hROI.returnMask(roiId);
        bb = obj.I{options.id}.hROI.getBoundingBox(roiId);
        options.x = [bb(1), bb(2)];
        options.y = [bb(3), bb(4)];
        
        if ~isnan(options.fillBg)
            if iscell(dataset)
                result = obj.I{options.id}.setData(type, dataset{roiId2}, orient, col_channel, options);
            else
                result = obj.I{options.id}.setData(type, dataset, orient, col_channel, options);
            end
        else
            % crop mask to its bounding box
            mask = mask(bb(3):bb(4), bb(1):bb(2));
            if iscell(dataset)
                mask = repmat(mask, [1, 1, numel(col_channel), size(dataset{roiId2}, max([ndims(dataset{roiId2}) 3]))]);
                sliceTemp = obj.I{options.id}.getData(type, orient, col_channel, options);     % get current dataset
                sliceTemp(mask==1) = dataset{roiId2}(mask==1);
            else
                mask = repmat(mask, [1, 1, numel(col_channel), size(dataset, max([ndims(dataset) 3]))]);
                sliceTemp = obj.I{options.id}.getData(type, orient, col_channel, options);     % get current dataset
                sliceTemp(mask==1) = dataset(mask==1);
            end
            result = obj.I{options.id}.setData(type, sliceTemp, orient, col_channel, options);
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