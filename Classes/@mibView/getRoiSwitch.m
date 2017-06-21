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

% Copyright (C) 17.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if strcmp(obj.handles.toolbarShowROISwitch.State, 'off')
    roiSwitch = 0;
else
    roiSwitch = 1;
end
end


