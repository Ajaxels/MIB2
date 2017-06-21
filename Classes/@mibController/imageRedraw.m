function imageRedraw(obj)
% function imageRedraw(obj)
% redraw image in the handles.mibImageAxes after press of
% handles.mibHideImageCheck or transparency sliders
%
% Parameters:
% 
% Return values
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

obj.mibModel.preferences.mibSelectionTransparencySlider = obj.mibView.handles.mibSelectionTransparencySlider.Value;
obj.mibModel.preferences.mibMaskTransparencySlider = obj.mibView.handles.mibMaskTransparencySlider.Value;
obj.mibModel.preferences.mibModelTransparencySlider = obj.mibView.handles.mibModelTransparencySlider.Value;
            
obj.plotImage(0);
end
