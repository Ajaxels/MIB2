function result = addFrameToImage(obj, options)
% function result = addFrameToImage(obj, options)
% Add a frame around the dataset
% see also mibModel.addFrame function
%
% Parameters:
% options: an optional structure with parameters
%
% Return values:
% result: status of the operation, 1-success, 0-cancel
% .leftFrame - number of pixels, left margin
% .rightFrame - number of pixels, right margin
% .topFrame - number of pixels, top margin
% .bottomFrame - number of pixels, bottom margin
% .frameColor - a number with the frame color
%| 
% @b Examples:
% @code 
% @code obj.mibModel.I{obj.mibModel.Id}.addFrameToImage();  // call from mibController; add a frame; parameters of the frame will be prompted @endcode

% Copyright (C) 13.12.2018, Ilya Belevich (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;

if obj.Virtual.virtual == 1
    errordlg('Not yet implemented!');
    return;
end
options.blockModeSwitch = 0;
[height, width, colors, depth, time] = obj.getDatasetDimensions('image', NaN, 0, options);

if nargin < 2
    options = struct(); 
    prompts = {'Position of the image:'; 'New image width:'; 'New image height:'; 'Frame color intensity:'};
    defAns = {{'Center', 'Left-upper corner', 'Right-upper corner', 'Left-bottom corner','Right-bottom corner', 1}; num2str(width); num2str(height); '0'};
    dlgTitle = 'Add frame to the image';
    options.WindowStyle = 'normal';       % [optional] style of the window
    options.PromptLines = [1, 1, 1, 1];   % [optional] number of lines for widget titles
    options.Focus = 1;      % [optional] define index of the widget to get focus
    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); return; end 
    
    newWidth = str2double(answer{2});
    newHeight = str2double(answer{3});
    options.frameColor = min([str2double(answer{4}) obj.meta('MaxInt')]);
    options.frameColor = max([options.frameColor 0]);
    
    if newWidth < width || newHeight < height
        errordlg(sprintf('!!! Error !!!\n\nThe new width and height should be larger than the current width and height!'), 'Wrong dimensions', 'modal');
        return;
    end
    switch answer{1}
        case 'Center'
            options.leftFrame = round((newWidth-width)/2);
            options.rightFrame = newWidth - width - options.leftFrame;
            options.topFrame = round((newHeight-height)/2);
            options.bottomFrame = newHeight - height - options.topFrame;
        case 'Left-upper corner'
            options.leftFrame = 0;
            options.rightFrame = newWidth - width;
            options.topFrame = 0;
            options.bottomFrame = newHeight - height;
        case 'Right-upper corner'
            options.leftFrame = newWidth - width;
            options.rightFrame = 0;
            options.topFrame = 0;
            options.bottomFrame = newHeight - height;
        case 'Left-bottom corner'
            options.leftFrame = 0;
            options.rightFrame = newWidth - width;
            options.topFrame = newHeight - height;
            options.bottomFrame = 0;
        case 'Right-bottom corner'
            options.leftFrame = newWidth - width;
            options.rightFrame = 0;
            options.topFrame = newHeight - height;
            options.bottomFrame = 0;
    end
end

if ~isfield(options, 'leftFrame'); options.leftFrame = 0; end
if ~isfield(options, 'rightFrame'); options.rightFrame = 0; end
if ~isfield(options, 'topFrame'); options.topFrame = 0; end
if ~isfield(options, 'bottomFrame'); options.bottomFrame = 0; end
if ~isfield(options, 'frameColor'); options.frameColor = 0; end
    
newWidth = width + options.leftFrame + options.rightFrame;
newHeight = height + options.topFrame + options.bottomFrame;

x1 = options.leftFrame + 1;
x2 = newWidth - options.rightFrame;
y1 = options.topFrame + 1;
y2 = newHeight - options.bottomFrame;

result = 0;
wb = waitbar(0,'Please wait...', 'Name', 'Adding a frame...');

cImg = obj.img{1};
obj.img{1} = zeros([newHeight, newWidth, numel(colors), depth, time], obj.meta('imgClass')) + options.frameColor;   %#ok<ZEROLIKE> % allocate space
obj.img{1}(y1:y2,x1:x2,:,:,:) = cImg;
waitbar(.4, wb);
if obj.modelType ~= 63
    if obj.modelExist % crop model
        cImg = obj.model{1};
        obj.model{1} = zeros([newHeight, newWidth, depth, time], 'uint8');  
        obj.model{1}(y1:y2,x1:x2,:,:) = cImg;
    end
    waitbar(.5, wb);
    if ~isnan(obj.maskImg{1}(1))    % crop mask
        cImg = obj.maskImg{1};
        obj.maskImg{1} = zeros([newHeight, newWidth, depth, time], 'uint8');  
        obj.maskImg{1}(y1:y2,x1:x2,:,:) = cImg;
    end
    waitbar(.6, wb);
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
waitbar(.8, wb);

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

xyzShift = [(options.leftFrame-1)*obj.pixSize.x (options.topFrame-1)*obj.pixSize.y 0];
% update BoundingBox Coordinates
obj.updateBoundingBox(NaN, xyzShift);
waitbar(9, wb);

crop_factor = [-options.leftFrame+1, -options.topFrame+1, NaN, NaN, 1, NaN, 1, NaN];
obj.hROI.crop(crop_factor);
obj.hLabels.crop(crop_factor);

% update the log
log_text = sprintf('AddFrame: [left right top bottom]: %d %d %d %d; color=%d', ...
    options.leftFrame, options.rightFrame, options.topFrame, options.bottomFrame, options.frameColor);
obj.updateImgInfo(log_text);

waitbar(1, wb);
delete(wb);
result = 1;
end