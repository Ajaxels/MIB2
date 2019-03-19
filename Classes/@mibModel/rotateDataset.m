function rotateDataset(obj, mode, showWaitbar)
% function rotateDataset(obj, mode, showWaitbar)
% Rotate dataset in 90 or -90 degrees
% 
% Rotate dataset in 90 or -90 degrees
%
% Parameters:
% mode: -> a string that defines the rotation
%     - ''Rotate 90 degrees'' -> rotate dataset to 90 degrees clock-wise
%     - ''Rotate -90 degrees'' -> rotate dataset to 90 degrees anti clock-wise
% showWaitbar: logical, show or not the waitbar
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

if nargin < 3; showWaitbar = true; end

options.blockModeSwitch = 0;    % overwrite blockmode switch
if showWaitbar; wb = waitbar(0,sprintf('Rotating image\nPlease wait...'), 'Name', 'Rotate dataset', 'WindowStyle', 'modal'); end

% rotate image
[hMax, wMax, cMax, zMax, tMax] = obj.I{obj.Id}.getDatasetDimensions('image', 4, 0, options);
cMax = numel(cMax);

imgOut = zeros([wMax, hMax, cMax, zMax, tMax], obj.I{obj.Id}.meta('imgClass')); %#ok<ZEROLIKE>
% rotate image
for t=1:tMax
    img = cell2mat(obj.getData3D('image', t, 4, 0, options));   % get z-stack (image)
    imgOut(:,:,:,:,t) = rotateme(img, mode);
    if showWaitbar; waitbar(t/tMax, wb); end
end
obj.setData4D('image', imgOut, 4, 0, options);   % set dataset (image) back
clear imgOut;

% rotate other layers
if obj.I{obj.Id}.modelType == 63 && obj.I{obj.Id}.disableSelection == 0
    if showWaitbar; waitbar(0.5, wb, sprintf('Rotating other layers\nPlease wait...')); end
    img = obj.I{obj.Id}.model{1};  % get everything
    obj.I{obj.Id}.model{1} = zeros([wMax, hMax, zMax, tMax], 'uint8');
    for t=1:tMax
        obj.setData3D('everything', rotateme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
        if showWaitbar; waitbar(t/tMax, wb); end
    end
elseif  obj.I{obj.Id}.disableSelection == 0
    % Rotate selection layer
    if showWaitbar; waitbar(0.25, wb, sprintf('Rotating the selection layer\nPlease wait...')); end
    img = obj.I{obj.Id}.selection{1};  % get selection
    obj.I{obj.Id}.selection{1} = zeros([wMax, hMax, zMax, tMax], 'uint8');
    for t=1:tMax
        obj.setData3D('selection', rotateme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
        if showWaitbar; waitbar(t/tMax, wb); end
    end
    
    % Rotate mask
    if obj.I{obj.Id}.maskExist
        if showWaitbar; waitbar(0.5, wb, sprintf('Rotating the mask layer\nPlease wait...')); end
        img = obj.I{obj.Id}.maskImg{1};  % get mask
        obj.I{obj.Id}.maskImg = zeros([wMax, hMax, zMax, tMax], 'uint8');
        for t=1:tMax
            obj.setData3D('mask', rotateme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
            if showWaitbar; waitbar(t/tMax, wb); end
        end
    end
    
    % Rotate model
    if obj.I{obj.Id}.modelExist
        if showWaitbar; waitbar(0.75, wb, sprintf('Rotating the model layer\nPlease wait...')); end
        img = obj.I{obj.Id}.model{1};  % get model
        obj.I{obj.Id}.model{1} = zeros([wMax, hMax, zMax, tMax], 'uint8');
        for t=1:tMax
            obj.setData3D('model', rotateme(img(:,:,:,t), mode), t, 4, NaN, options);   % set dataset (everything) back
            if showWaitbar; waitbar(t/tMax, wb); end
        end
    end
end
if showWaitbar; waitbar(1, wb, sprintf('Finishing...')); end
clear img;

% swap pixSize.x and pixSize.y
dummy = obj.I{obj.Id}.pixSize.x;
obj.I{obj.Id}.pixSize.x = obj.I{obj.Id}.pixSize.y;
obj.I{obj.Id}.pixSize.y = dummy;

% update the bounding box
bb = obj.I{obj.Id}.getBoundingBox();    % get current bounding box
dummy = bb(1:2);
bb(1:2) = bb(3:4);
bb(3:4) = dummy;
obj.I{obj.Id}.updateBoundingBox(bb);  % update bounding box

log_text = ['Rotate: mode=' mode];
obj.I{obj.Id}.updateImgInfo(log_text);
if showWaitbar; delete(wb); end
notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
eventdata = ToggleEventData(1);
notify(obj, 'plotImage', eventdata);
end

function imgOut = rotateme(img, mode)
% rotate function
if ndims(img) == 4  % for image
    imgOut = zeros([size(img,2), size(img,1), size(img,3), size(img,4)], class(img)); %#ok<ZEROLIKE>
    colorNo = size(img,3);
    for slice = 1:size(img, 4)
        if strcmp(mode, 'Rotate 90 degrees')
            for color = 1:colorNo
                imgOut(:,:,color,slice) = rot90(img(:,:,color,slice), 3);
            end
        elseif strcmp(mode, 'Rotate -90 degrees')
            for color = 1:colorNo
                imgOut(:,:,color,slice) = rot90(img(:,:,color,slice));
            end
        end
    end
else    % for other layers
    imgOut = zeros([size(img,2), size(img,1), size(img,3)], class(img)); %#ok<ZEROLIKE>
    for slice = 1:size(img, 3)
        if strcmp(mode, 'Rotate 90 degrees')
            imgOut(:,:,slice) = rot90(img(:,:,slice), 3);
        elseif strcmp(mode, 'Rotate -90 degrees')
            imgOut(:,:,slice) = rot90(img(:,:,slice));
        end
    end
end
end