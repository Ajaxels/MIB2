function mibRoiToSelectionBtn_Callback(obj)
% function mibRoiToSelectionBtn_Callback(obj)
% a callback to obj.mibView.handles.mibRoiToSelectionBtn, highlight area
% under the selected ROI in the Selection layer
%
% Parameters:
% 
% Return values:
% 

% Copyright (C) 13.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

% get index of the ROI
roiNo = obj.mibModel.I{obj.mibModel.Id}.selectedROI;
if roiNo(1) < 0
    warndlg(sprintf('!!! Warning !!!\n\nNo ROIs were detected!\nAdd a new ROI area and try again.'), 'ROI is missing');
    return;
end

% define whether the selection should be expanded to 3D space
mode3D = 0;
modifier = obj.mibView.gui.CurrentModifier;
if ismember({'shift'}, modifier)
    mode3D = 1;
elseif obj.mibView.handles.mibActions3dCheck.Value == 1
    mode3D = 1;
end

backupOptions.blockModeSwitch = 0;
[Height, Width, ~, Depth] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', NaN, NaN, backupOptions);

index = 1;
for roiId = roiNo
    if index == 1
        selected_mask = obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(roiId, Height, Width, NaN, backupOptions.blockModeSwitch);
    else
        selected_mask = bitor(selected_mask, obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(roiId, Height, Width, NaN, backupOptions.blockModeSwitch));
    end
    index = index + 1;
end

% calculating bounding box for the backup
CC = regionprops(selected_mask, 'BoundingBox');
bb = CC.BoundingBox;

if obj.mibModel.getImageProperty('orientation')
    backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
    backupOptions.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
elseif obj.mibModel.getImageProperty('orientation') == 1
    backupOptions.x = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
    backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
elseif obj.mibModel.getImageProperty('orientation') == 2
    backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
    backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
end
selected_mask = selected_mask(backupOptions.y(1):backupOptions.y(2), backupOptions.x(1):backupOptions.x(2));

% propagate in 3D
if mode3D
    obj.mibModel.mibDoBackup('selection', 1, backupOptions);
    currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, NaN, NaN, backupOptions));
    selarea = zeros(size(currSelection), 'uint8');
    for layer_id = 1:size(selarea, 3)
        selarea(:,:,layer_id) = selected_mask;
    end
    
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial
        selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        currModel = cell2mat(obj.mibModel.getData3D('model', NaN, NaN, selcontour, backupOptions));
        selarea = bitand(selarea, currModel);
    end
    
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask && obj.mibView.getImageProperty('maskExist')   % do selection only in the masked areas
        currModel = cell2mat(obj.mibModel.getData3D('mask', NaN, 4, NaN, backupOptions));
        selarea = bitand(selarea, currModel);
    end
    obj.mibModel.setData3D('selection', {bitor(selarea, currSelection)}, NaN, NaN, NaN, backupOptions);
else
    obj.mibModel.mibDoBackup('selection', 0);
    currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, backupOptions));
    
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial
        selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
        currModel = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, selcontour, backupOptions));
        selected_mask = bitand(selected_mask, currModel);
    end
    
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask && obj.mibView.getImageProperty('maskExist')
        currModel = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, NaN, backupOptions));
        selected_mask = bitand(selected_mask, currModel);
    end
    obj.mibModel.setData2D('selection', {bitor(currSelection, selected_mask)}, NaN, NaN, NaN, backupOptions);
end
obj.plotImage(0);
end
