function mibRoiAddBtn_Callback(obj, options)
% function mibRoiAddBtn_Callback(obj)
% a callback to handles.mibRoiAddBtn, adds a roi to a dataset
%
% Parameters:
% 
% Return values:
% 

% Copyright (C) 15.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

type = obj.mibView.handles.mibRoiTypePopup.Value;
x1 = str2double(obj.mibView.handles.mibRoiX1Edit.String);
y1 = str2double(obj.mibView.handles.mibRoiY1Edit.String);
width = str2double(obj.mibView.handles.mibRoiWidthEdit.String);
height = str2double(obj.mibView.handles.mibRoiHeightEdit.String);
selected_pos = obj.mibView.handles.mibRoiList.Value;
obj.mibView.handles.mibRoiShowCheck.Value = 1;

switch type
    case 1  % rectangle
        if obj.mibView.handles.mibRoiManualCheck.Value     % use entered values
            obj.mibModel.I{obj.mibModel.Id}.hROI.addROI([], 'imrect', [], [x1 y1 width height]);
        else % place ROI interactively
            obj.mibModel.I{obj.mibModel.Id}.hROI.addROI(obj, 'imrect');
        end
    case 2  % ellipse
        if obj.mibView.handles.mibRoiManualCheck.Value     % use entered values
            obj.mibModel.I{obj.mibModel.Id}.hROI.addROI(obj, 'imellipse', [], [x1 y1 width height]);
        else % place ROI interactively
            obj.mibModel.I{obj.mibModel.Id}.hROI.addROI(obj, 'imellipse');
        end
    case 3  % polyline
        noPoints = str2double(obj.mibView.handles.mibRoiY1Edit.String);
        obj.mibModel.I{obj.mibModel.Id}.hROI.addROI(obj, 'impoly', [], [], noPoints);
    case 4  % imfreehand
        obj.mibModel.I{obj.mibModel.Id}.hROI.addROI(obj, 'imfreehand');
end

% restore mibGUI_WindowButtonDownFcn
obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());

% get number of ROIs
[number, indices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI();
str2 = cell([number+1 1]);
str2(1) = cellstr('All');
for i=1:number
%    str2(i+1) = cellstr(num2str(indices(i)));
    str2(i+1) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(indices(i)).label;
end

obj.mibView.handles.mibRoiList.String = str2;
if selected_pos ~= 1
    obj.mibView.handles.mibRoiList.Value = numel(str2);
end

obj.mibRoiShowCheck_Callback();
end
