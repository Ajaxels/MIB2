function mibGUI_WindowButtonUpFcn(obj, brush_switch)
% function mibGUI_WindowButtonUpFcn(obj, brush_switch)
% callback for release of the mouse button
%
% Parameters:
% brush_switch: when ''subtract'' - subtracts the brush selection from the existing selection, needed for return after the brush drawing tool

% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if iscell(obj.mibView.brushSelection)  % return after movement of the brush tool
    if numel(obj.mibView.brushSelection) > 1
        obj.mibView.brushSelection{1} = obj.mibView.brushSelection{2}.selectedSlic;
    end
    getDataOptions.blockModeSwitch = 1;
    getDataOptions.roiId = -1;
    currSelection = cell2mat(obj.mibModel.getData2D('selection',NaN, NaN, NaN, getDataOptions));
    obj.mibView.brushSelection{1} = imresize(obj.mibView.brushSelection{1}, size(currSelection),'method','nearest');
    
%     % smooth brush, quite slow
%     filterOptions.fitType = 'Gaussian';
%     filterOptions.hSize = 11;
%     filterOptions.sigma = filterOptions.hSize;
%     filterOptions.showWaitbar = 0;
%     filterOptions.dataType = '3D';
%     filterOptions.orientation = 4;
%     obj.mibView.brushSelection{1} = mibDoImageFiltering(obj.mibView.brushSelection{1}, filterOptions);
    
    selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
    
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial
        currModel = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, NaN, getDataOptions));
        obj.mibView.brushSelection{1}(currModel~=selcontour) = 0;
    end
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask
        mask = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, NaN, getDataOptions));
        obj.mibView.brushSelection{1}(mask ~= 1) = 0;
    end
    if strcmp(brush_switch, 'subtract')
        currSelection(obj.mibView.brushSelection{1}==1) = 0;
        obj.mibModel.setData2D('selection',currSelection, NaN, NaN, NaN, getDataOptions);
    else
        obj.mibModel.setData2D('selection', uint8(currSelection | obj.mibView.brushSelection{1}), NaN, NaN, NaN, getDataOptions);
    end
end
obj.mibView.brushSelection = NaN;    % remove all brush_selection data
obj.mibView.brushPrevXY = NaN;

% update ROI of the Measure tool
if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.type)
    obj.mibModel.I{obj.mibModel.Id}.hMeasure.updateROIScreenPosition('crop');
end

% update ROI of the hROI class
if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hROI.roi.type)
    obj.mibModel.I{obj.mibModel.Id}.hROI.updateROIScreenPosition('crop');
end

obj.mibView.gui.Pointer = 'crosshair';
obj.mibView.gui.WindowButtonUpFcn = [];
%obj.mibView.gui.WindowButtonDownFcn = {@im_browser_WindowButtonDownFcn, handles});
obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(hObject, eventdata)); % turn ON callback for the keys

if obj.mibView.centerSpotHandle.enable
    obj.mibView.centerSpotHandle.handle.Visible = 'on';
end

obj.plotImage();
obj.mibView.updateCursor('dashed');
obj.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) obj.mibGUI_ScrollWheelFcn(eventdata));   % moved from plotImage
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());   % moved from plotImage

end
