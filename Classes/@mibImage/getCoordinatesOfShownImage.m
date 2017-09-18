function [yMin, yMax, xMin, xMax, zMin, zMax] = getCoordinatesOfShownImage(obj, transposeTo4)
% function [yMin, yMax, xMin, xMax, zMin, zMax] = getCoordinatesOfShownImage(obj, transposeTo4)
% Return minimal and maximal coordinates (XY) of the image that is
% currently shown.
%
% Parameters:
% transposeTo4: - [@em optional] when 1, transpose dataset to the
% orientation 4, when looking on the XY plane of the dataset, used in
% mibController.menuSelectionInterpolate
% 
% Return values:
% yMin: - minimal Y coordinate
% yMax: - maximal Y coordinate
% xMin: - minimal Y coordinate
% xMax: - maximal Y coordinate
% zMin: - minimal Z coordinate
% zMax: - maximal Z coordinate
%
% @b Note:
% it is also possible to get coordinates from .slices field of mibImage
% class

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
% 18.08.2017 IB updated for Z, added transpose option

if nargin < 2; transposeTo4 = 0; end

Xlim = ceil(obj.axesX);
Ylim = ceil(obj.axesY);

if transposeTo4 == 0
    if obj.orientation==1     % xz
        yMin = max([Ylim(1) 1]);
        yMax = min([Ylim(2) obj.width]);
        xMin = max([Xlim(1) 1]);
        xMax = min([Xlim(2) obj.depth]);
        zMin = 1;
        zMax = obj.height;
    elseif obj.orientation==2 % yz
        yMin = max([Ylim(1) 1]);
        yMax = min([Ylim(2) obj.height]);
        xMin = max([Xlim(1) 1]);
        xMax = min([Xlim(2) obj.depth]);
        zMin = 1;
        zMax = obj.width;
    elseif obj.orientation==4 % yx
        yMin = max([Ylim(1) 1]);
        yMax = min([Ylim(2) obj.height]);
        xMin = max([Xlim(1) 1]);
        xMax = min([Xlim(2) obj.width]);
        zMin = 1;
        zMax = obj.depth;
    end
else    % transpose to XY
    if obj.orientation==1     % xz
        xMin = max([Ylim(1) 1]);
        xMax = min([Ylim(2) obj.width]);
        zMin = max([Xlim(1) 1]);
        zMax = min([Xlim(2) obj.depth]);
        yMin = 1;
        yMax = obj.height;
    elseif obj.orientation==2 % yz
        yMin = max([Ylim(1) 1]);
        yMax = min([Ylim(2) obj.height]);
        zMin = max([Xlim(1) 1]);
        zMax = min([Xlim(2) obj.depth]);
        xMin = 1;
        xMax = obj.width;
    elseif obj.orientation==4 % yx
        yMin = max([Ylim(1) 1]);
        yMax = min([Ylim(2) obj.height]);
        xMin = max([Xlim(1) 1]);
        xMax = min([Xlim(2) obj.width]);
        zMin = 1;
        zMax = obj.depth;
    end
end

end