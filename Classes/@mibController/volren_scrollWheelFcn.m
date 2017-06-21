function volren_scrollWheelFcn(obj, eventdata)
% function volren_scrollWheelFcn(obj, eventdata)
% callback for mouse wheel during the volume rendering mode
%
% Parameters:
% 

% Copyright (C) 24.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


modifier = obj.mibView.gui.CurrentModifier;   % change size of the brush tool, when the Ctrl key is pressed
scaleF = 1;
if strcmp(modifier, 'shift')
    scaleF = 5;
end
z = 1+(0.1*eventdata.VerticalScrollCount*scaleF);

obj.mibModel.I{obj.mibModel.Id}.magFactor = obj.mibModel.I{obj.mibModel.Id}.magFactor * z;
S = makehgtform('scale', 1/z);
obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = S * obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix;

obj.mibView.handles.mibZoomEdit.String = sprintf('%d %%', round(1/obj.mibModel.I{obj.mibModel.Id}.magFactor*100));
obj.plotImage();
end

