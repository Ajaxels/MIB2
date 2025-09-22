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

function mibGUI_WinMouseMotionFcn(obj)
% function mibGUI_WinMouseMotionFcn(obj)
% returns coordinates and image intensities under the mouse cursor
%
% Parameters:
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

if x>axXLim(1) && x<axXLim(2) && y>axYLim(1) && y<axYLim(2) % mouse pointer within the current axes
    obj.mibView.handles.mibGUI.Pointer = 'crosshair';
    
    % calculate mouse travel distance
    if obj.mibModel.sessionSettings.prevCursorCoordinate(1) > 0
        mouseDist = sqrt((obj.mibModel.sessionSettings.prevCursorCoordinate(1)-x)^2 + (obj.mibModel.sessionSettings.prevCursorCoordinate(2)-y)^2) *...
            obj.mibModel.sessionSettings.metersPerPixel;
        obj.mibModel.preferences.Users.Tiers.mouseTravelDistance = obj.mibModel.preferences.Users.Tiers.mouseTravelDistance + mouseDist;
        obj.mibModel.preferences.Users.Tiers.collectedPoints = obj.mibModel.preferences.Users.Tiers.collectedPoints + mouseDist;
    end
    obj.mibModel.sessionSettings.prevCursorCoordinate = [x, y];     % store the previous coordinate of the cursor
    
    %fprintf('Mouse travel distance: %f meters\n', obj.mibModel.preferences.Users.mouseTravelDistance);
    %fprintf('Collected points: %f\n', obj.mibModel.preferences.Users.Tiers.collectedPoints);

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
        
        modelValues = [];
        colorValues = [];
        if obj.mibModel.I{obj.mibModel.Id}.orientation == 4   % yx
            y = min([y, obj.mibModel.I{obj.mibModel.Id}.height]);
            x = min([x, obj.mibModel.I{obj.mibModel.Id}.width]);
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0     % normal mode, memory-resident
                sliceNo = min([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 4), sliceNo]);
                colorValues = obj.mibModel.I{obj.mibModel.Id}.img{1}(y, x,...
                    obj.mibModel.I{obj.mibModel.Id}.slices{3}, sliceNo, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                if obj.mibModel.I{obj.mibModel.Id}.modelExist
                    modelValues = obj.mibModel.I{obj.mibModel.Id}.model{1}(y,x, sliceNo, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                end
            else    % virtual stacking mode, hdd-resident
                colorValues = 0;
                if ~isempty(obj.mibView.Iraw)
                    colorValues = obj.mibView.Iraw(yImg, xImg, :);
                end
            end
        elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1 && ~obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual % zx
            y = min([y, obj.mibModel.I{obj.mibModel.Id}.width]);
            x = min([x, obj.mibModel.I{obj.mibModel.Id}.depth]);
            colorValues = obj.mibModel.I{obj.mibModel.Id}.img{1}(sliceNo,y,...
                obj.mibModel.I{obj.mibModel.Id}.slices{3},x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
            if obj.mibModel.I{obj.mibModel.Id}.modelExist
                modelValues = obj.mibModel.I{obj.mibModel.Id}.model{1}(sliceNo, y, x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
            end
        elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 && ~obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual % zy
            y = min([y, obj.mibModel.I{obj.mibModel.Id}.height]);
            x = min([x, obj.mibModel.I{obj.mibModel.Id}.depth]);
            colorValues = obj.mibModel.I{obj.mibModel.Id}.img{1}(y,sliceNo,...
                obj.mibModel.I{obj.mibModel.Id}.slices{3},x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
            if obj.mibModel.I{obj.mibModel.Id}.modelExist
                modelValues = obj.mibModel.I{obj.mibModel.Id}.model{1}(y, sliceNo, x, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
            end
        end
        
        switch numel(colorValues)
            case 0
                txt = sprintf('%d:%d', x, y);
            case 1
                txt = sprintf('%d:%d (%d:NaN:NaN) / %d', x, y, colorValues(1), modelValues);
            case 2
                txt = sprintf('%d:%d (%d:%d:NaN) / %d', x, y, colorValues(1), colorValues(2), modelValues);
            case 3
                txt = sprintf('%d:%d (%d:%d:%d) / %d', x, y, colorValues(1), colorValues(2), colorValues(3), modelValues);
            otherwise
                txt = sprintf('%d:%d (%d:%d:%d:%d) / %d', x, y, colorValues(1), colorValues(2), colorValues(3), colorValues(4), modelValues);
        end
        obj.mibView.handles.mibPixelInfoTxt2.String = txt;
    else
        txt = [num2str(x) ':' num2str(y) ' (RRR:GGG:BBB)'];
        obj.mibView.handles.mibPixelInfoTxt2.String = txt;
    end
elseif x2>separatingPanelPos(1) && x2<separatingPanelPos(1)+separatingPanelPos(3) && y2>separatingPanelPos(2) && y2<separatingPanelPos(2)+separatingPanelPos(4) % mouse pointer within the current axes
    obj.mibView.gui.Pointer = 'left';
    obj.mibModel.sessionSettings.prevCursorCoordinate = 0; % clear the previous mouse coordinate when leaving the image axes
elseif x2>separatingPanelPos2(1) && x2<separatingPanelPos2(1)+separatingPanelPos2(3) && y2>separatingPanelPos2(2) && y2<separatingPanelPos2(2)+separatingPanelPos2(4) % mouse pointer within the current axes
    obj.mibView.gui.Pointer = 'top';
    obj.mibModel.sessionSettings.prevCursorCoordinate = 0; % clear the previous mouse coordinate when leaving the image axes
else
    obj.mibView.gui.Pointer = 'arrow';
    obj.mibView.handles.mibPixelInfoTxt2.String = 'XXXX:YYYY (RRR:GGG:BBB)';
    obj.mibModel.sessionSettings.prevCursorCoordinate = 0; % clear the previous mouse coordinate when leaving the image axes
end

% recalculate brush cursor positions
% possible code to show brush cursor, requires obj.handles.cursor handle for the plot type object
try
    if ishandle(obj.mibView.cursor)
        obj.mibView.cursor.XData = ...
            obj.mibView.cursor.XData + position(1,1) - obj.mibView.cursor.XData(5);
        
        obj.mibView.cursor.YData = ...
            obj.mibView.cursor.YData + position(1,2) - obj.mibView.cursor.YData(1);
        drawnow nocallbacks;
    end
catch err
end
end