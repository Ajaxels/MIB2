function mibSegmentationBlackWhiteThreshold(obj, parameter, BatchOptIn)
% function mibSegmentationBlackWhiteThreshold(obj, parameter, BatchOptIn)
% Perform black and white thresholding for @em BW @em Threshold tool of the 'Segmentation
% panel'
%
% Parameters:
% parameter: a tag of the calling object
% - ''mibSegmLowEdit'' - callback after enter a new value to the obj.mibView.handles.mibSegmLowEdit editbox
% - ''mibSegmHighEdit'' - callback after enter a new value to the obj.mibView.handles.mibSegmHighEdit editbox
% - ''mibSegmLowSlider'' - callback after interacting with the obj.mibView.handles.mibSegmLowSlider slider
% - ''mibSegmHighSlider'' - callback after interacting with the obj.mibView.handles.mibSegmHighSlider slider
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Mode - Apply thresholding for the current slice (2D), current stack (3D) or the whole dataset(4D)
% @li .MinValue - Minimum intensity or Sensitivity value for thresholding
% @li .MaxValue - Maximum intensity or Width value for thresholding
% @li .ColorChannel - Color channel to be used for thresholding
% @li .FixSelectionToMask - Apply thresholding only to the masked area
% @li .FixSelectionToMaterial - Apply thresholding only to the area of the selected material; use Modify checkboxes to update the selected material
% @li .Adaptive - Enable the adaptive thresholding; use MinValue to specifty Sensitivity and MaxValue to specify Width
% @li .AdaptiveInvert - Adaptive only] invert dataset before adaptive thresholding
% @li .AdaptiveForegroundPolarity - [Adaptive only] determine which pixels are considered foreground pixels
% @li .Target - Destination layer for the thresholding
% @li .showWaitbar - Show or not the progress bar during execution
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
% 03.10.2019 updated for the batch mode

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.id = obj.mibModel.Id;   % optional, id
if obj.mibModel.I{BatchOpt.id}.selectedColorChannel == 0    % do check and correction of the selected color channel
    if obj.mibModel.I{BatchOpt.id}.colors == 1
        obj.mibModel.I{BatchOpt.id}.selectedColorChannel = 1;
    else
        errordlg(sprintf('!!! Error !!!\n\nPlease select the active the color channel for the thresholding!\nSelection panel -> Color channel:'), ...
            'Wrong color channel');
        notify(obj.mibModel, 'stopProtocol');
        return;
    end
end

BatchOpt.Mode = {'2D, Slice'};     % '2D, Slice', '3D, Stack', '4D, Dataset'
if obj.mibView.handles.mibSegmBWthres3D.Value == 1; BatchOpt.Mode = {'3D, Stack'}; end
if obj.mibView.handles.mibSegmBWthres4D.Value == 1; BatchOpt.Mode = {'4D, Dataset'}; end
BatchOpt.Mode{2} = {'2D, Slice','3D, Stack','4D, Dataset'};
BatchOpt.ColorChannel{2} = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{BatchOpt.id}.colors, 'UniformOutput', false);
BatchOpt.ColorChannel{1} = BatchOpt.ColorChannel{2}{obj.mibModel.I{BatchOpt.id}.selectedColorChannel};
BatchOpt.MinValue = num2str(round(obj.mibView.handles.mibSegmLowSlider.Value));
BatchOpt.MaxValue = num2str(round(obj.mibView.handles.mibSegmHighSlider.Value));
BatchOpt.FixSelectionToMask = logical(obj.mibModel.I{BatchOpt.id}.fixSelectionToMask);  
BatchOpt.FixSelectionToMaterial = logical(obj.mibModel.I{BatchOpt.id}.fixSelectionToMaterial);  
BatchOpt.Adaptive = logical(obj.mibView.handles.mibSegmThresPanelAdaptiveCheck.Value);    % use or not the adaptive mode
BatchOpt.AdaptiveInvert = logical(obj.mibView.handles.mibSegmThresPanelAdaptiveInvert.Value);    
BatchOpt.AdaptiveForegroundPolarity = obj.mibView.handles.mibSegmThresPanelAdaptivePopup.String(obj.mibView.handles.mibSegmThresPanelAdaptivePopup.Value);
BatchOpt.AdaptiveForegroundPolarity{2} = obj.mibView.handles.mibSegmThresPanelAdaptivePopup.String;
BatchOpt.Target = {'selection'};
BatchOpt.Target{2} = {'selection', 'mask'};
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Black and white thresholding';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Mode = sprintf('Apply thresholding for the current slice (2D), current stack (3D) or the whole dataset(4D)');
BatchOpt.mibBatchTooltip.MinValue = 'Minimum intensity or Sensitivity value for thresholding';
BatchOpt.mibBatchTooltip.MaxValue = 'Maximum intensity or Width value for thresholding';
BatchOpt.mibBatchTooltip.ColorChannel = 'Color channel to be used for thresholding';
BatchOpt.mibBatchTooltip.FixSelectionToMask = 'Apply thresholding only to the masked area';
BatchOpt.mibBatchTooltip.FixSelectionToMaterial = 'Apply thresholding only to the area of the selected material; use Modify checkboxes to update the selected material';
BatchOpt.mibBatchTooltip.Adaptive = 'Enable the adaptive thresholding; use MinValue to specifty Sensitivity and MaxValue to specify Width';
BatchOpt.mibBatchTooltip.AdaptiveInvert = '[Adaptive only] invert dataset before adaptive thresholding';
BatchOpt.mibBatchTooltip.AdaptiveForegroundPolarity = '[Adaptive only] determine which pixels are considered foreground pixels';
BatchOpt.mibBatchTooltip.Target = 'Destination layer for the thresholding';
BatchOpt.mibBatchTooltip.showWaitbar = 'Show or not the progress bar during execution';

% do black and white thresholding for segmentation
maxVal = obj.mibModel.I{BatchOpt.id}.meta('MaxInt');

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
        backgroundColor = obj.mibView.handles.mibSegmThresPanelLowText.BackgroundColor;
    end
else
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
    BatchOpt.MinValue = num2str(round(obj.mibView.handles.mibSegmLowSlider.Value));
    BatchOpt.MaxValue = num2str(round(obj.mibView.handles.mibSegmHighSlider.Value));    
end

% check for the virtual stacking mode and return
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'black-and-white thresholding is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

obj.mibView.handles.mibSegmLowSlider.BackgroundColor = [1 0 0];
drawnow;

val1 = str2double(BatchOpt.MinValue);
val2 = str2double(BatchOpt.MaxValue);
model_id = obj.mibModel.I{BatchOpt.id}.getSelectedMaterialIndex();  % get selected contour;
color_channel = find(ismember(BatchOpt.ColorChannel{2},BatchOpt.ColorChannel{1}));

if BatchOpt.Adaptive
    val1 = val1/double(maxVal);
    height = obj.mibModel.I{BatchOpt.id}.getDatasetDimensions('image');
    val2 = 2*ceil(height*val2/double(maxVal))+1;
    polarity = 'dark';  % polarity for the adaptive thresholding
    if strcmp(BatchOpt.AdaptiveForegroundPolarity{1}, 'white-on-black'); polarity = 'bright'; end
end
if model_id < 0 && BatchOpt.FixSelectionToMaterial == 1;  BatchOpt.FixSelectionToMask = 1; end

getDataOptions.id = BatchOpt.id;
if strcmp(BatchOpt.Mode{1}, '3D, Stack') || strcmp(BatchOpt.Mode{1}, '4D, Dataset') % do segmentation for the whole dataset
    if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Black and white thresholding'); end
    if strcmp(BatchOpt.Mode{1}, '4D, Dataset')
        t1 = 1;
        t2 = obj.mibModel.I{BatchOpt.id}.time;
    else
        slices = obj.mibModel.I{BatchOpt.id}.slices;
        t1 = slices{5}(1);
        t2 = slices{5}(1);
        obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 1, getDataOptions);
    end
    
    orientation = obj.mibModel.I{BatchOpt.id}.orientation;
    [axesX, axesY] = obj.mibModel.getAxesLimits(BatchOpt.id);
    
    for t=t1:t2
        img = squeeze(cell2mat(obj.mibModel.getData3D('image', t, 4, color_channel, getDataOptions)));  % get dataset
        
        if BatchOpt.FixSelectionToMask == 1 
            selection = zeros(size(img), 'uint8');  % generate new selection
            
            mask = cell2mat(obj.mibModel.getData3D('mask', t, 4, NaN, getDataOptions));    % get mask
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
            img = img(indeces(1,1):indeces(1,2), indeces(2,1):indeces(2,2), indeces(3,1):indeces(3,2));
            % crop the mask
            mask = mask(indeces(1,1):indeces(1,2), indeces(2,1):indeces(2,2), indeces(3,1):indeces(3,2));
            
            % generate cropped selection
            selection2 = zeros(size(img), 'uint8') + 1;
            if BatchOpt.Adaptive
                for sliceId = 1:size(img,3)
                    %selection2(:,:,sliceId) = 1-uint8(imbinarize(img(:,:,sliceId), 'adaptive','Sensitivity', val1, 'ForegroundPolarity', polarity));
                    T = adaptthresh(img(:,:,sliceId), val1, 'ForegroundPolarity', polarity, 'NeighborhoodSize', val2);
                    selection2(:,:,sliceId) = uint8(imbinarize(img(:,:,sliceId), T));
                    if BatchOpt.AdaptiveInvert
                        selection2(:,:,sliceId) = 1 - selection2(:,:,sliceId);
                    end
                end
            else
                selection2(img < val1 | img > val2) = 0;
            end
            
            selection2 = selection2 & mask;
            
            if BatchOpt.FixSelectionToMaterial && model_id >= 0
                if obj.mibModel.I{BatchOpt.id}.blockModeSwitch
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
                getDataOptions.x = [indeces(2,1), indeces(2,2)]+shiftX;
                getDataOptions.y = [indeces(1,1), indeces(1,2)]+shiftY;
                getDataOptions.z = [indeces(3,1), indeces(3,2)]+shiftZ;
                model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, model_id, getDataOptions));
                selection2(model ~= 1) = 0;
            end
            selection(indeces(1,1):indeces(1,2),indeces(2,1):indeces(2,2),indeces(3,1):indeces(3,2)) = selection2;
        else
            selection = zeros(size(img),'uint8') + 1;  % generate new selection
            if BatchOpt.Adaptive
                for sliceId=1:size(img,3)
                    %selection(:,:,sliceId) = uint8(imbinarize(img(:,:,sliceId), 'adaptive','Sensitivity', val1, 'ForegroundPolarity', polarity));
                    T = adaptthresh(img(:,:,sliceId), val1, 'ForegroundPolarity', polarity, 'NeighborhoodSize', val2);
                    selection(:,:,sliceId) = uint8(imbinarize(img(:,:,sliceId), T));
                    if BatchOpt.AdaptiveInvert
                        selection(:,:,sliceId) = 1-selection(:,:,sliceId);
                    end
                end
            else
                selection(img < val1 | img > val2) = 0;
            end
            
            if BatchOpt.FixSelectionToMaterial && model_id >= 0
                model = cell2mat(obj.mibModel.getData3D('model', t, 4, model_id, getDataOptions));
                selection = selection & model;
            end
        end
        obj.mibModel.setData3D(BatchOpt.Target{1}, {selection}, t, 4, NaN, getDataOptions);
        if BatchOpt.showWaitbar; waitbar(t/(t2-t1), wb); end
    end
    if BatchOpt.showWaitbar; delete(wb); end
else    % do segmentation for the current slice only
    obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 0, getDataOptions);
    img = squeeze(cell2mat(obj.mibModel.getData2D('image', NaN, NaN, color_channel, getDataOptions)));
    if BatchOpt.Adaptive
        T = adaptthresh(img, val1, 'ForegroundPolarity', polarity, 'NeighborhoodSize', val2);
        selection = uint8(imbinarize(img, T));
        %selection = uint8(imbinarize(img, 'adaptive','Sensitivity', val1, 'ForegroundPolarity', polarity));
        if BatchOpt.AdaptiveInvert
            selection = 1 - selection;
        end
    else
        selection = zeros(size(img),'uint8') + 1;  % generate new selection
        selection(img<val1 | img>val2) = 0;
    end
    
    if BatchOpt.FixSelectionToMask == 1 
        mask = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, NaN, getDataOptions));
        selection(mask ~= 1) = 0;
    end
    if BatchOpt.FixSelectionToMaterial && model_id >= 0
        model = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, NaN, getDataOptions));
        selection(model ~= model_id) = 0;
    end
    obj.mibModel.setData2D(BatchOpt.Target{1}, {selection}, NaN, NaN, NaN, getDataOptions);
end
obj.mibView.handles.mibSegmLowSlider.BackgroundColor = backgroundColor;

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

end
