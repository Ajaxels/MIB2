function menuDatasetSlice_Callback(obj, parameter)
% function menuDatasetSlice_Callback(obj, parameter)
% a callback to Menu->Dataset->Slice
% do actions with individual slices
%
% Parameters:
% parameter: a string that defines image source:
% - 'copySlice', copy slice (a section from a Z-stack) from one position to another
% - 'insertSlice', insert an empty slice
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
% 28.03.2018, IB added insert an empty slice

global mibPath;

% check for the virtual stacking mode and close the controller
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'slice actions';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

switch parameter
    case 'copySlice'
        currentSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
        maxSlice = obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation);
        prompt = {'Replace or insert slice at the destination:', 'Index of the source slice:', 'Index of the destination slice (use 0 to insert the slice at the end of the dataset):'};
        defAns = {{'Replace','Insert', 1}, num2str(currentSlice), num2str(min([currentSlice+1 maxSlice]))};
        mibInputMultiDlgOptions.Title = sprintf('Please enter the slice numbers (1-%d)', maxSlice);
        mibInputMultiDlgOptions.TitleLines = 2;
        mibInputMultiDlgOptions.PromptLines = [1, 1, 2];
        
        answer = mibInputMultiDlg({obj.mibPath}, prompt, defAns, 'Copy slice', mibInputMultiDlgOptions);
        if isempty(answer); return; end
        
        if isnan(str2double(answer{2})) || isnan(str2double(answer{3}))
            errordlg(sprintf('!!! Error !!!\n\nWrong number!'));
            return;
        end
        
        if strcmp(answer{1}, 'Replace')
            orient = obj.mibModel.I{obj.mibModel.Id}.orientation;
            result = obj.mibModel.I{obj.mibModel.Id}.copySlice(str2num(answer{2}), str2num(answer{3}), orient); %#ok<ST2NM>
            if result == 0; return; end
        else
            getDataOpt.blockmodeSwitch = 0;
            img = cell2mat(obj.mibModel.getData2D('image', str2double(answer{2}), NaN, NaN, getDataOpt));
            obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, str2double(answer{3}));
            notify(obj.mibModel, 'newDataset');  % notify newDataset 
        end
    case 'insertSlice'
        currentSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
        maxSlice = obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation);
        imgClass = class(obj.mibModel.I{obj.mibModel.Id}.img{1}(1));
        maxIntValue = intmax(imgClass);
        prompt = {'Destination index (use 0 to insert a slice into the end of the dataset):', sprintf('Intensity of the color (0 for black-%d for white)', maxIntValue)};
        defAns = {num2str(currentSlice), num2str(maxIntValue)};
        
        mibInputMultiDlgOptions.Title = sprintf('Please enter the slice number (1-%d) and intensity of the color', maxSlice);
        mibInputMultiDlgOptions.TitleLines = 2;
        mibInputMultiDlgOptions.PromptLines = [2, 1];
        answer = mibInputMultiDlg({obj.mibPath}, prompt, defAns, 'Copy slice', mibInputMultiDlgOptions);
        if isempty(answer); return; end
        
        if isnan(str2double(answer{1})) || isnan(str2double(answer{2}))
            errordlg(sprintf('!!! Error !!!\n\nWrong number!'));
            return;
        end
        
        getDataOpt.blockmodeSwitch = 0;
        [height, width, colors] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOpt);
        img = zeros([height, width, colors], imgClass) + str2double(answer{2});
        obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, str2double(answer{1}));
        notify(obj.mibModel, 'newDataset');  % notify newDataset 
    case 'deleteSlice'
        currentSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
        maxSlice = obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation);

        answer=mibInputDlg({mibPath}, sprintf('Please enter slice number(s) to delete (1:%d):\nfor example: 1,5,10,15:20', maxSlice), ...
            'Enter slice number', num2str(currentSlice));
        if isempty(answer); return; end
        
        orient = obj.mibModel.I{obj.mibModel.Id}.orientation;
        result = obj.mibModel.I{obj.mibModel.Id}.deleteSlice(str2num(answer{1}), orient); %#ok<ST2NM>
        if result == 0; return; end
        notify(obj.mibModel, 'newDataset');  % notify newDataset
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