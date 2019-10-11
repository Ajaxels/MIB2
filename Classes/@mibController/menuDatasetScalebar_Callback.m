function menuDatasetScalebar_Callback(obj, parameter)
% function menuDatasetScalebar_Callback(obj, parameter)
% a callback to Menu->Dataset->Scale bar
% calibrate pixel size from an existing scale bar
%

% Copyright (C) 02.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
global mibPath;

choice = questdlg(sprintf('The following procedure allows to define the pixel size for the dataset using a scale bar displayed on the image.\n\nHow to use:\n1. Specify the length of the scale bar\n2. With the left mouse button mark the end points of the scale bar\n3. Modify the scale bar by moving the end points\n4. Double click on the line to confirm the selection'), ...
    'Scale bar info', 'Continue', 'Cancel', 'Cancel');
if strcmp(choice, 'Cancel'); return; end
    
prompts = {'Length of the scale bar'; 'Units'};
defAns = {'2'; {'m', 'cm', 'mm', 'um', 'nm', 4}};
title = 'Scale bar lenght';
mibInputMultiDlgOptions.Columns = 2;
mibInputMultiDlgOptions.Title = sprintf('Please enter the length of the scale bar as shown on the image.\nRemember to specify the correct units!');
mibInputMultiDlgOptions.TitleLines = 3;
answer = mibInputMultiDlg([], prompts, defAns, title, mibInputMultiDlgOptions);

if isempty(answer) 
    obj.plotImage();
    return;
end

obj.mibModel.disableSegmentation = 1;    % disable segmentation while marking the scale bar
result = obj.mibModel.I{obj.mibModel.Id}.hMeasure.DistanceFun(obj); % use Measure class to draw a line above the scale bar
obj.mibModel.disableSegmentation = 0;    % disable segmentation while marking the scale bar

if result == 0 
    obj.plotImage();
    return; 
end

xCoord = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(end).X;    % get the X coordinates in pixels
yCoord = obj.mibModel.I{obj.mibModel.Id}.hMeasure.Data(end).Y;    % get the Y coordinates in pixels
distPix = sqrt((xCoord(1)-xCoord(2))^2 + (yCoord(1)-yCoord(2))^2);  % calculate the distance between two selected points
obj.mibModel.I{obj.mibModel.Id}.hMeasure.removeMeasurements(obj.mibModel.I{obj.mibModel.Id}.hMeasure.getNumberOfMeasurements());    % remove this measurement from the list

scaleLength = str2double(answer{1});
pixSize.units = answer{2};
pixSize.x = scaleLength / distPix;
pixSize.y = scaleLength / distPix;
pixSize.z = scaleLength / distPix;

obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution(pixSize);
obj.updateAxesLimits('resize');
obj.plotImage();
end