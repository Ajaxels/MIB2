function clearContents(obj, img, meta, disableSelection)
% function clearContents(obj, img, meta, disableSelection)
% Set all elements of the class to default values
%
% Parameters:
% img: @b [optional], image to use to initialize the imageData class
% meta: @b [optional], 'containers'.'Map' class with parameters of the dataset, can be @e []
% disableSelection: a switch (0 or 1) to enable/disable selection layer
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.clearContents(); // call from mibController to clear the class @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.clearContents(I, metadata); // call from mibController to reinitialize the class with image I and its metadata @endcode
% @code obj.mibModel.getImageMethod('clearContents'); // call from mibController via a wrapper function getImageMethod @endcode


% Copyright (C) 28.10.2016, Ilya Belevich (ilya.belevich @ helsinki.fi)
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 

obj.modelFilename = [];    % filename for a model
obj.modelVariable = 'mibModel'; % variable name in the model mat-file
obj.modelMaterialNames = {};
% obj.maskStat = struct();    %%% TO DO
obj.maskImgFilename = NaN;
obj.modelExist = 0;
obj.maskExist = 0;
obj.hLabels = Labels();     % initialize labels class
obj.hMeasure = mibMeasure(obj);     % initialize measure class
obj.hROI = mibRoiRegion(obj);
obj.blockModeSwitch = 0;
obj.selectedMaterial = 1;   % index of the selected material in mibView.handles.mibSegmentationTable; 1-mask
obj.selectedAddToMaterial = 1; % index of the selected material for the Add to in mibView.handles.mibSegmentationTable; 1-mask
obj.selectedColorChannel = 1;   % selected color channel
obj.modelType = 63;     % set by default the model type to 63


if nargin < 4; disableSelection = 0; end
if nargin < 3;    meta = []; end
if nargin < 2
    obj.img{1} = imread('im_browser_dummy.jpg'); % dummy image
else
    obj.img{1} = img; % initialize with an image
end

if disableSelection == 0
    if obj.modelType == 255
        obj.maskImg{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8'); % bw filter data
        obj.selection{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8'); % selection mask image
        obj.model{1} = NaN; % model image
    elseif obj.modelType == 63
        obj.model{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8');
        obj.maskImg{1} = NaN;
        obj.selection{1} = NaN;
    elseif obj.modelType == 128
        obj.maskImg{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'int8'); %
        obj.selection{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8'); % selection mask image
        obj.model{1} = NaN; % model image
    end
else
    obj.selection = NaN;
    obj.model = NaN;
    obj.maskImg = NaN;
end

obj.height = size(obj.img{1}, 1);   % height of the dataset
obj.width = size(obj.img{1}, 2);    % width of the dataset
obj.depth = size(obj.img{1}, 4);    % number of stacks in the dataset
obj.colors = size(obj.img{1}, 3); % number of color channels
obj.time = size(obj.img{1}, 5);    % number of time points
obj.axesX = NaN;
obj.axesY = NaN;
obj.magFactor = 1;

% define pixel sizes
obj.pixSize.x = 1;
obj.pixSize.y = 1;
obj.pixSize.z = 1;
obj.pixSize.t = 1;
obj.pixSize.tunits = 's';
obj.pixSize.units = 'um';

R = [0 0 0];
S = [1*obj.magFactor,...
     1*obj.magFactor,...
     1*obj.pixSize.x/obj.pixSize.z*obj.magFactor];
T = [0 0 0];

obj.volren.show = 0;    % do not show the volume rendering
obj.volren.viewer_matrix = [];
obj.volren.previewImg = [];
obj.volren.showFullRes = 1;
obj.volren.viewer_matrix = makeViewMatrix(R, S, T);

% obj.bbox = [0, (max([obj.width 2])-1) * obj.pixSize.x,...   % max([obj.width 2]) - tweek for amira bounding box of a single layer
%             0, (max([obj.height 2])-1) * obj.pixSize.y,...
%             0, (max([obj.depth 2])-1) * obj.pixSize.z];

obj.orientation = 4;
obj.current_yxz = [1 1 1];

obj.viewPort.min = zeros([obj.colors, 1]);
obj.viewPort.max = zeros([obj.colors, 1]) + double(intmax(class(obj.img{1})));
obj.viewPort.gamma = zeros([obj.colors, 1]) + 1;
%obj.model_diff_max = 255;
%obj.trackerYXZ = [NaN;NaN;NaN];
obj.slices{1} = [1, size(obj.img{1},1)];   % height [min, max]
obj.slices{2} = [1, size(obj.img{1},2)];   % width [min, max]
obj.slices{3} = 1:size(obj.img{1},3);      % list of shown color channels [1, 2, 3, 4...]
obj.slices{4} = [1, 1];                 % z-values, [min, max]
obj.slices{5} = [1, 1];                 % time points, [min, max]

[SliceName{1:obj.depth}] = deal('none.tif');
keySet = {'ColorType','ImageDescription','Filename','SliceName', 'Height', 'Width', 'Depth', 'Colors', 'Time'};
valueSet = {'grayscale', sprintf('|'), 'none.tif', SliceName, obj.height, obj.width, obj.depth, obj.colors, obj.time};
if obj.colors > 1
    valueSet{1} = 'truecolor';
end
if isempty(meta)
    obj.meta = containers.Map(keySet, valueSet);
else
    Keys = keys(meta);
    Keys = [keySet, Keys];
    Values = values(meta);
    Values = [valueSet, Values];
    obj.meta = containers.Map(Keys, Values);
end

% add colors to the LUT color table
if obj.colors > size(obj.lutColors,1)
    for i=size(obj.lutColors,1)+1:obj.colors
        obj.lutColors(i,:) = [rand(1) rand(1) rand(1)];
    end
end

% modify filename for the mask
if isnan(obj.maskImgFilename) 
    pathStr = fileparts(obj.meta('Filename'));
    if ~isempty(pathStr)
        [pathStr, filenameStr] = fileparts(obj.meta('Filename'));
        obj.maskImgFilename = fullfile(pathStr, ['Mask_' filenameStr '.mask']);
    end
end

% extract lut colors from meta data
if isa(meta,'containers.Map')
    if isKey(meta, 'lutColors')
        if ischar(meta('lutColors')); meta('lutColors') = str2num(meta('lutColors')); end;
        obj.lutColors(1:size(meta('lutColors'),1), :) = meta('lutColors');
    end
end
obj.selectedROI = -1;

% 
% if nargin == 2
%     handles = obj.replaceDataset(obj.img{1}, handles);
% end
end