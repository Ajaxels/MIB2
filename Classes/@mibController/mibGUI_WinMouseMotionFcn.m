function mibGUI_WinMouseMotionFcn(obj)
% function mibGUI_WinMouseMotionFcn(obj)
% returns coordinates and image intensities under the mouse cursor
%
% Parameters:
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

position = obj.mibView.handles.mibImageAxes.CurrentPoint;
axXLim = obj.mibView.handles.mibImageAxes.XLim;
axYLim = obj.mibView.handles.mibImageAxes.YLim;

x = round(position(1,1));
y = round(position(1,2));

% get mouse coordinates for the im_browser window to change cursor for
% rescaling of the right panels
position2 = obj.mibView.gui.CurrentPoint;
x2 = round(position2(1,1));
y2 = round(position2(1,2));
separatingPanelPos = obj.mibView.handles.mibSeparatingPanel.Position;
separatingPanelPos2 = obj.mibView.handles.mibSeparatingPanel2.Position;

% x
%         if x == -111
%             
%             error('dasda')
%         end

if x>axXLim(1) && x<axXLim(2) && y>axYLim(1) && y<axYLim(2) % mouse pointer within the current axes
    obj.mibView.handles.mibGUI.Pointer = 'crosshair';
    
    if x > 0 && y > 0 && x<=size(obj.mibView.Ishown,2) && y<=size(obj.mibView.Ishown,1) && ~isempty(obj.mibView.imh.CData) % mouse pointer inside the image dimensions
        if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
            % in the virtual mode intensity of pixels is obtained from obj.mibView.Iraw, which is a raw dataset displayed on the screen 
            if obj.mibModel.I{obj.mibModel.Id}.magFactor < 1
                [xImg, yImg] = obj.mibModel.convertMouseToDataCoordinates(x, y, 'blockmode');
            else
                xImg = ceil(x);     
                yImg = ceil(y);
            end
            xImg = ceil(xImg);     
            yImg = ceil(yImg);
        end
        
        % recalculate mouse coordinates to coordinates of the dataset
        [x, y, sliceNo] = obj.mibModel.convertMouseToDataCoordinates(x, y, 'shown');
        x = ceil(x);
        y = ceil(y);
        
        %fprintf('x=%d, y=%d\n', x, y)
        
        %sliceNo = obj.handles.Img{obj.handles.Id}.I.getCurrentSliceNumber();
        modelValues = [];
        try
            if obj.mibModel.I{obj.mibModel.Id}.orientation == 4   % yx
                if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0     % normal mode, memory-resident
                    colorValues = obj.mibModel.I{obj.mibModel.Id}.img{1}(y, x,...
                        obj.mibModel.I{obj.mibModel.Id}.slices{3}, sliceNo, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                    if obj.mibModel.I{obj.mibModel.Id}.modelExist
                        modelValues = obj.mibModel.I{obj.mibModel.Id}.model{1}(y,x, sliceNo, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                    end    
                else    % virtual stacking mode, hdd-resident
                    colorValues = obj.mibView.Iraw(yImg, xImg, :);
                end
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1 % zx
                colorValues = obj.mibModel.I{obj.mibModel.Id}.img{1}(sliceNo,y,...
                    obj.mibModel.I{obj.mibModel.Id}.slices{3},x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                if obj.mibModel.I{obj.mibModel.Id}.modelExist
                    modelValues = obj.mibModel.I{obj.mibModel.Id}.model{1}(sliceNo, y, x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                end
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 % zy
                colorValues = obj.mibModel.I{obj.mibModel.Id}.img{1}(y,sliceNo,...
                    obj.mibModel.I{obj.mibModel.Id}.slices{3},x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                if obj.mibModel.I{obj.mibModel.Id}.modelExist
                    modelValues = obj.mibModel.I{obj.mibModel.Id}.model{1}(y, sliceNo, x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                end
            end
        catch err
            colorValues = '';
            %err
        end
        
        rI = NaN;
        gI = NaN;
        bI = NaN;
        extI = NaN;
        if ~isempty(colorValues); rI = colorValues(1); end
        if numel(colorValues) > 1; gI = colorValues(2); end
        if numel(colorValues) > 2;  bI = colorValues(3);    end
        R = sprintf('%.0f',rI);
        G = sprintf('%.0f',gI);
        B = sprintf('%.0f',bI);
        
        if numel(colorValues) > 3
            extI = colorValues(4);
            E = sprintf('%.0f',extI);
            txt = [num2str(x) ':' num2str(y) '  (' R ':' G ':' B ':' E ') / ' num2str(modelValues)];
        else
            txt = [num2str(x) ':' num2str(y) '  (' R ':' G ':' B ') / ' num2str(modelValues)];
        end
        obj.mibView.handles.mibPixelInfoTxt2.String = txt;
    else
        %set(obj.handles.pixelinfoTxt2,'String','XXXX:YYYY (RRR:GGG:BBB)');
        txt = [num2str(x) ':' num2str(y) ' (RRR:GGG:BBB)'];
        obj.mibView.handles.mibPixelInfoTxt2.String = txt;
    end
    %[axesX, axesY] = obj.mibModel.getAxesLimits();
    %centX = mean(axesX);
    %centY = mean(axesY);
    %centX = max([1 centX]);
    %centY = max([1 centY]);
    %centX = min([centX obj.mibModel.I{obj.mibModel.Id}.width]);
    %centY = min([centY obj.mibModel.I{obj.mibModel.Id}.height]);
    %[x2, y2] = obj.mibModel.convertMouseToDataCoordinates(centX, centY, 'shown');
    %x2 = floor(axesY(1));
    %y2 = floor(axesY(2));
    
    %x2 = x*obj.mibModel.I{obj.mibModel.Id}.magFactor + max([0 floor(axesX(1))]);
    %y2 = y*obj.mibModel.I{obj.mibModel.Id}.magFactor + max([0 floor(axesY(1))]);
    %y2 = axesY(2);
    %txt = sprintf('%dx%d (:::) %sx%s', x, y, num2str(floor(x2)), num2str(floor(y2)));
    %obj.mibView.handles.mibPixelInfoTxt2.String = txt;
    
elseif x2>separatingPanelPos(1) && x2<separatingPanelPos(1)+separatingPanelPos(3) && y2>separatingPanelPos(2) && y2<separatingPanelPos(2)+separatingPanelPos(4) % mouse pointer within the current axes
    obj.mibView.gui.Pointer = 'left';
elseif x2>separatingPanelPos2(1) && x2<separatingPanelPos2(1)+separatingPanelPos2(3) && y2>separatingPanelPos2(2) && y2<separatingPanelPos2(2)+separatingPanelPos2(4) % mouse pointer within the current axes
    obj.mibView.gui.Pointer = 'top';
else
    obj.mibView.gui.Pointer = 'arrow';
    obj.mibView.handles.mibPixelInfoTxt2.String = 'XXXX:YYYY (RRR:GGG:BBB)';
end

% recalculate brush cursor positions
% possible code to show brush cursor, requires obj.handles.cursor handle for the plot type object
try
    if ishandle(obj.mibView.cursor)
        xdata = obj.mibView.cursor.XData;
        ydata = obj.mibView.cursor.YData;
        
        diffX = round(position(1,1))-mean(xdata);
        diffY = round(position(1,2))-mean(ydata);
        
        xv = xdata+diffX;
        yv = ydata+diffY;
        obj.mibView.cursor.XData = xv;
        obj.mibView.cursor.YData = yv;
    end
catch err
end
end