function menuDatasetSlice_Callback(obj, parameter)
% function menuDatasetSlice_Callback(obj, parameter)
% a callback to Menu->Dataset->Slice
% do actions with individual slices
%
% Parameters:
% parameter: a string that defines image source:
% - 'copySlice', copy slice (a section from a Z-stack) from one position to another
% - 'deleteSlice', delete slice (a section from a Z-stack) from the dataset
% - 'deleteFrame', delete frame (a section from a time series) from the dataset

% Copyright (C) 02.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
global mibPath;

switch parameter
    case 'copySlice'
        currentSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
        maxSlice = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
        prompt = {sprintf('Please enter the slice numbers (1-%d)\n\nIndex of the source slice:', maxSlice), 'Index of the destination slice:'};
        dlg_title = 'Copy slice';
        defaultans = {num2str(currentSlice), num2str(min([currentSlice+1 maxSlice]))};
        answer = inputdlg(prompt, dlg_title, 1, defaultans);
        if isempty(answer); return; end
        
        orient = obj.mibModel.I{obj.mibModel.Id}.orientation;
        result = obj.mibModel.I{obj.mibModel.Id}.copySlice(str2num(answer{1}), str2num(answer{2}), orient); %#ok<ST2NM>
        if result == 0; return; end
    case 'deleteSlice'
        currentSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
        maxSlice = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);

        answer=mibInputDlg({mibPath}, sprintf('Please enter slice number(s) to delete (1:%d):\nfor example: 1,5,10,15:20', maxSlice), ...
            'Enter slice number', num2str(currentSlice));
        if isempty(answer); return; end
        
        orient = obj.mibModel.I{obj.mibModel.Id}.orientation;
        result = obj.mibModel.I{obj.mibModel.Id}.deleteSlice(str2num(answer{1}), orient); %#ok<ST2NM>
        if result == 0; return; end
        notify(obj.mibModel, 'newDataset');  % notify newDataset with the index of the dataset
    case 'deleteFrame'
        currentSlice = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
        maxSlice = obj.mibModel.I{obj.mibModel.Id}.time;
        if maxSlice == 1; return; end
        
        answer=mibInputDlg({mibPath}, sprintf('Please enter frame number(s) to delete (1:%d):', maxSlice), ...
            'Enter slice number', num2str(currentSlice));
        if isempty(answer); return; end

        orient = 5;
        result = obj.mibModel.I{obj.mibModel.Id}.deleteSlice(str2num(answer{1}), orient); %#ok<ST2NM>
        if result == 0; return; end
        notify(obj.mibModel, 'newDataset');  % notify newDataset with the index of the dataset
end
notify(obj.mibModel, 'plotImage');
end