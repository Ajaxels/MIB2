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
destBuffers = arrayfun(@(x) sprintf('%d', x), 1: obj.mibModel.maxId, 'UniformOutput', false);
destBuffers{end+1} = obj.mibModel.Id;
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0
    defAns = {{'Max', 'Min', 'Mean','Median','Focus stacking' 1}; {'Y', 'X', 'C', 'Z', 'T', 4}; destBuffers};
else
    defAns = {{'Max', 'Min', 'Mean', 1}; {'Z', 1}; destBuffers};
end
dlgTitle = 'Calculation of intensity projection';
options.WindowStyle = 'normal';       % [optional] style of the window
options.Title = 'Intensity projection parameters';   % [optional] additional text at the top of the window
options.Focus = 1;      % [optional] define index of the widget to get focus
[answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
if isempty(answer); return; end

projectionType = lower(answer{1});
dim = selIndex(2);  % dimension over which calculate projection
bufferId = selIndex(3);

wb = waitbar(0, sprintf('Generating the projection\nPlease wait...'), 'Name', 'Projection');

getDataOptions.blockModeSwitch = 0;
[height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, getDataOptions);
colors = numel(colors);

if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0
    if strcmp(projectionType, 'focus stacking')
        if depth < 3
            errordlg('Focus stacking requires at least 3 images assembled into a Z-stack');
            delete(wb);
            return;
        end
        if dim ~= 4
            res = questdlg(sprintf('!!! Warning !!!\n\nThe focus stacking is only available for the Z-dimention!\nContinue?'), 'Dimension issue', 'Continue', 'Cancel', 'Continue');
            if strcmp(res, 'Cancel'); delete(wb); return; end
        end
        dim = 4;    % only available for the Z-stacks
        I = zeros([height, width, colors, 1, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'));
        if time > 1
            fstackOptions.showWaitbar = 0; 
        else
            fstackOptions.showWaitbar = 1;
        end
        for t = 1:time
            Iin = cell2mat(obj.mibModel.getData3D('image', t, 4, 0, getDataOptions));
            I(:,:,:,1,t) = fstack_mib(Iin, fstackOptions);
        end
    else
        I = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
        waitbar(0.1, wb);
        switch projectionType
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
    end
    waitbar(0.8, wb);
    if dim < 3  % permute the matrix
        if dim == 1
            I = permute(I, [4, 2, 3, 1, 5]);
        elseif dim == 2
            I = permute(I, [1, 4, 3, 2, 5]);
        end
    end
    waitbar(0.9, wb);
else        % virtual stacking mode
    % allocate space for the output image
    switch projectionType
        case 'min'
            shift = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
            I = zeros([height, width, colors, 1, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')) + shift;
        case 'max'
            I = zeros([height, width, colors, 1, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'));
        case 'mean'
            I = zeros([height, width, colors, 1, time]);
    end
    waitbar(0.1, wb);
    for t = 1:time
        getDataOptions.t = t;
        for z = 1:depth
            Icur = cell2mat(obj.mibModel.getData2D('image', z, 4, 0, getDataOptions));
            switch projectionType
                case 'min'
                    I(:,:,:,1,t) = min(I(:,:,:,1,t), Icur);
                case 'max'
                    I(:,:,:,1,t) = max(I(:,:,:,1,t), Icur);
                case 'mean'
                    I(:,:,:,1,t) = I(:,:,:,1,t) + double(Icur)/depth;
            end
        end
        waitbar(t/time, wb);
    end
end

% convert from double to the image class
if isa(I, 'double')
    commandStr = sprintf('I = %s(I);', obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'));
    eval(commandStr);
end

waitbar(0.95, wb);

logText = sprintf('%s-intensity projection, dim=%c', lower(answer{1}), answer{2});
% store view port structure
if ~strcmp(answer{2}, 'C'); viewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;   end
if bufferId == obj.mibModel.Id
    if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
        newMode = obj.mibModel.I{obj.mibModel.Id}.switchVirtualStackingMode(0, obj.mibModel.preferences.disableSelection);
        if isempty(newMode); delete(wb); return; end
    end
    setDataOptions.replaceDatasetSwitch = 1;    % force to replace dataset
    setDataOptions.keepModel = 0;   % reinitialize the model
    obj.mibModel.setData4D('image', I, 4, 0, setDataOptions);
    if ~strcmp(answer{2}, 'C')
        obj.mibModel.I{obj.mibModel.Id}.viewPort = viewPort;   % restore viewport
    end
    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(logText);
    notify(obj.mibModel, 'newDataset');
else
    if obj.mibModel.I{bufferId}.Virtual.virtual == 1; obj.mibModel.I{bufferId}.clearContents(); end % close the readers, otherwise the files stay locked
    meta = containers.Map(keys(obj.mibModel.I{obj.mibModel.Id}.meta), values(obj.mibModel.I{obj.mibModel.Id}.meta));
    meta('Height') = size(I,1);
    meta('Width') = size(I,2);
    meta('Colors') = size(I,3);
    meta('Depth') = size(I,4);
    meta('Time') = size(I,5);
    obj.mibModel.I{bufferId} = mibImage(I, meta);
    if ~strcmp(answer{2}, 'C')
        obj.mibModel.I{bufferId}.viewPort = viewPort;   % restore viewport
    end
    eventdata = ToggleEventData(bufferId);
    notify(obj.mibModel, 'newDataset', eventdata);
    obj.mibModel.I{bufferId}.updateImgInfo(logText);
end
waitbar(1, wb);
obj.updateGuiWidgets();
obj.plotImage();
delete(wb);
end