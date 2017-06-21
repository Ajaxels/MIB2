function mibSegmentationSpot(obj, y, x, modifier)
% mibSegmentationSpot(obj, y, x, modifier)
% Do segmentation using the spot tool
%
% Parameters:
% y: y-coordinate of the spot center
% x: x-coordinate of the spot center
% modifier: a string, to specify what to do with the generated selection
% - @em empty - makes new selection
% - @em ''control'' - removes selection from the existing one
%
% Return values:

% Copyright (C) 22.02.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

switch3d = obj.mibView.handles.mibActions3dCheck.Value;     % use tool in 3d
selcontour = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2; % get selected contour
radius = str2double(obj.mibView.handles.mibSegmSpotSizeEdit.String)-2;
if radius < 1; radius = 0.5; end
radius = round(radius);
options.x = [x-radius x+radius];
options.y = [y-radius y+radius];
options.blockModeSwitch = 0;
% recalculate x and y for the obtained cropped image
x = radius + min([options.x(1) 1]);
y = radius + min([options.y(1) 1]);

currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
currSelection2 = zeros(size(currSelection), 'uint8');
currSelection2(y,x) = 1;
currSelection2 = bwdist(currSelection2); 
currSelection2 = uint8(currSelection2 <= radius);

orientation = obj.mibModel.getImageProperty('orientation');
if switch3d
    if orientation == 4
        backupOptions.y = options.y;
        backupOptions.x = options.x;
    elseif orientation == 1
        backupOptions.x = options.y;
        backupOptions.z = options.x;
    elseif orientation == 2
        backupOptions.y = options.y;
        backupOptions.z = options.x;
    end
    
    obj.mibModel.mibDoBackup('selection', 1, backupOptions);
    orient = NaN;
    [localHeight, localWidth, localColor, localThick] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'selection', orient, NaN, options);
    selarea = zeros([size(currSelection,1), size(currSelection,2), localThick],'uint8');
    options.z = [1, localThick];
    for layer_id = 1:size(selarea, 3)
        selarea(:,:,layer_id) = currSelection2;
    end
    
    % limit to the selected material of the model
    if obj.mibView.handles.mibSegmSelectedOnlyCheck.Value
        currSelection = cell2mat(obj.mibModel.getData3D('model', NaN, orient, selcontour, options));
        selarea = bitand(selarea, currSelection);
    end
    % limit selection to the masked area
    if obj.mibView.handles.mibMaskedAreaCheck.Value && obj.mibModel.getImageProperty('maskExist')   % do selection only in the masked areas
        currSelection = cell2mat(obj.mibModel.getData3D('mask', NaN, orient, selcontour, options));
        selarea = bitand(selarea, currSelection);
    end
    
    currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, orient, NaN, options));
    if isempty(modifier) || strcmp(modifier, 'shift')    % combines selections
        obj.mibModel.setData3D('selection', bitor(selarea, currSelection), NaN, orient, NaN, options);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection(selarea==1) = 0;
        obj.mibModel.setData3D('selection', currSelection, NaN, orient, NaN, options);
    end
else
    obj.mibModel.mibDoBackup('selection', 0, options);
    selarea = currSelection2;
    
    % limit to the selected material of the model
    if obj.mibView.handles.mibSegmSelectedOnlyCheck.Value
        currModel = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, selcontour, options));
        selarea = bitand(selarea, currModel);
    end
    
    % limit selection to the masked area
    if obj.mibView.handles.mibMaskedAreaCheck.Value && obj.mibModel.getImageProperty('maskExist')
        currModel = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, NaN, options));
        selarea = bitand(selarea, currModel);
    end
    
    if isempty(modifier) || strcmp(modifier, 'shift')    % combines selections
        obj.mibModel.setData2D('selection', bitor(currSelection, selarea), NaN, NaN, NaN, options);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection(selarea==1) = 0;
        obj.mibModel.setData2D('selection', currSelection, NaN, NaN, NaN, options);
    end
end
