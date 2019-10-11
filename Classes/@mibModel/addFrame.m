function BatchOptOut = addFrame(obj, BatchOpt)
% function BatchOptOut = addFrame(obj, BatchOpt)
% Add a frame around the dataset
% see also mibModel.addFrameToImage function
%
% Parameters:
% BatchOpt: an optional structure with parameters
% .FrameWidth - a string with a width of the frame
% .FrameHeight - a string with a height of the frame
% .IntensityPadValue - a string with intensity of the frame
% .Method - a cell string with one of these options {'use the pad value', 'replicate', 'circular', 'symmetric'}
% .Direction - a cell string with one of these options {'both', 'pre', 'post'}
% .showWaitbar - logical, show or not the waitbar
%
% Return values:
% BatchOptOut: structure with parameters used in the function

% Copyright (C) 13.03.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 13.03.2019

global mibPath;

if obj.I{obj.Id}.Virtual.virtual == 1
    errordlg('Not yet implemented!');
    return;
end

% default BatchOpt settings
BatchOptOut.Transform = {'Add frame (dX/dY)'};
BatchOptOut.Transform{2} = {'Add frame (dX/dY)'};
BatchOptOut.FrameWidth = '10';
BatchOptOut.FrameHeight = '10';
BatchOptOut.IntensityPadValue = num2str(intmax(obj.I{obj.Id}.meta('imgClass')));
BatchOptOut.Method = {'use the pad value'};
BatchOptOut.Method{2} = {'use the pad value', 'replicate', 'circular', 'symmetric'};
BatchOptOut.Direction = {'both'};
BatchOptOut.Direction{2} = {'both', 'pre', 'post'};
BatchOptOut.showWaitbar = true;

if nargin < 2
    maxVal = BatchOptOut.IntensityPadValue;
    prompts = {'Frame width, px:'; 'Frame height (can be negative), px'; sprintf('Intensity pad value (0 - %s):', maxVal); 'Method:'; 'Direction:'};
    defAns = {'10'; '10'; maxVal; {'use the pad value', 'replicate', 'circular', 'symmetric', 1}; {'both', 'pre', 'post', 1}};
    dlgTitle = 'Add frame';
    options.Title = 'Please provide width and height for the frame; when both values are negative the dataset is trimmed from the sides using this value';
    options.TitleLines = 3;
    options.PromptLines = [1, 1, 2, 1, 1];   % [optional] number of lines for widget titles
    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); return; end
    
    BatchOptOut.FrameWidth = answer{1};
    BatchOptOut.FrameHeight = answer{2};
    BatchOptOut.IntensityPadValue = answer{3};
    BatchOptOut.Method(1) = answer(4);
    BatchOptOut.Direction(1) = answer(5);
else
    % add missing fields structures
    fieldNames = fieldnames(BatchOpt);
    for i=1:numel(fieldNames)
        BatchOptOut.(fieldNames{i}) = BatchOpt.(fieldNames{i});
    end
end

padval = str2double(BatchOptOut.IntensityPadValue);
direction = BatchOptOut.Direction{1};
method = BatchOptOut.Method{1};
extW = str2double(BatchOptOut.FrameWidth);
extH = str2double(BatchOptOut.FrameHeight);

if isnan(extW) || isnan(extH) || isnan(padval)
    errordlg(sprintf('!!! Error !!!\n\nWrong width, height or pad intensity value parameter!\nThese parameters should be numbers above 0, or 0'));
    return;
end
% if extW < 0 || extH < 0 || padval < 0
%     errordlg(sprintf('!!! Error !!!\n\nWrong width, height or pad intensity value parameter!\nThese parameters should not be negative'));
%     return;
% end

tic
options.blockModeSwitch = 0;    % overwrite blockmode switch
[yMax, xMax, cMax, zMax, tMax] = obj.I{obj.Id}.getDatasetDimensions('image', 4, NaN, options);
cMax = numel(cMax);

if strcmp(direction, 'both')
    outputDims = [yMax+extH*2, xMax+extW*2, cMax, zMax, tMax];
else    % pre or post
    outputDims = [yMax+extH, xMax+extW, cMax, zMax, tMax];
end
imgOut = zeros(outputDims, class(obj.I{obj.Id}.img{1}(1)));

if BatchOptOut.showWaitbar; wb = waitbar(0,sprintf('Adding a frame to the image\nPlease wait...'),...
        'Name', 'Add frame', 'WindowStyle', 'modal'); end

% transpose the image layer
for t=1:tMax
    img = cell2mat(obj.getData3D('image', t, 4, 0, options));   % get z-stack (image)
    if extW > 0 && extH > 0
        if strcmp(method, 'use the pad value')    % use the pad value
            imgOut(:,:,:,:,t) = padarray(img, [extH, extW], padval, direction);
        else
            imgOut(:,:,:,:,t) = padarray(img, [extH, extW], method, direction);
        end
    else
        imgOut(:,:,:,:,t) = img(-extH+1:end+extH, -extW+1:end+extW, :, :);
    end
    if BatchOptOut.showWaitbar; waitbar(t/tMax, wb); end
end
obj.setData4D('image', imgOut, 4, 0, options);   % set dataset (image) back
clear imgOut;

% transpose other layers
if obj.I{obj.Id}.modelType == 63 && obj.I{obj.Id}.disableSelection == 0
    if BatchOptOut.showWaitbar; waitbar(0.5, wb, sprintf('Adding a frame to other layers\nPlease wait...')); end
    img = obj.I{obj.Id}.model{1};  % get everything
    obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        if extW > 0 && extH > 0
            if strcmp(method, 'use the pad value')    % use the pad value
                imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
            else
                imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
            end
        else
            imgOut = img(-extH+1:end+extH, -extW+1:end+extW, :, t);
        end
        obj.setData3D('everything', imgOut, t, 4, NaN, options);   % set dataset (everything) back
        if BatchOptOut.showWaitbar; waitbar(t/tMax, wb); end
    end
elseif obj.I{obj.Id}.disableSelection == 0
    % transpose selection layer
    if BatchOptOut.showWaitbar; waitbar(0.25, wb, sprintf('Adding a frame to the selection layer\nPlease wait...')); end
    img = obj.I{obj.Id}.selection{1};  % get selection
    obj.I{obj.Id}.selection{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        if extW > 0 && extH > 0
            if strcmp(method, 'use the pad value')    % use the pad value
                imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
            else
                imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
            end
        else
            imgOut = img(-extH+1:end+extH, -extW+1:end+extW, :, t);
        end
        obj.setData3D('selection', imgOut, t, 4, NaN, options);   % set dataset (everything) back
        if BatchOptOut.showWaitbar; waitbar(t/tMax, wb); end
    end
    
    % transpose mask
    if obj.I{obj.Id}.maskExist
        if BatchOptOut.showWaitbar; waitbar(0.5, wb, sprintf('Adding a frame to the mask layer\nPlease wait...')); end
        img = obj.I{obj.Id}.maskImg{1};  % get mask
        obj.I{obj.Id}.maskImg{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            if extW > 0 && extH > 0
                if strcmp(method, 'use the pad value')    % use the pad value
                    imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
                else
                    imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
                end
            else
                imgOut = img(-extH+1:end+extH, -extW+1:end+extW, :, t);
            end
            obj.setData3D('mask', imgOut, t, 4, NaN, options);   % set dataset (everything) back
            if BatchOptOut.showWaitbar; waitbar(t/tMax, wb); end
        end
    end
    
    % transpose model
    if obj.I{obj.Id}.modelExist
        if BatchOptOut.showWaitbar; waitbar(0.75, wb, sprintf('Adding a frame to the model layer\nPlease wait...')); end
        img = obj.I{obj.Id}.model{1};  % get model
        obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            if extW > 0 && extH > 0
                if strcmp(method, 'use the pad value')    % use the pad value
                    imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
                else
                    imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
                end
            else
                imgOut = img(-extH+1:end+extH, -extW+1:end+extW, :, t);
            end
            obj.setData3D('model', imgOut, t, 4, NaN, options);   % set dataset (everything) back
            if BatchOptOut.showWaitbar; waitbar(t/tMax, wb); end
        end
    end
end
if BatchOptOut.showWaitbar; waitbar(1, wb, sprintf('Finishing...')); end
clear img;

% % update the bounding box
bb = obj.I{obj.Id}.getBoundingBox();    % get current bounding box
switch direction
    case 'both'
        bb(1) = bb(1)-extW*obj.I{obj.Id}.pixSize.x;
        bb(2) = bb(2)+extW*obj.I{obj.Id}.pixSize.x;
        bb(3) = bb(3)-extH*obj.I{obj.Id}.pixSize.y;
        bb(4) = bb(4)+extH*obj.I{obj.Id}.pixSize.y;
    case 'pre'
        bb(1) = bb(1)-extW*obj.I{obj.Id}.pixSize.x;
        bb(3) = bb(3)-extH*obj.I{obj.Id}.pixSize.y;
    case 'post'
        bb(2) = bb(2)+extW*obj.I{obj.Id}.pixSize.x;
        bb(4) = bb(4)+extH*obj.I{obj.Id}.pixSize.y;
end
obj.I{obj.Id}.updateBoundingBox(bb);  % update bounding box

crop_factor = [-extW+1, -extH+1, NaN, NaN, 1, NaN, 1, NaN];
obj.I{obj.Id}.hROI.crop(crop_factor);
obj.I{obj.Id}.hLabels.crop(crop_factor);

if strcmp(method, 'use the pad value')    % use the pad value
    log_text = sprintf('Add frame: dX=%d, dY=%d, padValue=%d, direction=%s', extW, extH, padval, direction);
else
    log_text = sprintf('Add frame: dX=%d, dY=%d, method=%s, direction=%s', extW, extH, method, direction);
end
obj.I{obj.Id}.updateImgInfo(log_text);
if BatchOptOut.showWaitbar; delete(wb); end
toc;

BatchOptOut.Method{2} = {'use the pad value', 'replicate', 'circular', 'symmetric'};
BatchOptOut.Direction{2} = {'both', 'pre', 'post'};

notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
eventdata = ToggleEventData(1);
notify(obj, 'plotImage', eventdata);
end

