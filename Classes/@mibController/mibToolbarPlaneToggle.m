function mibToolbarPlaneToggle(obj, hObject, moveMouseSw)
% function mibToolbarPlaneToggle(obj, hObject, moveMouseSw)
% a callback to the change orientation buttons in the toolbar of MIB; it toggles viewing plane: xy, zx, or zy direction
%
% Parameters:
% hObject: handle to im_browser.m (see GCBO)
% moveMouseSw: [@em optional] -> when 1, moves the mouse to the point where the the plane orientation has been changed

% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3;     moveMouseSw = 0; end

obj.mibView.handles.zyPlaneToggle.State = 'off';
obj.mibView.handles.xyPlaneToggle.State = 'off';
obj.mibView.handles.zxPlaneToggle.State = 'off';

if obj.mibModel.I{obj.mibModel.Id}.depth == 1
    obj.mibView.handles.xyPlaneToggle.State = 'on';
    return;
end
hObject.State = 'on';

% when volume rendering is enabled
if obj.mibModel.I{obj.mibModel.Id}.volren.show == 1
    switch hObject.Tag
        case 'xyPlaneToggle'
              R = [0 0 0];  % 'yx'
        case 'zxPlaneToggle'
             R = [90 0 90]; % 'xz'
        case 'zyPlaneToggle'
             R = [90 90 0]; % 'yz'
    end
    S = [1*magFactor,...
         1*magFactor,...
         1*obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.z*obj.mibModel.I{obj.mibModel.Id}.magFactor];  
    T = [0 0 0];               
    obj.mibModel.I{obj.mibModel.Id}.volren{obj.mibModel.Id}.viewer_matrix = makeViewMatrix(R, S, T);
    obj.plotImage();
    return;
end

switch get(hObject,'Tag')
    case 'xyPlaneToggle'
        obj.mibModel.I{obj.mibModel.Id}.transpose(4);  % 'yx'
    case 'zxPlaneToggle'
        obj.mibModel.I{obj.mibModel.Id}.transpose(1); % 'xz'
    case 'zyPlaneToggle'
        obj.mibModel.I{obj.mibModel.Id}.transpose(2); % 'yz'
end
oldMagFactor = obj.mibModel.getMagFactor();
obj.updateAxesLimits('resize');
obj.updateGuiWidgets();
obj.plotImage(1);

if moveMouseSw
    % move the mouse to the point of the plane change
    import java.awt.Robot;
    mouse = Robot;
    
    % set units to pixels
    obj.mibView.gui.Units = 'pixels';   % they were in points
    obj.mibView.handles.mibViewPanel.Units = 'pixels';
    
    % get pisition
    pos1 = obj.mibView.gui.Position;
    pos2 = obj.mibView.handles.mibViewPanel.Position;
    pos3 = obj.mibView.handles.mibImageAxes.Position;
    screenSize = get(0, 'screensize');
    
    x = 1;
    y = 1;
    switch get(hObject,'Tag')
        case 'xyPlaneToggle'
            x = obj.mibModel.I{obj.mibModel.Id}.current_yxz(2);
            y = obj.mibModel.I{obj.mibModel.Id}.current_yxz(1);
        case 'zxPlaneToggle'
            x = obj.mibModel.I{obj.mibModel.Id}.current_yxz(3);
            y = obj.mibModel.I{obj.mibModel.Id}.current_yxz(2);
        case 'zyPlaneToggle'
            x = obj.mibModel.I{obj.mibModel.Id}.current_yxz(3);
            y = obj.mibModel.I{obj.mibModel.Id}.current_yxz(1);
    end
    % recenter the view
    obj.mibModel.I{obj.mibModel.Id}.moveView(x, y);
    
    % restore the units
    obj.mibView.gui.Units = 'points';
    obj.mibView.handles.mibViewPanel.Units = 'points';

    % change zoom
    obj.mibView.handles.mibZoomEdit.String = [num2str(str2double(sprintf('%.3f',1/oldMagFactor))*100) ' %'];
    obj.mibZoomEdit_Callback();
    
    % calculate position of the imageAxes center in pixels (for coordinates of the monitor)
    xMouse = pos1(1) + pos2(1) + pos3(1) + pos3(3)/2;
    yMouse = screenSize(4) - (pos1(2) + pos2(2) + pos3(2) + pos3(4)/2);
    mouse.mouseMove(xMouse*obj.mibModel.preferences.gui.systemscaling, yMouse*obj.mibModel.preferences.gui.systemscaling);    % move the mouse
end
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());   
end