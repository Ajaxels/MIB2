function updateBoundingBox(obj, newBB, xyzShift, imgDims)
% function updateBoundingBox(obj, newBB, xyzShift, imgDims)
% Update the bounding box info of the dataset
%
% The bounding box info is needed to properly put the dataset in the 3D space. It is encoded in the header of the
% Amira mesh file, or in the beginning of the ImageDescription field of the TIF file.
%
% Parameters:
% newBB: - new Bounding Box parameters, @b Note! when @em NaN the dataset will be shifted with using @em xyzShift
% @li bb(1) = Xmin
% @li bb(2) = Width
% @li bb(3) = Ymin
% @li bb(4) = Height
% @li bb(5) = Zmin
% @li bb(6) = Thickness
% xyzShift: [@em optional] a vector [height, width, z-stacks] with shifts of the bounding box; when omitted the function will use minimal
% parameters of the existing boinding box for the shitfs. @b Note! the units here are the image units:
% mibImage.pixSize.units.
% imgDims: [@em optional] a vector [height, width, z-stacks] with dimensions of the image; when omitted the function will use
% mibImage.height, mibImage.width and mibImage.no_stacks variables. @b Note! the units here are the image units:
% mibImage.pixSize.units.
%
% Return values:

%| 
% @b Examples:
% @code xyzShift = [10 5 0];  // shift the bounging box by 10 units in X, by 10 units in Y, and by 0 units in Z @endcode
% @code mibImage.updateBoundingBox(NaN, xyzShift);  // get bounding box info @endcode
% @code newBB = [15 50 10 150 1 15];  // define new bounding box in mibImage.pixSize.units @endcode
% @code mibImage.updateBoundingBox(newBB);  // get bounding box info @endcode

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%


if nargin < 4
    h = obj.height;
    w = obj.width;
    depth = obj.depth; %#ok<PROP>
else
    h = imgDims(1);
    w = imgDims(2);
    depth = imgDims(3);     %#ok<PROP>
end
if nargin < 2
    newBB = NaN;
end

% bouding box will be recalculated to um
switch obj.pixSize.units
    case 'm'
        coef = 1e6;
    case 'cm'
        coef = 1e4;
    case 'mm'
        coef = 1e3;
    case 'um'
        coef = 1;
    case 'nm'
        coef = 1e-3;
end
obj.pixSize.units = 'um';

if isnan(newBB)     % shift the existing bounding box
    % get current bounding box x1,y1,z1
    bb = obj.getBoundingBox();
    xyzZero(1) = bb(1);
    xyzZero(2) = bb(3);
    xyzZero(3) = bb(5);
    
    if nargin < 2
        xyzShift = xyzZero;
    else
        xyzShift(1) = xyzZero(1)+xyzShift(1); %*obj.pixSize.x*coef;   % convert from pixels to um
        xyzShift(2) = xyzZero(2)+xyzShift(2); %*obj.pixSize.y*coef;
        xyzShift(3) = xyzZero(3)+xyzShift(3); %*obj.pixSize.z*coef;
    end
    
    if isnan(xyzShift(1)); xyzShift(1) = 0; end
    if isnan(xyzShift(2)); xyzShift(2) = 0; end
    if isnan(xyzShift(3)); xyzShift(3) = 0; end
    
    dx = (max([w 2])-1)*obj.pixSize.x*coef;     % tweek for Amira single layer images max([w 2])
    dy = (max([h 2])-1)*obj.pixSize.y*coef;
    dz = (max([depth 2])-1)*obj.pixSize.z*coef; %#ok<PROP>
    %             dx = (max([w 1]))*obj.pixSize.x*coef;
    %             dy = (max([h 1]))*obj.pixSize.y*coef;
    %             dz = (max([depth 1]))*obj.pixSize.z*coef; %#ok<PROP>
    newBB = [xyzShift(1), xyzShift(1)+dx,...
             xyzShift(2), xyzShift(2)+dy, ...
             xyzShift(3), xyzShift(3)+dz];
end

str2 = sprintf('BoundingBox %.5f %.5f %.5f %.5f %.5f %.5f ',...
    newBB(1), newBB(2), ...
    newBB(3), newBB(4), ...
    newBB(5), newBB(6));
curr_text = obj.meta('ImageDescription');
bb_info_exist = strfind(curr_text,'BoundingBox');
if bb_info_exist == 1
    spaces = strfind(curr_text,' ');
    if numel(spaces) < 7; spaces(7) = numel(curr_text); end
    tab_pos = strfind(curr_text,sprintf('|'));
    % emilinate double ||
    doubleBreak = find(diff(tab_pos)==1);
    if ~isempty(doubleBreak)
        curr_text(tab_pos(doubleBreak)) = [];
        tab_pos(doubleBreak) = [];
    end
    
    % 12    14    21    23    28    30
    pos = min([spaces(7) tab_pos]);
    obj.meta('ImageDescription') = [str2 curr_text(pos:end)];
else
    obj.meta('ImageDescription') = [str2 curr_text];
end

obj.pixSize.x = (newBB(2)-newBB(1))/(w-1);
obj.pixSize.y = (newBB(4)-newBB(3))/(h-1);
obj.pixSize.z = (newBB(6)-newBB(5))/(max([depth-1, 1]));
end