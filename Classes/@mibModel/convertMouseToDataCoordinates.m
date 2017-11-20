function [xOut, yOut, zOut, tOut] = convertMouseToDataCoordinates(obj, x, y, mode, permuteSw)
% function [xOut, yOut, zOut, tOut] = convertMouseToDataCoordinates(obj, x, y, mode, permuteSw)
% Convert coordinates under the mouse cursor to the coordinates of the dataset
%
% Parameters:
% x: x - coordinate
% y: y - coordinate
% mode:  [@em optional] a string that defines a mode of the shown image, @b default is 'shown'
% @li 'shown' - the most common one, convert coordinates of the mouse
% above the image to the coordinates of the dataset
% @li 'full' - suppose to do the conversion for the situation when the full
% image is rendered in the handles.imageAxes, never used...?
% @li 'blockmode' - when the blockface mode is switched on the function
% returns coordinates under the mouse for the Block
% permuteSw: [@em optional], can be @em empty
% @li when @b 0 returns the coordinates for the dataset in the original xy-orientation;
% @li when @b 1 (@b default) returns coordinates for the dataset so that the currently selected orientation becomes @b xy
%
% Return values:
% xOut: x - coordinate with the dataset
% yOut: y - coordinate with the dataset
% zOut: z - coordinate with the dataset
% tOut: t - time coordinate

%| 
% @b Examples:
% @code [xOut, yOut] = obj.convertMouseToDataCoordinates(x, y);  // Call from mibModel: do conversion' @endcode

% Copyright (C) 08.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 


if nargin < 5; permuteSw = 1; end
if nargin < 4; mode = 'shown'; end

magFactor = obj.getMagFactor();
[axesX, axesY] = obj.getAxesLimits();

if strcmp(mode, 'shown')
    % used in im_browser_winMouseMotionFcn, toolbar_zoomBtn
    xOut = x*magFactor + max([0 floor(axesX(1))]);
    yOut = y*magFactor + max([0 floor(axesY(1))]);
elseif strcmp(mode, 'blockmode')    
    xOut = x*magFactor;
    yOut = y*magFactor;
else
    %sprintf('Mag=%f, x1=%f, axexX=%f\n',magFactor, x(1), axesX(1))
    xOut = (x*magFactor +  max([0 axesX(1)]))/max([1 magFactor]);
    yOut = (y*magFactor +  max([0 axesY(1)]))/max([1 magFactor]);
    
%     if magFactor < 1
%         xOut = x*magFactor +  max([0 axesX(1)]);
%         yOut = y*magFactor +  max([0 axesY(1)]);
%     else
%         xOut = (x*magFactor +  max([0 axesX(1)]))/magFactor;
%         yOut = (y*magFactor +  max([0 axesY(1)]))/magFactor;
%     end
end

zOut = zeros(size(xOut,1)) + obj.I{obj.Id}.getCurrentSliceNumber();
% generate zOut coordinates
if permuteSw == 0
    tempX = xOut;
    tempY = yOut;
    tempZ = zOut;
    if obj.I{obj.Id}.orientation == 1    % zx
        xOut = tempY;
        yOut = tempZ;
        zOut = tempX;
    elseif obj.I{obj.Id}.orientation == 2 % zy
        xOut = tempZ;
        yOut = tempY;
        zOut = tempX;
    end
end
tOut = obj.I{obj.Id}.slices{5}(1);
end