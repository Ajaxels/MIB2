function mibToolbar_ZoomBtn_ClickedCallback(obj, hObject, recenterSwitch)
% function mibToolbar_ZoomBtn_ClickedCallback(obj, hObject, recenterSwitch)
% modifies magnification using the zoom buttons in the toolbar of MIB
%
% Parameters:
% hObject: a string with tag of the pressed button
% recenterSwitch: [@em optional], defines whether the image should be recentered after zoom/unzoom. Default=0

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

if nargin < 3; recenterSwitch = 0; end
% zoom buttons
xy = obj.mibView.handles.mibImageAxes.CurrentPoint;

[xy2(1),xy2(2)] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown');
xy2 = ceil(xy2);

switch hObject
    case 'one2onePush'
        obj.mibView.handles.mibZoomEdit.String = '100 %';
        obj.mibZoomEdit_Callback();
    case 'fitPush'
        obj.updateAxesLimits('resize');
        obj.plotImage(1);
    case 'zoominPush'
        if recenterSwitch
            % recenter the view
            obj.mibModel.I{obj.mibModel.Id}.moveView(xy2(1), xy2(2));
            % recenter the mouse
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
            x = pos1(1) + pos2(1) + pos3(1) + pos3(3)/2;
            y = screenSize(4) - (pos1(2) + pos2(2) + pos3(2) + pos3(4)/2);

            mouse.mouseMove(x*obj.mibModel.preferences.gui.systemscaling, y*obj.mibModel.preferences.gui.systemscaling);
            
            % restore the units
            obj.mibView.gui.Units = 'points';
            obj.mibView.handles.mibViewPanel.Units = 'points';
        end
        % change zoom
        zoom = obj.mibView.handles.mibZoomEdit.String;
        zoom = str2double(strrep(zoom, '%', ''))/100;
        obj.mibView.handles.mibZoomEdit.String = [num2str(str2double(sprintf('%.3f',zoom*1.5))*100) ' %'];
        obj.mibZoomEdit_Callback();
    case 'zoomoutPush'
        % change zoom
        zoom = obj.mibView.handles.mibZoomEdit.String;
        zoom = str2double(strrep(zoom, '%', ''))/100;
        obj.mibView.handles.mibZoomEdit.String = [num2str(str2double(sprintf('%.2f',zoom/1.5))*100) ' %'];
        if recenterSwitch
            % recenter the view
            obj.mibModel.I{obj.mibModel.Id}.moveView(xy2(1), xy2(2));
            
            % recenter the mouse
            import java.awt.Robot;
            mouse = Robot;
            
            % set units to pixels
            obj.mibView.gui.Units = 'pixels';   % they were in points
            obj.mibView.handles.mibViewPanel.Units = 'pixels';
            
            pos1 = obj.mibView.gui.Position;
            pos2 = obj.mibView.handles.mibViewPanel.Position;
            pos3 = obj.mibView.handles.mibImageAxes.Position;
            screenSize = get(0, 'screensize');
            x = pos1(1) + pos2(1) + pos3(1) + pos3(3)/2;
            y = screenSize(4) - (pos1(2) + pos2(2) + pos3(2) + pos3(4)/2);
            mouse.mouseMove(x*obj.mibModel.preferences.gui.systemscaling, y*obj.mibModel.preferences.gui.systemscaling);
            
            % restore the units
            obj.mibView.gui.Units = 'points';
            obj.mibView.handles.mibViewPanel.Units = 'points';
        end
        obj.mibZoomEdit_Callback();
end
% % update ROI of the hMeasure class
if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.type)
    obj.mibModel.I{obj.mibModel.Id}.hMeasure.updateROIScreenPosition('crop');
end

% update ROI of the hROI class
if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hROI.roi.type)
    obj.mibModel.I{obj.mibModel.Id}.hROI.updateROIScreenPosition('crop');
end

end