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

function roiSwitch = getRoiSwitch(obj)
% function roiSwitch = getRoiSwitch(obj)
% get status of the mibGUI.handles.toolbarShowROISwitch
%
% Parameters:
%
% Return values:
% roiSwitch:
% @li @b 1 - enabled, return only areas inside ROIs
% @li @b 0 - disabled, return complete dataset

%| 
% @b Examples:
% @code roiSwitch = obj.mibView.getRoiSwitch();     // call from mibController: get the toolbarShowROISwitch @endcode

% Updates
% 

if strcmp(obj.handles.toolbarShowROISwitch.State, 'off')
    roiSwitch = 0;
else
    roiSwitch = 1;
end
end


