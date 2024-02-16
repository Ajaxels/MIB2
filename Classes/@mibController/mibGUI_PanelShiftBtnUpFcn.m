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