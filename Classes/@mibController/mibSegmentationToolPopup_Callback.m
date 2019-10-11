function mibSegmentationToolPopup_Callback(obj)
% function mibSegmentationToolPopup_Callback(obj)
% a callback to the handles.mibSegmentationToolPopup, allows to select tool for the segmentation
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 23.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


% Selection of tools for segmentation
val = obj.mibView.handles.mibSegmentationToolPopup.Value;
toolsList = obj.mibView.handles.mibSegmentationToolPopup.String;
selectedTool = strtrim(toolsList{val});
obj.mibView.handles.mibSegmMagicPanel.Visible = 'off';
obj.mibView.handles.mibSegmAnnPanel.Visible = 'off';
obj.mibView.handles.mibSegmLines3DPanel.Visible = 'off';
obj.mibView.handles.mibSegmObjectPickerPanel.Visible = 'off';
obj.mibView.handles.mibSegmSpotPanel.Visible = 'off';
obj.mibView.handles.mibSegmThresPanel.Visible = 'off';
obj.mibView.handles.mibSegmMembTracerPanel.Visible = 'off';
obj.mibView.handles.mibSegmDragDropPanel.Visible = 'off';
obj.mibView.showBrushCursor = 0;

if ~isempty(find(obj.mibModel.preferences.lastSegmTool == val, 1)) % the selected tool is also a fast access tool for the 'd' shortcut
    obj.mibView.handles.mibSegmFavToolCheck.Value = 1;
    obj.mibView.handles.mibSegmentationToolPopup.BackgroundColor = [1 .69 .39];    
else
    obj.mibView.handles.mibSegmFavToolCheck.Value = 0;
    obj.mibView.handles.mibSegmentationToolPopup.BackgroundColor = [1 1 1];
end

switch selectedTool
    case 'Annotations'
        obj.mibView.handles.mibSegmAnnPanel.Visible = 'on';
    case '3D lines'
        obj.mibView.handles.mibSegmLines3DPanel.Visible = 'on';
    case 'Lasso'
        obj.mibView.handles.mibSegmObjectPickerPanel.Visible = 'on';
        obj.mibView.handles.mibSegmObjectPickerPanelSub.Visible = 'off';
        obj.mibView.handles.mibSegmObjectPickerPanelSub2.Visible = 'on';
        list = obj.mibView.handles.mibFilterSelectionPopup.String;
        if numel(list) > 5 % reinitialize the list, because it is shared with Object Picker tool
            list = {'Lasso','Rectangle','Ellipse','Polyline'};
            obj.mibView.handles.mibFilterSelectionPopup.Value = 2;
            obj.mibView.handles.mibFilterSelectionPopup.String = list;
        end
    case 'MagicWand-RegionGrowing'
        obj.mibView.handles.mibSegmMagicPanel.Visible = 'on';
    case 'Drag & Drop materials'
        obj.mibView.handles.mibSegmDragDropPanel.Visible = 'on';
    case 'Object Picker'
        obj.mibView.handles.mibSegmObjectPickerPanel.Visible = 'on';
        obj.mibView.handles.mibSegmObjectPickerPanelSub.Visible = 'on';
        obj.mibView.handles.mibSegmObjectPickerPanelSub2.Visible = 'off';
        
        list = obj.mibView.handles.mibFilterSelectionPopup.String;
        if numel(list) < 7     % reinitialize the list, because it is shared with Lasso tool
            list = {'Click','Lasso','Rectangle','Ellipse','Polyline','Mask within Selection'};
            obj.mibView.handles.mibFilterSelectionPopup.String = list;
            obj.mibView.handles.mibFilterSelectionPopup.Value = 1;
        end
        if strcmp(list{obj.mibView.handles.mibFilterSelectionPopup.Value'}, 'Brush') && obj.mibModel.I{obj.mibModel.Id}.disableSelection == 0
            obj.mibView.showBrushCursor = 1;
        end
    case {'Spot', '3D ball'}
        if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 0
            obj.mibView.showBrushCursor = 1;
        end
        obj.mibView.handles.mibSegmSpotPanel.Visible = 'on';
        obj.mibView.handles.mibSpotPanelClusteringText.Visible = 'off';
        obj.mibView.handles.mibBrushSuperpixelsCheck.Visible = 'off';
        obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Visible = 'off';
        obj.mibView.handles.mibBrushPanelNText.Visible = 'off';
        obj.mibView.handles.mibSuperpixelsNumberEdit.Visible = 'off';
        obj.mibView.handles.mibBrushPanelCompactText.Visible = 'off';
        obj.mibView.handles.mibSuperpixelsCompactEdit.Visible = 'off';
    case 'Brush'
        obj.mibView.handles.mibSegmSpotPanel.Visible = 'on';
        if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 0
            obj.mibView.showBrushCursor = 1;
        end
        obj.mibView.handles.mibSpotPanelClusteringText.Visible = 'on';
        obj.mibView.handles.mibBrushSuperpixelsCheck.Visible = 'on';
        obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Visible = 'on';
        obj.mibView.handles.mibBrushPanelNText.Visible = 'on';
        obj.mibView.handles.mibSuperpixelsNumberEdit.Visible = 'on';
        obj.mibView.handles.mibBrushPanelCompactText.Visible = 'on';
        obj.mibView.handles.mibSuperpixelsCompactEdit.Visible = 'on';
    case 'BW Thresholding'
        obj.mibView.handles.mibSegmThresPanel.Visible = 'on';
    case 'Membrane ClickTracker'
        obj.mibView.handles.mibSegmMembTracerPanel.Visible = 'on';
end
obj.mibView.updateCursor();
end