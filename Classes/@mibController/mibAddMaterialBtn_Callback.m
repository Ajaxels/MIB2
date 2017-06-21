function mibAddMaterialBtn_Callback(obj)
% function mibAddMaterialBtn_Callback(obj)
% callback to the obj.mibView.handles.mibAddMaterialBtn, add material to the model
%
%
% Parameters:
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibAddMaterialBtn_Callback();     // add material to the model @endcode
 
% Copyright (C) 29.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
global mibPath;

unFocus(obj.mibView.handles.mibAddMaterialBtn); % remove focus from hObject

% do nothing is selection is disabled
if obj.mibModel.preferences.disableSelection == 1
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The models are disabled');
    return;
end

if ~obj.mibModel.getImageProperty('modelExist')
    obj.mibCreateModelBtn_Callback(); % make an empty model
end

list = obj.mibModel.getImageProperty('modelMaterialNames');
if isempty(list); list = cell(0); end    % remove empty entry from the list
number = numel(list);

if obj.mibModel.getImageProperty('modelType') < number + 1 
    warndlg(sprintf('!!! Warning !!!\n\nThe current type of the model can only have %d materials!\n\nPlease convert it to another suitable type and try again:\nMenu->Models->Type', obj.mibModel.getImageProperty('modelType')), ...
        'Wrong model type', 'modal');
    return;
end

if obj.mibModel.getImageProperty('modelType') < 256

    answer = mibInputDlg({mibPath}, sprintf('Please add a new name for this material:'), 'Rename material', num2str(number+1));
    if ~isempty(answer)
        list(end+1,1) = cellstr(answer(1));
    else
        return;
    end

    % update material list for the model
    obj.mibModel.setImageProperty('modelMaterialNames', list);
    obj.mibModel.I{obj.mibModel.Id}.generateModelColors();

    obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = numel(list)+2;
    obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = numel(list)+2;
    obj.updateSegmentationTable('end'); % scroll the segmentation table to bottom
    obj.plotImage(0);
else     % for 65535 model look for the next empty material
    maxVal = 0;
    options.blockModeSwitch = 0;
    wb = waitbar(0, sprintf('Looking for the next empty material\nPlease wait...'), 'Name', 'Next empty material', 'WindowStyle','modal');
    t2 = obj.mibModel.getImageProperty('time');
    for t=1:t2
        M = cell2mat(obj.mibModel.getData3D('model', t, 4, NaN, options));
        maxVal = max([maxVal max(max(max(M)))]);
        waitbar(t/t2, wb);
    end
    waitbar(.99, wb);
    if maxVal == obj.mibModel.getImageProperty('modelType')
        delete(wb);
        warndlg(sprintf('!!! Warning !!!\n\nThe model is full, i.e. the maximal material index found in the model is equal to the maximal allowed number (%d)', maxVal), 'Model is full!');
        return;
    end
    
    if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial > 2
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{obj.mibModel.I{obj.mibModel.Id}.selectedMaterial-2} = num2str(maxVal+1);
        eventdata2.Indices = [obj.mibModel.I{obj.mibModel.Id}.selectedMaterial, 2];
    else
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{1} = num2str(maxVal+1);
        eventdata2.Indices = [3, 2];
    end
    obj.mibSegmentationTable_CellSelectionCallback(eventdata2);     % update mibSegmentationTable
    waitbar(1, wb);
    delete(wb);
end
end