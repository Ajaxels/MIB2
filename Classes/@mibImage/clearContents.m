function clearContents(obj, img, metaIn, disableSelection)
% function clearContents(obj, img, metaIn, disableSelection)
% Set all elements of the class to default values
%
% Parameters:
% img: @b [optional], image to use to initialize the imageData class
% metaIn: @b [optional], 'containers'.'Map' class with parameters of the dataset, can be @e []
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
obj.maskImgFilename = [];
obj.modelExist = 0;
obj.maskExist = 0;
obj.hLabels = Labels();     % initialize labels class
obj.hMeasure = mibMeasure(obj);     % initialize measure class
obj.hROI = mibRoiRegion(obj);
obj.hLines3D = Lines3D();     % initialize Lines3D class
obj.blockModeSwitch = 0;
obj.selectedMaterial = 1;   % index of the selected material in mibView.handles.mibSegmentationTable; 1-mask
obj.fixSelectionToMask = 0;  % unselect fix selection to mask
obj.fixSelectionToMaterial = 0;  % unselect fix selection to material
obj.selectedAddToMaterial = 1; % index of the selected material for the Add to in mibView.handles.mibSegmentationTable; 1-mask
obj.selectedColorChannel = 1;   % selected color channel
obj.modelType = 63;     % set by default the model type to 63
obj.useLUT = 0;
obj.lastSegmSelection = [2 1];  % last selected contours for use with the 'e' button of mibController

if isempty(obj.Virtual); obj.Virtual.virtual = 0; end   % define default mode to non-virtual

if nargin < 4; disableSelection = 0; end
if nargin < 3; metaIn = containers.Map(); end
if nargin < 2; img = []; end

if isempty(metaIn)
    meta = containers.Map(); 
else
    % create a copy of meta, otherwise the handle is copied
    meta = containers.Map(keys(metaIn), values(metaIn));
end

if isempty(img)
    if obj.Virtual.virtual == 0
        obj.img{1} = imread('im_browser_dummy.jpg'); % dummy image
    else
        obj.closeVirtualDataset();    % close open bio-format readers, otherwise the files locked
        obj.img{1} = 'im_browser_dummy.h5'; % dummy image
    end
else
    if isa(img, 'double') || isa(img, 'single')
        % find maximal value
        maxVal = max(img(:));
        if maxVal < 256
            img = uint8(img);   % convert to 8bit
            fprintf('MIB: image was converted to 8bit\n');
        elseif maxVal < 65536
            img = uint16(img);   % convert to 16bit 
            fprintf('MIB: image was converted to 16bit\n');
        elseif maxVal < 4294967296
            img = uint32(img);   % convert to 32bit
            fprintf('MIB: image was converted to 32bit\n');
        else
            errordlg(sprintf('!!! Wrong data type !!!\n\nThis dataset is not compatible with MIB'));
            return;
        end
    end
    obj.closeVirtualDataset();    % close open bio-format readers, otherwise the files locked
        
    if ~iscell(img)
        obj.img{1} = img; % initialize with an image
    else
        obj.img = img;
    end
end
obj.disableSelection = disableSelection;

% disable selection for virtual stacks
if obj.Virtual.virtual == 1;  obj.disableSelection = 1;  end

% allocate memory for service layers
if obj.disableSelection == 0
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
    obj.selection{1} = NaN;
    obj.model{1} = NaN;
    obj.maskImg{1} = NaN;
end

obj.axesX = NaN;
obj.axesY = NaN;
obj.magFactor = 1;
obj.selectedROI = -1;

% allocate slices
obj.slices{1} = [1, 1];
obj.slices{2} = [1, 1];
obj.slices{3} = 1;
obj.slices{4} = [1, 1];
obj.slices{5} = [1 1];

obj.orientation = 4;
obj.current_yxz = [1 1 1];

% update obj.meta and class variables
obj.updateServiceMetadata(meta);

% 
% if nargin == 2
%     handles = obj.replaceDataset(obj.img{1}, handles);
% end
end