function mibSegmentationBlackWhiteThreshold(obj, parameter)
% function mibSegmentationBlackWhiteThreshold(obj, parameter)
% Perform black and white thresholding for @em BW @em Threshold tool of the 'Segmentation
% panel'
%
% Parameters:
% handles: structure with handles of im_browser.m
% parameter: a tag of the calling object
% - ''mibSegmLowEdit'' - callback after enter a new value to the obj.mibView.handles.mibSegmLowEdit editbox
% - ''mibSegmHighEdit'' - callback after enter a new value to the obj.mibView.handles.mibSegmHighEdit editbox
% - ''mibSegmLowSlider'' - callback after interacting with the obj.mibView.handles.mibSegmLowSlider slider
% - ''mibSegmHighSlider'' - callback after interacting with the obj.mibView.handles.mibSegmHighSlider slider
%
% Return values:
% 

% Copyright (C) 19.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

% do black and white thresholding for segmentation
maxVal = intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1}));
switch parameter
    case 'mibSegmLowEdit'
        val = round(str2double(obj.mibView.handles.mibSegmLowEdit.String));
        if val > maxVal
            val = maxVal;
            obj.mibView.handles.mibSegmLowEdit.String = num2str(val);
        end
        obj.mibView.handles.mibSegmLowSlider.Value = val;
        backgroundColor = [1 1 1];
    case 'mibSegmHighEdit'
        val = round(str2double(obj.mibView.handles.mibSegmHighEdit.String));
        if val > maxVal
            val = maxVal;
            obj.mibView.handles.mibSegmHighEdit.String = num2str(val);
        end
        obj.mibView.handles.mibSegmHighSlider.Value = val;
        backgroundColor = [1 1 1];
    case 'mibSegmLowSlider'
        val = round(obj.mibView.handles.mibSegmLowSlider.Value);
        if val > maxVal
            val = maxVal;
            obj.mibView.handles.mibSegmLowSlider.Value = val;
        end
        obj.mibView.handles.mibSegmLowEdit.String = num2str(val);
        backgroundColor = obj.mibView.handles.mibSegmThresPanelLowText.BackgroundColor;
    case 'mibSegmHighSlider'
        val = round(obj.mibView.handles.mibSegmHighSlider.Value);
        if val > maxVal
            val = maxVal;
            obj.mibView.handles.mibSegmHighSlider.Value = val;
        end
        obj.mibView.handles.mibSegmHighEdit.String = num2str(val);
        backgroundColor = obj.mibView.handles.mibSegmThresPanelLowText.BackgroundColor;
end
val1 = round(obj.mibView.handles.mibSegmLowSlider.Value);
val2 = round(obj.mibView.handles.mibSegmHighSlider.Value);

selected = obj.mibView.handles.mibSegmSelectedOnlyCheck.Value;  % do only for selected material
masked = obj.mibView.handles.mibMaskedAreaCheck.Value;     % do only for masked material
model_id = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;  % get selected contour;
adaptive = obj.mibView.handles.mibSegmThresPanelAdaptiveCheck.Value;    % use or not the adaptive mode
if adaptive
    val1 = val1/double(maxVal);
    height = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
    val2 = 2*ceil(height*val2/double(maxVal))+1;
    invert = obj.mibView.handles.mibSegmThresPanelAdaptiveInvert.Value;
end
polarity = 'dark';  % polarity for the adaptive thresholding
if obj.mibView.handles.mibSegmThresPanelAdaptivePopup.Value == 2
    polarity = 'bright';
end

if model_id < 0 && selected == 1;  masked = 1; end

color_channel = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
if color_channel == 0
    if obj.mibModel.getImageProperty('colors') > 1
        msgbox('Please select the color channel!', 'Wrong color channel!', 'error');
        return;
    else
        color_channel = 1;
    end
end

if obj.mibView.handles.mibSegmBWthres3D.Value || obj.mibView.handles.mibSegmBWthres4D.Value % do segmentation for the whole dataset
    if obj.mibView.handles.mibSegmBWthres4D.Value == 1
        t1 = 1;
        t2 = obj.mibModel.getImageProperty('time');
    else
        slices = obj.mibModel.getImageProperty('slices');
        t1 = slices{5}(1);
        t2 = slices{5}(1);
        obj.mibModel.mibDoBackup('selection', 1);
    end

    obj.mibView.handles.(parameter).BackgroundColor = [1 0 0];
    drawnow;
    
    orientation = obj.mibModel.getImageProperty('orientation');
    [axesX, axesY] = obj.mibModel.getAxesLimits();
    
    for t=t1:t2
        img = squeeze(cell2mat(obj.mibModel.getData3D('image', t, 4, color_channel)));  % get dataset
        
        if masked == 1 
            selection = zeros(size(img),'uint8');  % generate new selection
            
            mask = cell2mat(obj.mibModel.getData3D('mask', t, 4));    % get mask
            STATS = regionprops(uint8(mask), 'BoundingBox');    % calculate the bounding box for the mask
            if numel(STATS) == 0; continue; end
            
            BBox = round(STATS.BoundingBox);
            if numel(BBox) == 4
                BBox = [BBox(1) BBox(2) 1 BBox(3) BBox(4) 1];
            end
            
            indeces(1,:) = [BBox(2), BBox(2)+BBox(5)-1];
            indeces(2,:) = [BBox(1), BBox(1)+BBox(4)-1];
            indeces(3,:) = [BBox(3), BBox(3)+BBox(6)-1];
            % crop image to the masked area
            img = img(indeces(1,1):indeces(1,2),indeces(2,1):indeces(2,2),indeces(3,1):indeces(3,2));
            % crop the mask
            mask = mask(indeces(1,1):indeces(1,2),indeces(2,1):indeces(2,2),indeces(3,1):indeces(3,2));
            
            % generate cropped selection
            selection2 = zeros(size(img),'uint8')+1;
            if adaptive
                for sliceId=1:size(img,3)
                    %selection2(:,:,sliceId) = 1-uint8(imbinarize(img(:,:,sliceId), 'adaptive','Sensitivity', val1, 'ForegroundPolarity', polarity));
                    T = adaptthresh(img(:,:,sliceId), val1, 'ForegroundPolarity', polarity, 'NeighborhoodSize', val2);
                    selection2(:,:,sliceId) = uint8(imbinarize(img(:,:,sliceId), T));
                    if invert
                        selection2(:,:,sliceId) = 1-selection2(:,:,sliceId);
                    end
                end
            else
                selection2(img<val1 | img>val2) = 0;
            end
            
            selection2 = selection2 & mask;
            
            if selected && model_id >= 0
                if obj.mibModel.getImageProperty('blockModeSwitch')
                    if orientation==1     % xz
                        shiftX = max([ceil(axesY(1)) 0]);
                        shiftY = 0;
                        shiftZ = max([ceil(axesX(1)) 0]);
                    elseif orientation==2 % yz
                        shiftX = 0;
                        shiftY = max([ceil(axesY(1)) 0]);
                        shiftZ = max([ceil(axesX(1)) 0]);
                    elseif orientation==4 % yx
                        shiftX = max([ceil(axesX(1)) 0]);
                        shiftY = max([ceil(axesY(1)) 0]);
                        shiftZ = 0;
                    end
                else
                    shiftX = 0;
                    shiftY = 0;
                    shiftZ = 0;
                end
                Options.x = [indeces(2,1), indeces(2,2)]+shiftX;
                Options.y = [indeces(1,1), indeces(1,2)]+shiftY;
                Options.z = [indeces(3,1), indeces(3,2)]+shiftZ;
                model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, model_id, Options));
                selection2(model ~= 1) = 0;
            end
            selection(indeces(1,1):indeces(1,2),indeces(2,1):indeces(2,2),indeces(3,1):indeces(3,2)) = selection2;
        else
            selection = zeros(size(img),'uint8') + 1;  % generate new selection
            if adaptive
                for sliceId=1:size(img,3)
                    %selection(:,:,sliceId) = uint8(imbinarize(img(:,:,sliceId), 'adaptive','Sensitivity', val1, 'ForegroundPolarity', polarity));
                    T = adaptthresh(img(:,:,sliceId), val1, 'ForegroundPolarity', polarity, 'NeighborhoodSize', val2);
                    selection(:,:,sliceId) = uint8(imbinarize(img(:,:,sliceId), T));
                    if invert
                        selection(:,:,sliceId) = 1-selection(:,:,sliceId);
                    end
                end
            else
                selection(img < val1 | img > val2) = 0;
            end
            
            if selected && model_id >= 0
                model = cell2mat(obj.mibModel.getData3D('model', t, 4, model_id));
                selection = selection & model;
            end
        end
        obj.mibModel.setData3D('selection', {selection}, t, 4);
    end
else    % do segmentation for the current slice only
    obj.mibModel.mibDoBackup('selection', 0);
    img = squeeze(cell2mat(obj.mibModel.getData2D('image', NaN, NaN, color_channel)));
    if adaptive
        T = adaptthresh(img, val1, 'ForegroundPolarity', polarity, 'NeighborhoodSize', val2);
        selection = uint8(imbinarize(img, T));
        %selection = uint8(imbinarize(img, 'adaptive','Sensitivity', val1, 'ForegroundPolarity', polarity));
        if invert
            selection = 1-selection;
        end
    else
        selection = zeros(size(img),'uint8') + 1;  % generate new selection
        selection(img<val1 | img>val2) = 0;
    end
    
    if masked == 1 
        mask = cell2mat(obj.mibModel.getData2D('mask'));
        selection(mask ~= 1) = 0;
    end
    if selected && model_id >= 0
        model = cell2mat(obj.mibModel.getData2D('model'));
        selection(model ~= model_id) = 0;
    end
    obj.mibModel.setData2D('selection', {selection});
end
obj.mibView.handles.(parameter).BackgroundColor = backgroundColor;
end
