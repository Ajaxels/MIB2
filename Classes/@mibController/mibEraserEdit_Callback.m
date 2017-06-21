function mibEraserEdit_Callback(obj)
% function mibEraserEdit_Callback(obj)
% increase size of the eraser tool with the provided in
% obj.mibView.handles.mibEraserEdit
%
% Parameters:
% 
% Return values
%

% Copyright (C) 09.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

status = obj.mibView.editbox_Callback(obj.mibView.handles.mibEraserEdit, 'pfloat', '1.4');
if status == 0; return; end;

val = str2double(obj.mibView.handles.mibEraserEdit.String);
obj.mibModel.preferences.eraserRadiusFactor = val;
end
