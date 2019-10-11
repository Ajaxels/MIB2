function updateCursor(obj, mode)
% function updateCursor(obj, mode)
% Update brush cursor
%
% Parameters:
% mode: @b [optional] a string, a mode to use with the brush cursor: @b 'dashed' (default) - show dashed cursor, @b 'solid' -
% show solid cursor when painting.
%
% Return values:
% 

% Copyright (C) 06.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; mode = 'dashed'; end

xy=obj.handles.mibImageAxes.CurrentPoint;

x = round(xy(1,1));
y = round(xy(1,2));

% when 1, show the brush cursor
if obj.showBrushCursor 
     toolsList = obj.handles.mibSegmentationToolPopup.String;
     selectedTool = toolsList{obj.handles.mibSegmentationToolPopup.Value};
     
    if strcmp(selectedTool, 'Object Picker')
        radius = str2double(obj.handles.mibMaskBrushSizeEdit.String)-1;
    else
        radius = str2double(obj.handles.mibSegmSpotSizeEdit.String)-1;
    end
    
    magFactor = obj.mibModel.getMagFactor();
    if radius == 0
        se_size = round(1/magFactor/2);
    else
        se_size = round(radius/magFactor);
    end
    
    se_size(2) = se_size(1);
    
    if strcmp(mode, 'dashed')
        lineStyle = ':';
    else
        lineStyle = '-';
    end
    
%     % to correct aspect ratio
%     pixSize = handles.Img{handles.Id}.I.pixSize;
%     if handles.Img{handles.Id}.I.orientation == 1 
%         se_size(2) = se_size(1)/(pixSize.x/pixSize.z);
%     elseif handles.Img{handles.Id}.I.orientation == 2
%         se_size(2) = se_size(1)/(pixSize.y/pixSize.z);
%     elseif handles.Img{handles.Id}.I.orientation == 4
%         se_size(2) = se_size(1)/(pixSize.x/pixSize.y);
%     end
    
    % set brush cursor
    theta = linspace(0,2*pi,16);
    xv = cos(theta)*se_size(1) + x;
    yv = sin(theta)*se_size(2) + y;
    
    hold(obj.handles.mibImageAxes, 'on');
    if ishandle(obj.cursor) 
        %oldversion handles.cursor = plot(handles.imageAxes, xv,yv,'color',[0, 0.5, 0],'linewidth',1,'linestyle',':');
        set(obj.cursor, 'XData', xv,'YData', yv,'linewidth', 2, 'linestyle', lineStyle, 'color', [0, 0.5, 0]);
    else
        obj.cursor = plot(obj.handles.mibImageAxes, xv,yv,'color',[0, 0.5, 0],'linewidth',2,'linestyle', lineStyle);
        obj.cursor.Tag = 'brushcursor';
    end
    obj.cursor.Visible = 'on';
    hold(obj.handles.mibImageAxes, 'off');
else
    if isvalid(obj.cursor)
        obj.cursor.Visible = 'off';
    else
        %hold(obj.handles.mibImageAxes, 'on');
        obj.cursor = plot(obj.handles.mibImageAxes, [],[]);
        %hold(obj.handles.mibImageAxes, 'off');
    end
%     if ishandle(obj.cursor) 
%         obj.cursor.Visible = 'off';
%         %set(handles.cursor, 'XData', [],'YData', []);
%     elseif isfield(handles, 'cursor')   % to fix situation when pressing the Buffer toggle when cursor is not shown
%         hold(handles.imageAxes, 'on');
%         handles.cursor = plot(handles.imageAxes, [],[]);
%         hold(handles.imageAxes, 'off');
%     end
end
end