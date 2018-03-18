function I = mibAddScaleBar(I, pixSize, scale, Options)
% I = mibAddScaleBar(I, pixSize, scale, orientation, scaleBarHeight)
% add a scale bar to the image.
% Requires insertText and insertMarker functions from the Computer Vision System
% Toolbox. When these functions are not available is using an old function.
%
% Parameters:
% I:    RGB image that requires the scale bar
% pixSize:  a structure with pixel size of the image, .x, .y, .z
% scale: scaling factor, i.e. how the pixel size is different from the pixSize structure   
% Options: an optional structure with additional settings
%  .orientation - orientation of the snapshot: 1, 2, 4 (default)
%  .scaleBarHeight - height of the scale bar in pixels, minimal height is 22 pixels, default = []
%  .bgColor - background color, a single number from 0 (black) to 1 (while), default = 0

%| 
% @b Examples:
% @code I = mibAddScaleBar(I, pixSize, scale);      // add scalebar @endcode

% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 13.11.2017, fix of wrong scale size when using the YZ, XZ orientations
% 27.01.2018, updated to use insertImage function of Matlab
% 20.02.2018, added background color and modified the syntax

global DejaVuSansMono;

if nargin < 4; Options = struct(); end
if ~isfield(Options, 'orientation'); Options.orientation = 4; end
if ~isfield(Options, 'scaleBarHeight'); Options.scaleBarHeight = []; end
if ~isfield(Options, 'bgColor'); Options.bgColor = 0; end
scaleBarHeight = Options.scaleBarHeight;

if Options.orientation == 4
    pixelSize = pixSize.x/scale;
elseif Options.orientation == 1
    pixelSize = pixSize.z/scale;
elseif Options.orientation == 2
    pixelSize = pixSize.z/scale;
end

width = size(I,2);
height = size(I,1);
if isempty(scaleBarHeight)
    scaleBarHeight = 22*ceil(min([width height])/600);
else
    if scaleBarHeight < 22
        msgbox(sprintf('The height of the scale bar should be at least 22 pixels'), 'Scale bar', 'error');
        return;
    end
end
resizeFactor = scaleBarHeight/22;    

targetStep = width*pixelSize/10;  % targeted length of the scale bar in units
mag = floor(log10(targetStep));     % magnitude of the scale bar
magPow = power(10, mag);
magDigit = floor(targetStep/magPow + 0.5);
roundStep = magDigit*magPow;    % rounded step
if mag < 0
    strText = ['scaleBarText = sprintf(''%.' num2str(abs(mag)) 'f %s'', roundStep, pixSize.units);'];
    eval(strText);
else
    scaleBarText = sprintf('%d %s', roundStep, pixSize.units);
end
scaleBarLength = round(roundStep/pixelSize);

ColorsNumber = size(I, 3);
shiftX = 5;     % shift of the scale bar from the left corner
max_int = double(intmax(class(I)));
bgColor = round(Options.bgColor*max_int);  % background color
fgColor = round((1-Options.bgColor)*max_int); % foreground color

if scaleBarLength+shiftX*2+(numel(scaleBarText)*12*resizeFactor) > width
    msgbox(sprintf('Image is too small to put the scale bar!\nSaving image without the scale bar...'),'Scale bar','warn');
    return;
end

scaleBarSectionHeight = 22;
model = zeros(scaleBarSectionHeight, size(I,2), size(I,3), class(I))+bgColor;

% add scale
model(10:12, shiftX:shiftX+scaleBarLength-1,:) = repmat(fgColor, [3, scaleBarLength, ColorsNumber]);
model(8:14, shiftX,:) = repmat(fgColor, [7, 1, ColorsNumber]);
model(8:14, shiftX+scaleBarLength-1,:) = repmat(fgColor, [7, 1, ColorsNumber]);

if isempty(DejaVuSansMono)
    % resize the scale bar
    if resizeFactor > 1
        model1 = model(:, 1:scaleBarLength+shiftX*2, :);    % crop the scale bar
        model1 = imresize(model1, [scaleBarHeight size(model1,2)], 'nearest');
        scaleBarLength = size(model1, 2);

        model = zeros(scaleBarHeight,  size(I,2), size(I,3), class(I))+bgColor;
        model(:, round(shiftX*resizeFactor):round(shiftX*resizeFactor)+size(model1,2)-1,:) = model1;
    end
    scaleBarText = strrep(scaleBarText, 'u', char(956));    % replace u sign
    model = insertText(model, [scaleBarLength+10*resizeFactor, round(scaleBarHeight/2)], scaleBarText, 'FontSize', round(15*resizeFactor), ...
        'BoxOpacity',0, 'TextColor', [fgColor, fgColor, fgColor], 'AnchorPoint', 'LeftCenter');
else
    options.color = [fgColor, fgColor, fgColor];
    %options.fontSize = min([round(15*resizeFactor) 7]); %9 10 13 13 16 18 20
    options.fontSize = 7;
    options.markerText = 'text';
    model = mibAddText2Img_Legacy(model, scaleBarText, [scaleBarLength+10*resizeFactor, 1], [], options);
    if resizeFactor > 1
        dx = scaleBarLength+10*resizeFactor;
        labelImage = imresize(model(:, dx:dx+numel(scaleBarText)+numel(scaleBarText)*12,:), resizeFactor, 'nearest');
                
        model1 = model(:, 1:scaleBarLength+shiftX*2, :);    % crop the scale bar
        model1 = imresize(model1, [scaleBarHeight size(model1,2)], 'nearest');
        scaleBarLength = size(model1, 2);
        
        model = zeros(scaleBarHeight,  size(I,2), size(I,3), class(I))+bgColor;
        model(:, round(shiftX*resizeFactor):round(shiftX*resizeFactor)+size(model1,2)-1,:) = model1;
        dx = scaleBarLength+10*resizeFactor;
        model(:, dx:dx+size(labelImage,2)-1,:) = labelImage;
    end
end

I = cat(1, I, model);
end