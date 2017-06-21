function volren_winMouseMotionFcn(obj)
% function volren_winMouseMotionFcn(obj)
% change cursor shape when cursor is inside the axis during the volume
% rendering mode
%
% Parameters:
% 

% Copyright (C) 24.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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

if x>axXLim(1) && x<axXLim(2) && y>axYLim(1) && y<axYLim(2) % mouse pointer within the current axes
    obj.mibView.gui.Pointer = 'crosshair';
else
    obj.mibView.gui.Pointer = 'arrow';
end
end