% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

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