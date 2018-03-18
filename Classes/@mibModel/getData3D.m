function dataset = getData3D(obj, type, time, orient, col_channel, options, custom_img)
% function dataset = getData3D(obj, type, time, orient, col_channel, options, custom_img)
% Get the a 3D dataset with colors: height:width:colors:depth
%
% Parameters:
% type: type of the slice to retrieve, 'image', 'model','mask', 'selection', 'custom' ('custom' indicates to use custom_img as the dataset), 'everything'('model','mask' and 'selection' for imageData.model_type==''uint6'' only)
% time: [@em optional], an index of the time point to show, when @em NaN gets the dataset for the current time point
% orient: [@em optional], can be @em NaN 
% @li when @b 0 (@b default) returns the dataset transposed to the current orientation (obj.orientation)
% @li when @b 1 returns transposed dataset to the zx configuration: [y,x,c,z] -> [x,z,c,y]
% @li when @b 2 returns transposed dataset to the zy configuration: [y,x,c,z] -> [y,z,c,y]
% @li when @b 3 not used
% @li when @b 4 returns original dataset to the yx configuration: [y,x,c,z]
% @li when @b 5 not used
% col_channel: [@em optional], can be @e NaN
% @li when @b type is 'image', col_channel is a vector with color numbers to take, when @b NaN [@e default] take the colors
% selected in the imageData.slices{3} variable, when @b 0 - take all colors of the dataset.
% @li when @b type is 'model' col_channel may be @em NaN - to take all materials of the model or an integer to take specific material. In the later case the selected material in @b slice will have index = 1.
% options: [@em optional], a structure with extra parameters
% @li .blockModeSwitch -> override the block mode switch mibImage.blockModeSwitch; use or not the block mode (@b 0 - return full dataset, @b 1 - return only the shown part)
% @li .roiId -> use or not the ROI mode (@b when missing or less than 0, return full dataset; @b 0 - return all shown ROIs dataset, @b Index or [] - return ROI with this index or currently selected)
% @li .fillBg -> when @em NaN (@b default) -> crops the dataset as a rectangle; when @em a @em number fills the areas out of the ROI area with this intensity number (@b Attention: see also fillBg parameter!)
% @li .y -> [@em optional], [ymin, ymax] of the part of the dataset to take (sets .blockModeSwitch to 0)
% @li .x -> [@em optional], [xmin, xmax] of the part of the dataset to take (sets .blockModeSwitch to 0)
% @li .z -> [@em optional], [zmin, zmax] of the part of the dataset to take (sets .blockModeSwitch to 0)
% @li .level -> [@em optional], index of image level from the image pyramid
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
% custom_img: [@em optional], can be @e NaN; the function return a slice not from the imageData class but from this custom_img, requires to
% specify the 'custom' @b type. 'custom_img' should be a 3D dataset.
%
% Return values:
% dataset: a cell array with 3D dataset with colors. For the 'image' type: {roiId}[1:height, 1:width, 1:colors, 1:depth]; for all other types: {roiId}[1:height, 1:width, 1:depth]

%| 
% @b Examples:
% @code dataset = obj.mibModel.getData3D('image');      //  Call from mibController: get the 4D dataset for the current time point, in the shown orientation  @endcode
% @code dataset = obj.mibModel.getData3D('image', 5, 4, 2); //  Call from mibController: get the 4D dataset for the 5-th time point in the XY orientation @endcode
% @attention @b sensitive to the @code mibGUI.handles.toolbarBlockModeSwitch; if the blockMode should be disabled use options.blockModeSwitch=0 @endcode
% @attention @b not @b sensitive to the shown ROI, if areas under ROIs are required use options.roiId and options.fillBg parameters

% Copyright (C) 07.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 16.08.2017, IB added forcing of the block mode off, when x, y, or z parameter is present in options

if nargin < 7; custom_img = NaN; end
if nargin < 6; options = struct();  end
if nargin < 5; col_channel = NaN;   end
if nargin < 4; orient = NaN; end
if nargin < 3; time = NaN; end

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

if strcmp(type,'image')
    if isnan(col_channel); col_channel=obj.I{options.id}.slices{3}; end
    if col_channel(1) == 0;  col_channel = 1:obj.I{options.id}.colors; end
end
options.t = [time time];   % define the time point

if isfield(options, 'blockModeSwitch')
    if options.blockModeSwitch == 1
        [axesX, axesY] = obj.getAxesLimits(options.id);
        options.x = ceil(axesX);
        options.y = ceil(axesY);
    end
end

if options.roiId >= 0
    % get indices of ROI
    if options.roiId == 0
        [~, options.roiId] = obj.I{options.id}.hROI.getNumberOfROI(orient);  % get number of ROI for the selected orientation
    end
    roiId2 = 1;
    dataset{roiId2} = cell(numel(options.roiId), 1);
    for roiId = options.roiId
        mask = obj.I{options.id}.hROI.returnMask(roiId);
        bb = obj.I{options.id}.hROI.getBoundingBox(roiId);
        options.x = [bb(1), bb(2)];
        options.y = [bb(3), bb(4)];

        dataset{roiId2} = obj.I{options.id}.getData(type, orient, col_channel, options);
        if ~isnan(options.fillBg)
            mask = mask(bb(3):bb(4), bb(1):bb(2));
            
            mask = repmat(mask,[1, 1, numel(col_channel)]);
            for layerId = 1:size(dataset{roiId2}, max([ndims(dataset{roiId2}) 3]))
                if strcmp(type, 'image')
                    slice = dataset{roiId2}(:,:,:,layerId);
                    slice(~mask) = options.fillBg;
                    dataset{roiId2}(:,:,:,layerId) = slice; 
                else
                    slice = dataset{roiId2}(:,:,layerId);
                    slice(~mask) = options.fillBg;
                    dataset{roiId2}(:,:,layerId) = slice; 
                end
            end
        end
        roiId2 = roiId2 + 1;
    end
else    
    dataset = {obj.I{options.id}.getData(type, orient, col_channel, options, custom_img)};    
end
end