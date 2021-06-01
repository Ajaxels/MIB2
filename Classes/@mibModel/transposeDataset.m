function transposeDataset(obj, mode, showWaitbar, noColorChannels)
% function transposeDataset(obj, mode, showWaitbar, noColorChannels)
% Transpose dataset physically between dimensions
%
% Parameters:
% mode: -> a string that defines the transpose dimension
%     - ''Transpose XY -> ZX'' -> transpose so that XY dimension becomes ZX
%     - ''Transpose XY -> ZY'' -> transpose so that XY dimension becomes ZY
%     - ''Transpose ZX -> ZY'' -> transpose so that ZX dimension becomes ZY
%     - ''Transpose Z<->T'' -> transpose so that Z-dimension becomes T-dimension
%     - ''Transpose Z->C'' -> transpose Z to C, if noColorChannels 
% showWaitbar: logical, show or not the waitbar
% noColorChannels: numeric, a number of color channels for the 'Transpose
% Z->C' mode; provide NaN to generate as many color channels as Z-sections
% Return values:
% 

% Copyright (C) 02.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 4; noColorChannels = NaN; end
if nargin < 3; showWaitbar = true; end

options.blockModeSwitch = 0;    % overwrite blockmode switch
tic
[yMax, xMax, cMax, zMax, tMax] = obj.I{obj.Id}.getDatasetDimensions('image', 4, NaN, options);
cMax = obj.I{obj.Id}.colors;
switch mode
    case 'Transpose XY -> ZX'
        imgOut = zeros([zMax, xMax, cMax, yMax, tMax], obj.I{obj.Id}.meta('imgClass')); %#ok<ZEROLIKE>
        outputDims = [zMax, xMax, cMax, yMax, tMax];
    case 'Transpose XY -> ZY'
        imgOut = zeros([yMax, zMax, cMax, xMax tMax], obj.I{obj.Id}.meta('imgClass')); %#ok<ZEROLIKE>
        outputDims = [yMax, zMax, cMax, xMax tMax];
    case 'Transpose ZX -> ZY'
        imgOut = zeros([xMax, yMax, cMax, zMax, tMax], obj.I{obj.Id}.meta('imgClass')); %#ok<ZEROLIKE>
        outputDims = [xMax, yMax, cMax, zMax, tMax];
    case 'Transpose Z<->T'
        obj.transposeZ2T();
        log_text = 'Transpose: mode=Z->T';
        obj.I{obj.Id}.updateImgInfo(log_text);
        notify(obj, 'newDatasetLite');  % notify newDataset with the index of the dataset
        eventdata = ToggleEventData(1);
        notify(obj, 'plotImage', eventdata);
        return;
    case 'Transpose Z<->C'
        if isnan(noColorChannels)
            cMaxNew = zMax;
            zMaxNew = cMax;
            log_text = 'Transpose: mode=Z->C';
        else
            if cMax > 1
                errordlg(sprintf('!!! Error !!!\n\nTransformation of Z to C is working only with the single color channel before the transformation!'), 'Wrong too many color channels');
                return;
            end
            cMaxNew = noColorChannels;
            zMaxNew = zMax/noColorChannels;
            log_text = sprintf('Transpose: mode=Z->C; ColChNo=%d', cMax);
        end
        if mod(zMaxNew, 1) ~= 0
            errordlg('Division of Z by C should give a round number!', 'Wrong number of resulting color channels!');
            return;
        end
        if showWaitbar; wb = waitbar(0,sprintf('Transposing the image Z->C\nPlease wait...'),...
             'Name', 'Transpose dataset', 'WindowStyle', 'modal'); end
        
        imgOut = zeros([yMax, xMax, cMaxNew, zMaxNew, tMax], obj.I{obj.Id}.meta('imgClass'));
        % transpose the image layer
        for t=1:tMax
            img = cell2mat(obj.getData3D('image', t, 4, 0, options));   % get z-stack (image)
            if isnan(noColorChannels)
                imgOut(:,:,:,:,t) = permute(img,[1, 2, 4, 3]);
            else
                for z=1:zMax
                    % mod(z-1,3)+1
                    imgOut(:,:,mod(z-1, noColorChannels)+1,ceil(z/noColorChannels),t) = img(:, :, :, z);
                end
            end
            
            if showWaitbar; waitbar(t/tMax, wb); end
        end
        
        viewPort = obj.I{obj.Id}.viewPort;
        meta = containers.Map(keys(obj.I{obj.Id}.meta), values(obj.I{obj.Id}.meta));
        meta('Colors') = size(imgOut,3);
        meta('Depth') = size(imgOut,4);
        if size(imgOut, 3) > 1     % define color type for provided image
            meta('ColorType') = 'truecolor';
        else
            meta('ColorType') = 'grayscale';
        end
        
        obj.I{obj.Id} = mibImage(imgOut, meta);
        if cMaxNew<cMax     % restore viewport
            obj.I{obj.Id}.viewPort.min = viewPort.min(1:cMaxNew); 
            obj.I{obj.Id}.viewPort.max = viewPort.max(1:cMaxNew);
            obj.I{obj.Id}.viewPort.gamma = viewPort.gamma(1:cMaxNew);
        else
            obj.I{obj.Id}.viewPort.min = repmat(viewPort.min, [cMaxNew, 1]);  
            obj.I{obj.Id}.viewPort.max = repmat(viewPort.max, [cMaxNew, 1]);  
            obj.I{obj.Id}.viewPort.gamma = repmat(viewPort.gamma, [cMaxNew, 1]);  
        end
        
        eventdata = ToggleEventData(obj.Id);
        notify(obj, 'newDatasetLite', eventdata);
        
        obj.I{obj.Id}.updateImgInfo(log_text);
        clear imgOut;
        if showWaitbar; delete(wb); end
        notify(obj, 'plotImage');
        return;
end

if showWaitbar; wb = waitbar(0,sprintf('Transposing the image\nPlease wait...'),...
    'Name', sprintf('Transpose dataset [%s]', mode), 'WindowStyle', 'modal'); end

% transpose the image layer
for t=1:tMax
    img = cell2mat(obj.getData3D('image', t, 4, 0, options));   % get z-stack (image)
    imgOut(:,:,:,:,t) = transposeme(img, mode);
    if showWaitbar; waitbar(t/tMax, wb); end
end
obj.setData4D('image', imgOut, 4, 0, options);   % set dataset (image) back
clear imgOut;

% transpose other layers
if obj.I{obj.Id}.modelType == 63 && obj.I{obj.Id}.enableSelection == 1
    if showWaitbar; waitbar(0.5, wb, sprintf('Transposing other layers\nPlease wait...')); end
    img = obj.I{obj.Id}.model{1};  % get everything
    obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        obj.setData3D('everything', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
        if showWaitbar; waitbar(t/tMax, wb); end
    end
elseif  obj.I{obj.Id}.enableSelection == 1
    % transpose selection layer
    if showWaitbar; waitbar(0.25, wb, sprintf('Transposing the selection layer\nPlease wait...')); end
    img = obj.I{obj.Id}.selection{1};  % get selection
    obj.I{obj.Id}.selection{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        obj.setData3D('selection', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
        if showWaitbar; waitbar(t/tMax, wb); end
    end
    
    % transpose mask
    if obj.I{obj.Id}.maskExist
        if showWaitbar; waitbar(0.5, wb, sprintf('Transposing the mask layer\nPlease wait...')); end
        img = obj.I{obj.Id}.maskImg{1};  % get mask
        obj.I{obj.Id}.maskImg{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            obj.setData3D('mask', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
            if showWaitbar; waitbar(t/tMax, wb); end
        end
    end
    
    % transpose model
    if obj.I{obj.Id}.modelExist
        if showWaitbar; waitbar(0.75, wb, sprintf('Transposing the model layer\nPlease wait...')); end
        img = obj.I{obj.Id}.model{1};  % get model
        obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            obj.setData3D('model', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
            if showWaitbar; waitbar(t/tMax, wb); end
        end
    end
end
if showWaitbar; waitbar(1, wb, sprintf('Finishing...')); end
clear img;

% % update the bounding box
bb = obj.I{obj.Id}.getBoundingBox();    % get current bounding box

switch mode
    case 'Transpose XY -> ZX'
        % swap pixSize.y and pixSize.z
        dummy = obj.I{obj.Id}.pixSize.y;
        obj.I{obj.Id}.pixSize.y = obj.I{obj.Id}.pixSize.z;
        obj.I{obj.Id}.pixSize.z = dummy;
        % update the bounding box
        dummy = bb(3:4);
        bb(3:4) = bb(5:6);
        bb(5:6) = dummy;
    case 'Transpose XY -> ZY'
        % swap pixSize.x and pixSize.z
        dummy = obj.I{obj.Id}.pixSize.x;
        obj.I{obj.Id}.pixSize.x = obj.I{obj.Id}.pixSize.z;
        obj.I{obj.Id}.pixSize.z = dummy;
        % update the bounding box
        dummy = bb(1:2);
        bb(1:2) = bb(5:6);
        bb(5:6) = dummy;
    case 'Transpose ZX -> ZY'
        % swap pixSize.y and pixSize.x
        dummy = obj.I{obj.Id}.pixSize.x;
        obj.I{obj.Id}.pixSize.x = obj.I{obj.Id}.pixSize.y;
        obj.I{obj.Id}.pixSize.y = dummy;
        % update the bounding box
        dummy = bb(1:2);
        bb(1:2) = bb(3:4);
        bb(3:4) = dummy;
end
obj.I{obj.Id}.updateBoundingBox(bb);  % update bounding box

log_text = ['Transpose: mode=' mode];
obj.I{obj.Id}.updateImgInfo(log_text);
if showWaitbar; delete(wb); end
toc;

notify(obj, 'newDatasetLite');  % notify newDataset with the index of the dataset
eventdata = ToggleEventData(1);
notify(obj, 'plotImage', eventdata);
end

function img = transposeme(img, mode)
% transpose function
%     - ''Transpose XY -> ZX'' -> transpose so that XY dimension becomes ZX
%     - ''Transpose XY -> ZY'' -> transpose so that XY dimension becomes ZY
%     - ''Transpose ZX -> ZY'' -> transpose so that ZX dimension becomes ZY

if ndims(img) == 4  % for image
    switch mode
        case 'Transpose XY -> ZX'
            img = permute(img,[4, 2, 3, 1]);
        case 'Transpose XY -> ZY'
            img = permute(img,[1, 4, 3, 2]);
        case 'Transpose ZX -> ZY'
            img = permute(img,[2, 1, 3, 4]);
    end
else     % for other layers
    switch mode
        case 'Transpose XY -> ZX'
            img = permute(img,[3, 2, 1]);
        case 'Transpose XY -> ZY'
            img = permute(img,[1, 3, 2]);
        case 'Transpose ZX -> ZY'
            img = permute(img,[2, 1, 3]);
    end
end
end
