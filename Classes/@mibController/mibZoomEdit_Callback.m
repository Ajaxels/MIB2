function mibZoomEdit_Callback(obj)
% function mibZoomEdit_Callback(obj)
% callback function for modification of the handles.mibZoomEdit 
%
% Parameters:
% handles: structure with handles of im_browser.m

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

zoom = obj.mibView.handles.mibZoomEdit.String;
newMagFactor = 100/str2double(zoom(1:end-1));
obj.updateAxesLimits('zoom', [], newMagFactor);
obj.plotImage(0);
end