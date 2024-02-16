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

function [axesX, axesY] = getAxesLimits(obj, id)
% function [axesX, axesY] = getAxesLimits(obj, id)
% get axes limits for the currently shown or id dataset
%
% Parameters:
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.mibModel.Id)
%
% Return values:
% axesX: a vector [min, max] for the X
% axesY: a vector [min, max] for the Y

%| 
% @b Examples:
% @code [axesX, axesY] = obj.mibView.getAxesLimits();     // call from mibController: get axes limits for the currently shown dataset @endcode
% @code [axesX, axesY] = obj.mibView.getAxesLimits(2);     // call from mibController: get axes limits for dataset 2 @endcode

% Updates
% 

if nargin < 2; id = obj.Id; end
axesX = obj.I{id}.axesX;
axesY = obj.I{id}.axesY;
end


