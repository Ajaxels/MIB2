function transposeDataset(obj, mode)
% function transposeDataset(obj, mode)
% Transpose dataset physically between dimensions
%
% Parameters:
% mode: -> a string that defines the transpose dimension
%     - ''xy2zx'' -> transpose so that XY dimension becomes ZX
%     - ''xy2zy'' -> transpose so that XY dimension becomes ZY
%     - ''zx2zy'' -> transpose so that ZX dimension becomes ZY
%     - ''z2t'' -> transpose so that Z-dimension becomes T-dimension
%
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

options.blockModeSwitch = 0;    % overwrite blockmode switch
tic
[yMax, xMax, cMax, zMax, tMax] = obj.I{obj.Id}.getDatasetDimensions('image', 4, NaN, options);
cMax = numel(cMax);
switch mode
    case 'xy2zx'
        imgOut = zeros([zMax, xMax, cMax, yMax, tMax], class(obj.I{obj.Id}.img{1})); %#ok<ZEROLIKE>
        outputDims = [zMax, xMax, cMax, yMax, tMax];
    case 'xy2zy'
        imgOut = zeros([yMax, zMax, cMax, xMax tMax], class(obj.I{obj.Id}.img{1})); %#ok<ZEROLIKE>
        outputDims = [yMax, zMax, cMax, xMax tMax];
    case 'zx2zy'
        imgOut = zeros([xMax, yMax, cMax, zMax, tMax], class(obj.I{obj.Id}.img{1})); %#ok<ZEROLIKE>
        outputDims = [xMax, yMax, cMax, zMax, tMax];
    case 'z2t'
        obj.transposeZ2T();
        log_text = 'Rotate: mode=Z->T';
        obj.I{obj.Id}.updateImgInfo(log_text);
        notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
        eventdata = ToggleEventData(1);
        notify(obj, 'plotImage', eventdata);
        return;
end
wb = waitbar(0,sprintf('Transposing the image\nPlease wait...'),...
    'Name', sprintf('Transpose dataset [%s]', mode), 'WindowStyle', 'modal');

% transpose the image layer
for t=1:tMax
    img = cell2mat(obj.getData3D('image', t, 4, 0, options));   % get z-stack (image)
    imgOut(:,:,:,:,t) = transposeme(img, mode);
    waitbar(t/tMax, wb)
end
obj.setData4D('image', imgOut, 4, 0, options);   % set dataset (image) back
clear imgOut;

% transpose other layers
if obj.I{obj.Id}.modelType == 63 && obj.preferences.disableSelection == 0
    waitbar(0.5, wb, sprintf('Transposing other layers\nPlease wait...'));
    img = obj.I{obj.Id}.model{1};  % get everything
    obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        obj.setData3D('everything', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
        waitbar(t/tMax, wb);
    end
elseif  obj.preferences.disableSelection == 0
    % transpose selection layer
    waitbar(0.25, wb, sprintf('Transposing the selection layer\nPlease wait...'));
    img = obj.I{obj.Id}.selection{1};  % get selection
    obj.I{obj.Id}.selection{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        obj.setData3D('selection', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
        waitbar(t/tMax, wb);
    end
    
    % transpose mask
    if obj.I{obj.Id}.maskExist
        waitbar(0.5, wb, sprintf('Transposing the mask layer\nPlease wait...'));
        img = obj.I{obj.Id}.maskImg{1};  % get mask
        obj.I{obj.Id}.maskImg{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            obj.setData3D('mask', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
            waitbar(t/tMax, wb);
        end
    end
    
    % transpose model
    if obj.I{obj.Id}.modelExist
        waitbar(0.75, wb, sprintf('Transposing the model layer\nPlease wait...'));
        img = obj.I{obj.Id}.model{1};  % get model
        obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            obj.setData3D('model', transposeme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
            waitbar(t/tMax, wb);
        end
    end
end
waitbar(1, wb, sprintf('Finishing...'));
clear img;

% % update the bounding box
bb = obj.I{obj.Id}.getBoundingBox();    % get current bounding box

switch mode
    case 'xy2zx'
        % swap pixSize.y and pixSize.z
        dummy = obj.I{obj.Id}.pixSize.y;
        obj.I{obj.Id}.pixSize.y = obj.I{obj.Id}.pixSize.z;
        obj.I{obj.Id}.pixSize.z = dummy;
        % update the bounding box
        dummy = bb(3:4);
        bb(3:4) = bb(5:6);
        bb(5:6) = dummy;
    case 'xy2zy'
        % swap pixSize.x and pixSize.z
        dummy = obj.I{obj.Id}.pixSize.x;
        obj.I{obj.Id}.pixSize.x = obj.I{obj.Id}.pixSize.z;
        obj.I{obj.Id}.pixSize.z = dummy;
        % update the bounding box
        dummy = bb(1:2);
        bb(1:2) = bb(5:6);
        bb(5:6) = dummy;
    case 'zx2zy'
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
delete(wb);
toc;

notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
eventdata = ToggleEventData(1);
notify(obj, 'plotImage', eventdata);
end

function img = transposeme(img, mode)
% transpose function
%     - ''xy2zx'' -> transpose so that XY dimension becomes ZX
%     - ''xy2zy'' -> transpose so that XY dimension becomes ZY
%     - ''zx2zy'' -> transpose so that ZX dimension becomes ZY

if ndims(img) == 4  % for image
    switch mode
        case 'xy2zx'
            img = permute(img,[4, 2, 3, 1]);
        case 'xy2zy'
            img = permute(img,[1, 4, 3, 2]);
        case 'zx2zy'
            img = permute(img,[2, 1, 3, 4]);
    end
else     % for other layers
    switch mode
        case 'xy2zx'
            img = permute(img,[3, 2, 1]);
        case 'xy2zy'
            img = permute(img,[1, 3, 2]);
        case 'zx2zy'
            img = permute(img,[2, 1, 3]);
    end
end
end
