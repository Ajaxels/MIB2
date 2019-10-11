function imgOut = mibCrossShiftStack(imgIn, shiftsX, shiftsY, options)
% imgOut = mibCrossShiftStack(imgIn, shiftsX, shiftsY, options)
% Shift stack provided in imgIn using translation numbers in shiftX and
% shiftY
%
% Parameters:
% imgIn: a stack to shift: [1:height, 1:width, 1:color, 1:depth]
% shiftsX: a vector for X-shifts [1:depth]
% shiftsY: a vector for Y-shifts [1:depth]
% options: an optional structure with options
%  - .backgroundColor -> background color: 'black', 'white', 'mean', or a number
%  - .waitbar -> [optional] a handle to the opened waitbar
%
% Return values:
% imgOut: aligned stack

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

if nargin < 3
    errordlg(sprintf('!!! Error !!!\n\nThis function requires 3 parameters: image, shiftX and shiftY'));
    imgOut = [];
    return;
end

if isfield(options, 'waitbar') == 1
    wb = options.waitbar;
else
    wb = waitbar(0, sprintf('Aligning the images\nPlease wait'), 'Name', 'Align and drift correction', 'WindowStyle','modal');
end

% permute image to have it 4D
mode = '4D';
if ndims(imgIn) == 3
    mode = '3D';
    imgIn = permute(imgIn, [1 2 4 3]);
end

[height,width, color, depth] = size(imgIn);
minX = min(shiftsX);    % find minimal x shift for all stacks
minY = min(shiftsY);    % find minimal y shift for all stacks

maxX = max(shiftsX);    % find maximal x shift for all stacks
maxY = max(shiftsY);    % find maximal y shift for all stacks

% find how larger the dataset is going to be
deltaX = abs(minX) + maxX;
deltaY = abs(minY) + maxY;

if isnumeric(options.backgroundColor)
    imgOut = zeros([height+deltaY, width+deltaX, color, depth], class(imgIn))+options.backgroundColor;
else
    if strcmp(options.backgroundColor,'black')
        imgOut = zeros([height+deltaY, width+deltaX, color, depth], class(imgIn));
    elseif strcmp(options.backgroundColor,'white')
        imgOut = zeros([height+deltaY, width+deltaX, color, depth], class(imgIn)) + intmax(class(imgIn));
    else
        bgIntensity = mean(mean(mean(mean(imgIn))));
        imgOut = zeros([height+deltaY, width+deltaX, color, depth], class(imgIn)) + bgIntensity;
    end
end

for slice = 1:depth
    Xo = shiftsX(slice)-minX+1;
    Yo = shiftsY(slice)-minY+1;
    
    imgOut(Yo:Yo+height-1,Xo:Xo+width-1,:,slice) = imgIn(:,:,:,slice);
    waitbar(slice/depth, wb);
end

% permute dataset back to 3D mode if needed
if strcmp(mode, '3D')
    imgOut = squeeze(imgOut);
end
if ~isfield(options, 'waitbar')
    delete(wb);
end
%assignin('base', 'I2', imgOut);
end




