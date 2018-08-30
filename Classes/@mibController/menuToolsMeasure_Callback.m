function menuToolsMeasure_Callback(obj, type)
% function menuToolsMeasure_Callback(obj, type)
% a callback for selection of obj.mibView.handles.menuToolsMeasure entries
%
% Parameters:
% type:    a string with parameter for the tool
% @li 'tool', start a measure tool
% @li 'line', start a simple line measure tool
% @li 'freehand', start a simple freehand measure tool

% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

switch type
    case 'tool'
        obj.startController('mibMeasureToolController', obj);     % start the Measure Tool
        obj.mibView.handles.mibShowAnnotationsCheck.Value = 1;
        obj.mibModel.mibShowAnnotationsCheck = 1;
        return;
    case 'line'
        %obj.mibModel.mibDoBackup('selection', 0);
        obj.mibView.gui.WindowButtonDownFcn = [];
        roi = imline(obj.mibView.handles.mibImageAxes);
    case 'freehand'
        %obj.mibModel.mibDoBackup('selection', 0);
        obj.mibView.gui.WindowButtonDownFcn = [];
        roi = imfreehand(obj.mibView.handles.mibImageAxes, 'Closed', 'false');
end
resume(roi);
pos = roi.getPosition();
magFactor = obj.mibModel.getMagFactor();
[axesX, axesY] = obj.mibModel.getAxesLimits();
pos(:,1) = pos(:,1)*magFactor + max([0 floor(axesX(1))]);
pos(:,2) = pos(:,2)*magFactor + max([0 floor(axesY(1))]);
delete(roi);

% restore mibGUI_WindowButtonDownFcn
obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());

% helpSubString ='';
% if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 0
%     img = cell2mat(obj.mibModel.getData2D('selection'));
%     img = mibConnectPoints(img, pos);
%     obj.mibModel.setData2D('selection', {img});
%     helpSubString = 'Use the "C"-key shortcut to clear the measured path';
% end
orientation = obj.mibModel.getImageProperty('orientation');
pixSize = obj.mibModel.getImageProperty('pixSize');
if orientation == 4   % xy plane
    x = pixSize.x;
    y = pixSize.y;
elseif orientation == 1   % xz plane
    x = pixSize.z;
    y = pixSize.x;
elseif orientation == 2   % yz plane
    x = pixSize.z;
    y = pixSize.y;
end
distance = 0;
for i=2:size(pos,1)
    distance = distance + sqrt(((pos(i,1)-pos(i-1,1))*x)^2 + ((pos(i,2)-pos(i-1,2))*y)^2);
end
str2 = ['Distance = ' num2str(distance) ' ' pixSize.units];
msgbox(sprintf('%s\nThe measured length has been also copied to the system clipboard', str2), 'Measure...', 'help');
disp(str2);
clipboard('copy', [num2str(distance) ' ' pixSize.units])
obj.plotImage();

end