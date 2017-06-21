function mibPixelInfo_Callback(obj, parameter)
% function mibPixelInfo_Callback(obj, parameter)
% center image to defined position
% it is a callback from a popup menu above the pixel information field of
% the Path panel
% 
% Parameters:
% parameter: - a string that defines options:
% @li ''jump'' - center the viewing window around specified coordinates

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%


%handles = guidata(hObject);
switch parameter
    case 'jump'
        prompt = {sprintf('Enter destination in pixels\n\nX (1-%d):', obj.mibModel.I{obj.mibModel.Id}.width),...
            sprintf('Y (1-%d):', obj.mibModel.I{obj.mibModel.Id}.height),...
            sprintf('Z (1-%d):', obj.mibModel.I{obj.mibModel.Id}.depth)};
        def = {num2str(round(obj.mibModel.I{obj.mibModel.Id}.width/2)),num2str(round(obj.mibModel.I{obj.mibModel.Id}.height/2)),...
            num2str(obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber())};
        answer = inputdlg(prompt,'Jump to:',1,def);
        if isempty(answer); return; end;
        if num2str(obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber()) ~= str2double(answer{3})
            obj.mibView.handles.mibChangeLayerEdit.String = answer{3};
            obj.mibChangeLayerEdit_Callback();
        end
        
        if obj.mibModel.I{obj.mibModel.Id}.width < str2double(answer{1}) || ...
                obj.mibModel.I{obj.mibModel.Id}.height < str2double(answer{2}) || ...
            str2double(answer{1}) < 1 || str2double(answer{2}) < 1 || isnan(str2double(answer{1})) || isnan(str2double(answer{2})) || isnan(str2double(answer{3})) 
            errordlg(sprintf('!!! Error !!!\nThe coordinates should be within the image boundaries!'),'Error');
            return;
        end
        
        import java.awt.Robot;
        mouse = Robot;
        % set units to pixels
        obj.mibView.gui.Units = 'pixels';   % they were in points
        obj.mibView.handles.mibViewPanel.Units = 'pixels';   % they were in points
        
        pos1 = obj.mibView.gui.Position;
        pos2 = obj.mibView.handles.mibViewPanel.Position;
        pos3 = obj.mibView.handles.mibImageAxes.Position;
        screenSize = get(0, 'screensize');
        x = pos1(1) + pos2(1) + pos3(1) + pos3(3)/2;
        y = screenSize(4) - (pos1(2) + pos2(2) + pos3(2) + pos3(4)/2);
        mouse.mouseMove(x*obj.mibModel.preferences.gui.systemscaling, y*obj.mibModel.preferences.gui.systemscaling);
        % recenter the view
        obj.mibModel.I{obj.mibModel.Id}.moveView(str2double(answer{1}), str2double(answer{2}));
        
        % restore the units
        obj.mibView.gui.Units = 'points';
        obj.mibView.handles.mibViewPanel.Units = 'points';
        obj.plotImage(0);
end
end