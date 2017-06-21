function volren_WindowButtonDownFcn(obj)
% function volren_WindowButtonDownFcn(obj)
% callback for the press of a mouse button during the volume rendering mode
%
% Parameters:
% 

% Copyright (C) 22.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

xy = obj.mibView.handles.mibImageAxes.CurrentPoint;

axXLim = obj.mibView.handles.mibImageAxes.XLim;
axYLim = obj.mibView.handles.mibImageAxes.YLim;
if xy(1, 1) < axXLim(1) || xy(1, 1) > axXLim(2) || ...
        xy(1, 2) < axYLim(1) || xy(1, 2) > axYLim(2) % mouse pointer outside the current axes
    return;
end

if (~isempty(xy))
    axes_size(1) = obj.mibModel.I{obj.mibModel.Id}.axesX(2)-obj.mibModel.I{obj.mibModel.Id}.axesX(1);
    axes_size(2) = obj.mibModel.I{obj.mibModel.Id}.axesY(2)-obj.mibModel.I{obj.mibModel.Id}.axesY(1);
    obj.mibView.brushPrevXY = [xy(1, 1) xy(1, 2)]./axes_size(1:2);  % as fraction of the viewing axes
end
seltype = obj.mibView.gui.SelectionType;
obj.mibModel.I{obj.mibModel.Id}.volren.showFullRes = 0;
if obj.mibModel.I{obj.mibModel.Id}.volren.showFullRes == 0
    S = makehgtform('scale', 1/obj.mibModel.I{obj.mibModel.Id}.volren.previewScale);
    obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix*S;
end

if strcmp(seltype, 'normal')
    cursorIcon=[NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 1 NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN NaN 1 1 1 NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN 1 1 NaN NaN NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN 1 NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN NaN;
        NaN 1 1 1 1 1 NaN 1 NaN NaN 1 1 1 1 1 1; 1 1 1 1 NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN 1 1;
        1 1 1 1 NaN NaN NaN 1 NaN NaN NaN NaN NaN 1 1 1; 1 NaN NaN NaN NaN NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 1;
        NaN NaN NaN NaN NaN NaN NaN NaN 1 1 1 NaN NaN NaN NaN 1; NaN NaN NaN NaN NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN NaN NaN NaN 1 1 1 NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN];
else
    cursorIcon=[NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN 1 NaN 1 NaN NaN NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN 1 1 NaN 1 1 NaN NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN 1 NaN 1 NaN 1 NaN NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN 1 1 NaN NaN NaN 1 NaN NaN NaN 1 1 NaN NaN NaN;
        NaN 1 1 NaN NaN NaN NaN 1 NaN NaN NaN NaN 1 1 NaN NaN; 1 NaN NaN 1 1 1 1 1 1 1 1 1 NaN NaN 1 NaN;
        NaN 1 1 NaN NaN NaN NaN 1 NaN NaN NaN NaN 1 1 NaN NaN; NaN NaN 1 1 NaN NaN NaN 1 NaN NaN NaN 1 1 NaN NaN NaN;
        NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN 1 NaN 1 NaN 1 NaN NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN 1 1 NaN 1 1 NaN NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN 1 NaN 1 NaN NaN NaN NaN NaN NaN NaN;
        NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];
end
obj.mibView.gui.Pointer = 'custom';
obj.mibView.gui.PointerShapeCData = cursorIcon;
obj.mibView.gui.PointerShapeHotSpot = round(size(cursorIcon)/2);

%set(handles.im_browser, 'WindowButtonMotionFcn' , {@volren_WindowInteractMotionFcn, handles, seltype});
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.volren_WindowInteractMotionFcn(seltype));  
%set(handles.im_browser, 'WindowButtonUpFcn', {@volren_WindowButtonUpFcn, handles});
obj.mibView.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.volren_WindowButtonUpFcn());
end
