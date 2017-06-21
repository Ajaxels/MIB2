function volrenModeSwitch = getVolrenModeSwitch(obj)
% function volrenModeSwitch = getVolrenModeSwitch(obj)
% get status of the mibGUI.handles.volrenToolbarSwitch
%
% Parameters:
%
% Return values:
% volrenModeSwitch:
% @li @b 1 - enabled, the volume is displayed
% @li @b 0 - disabled, a single 2D slice is displayed

%| 
% @b Examples:
% @code volrenModeSwitch = obj.mibView.getVolrenModeSwitch();     // call from mibController: get the blockModeSwitch @endcode

% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if strcmp(obj.handles.volrenToolbarSwitch.State, 'off')
    volrenModeSwitch = 0;
else
    volrenModeSwitch = 1;
end
end


