function mibSelectionErodeBtn_Callback(obj)
% function mibSelectionErodeBtn_Callback(obj, sel_switch)
% a callback to the mibGUI.handles.mibSelectionErodeBtn, shrinks the selection layer
%
% Parameters:

% Copyright (C) 19.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
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
    button = questdlg(sprintf('You are going to erode the image in 3D!\nContinue?'),'Erode 3D objects','Continue','Cancel','Continue');
    if strcmp(button, 'Cancel'); return; end
    BatchOpt.ErodeMode = {'3D'};
    if strcmp(BatchOpt.DatasetType{1}, '2D, Slice'); BatchOpt.DatasetType{1} = '3D, Stack'; end
else
    BatchOpt.ErodeMode = {'2D'};
end
BatchOpt.Difference = logical(obj.mibView.handles.mibSelectionDifferenceCheck.Value);   % if 1 will make selection as a difference
BatchOpt.StrelSize = obj.mibView.handles.mibStrelSizeEdit.String;
obj.mibModel.erodeImage(BatchOpt);
end