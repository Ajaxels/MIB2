function bb = getBoundingBox(obj)
% function bb = getBoundingBox(obj)
% Get Bounding box info as a vector [xmin, width, ymin, height, zmin, depth]
%
% The bounding box info is needed to properly put the dataset in the 3D space. It is stored in the header of the
% Amira mesh file, or in the beginning of the ImageDescription field of the TIF file.
%
% Parameters:
%
% Return values:
% bb: - bounding box info
% @li bb(1) = Xmin
% @li bb(2) = Width
% @li bb(3) = Ymin
% @li bb(4) = Height
% @li bb(5) = Zmin
% @li bb(6) = Depth

%| 
% @b Examples:
% @code bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();  // call from mibController; get bounding box info @endcode

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%


curr_text = obj.meta('ImageDescription');             % get current bounding box x1,y1,z1
bb_info_exist = strfind(curr_text,'BoundingBox');
if bb_info_exist == 1   % use information from the BoundingBox parameter for pixel sizes if it is exist
    spaces = strfind(curr_text,' ');
    if numel(spaces) < 7; spaces(7) = numel(curr_text); end
    tab_pos = strfind(curr_text,sprintf('|'));
    pos = min([spaces(7) tab_pos]);
    bb = str2num(curr_text(spaces(1):pos-1)); %#ok<ST2NM>
else
    bb(1) = 0;
    bb(3) = 0;
    bb(5) = 0;
    bb(2) = (max([obj.width 2])-1) * obj.pixSize.x;     % max([obj.width 2]) - tweek for amira bounding box of a single layer
    bb(4) = (max([obj.height 2])-1) * obj.pixSize.y;
    bb(6) = (max([obj.depth 2])-1) * obj.pixSize.z;
    %bb(2) = (obj.width-1) * obj.pixSize.x;
    %bb(4) = (obj.height-1) * obj.pixSize.y;
    %bb(6) = (obj.depth-1) * obj.pixSize.z;
end
end