function menuMaskImageReplace_Callback(obj, type)
% function menuMaskImageReplace_Callback(obj, type)
% callback to Menu->Mask->Replace color; 
% Replace image intensities in the @em Masked or @em Selected areas with new intensity value
%
% Parameters:
% type: a string with source layer
% @li 'mask' - replace image intensities under the Mask layer
% @li 'selection' - replace image intensities under the Selection layer

% Copyright (C) 10.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'), 'indexed')
    msgbox('Not compatible with indexed images!');
    return;
end
max_slice = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
max_time = obj.mibModel.I{obj.mibModel.Id}.time;

prompt = {sprintf('Your are going to replace the *%s* area in the image.\n\nPlease provide intensity of a new color [0-%d]:', ...
    type, intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1}))), ...
    sprintf('Time point (1-%d; 0 for all):', max_time), ...
    sprintf('Slice number (1-%d; 0 for all):', max_slice), ...
    'Color channels (0 for all):'};
title = 'Replace color';
time_pnt = obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint();
slice_no = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
def = {repmat('0;', 1, obj.mibModel.I{obj.mibModel.Id}.colors), num2str(time_pnt), num2str(slice_no), '0'};

answer = inputdlg(prompt, title, 1, def, 'on');
if size(answer) == 0; return; end;

color_id = str2num(answer{1}); %#ok<ST2NM>
if numel(color_id) ~= obj.mibModel.I{obj.mibModel.Id}.colors
    color_id = repmat(color_id(1), 1, obj.mibModel.I{obj.mibModel.Id}.colors)';
end
time_pnt = str2double(answer{2});
slice_id = str2double(answer{3});
channel_id = str2double(answer{4});

% do backups
if slice_id ~= 0 && time_pnt ~= 0
    getDataOptions.z = [slice_id slice_id];
    getDataOptions.t = [time_pnt time_pnt];
    obj.mibModel.mibDoBackup('image', 0, getDataOptions); 
elseif time_pnt ~= 0
    getDataOptions.t = [time_pnt time_pnt];
    obj.mibModel.mibDoBackup('image', 1, getDataOptions); 
end

obj.mibModel.I{obj.mibModel.Id}.replaceImageColor(type, color_id, channel_id, slice_id, time_pnt);
obj.plotImage();
end
