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

% Copyright (C) 08.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; id = obj.Id; end
axesX = obj.I{id}.axesX;
axesY = obj.I{id}.axesY;
end


