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

function updateWidgets(obj)
% function updateWidgets(obj)
% update widgets of mibBatchController class

% update obj.View.handles.actionPopup

obj.View.handles.sectionPopup.String = {obj.Sections.Name}';
obj.View.handles.sectionPopup.Value = obj.selectedSection;

obj.View.handles.actionPopup.String = {obj.Sections(obj.selectedSection).Actions.Name}';
obj.View.handles.actionPopup.Value = obj.selectedAction;

obj.View.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.gui_WinMouseMotionFcn());   
obj.View.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.gui_WindowButtonDownFcn());   

end


