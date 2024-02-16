% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function dilateImage(obj, BatchOptIn)
% function dilateImage(obj, BatchOptIn)
% dilate image
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event
% Possible fields,
% @li .TargetLayer -> cell, layer to be dilated, 'selection', 'mask', 'model'
% @li .DatasetType -> cell, specify whether to dilate the current slice (2D, Slice), the stack (3D, Stack) or complete dataset (4D, Dataset)
% @li .DilateMode -> cell, type of the strel element for dilation, '2D', '3D'
% @li .StrelSize -> string, size of the strel element in pixels; one or two numbers, when two numbers entered, the second one defines Y or Z dimension for 2D and 3D strel elements respectively
% @li .Difference -> logical, obtain the difference between dilated and original image'
% @li .Adaptive -> logical, adaptive dilation
% @li .AdaptiveCoef -> [Adaptive mode] expansion coefficient for the adaptive dilation
% @li .AdaptiveColorChannel -> [Adaptive mode] color channel for adaptive dilation
% @li .AdaptiveSmoothing -> [Adaptive mode] logical, additional smoothing during adaplive dilation
% @li .MaterialIndex -> string, index of material of the model to be eroded; only for TargetLayer="model"
% @li .Use2DParallelComputing -> logical, use parallel processing to erode images in 2D'
% @li .showWaitbar -> logical, show or not the progress bar during execution

% Updates
%

if nargin < 2; BatchOptIn = struct; end

%% populate default values
BatchOpt = struct();
BatchOpt.id = obj.Id;   % optional, id
BatchOpt.TargetLayer = {'selection'};     %
BatchOpt.TargetLayer{2} = {'selection', 'mask', 'model'};     %
BatchOpt.DatasetType = {'2D, Slice'};     % '2D, Slice', '3D, Stack', '4D, Dataset'
BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
BatchOpt.DilateMode = {'2D'};
BatchOpt.DilateMode{2} = {'2D', '3D'};
BatchOpt.StrelSize = '3';
BatchOpt.MaterialIndex = '1';
BatchOpt.Difference = false;
BatchOpt.Adaptive = false;
BatchOpt.AdaptiveCoef = '2.4';
BatchOpt.AdaptiveColorChannel{2} = arrayfun(@(x) sprintf('Ch %d', x), 1:obj.I{BatchOpt.id}.colors, 'UniformOutput', false);
BatchOpt.AdaptiveColorChannel{1} = BatchOpt.AdaptiveColorChannel{2}{max([1 obj.I{BatchOpt.id}.selectedColorChannel])};
BatchOpt.AdaptiveSmoothing = false;
BatchOpt.Use2DParallelComputing = false;
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
% not used in the batch mode
if obj.I{obj.Id}.fixSelectionToMaterial
    BatchOpt.FixSelectionToMaterial = num2str(obj.I{obj.Id}.getSelectedMaterialIndex()); %  % index of material (str) or NaN
else
    BatchOpt.FixSelectionToMaterial = 'NaN';  % index of material or NaN
end
BatchOpt.FixSelectionToMask = false;    % clip by mask

BatchOpt.mibBatchSectionName = 'Panel -> Selection';
BatchOpt.mibBatchActionName = 'Dilate';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.TargetLayer = sprintf('Layer to be dilated');
BatchOpt.mibBatchTooltip.DatasetType = sprintf('Specify whether to dilate the current slice (2D, Slice), the stack (3D, Stack) or complete dataset (4D, Dataset)');
BatchOpt.mibBatchTooltip.DilateMode = sprintf('Type of the strel element for dilation');
BatchOpt.mibBatchTooltip.StrelSize = sprintf('Size of the strel element in pixels; one or two numbers, when two numbers entered, the second one defines Y or Z dimension for 2D and 3D strel elements respectively');
BatchOpt.mibBatchTooltip.MaterialIndex = sprintf('Index of material of the model to be dilated; only for TargetLayer="model"');
BatchOpt.mibBatchTooltip.Difference = sprintf('Obtain the difference between dilated and original image');
BatchOpt.mibBatchTooltip.Adaptive = sprintf('Adaptive dilation, when result depends on intensity of the original object');
BatchOpt.mibBatchTooltip.AdaptiveCoef = sprintf('[Adaptive] expansion coefficient for the adaptive dilation');
BatchOpt.mibBatchTooltip.AdaptiveColorChannel = '[Adaptive mode] color channel for adaptive dilation';
BatchOpt.mibBatchTooltip.AdaptiveSmoothing = '[Adaptive mode] additional smoothing';
BatchOpt.mibBatchTooltip.FixSelectionToMaterial = 'Fix dilation only to the specified material of the model; when NaN - disabled';
BatchOpt.mibBatchTooltip.FixSelectionToMask = 'Fix dilation to the masked area';
BatchOpt.mibBatchTooltip.Use2DParallelComputing = sprintf('Use parallel processing to dilate images in 2D');
BatchOpt.mibBatchTooltip.showWaitbar = 'Show or not the progress bar during execution';

%%
batchModeSwitch = 0;
if isstruct(BatchOptIn) == 0
    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
        % trigger syncBatch event to send BatchOptInOut to mibBatchController
        BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
        eventdata = ToggleEventData(BatchOpt);
        notify(obj, 'syncBatch', eventdata);
    else
        errordlg(sprintf('A structure as the 1st parameter is required!'));
    end
    return;
else
    % add/update BatchOpt with the provided fields in BatchOptIn
    % combine fields from input and default structures
    BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    if isfield(BatchOptIn, 'mibBatchTooltip'); batchModeSwitch = 1; end
end

%% start of the function
% do nothing if selection is disabled
if obj.I{BatchOpt.id}.enableSelection == 0; notify(obj, 'stopProtocol'); return; end
tic

% tweak when only one time point
if strcmp(BatchOpt.DatasetType{1}, '4D, Dataset') && obj.I{BatchOpt.id}.time == 1
    BatchOpt.DatasetType{1} = '3D, Stack';
end

getDataOptions.id = BatchOpt.id;
% do not make backup in the batch processing mode
if ~batchModeSwitch
    if (strcmp(BatchOpt.DilateMode{1}, '3D') && ~strcmp(BatchOpt.DatasetType{1}, '4D, Dataset') ) || strcmp(BatchOpt.DatasetType{1}, '3D, Stack')
        obj.mibDoBackup(BatchOpt.TargetLayer{1}, 1, getDataOptions);
    else
        obj.mibDoBackup(BatchOpt.TargetLayer{1}, 0, getDataOptions);
    end
end

% define parallel processing settings
% when not in the batch mode, when parpool is present use it
if ~batchModeSwitch
    p = gcp('nocreate');
    if ~isempty(p); BatchOpt.Use2DParallelComputing = true; end
end

% check for parallel processing options
if BatchOpt.Use2DParallelComputing
    parforArg = obj.cpuParallelLimit;    % Maximum number of workers running in parallel
    if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
else
    parforArg = 0;
end

% define the time points
if strcmp(BatchOpt.DatasetType{1}, '4D, Dataset')
    t1 = 1;
    t2 = obj.I{BatchOpt.id}.time;
else    % 2D, 3D
    t1 = obj.I{BatchOpt.id}.slices{5}(1);
    t2 = obj.I{BatchOpt.id}.slices{5}(2);
end

seSize = str2num(BatchOpt.StrelSize); %#ok<ST2NM>
if numel(seSize) == 2  % when 2 values are provided take them
    se_size(1) = seSize(1);     % for y and x
    se_size(2) = seSize(2);   % for z (or x in 2d mode)
else                    % when only 1 value - calculate the second from the pixSize
    if strcmp(BatchOpt.DilateMode{1}, '3D')
        se_size(1) = seSize; % for y and x
        se_size(2) = max([round(se_size(1)*obj.I{BatchOpt.id}.pixSize.x/obj.I{BatchOpt.id}.pixSize.z) 1]); % for z
    else
        se_size(1) = seSize; % for y
        se_size(2) = se_size(1);    % for x
    end
end

if se_size(1) < 0; se_size(1) = 0; end
if se_size(2) < 0; se_size(2) = 0; end

fixSelectionToMaterial = str2double(BatchOpt.FixSelectionToMaterial);
adapt_coef = str2double(BatchOpt.AdaptiveCoef);
sel_col_ch = find(ismember(BatchOpt.AdaptiveColorChannel{2}, BatchOpt.AdaptiveColorChannel{1})==1);

[height, width, colors, depth] = obj.I{BatchOpt.id}.getDatasetDimensions();

materialIndex = NaN;    % for selection and mask TargetLayer
if strcmp(BatchOpt.TargetLayer{1}, 'model'); materialIndex = str2double(BatchOpt.MaterialIndex); end

if strcmp(BatchOpt.DilateMode{1}, '3D')         % do in 3D
    if BatchOpt.showWaitbar; wb = waitbar(0,sprintf('Dilating selection...\nStrel width: XY=%d x Z=%d',se_size(1)*2+1,se_size(2)*2+1),'Name','Dilating...','WindowStyle','modal'); end
    se = zeros(se_size(1)*2+1,se_size(1)*2+1,se_size(2)*2+1);    % do strel ball type in volume
    [x,y,z] = meshgrid(-se_size(1):se_size(1),-se_size(1):se_size(1),-se_size(2):se_size(2));
    %ball = sqrt(x.^2+y.^2+(se_size(2)/se_size(1)*z).^2);
    %se(ball<sqrt(se_size(1)^2+se_size(2)^2)) = 1;
    ball = sqrt((x/se_size(1)).^2+(y/se_size(1)).^2+(z/se_size(2)).^2);
    se(ball<=1) = 1;

    index = 1;
    tMax = t2-t1+1;
    for t=t1:t2
        if BatchOpt.showWaitbar; waitbar(index/tMax, wb); end
        selection = obj.getData3D(BatchOpt.TargetLayer{1}, t, 4, materialIndex, getDataOptions);
        if isnan(fixSelectionToMaterial)  % dilate to all pixels around selection
            selection = imdilate(selection{1}, se);
        else                % dilate using pixels only from the selected countour
            model = obj.getData3D('model', t, 4, fixSelectionToMaterial, getDataOptions);
            selection = bitand(imdilate(selection{1},se), model{1});
        end
        if BatchOpt.Adaptive
            img = cell2mat(obj.getData3D('image', t, 4, sel_col_ch, getDataOptions));
            existingSelection = cell2mat(obj.getData3D('selection', t, 4, NaN, getDataOptions));
            mean_val = mean2(img(existingSelection==1));
            std_val = std2(img(existingSelection==1))*adapt_coef;
            diff_mask = imabsdiff(selection, existingSelection); % get difference to see only added mask
            updated_mask = zeros(size(selection), 'uint8');
            img(~diff_mask) = 0;
            low_limit = mean_val-std_val;%-thres_down;
            high_limit = mean_val+std_val;%+thres_up;
            if low_limit < 1; low_limit = 1; end
            if high_limit > 255; high_limit = 255; end
            updated_mask(img>=low_limit & img<=high_limit) = 1;
            selection = existingSelection;
            selection(updated_mask==1) = 1;
            CC = bwconncomp(selection,18);  % keep it connected to the largest block
            [~, idx] = max(cellfun(@numel,CC.PixelIdxList));
            selection = zeros(size(selection),'uint8');
            selection(CC.PixelIdxList{idx}) = 1;
        end
        if BatchOpt.Difference
            selection = imabsdiff(uint8(selection), cell2mat(obj.getData3D(BatchOpt.TargetLayer{1}, t, 4, materialIndex, getDataOptions)));
        end

        % clip to mask
        if BatchOpt.FixSelectionToMask && ~strcmp(BatchOpt.TargetLayer{1}, 'mask')
            mask = cell2mat(obj.getData3D('mask', t, 4, NaN, getDataOptions));
            selection = selection & mask;
        end

        obj.setData3D(BatchOpt.TargetLayer{1}, {selection}, t, 4, materialIndex, getDataOptions);
    end
    if BatchOpt.showWaitbar; delete(wb); end
else  % do in 2d layer by layer
    % setup details for parallel computing
    use2DParallelComputing = BatchOpt.Use2DParallelComputing;
    % define parallel processing settings
    % when not in the batch mode, when parpool is present use it
    if batchModeSwitch == 0
        p = gcp('nocreate');
        if ~isempty(p); use2DParallelComputing = true; end
    end

    % setup number of CPUs
    if use2DParallelComputing
        parforArg = obj.cpuParallelLimit;    % Maximum number of workers running in parallel
        if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
    else
        parforArg = 0;
    end

    showWaitbar = BatchOpt.showWaitbar;
    take_difference = BatchOpt.Difference;
    adaptiveSwitch = BatchOpt.Adaptive;
    adaptiveSmoothing = BatchOpt.AdaptiveSmoothing;
    
    se = zeros([se_size(1)*2+1 se_size(2)*2+1],'uint8');
    se(se_size(1)+1,se_size(2)+1) = 1;
    se = bwdist(se);
    se = uint8(se <= max(se_size));

    if strcmp(BatchOpt.DatasetType{1}, '2D, Slice')
        start_no = obj.I{BatchOpt.id}.getCurrentSliceNumber();
        end_no = start_no;
        use2DParallelComputing = false;
        max_size2 = (end_no-start_no+1)*(t2-t1+1);
        showWaitbar = false;
    else
        start_no=1;
        end_no = obj.I{BatchOpt.id}.dim_yxczt(obj.I{BatchOpt.id}.orientation);
        max_size2 = (end_no-start_no+1)*(t2-t1+1);
        if showWaitbar
            pw = PoolWaitbar(max_size2, sprintf('Dilating selection...\nStrel size: %dx%d px', se_size(1),se_size(2)), [], 'Dilating...');
            pw.setIncrement(10);
        end
    end

    options.id = BatchOpt.id;
    for t=t1:t2
        options.t = [t, t];
        if use2DParallelComputing
            stack = cell2mat(obj.getData3D(BatchOpt.TargetLayer{1}, t, obj.I{BatchOpt.id}.orientation, materialIndex, getDataOptions));
            model = [];
            img = [];
            mask = [];
            if ~isnan(fixSelectionToMaterial)
                model = cell2mat(obj.getData3D('model', t, obj.I{BatchOpt.id}.orientation, fixSelectionToMaterial, options));
            end
            if BatchOpt.Adaptive
                img = cell2mat(obj.getData3D('image', t, obj.I{BatchOpt.id}.orientation, sel_col_ch, options));
            end
            if BatchOpt.FixSelectionToMask && ~strcmp(BatchOpt.TargetLayer{1}, 'mask')
                mask = cell2mat(obj.getData3D('mask', t, obj.I{BatchOpt.id}.orientation, NaN, options));
            end

            parfor (layer_id=start_no:end_no, parforArg)
            %for layer_id=start_no:end_no
                if showWaitbar && mod(layer_id, 10) == 1;  increment(pw); end
                sliceIn = stack(:,:,layer_id);
                if max(max(sliceIn)) < 1; continue; end
                modelSlice= [];
                imgSlice = [];
                maskSlice = [];
                if ~isempty(model); modelSlice = model(:,:,layer_id); end
                if ~isempty(img); imgSlice = img(:,:,:,layer_id); end
                if ~isempty(mask); maskSlice = mask(:,:,layer_id); end

                stack(:,:,layer_id) = do_dilate(sliceIn, modelSlice, maskSlice, imgSlice, take_difference, adaptiveSwitch, adaptiveSmoothing, adapt_coef, se_size, se);
            end
            obj.setData3D(BatchOpt.TargetLayer{1}, {stack}, t, obj.I{BatchOpt.id}.orientation, materialIndex, getDataOptions);
        else
            for layer_id=start_no:end_no
                if showWaitbar && mod(layer_id, 10) == 1; increment(pw); end

                sliceIn = cell2mat(obj.getData2D(BatchOpt.TargetLayer{1}, layer_id, obj.I{BatchOpt.id}.orientation, materialIndex, options));
                if max(max(sliceIn)) < 1; continue; end
                model = [];
                img = [];
                mask = [];
                if ~isnan(fixSelectionToMaterial)
                    model = cell2mat(obj.getData2D('model', layer_id, obj.I{BatchOpt.id}.orientation, fixSelectionToMaterial, options));
                end
                if BatchOpt.Adaptive
                    img = cell2mat(obj.getData2D('image', layer_id, obj.I{BatchOpt.id}.orientation, sel_col_ch, options));
                end
                if BatchOpt.FixSelectionToMask && ~strcmp(BatchOpt.TargetLayer{1}, 'mask')
                    mask = cell2mat(obj.getData2D('mask', layer_id, obj.I{BatchOpt.id}.orientation, NaN, options));
                end

                sliceOut = do_dilate(sliceIn, model, mask, img, take_difference, adaptiveSwitch, adaptiveSmoothing, adapt_coef, se_size, se);
                obj.setData2D(BatchOpt.TargetLayer{1}, {sliceOut}, layer_id, obj.I{obj.Id}.orientation, materialIndex, options);
            end
        end
    end
    if showWaitbar; pw.deletePoolWaitbar(); end
end

if ~strcmp(BatchOpt.DatasetType{1}, '2D, Slice')
    toc;
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');
end

function sliceOut = do_dilate(sliceIn, model, mask, img, take_difference, adaptiveSwitch, adaptiveSmoothing, adapt_coef, se_size, se)
% function sliceOut = do_dilate(sliceIn, model, mask, img, take_difference, adaptiveSwitch, adaptiveSmoothing, adapt_coef, se_size, se)
% subfunction to do dilation in normal and parallel processing mode
%
% Parameters:
% sliceIn:  slice [height, width] to be diluted
% model:    model layer [height, width] with 0 and 1 values only when fixSelectionToMaterial is checked, otherwise it should be empty = []
% mask:     mask layer [height, width] with 0 and 1 values only when FixSelectionToMask is checked, otherwise it should be empty = []
% img:      image layer [height, width] only when BatchOpt.Adaptive==true, otherwise it should be empty = []
% take_difference: switch to return a difference after dilation
% adaptiveSwitch:   switch to use adaptive mode
% adaptiveSmoothing:    switch to do smoothing in the adaptive mode
% adapt_coef:   coefficient for adaptive snoothing
% se_size:  % size of the strel [height, width]
% se:   % generated strel element for doing dilation

height = size(sliceIn, 1);
width = size(sliceIn, 2);
connect8 = true;

if adaptiveSwitch
    remember_sliceIn = sliceIn;
    STATS = regionprops(logical(remember_sliceIn), 'BoundingBox', 'PixelList');    % get all original objects before dilation
    sliceOut = zeros(size(sliceIn),'uint8');

    for object=1:numel(STATS)   % cycle through the objects
        bb =  floor(STATS(object).BoundingBox);
        coordXY =  STATS(object).PixelList(1,:);    % coordinate of a pixel that belongs to selected object
        coordXY(1) = coordXY(1)-max([1 bb(1)-ceil(se_size(2)/2)])+1;
        coordXY(2) = coordXY(2)-max([1 bb(2)-ceil(se_size(1)/2)])+1;

        cropImg = img(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])); % crop image
        cropRemembered = remember_sliceIn(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])); % crop sliceIn to an area around the object
        if connect8
            cropRemembered = bwselect(cropRemembered, coordXY(1),coordXY(2), 8);   % pickup only the object
        else
            cropRemembered = bwselect(cropRemembered, coordXY(1),coordXY(2), 4);   % pickup only the object
        end

        if isempty(model) % dilate to all pixels around sliceIn
            cropSelection = imdilate(cropRemembered, se);
        else                % dilate using pixels only from the selected countour
            cropModel = model(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])); % crop model
            cropSelection = imdilate(cropRemembered,se) & (cropModel==1 | cropRemembered);
        end

        mean_val = mean2(cropImg(cropRemembered==1));
        std_val = std2(cropImg(cropRemembered==1))*adapt_coef;
        diff_mask = cropSelection - cropRemembered; % get difference to see only added mask
        cropImg(~diff_mask) = 0;
        low_limit = mean_val-std_val;
        high_limit = mean_val+std_val;
        if low_limit < 1; low_limit = 1; end
        if high_limit > 255; high_limit = 255; end
        newCropSelection = zeros(size(cropRemembered), 'uint8');
        newCropSelection(cropImg>=low_limit & cropImg<=high_limit) = 1;
        newCropSelection(cropRemembered==1) = 1;    % combine original and new sliceIn

        if adaptiveSmoothing
            se2 = strel('rectangle', [1 1]);
            newCropSelection = imdilate(imerode(newCropSelection, se2), se2);
            newCropSelection(cropImg<low_limit & cropImg>high_limit) = 0;
            newCropSelection(cropRemembered==1) = 1;    % combine original and new sliceIn
        end
        if connect8
            newCropSelection = bwselect(newCropSelection,coordXY(1), coordXY(2), 8);   % get only a one connected object, removing unconnected components
        else
            newCropSelection = bwselect(newCropSelection,coordXY(1), coordXY(2), 4);   % get only a one connected object, removing unconnected components
        end
        sliceOut(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])) = ...
            newCropSelection | sliceOut(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)]));
    end
    if take_difference
        sliceOut = sliceOut - remember_sliceIn;
    end
else
    if take_difference  % result of dilation is only expantion of the area
        if isempty(model)  % dilate to all pixels around sliceIn
            sliceOut = imdilate(sliceIn, se) - sliceIn;
        else                % dilate using pixels only from the selected countour
            sliceOut = imdilate(sliceIn, se) & model;
        end
    else            % result of dilation is object's area + expantion of that area
        if isempty(model)  % dilate to all pixels around sliceIn
            sliceOut = imdilate(sliceIn, se);
        else                % dilate using pixels only from the selected countour
            sliceOut = imdilate(sliceIn, se) & bitor(model, sliceIn);
        end
    end
end

% clip to mask
if ~isempty(mask)
    sliceOut = sliceOut & mask;
end
end