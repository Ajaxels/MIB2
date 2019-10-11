% --- Executes on button press in maskShowCheck.
function mibLutCheckbox_Callback(obj)
% function mibLutCheckbox_Callback(obj)
% a callback to the mibGUI.handles.mibLutCheckbox, turn on/off
% visualization of color channels using luck-up table (LUT)
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 07.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

val = obj.mibView.handles.mibLutCheckbox.Value;
if val==1 && strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'), 'indexed')
    errordlg(sprintf('LUTs are not implemented for the indexed images!\n\nPlease convert the image to the RGB color to use LUT:\nMenu->Image->Mode->RGB Color'),'Color type error!')
    obj.mibView.handles.mibLutCheckbox.Value = 0;
    obj.mibModel.I{obj.mibModel.Id}.useLUT = 0;
    return;
end
obj.mibModel.I{obj.mibModel.Id}.useLUT = val;
% update handles.channelMixerTable
obj.redrawMibChannelMixerTable();

% redraw image in the obj.mibView.handles.mibImageAxes
obj.plotImage(0);

unFocus(obj.mibView.handles.mibLutCheckbox);   % remove focus from hObject
end