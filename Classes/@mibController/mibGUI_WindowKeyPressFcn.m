% --- Executes on key release with focus on mibGUI or any of its controls.
function mibGUI_WindowKeyPressFcn(obj, hObject, eventdata)
% function  mibGUI_WindowKeyPressFcn(obj, hObject, eventdata)
% callback for a key press in mibGUI
%
% Parameters:
% hObject: handle of the focused object
% eventdata:  structure with the following fields (see FIGURE)
%	Key -> name of the key that was released, in lower case
%	Character -> character interpretation of the key(s) that was released
%	Modifier -> name(s) of the modifier key(s) (i.e., control, shift) released
% 
% Return values:
%

% Copyright (C) 15.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

% return after adding ROIs
%if isa(hObject.CurrentObject, 'matlab.graphics.GraphicsPlaceholder')

if nargin < 2; return; end

if nargin < 3   % this when returning from fine-tuning of ROIs via the Escape key
    char=hObject.Character;
    modifier = hObject.Modifier;
else
    % return when editing the edit boxes
    if ~isempty(hObject.CurrentObject)
        if ~isempty(strfind(lower(hObject.CurrentObject.Tag), 'edit')) 
            return; 
        end
    end
    
    char = eventdata.Key;
    modifier = eventdata.Modifier;
end
% if ~isempty(eventdata.Modifier)
%     fprintf('Ch=%s, mod=%s\n', char, eventdata.Modifier{1});
% else
%     fprintf('Ch=%s, mod=[]\n', char);
% end
if strcmp(char, 'alt'); return; end

xyString = obj.mibView.handles.mibPixelInfoTxt2.String;
colon = strfind(xyString, ':');
bracket = strfind(xyString, '(');
x = str2double(xyString(1:colon(1)-1));
y = str2double(xyString(colon(1)+1:bracket(1)-1));
inImage = str2double(xyString(bracket+1));  % when inImage is a number the mouse cursor is above the image
inAxes = 1;
if xyString(1) == 'X'; inAxes = 0; end     % when inAxes is 1, the mouse cursor above the image axes

% find a shortcut action
controlSw = 0;
shiftSw = 0;
altSw = 0;
if ismember('control', modifier); controlSw = 1; end
if ismember('shift', modifier)
    if ismember(char, obj.mibModel.preferences.KeyShortcuts.Key(6:16))   % override the Shift state for actions that work for all slices
        shiftSw = 0;  
    else
        shiftSw = 1; 
    end
end
if ismember('alt', modifier)
    % override the Alt state for previous/next time point
    % 'a', 's', 'r', 'c', 'z', 'x'
    if ismember(char, obj.mibModel.preferences.KeyShortcuts.Key([7:12 13:14]))  
        altSw = 0;
    elseif ismember(char, obj.mibModel.preferences.KeyShortcuts.Key(6)) && ismember('shift', modifier)
        % to care about Alt+A
        altSw = 0;
    else
        altSw = 1; 
    end
end
ActionId = ismember(obj.mibModel.preferences.KeyShortcuts.Key, char) & ismember(obj.mibModel.preferences.KeyShortcuts.control, controlSw) & ...
    ismember(obj.mibModel.preferences.KeyShortcuts.shift, shiftSw) & ismember(obj.mibModel.preferences.KeyShortcuts.alt, altSw);
ActionId = find(ActionId>0);    % action id is the index of the action, obj.mibModel.preferences.KeyShortcuts.Action(ActionId)

if ~isempty(ActionId) % find in the list of existing shortcuts
    switch obj.mibModel.preferences.KeyShortcuts.Action{ActionId}
        case 'Add measurement (Measure tool)'   % add measurement, works with Measure Tool, default 'm'
            notify(obj.mibModel.I{obj.mibModel.Id}.hMeasure, 'addMeasurement');
        case 'Switch dataset to XY orientation'         % default 'Alt + 1'
            if obj.mibModel.I{obj.mibModel.Id}.orientation == 4 || isnan(inImage) || obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual %|| x < 1 || x > handles.Img{handles.Id}.I.no_stacks;
                return;
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(2) = y;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = x;
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(1) = y;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = x;
            end
            moveMouseSw = 1;   % move the mouse cursor to the point where the plane was changed
            obj.mibToolbarPlaneToggle(obj.mibView.handles.xyPlaneToggle, moveMouseSw)
        case 'Switch dataset to ZX orientation'         % default 'Alt + 2'
            if obj.mibModel.I{obj.mibModel.Id}.orientation == 1 || isnan(inImage) || obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual
                return;
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(1) = y;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(2) = obj.mibModel.I{obj.mibModel.Id}.slices{2}(1);
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = x;
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 4
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(1) = y;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(2) = x;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = obj.mibModel.I{obj.mibModel.Id}.slices{4}(1);
            end
            moveMouseSw = 1;   % move the mouse cursor to the point where the plane was changed
            obj.mibToolbarPlaneToggle(obj.mibView.handles.zxPlaneToggle, moveMouseSw);
        case 'Switch dataset to ZY orientation'         % default 'Alt + 3'
            if obj.mibModel.I{obj.mibModel.Id}.orientation == 2 || isnan(inImage) || obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual
                return;
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(1) = obj.mibModel.I{obj.mibModel.Id}.slices{1}(1);
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(2) = y;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = x;
            elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 4
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(1) = y;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(2) = x;
                obj.mibModel.I{obj.mibModel.Id}.current_yxz(3) = obj.mibModel.I{obj.mibModel.Id}.slices{4}(1);
            end
            moveMouseSw = 1;   % move the mouse cursor to the point  where the plane was changed
            obj.mibToolbarPlaneToggle(obj.mibView.handles.zyPlaneToggle, moveMouseSw);
        case 'Interpolate selection'            % default 'i'
            obj.menuSelectionInterpolate();
        case 'Invert image'                     % default 'Ctrl + i'
            %obj.mibModel.invertImage('4D', 0);
            obj.menuImageInvert_Callback('4D');
        case 'Add to selection to material'     % default 'a'/'Shift+a'
            % do nothing is selection is disabled
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end
            
            if obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo') == -1    % Selection to Mask or Model
                selectionTo = 'mask';
            else    % Selection to Mask
                selectionTo = 'model';
            end
            if sum(ismember({'alt','shift'}, modifier)) == 2
                obj.mibModel.moveLayers('selection', selectionTo, '4D, Dataset', 'add');
            elseif sum(ismember({'alt','shift'}, modifier)) == 1
                obj.mibModel.moveLayers('selection', selectionTo, '3D, Stack', 'add');
            else
                obj.mibModel.moveLayers('selection', selectionTo, '2D, Slice', 'add');
            end
        case 'Subtract from material'   % default 's'/'Shift+s'
            % do nothing is selection is disabled
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end

            if obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo') == -1   % Selection to Mask or Model
                selectionTo = 'mask';
            else    % Selection to Mask
                selectionTo = 'model';
            end
            if sum(ismember({'alt','shift'}, modifier)) == 2
                obj.mibModel.moveLayers('selection',selectionTo,'4D, Dataset','remove');
            elseif sum(ismember({'alt','shift'}, modifier)) == 1
                obj.mibModel.moveLayers('selection',selectionTo,'3D, Stack','remove');
            else
                obj.mibModel.moveLayers('selection',selectionTo,'2D, Slice','remove');
            end
        case 'Replace material with current selection'  % default 'r'/'Shift+r'
            % do nothing is selection is disabled
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end
        
            if obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo') == -1    % Selection to Mask or Model
                selectionTo = 'mask';
            else    % Selection to Mask
                selectionTo = 'model';
            end
            if sum(ismember({'alt','shift'}, modifier)) == 2
                obj.mibModel.moveLayers('selection',selectionTo,'4D, Dataset','replace');
            elseif sum(ismember({'alt','shift'}, modifier)) == 1
                obj.mibModel.moveLayers('selection',selectionTo,'3D, Stack','replace');
            else
                obj.mibModel.moveLayers('selection',selectionTo,'2D, Slice','replace');
            end
        case 'Clear selection'  % default 'c'/'Shift+c'
             obj.mibSelectionClearBtn_Callback();
        case 'Fill the holes in the Selection layer'   % default 'f'/'Shift+f'
            % do nothing is selection is disabled
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end
            obj.mibSelectionFillBtn_Callback();
        case 'Erode the Selection layer'    % default 'z'/'Shift+z'
            % do nothing is selection is disabled
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end
            obj.mibSelectionErodeBtn_Callback();
        case 'Dilate the Selection layer'   % default 'x'/'Shift + x'
            if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end
            obj.mibSelectionDilateBtn_Callback();
        case {'Zoom out/Previous slice','Previous slice'}       % default 'q' / 'downarrow'
            % do nothing if the mouse not above the image
            if (strcmp(char, 'leftarrow') && inAxes == 0) || (strcmp(char, 'downarrow') && inAxes == 0)
                return;
            end
            if strcmp(obj.mibModel.preferences.KeyShortcuts.Action{ActionId}, 'Previous slice')
                changeSliceSwitch = 1;
            else
                changeSliceSwitch = strcmp(obj.mibView.handles.mouseWheelToolbarSw.State,'off');
            end
            if changeSliceSwitch == 1   % change slices
                if strcmp(modifier, 'alt')  % change time
                    if obj.mibModel.I{obj.mibModel.Id}.time == 1; return; end   % check for a single time point
                    shift = 1;
                    new_index = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1) - shift;
                    if new_index < 1;  new_index = 1; end
                    obj.mibModel.I{obj.mibModel.Id}.slices{5} = [1, 1];
                    obj.mibView.handles.mibChangeTimeSlider.Value = new_index;
                    obj.mibChangeTimeSlider_Callback();
                else    % change Z
                    if obj.mibModel.I{obj.mibModel.Id}.depth == 1; return; end   % check for a single image
                    if strcmp(modifier,'shift')  % 10 frames shift
                        shift = obj.mibView.handles.mibChangeLayerSlider.UserData.sliderShiftStep;
                    else
                        shift = obj.mibView.handles.mibChangeLayerSlider.UserData.sliderStep;
                    end
                    new_index = obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation}(1) - shift;
                    if new_index < 1;  new_index = 1; end
                    obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation} = [1, 1];
                    obj.mibView.handles.mibChangeLayerSlider.Value = new_index;
                    obj.mibChangeLayerSlider_Callback();
                end
            else    % zoom out with Q
                recenter = 1;
                obj.mibToolbar_ZoomBtn_ClickedCallback('zoomoutPush', recenter);
            end
        case {'Zoom in/Next slice', 'Next slice'}       % default 'w' / 'uparrow'
            % do nothing if the mouse not above the image
            if (strcmp(char, 'leftarrow') && inAxes == 0) || (strcmp(char, 'downarrow') && inAxes == 0)
                return;
            end
            if strcmp(obj.mibModel.preferences.KeyShortcuts.Action{ActionId}, 'Next slice')
                changeSliceSwitch = 1;
            else
                changeSliceSwitch = strcmp(obj.mibView.handles.mouseWheelToolbarSw.State,'off');
            end
            
            if changeSliceSwitch == 1   % change slices
                if strcmp(modifier, 'alt')  % change time
                    if obj.mibModel.I{obj.mibModel.Id}.time == 1; return; end   % check for a single time point
                    shift = 1;
                    new_index = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1) + shift;
                    if new_index > obj.mibModel.I{obj.mibModel.Id}.time;  new_index = obj.mibModel.I{obj.mibModel.Id}.time; end
                    obj.mibModel.I{obj.mibModel.Id}.slices{5} = [new_index, new_index];
                    obj.mibView.handles.mibChangeTimeSlider.Value = new_index;
                    obj.mibChangeTimeSlider_Callback();
                else    % change Z
                    if obj.mibModel.I{obj.mibModel.Id}.depth == 1; return; end   % check for a single image
                    if strcmp(modifier,'shift')  % 10 frames shift
                        shift = obj.mibView.handles.mibChangeLayerSlider.UserData.sliderShiftStep;
                    else
                        shift = obj.mibView.handles.mibChangeLayerSlider.UserData.sliderStep;
                    end
                    new_index = obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation}(1) + shift;
                    if new_index > obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation)
                        new_index = obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation);
                    end
                    obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation} = [new_index, new_index];
                    obj.mibView.handles.mibChangeLayerSlider.Value = new_index;
                    obj.mibChangeLayerSlider_Callback();
                end
            else   % zoom in with W
                recenter = 1;
                obj.mibToolbar_ZoomBtn_ClickedCallback('zoominPush', recenter); % zoomoutPush zoominPush
            end
        case 'Show/hide the Model layer'    % default 'space'
            val = obj.mibView.handles.mibModelShowCheck.Value;
            obj.mibView.handles.mibModelShowCheck.Value = abs(val-1);
            obj.mibModelShowCheck_Callback();
        case 'Show/hide the Mask layer'     % default 'Ctrl + space'
            val = obj.mibView.handles.mibMaskShowCheck.Value;
            obj.mibView.handles.mibMaskShowCheck.Value = abs(val-1);
            obj.mibMaskShowCheck_Callback();
        case 'Fix selection to material'
            selCheck = obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial;
            obj.mibView.handles.mibSegmSelectedOnlyCheck.Value = abs(selCheck-1);
            obj.mibSegmSelectedOnlyCheck_Callback();
        case 'Save image as...' % default 'Ctrl + s'
            obj.menuFileSaveImageAs_Callback();
        case 'Copy to buffer selection from the current slice'  % default 'Ctrl + c'
            obj.menuSelectionBuffer_Callback('copy');
        case 'Paste buffered selection to the current slice'    % default 'Ctrl + v'
            obj.menuSelectionBuffer_Callback('paste');
        case 'Paste buffered selection to all slices'    % default 'Ctrl + Shift + v'
            obj.menuSelectionBuffer_Callback('pasteall');
        case 'Toggle between the selected material and exterior' % default 'e'
            userData = obj.mibView.handles.mibSegmentationTable.UserData;
            jTable = userData.jTable;   % jTable is initializaed in the beginning of mibGUI.m
            jTable.changeSelection(obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection(1)-1, 1, false, false);    % automatically calls mibSegmentationTable_CellSelectionCallback
            obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection = fliplr(obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection);
        case 'Toggle current and previous buffer'
            obj.mibBufferToggle_Callback(obj.mibModel.mibPrevId);   % default ctrl+e, toggle buffer buttons
        case 'Loop through the list of favourite segmentation tools'    % default 'd'
            if numel(obj.mibModel.preferences.lastSegmTool) == 0
                errordlg(sprintf('The selection tools for the fast access with the "D" shortcut are not difined!\n\nPlease use the "D" button in the Segmentation panel to select them!'),'No tools defined!');
                return;
            end
            toolId = obj.mibView.handles.mibSegmentationToolPopup.Value;
            nextTool = obj.mibModel.preferences.lastSegmTool(find(obj.mibModel.preferences.lastSegmTool > toolId, 1));
            if isempty(nextTool)
                nextTool = obj.mibModel.preferences.lastSegmTool(1);
            end
            toolList = obj.mibView.handles.mibSegmentationToolPopup.String;
            
            fittext = annotation(obj.mibView.handles.mibViewPanel,'textbox',...
                'Position',[0.44    0.6964    0.3    0.0534],...
                'BackgroundColor',[0.8706 0.9216 0.9804],...
                'Color',[0 0 0],...
                'FitHeightToText','off',...
                'FontAngle','italic',...
                'FontName','Arial',...
                'FontSize',20,...
                'FontWeight','bold',...
                'HorizontalAlignment','center',...
                'VerticalAlignment', 'middle',...
                'String',toolList(nextTool));
            pause(.1);
            obj.mibView.handles.mibSegmentationToolPopup.Value = nextTool;
            obj.mibSegmentationToolPopup_Callback();
            delete(fittext);
        case 'Undo/Redo last action'    % default 'Ctrl + z'
            if obj.mibModel.U.enableSwitch == 0; return; end   % cancel if the undo system is disabled
            if obj.mibModel.U.prevUndoIndex == 0; return; end
            obj.mibDoUndo();
        case 'Find material under cursor' % default 'Ctrl + f'
            obj.mibFindMaterialUnderCursor();
        case 'Previous time point'      % default leftarrow
            if obj.mibModel.I{obj.mibModel.Id}.time == 1; return; end  % check for a single time point
            shift = 1;
            new_index = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1) - shift;
            if new_index < 1;  new_index = 1; end
            obj.mibView.handles.mibChangeTimeSlider.Value = new_index;
            obj.mibChangeTimeSlider_Callback();
        case 'Next time point'          % default rightarrow
            if obj.mibModel.I{obj.mibModel.Id}.time == 1; return; end   % check for a single time point
            shift = 1;
            new_index = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1) + shift;
            if new_index > obj.mibModel.I{obj.mibModel.Id}.time;  new_index = obj.mibModel.I{obj.mibModel.Id}.time; end
            obj.mibView.handles.mibChangeTimeSlider.Value = new_index;
            obj.mibChangeTimeSlider_Callback();
    end
else    % all other possible shortcuts
    switch char
        case 'escape'
            % detect escape when modifying the measurements, see Measure.drawROI method
            if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.imroi)
                if isvalid(obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.imroi)
                    % changing the color to red to detect the Esc key in the Measure.drawROI method
                    obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.imroi.setColor('r');
                    resume(obj.mibModel.I{obj.mibModel.Id}.hMeasure.roi.imroi);
                end
            end
            
            % detect escape when modifying the ROIs, see mibRoiRegion.drawROI method
            if ~isempty(obj.mibModel.I{obj.mibModel.Id}.hROI.roi.imroi)
                if isvalid(obj.mibModel.I{obj.mibModel.Id}.hROI.roi.imroi)
                    % changing the color to red to detect the Esc key in the mibRoiRegion.drawROI method
                    obj.mibModel.I{obj.mibModel.Id}.hROI.roi.imroi.setColor('r');
                    resume(obj.mibModel.I{obj.mibModel.Id}.hROI.roi.imroi);
                end
            end
        case 'a'    % Select the Mask or Material (when mask is not shown) layer 
            if strcmp(modifier, 'control') | strcmp(modifier, 'alt') %#ok<OR2>    
                if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 128
                    if strcmp(modifier, 'alt')
                        if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial == 1 % select mask
                            obj.mibModel.moveLayers('mask','selection','3D, Stack','replace');
                        elseif obj.mibModel.I{obj.mibModel.Id}.modelExist     % select only model
                            obj.mibModel.moveLayers('model','selection','3D, Stack','replace');
                        else    % make a combination of both mask and model
                            
                        end
                    else
                        if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial == 1 % select mask                            
                            obj.mibModel.moveLayers('mask','selection','2D, Slice','replace');
                        elseif obj.mibModel.I{obj.mibModel.Id}.modelExist    % select only model
                            obj.mibModel.moveLayers('model','selection','2D, Slice','replace');
                        else    % make a combination of both mask and model
                            
                        end
                    end
                end
                obj.plotImage(0);
            end
        case 'control'  % increase the radius of the brush for the erase tool
            if strcmp(modifier{1}, 'control') && obj.mibView.ctrlPressed == 0
                if obj.mibModel.preferences.eraserRadiusFactor == 1; return; end
                radius = str2double(obj.mibView.handles.mibSegmSpotSizeEdit.String);
                obj.mibView.ctrlPressed = max([floor(radius*obj.mibModel.preferences.eraserRadiusFactor - radius) 1]);
                obj.mibView.handles.mibSegmSpotSizeEdit.String = num2str(radius+obj.mibView.ctrlPressed);
                obj.mibView.updateCursor('solid');
            end
    end
end

end  % ------ end of im_browser_WindowKeyPressFcn
