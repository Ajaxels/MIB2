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
% 16.08.2017 IB added waitbar
% 15.11.2018, IB, added selection of materials
global mibPath;

unFocus(obj.mibView.handles.mibRemoveMaterialBtn); % remove focus from hObject

if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial >= 3
    value = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
else
    value = '';
end  
prompts = {sprintf('Specify indices of materials to be removed\n(for example, 2,4,6:8)')};
defAns = {num2str(value)};
dlgTitle = 'Delete materials';
options.WindowStyle = 'modal'; 
options.PromptLines = 2;  
answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
if isempty(answer); return; end
value = str2num(answer{1});
modelMaterialNames = obj.mibModel.getImageProperty('modelMaterialNames');    % list of materials of the model

matListString = sprintf('%s, ', modelMaterialNames{value});
matIndexString = sprintf('%d, ', value);
msg = sprintf('You are going to delete material(s):\n"%s",\nwith indices: %s\n\nAre you sure?', matListString(1:end-2), matIndexString(1:end-2));
button =  questdlg(msg, 'Delete materials?', 'Yes', 'Cancel', 'Cancel');
if strcmp(button, 'Cancel') == 1; return; end

wb = waitbar(0, sprintf('Deleting materials\nPlease wait...'), 'Name', 'Deleting materials');
value = sort(value,'descend');

options.blockModeSwitch=0;
waitbar(0.05, wb);
maxIndex = obj.mibModel.getImageProperty('time')*numel(value);
curIndex = 0;
for t=1:obj.mibModel.getImageProperty('time')
    model = cell2mat(obj.mibModel.getData3D('model', t, 4, NaN, options));
    model(ismember(model, value)) = 0;  % make 0 all pixels in the selected materials
    for modelId = 1:numel(value)
        model(model>value(modelId)) = model(model>value(modelId)) - 1;
        
        curIndex = curIndex + 1;
        waitbar(curIndex/maxIndex , wb);
    end
    obj.mibModel.setData3D('model', model, t, 4, NaN, options);
end

obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(value,:) = [];  % remove color of the removed material
obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(value) = [];  % remove material name from the list of materials

obj.updateSegmentationTable();
obj.mibView.lastSegmSelection = [2 1];
delete(wb);
obj.plotImage(0);
end