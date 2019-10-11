function mibSelectionDilateBtn_Callback(obj)
% function mibSelectionDilateBtn_Callback(obj)
% a callback to the mibGUI.handles.mibSelectionDilateBtn, expands the selection layer
%
% Parameters:

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 30.08.2017 IB added clipping with mask
% 19.09.2019 updated for the batch mode

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end

BatchOpt = struct();
BatchOpt.TargetLayer = {'selection'};
modifier = obj.mibView.gui.CurrentModifier;
if sum(ismember({'alt','shift'}, modifier)) == 2
    BatchOpt.DatasetType = {'4D, Dataset'};
elseif sum(ismember({'alt','shift'}, modifier)) == 1
    BatchOpt.DatasetType = {'3D, Stack'};
else
    BatchOpt.DatasetType = {'2D, Slice'};
end

switch3d = obj.mibView.handles.mibActions3dCheck.Value;
if switch3d == 1
    button = questdlg(sprintf('You are going to dilate the image in 3D!\nContinue?'),'Dilate 3D objects','Continue','Cancel','Continue');
    if strcmp(button, 'Cancel'); return; end
    BatchOpt.DilateMode = {'3D'};
    if strcmp(BatchOpt.DatasetType{1}, '2D, Slice'); BatchOpt.DatasetType{1} = '3D, Stack'; end
else
    BatchOpt.DilateMode = {'2D'};
end 
BatchOpt.Difference = logical(obj.mibView.handles.mibSelectionDifferenceCheck.Value);   % if 1 will make selection as a difference
BatchOpt.StrelSize = obj.mibView.handles.mibStrelSizeEdit.String;
BatchOpt.Adaptive = logical(obj.mibView.handles.mibAdaptiveDilateCheck.Value);
BatchOpt.AdaptiveCoef = obj.mibView.handles.mibDilateAdaptCoefEdit.String;
BatchOpt.AdaptiveSmoothing = logical(obj.mibView.handles.mibAdaptiveSmoothCheck.Value);
BatchOpt.FixSelectionToMaterial = NaN;
if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial  % area for dilation is taken only from selected contour
    BatchOpt.FixSelectionToMaterial = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
end
BatchOpt.FixSelectionToMask = logical(obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask);

if obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel == 0 && obj.mibView.handles.mibAdaptiveDilateCheck.Value == 1
    msgbox('Please select the color channel!','Error!','error','modal');
    return;
end

obj.mibModel.dilateImage(BatchOpt);
end