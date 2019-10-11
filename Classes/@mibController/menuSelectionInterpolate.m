function menuSelectionInterpolate(obj)
% function menuSelectionInterpolate(obj)
% a callback to the Menu->Selection->Interpolate; interpolates shapes of the selection layer
%
% Parameters:
% 
% Return values:
%


% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 18.08.2017, IB, fix backup before interpolation for YZ and XZ
% orientations

obj.mibModel.interpolateImage('selection');
end