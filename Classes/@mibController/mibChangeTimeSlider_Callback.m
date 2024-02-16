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

function mibChangeTimeSlider_Callback(obj)
% function mibChangeTimeSlider_Callback(obj)
%  A callback function for mibGUI.mibChangeTimeSlider. Responsible for showing next or previous time point of the dataset
%
% Parameters:
%
% Return values:
%

% Updates
% 

% update handles, needed for slider listener, initialized in im_browser_getDefaultParameters() 
%handles = guidata(hObject);

value = obj.mibView.handles.mibChangeTimeSlider.Value;
value_str = sprintf('%.0f',value);
obj.mibView.handles.mibChangeTimeEdit.String = value_str;
value = str2double(value_str);

obj.mibModel.I{obj.mibModel.Id}.slices{5} = [value, value];
notify(obj.mibModel, 'changeTime');   % notify the controller about changed slice
obj.plotImage(0);
end