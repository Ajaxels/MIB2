function volren_WindowButtonUpFcn(obj)
% function volren_WindowButtonUpFcn(obj)
% callback for mouse button up event during the volume rendering mode
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
    
obj.mibView.gui.Pointer = 'crosshair';
obj.mibView.gui.WindowButtonUpFcn = [];

if obj.mibModel.I{obj.mibModel.Id}.volren.showFullRes == 0
    S = makehgtform('scale', obj.mibModel.I{obj.mibModel.Id}.volren.previewScale) ;
    obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix * S;
end

obj.mibModel.I{obj.mibModel.Id}.volren.showFullRes = 1;

%set(handles.im_browser, 'WindowButtonDownFcn', {@volren_WindowButtonDownFcn, handles});
obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.volren_WindowButtonDownFcn());
%set(handles.im_browser, 'WindowButtonMotionFcn' , {@volren_winMouseMotionFcn, handles});
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.volren_winMouseMotionFcn());   
obj.plotImage();
end
