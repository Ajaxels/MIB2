function erodeImage(obj, BatchOptIn)
% function erodeImage(obj, BatchOptIn)
% erode image
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event
% Possible fields,
% @li .TargetLayer -> cell, layer to be eroded, 'selection', 'mask', 'model'
% @li .DatasetType -> cell, specify whether to erode the current slice (2D, Slice), the stack (3D, Stack) or complete dataset (4D, Dataset)
% @li .ErodeMode -> cell, type of the strel element for erosion, '2D', '3D'
% @li .StrelSize -> string, size of the strel element in pixels; one or two numbers, when two numbers entered, the second one defines Y or Z dimension for 2D and 3D strel elements respectively
% @li .Difference -> logical, obtain the difference between eroded and original image'
% @li .showWaitbar -> logical, show or not the progress bar during execution

% Copyright (C) 15.09.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 01.10.2022 added erosion of models
% 04.10.2022 added parallel processing

if nargin < 2; BatchOptIn = struct; end

%% populate default values
BatchOpt = struct();
BatchOpt.TargetLayer = {'selection'};     % 
BatchOpt.TargetLayer{2} = {'selection', 'mask', 'model'};     % 
BatchOpt.DatasetType = {'2D, Slice'};     % '2D, Slice', '3D, Stack', '4D, Dataset'
BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
BatchOpt.ErodeMode = {'2D'};
BatchOpt.ErodeMode{2} = {'2D', '3D'};
BatchOpt.StrelSize = '3';
BatchOpt.MaterialIndex = '1';
BatchOpt.Difference = false;
BatchOpt.Use2DParallelComputing = false;
BatchOpt.id = obj.Id;   % optional, id
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar

BatchOpt.mibBatchSectionName = 'Panel -> Selection';
BatchOpt.mibBatchActionName = 'Erode';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.TargetLayer = sprintf('Layer to be eroded');
BatchOpt.mibBatchTooltip.DatasetType = sprintf('Specify whether to erode the current slice (2D, Slice), the stack (3D, Stack) or complete dataset (4D, Dataset)');
BatchOpt.mibBatchTooltip.ErodeMode = sprintf('Type of the strel element for erosion');
BatchOpt.mibBatchTooltip.StrelSize = sprintf('Size of the strel element in pixels; one or two numbers, when two numbers entered, the second one defines Y or Z dimension for 2D and 3D strel elements respectively');
BatchOpt.mibBatchTooltip.MaterialIndex = sprintf('Index of material of the model to be eroded; only for TargetLayer="model"');
BatchOpt.mibBatchTooltip.Difference = sprintf('Obtain the difference between eroded and original image');
BatchOpt.mibBatchTooltip.Use2DParallelComputing = sprintf('Use parallel processing to erode images in 2D');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

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
    if isfield(BatchOptIn, 'mibBatchSectionName'); batchModeSwitch = 1; end
end

%% start of the function
% do nothing is selection is disabled
if obj.I{BatchOpt.id}.enableSelection == 0; notify(obj, 'stopProtocol'); return; end
tic;

% tweak when only one time point
if strcmp(BatchOpt.DatasetType{1}, '4D, Dataset') && obj.I{BatchOpt.id}.time == 1
    BatchOpt.DatasetType{1} = '3D, Stack';
end

getDataOptions.id = BatchOpt.id;
if (strcmp(BatchOpt.ErodeMode{1}, '3D') && ~strcmp(BatchOpt.DatasetType{1}, '4D, Dataset') ) || strcmp(BatchOpt.DatasetType{1}, '3D, Stack')
    obj.mibDoBackup(BatchOpt.TargetLayer{1}, 1, getDataOptions);
else
    obj.mibDoBackup(BatchOpt.TargetLayer{1}, 0, getDataOptions);
end

% define parallel processing settings
% when not in the batch mode, when parpool is present use it
if batchModeSwitch == 0
    p = gcp('nocreate');
    if ~isempty(p); BatchOpt.Use2DParallelComputing = 1; end
end

if BatchOpt.Use2DParallelComputing
    parforArg = obj.cpuParallelLimit;    % Maximum number of workers running in parallel
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
    if strcmp(BatchOpt.ErodeMode{1}, '3D')
        se_size(1) = seSize; % for y and x
        se_size(2) = round(se_size(1)*obj.I{BatchOpt.id}.pixSize.x/obj.I{BatchOpt.id}.pixSize.z); % for z
    else
        se_size(1) = seSize; % for y
        se_size(2) = se_size(1);    % for x
    end
end

if se_size(1) < 0; se_size(1) = 0; end
if se_size(2) < 0; se_size(2) = 0; end  

materialIndex = NaN;    % for selection and mask TargetLayer
if strcmp(BatchOpt.TargetLayer{1}, 'model'); materialIndex = str2double(BatchOpt.MaterialIndex); end

if strcmp(BatchOpt.ErodeMode{1}, '3D')         % do in 3D
    if BatchOpt.showWaitbar; wb = waitbar(0,sprintf('Eroding %s...\nStrel size: XY=%d x Z=%d', BatchOpt.TargetLayer{1},se_size(1)*2+1,se_size(2)*2+1),'Name','Eroding...','WindowStyle','modal'); end
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
        selection{1} = imerode(selection{1}, se);
        if BatchOpt.Difference
            selection{1} = imabsdiff(selection{1}, cell2mat(obj.getData3D(BatchOpt.TargetLayer{1}, t, 4, materialIndex, getDataOptions)));
        end
        obj.setData3D(BatchOpt.TargetLayer{1}, selection, t, 4, materialIndex, getDataOptions);
        index = index + 1;
    end
    if BatchOpt.showWaitbar; delete(wb); end
else    % do in 2d layer by layer
    %se = strel('disk',[se_size(1) se_size(2)],0);
    %se = strel('rectangle',[se_size(1) se_size(2)]);
    
    se = zeros([se_size(1)*2+1 se_size(2)*2+1],'uint8');
    se(se_size(1)+1,se_size(2)+1) = 1;
    se = bwdist(se); 
    se = uint8(se <= max(se_size));

    if strcmp(BatchOpt.DatasetType{1}, '2D, Slice')
        eroded_img = imerode(cell2mat(obj.getData2D(BatchOpt.TargetLayer{1}, NaN, NaN, materialIndex, getDataOptions)), se);
        if BatchOpt.Difference   % if 1 will make selection as a difference
            eroded_img = cell2mat(obj.getData2D(BatchOpt.TargetLayer{1}, NaN, NaN, materialIndex, getDataOptions)) - eroded_img;
        end
        obj.setData2D(BatchOpt.TargetLayer{1}, {eroded_img}, NaN, NaN, materialIndex, getDataOptions);
    else
        showWaitbar = BatchOpt.showWaitbar;
        take_difference = BatchOpt.Difference;
        max_size = obj.I{BatchOpt.id}.dim_yxczt(obj.I{BatchOpt.id}.orientation);
        max_size2 = max_size*(t2-t1+1);

        if showWaitbar
            pw = PoolWaitbar(max_size2, sprintf('Eroding %s...\nStrel size: %dx%d px', BatchOpt.TargetLayer{1}, se_size(1),se_size(2)), [], 'Eroding...'); 
            pw.setIncrement(10);
        end

        for t=t1:t2
            getDataOptions.t = [t, t];
            if ~BatchOpt.Use2DParallelComputing
                for layer_id=1:max_size
                    if showWaitbar && mod(layer_id, 10) == 1; increment(pw); end
                    
                    slice = obj.getData2D(BatchOpt.TargetLayer{1}, layer_id, obj.I{BatchOpt.id}.orientation, materialIndex, getDataOptions);
                    if max(max(slice{1})) < 1; continue; end
                    eroded_img{1} = imerode(slice{1}, se);
                    if BatchOpt.Difference   % if 1 will make selection as a difference
                        eroded_img{1} = slice{1} - eroded_img{1};
                    end
                    obj.setData2D(BatchOpt.TargetLayer{1}, eroded_img, layer_id, obj.I{BatchOpt.id}.orientation, materialIndex, getDataOptions);
                end
            else    % process in parallel
                stack = cell2mat(obj.getData3D(BatchOpt.TargetLayer{1}, t, obj.I{BatchOpt.id}.orientation, materialIndex, getDataOptions));
                parfor (layer_id=1:max_size, parforArg)
                    if showWaitbar && mod(layer_id, 10) == 1;  increment(pw); end
                    slice = stack(:,:,layer_id);
                    if max(max(slice)) < 1; continue; end
                    eroded_img = imerode(slice, se);
                    if take_difference   % if 1 will make selection as a difference
                        eroded_img = slice - eroded_img;
                    end
                    stack(:,:,layer_id) = eroded_img;
                end
                obj.setData3D(BatchOpt.TargetLayer{1}, {stack}, t, obj.I{BatchOpt.id}.orientation, materialIndex, getDataOptions);
            end
        end
        if showWaitbar; pw.deletePoolWaitbar(); end
    end
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