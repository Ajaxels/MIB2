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

function pixSize = mibCalculatePixSizes(resolution, unitFrom, unitTo)
% function pixSize = mibCalculatePixSizes(resolution, unitFrom, unitTo)
% Recalculate pixel size (width, height) of the dataset to new units
%
% Parameters:
% resolution: a vector with current resolution of the dataset [XResolution, YResolution]
% unitFrom: source units - ''m'', ''cm'', ''mm'', ''um'', ''nm''
% unitTo: desired units - ''Inch'', ''Centimeter'', ''Meter''
%
% Return values:
% pixSize: a structure with voxel sizes, the two fields are updated,
% .x - physical width of the pixel
% .y - physical height of the pixel

% Updates
% 

switch unitFrom     % get coef for conversion to meters
    case 'Inch'
        coef = 1/.0254;
    case 'Centimeter'
        coef = 1e2;
    case 'Meter'
        coef = 1;
    otherwise
        coef = 1;
end
% calculate pixel sizes in program units
switch unitTo
    case 'm'
        pixSize.x = 1/(resolution(1)*coef);
        pixSize.y = 1/(resolution(2)*coef);
    case 'cm'
        pixSize.x = 1e2/(resolution(1)*coef);
        pixSize.y = 1e2/(resolution(2)*coef);
    case 'mm'
        pixSize.x = 1e3/(resolution(1)*coef);
        pixSize.y = 1e3/(resolution(2)*coef);
    case 'um'
        pixSize.x = 1e6/(resolution(1)*coef);
        pixSize.y = 1e6/(resolution(2)*coef);
    case 'nm'
        pixSize.x = 1e9/(resolution(1)*coef);
        pixSize.y = 1e9/(resolution(2)*coef);
end
end
