% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function mibGUI_WindowButtonDownFcn(obj)
% function mibGUI_WindowButtonDownFcn(obj)
% this is callback for the press of a mouse button
%
% Parameters:
% 

% Updates
% 

val = obj.mibView.handles.mibSegmentationToolPopup.Value; % get a selected segmentation tool: magic wand, brush etc
txt = obj.mibView.handles.mibSegmentationToolPopup.String;
tool = cell2mat(txt(val));
tool = strtrim(tool);   % remove ending space
switch3d = obj.mibView.handles.mibActions3dCheck.Value;     % use filters in 3d
xy = obj.mibView.handles.mibImageAxes.CurrentPoint;
seltype = obj.mibView.gui.SelectionType;
modifier = obj.mibView.gui.CurrentModifier;
%character = obj.mibView.gui.CurrentCharacter; 
%fprintf('seltype: %s modifier: "%s" char: "%s"\n', seltype, cell2mat(modifier), character)
%fprintf('seltype: %s modifier: "%s"\n', seltype, cell2mat(modifier))

% define operation depending on the state of obj.mibView.handles.toolbarSwapMouse.State
if strcmp(obj.mibView.handles.toolbarSwapMouse.State, 'on')
    switch seltype
        case 'normal'   % LMB
            if ~isempty(modifier) && sum(ismember(modifier, {'shift', 'alt', 'control'})) == 3
                % a tweak for the drawing pan
                % shift+alt+control+click for pan eraser
                operation = 'pan';
            else
                operation = 'interact';
            end
        case 'alt'  % RMB, Ctrl+LMB
            if isempty(modifier)
                operation = 'pan';
            else
                operation = 'interact';
            end
        case 'extend'   % Shift+RMB, Shift+LMB, MMB, LMB+RMB
            operation = 'interact';
        case 'open'     % double click
            return
        otherwise
            return
    end
else
    switch seltype
        case 'normal'   % LMB
            if ~isempty(modifier) && sum(ismember(modifier, {'shift', 'alt', 'control'})) == 3
                % a tweak for the drawing pan
                % the panning mode is enabled when Shift+Alt+Ctrl are used
                operation = 'interact';
            else
                operation = 'pan';
            end
        case 'alt'  % RMB, Ctrl+LMB
            operation = 'interact';
        case 'extend'   % Shift+RMB, Shift+LMB, MMB, LMB+RMB
            operation = 'interact';
        case 'open'     % double click
            return
        otherwise 
            return
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

if strcmp(operation, 'pan') %& strcmp(modifier,'alt')
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
elseif strcmp(operation, 'interact')
    %% Start segmentation mode
    %y = round(xy(1,2));
    %x = round(xy(1,1));

    if obj.mibModel.I{obj.mibModel.Id}.enableSelection == 0 && ~ismember(tool, {'Annotations', '3D lines'})
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
            if strcmp(obj.mibView.handles.mibSegmObjectPickerPanelSub2Select.Enable, 'on')
                [w, h] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 1);
                spotToolBatchOpt.Shape = {'square'};
                spotToolBatchOpt.Radius = [obj.mibView.handles.mibSegmObjectPickerPanelSub2Width.String ';' obj.mibView.handles.mibSegmObjectPickerPanelSub2Height.String];
                obj.mibSegmentationSpot(ceil(h), ceil(w), modifier, spotToolBatchOpt);
                return; 
            end   % cancel when the manual mode is enabled
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
        case 'Segment-anything model'
            % check that Interactive 3D mode is used only for SAM2
            if obj.mibView.handles.mibSegmSAMMethod.Value == 2 && ~obj.mibView.handles.mibSAM2checkbox.Value
                errordlg(sprintf('!!! Error !!!\n\nThe Interactive 3D mode is not available for SAM1!\nCheck the SAM2 checkbox or use the 3D mode for the Interactive mode!'), ...
                    'Interactive 3D');
                return;
            end

            % add labels
            [w, h, z, t] = obj.mibModel.convertMouseToDataCoordinates(xy(1,1), xy(1,2), 'shown', 1); % to enable the interactive mode also in YZ/XZ
            if obj.mibView.handles.mibSegmSAMMethod.Value == 1 || obj.mibView.handles.mibSegmSAMMethod.Value == 2   %     'Interactive' or 'Interactive 3D'
                % remove shift modifier
                if ~isempty(modifier) && max(strcmp(modifier, 'shift')) && isempty(obj.mibModel.sessionSettings.SAMsegmenter.Points.Value)
                    modifier = [];
                end
                extraOptions.addNextMaterial = false;    % add next material after adding the current one only for "add, +next material" mode
                
                samMode = obj.mibView.handles.mibSegmSAMMode.String{obj.mibView.handles.mibSegmSAMMode.Value};
                if strcmp(samMode, 'add, +next material') && ~strcmp(obj.mibView.handles.mibSegmSAMDestination.String{obj.mibView.handles.mibSegmSAMDestination.Value}, 'model')
                    samMode = 'replace';
                    obj.mibView.handles.mibSegmSAMMode.Value = 1;
                end

                destinationLayer = obj.mibView.handles.mibSegmSAMDestination.String{obj.mibView.handles.mibSegmSAMDestination.Value};
                if isempty(modifier)    % start new segmentation
                    obj.mibModel.sessionSettings.SAMsegmenter.Points.Position = [w, h, z];
                    obj.mibModel.sessionSettings.SAMsegmenter.Points.Value = 1;
                    
                    % limit to the selected material of the model
                    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
                        % update selected material state
                        selectedFixToMaterial = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
                        getData2Doptions.blockModeSwitch = true;
                        obj.mibModel.sessionSettings.SAMsegmenter.initialImageSelected = ...
                            uint8(cell2mat(obj.mibModel.getData2D('model', NaN, NaN, selectedFixToMaterial, getData2Doptions)));
                    end

                    switch samMode
                        case 'add'
                            % % store the current state
                            % %obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo = ...
                            % %    cell2mat(obj.mibModel.getData2D(destinationLayer, NaN, NaN, obj.mibModel.I{obj.mibModel.Id}.selectedMaterial-2));
                            % getData2Doptions.blockModeSwitch = true;
                            % obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo = ...
                            %     cell2mat(obj.mibModel.getData2D(destinationLayer, NaN, NaN, obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'), getData2Doptions));
                            % 
                            % % do backup
                            % destinationStr = obj.mibView.handles.mibSegmSAMDestination.String{obj.mibView.handles.mibSegmSAMDestination.Value};     % {'selection', 'mask', 'model'}'
                            % obj.mibModel.mibDoBackup(destinationStr, 0);
                        case 'add, +next material'
                            if obj.mibModel.I{obj.mibModel.Id}.modelType < 256 || ...
                                ~strcmp(obj.mibView.handles.mibSegmSAMDestination.String{obj.mibView.handles.mibSegmSAMDestination.Value}, 'model')

                                errordlg(sprintf(['!!! Error !!!\n\nThere current settings are not compatible with the "add, +next material" mode!\n\n' ...
                                    'Please make sure that:\n' ...
                                    '   1. You created or already have a model with type 65535 or larger\n' ...
                                    '   2. Destination should be set to "Model"']), ...
                                    'add, +next material');
                                return; 
                            end
                            
                            % select the second material row in the table
                            if obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial < 4
                                userData = obj.mibView.handles.mibSegmentationTable.UserData;
                                jTable = userData.jTable;   % jTable is initializaed in the beginning of mibGUI.m
                                jTable.changeSelection(3, 2, false, false);    % automatically calls mibSegmentationTable_CellSelectionCallback
                                obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection = [3 4];
                                obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = 4;
                            end

                            % getData2Doptions.blockModeSwitch = true;
                            % obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo = ...
                            %     uint8(cell2mat(obj.mibModel.getData2D(destinationLayer, NaN, NaN, obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'), getData2Doptions)));
                            extraOptions.addNextMaterial = true;

                            % % do backup
                            % destinationStr = obj.mibView.handles.mibSegmSAMDestination.String{obj.mibView.handles.mibSegmSAMDestination.Value};     % {'selection', 'mask', 'model'}'
                            backupOptions.LinkedVariable.modelMaterialNames = 'obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames';
                            backupOptions.LinkedData.modelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
                            obj.mibModel.mibDoBackup(destinationLayer, 0, backupOptions);
                        otherwise
                            obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo = [];
                    end
                else  % second click with Shift or Ctrl modifiers
                    if strcmp(modifier, 'control')
                        if isempty(obj.mibModel.sessionSettings.SAMsegmenter.Points.Position); return; end
                        markerValue = 0;
                    elseif strcmp(modifier, 'shift')
                        markerValue = 1;
                    else
                        return
                    end

                    switch samMode
                        case 'add, +next material'
                            % select the first material row in the table
                            if obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial == 4
                                eventdata2.Indices = [3, 3];
                                obj.mibSegmentationTable_CellSelectionCallback(eventdata2);     % update mibSegmentationTable
                            end
                    end

                    if obj.mibView.handles.mibSegmSAMMethod.Value == 2  % 'Interactive 3D'
                        if obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end) == z
                            % use NaN value to specify end of the dataset for automatic cropping
                            obj.mibModel.sessionSettings.SAMsegmenter.Points.Value = [obj.mibModel.sessionSettings.SAMsegmenter.Points.Value, markerValue];
                        else
                            % use NaN value to specify end of the dataset for automatic cropping
                            obj.mibModel.sessionSettings.SAMsegmenter.Points.Value = [obj.mibModel.sessionSettings.SAMsegmenter.Points.Value, NaN];

                            % limit to the selected material of the model
                            if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
                                % update selected material state
                                selectedFixToMaterial = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
                                getData3Doptions.blockModeSwitch = true;
                                getData3Doptions.z = [min([obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3); z]), max([obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3); z])];
                                obj.mibModel.sessionSettings.SAMsegmenter.initialImageSelected = ...
                                    uint8(cell2mat(obj.mibModel.getData3D('model', NaN, NaN, selectedFixToMaterial, getData3Doptions)));
                            end

                        end
                        obj.mibModel.sessionSettings.SAMsegmenter.Points.Position = [obj.mibModel.sessionSettings.SAMsegmenter.Points.Position; w, h, z];
                    else   % 'Interactive', 'Landmarks', 'Automatic everything'
                        if obj.mibView.handles.mibSegmSAMDataset.Value == 1 % 2D, Slice
                            % add point to segmentation
                            obj.mibModel.sessionSettings.SAMsegmenter.Points.Position = [obj.mibModel.sessionSettings.SAMsegmenter.Points.Position; w, h, z];
                            obj.mibModel.sessionSettings.SAMsegmenter.Points.Value = [obj.mibModel.sessionSettings.SAMsegmenter.Points.Value, markerValue];
                        else % 3D, Dataset
                            % interpolate the points between the current and
                            % the previous points when z-value was changed
                            if obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(end) == markerValue && ...
                                    obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end,3) ~= z

                                % range vector between min and max Z
                                %z_range = min([obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 3), z]):max([obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end,3), z]);
                                if obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 3) < z
                                    z_range = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 3):z;
                                else
                                    z_range = obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 3):-1:z;
                                end

                                % Interpolate x and y values for each z value
                                x_interp = interp1([obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 3); z], [obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 1); w], z_range, 'linear');     % x_interp = interp1([z1 z2], [x1 x2], z_range);
                                y_interp = interp1([obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 3); z], [obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(end, 2); h], z_range, 'linear');     % y_interp = interp1([z1 z2], [y1 y2], z_range);
                                id1 = size(obj.mibModel.sessionSettings.SAMsegmenter.Points.Position, 1);
                                id2 = id1+numel(x_interp)-1;
                                obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(id1:id2, 1) = x_interp;
                                obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(id1:id2, 2) = y_interp;
                                obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(id1:id2, 3) = z_range;
                                obj.mibModel.sessionSettings.SAMsegmenter.Points.Value(id1:id2) = markerValue;
                            else
                                % add point to segmentation
                                obj.mibModel.sessionSettings.SAMsegmenter.Points.Position = [obj.mibModel.sessionSettings.SAMsegmenter.Points.Position; w, h, z];
                                obj.mibModel.sessionSettings.SAMsegmenter.Points.Value = [obj.mibModel.sessionSettings.SAMsegmenter.Points.Value, markerValue];
                            end
                        end
                    end
                end

                % do backup and store states
                z1 = min(obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3));
                z2 = max(obj.mibModel.sessionSettings.SAMsegmenter.Points.Position(:,3));
                getDataOptions.blockModeSwitch = true;
                getDataOptions.z = [z1 z2];
                switch samMode
                    case 'add'
                        % store the current state
                        obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo = ...
                            uint8(cell2mat(obj.mibModel.getData3D(destinationLayer, t, NaN, obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'), getDataOptions)));

                        % done in mibSegmentationSAM2
                        obj.mibModel.mibDoBackup(destinationLayer, 1, getDataOptions);
                    case 'add, +next material'
                        if isempty(modifier) % store initial state for the initial selection of the object
                            obj.mibModel.sessionSettings.SAMsegmenter.initialImageAddTo = ...
                                uint8(cell2mat(obj.mibModel.getData3D(destinationLayer, NaN, NaN, obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'), getDataOptions)));
                        end
                end

                if obj.mibModel.preferences.SegmTools.SAM.samVersion == 1
                    % use original SAM1
                    obj.mibSegmentationSAM(extraOptions);
                else  
                    % use newer version SAM2
                    obj.mibSegmentationSAM2(extraOptions);
                end
                return;
            elseif obj.mibView.handles.mibSegmSAMMethod.Value == 3    %     'Landmarks'
                obj.mibSegmentationAnnotation(h, w, z, t, modifier);
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
end
end