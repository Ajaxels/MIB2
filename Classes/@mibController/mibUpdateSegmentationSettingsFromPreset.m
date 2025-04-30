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
% Date: 24.02.2025

function mibUpdateSegmentationSettingsFromPreset(obj, presetId)  
% function mibUpdateSegmentationSettingsFromPreset(obj, presetId)  
% update settings of the selected segmentation tool from preset, this
% function is a callback on press of 1,2,3 default key shortcuts
%
% Parameters:
% presetId: a number from 1 to 3 specifying the required preset to use
%
% See also: mibUpdatePresetFromSegmentationSettings.m

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
        obj.mibView.handles.mibAnnPromptCheck.Value = obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).ShowPrompt;
        obj.mibView.handles.mibAnnValueEccentricCheck.Value = obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).FocusOnValue;
        obj.mibModel.preferences.SegmTools.Annotations.FontSize = obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).Size;
        obj.mibModel.preferences.SegmTools.Annotations.Color = obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).Color;
        obj.mibModel.preferences.SegmTools.Annotations.ShownExtraDepth = obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).ExtraSlices;
        obj.mibView.handles.mibAnnMarkerEdit.Value = ...
            find(ismember(obj.mibView.handles.mibAnnMarkerEdit.String, obj.mibModel.preferences.SegmTools.Presets.Annotations.(setName).DisplayAs));
        obj.plotImage();
    case '3D lines'
        obj.mibView.handles.mibSegmLines3DClickPopup.Value = ...
            find(ismember(obj.mibView.handles.mibSegmLines3DClickPopup.String, obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).Click));
        obj.mibView.handles.mibSegmLines3DShiftClickPopup.Value = ...
            find(ismember(obj.mibView.handles.mibSegmLines3DShiftClickPopup.String, obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).ShiftClick));
        obj.mibView.handles.mibSegmLines3DCtrlClickPopup.Value = ...
            find(ismember(obj.mibView.handles.mibSegmLines3DCtrlClickPopup.String, obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).CtrlClick));
        obj.mibView.handles.mibSegmLines3DAltClickPopup.Value = ...
            find(ismember(obj.mibView.handles.mibSegmLines3DAltClickPopup.String, obj.mibModel.preferences.SegmTools.Presets.Lines3D.(setName).AltClick));
    case {'3D ball', 'Brush', 'Spot'}
        obj.mibView.handles.mibSegmSpotSizeEdit.String = obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).Radius;
        obj.mibView.handles.mibEraserEdit.String = obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).Eraser;
        obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value = obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).Watershed;
        obj.mibView.handles.mibBrushSuperpixelsCheck.Value = obj.mibModel.preferences.SegmTools.Presets.Brush.(setName).SLIC;
        if obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value
            obj.mibBrushSuperpixelsWatershedCheck_Callback(obj.mibView.handles.mibBrushSuperpixelsWatershedCheck);
        else
            obj.mibBrushSuperpixelsWatershedCheck_Callback(obj.mibView.handles.mibBrushSuperpixelsCheck);
        end
        obj.mibView.updateCursor();
    case 'BW Thresholding'
        obj.mibView.handles.mibSegmThresPanelAdaptiveCheck.Value = obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).Adaptive;
        if obj.mibView.handles.mibSegmThresPanelAdaptiveCheck.Value == 1    % adaptive mode
            obj.mibView.handles.mibSegmThresPanelAdaptivePopup.Enable = 'on';
            obj.mibView.handles.mibSegmThresPanelAdaptiveInvert.Enable = 'on';
            obj.mibView.handles.mibSegmThresPanelLowText.String = 'Sensibility:';
            obj.mibView.handles.mibSegmThresPanelHighText.String = 'Width:';
            obj.mibView.handles.mibSegmLowEdit.TooltipString = 'specify sensibility for adaptive thresholding';
            obj.mibView.handles.mibSegmHighEdit.TooltipString = 'specify size of neighborhood used to compute local statistic around each pixel';
        else
            obj.mibView.handles.mibSegmThresPanelAdaptivePopup.Enable = 'off';
            obj.mibView.handles.mibSegmThresPanelAdaptiveInvert.Enable = 'off';
            obj.mibView.handles.mibSegmThresPanelLowText.String = 'Low:';
            obj.mibView.handles.mibSegmThresPanelHighText.String = 'High:';
            obj.mibView.handles.mibSegmLowEdit.TooltipString = 'specify the low limit for the thresholding:';
            obj.mibView.handles.mibSegmHighEdit.TooltipString = 'specify the high limit for the thresholding';
        end
        obj.mibView.handles.mibSegmThresPanelAdaptivePopup.Value = ...
            find(ismember(obj.mibView.handles.mibSegmThresPanelAdaptivePopup.String, obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).BlackOnWhite));
        obj.mibView.handles.mibSegmBWthres3D.Value = obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).Switch3D;
        obj.mibView.handles.mibSegmThresPanelAdaptiveInvert.Value = obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).Invert;
        obj.mibView.handles.mibSegmLowEdit.String = obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).ParameterLo;
        obj.mibSegmentationBlackWhiteThreshold('mibSegmLowEdit');
        obj.mibView.handles.mibSegmHighEdit.String = obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).ParameterHi;
        obj.mibSegmentationBlackWhiteThreshold('mibSegmHighEdit');
        if strcmp(obj.mibView.handles.menuImage8bit.Checked, 'on')
            maxVal = 255;
        elseif strcmp(obj.mibView.handles.menuImage16bit.Checked, 'on')
            maxVal = 65535;
        else
            maxVal = 4294967295;
        end
        stepValue = obj.mibModel.preferences.SegmTools.Presets.BWThresholding.(setName).SliderStep;
        obj.mibView.handles.mibSegmLowSlider.SliderStep = [stepValue/maxVal stepValue/maxVal*10];
        obj.mibView.handles.mibSegmHighSlider.SliderStep = [stepValue/maxVal stepValue/maxVal*10];
    case 'Drag & Drop materials'
        obj.mibView.handles.mibSegmDragDropLayer.Value = ...
            find(ismember(obj.mibView.handles.mibSegmDragDropLayer.String, obj.mibModel.preferences.SegmTools.Presets.DragNDrop.(setName).Layer));
        obj.mibView.handles.mibSegmDragDropShift.String = obj.mibModel.preferences.SegmTools.Presets.DragNDrop.(setName).Shift;
    case 'MagicWand-RegionGrowing'
        obj.mibView.handles.mibMagicwandMethodPopup.Value = ...
            find(ismember(obj.mibView.handles.mibMagicwandMethodPopup.String, obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Method));
        obj.mibView.handles.mibSelectionToolEdit.String = obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).VariationLo;
        obj.mibView.handles.mibMagicUpThresEdit.String = obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).VariationHi;
        obj.mibView.handles.mibMagicWandRadius.String = obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Radius;
        if obj.mibModel.preferences.SegmTools.Presets.MagicWand.(setName).Connect == 8
            obj.mibView.handles.mibMagicwandConnectCheck.Value = true;
            obj.mibView.handles.mibMagicwandConnectCheck4.Value = false;
        else
            obj.mibView.handles.mibMagicwandConnectCheck.Value = false;
            obj.mibView.handles.mibMagicwandConnectCheck4.Value = true;
        end

        if obj.mibView.handles.mibMagicwandMethodPopup.Value == 1   % magic wand
            obj.mibView.handles.mibMagicUpThresEdit.Visible = 'on';
            obj.mibView.handles.mibMagicdashTxt.Visible = 'on';
        else        % region growing
            obj.mibView.handles.mibMagicUpThresEdit.Visible = 'off';
            obj.mibView.handles.mibMagicdashTxt.Visible = 'off';
        end
   case 'Membrane ClickTracker'
        obj.mibView.handles.mibSegmTracScaleEdit.String = obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).Scale;
        obj.mibView.handles.mibSegmTrackWidthEdit.String = obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).Width;
        obj.mibView.handles.mibSegmTrackStraightChk.Value = obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).StraightLine;
        obj.mibView.handles.mibSegmTrackBlackChk.Value = obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).BlackSignal;
        obj.mibView.handles.mibSegmTrackRecenterCheck.Value = obj.mibModel.preferences.SegmTools.Presets.MembraClickTracker.(setName).RecenterView;
    case 'Segment-anything model'
        obj.mibView.handles.mibSegmSAMMethod.Value = ...
            find(ismember(obj.mibView.handles.mibSegmSAMMethod.String, obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Method));
        obj.mibView.handles.mibSegmSAMDataset.Value = ...
            find(ismember(obj.mibView.handles.mibSegmSAMDataset.String, obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Dataset));
        obj.mibView.handles.mibSegmSAMDestination.Value = ...
            find(ismember(obj.mibView.handles.mibSegmSAMDestination.String, obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Destination));
        obj.mibView.handles.mibSegmSAMMode.Value = ...
            find(ismember(obj.mibView.handles.mibSegmSAMMode.String, obj.mibModel.preferences.SegmTools.Presets.SAM.(setName).Mode));
        obj.mibSegmSAMPanel_Callbacks('mibSegmSAMMethod');
end