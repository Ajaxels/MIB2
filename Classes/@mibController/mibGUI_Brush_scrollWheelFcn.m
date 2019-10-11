function mibGUI_Brush_scrollWheelFcn(obj, eventdata)
% function mibGUI_Brush_scrollWheelFcn(obj, eventdata)
% Control callbacks from mouse scroll wheel during the brush tool
%
%
% Parameters:
% eventdata: additinal parameters

% Copyright (C) 15.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

modifier = obj.mibView.gui.CurrentModifier;   % change size of the brush tool, when the Ctrl key is pressed

step = .2;   % step of the brush size change
if strcmp(cell2mat(modifier), 'shift')
    step = 1;
elseif strcmp(cell2mat(modifier), 'shiftcontrol')
    step = 5;
end

if eventdata.VerticalScrollCount < 0
    obj.mibView.brushSelection{3}.factor = obj.mibView.brushSelection{3}.factor + step;
else
    obj.mibView.brushSelection{3}.factor = obj.mibView.brushSelection{3}.factor - step;
    if obj.mibView.brushSelection{3}.factor < 0; obj.mibView.brushSelection{3}.factor = 0.1; end;
end
obj.mibView.handles.mibDilateAdaptCoefEdit.String = num2str(obj.mibView.brushSelection{3}.factor);

end