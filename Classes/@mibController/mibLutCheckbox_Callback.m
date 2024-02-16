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

function mibLutCheckbox_Callback(obj)
% function mibLutCheckbox_Callback(obj)
% a callback to the mibGUI.handles.mibLutCheckbox, turn on/off
% visualization of color channels using luck-up table (LUT)
%
% Parameters:
% 
% Return values:
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