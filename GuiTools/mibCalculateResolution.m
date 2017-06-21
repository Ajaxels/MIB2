function resolution = mibCalculateResolution(pixSize)
% function resolution = ib_calculateResolution(pixSize)
% Calculate image resolution in Inch as default for saving tifs
% 
% Parameters:
% pixSize: a structure with voxel physical dimensions, the three following
% fields are used:
% - .x - physical width of the pixel
% - .y - physical height of the pixel
% - .units - physical units: ''m'', ''cm'', ''mm'', ''um'', ''nm''
% 
% Return values:
% resolution: a vector [XResolution, YResolution] in Pixels/Inch

% Copyright (C) 21.11.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

switch pixSize.units
    case 'm'
        resolution(1) = 1/pixSize.x*1*0.0254;
        resolution(2) = 1/pixSize.y*1*0.0254;
    case 'cm'
        resolution(1) = 1/pixSize.x*1e2*0.0254;
        resolution(2) = 1/pixSize.y*1e2*0.0254;
    case 'mm'
        resolution(1) = 1/pixSize.x*1e3*0.0254;
        resolution(2) = 1/pixSize.y*1e3*0.0254;
    case 'um'
        resolution(1) = 1/pixSize.x*1e6*0.0254;
        resolution(2) = 1/pixSize.y*1e6*0.0254;
    case 'nm'
        resolution(1) = 1/pixSize.x*1e9*0.0254;
        resolution(2) = 1/pixSize.y*1e9*0.0254;
    otherwise
        resolution(1) = 72;
        resolution(2) = 72;
end
end