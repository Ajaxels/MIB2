function setAxesLimits(obj, axesX, axesY, id)
% function setAxesLimits(obj, axesX, axesY, id)
% set axes limits for the currently shown or id dataset
%
% Parameters:
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% axesX: a vector [min, max] for the X
% axesY: a vector [min, max] for the Y

%| 
% @b Examples:
% @code [axesX, axesY] = obj.mibModel.getAxesLimits();     // call from mibController: get axes limits for the currently shown dataset @endcode
% @code [axesX, axesY] = obj.mibModel.getAxesLimits(2);     // call from mibController: get axes limits for dataset 2 @endcode

% Copyright (C) 08.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 4; id = obj.Id; end
if nargin < 3
    errordlg(sprintf('!!! Error !!!\n\nthe axesX, axesY parameters are missing'),'mibModel.setAxesLimits');
    return; 
end

obj.I{id}.updateSlicesStructure(axesX, axesY);

% obj.I{id}.axesX = axesX;
% obj.I{id}.axesY = axesY;
% 
% % update obj.slices
% if obj.I{id}.orientation == 4     % xy
%     obj.I{id}.slices{1}(1) = ceil(max([axesY(1) 1]));
%     obj.I{id}.slices{1}(2) = ceil(min([axesY(2) obj.I{id}.height]));
%     obj.I{id}.slices{2}(1) = ceil(max([axesX(1) 1]));
%     obj.I{id}.slices{2}(2) = ceil(min([axesX(2) obj.I{id}.width]));
% elseif obj.I{id}.orientation == 1     % xz
%     obj.I{id}.slices{2}(1) = ceil(max([axesY(1) 1]));
%     obj.I{id}.slices{2}(2) = ceil(min([axesY(2) obj.I{id}.width]));
%     obj.I{id}.slices{4}(1) = ceil(max([axesX(1) 1]));
%     obj.I{id}.slices{4}(2) = ceil(min([axesX(2) obj.I{id}.depth]));    
% elseif obj.I{id}.orientation == 2     % yz
%     obj.I{id}.slices{1}(1) = ceil(max([axesY(1) 1]));
%     obj.I{id}.slices{1}(2) = ceil(min([axesY(2) obj.I{id}.height]));
%     obj.I{id}.slices{4}(1) = ceil(max([axesX(1) 1]));
%     obj.I{id}.slices{4}(2) = ceil(min([axesX(2) obj.I{id}.depth])); 
% end
end


