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

% Copyright (C) 20.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

switch parameter
    case 'mibSelectionTransparencySlider'
        obj.mibModel.preferences.mibSelectionTransparencySlider = obj.mibView.handles.(parameter).Value;
    case 'mibModelTransparencySlider'
        obj.mibModel.preferences.mibModelTransparencySlider = obj.mibView.handles.(parameter).Value;
    case 'mibMaskTransparencySlider'        
        obj.mibModel.preferences.mibMaskTransparencySlider = obj.mibView.handles.(parameter).Value;
    otherwise
        obj.mibModel.(parameter) = obj.mibView.handles.(parameter).Value;
end
obj.plotImage();
end
