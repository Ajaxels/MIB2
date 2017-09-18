% --- Executes on button press in maskShowCheck.
function mibMaskShowCheck_Callback(obj)
% function mibMaskShowCheck_Callback(obj)
% a callback to the mibGUI.handles.maskShowCheck, allows to toggle visualization of the mask layer
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
    obj.mibView.handles.mibMaskShowCheck.Value = 0;
    obj.mibModel.mibMaskShowCheck = 0;
    return;
end
obj.mibModel.mibMaskShowCheck = obj.mibView.handles.mibMaskShowCheck.Value;
obj.plotImage(0);
unFocus(obj.mibView.handles.mibMaskShowCheck);   % remove focus from hObject
end