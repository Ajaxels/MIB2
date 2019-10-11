% --- Executes on button press in segmSelectedOnlyCheck.
function mibSegmSelectedOnlyCheck_Callback(obj)
% function mibSegmSelectedOnlyCheck_Callback(obj)
% a callback to the mibGUI.handles.mibSegmSelectedOnlyCheck, allows to toggle state of the 'Fix selection to material'
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial = obj.mibView.handles.mibSegmSelectedOnlyCheck.Value;
if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1 % selected only
    obj.mibView.handles.mibSegmSelectedOnlyCheck.BackgroundColor = [1 .6 .784];
else
    obj.mibView.handles.mibSegmSelectedOnlyCheck.BackgroundColor = [0.94    0.94    0.94];
    userData = obj.mibView.handles.mibSegmentationTable.UserData;
    if userData.unlink == 0
        obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial;
        obj.mibView.handles.mibSegmentationTable.UserData = userData;
    end
end
obj.updateSegmentationTable();
unFocus(obj.mibView.handles.mibSegmSelectedOnlyCheck);   % remove focus from hObject
end