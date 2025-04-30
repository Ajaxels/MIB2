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
% Date: 26.02.2025

function mibUpdatePresetFromSegmentationSettings(obj, presetId)
% function mibUpdatePresetFromSegmentationSettings(obj, presetId)
% update preset using the current settings of the selected segmentation
% tool; this function is a callback on press of Shift+1, Shift+2, Shift+3 default key shortcuts
%
% Parameters:
% presetId: a number from 1 to 3 specifying the required preset to use
%
% See also: mibUpdateSegmentationSettingsFromPreset.m

% Updates
% 

% define field name encoding the choosed preset
switch presetId
    case 1
        setName = 'Set1';
    case 2
        setName = 'Set2';
    case 3
        setName = 'Set3';
end

% update segmentation settings depending on the selected tool
switch obj.mibView.handles.mibSegmentationToolPopup.String{obj.mibView.handles.mibSegmentationToolPopup.Value}
    case 'Annotations'
        obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).ShowPrompt = logical(obj.mibView.handles.mibAnnPromptCheck.Value);
        obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).FocusOnValue = logical(obj.mibView.handles.mibAnnValueEccentricCheck.Value);
        obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).Size = obj.mibModel.preferences.SegmTools.Annotations.FontSize;
        obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).Color = obj.mibModel.preferences.SegmTools.Annotations.Color;
        obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).ExtraSlices = obj.mibModel.preferences.SegmTools.Annotations.ShownExtraDepth;
        obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).DisplayAs = obj.mibView.handles.mibAnnMarkerEdit.String{obj.mibView.handles.mibAnnMarkerEdit.Value};
    case '3D lines'
        obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).Click = obj.mibView.handles.mibSegmLines3DClickPopup.String{obj.mibView.handles.mibSegmLines3DClickPopup.Value};
        obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).ShiftClick = obj.mibView.handles.mibSegmLines3DShiftClickPopup.String{obj.mibView.handles.mibSegmLines3DShiftClickPopup.Value};
        obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).CtrlClick = obj.mibView.handles.mibSegmLines3DCtrlClickPopup.String{obj.mibView.handles.mibSegmLines3DCtrlClickPopup.Value};
        obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).AltClick = obj.mibView.handles.mibSegmLines3DAltClickPopup.String{obj.mibView.handles.mibSegmLines3DAltClickPopup.Value};
    case {'3D ball', 'Brush', 'Spot'}
        obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).Radius = obj.mibView.handles.mibSegmSpotSizeEdit.String;
        obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).Eraser = obj.mibView.handles.mibEraserEdit.String;
        obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).Watershed = logical(obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value);
        obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).SLIC = logical(obj.mibView.handles.mibBrushSuperpixelsCheck.Value);
    case 'BW Thresholding'
        obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).Adaptive = logical(obj.mibView.handles.mibSegmThresPanelAdaptiveCheck.Value);
        obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).BlackOnWhite = obj.mibView.handles.mibSegmThresPanelAdaptivePopup.String{obj.mibView.handles.mibSegmThresPanelAdaptivePopup.Value};
        obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).Switch3D = logical(obj.mibView.handles.mibSegmBWthres3D.Value);
        obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).Invert = logical(obj.mibView.handles.mibSegmThresPanelAdaptiveInvert.Value);
        obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).ParameterLo = obj.mibView.handles.mibSegmLowEdit.String;
        obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).ParameterHi = obj.mibView.handles.mibSegmHighEdit.String;
        if strcmp(obj.mibView.handles.menuImage8bit.Checked, 'on')
            maxVal = 255;
        elseif strcmp(obj.mibView.handles.menuImage16bit.Checked, 'on')
            maxVal = 65535;
        else
            maxVal = 4294967295;
        end
        obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).SliderStep = round(obj.mibView.handles.mibSegmLowSlider.SliderStep(1)*maxVal);
    case 'Drag & Drop materials'
        obj.mibModel.preferences.SegmTools.Presets.DragNDrop.(setName).Layer = obj.mibView.handles.mibSegmDragDropLayer.String{obj.mibView.handles.mibSegmDragDropLayer.Value};
        obj.mibModel.preferences.SegmTools.Presets.DragNDrop.(setName).Shift = obj.mibView.handles.mibSegmDragDropShift.String;
    case 'MagicWand-RegionGrowing'
        obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Method = obj.mibView.handles.mibMagicwandMethodPopup.String{obj.mibView.handles.mibMagicwandMethodPopup.Value};
        obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).VariationLo = obj.mibView.handles.mibSelectionToolEdit.String;
        obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).VariationHi = obj.mibView.handles.mibMagicUpThresEdit.String;
        obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Radius = obj.mibView.handles.mibMagicWandRadius.String;
        if obj.mibView.handles.mibMagicwandConnectCheck.Value
            obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Connect = 8;
        end
        if obj.mibView.handles.mibMagicwandConnectCheck.Value
            obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Connect = 8;
        else
            obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Connect = 4;
        end
   case 'Membrane ClickTracker'
        obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).Scale = obj.mibView.handles.mibSegmTracScaleEdit.String;
        obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).Width = obj.mibView.handles.mibSegmTrackWidthEdit.String;
        obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).StraightLine = logical(obj.mibView.handles.mibSegmTrackStraightChk.Value);
        obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).BlackSignal = logical(obj.mibView.handles.mibSegmTrackBlackChk.Value);
        obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).RecenterView = logical(obj.mibView.handles.mibSegmTrackRecenterCheck.Value);
    case 'Segment-anything model'
        obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Method = obj.mibView.handles.mibSegmSAMMethod.String{obj.mibView.handles.mibSegmSAMMethod.Value};
        obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Dataset = obj.mibView.handles.mibSegmSAMDataset.String{obj.mibView.handles.mibSegmSAMDataset.Value};
        obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Destination = obj.mibView.handles.mibSegmSAMDestination.String{obj.mibView.handles.mibSegmSAMDestination.Value};
        obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Mode = obj.mibView.handles.mibSegmSAMMode.String{obj.mibView.handles.mibSegmSAMMode.Value};
end