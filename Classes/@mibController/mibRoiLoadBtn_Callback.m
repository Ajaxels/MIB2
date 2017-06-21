function mibRoiLoadBtn_Callback(obj)
% function mibRoiLoadBtn_Callback(obj)
% a callback to the obj.mibView.handles.mibRoiLoadBtn, loads roi from a file to MIB
%
% Parameters:
% 
% Return values:
% 

% Copyright (C) 13.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

% load ROI from a file
if isempty(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'))
    path = obj.mibView.handles.mibPathEdit.String;
else
    path = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
end
[filename, path] = uigetfile(...
    {'*.roi',  'Area shape, Matlab format (*.roi)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Open ROI shape file...',path);
if isequal(filename,0); return; end; % check for cancel

res = load(fullfile(path, filename),'-mat');
obj.mibModel.I{obj.mibModel.Id}.hROI.Data = res.Data;
obj.mibView.handles.mibRoiShowCheck.Value = 1;
obj.mibView.handles.mibRoiList.Value = 1;

% get number of ROIs
[number, indices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI();
str2 = cell([number+1 1]);
str2(1) = cellstr('All');
for i=1:number
%    str2(i+1) = cellstr(num2str(indices(i)));
    str2(i+1) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(indices(i)).label;
end
obj.mibView.handles.mibRoiList.String = str2;
obj.mibRoiShowCheck_Callback();
fprintf('MIB: loading ROI from %s -> done!\n', fullfile(path, filename));
end
