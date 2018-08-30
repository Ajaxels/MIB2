function addFrame(obj)
% function addFrame(obj)
% Add a frame around the dataset
%
% Parameters:
%
% Return values:
%

% Copyright (C) 13.03.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

global mibPath;
maxVal = num2str(intmax(class(obj.I{obj.Id}.img{1}(1))));
prompts = {'Frame width, px:'; 'Frame height, px'; sprintf('Intensity pad value (0 - %s):', maxVal); 'Method:'; 'Direction:'};
defAns = {'10'; '10'; maxVal; {'use the pad value', 'replicate', 'circular', 'symmetric', 1}; {'both', 'pre', 'post', 1}};
dlgTitle = 'Add frame';
options.PromptLines = [1, 1, 2, 1, 1];   % [optional] number of lines for widget titles
%options.WindowWidth = 1.0;    % [optional] make window x1.2 times wider
[answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
if isempty(answer); return; end
padval = str2double(answer{3});
direction = answer{5};
method = answer{4};
options.blockModeSwitch = 0;    % overwrite blockmode switch
tic
[yMax, xMax, cMax, zMax, tMax] = obj.I{obj.Id}.getDatasetDimensions('image', 4, NaN, options);
cMax = numel(cMax);

extW = str2double(answer{1});
extH = str2double(answer{2});
if isnan(extW) || isnan(extH) || isnan(padval)
    errordlg(sprintf('!!! Error !!!\n\nWrong width, height or pad intensity value parameter!\nThese parameters should be numbers above 0, or 0')); 
    return;
end
if extW < 0 || extH < 0 || padval < 0
    errordlg(sprintf('!!! Error !!!\n\nWrong width, height or pad intensity value parameter!\nThese parameters should not be negative')); 
    return;
end

if selIndex(5) == 1     % both
    outputDims = [yMax+extH*2, xMax+extW*2, cMax, zMax, tMax];
else    % pre or post
    outputDims = [yMax+extH, xMax+extW, cMax, zMax, tMax];
end
imgOut = zeros(outputDims, class(obj.I{obj.Id}.img{1}(1))); 

% switch mode
%     case 'xy2zx'
%         imgOut = zeros([zMax, xMax, cMax, yMax, tMax], obj.meta('imgClass')); %#ok<ZEROLIKE>
%         outputDims = [zMax, xMax, cMax, yMax, tMax];
%     case 'xy2zy'
%         imgOut = zeros([yMax, zMax, cMax, xMax tMax], obj.meta('imgClass')); %#ok<ZEROLIKE>
%         outputDims = [yMax, zMax, cMax, xMax tMax];
%     case 'zx2zy'
%         imgOut = zeros([xMax, yMax, cMax, zMax, tMax], obj.meta('imgClass')); %#ok<ZEROLIKE>
%         outputDims = [xMax, yMax, cMax, zMax, tMax];
%     case 'z2t'
%         obj.transposeZ2T();
%         log_text = 'Rotate: mode=Z->T';
%         obj.I{obj.Id}.updateImgInfo(log_text);
%         notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
%         eventdata = ToggleEventData(1);
%         notify(obj, 'plotImage', eventdata);
%         return;
% end
wb = waitbar(0,sprintf('Adding a frame to the image\nPlease wait...'),...
    'Name', 'Add frame', 'WindowStyle', 'modal');

% transpose the image layer
for t=1:tMax
    img = cell2mat(obj.getData3D('image', t, 4, 0, options));   % get z-stack (image)
    if selIndex(4) == 1     % use the pad value
        imgOut(:,:,:,:,t) = padarray(img, [extH, extW], padval, direction);
    else
        imgOut(:,:,:,:,t) = padarray(img, [extH, extW], method, direction);
    end
    waitbar(t/tMax, wb)
end
obj.setData4D('image', imgOut, 4, 0, options);   % set dataset (image) back
clear imgOut;

% transpose other layers
if obj.I{obj.Id}.modelType == 63 && obj.I{obj.Id}.disableSelection == 0
    waitbar(0.5, wb, sprintf('Adding a frame to other layers\nPlease wait...'));
    img = obj.I{obj.Id}.model{1};  % get everything
    obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        if selIndex(4) == 1     % use the pad value
            imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
        else
            imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
        end
        obj.setData3D('everything', imgOut, t, 4, NaN, options);   % set dataset (everything) back
        waitbar(t/tMax, wb);
    end
elseif obj.I{obj.Id}.disableSelection == 0
    % transpose selection layer
    waitbar(0.25, wb, sprintf('Adding a frame to the selection layer\nPlease wait...'));
    img = obj.I{obj.Id}.selection{1};  % get selection
    obj.I{obj.Id}.selection{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
    for t=1:tMax
        if selIndex(4) == 1     % use the pad value
            imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
        else
            imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
        end
        obj.setData3D('selection', imgOut, t, 4, NaN, options);   % set dataset (everything) back
        waitbar(t/tMax, wb);
    end
    
    % transpose mask
    if obj.I{obj.Id}.maskExist
        waitbar(0.5, wb, sprintf('Adding a frame to the mask layer\nPlease wait...'));
        img = obj.I{obj.Id}.maskImg{1};  % get mask
        obj.I{obj.Id}.maskImg{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            if selIndex(4) == 1     % use the pad value
                imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
            else
                imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
            end
            obj.setData3D('mask', imgOut, t, 4, NaN, options);   % set dataset (everything) back
            waitbar(t/tMax, wb);
        end
    end
    
    % transpose model
    if obj.I{obj.Id}.modelExist
        waitbar(0.75, wb, sprintf('Adding a frame to the model layer\nPlease wait...'));
        img = obj.I{obj.Id}.model{1};  % get model
        obj.I{obj.Id}.model{1} = zeros([outputDims(1), outputDims(2), outputDims(4), outputDims(5)], 'uint8');
        for t=1:tMax
            if selIndex(4) == 1     % use the pad value
                imgOut = padarray(img(:,:,:,t), [extH, extW], 0, direction);
            else
                imgOut = padarray(img(:,:,:,t), [extH, extW], method, direction);
            end
            obj.setData3D('model', imgOut, t, 4, NaN, options);   % set dataset (everything) back
            waitbar(t/tMax, wb);
        end
    end
end
waitbar(1, wb, sprintf('Finishing...'));
clear img;

% % update the bounding box
bb = obj.I{obj.Id}.getBoundingBox();    % get current bounding box
if selIndex(5) == 1     % both
    bb(1) = bb(1)-extW*obj.I{obj.Id}.pixSize.x;
    bb(2) = bb(2)+extW*obj.I{obj.Id}.pixSize.x;
    bb(3) = bb(3)-extW*obj.I{obj.Id}.pixSize.y;
    bb(4) = bb(4)+extW*obj.I{obj.Id}.pixSize.y;
elseif selIndex(5) == 2     % pre
    bb(1) = bb(1)-extW*obj.I{obj.Id}.pixSize.x;
    bb(3) = bb(3)-extW*obj.I{obj.Id}.pixSize.y;
elseif selIndex(5) == 3     % post    
    bb(2) = bb(2)+extW*obj.I{obj.Id}.pixSize.x;
    bb(4) = bb(4)+extW*obj.I{obj.Id}.pixSize.y;
end
obj.I{obj.Id}.updateBoundingBox(bb);  % update bounding box

if selIndex(4) == 1     % use the pad value
    log_text = sprintf('Add frame: padValue=%d, direction=%s', padval, direction);
else
    log_text = sprintf('Add frame: method=%s, direction=%s', method, direction);
end
obj.I{obj.Id}.updateImgInfo(log_text);
delete(wb);
toc;

notify(obj, 'newDataset');  % notify newDataset with the index of the dataset
eventdata = ToggleEventData(1);
notify(obj, 'plotImage', eventdata);
end
