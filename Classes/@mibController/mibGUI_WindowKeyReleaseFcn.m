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

function mibGUI_WindowKeyReleaseFcn(obj, eventdata)
% function mibGUI_WindowKeyReleaseFcn(obj, eventdata)
% callback for release of keys in mibGUI window
%
% Parameters:
% eventdata:  structure with the following fields (see FIGURE)
%	Key -> name of the key that was released, in lower case
%	Character -> character interpretation of the key(s) that was released
%	Modifier -> name(s) of the modifier key(s) (i.e., control, shift) released
%
% Return values:
%

% Updates
% 

% return after use of Control key. handles.ctrlPressed contains change in
% the brush diameter
if obj.mibView.ctrlPressed ~= 0
    radius = str2double(obj.mibView.handles.mibSegmSpotSizeEdit.String);
    obj.mibView.handles.mibSegmSpotSizeEdit.String = num2str(radius - max([0 obj.mibView.ctrlPressed]));
    obj.mibView.updateCursor('dashed');
end
obj.mibView.ctrlPressed = 0;
if obj.mibView.altPressed ~= 0 && ~obj.mibModel.preferences.System.AltWithScrollWheel
    obj.mibView.handles.mibChangeLayerSlider.Value = obj.mibView.altPressed;     % update slider value
    obj.mibChangeLayerSlider_Callback();
end
obj.mibView.altPressed = 0;

% % return after Alt key press, used together with the mouse wheel to zoom in/out 
% if strcmp(eventdata.Key, 'alt')
%     warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
%     jFig = get(obj.mibView.handles.mibGUI, 'JavaFrame');
%     jFig.requestFocus();
% end

end

