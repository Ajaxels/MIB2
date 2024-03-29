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

function setVolrenModeSwitch(obj, volrenModeSwitch)
% function setVolrenModeSwitch(obj, volrenModeSwitch)
% set status of the mibGUI.handles.volrenToolbarSwitch
%
% Parameters:
% volrenModeSwitch:
% @li @b 1 - or 'on' enabled, show dataset as a volume
% @li @b 0 - or 'off' disabled, show dataset as a 2D slice
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibView.setVolrenModeSwitch(0);     // call from mibController: show dataset as a 2D slice @endcode

% Updates
% 

if nargin < 2
    errordlg(sprintf('!!! Error !!!\n\nthe volrenModeSwitch is missing!'),'mibView.volrenModeSwitch')
    return;
end

if ischar(volrenModeSwitch)
    if strcmp(volrenModeSwitch, 'on')
        volrenModeSwitch = 1;
    else
        volrenModeSwitch = 0;
    end
end

if volrenModeSwitch == 0
    obj.handles.volrenToolbarSwitch.State = 'off';
else
    obj.handles.volrenToolbarSwitch.State = 'on';
end
% redraw the image
notify(obj.mibModel, 'plotImage');
end


