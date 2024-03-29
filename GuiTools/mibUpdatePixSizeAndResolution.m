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

function [img_info, pixSize] = mibUpdatePixSizeAndResolution(img_info, pixSize)
% function [img_info, pixSize] = mibUpdatePixSizeAndResolution(img_info, pixSize)
% Calculate update resolution fields in the imageData.img_info('ImageDescription') or recalculate physical size of voxels
%
% - If 'BoundingBox' information exist in the imageData.img_info('ImageDescription') the function recalculates the
% imageData.pixSize based on information from the BoundingBox.
% - If 'BoundingBox' is missing, but imageData.img_info('XResolution') is present the imageData.pixSize recalculated based
% on XResolution and YResolution information
% - If both 'BoundingBox' and 'XResolution' is missing, the resolution is recalculated based on imageData.pixSize
%
% Parameters:
% img_info: information about the dataset, an instance of the 'containers'.'Map' class
% pixSize: a structure (imageData.pixSize) with diminsions of voxels, @code .x .y .z .t .tunits .units @endcode
% the fields are
% @li .x - physical width of a pixel
% @li .y - physical height of a pixel
% @li .z - physical depthness of a pixel
% @li .t - time between the frames for 2D movies
% @li .tunits - time units
% @li .units - physical units for x, y, z. Possible values: [m, cm, mm, um, nm]
%
% Return values:
% img_info: updated imageData.img_info
% pixSize: updated imageData.pixSize
%
% @attention @b requres Width, Height, Depth fields in img_info

% Updates
% 

if nargin < 2
    pixSize.x = 1;
    pixSize.y = 1;
    pixSize.z = 1;
    pixSize.t = 1;
    pixSize.tunits = 's';
    pixSize.units = 'um';
end

% update resolution and pixel sizes
curr_text = img_info('ImageDescription');
if iscell(curr_text); curr_text = curr_text{1}; end
width = img_info('Width');
height = img_info('Height');
depth = img_info('Depth');
bb_info_exist = strfind(curr_text,'BoundingBox');
if bb_info_exist > 0   % use information from the BoundingBox parameter for pixel sizes if it is exist
    spaces = strfind(curr_text,' ');
    if numel(spaces) < 7; spaces(7) = numel(curr_text); end
    tab_pos = strfind(curr_text,sprintf('|'));
    pos = min([spaces(7) tab_pos]);
    bb_coord = str2num(curr_text(spaces(1):pos)); %#ok<ST2NM>
    dx = bb_coord(2)-bb_coord(1);
    dy = bb_coord(4)-bb_coord(3);
    dz = bb_coord(6)-bb_coord(5);
    pixSize.x = dx/(max([width 2])-1);  % tweek for saving single layered tifs for Amira
    pixSize.y = dy/(max([height 2])-1);
    pixSize.z = dz/(max([depth 2])-1);
    if isnan(pixSize.z);   pixSize.z = pixSize.x; end  % fix to do not get errors for setting of DataAspectRatio
    pixSize.units = 'um';
    resolution = mibCalculateResolution(pixSize);
else
    if ~isKey(img_info,'XResolution') || nargin == 2
        resolution = mibCalculateResolution(pixSize);
    else
        if ischar(img_info('XResolution'))  % this may come from ome.tiff when loading with bio-formats, but in practice it is not resolution, but pixel size
            img_info('XResolution') = str2double(img_info('XResolution')); 
            img_info('YResolution') = str2double(img_info('YResolution')); 
        end
        if isempty(img_info('XResolution')) || img_info('XResolution') == 0 || img_info('YResolution') == 0
            resolution = mibCalculateResolution(pixSize);
        else
            pixSize_temp = mibCalculatePixSizes([img_info('XResolution') img_info('YResolution')], img_info('ResolutionUnit'), 'um');
            pixSize.x = pixSize_temp.x;
            pixSize.y = pixSize_temp.y;
            pixSize.z = pixSize_temp.x;
            resolution = mibCalculateResolution(pixSize);
        end
    end
    
    % generate BoundingBox Info and add to ImageDescription
    coef = 1; % um
    dx = (max([width 2])-1)*pixSize.x*coef;     % tweek for Amira single layer images max([w 2])
    dy = (max([height 2])-1)*pixSize.y*coef;
    dz = (max([depth 2])-1)*pixSize.z*coef; %#ok<PROP>
    newBB = [0, dx,0, dy, 0, dz];
    str2 = sprintf('BoundingBox %.5f %.5f %.5f %.5f %.5f %.5f ',...
    newBB(1), newBB(2), newBB(3), newBB(4), newBB(5), newBB(6));
    curr_text = img_info('ImageDescription');
    if iscell(curr_text); curr_text = curr_text{1}; end
    img_info('ImageDescription') = sprintf('%s|%s', str2, curr_text); 
    
end
img_info('XResolution') = resolution(1);
img_info('YResolution') = resolution(2);
img_info('ResolutionUnit') = 'Inch';
end
