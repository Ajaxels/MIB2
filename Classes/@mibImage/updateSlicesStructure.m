function updateSlicesStructure(obj, axesX, axesY)
% function updateSlicesStructure(obj, axesX, axesY)
% updates obj.slices structure using the provided axesX, axesY boundaries
%
% Parameters:
% axesX: a vector [min, max] for the X
% axesY: a vector [min, max] for the Y
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.I{id}.updateSlicesStructure(axesX, axesY);     // call from mibController: update obj.slices structure @endcode

% Copyright (C) 16.08.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


if nargin < 3
    errordlg(sprintf('!!! Error !!!\n\nthe axesX, axesY parameters are missing'), 'mibImage.updateSlicesStructure');
    return; 
end
obj.axesX = axesX;
obj.axesY = axesY;

% update obj.slices
if obj.orientation == 4     % xy
    obj.slices{1}(1) = ceil(max([axesY(1) 1]));
    obj.slices{1}(2) = ceil(min([axesY(2) obj.height]));
    obj.slices{2}(1) = ceil(max([axesX(1) 1]));
    obj.slices{2}(2) = ceil(min([axesX(2) obj.width]));
elseif obj.orientation == 1     % xz
    obj.slices{2}(1) = ceil(max([axesY(1) 1]));
    obj.slices{2}(2) = ceil(min([axesY(2) obj.width]));
    obj.slices{4}(1) = ceil(max([axesX(1) 1]));
    obj.slices{4}(2) = ceil(min([axesX(2) obj.depth]));    
elseif obj.orientation == 2     % yz
    obj.slices{1}(1) = ceil(max([axesY(1) 1]));
    obj.slices{1}(2) = ceil(min([axesY(2) obj.height]));
    obj.slices{4}(1) = ceil(max([axesX(1) 1]));
    obj.slices{4}(2) = ceil(min([axesX(2) obj.depth])); 
end
end


