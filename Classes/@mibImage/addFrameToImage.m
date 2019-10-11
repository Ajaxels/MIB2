function BatchOpt = addFrameToImage(obj, BatchOpt)
% function BatchOpt = addFrameToImage(obj, BatchOpt)
% Add a frame around the dataset
% see also addFrame function
%
% Parameters:
% BatchOpt: an optional structure with parameters
% .Position - a cell string with position of the current image one of these options: {'Center', 'Left-upper corner', 'Right-upper corner', 'Left-bottom corner','Right-bottom corner'};
% .NewImageWidth - a string with new image width in pixels
% .NewImageHeight - a string with new image height in pixels
% .FrameColorIntensity - a string with new image frame color intensity
% .showWaitbar - logical, show or not the waitbar
%
% Return values:
% BatchOpt: structure with parameters

%|
% @b Examples
% @code 
% BatchOpt = obj.mibModel.I{obj.mibModel.Id}.addFrameToImage();  // call from mibController; add a frame; parameters of the frame will be prompted
% @endcode

% Copyright (C) 13.12.2018, Ilya Belevich (ilya.belevich -at- helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 12.03.2019, IB updated for the batch mode

global mibPath;

if obj.Virtual.virtual == 1
    errordlg('Not yet implemented!');
    return;
end
getDataOpt.blockModeSwitch = 0;
[height, width, colors, depth, time] = obj.getDatasetDimensions('image', NaN, 0, getDataOpt);

if nargin < 2 || ~isfield(BatchOpt, 'Position') || ~isfield(BatchOpt, 'NewImageWidth') || ~isfield(BatchOpt, 'NewImageHeight') || ~isfield(BatchOpt, 'FrameColorIntensity') 
    options = struct(); 
    prompts = {'Position of the image:'; 'New image width:'; 'New image height:'; 'Frame color intensity:'};
    defAns = {{'Center', 'Left-upper corner', 'Right-upper corner', 'Left-bottom corner','Right-bottom corner', 1}; num2str(width); num2str(height); '0'};
    dlgTitle = 'Add frame to the image';
    options.WindowStyle = 'normal';       % [optional] style of the window
    options.PromptLines = [1, 1, 1, 1];   % [optional] number of lines for widget titles
    options.Focus = 1;      % [optional] define index of the widget to get focus
    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); return; end 
    
    BatchOpt.Position = answer(1);
    BatchOpt.NewImageWidth = answer{2};
    BatchOpt.NewImageHeight = answer{3};
    frameColor = min([str2double(answer{4}) obj.meta('MaxInt')]);
    frameColor = max([frameColor 0]);
    BatchOpt.FrameColorIntensity = num2str(frameColor);
    BatchOpt.showWaitbar = true;
end

newWidth = str2double(BatchOpt.NewImageWidth);
newHeight = str2double(BatchOpt.NewImageHeight);
frameColor = str2double(BatchOpt.FrameColorIntensity);

if newWidth < width || newHeight < height
    errordlg(sprintf('!!! Error !!!\n\nThe new width and height should be larger than the current width and height!'), 'Wrong dimensions', 'modal');
    return;
end

switch BatchOpt.Position{1}
    case 'Center'
        leftFrame = round((newWidth-width)/2);
        rightFrame = newWidth - width - leftFrame;
        topFrame = round((newHeight-height)/2);
        bottomFrame = newHeight - height - topFrame;
    case 'Left-upper corner'
        leftFrame = 0;
        rightFrame = newWidth - width;
        topFrame = 0;
        bottomFrame = newHeight - height;
    case 'Right-upper corner'
        leftFrame = newWidth - width;
        rightFrame = 0;
        topFrame = 0;
        bottomFrame = newHeight - height;
    case 'Left-bottom corner'
        leftFrame = 0;
        rightFrame = newWidth - width;
        topFrame = newHeight - height;
        bottomFrame = 0;
    case 'Right-bottom corner'
        leftFrame = newWidth - width;
        rightFrame = 0;
        topFrame = newHeight - height;
        bottomFrame = 0;
end
   
newWidth = width + leftFrame + rightFrame;
newHeight = height + topFrame + bottomFrame;

x1 = leftFrame + 1;
x2 = newWidth - rightFrame;
y1 = topFrame + 1;
y2 = newHeight - bottomFrame;

if BatchOpt.showWaitbar; wb = waitbar(0,'Please wait...', 'Name', 'Adding a frame...'); end

cImg = obj.img{1};
obj.img{1} = zeros([newHeight, newWidth, numel(colors), depth, time], obj.meta('imgClass')) + frameColor;   %#ok<ZEROLIKE> % allocate space
obj.img{1}(y1:y2,x1:x2,:,:,:) = cImg;
if BatchOpt.showWaitbar; waitbar(.4, wb); end
if obj.modelType ~= 63
    if obj.modelExist % crop model
        cImg = obj.model{1};
        obj.model{1} = zeros([newHeight, newWidth, depth, time], 'uint8');  
        obj.model{1}(y1:y2,x1:x2,:,:) = cImg;
    end
    if BatchOpt.showWaitbar; waitbar(.5, wb); end
    if ~isnan(obj.maskImg{1}(1))    % crop mask
        cImg = obj.maskImg{1};
        obj.maskImg{1} = zeros([newHeight, newWidth, depth, time], 'uint8');  
        obj.maskImg{1}(y1:y2,x1:x2,:,:) = cImg;
    end
    if BatchOpt.showWaitbar; waitbar(.6, wb); end
    if  ~isnan(obj.selection{1}(1))
        cImg = obj.selection{1};
        obj.selection{1} = zeros([newHeight, newWidth, depth, time], 'uint8');  
        obj.selection{1}(y1:y2,x1:x2,:,:) = cImg;
    end
elseif ~isnan(obj.model{1}(1))     % crop model/selectio/mask layer
    cImg = obj.model{1};
    obj.model{1} = zeros([newHeight, newWidth, depth, time], 'uint8');  
    obj.model{1}(y1:y2,x1:x2,:,:) = cImg;
end
if BatchOpt.showWaitbar; waitbar(.8, wb); end

obj.height = newHeight;
obj.width = newWidth;

if obj.height < obj.current_yxz(1); obj.current_yxz(1) = obj.height; end
if obj.width < obj.current_yxz(2); obj.current_yxz(2) = obj.width; end

obj.meta('Height') = newHeight;
obj.meta('Width') = newWidth;
obj.dim_yxczt = [obj.meta('Height'), obj.meta('Width'), obj.dim_yxczt(3), obj.meta('Depth'), obj.meta('Time')];

% update obj.slices
current_layer = obj.slices{obj.orientation}(1);
obj.slices{1} = [1, obj.height];
obj.slices{2} = [1, obj.width];
obj.slices{obj.orientation} = [min([obj.dim_yxczt(obj.orientation) current_layer]), min([obj.dim_yxczt(obj.orientation) current_layer])];

xyzShift = [(leftFrame-1)*obj.pixSize.x (topFrame-1)*obj.pixSize.y 0];
% update BoundingBox Coordinates
obj.updateBoundingBox(NaN, xyzShift);
if BatchOpt.showWaitbar; waitbar(9, wb); end

crop_factor = [-leftFrame+1, -topFrame+1, NaN, NaN, 1, NaN, 1, NaN];
obj.hROI.crop(crop_factor);
obj.hLabels.crop(crop_factor);

% update the log
log_text = sprintf('AddFrame: [left right top bottom]: %d %d %d %d; color=%d', ...
    leftFrame, rightFrame, topFrame, bottomFrame, frameColor);
obj.updateImgInfo(log_text);

if BatchOpt.showWaitbar
    waitbar(1, wb); 
    delete(wb); 
end

end