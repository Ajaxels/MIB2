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

function mibModelPropertyUpdate(obj, parameter)
% function mibModelPropertyUpdate(obj, parameter)
% % update switches in the obj.mibModel class that describe states of GUI
% widgets
%
% Parameters: a string with the parameter name
% @li 'mibHideImageCheck' - enable or disable visualization of the Image layer
% @li 'mibLiveStretchCheck' - enable or diable the live stretching of image intensities
% @li 'mibModelTransparencySlider' -  transparency value for the model layer
% @li 'mibMaskTransparencySlider' - transparency value for the mask layer
% @li 'mibSelectionTransparencySlider' - transparency value for the selection layer
% @li 'mibSegmShowTypePopup' - type of model visualization: @b 1 - filled; @b 2 - contour
% @li 'mibAnnValueEccentricCheck' - enable value-eccentric annotations
%
% Return values
%

% Updates
% 

switch parameter
    case 'mibSelectionTransparencySlider'
        obj.mibModel.preferences.Colors.SelectionTransparency = obj.mibView.handles.(parameter).Value;
    case 'mibModelTransparencySlider'
        obj.mibModel.preferences.Colors.ModelTransparency = obj.mibView.handles.(parameter).Value;
    case 'mibMaskTransparencySlider'        
        obj.mibModel.preferences.Colors.MaskTransparency = obj.mibView.handles.(parameter).Value;
    case 'mibAnnotationPrecisionEdit'
        obj.mibModel.mibAnnValuePrecision = str2double(obj.mibView.handles.mibAnnotationPrecisionEdit.String);
    otherwise
        obj.mibModel.(parameter) = obj.mibView.handles.(parameter).Value;
end
obj.plotImage();
end
