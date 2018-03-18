function menuImageToolsProjection_Callback(obj)
% function menuImageToolsProjection_Callback(obj, hObject)
% callback to the Menu->Image->Tools->Intensity projection, calculate
% intensity projection of the dataset
%
% Parameters:
% 
% 

% Copyright (C) 09.03.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;

if obj.mibModel.getImageProperty('modelExist') == 1 || obj.mibModel.getImageProperty('maskExist') == 1
    button = questdlg(...
        sprintf('!!! Warning !!!\n\nThe existing model and mask will be removed during calculation of the image intensity projection!'),...
        'Intensity projection', 'Continue','Cancel','Cancel');
    if strcmp(button, 'Cancel'); return; end
end

prompts = {'Projection type'; 'Dimension'; 'Destination buffer'};
destBuffers = cell([1, obj.mibModel.maxId]);
for i=1:obj.mibModel.maxId
    destBuffers{i} = num2str(i);
end
destBuffers{end+1} = obj.mibModel.Id;
defAns = {{'Max', 'Min', 'Mean','Median', 1}; {'Y', 'X', 'C', 'Z', 'T', 4}; destBuffers};
dlgTitle = 'Calculation of intensity projection';
options.WindowStyle = 'normal';       % [optional] style of the window
options.Title = 'Intensity projection parameters';   % [optional] additional text at the top of the window
options.Focus = 1;      % [optional] define index of the widget to get focus
[answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
if isempty(answer); return; end

bufferId = selIndex(3);
getDataOptions.blockModeSwitch = 0;
I = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
dim = selIndex(2);  % dimension over which calculate projection
switch lower(answer{1})
    case 'min'
        I = min(I, [], dim);
    case 'max'
        I = max(I, [], dim);
    case 'mean'
        classOfImg = class(I);
        I = mean(I, dim);
        evalStr = sprintf('I = %s(I);', classOfImg);
        eval(evalStr);
    case 'median'
        I = median(I, dim);
end
if dim < 3  % permute the matrix
    if dim == 1
        I = permute(I, [4, 2, 3, 1]);
    elseif dim == 2
        I = permute(I, [1, 4, 3, 2]);
    end
end

logText = sprintf('%s-intensity projection, dim=%c', lower(answer{1}), answer{2});
if bufferId == obj.mibModel.Id
    getDataOptions.replaceDatasetSwitch = 1;    % force to replace dataset
    obj.mibModel.setData4D('image', I, 4, 0, getDataOptions);
    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(logText);
else
    obj.mibModel.I{bufferId} = mibImage(I, obj.mibModel.getImageProperty('meta'));

    eventdata = ToggleEventData(bufferId);
    notify(obj.mibModel, 'newDataset', eventdata);
    obj.mibModel.I{bufferId}.updateImgInfo(logText);
end

obj.updateGuiWidgets();
obj.plotImage();
end