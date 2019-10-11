function mibSegmentationLasso(obj, modifier)
% function mibSegmentationLasso(obj, modifier)
% Do segmentation using the lasso tool
%
% Parameters:
% modifier: a string, to specify what to do with the generated selection
% - @em empty - makes new selection
% - @em ''control'' - removes selection from the existing one
%
% Return values:
% 

% Copyright (C) 19.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 28.11.2018, IB added modification of ROIs after placing them

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

switch3d = obj.mibView.handles.mibActions3dCheck.Value;     % use tool in 3d
selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
list = obj.mibView.handles.mibFilterSelectionPopup.String;
type = list{obj.mibView.handles.mibFilterSelectionPopup.Value};    % Lasso or Rectangle

obj.mibView.gui.Pointer = 'cross';
obj.mibView.gui.WindowButtonDownFcn = [];

switch type
    case 'Lasso'
        h = imfreehand(obj.mibView.handles.mibImageAxes);
        wait(h);
    case 'Rectangle'
        h = imrect(obj.mibView.handles.mibImageAxes); 
        wait(h);
    case 'Ellipse'
        h = imellipse(obj.mibView.handles.mibImageAxes);
        wait(h);
    case 'Polyline'
        h =  impoly(obj.mibView.handles.mibImageAxes);
        wait(h);
end

try
    selected_mask = uint8(h.createMask);
catch err
    return;
end
delete(h);
obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
obj.mibView.gui.Pointer = 'crosshair';

getDataOptions.blockModeSwitch = 1;
currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, getDataOptions));
selected_mask = imresize(selected_mask, [size(currSelection,1) size(currSelection,2)], 'method', 'nearest');

% calculating bounding box for the backup
CC = regionprops(selected_mask, 'BoundingBox');
bb = CC.BoundingBox;
[axesX, axesY] = obj.mibModel.getAxesLimits();
bb(1) = bb(1) + max([1 ceil(axesX(1))])-1;
bb(2) = bb(2) + max([1 ceil(axesY(1))])-1;

orientation = obj.mibModel.getImageProperty('orientation');
if orientation == 4
    backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
    backupOptions.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
elseif orientation == 1
    backupOptions.x = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
    backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
elseif orientation == 2
    backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
    backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
end

if switch3d     % 3d case
    wb = waitbar(0, 'Please wait');
    obj.mibModel.mibDoBackup('selection', 1, backupOptions);
    orient = NaN;
    [localHeight, localWidth, localColor, localThick] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'selection', orient, NaN, getDataOptions);
    selarea = zeros([localHeight localWidth localThick], 'uint8');
    currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, NaN, NaN, getDataOptions));
    for layer_id = 1:size(selarea, 3)
        selarea(:,:,layer_id) = selected_mask;
    end
    waitbar(0.3, wb);
    
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
        currModel = cell2mat(obj.mibModel.getData3D('model', NaN, NaN, selcontour, getDataOptions));
        selarea = bitand(selarea, currModel);
    end
    waitbar(0.6, wb);
    
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask && obj.mibModel.getImageProperty('maskExist')   % do selection only in the masked areas
        currModel = cell2mat(obj.mibModel.getData3D('mask', NaN, 4, NaN, getDataOptions));
        selarea = bitand(selarea, currModel);
    end
    waitbar(0.9, wb);
    if isempty(modifier) || strcmp(modifier, 'shift')    % combines selections
        obj.mibModel.setData3D('selection', {bitor(selarea, currSelection)}, NaN, orient, NaN, getDataOptions);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection(selarea==1) = 0;
        obj.mibModel.setData3D('selection', {currSelection}, NaN, orient, NaN, getDataOptions);
    end
    waitbar(1, wb);
    delete(wb);
else    % 2d case
    obj.mibModel.mibDoBackup('selection', 0);
    selarea = selected_mask;
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
        currModel = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, selcontour, getDataOptions));
        selarea = bitand(selarea, currModel);
    end
    
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask && obj.mibModel.getImageProperty('maskExist')  
        currModel = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, selcontour, getDataOptions));
        selarea = bitand(selarea, currModel);
    end
    
    if isempty(modifier) || strcmp(modifier, 'shift')    % combines selections
        obj.mibModel.setData2D('selection', {bitor(currSelection, selarea)}, NaN, NaN, selcontour, getDataOptions);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection(selarea==1) = 0;
        obj.mibModel.setData2D('selection', {currSelection}, NaN, NaN, selcontour, getDataOptions);
    end
end
