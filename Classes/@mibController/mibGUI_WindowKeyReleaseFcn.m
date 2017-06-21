% --- Executes on key release with focus on im_browser or any of its controls.
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

% Copyright (C) 18.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
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

% % return after Alt key press, used together with the mouse wheel to zoom in/out 
% if strcmp(eventdata.Key, 'alt')
%     warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
%     jFig = get(obj.mibView.handles.mibGUI, 'JavaFrame');
%     jFig.requestFocus();
% end

end

