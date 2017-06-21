function mibRemoveMaterialBtn_Callback(obj)
% function mibRemoveMaterialBtn_Callback(obj)
% callback to the obj.mibView.handles.mibRemoveMaterialBtn, remove material from the model
%
%
% Parameters:
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibRemoveMaterialBtn_Callback();     // add material to the model @endcode
 
% Copyright (C) 29.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

unFocus(obj.mibView.handles.mibRemoveMaterialBtn); % remove focus from hObject

if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial < 3; return; end;  % can't delete Mask/Exterior
value = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;

modelMaterialNames = obj.mibModel.getImageProperty('modelMaterialNames');    % list of materials of the model
msg = sprintf('You are going to delete material "%s"\nwhich has a number: %d\n\nAre you sure?', modelMaterialNames{value}, value);
button =  questdlg(msg,'Delete contour?','Yes','Cancel','Cancel');
if strcmp(button, 'Cancel') == 1; return; end;

options.blockModeSwitch=0;
for t=1:obj.mibModel.getImageProperty('time')
    model = cell2mat(obj.mibModel.getData3D('model', t, 4, NaN, options));

    model(model==value) = 0;
    model(model>value) = model(model > value) - 1;
    obj.mibModel.setData3D('model', model, t, 4, NaN, options);
end
obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(value,:) = [];  % remove color of the removed material
obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(value) = [];  % remove material name from the list of materials

obj.updateSegmentationTable();
obj.mibView.lastSegmSelection = 1;
obj.plotImage(0);
end