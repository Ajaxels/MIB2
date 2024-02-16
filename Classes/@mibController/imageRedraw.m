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

function imageRedraw(obj)
% function imageRedraw(obj)
% redraw image in the handles.mibImageAxes after press of
% handles.mibHideImageCheck or transparency sliders
%
% Parameters:
% 
% Return values
%

% Updates
% 

obj.mibModel.preferences.Colors.SelectionTransparency = obj.mibView.handles.mibSelectionTransparencySlider.Value;
obj.mibModel.preferences.Colors.MaskTransparency = obj.mibView.handles.mibMaskTransparencySlider.Value;
obj.mibModel.preferences.Colors.ModelTransparency = obj.mibView.handles.mibModelTransparencySlider.Value;

obj.plotImage(0);
end
