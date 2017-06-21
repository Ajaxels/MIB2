function [xOut, yOut] = convertDataToMouseCoordinates(obj, x, y, mode, magFactor)
% function [xOut, yOut] = convertDataToMouseCoordinates(obj, x, y, mode, magFactor)
% Convert coordinates of a pixel in the dataset to the coordinates of the mibView.handles.mibImageView axes
%
% Parameters:
% x: x - coordinate
% y: y - coordinate
% mode: a string that defines a mode of the shown image: 'shown' (in most cases), or 'full' (for panning)
% magFactor: [@em optional], used to force magFactor, @em default obj.I.{obj.Id}.magFactor
%
% Return values:
% xOut: x - coordinate with the dataset
% yOut: y - coordinate with the dataset


%| 
% @b Examples:
% @code [xOut,yOut] = obj.convertDataToMouseCoordinates(x, y);  // Call from mibModel: do conversion' @endcode

% Copyright (C) 08.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

if nargin < 5
    magFactor = obj.getMagFactor();
end
[axesX, axesY] = obj.getAxesLimits();
if strcmp(mode, 'shown')
    xOut = (x-max([floor(axesX(1)) 0]))/magFactor;
    yOut = (y-max([floor(axesY(1)) 0]))/magFactor;
else
    xOut = x/max([1 magFactor]);
    yOut = y/max([1 magFactor]);
end
end