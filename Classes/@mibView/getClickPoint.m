function [xData,yData,zData, xClick, yClick] = getClickPoint(obj, nTimes, permuteSw)
% function [xData,yData,zData, xClick, yClick] = getClickPoint(obj, nTimes, permuteSw)
% A function that gets ginput function to pick a point within handles.mibImageAxes 
%
% Parameters:
% nTimes: [@em optional] number of points to get, default = 1
% permuteSw: [@em optional], can be @em empty
% @li when @b 0 returns the coordinates for the dataset in the original xy-orientation;
% @li when @b 1 (@b default) returns coordinates for the dataset so that the currently selected orientation becomes @b xy
%
%
% Return values:
% xData: x - coordinate within the dataset
% yData: y - coordinate within the dataset
% zData: z - coordinate within the dataset; @b note! The Z-value is the same for all points
% xClick: x - coordinate of the click
% yClick: y - coordinate of the dataset


%| 
% @b Examples:
% @code [xData,yData,zData, xClick, yClick] = mibView.getClickPoint();  // get 1 point @endcode
% @code [xData,yData,zData, xClick, yClick] = mibView.getClickPoint(5);  // get 5 points @endcode

% Copyright (C) 15.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 


if nargin < 3; permuteSw = 1;  end
if nargin < 2; nTimes = []; end
if isempty(nTimes); nTimes = 1; end

% xData, yData, zData - coordinates of the click in the dataset
% xClick, yClick - coordinates of the click in the axes

% remove callbacks for key and mouse press
obj.gui.WindowButtonDownFcn = [];
obj.gui.WindowKeyPressFcn = [];

% get point, need to switch on visibility of callbacks
obj.gui.HandleVisibility = 'callback';

set(0, 'CurrentFigure', obj.gui);
obj.gui.CurrentAxes = obj.handles.mibImageAxes;
[xClick, yClick] = my_ginput(nTimes);
% turn off visibility of callbacks
obj.gui.HandleVisibility = 'off';

% restore callbacks for key and mouse press
obj.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibController.mibGUI_WindowButtonDownFcn());
obj.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibController.mibGUI_WindowKeyPressFcn(hObject, eventdata));

[xData,yData,zData] = obj.mibModel.convertMouseToDataCoordinates(xClick, yClick, 'shown', permuteSw);

% % testing the output
% str1 = sprintf('%dx%d -> %dx%d x%f axX=%.3f %.3f\n', handles.Img{handles.Id}.I.width, handles.Img{handles.Id}.I.height, size(handles.Img{handles.Id}.I.Ishown,2), size(handles.Img{handles.Id}.I.Ishown,1), handles.Img{handles.Id}.I.magFactor, handles.Img{handles.Id}.I.axesX(1),handles.Img{handles.Id}.I.axesX(2));
% str2 = sprintf('(x,y)=%.3f,%.3f -> %.3f,%.3f\n', xClick,yClick,xData,yData);
% disp([str1 str2])
% for point=1:numel(xClick)
%     handles.Img{handles.Id}.I.hLabels.addLabels('', [zData(point),xData(point),yData(point)]);
% end
% handles.Img{handles.Id}.I.plotImage(handles.imageAxes, handles, 0);
