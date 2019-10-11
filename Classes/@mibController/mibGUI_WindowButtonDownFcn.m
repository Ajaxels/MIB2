function mibGUI_WindowButtonDownFcn(obj)
% function mibGUI_WindowButtonDownFcn(obj)
% this is callback for the press of a mouse button
%
% Parameters:
% 

% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


val = obj.mibView.handles.mibSegmentationToolPopup.Value; % get a selected instrument: filter, magic wand, brush etc
txt = obj.mibView.handles.mibSegmentationToolPopup.String;
tool = cell2mat(txt(val));
tool = strtrim(tool);   % remove ending space
switch3d = obj.mibView.handles.mibActions3dCheck.Value;     % use filters in 3d
xy = obj.mibView.handles.mibImageAxes.CurrentPoint;
seltype = obj.mibView.gui.SelectionType;
modifier = obj.mibView.gui.CurrentModifier;
% swap left and right mouse buttons check
if strcmp(obj.mibView.handles.toolbarSwapMouse.State, 'on')
    if strcmp(seltype,'normal')
        seltype = 'extend';
    elseif strcmp(seltype,'alt') && isempty(modifier)
        seltype = 'normal';
    end
end

position2 = obj.mibView.gui.CurrentPoint;
x2 = round(position2(1,1));
y2 = round(position2(1,2));
separatingPanelPos = obj.mibView.handles.mibSeparatingPanel.Position;
if x2>separatingPanelPos(1) && x2<separatingPanelPos(1)+separatingPanelPos(3) && y2>separatingPanelPos(2) && y2<separatingPanelPos(2)+separatingPanelPos(4) % mouse pointer within the current axes
    obj.mibView.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.mibGUI_PanelShiftBtnUpFcn('mibSeparatingPanel'));
    obj.mibView.gui.WindowButtonMotionFcn = [];
    obj.mibView.gui.Pointer = 'left';
    return;
end
separatingPanelPos = obj.mibView.handles.mibSeparatingPanel2.Position;
if x2>separatingPanelPos(1) && x2<separatingPanelPos(1)+separatingPanelPos(3) && y2>separatingPanelPos(2) && y2<separatingPanelPos(2)+separatingPanelPos(4) % mouse pointer within the current axes
    obj.mibView.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.mibGUI_PanelShiftBtnUpFcn('mibSeparatingPanel2'));
    obj.mibView.gui.WindowButtonMotionFcn = [];
    obj.mibView.gui.Pointer = 'top';
    return;
end


if strcmp(seltype,'normal') %& strcmp(modifier,'alt')
    %%     % Start the pan mode
    obj.mibView.gui.WindowKeyPressFcn = [];  % turn off callback for the keys during the panning
    if obj.mibView.centerSpotHandle.enable
        obj.mibView.centerSpotHandle.handle.Visible = 'off';
    end
    
    % check for the mouse inside the image axes
    xlim = obj.mibView.handles.mibImageAxes.XLim;
    ylim = obj.mibView.handles.mibImageAxes.YLim;
    if xy(1,1) < xlim(1) || xy(1,2) < ylim(1) || xy(1,1) > xlim(2) || xy(1,2) > ylim(2); return; end
    
    if ishandle(obj.mibView.cursor)
       obj.mibView.cursor.Visible = 'off';
    end
    
    % get full image:
    if strcmp(obj.mibView.handles.toolbarFastPanMode.State, 'off')
        rgbOptions.blockModeSwitch = 0;     % get full image
        imgRGB = obj.mibModel.getRGBimage(rgbOptions);
        obj.mibView.imh.CData = [];
        obj.mibView.imh.CData = imgRGB;
        
        % delete shown measurements
        lineObj = findobj(obj.mibView.handles.mibImageAxes,'tag','measurements','-or','tag','roi');
        if ~isempty(lineObj); delete(lineObj); end     % keep it within if, because it is faster
        % show measurements
        if obj.mibModel.mibShowAnnotationsCheck
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.addMeasurementsToPlot(obj.mibModel, 'full', obj.mibView.handles.mibImageAxes);
        end
        
        % show ROIs
        if obj.mibView.handles.mibRoiShowCheck.Value
            obj.mibModel.I{obj.mibModel.Id}.hROI.addROIsToPlot(obj, 'full');
        end
        
        magFactor = obj.mibModel.getMagFactor;
        [axesX, axesY] = obj.mibModel.getAxesLimits();
        if magFactor < 1    % the image is not rescaled if magFactor less than 1
            obj.mibView.handles.mibImageAxes.XLim = axesX;
            obj.mibView.handles.mibImageAxes.YLim = axesY;
            % modify xy with respect to the magFactor and shifts of the axes
            xy2(1) = xy(1,1)*magFactor + max([axesX(1) 0]);
            xy2(2) = xy(1,2)*magFactor + max([axesY(1) 0]);
        else
            obj.mibView.handles.mibImageAxes.XLim = axesX/magFactor;
            obj.mibView.handles.mibImageAxes.YLim = axesY/magFactor;
            % modify xy with respect to the magFactor and shifts of the axes
            xy2(1) = xy(1,1)+max([axesX(1)/magFactor 0]);
            xy2(2) = xy(1,2)+max([axesY(1)/magFactor 0]);
        end
        imgWidth = size(imgRGB,2);
        imgHeight = size(imgRGB,1);
        
        if obj.mibView.handles.mibRoiShowCheck.Value
            obj.mibModel.I{obj.mibModel.Id}.hROI.updateROIScreenPosition('full');
        end
        
        % update ROI of the Measure tool
        if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.type)
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.updateROIScreenPosition('full');
        end
    else
        xdata = obj.mibView.imh.XData;
        ydata = obj.mibView.imh.YData;
        imgWidth = xdata(2);
        imgHeight = ydata(2);
        xy2(1) = xy(1,1);
        xy2(2) = xy(1,2);
    end
    
    obj.mibView.gui.WindowButtonDownFcn = [];  % turn off callback for the mouse key press during the pan mode
    obj.mibView.gui.WindowScrollWheelFcn = []; % turn off callback for the mouse wheel during the pan mode
    obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_panAxesFcn(xy2, imgWidth, imgHeight));
    
    
    setptr(obj.mibView.gui, 'closedhand');  % undocumented matlab http://undocumentedmatlab.com/blog/undocumented-mouse-pointer-functions/
    obj.mibView.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonUpFcn());
elseif strcmp(seltype,'extend') || strcmp(seltype,'alt')   % shift+left mouse, or both mouse buttons
    %% Start segmentation mode
    %y = round(xy(1,2));
    %x = round(xy(1,1));
    if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1 && ~ismember(tool, {'Annotations', '3D lines'})
        return; 
    end    % no selection layer
    
    if xy(1,1) < 1 || xy(1,2) < 1 || xy(1,1) > size(obj.mibView.Ishown,2) || xy(1,2) > size(obj.mibView.Ishown,1)
        return; 
    end
    
    % x, y - x/y coordinates of a pixel that was clicked for the full dataset
    %x = xy(1,1)*obj.mibView.handles.Img{obj.mibView.handles.Id}.I.magFactor + max([0 floor(obj.mibView.handles.Img{obj.mibView.handles.Id}.I.axesX(1))]);
    %y = xy(1,2)*obj.mibView.handles.Img{obj.mibView.handles.Id}.I.magFactor + max([0 floor(obj.mibView.handles.Img{obj.mibView.handles.Id}.I.axesY(1))]);
    
    switch tool
        case '3D ball'
            % 3D ball: filled shere in 3d with a center at the clicked point
            [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 0);
            obj.mibSegmentation3dBall(ceil(h), ceil(w), ceil(z), modifier);
            return;
        case '3D lines'
            [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 0);
            obj.mibSegmentationLines3D(h, w, z, modifier);
            
            if obj.mibView.handles.mibSegmTrackRecenterCheck.Value == 1 && isempty(modifier)  % recenter the view
                obj.mibModel.I{obj.mibModel.Id}.moveView(w, h);
            end
            obj.plotImage();
            return;
        case 'Annotations'
            % add text annotation
            [w, h, z, t] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 0);
            obj.mibSegmentationAnnotation(h, w, z, t, modifier);
        case {'Brush'}
            % the Brush mode
            x = round(xy(1,1));
            y = round(xy(1,2));
            obj.mibView.gui.WindowScrollWheelFcn = []; % turn off callback for the mouse wheel during the brush selection
            obj.mibView.gui.WindowKeyPressFcn = [];  % turn off callback for the keys during the brush selection
            obj.mibSegmentationBrush(y, x, modifier);
            return;
        case 'BW Thresholding'
            % Black and white thresholding
            return;
        case 'Drag & Drop materials'
            % Drag and drop selection with the mouse
            x = round(xy(1,1));
            y = round(xy(1,2));
            if isempty(modifier); return; end
            obj.mibView.gui.WindowScrollWheelFcn = []; % turn off callback for the mouse wheel during the brush selection
            obj.mibView.gui.WindowKeyPressFcn = [];  % turn off callback for the keys during the brush selection
            obj.mibSegmentationDragAndDrop(y, x, modifier);
            return;
        case 'Lasso'
            % Lasso mode
            if strcmp(obj.mibView.handles.mibSegmObjectPickerPanelSub2Select.Enable, 'on'); return; end   % cancel when the manual mode is enabled
            modifier = '';
            % have to define subtract action differently for the lasso type of tools
            if obj.mibView.handles.mibSegmObjectPickerPanelAddPopup.Value == 2 % subtract mode
                modifier = 'control';
            end
            try
                obj.mibSegmentationLasso(modifier);
            catch err
                %err
            end
        case {'MagicWand-RegionGrowing'}
            % Magic Wand mode
            magicWandRadius = str2double(obj.mibView.handles.mibMagicWandRadius.String);
            if switch3d
                if obj.mibModel.getImageProperty('blockModeSwitch') == 1 && magicWandRadius == 0
                    [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'blockmode', 0);
                else
                    [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 0);
                end
                yxzCoordinate = [h, w, z];
            else
                %yxzCoordinate = [yCrop, xCrop];
                if obj.mibModel.getImageProperty('blockModeSwitch') == 1 && magicWandRadius == 0
                    [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'blockmode', 1);    
                else
                    [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 1);    
                end
                yxzCoordinate = [h, w, z];
            end

            subTool = obj.mibView.handles.mibMagicwandMethodPopup.Value;    % magic wand or region growing
            % make new selection with shift and add to the selection
            % without modifiers
            if isempty(modifier)
                modifier = 'shift'; 
            elseif strcmp(modifier, 'shift')
                modifier = [];
            end
            
            if subTool == 1
                obj.mibSegmentationMagicWand(ceil(yxzCoordinate), modifier);
            else
                obj.mibSegmentationRegionGrowing(ceil(yxzCoordinate), modifier);
            end
        case 'Object Picker'
            % targeted selection from Mask/Models layers
            if switch3d
                [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 0); 
            else
                if obj.mibModel.getImageProperty('blockModeSwitch') == 1
                    [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'blockmode', 1); 
                else
                    [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 1); 
                end
            end
            yxzCoordinate = [h,w,z];
            try
                obj.mibSegmentationObjectPicker(ceil(yxzCoordinate), modifier);
            catch err
            end
            if obj.mibView.handles.mibFilterSelectionPopup.Value == 6; return; end     % return when using the Brush tool
        case 'Membrane ClickTracker'
            % Trace membranes
            if switch3d
                [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 0);
            else
                [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 1);
            end
            yxzCoordinate = [h,w,z];
            yx(1) = xy(1,2);
            yx(2) = xy(1,1);
            output = obj.mibSegmentationMembraneClickTraker(ceil(yxzCoordinate), yx, modifier);
            if strcmp(output, 'return')
%                 if obj.mibView.handles.mibSegmTrackRecenterCheck.Value == 1     % recenter the view
%                     obj.mibModel.I{obj.mibModel.Id}.moveView(w, h);
%                     obj.plotImage(); 
%                 end
                return; 
            end
            if obj.mibView.handles.mibSegmTrackRecenterCheck.Value == 1 && isempty(modifier)  % recenter the view
                obj.mibModel.I{obj.mibModel.Id}.moveView(w, h);
            end
        case 'Spot'
            % The spot mode: draw a circle after mouse click
            [w, h, z] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 1);
            obj.mibSegmentationSpot(ceil(h), ceil(w), modifier);
            return;
    end
    obj.plotImage();
    obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());   % moved from plotImage
    obj.mibView.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonUpFcn());
elseif strcmp(seltype, 'open')     % double click
    %disp('open')
end
end