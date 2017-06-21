function [yMin, yMax, xMin, xMax] = getCoordinatesOfShownImage(obj)
% function [yMin, yMax, xMin, xMax] = getCoordinatesOfShownImage(obj)
% Return minimal and maximal coordinates (XY) of the image that is
% currently shown.
%
% Parameters:
%
% Return values:
% yMin: - minimal Y coordinate
% yMax: - maximal Y coordinate
% xMin: - minimal Y coordinate
% xMax: - maximal Y coordinate

%| 
% @b Examples:
% @code [yMin, yMax, xMin, xMax] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage();  // get coordinates @endcode

% Copyright (C) 13.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% % 


Xlim = ceil(obj.axesX);
Ylim = ceil(obj.axesY);

if obj.orientation==1     % xz
    yMin = max([Ylim(1) 1]);
    yMax = min([Ylim(2) obj.width]);
    xMin = max([Xlim(1) 1]);
    xMax = min([Xlim(2) obj.depth]);
elseif obj.orientation==2 % yz
    yMin = max([Ylim(1) 1]);
    yMax = min([Ylim(2) obj.height]);
    xMin = max([Xlim(1) 1]);
    xMax = min([Xlim(2) obj.depth]);
elseif obj.orientation==4 % yx
    yMin = max([Ylim(1) 1]);
    yMax = min([Ylim(2) obj.height]);
    xMin = max([Xlim(1) 1]);
    xMax = min([Xlim(2) obj.width]);
end

end