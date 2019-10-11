function menuFileSaveImageAs_Callback(obj)
% function menuFileSaveImageAs_Callback(obj)
% a callback to the mibGUI.handles.menuFileSaveImageAs, saves image to a file
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
% 04.06.2018 save TransformationMatrix with AmiraMesh
% 22.01.2019 added saving of amira mesh files as 2D sequence

saveImageOptions.DestinationDirectory = obj.mibModel.myPath;
filename = obj.mibModel.I{obj.mibModel.Id}.saveImageAsDialog([], saveImageOptions);
if isempty(filename); return; end
[~, filename, ext] = fileparts(filename);
obj.updateFilelist([filename ext]);     % update list of files, use filename to highlight the saved file
return;
