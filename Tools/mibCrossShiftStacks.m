function [imgOut, bbShiftXY] = mibCrossShiftStacks(I1, I2, shiftX, shiftY, options)
% [imgOut, bbShiftXY] = mibCrossShiftStacks(I1, I2, shiftX, shiftY)
% Shift I2 vs I1 using translation numbers in shiftX and
% shiftY
%
% Parameters:
% I1: a reference stack: [1:height, 1:width, 1:color, 1:depth]
% I2: a second stack to shift over I2: [1:height, 1:width, 1:color, 1:depth]
% shiftX: a value for the X-shift
% shiftY: a value for the Y-shift
% options: an optional structure with options
%  - .backgroundColor -> background color: 'black', 'white', 'mean', or a number
%  - .waitbar -> [optional] a handle to existing waitbar
%  - .modelSwitch -> 1-defines that dataset has 3 dimensions
%       [H,W,Z], or when 0 - 4 dimensions [H,W,C,Z]
%
% Return values:
% imgOut: aligned stack
% bbShiftXY: a vector [xMin, yMin] with shift of the reference dataset

% Copyright (C) 30.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
%
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

bbShiftXY = [0, 0];

if nargin < 4
    errordlg(sprintf('!!! Error !!!\n\nThis function requires 4 parameters: image1, image2, shiftX and shiftY'));
    imgOut = [];
    return;
end

% detect type of the inpuit data
if ndims(I1) ~= ndims(I2) && ndims(I1) ~= 2 && ndims(I2) ~= 2
    msgbox('Datasets dimensions mismatch!','Error','err');
    imgOut = [];
    return;
end

if ~isfield(options, 'backgroundColor'); options.backgroundColor='black'; end
if ~isfield(options, 'modelSwitch'); options.modelSwitch = 0; end

if isfield(options, 'waitbar')
    wb = options.waitbar;
else
    wb = waitbar(0, sprintf('Aligning the images\nPlease wait'), 'Name', 'Align and drift correction', 'WindowStyle','modal');
end

% permute image to have it 4D
if options.modelSwitch == 1
    I1 = permute(I1, [1 2 4 3]);
    I2 = permute(I2, [1 2 4 3]);
end

[height1, width1, color1, depth1] = size(I1);
[height2, width2, color2, depth2] = size(I2);
depth = depth1 + depth2;
color = max([color1, color2]);

% allocate space for the output
if isnumeric(options.backgroundColor)
    backgroundColor = options.backgroundColor;
else
    if strcmp(options.backgroundColor,'black')
        backgroundColor = 0;
    elseif strcmp(options.backgroundColor,'white')
        backgroundColor = intmax(class(I1));
    else
        backgroundColor = mean(mean(mean(mean(I1))));
    end
end


if shiftX <= 0
    bbShiftXY(1) = shiftX;
    if shiftY >= 0     % the second dataset is shifted to towards the lower left corner
        imgOut = zeros(max([height1 shiftY+height2]),max([width2 abs(shiftX)+width1]), max([color1 color2]), depth1+depth2,class(I1))+backgroundColor;
        imgOut(1:height1,1+abs(shiftX):1+abs(shiftX)+width1-1,1:color1,1:depth1) = I1;
        imgOut(1+shiftY:1+shiftY+height2-1,1:width2,1:color2,depth1+1:depth1+depth2) = I2;
    else            % the second dataset is shifted to towards the upper left corner, !!! not checked
        bbShiftXY(2) = shiftY;
        imgOut = zeros(max([abs(shiftY)+height1 height2]), max([abs(shiftX)+width1 width2]), max([color1 color2]), depth1+depth2,class(I1))+backgroundColor;
        imgOut(1+abs(shiftY):1+abs(shiftY)+height1-1,1+abs(shiftX):1+abs(shiftX)+width1-1,1:color1,1:depth1) = I1;
        imgOut(1:height2,1:width2,1:color2,depth1+1:depth1+depth2) = I2;
    end
else
    if shiftY >= 0     % the second dataset is shifted to towards the lower right corner
        imgOut = zeros(max([height1 shiftY+height2]), max([width1 abs(shiftX)+width2]), max([color1 color2]), depth1+depth2,class(I1))+backgroundColor;
        imgOut(1:height1,1:width1,1:color1,1:depth1) = I1;
        imgOut(1+shiftY:1+shiftY+height2-1,1+abs(shiftX):1+abs(shiftX)+width2-1,1:color2,depth1+1:depth1+depth2) = I2;
    else            % the second dataset is shifted to towards the upper right corner, !!! not checked
        bbShiftXY(2) = shiftY;
        imgOut = zeros(max([height2 abs(shiftY)+height1]), max([width1 abs(shiftX)+width2]), max([color1 color2]), depth1+depth2,class(I1))+backgroundColor;
        imgOut(1+abs(shiftY):1+abs(shiftY)+height1-1,1:width1,1:color1,1:depth1) = I1;
        imgOut(1:height2,1+abs(shiftX):1+abs(shiftX)+width2-1,1:color2,depth1+1:depth1+depth2) = I2;
    end
end

% 
% % allocate space for the output
% if isnumeric(options.backgroundColor)
%     imgOut = zeros(height1+abs(shiftY), width1+abs(shiftX), color, depth, class(I1))+options.backgroundColor;
% else
%     if strcmp(options.backgroundColor,'black')
%         imgOut = zeros(height1+abs(shiftY), width1+abs(shiftX), color, depth, class(I1));
%     elseif strcmp(options.backgroundColor,'white')
%         imgOut = zeros(height1+abs(shiftY), width1+abs(shiftX), color, depth, class(I1))+intmax(class(I1));
%     else
%         bgIntensity = mean(mean(mean(mean(I1))));
%         imgOut = zeros(height1+abs(shiftY), width1+abs(shiftX), color, depth, class(I1))+bgIntensity;
%     end
% end
% 
% Xo = - min([0, shiftX]) +1;
% Yo = - min([0, shiftY]) +1;
% imgOut(Yo:Yo+height1-1,Xo:Xo+width1-1,1:color1,1:depth1) = I1;
% 
% Xo = shiftX - min([0, shiftX]) +1;
% Yo = shiftY - min([0, shiftY]) +1;
% imgOut(Yo:Yo+height2-1,Xo:Xo+width2-1,1:color2,depth1+1:end) = I2;
   
% permute dataset back to 3D mode if needed
if options.modelSwitch == 1
    imgOut = squeeze(imgOut);
end
if ~isfield(options, 'waitbar')
    delete(wb);
end
%assignin('base', 'I2', imgOut);
end

