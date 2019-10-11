function mibSegmentationLassoManual(obj, modifier)
% function mibSegmentationLassoManual(obj, modifier)
% Do manual segmentation using the lasso tool in the manual mode
%
% use the following fields to define selected area:
% obj.mibView.handles.mibSegmObjectPickerPanelSub2X1,
% obj.mibView.handles.mibSegmObjectPickerPanelSub2Y1,
% obj.mibView.handles.mibSegmObjectPickerPanelSub2Width,
% obj.mibView.handles.mibSegmObjectPickerPanelSub2Height edit boxes
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
% 

switch3d = obj.mibView.handles.mibActions3dCheck.Value;     % use tool in 3d
selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
list = obj.mibView.handles.mibFilterSelectionPopup.String;
type = list{obj.mibView.handles.mibFilterSelectionPopup.Value};    % Lasso or Rectangle

bb(1) = str2double(obj.mibView.handles.mibSegmObjectPickerPanelSub2X1.String);
bb(2) = str2double(obj.mibView.handles.mibSegmObjectPickerPanelSub2Y1.String);
bb(3) = str2double(obj.mibView.handles.mibSegmObjectPickerPanelSub2Width.String);
bb(4) = str2double(obj.mibView.handles.mibSegmObjectPickerPanelSub2Height.String);

switch type
    case 'Lasso'
        return;
    case 'Rectangle'
        
    case 'Ellipse'
        return;
    case 'Polyline'
        return;
end

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

getDataOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
getDataOptions.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];

if switch3d     % 3d case
    obj.mibModel.mibDoBackup('selection', 1, backupOptions);
    currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, NaN, NaN, getDataOptions));
    selarea = zeros(size(currSelection), 'uint8') + 1;
    %selarea(ceil(bb(2)):ceil(bb(2))+floor(bb(4))-1, ceil(bb(1)):ceil(bb(1))+floor(bb(3))-1, :) = 1;
    
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
        currModel = cell2mat(obj.mibModel.getData3D('model', NaN, NaN, selcontour, getDataOptions));
        selarea = bitand(selarea, currModel);
    end
    
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask && obj.mibModel.getImageProperty('maskExist')   % do selection only in the masked areas
        currModel = cell2mat(obj.mibModel.getData3D('mask', NaN, 4, NaN, getDataOptions));
        selarea = bitand(selarea, currModel);
    end
    if isempty(modifier) || strcmp(modifier, 'shift')    % combines selections
        obj.mibModel.setData3D('selection', {bitor(selarea, currSelection)}, NaN, NaN, NaN, getDataOptions);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection(selarea==1) = 0;
        obj.mibModel.setData3D('selection', {currSelection}, NaN, NaN, NaN, getDataOptions);
    end
else    % 2d case
    obj.mibModel.mibDoBackup('selection', 0);
    currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, getDataOptions));
    selarea = zeros(size(currSelection), 'uint8') + 1;
    
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
obj.plotImage();
end
