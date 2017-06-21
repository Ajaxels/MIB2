function mibBufferToggle_Callback(obj, Id)
% function mibBufferToggle_Callback(obj, Id)
% a callback to press of obj.mibView.handles.mibBufferToggle button
%
% Parameters:
% Id: index of the pressed toggle button

% Copyright (C) 04.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.mibView.imh = matlab.graphics.primitive.Image('CData', []); 
obj.updateShownId(str2double(Id));

[path, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
if ~isempty(path);     obj.mibModel.myPath = path;   end;
obj.updateFilelist([fn, ext]);
end