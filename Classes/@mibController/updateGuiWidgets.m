function updateGuiWidgets(obj)
% function updateGuiWidgets()
% Update user interface widgets in obj.mibView.gui based on the properties of the opened dataset
%
% Parameters:
% 

% Copyright (C) 06.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;

obj.mibView.updateCursor();  % update size of the cursor
obj.mibModel.disableSegmentation = 0;    % reenable segmentation tools if they were accidentaly turned off

%% update checkboxes in the menu
switch obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')
    case 'uint8'
        obj.mibView.handles.menuImage8bit.Checked = 'on';
        obj.mibView.handles.menuImage16bit.Checked = 'off';
        obj.mibView.handles.menuImage32bit.Checked = 'off';
    case 'uint16'
        obj.mibView.handles.menuImage8bit.Checked = 'off';
        obj.mibView.handles.menuImage16bit.Checked ='on';
        obj.mibView.handles.menuImage32bit.Checked = 'off';
    case 'uint32'
        obj.mibView.handles.menuImage8bit.Checked = 'off';
        obj.mibView.handles.menuImage16bit.Checked = 'off';
        obj.mibView.handles.menuImage32bit.Checked = 'on';
end

obj.mibView.handles.menuImageGrayscale.Enable = 'on';
obj.mibView.handles.menuImageIndexed.Enable = 'on';
obj.mibView.handles.menuImageHSVColor.Enable = 'on';
switch obj.mibModel.I{obj.mibModel.Id}.meta('ColorType')
    case 'grayscale'
        obj.mibView.handles.menuImageGrayscale.Checked = 'on';
        obj.mibView.handles.menuImageRGBColor.Checked = 'off';
        obj.mibView.handles.menuImageHSVColor.Checked = 'off';
        obj.mibView.handles.menuImageIndexed.Checked = 'off';
        obj.mibView.handles.menuImageHSVColor.Enable = 'off';
    case 'truecolor'
        obj.mibView.handles.menuImageGrayscale.Checked = 'off';
        obj.mibView.handles.menuImageRGBColor.Checked = 'on';
        obj.mibView.handles.menuImageHSVColor.Checked = 'off';
        obj.mibView.handles.menuImageIndexed.Checked = 'off';
    case 'hsvcolor'
        obj.mibView.handles.menuImageGrayscale.Checked = 'off';
        obj.mibView.handles.menuImageRGBColor.Checked = 'off';
        obj.mibView.handles.menuImageHSVColor.Checked = 'on';
        obj.mibView.handles.menuImageIndexed.Checked = 'off';        
        obj.mibView.handles.menuImageGrayscale.Enable = 'off';
        obj.mibView.handles.menuImageIndexed.Enable = 'off';
    case 'indexed'
        obj.mibView.handles.menuImageGrayscale.Checked = 'off';
        obj.mibView.handles.menuImageRGBColor.Checked = 'off';
        obj.mibView.handles.menuImageHSVColor.Checked = 'off';
        obj.mibView.handles.menuImageIndexed.Checked = 'on';
        obj.mibView.handles.menuImageHSVColor.Enable = 'off';
end

obj.mibView.handles.menuModelsType63.Checked = 'off';
obj.mibView.handles.menuModelsType255.Checked = 'off';
obj.mibView.handles.menuModelsType65535.Checked = 'off';
obj.mibView.handles.menuModelsType4294967295.Checked = 'off';
switch obj.mibModel.I{obj.mibModel.Id}.modelType
    case 63
        obj.mibView.handles.menuModelsType63.Checked = 'on';
    case 255
        obj.mibView.handles.menuModelsType255.Checked = 'on';
    case 65535
        obj.mibView.handles.menuModelsType65535.Checked = 'on';  
    case 4294967295
        obj.mibView.handles.menuModelsType4294967295.Checked = 'on';         
end

if obj.mibModel.getImageProperty('modelType') < 256
    obj.mibView.handles.mibAddMaterialBtn.CData = obj.mibModel.sessionSettings.guiImages.plus;
    obj.mibView.handles.mibAddMaterialBtn.TooltipString = 'press to add Material to the model';
    obj.mibView.handles.mibRemoveMaterialBtn.Enable = 'on';
    obj.mibView.handles.mibSegmShowTypePopup.Enable = 'on';
else
    %obj.mibView.handles.mibAddMaterialBtn.String = 'E';
    obj.mibView.handles.mibAddMaterialBtn.CData = obj.mibModel.sessionSettings.guiImages.next;
    obj.mibView.handles.mibAddMaterialBtn.TooltipString = 'press to find and select the next empty material';
    obj.mibView.handles.mibRemoveMaterialBtn.Enable = 'off';
    obj.mibView.handles.mibSegmShowTypePopup.Enable = 'off';
    obj.mibView.handles.mibSegmShowTypePopup.Value = 1;
    obj.mibModel.mibSegmShowTypePopup = 1;
end

%% update toolbar buttons
% set properties for the slice slider, turn on/off the slider
% and set XY, YZ, XZ toggles
obj.mibView.handles.xyPlaneToggle.State = 'off';    % set back to default XY-viewing plane
obj.mibView.handles.zxPlaneToggle.State = 'off';
obj.mibView.handles.zyPlaneToggle.State = 'off';
if obj.mibModel.I{obj.mibModel.Id}.orientation == 1 % 'xz'
    current = obj.mibModel.I{obj.mibModel.Id}.slices{1}(1);
    max_slice = obj.mibModel.I{obj.mibModel.Id}.height;
    obj.mibView.handles.zxPlaneToggle.State = 'on';
elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 % 'yz'
    current = obj.mibModel.I{obj.mibModel.Id}.slices{2}(1);
    max_slice = obj.mibModel.I{obj.mibModel.Id}.width;
    obj.mibView.handles.zyPlaneToggle.State = 'on';
elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 4 %'yx'
    current = obj.mibModel.I{obj.mibModel.Id}.slices{4}(1);
    max_slice = obj.mibModel.I{obj.mibModel.Id}.depth;
    obj.mibView.handles.xyPlaneToggle.State = 'on';
end

if strcmp(obj.mibModel.preferences.mouseWheel, 'zoom')
    obj.mibView.handles.mouseWheelToolbarSw.State = 'off';
else
    obj.mibView.handles.mouseWheelToolbarSw.State = 'on';
end

if strcmp(obj.mibModel.preferences.mouseButton, 'pan')
    obj.mibView.handles.toolbarSwapMouse.State = 'off';
else
    obj.mibView.handles.toolbarSwapMouse.State = 'on';
end
obj.mibView.handles.toolbarShowROISwitch.State = 'off';

obj.toolbarInterpolation_ClickedCallback('keepcurrent');      % update the selection interpolation button
obj.toolbarResizingMethod_ClickedCallback('keepcurrent');     % update the image interpolation button icon
obj.toolbarVirtualMode_ClickedCallback('keepcurrent');         % update the virtual stack button

if obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch == 0
    obj.mibView.handles.toolbarBlockModeSwitch.State = 'off';
else
    obj.mibView.handles.toolbarBlockModeSwitch.State = 'on';
end



%% Update sliders
max_val = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
% update sliders and checkboxes in the black-and-white thresholding panel (handles.mibSegmThresPanel)
if obj.mibView.handles.mibSegmLowSlider.Value > max_val; obj.mibView.handles.mibSegmLowSlider.Value = max_val; end
if obj.mibView.handles.mibSegmHighSlider.Value > max_val; obj.mibView.handles.mibSegmHighSlider.Value = max_val; end
obj.mibView.handles.mibSegmLowSlider.Max = max_val;
obj.mibView.handles.mibSegmHighSlider.Max = max_val;

if obj.mibModel.I{obj.mibModel.Id}.time > 1
    obj.mibView.handles.mibSegmBWthres4D.Enable = 'on';
else
    obj.mibView.handles.mibSegmBWthres4D.Enable = 'off';
    obj.mibView.handles.mibSegmBWthres4D.Value = 0;
end

% update the change of layers slider
if max_slice > 1
    obj.mibView.handles.mibChangeLayerSlider.Max = max_slice;
    obj.mibView.handles.mibChangeLayerSlider.Min = 1;
    obj.mibView.handles.mibChangeLayerSlider.SliderStep = [1.0/(max_slice-1) 1.0/(max_slice-1)];
    obj.mibView.handles.mibSlider3Dpanel.Visible = 'on';
    %obj.mibView.handles.mibChangeLayerSliderListener.Enabled = 1;   % turn on changelayerSlider listener for real-time update of the slider
else
    %obj.mibView.handles.mibChangeLayerSliderListener.Enabled = 0;  % turn off changelayerSlider listener for Z=1
    obj.mibView.handles.mibSlider3Dpanel.Visible = 'off';
end
obj.mibView.handles.mibChangeLayerEdit.String = num2str(current);
obj.mibView.handles.mibChangeLayerSlider.Value = current;

% update the change of time points slider
if obj.mibModel.I{obj.mibModel.Id}.time > 1
    obj.mibView.handles.mibChangeTimeSlider.Max = obj.mibModel.I{obj.mibModel.Id}.time;
    obj.mibView.handles.mibChangeTimeSlider.Min = 1;
    obj.mibView.handles.mibChangeTimeSlider.SliderStep = [1.0/max([1 (obj.mibModel.I{obj.mibModel.Id}.time-1)]) 1.0/max([1 (obj.mibModel.I{obj.mibModel.Id}.time-1)])];
    %obj.mibView.handles.changeTimeSliderListener.Enabled = 1;   % turn on changelayerSlider listener for real-time update of the slider
    obj.mibView.handles.mibSliderTimePanel.Visible = 'on';
else
    %obj.mibView.handles.changeTimeSliderListener.Enabled = 0;  % turn off changelayerSlider listener for Z=1
    obj.mibView.handles.mibSliderTimePanel.Visible = 'off';
end
obj.mibView.handles.mibChangeTimeEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
obj.mibView.handles.mibChangeTimeSlider.Value = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);

%% update checkboxes
% update show mask checkbox
if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
    obj.mibView.handles.mibMaskShowCheck.Value = 0;
    obj.mibView.handles.mibMaskedAreaCheck.Value = 0;
    obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask = 0;
    obj.mibView.handles.mibMaskedAreaCheck.BackgroundColor = [0.94, 0.94, 0.94];
    obj.mibModel.mibMaskShowCheck = 0;
end

% update show model checkbox
if obj.mibView.handles.mibModelShowCheck.Value && obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
    obj.mibView.handles.mibModelShowCheck.Value = 0;
    obj.mibModel.mibModelShowCheck = 0;
    obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial = 0;
end

% clear trackerYXZ variable of the membrane clicktracker tool
obj.mibView.trackerYXZ = [NaN;NaN;NaN];

% update fix selection to material status and redraw mibSegmentationTable
% using obj.updateSegmentationTable() inside mibSegmSelectedOnlyCheck_Callback
obj.mibView.handles.mibSegmSelectedOnlyCheck.Value = obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial;
obj.mibSegmSelectedOnlyCheck_Callback();

% update MaskedAreaCheck status
if obj.mibView.handles.mibMaskedAreaCheck.Value ~= obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask
    obj.mibView.handles.mibMaskedAreaCheck.Value = obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask;
    obj.mibMaskedAreaCheck_Callback();
end

% update useLUT checkbox
obj.mibView.handles.mibLutCheckbox.Value = obj.mibModel.I{obj.mibModel.Id}.useLUT;

%% update ROI stuff
% update roi list box
% get number of ROIs
try
    [number, indices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI();
catch err
    err
end
str2 = cell([number+1 1]);
str2(1) = cellstr('All');
obj.mibView.handles.mibRoiList.Value = 1;
if number > 0
    %currVal = obj.mibView.handles.mibRoiList.Value;
    currVal = obj.mibModel.I{obj.mibModel.Id}.selectedROI;
    if currVal > 0; obj.mibView.handles.mibRoiShowCheck.Value = 1; end
    for i=1:number
        str2(i+1) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(indices(i)).label;
    end
    if currVal > number+1
        currVal = 1;
        obj.mibModel.I{obj.mibModel.Id}.selectedROI = 0;
    else
        currVal = currVal+1;
    end
else
    currVal = 1;
    obj.mibModel.I{obj.mibModel.Id}.selectedROI = 0;
end
obj.mibView.handles.mibRoiList.String = str2;
if numel(currVal) > 1
    obj.mibView.handles.mibRoiList.Value = 1;   % All
else
    targetRoiValue = max([currVal 1]);
    if targetRoiValue > numel(str2)
        obj.mibView.handles.mibRoiList.Value = 1;
        obj.mibModel.I{obj.mibModel.Id}.selectedROI = 0;
    end
end
obj.mibRoiShowCheck_Callback('noplot');    % noplot means do not redraw image inside this function

%% update panels
% add a label to the image view panel
strVal1 = 'Image View    >>>>>    ';
[~, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
strVal1 = sprintf('%s%s%s', strVal1, fn, ext);
if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName') && ...
        obj.mibModel.I{obj.mibModel.Id}.depth > 1 && obj.mibModel.I{obj.mibModel.Id}.orientation == 4   %'yx'
    
    % use getfield to get exact value as suggested by Ian M. Garcia in
    % http://stackoverflow.com/questions/3627107/how-can-i-index-a-matlab-array-returned-by-a-function-without-first-assigning-it
    layerName = getfield(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'), {min([current numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))])});  %#ok<GFLD>
    obj.mibView.handles.mibViewPanel.Title = sprintf('%s    >>>>>    %s', strVal1, layerName{1});
else
    obj.mibView.handles.mibViewPanel.Title = strVal1;
end

% update bufferToggles
for i=1:obj.mibModel.maxId
    bufferId = sprintf('mibBufferToggle%d', i);
    if ~strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif')
        if ismac()
            %eval(sprintf('obj.mibView.handles.mibBufferToggle%d.ForegroundColor = [0 1 0];', obj.mibModel.Id));     % make green
            obj.mibView.handles.(bufferId).ForegroundColor = [0 1 0];% make green
        else
            %eval(sprintf('obj.mibView.handles.mibBufferToggle%d.BackgroundColor = [0 1 0];', obj.mibModel.Id));     % make green
            obj.mibView.handles.(bufferId).BackgroundColor = [0 1 0]; % make green
        end
        %eval(sprintf('obj.mibView.handles.mibBufferToggle%d.TooltipString = obj.mibModel.I{%d}.meta(''Filename'');', obj.mibModel.Id, obj.mibModel.Id));     % make a tooltip as filename
        obj.mibView.handles.(bufferId).TooltipString = obj.mibModel.I{i}.meta('Filename');     % make a tooltip as filename
    else
        if ismac()
            obj.mibView.handles.(bufferId).ForegroundColor = [0 0 0];% make black
        else
            obj.mibView.handles.(bufferId).BackgroundColor = [0.9400    0.9400    0.9400]; % make grey
        end
        obj.mibView.handles.(bufferId).TooltipString = 'Use the left mouse button to select the dataset and the right mouse button for additional menu';     % make a tooltip as filename
    end
end

%% Virtual stacking mode related changes
obj.mibBioformatsCheck_Callback();  % update the list of available extensions
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    obj.mibView.handles.zyPlaneToggle.Enable = 'off';
    obj.mibView.handles.zxPlaneToggle.Enable = 'off';
else
    obj.mibView.handles.zyPlaneToggle.Enable = 'on';
    obj.mibView.handles.zxPlaneToggle.Enable = 'on';
end


%% redraw tables
%obj.mibView.handles.mibColChannelCombo.Value = min([obj.mibView.handles.mibColChannelCombo.Value obj.mibModel.getImageProperty('colors')+1]);
obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel = min([obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel obj.mibModel.getImageProperty('colors')]);
obj.redrawMibChannelMixerTable();

%% place callbacks for gui
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());   
obj.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) obj.mibGUI_ScrollWheelFcn(eventdata));
obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(hObject, eventdata));

%% update volume rendering
if obj.mibModel.I{obj.mibModel.Id}.volren.show == 1
    obj.mibView.handles.volrenToolbarSwitch.State = 'on';
else
    obj.mibView.handles.volrenToolbarSwitch.State = 'off';
end
obj.volrenToolbarSwitch_ClickedCallback();

notify(obj.mibModel, 'updateGuiWidgets');