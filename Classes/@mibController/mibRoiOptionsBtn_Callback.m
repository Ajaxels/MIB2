function mibRoiOptionsBtn_Callback(obj)
% function mibRoiOptionsBtn_Callback(obj, parameter)
% update ROI visualization settings, as callback of mibGUI.handles.mibRoiOptionsBtn
%
% Parameters:
% 

% Copyright (C) 13.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.mibModel.I{obj.mibModel.Id}.hROI.updateOptions();
obj.plotImage();
end