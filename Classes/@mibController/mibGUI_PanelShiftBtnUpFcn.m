function mibGUI_PanelShiftBtnUpFcn(obj, panelName)
% function mibGUI_PanelShiftBtnUpFcn(obj, panelName)
% callback for the release of a mouse button over
% handles.mibSeparatingPanel to change size of Directory contents and
% Segmentation panels
%
% Parameters:
% panelName: a string with the name of the moved panel
% @li 'mibSeparatingPanel' - for horizontal slider
% @li 'mibSeparatingPanel2' - for vertical slider

% Copyright (C) 28.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

position = obj.mibView.gui.CurrentPoint;  % get position of the cursor
separatingPanelPos = obj.mibView.handles.(panelName).Position;
resizeParameters.name = panelName;

if strcmp(panelName, 'mibSeparatingPanel')
    resizeParameters.panelShift =  position(1,1) - (separatingPanelPos(3))/2;
else 
    resizeParameters.panelShift =  position(1,2) - (separatingPanelPos(4))/2;
end
obj.mibGUI_SizeChangedFcn(resizeParameters);
obj.mibView.gui.WindowButtonUpFcn = [];
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());
end