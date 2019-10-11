function mibGUI_panAxesFcn(obj, xy, imgWidth, imgHeight)
% function mibGUI_panAxesFcn(obj, xy, imgWidth, imgHeight)
% This function is responsible for moving image in obj.mibView.handles.mibImageAxes during panning
%
% Parameters:
% xy: coordinates of the mouse when the mouse button was pressed
% imgWidth: width of the shown image
% imgHeight: height of the shown image

% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if strcmp(obj.mibView.handles.toolbarFastPanMode.State, 'off')
    fastPanMode = 0;        % slow pan mode, and showing the full image
else
    fastPanMode = 1;        % fast pan mode, but showing the currently shown piece
end
pt = obj.mibView.handles.mibImageAxes.CurrentPoint;

Xlim = obj.mibView.handles.mibImageAxes.XLim;
Ylim = obj.mibView.handles.mibImageAxes.YLim;

newXLim = Xlim + (xy(1)-(pt(1,1)+pt(2,1))/2);
newYLim = Ylim + (xy(2)-(pt(1,2)+pt(2,2))/2);

% check for out of image shifts
outSwitch = 0;
if newXLim(2) < 1 || newXLim(1) > imgWidth; outSwitch = 1; end
if newYLim(2) < 1 || newYLim(1) > imgHeight; outSwitch = 1; end

if outSwitch == 0
    magFactor = obj.mibModel.getMagFactor();
    if fastPanMode
        magFactorFixed = magFactor;
    else
        if magFactor < 1   % the image is not rescaled if magFactor less than 1
            magFactorFixed = 1;
        else
            magFactorFixed = magFactor;
        end
    end
    
    % the code requires:
    % 1. add panShiftXY property to mibView
    % 2. add [obj.mibView.panShiftXY(1,:) obj.mibView.panShiftXY(2,:)] =
    % obj.mibModel.getAxesLimits(); before
    % obj.mibView.gui.WindowButtonDownFcn = []; to mibGUI_WindowButtonDownFcn
    % not the best implementation, due to by-pixel shifts of the image
    
    
    %if fastPanMode && magFactorFixed<=1 && magFactorFixed>.1
    %    axesX = obj.mibView.panShiftXY(1,:) + (xy(1)-(pt(1,1)+pt(2,1))/2)*magFactorFixed;
    %    axesY = obj.mibView.panShiftXY(2,:) + (xy(2)-(pt(1,2)+pt(2,2))/2)*magFactorFixed;
    %    obj.mibModel.setAxesLimits(axesX, axesY);
    %    obj.plotImage();
    %else
        obj.mibView.handles.mibImageAxes.XLim = newXLim;
        obj.mibView.handles.mibImageAxes.YLim = newYLim;
        [axesX, axesY] = obj.mibModel.getAxesLimits();
        axesX = axesX + (xy(1)-(pt(1,1)+pt(2,1))/2)*magFactorFixed;
        axesY = axesY + (xy(2)-(pt(1,2)+pt(2,2))/2)*magFactorFixed;
        obj.mibModel.setAxesLimits(axesX, axesY);
    %end
end
end