% --- Executes on button press in mibMaskedAreaCheck_Callback.
function mibMaskedAreaCheck_Callback(obj)
% function mibMaskedAreaCheck_Callback(obj)
% a callback to the mibGUI.handles.mibMaskedAreaCheck, allows to toggle state of the 'Masked area'
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 27.06.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if obj.mibModel.getImageProperty('maskExist') == 0
    obj.mibView.handles.mibMaskedAreaCheck.Value = 0;
    obj.mibView.handles.mibMaskedAreaCheck.BackgroundColor = [0.94    0.94    0.94];
    return;
end
obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask = obj.mibView.handles.mibMaskedAreaCheck.Value;

if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask     % returns toggle state of mibMaskedAreaCheck
    obj.mibView.handles.mibMaskedAreaCheck.BackgroundColor = [1 .6 .784];
else
    obj.mibView.handles.mibMaskedAreaCheck.BackgroundColor = [0.94    0.94    0.94];
end
unFocus(obj.mibView.handles.mibMaskedAreaCheck);   % remove focus from hObject
end