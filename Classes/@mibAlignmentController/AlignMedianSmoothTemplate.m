function AlignMedianSmoothTemplate(obj, parameters)
% function AlignMedianSmoothTemplate(obj, parameters)
% perform automatic alignment to the median-smoothed template dataset
%
% Parameters:
% parameters: a structire with parameters
% .colorCh - index of the color channel to use
% .waitbar - a handle to the waitbar to show
% .useBatchMode - use the script in the batch mode
% .backgroundColor - string that defines background color: 'black', 'white', 'mean' or a number with intensity
% .imgWidthForAnalysis - width of the image used for analysis, the datasets are downsampled to this value
% .cpuParallelLimit - max value of parallel workers to use for parallel processing

% Copyright (C) 20.01.2020, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

% fix the wrong Transformation type value
if strcmp(obj.BatchOpt.TransformationType{1}, 'non reflective similarity'); obj.BatchOpt.TransformationType{1} = 'affine'; end

% check for pre-alignment
if parameters.useBatchMode == 0
    answer1 = questdlg(sprintf('Has the dataset been already pre-aligned?\n\nIf not please use the Drift correction method to do pre-alignment'), 'Pre-alignement', 'Yes, continue', 'Cancel', 'Yes, continue');
    if strcmp(answer1, 'Cancel')
        if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
        return; 
    end
end

global mibPath;
if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Step 1: Preparations\nPlease wait...')); end
movedId = obj.mibModel.Id;    % align moved by the template of the fixed
GetDataOpt.blockModeSwitch = 0;
GetDataOpt.id = movedId;
[Height, Width, Color, Depth, Time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, GetDataOpt);

% allocate space
iMatrix = cell([Depth,1]);      % cell array with transformed images
tformMatrix = cell([Depth,1]);  % for transformation matrix, https://se.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html
rbMatrix = cell([Depth,1]);     % cell array with spatial referencing information associated with the transformed images
loadShifts = 0;
if parameters.useBatchMode == 0
    if obj.View.handles.loadShiftsCheck.Value == 1
        tformMatrix = obj.shiftsX;
        rbMatrix = obj.shiftsY;
        loadShifts = 1;
    end
end
obj.shiftsX = zeros(1, Depth);
obj.shiftsY = zeros(1, Depth);

% update automatic detection options
% the batch mode will use session settings
if parameters.useBatchMode == 0 && loadShifts == 0
    status = obj.updateAutomaticOptions();
    if status == 0
        if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
        return;
    end
end

tic
% define background color
if isnumeric(parameters.backgroundColor)
    backgroundColor = parameters.backgroundColor;
else
    if strcmp(parameters.backgroundColor, 'black')
        backgroundColor = 0;
    elseif strcmp(parameters.backgroundColor, 'white')
        backgroundColor = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
    else
        backgroundColor = mean(mean(cell2mat(obj.mibModel.getData2D('image', 1, NaN, parameters.colorCh, GetDataOpt))));
    end
end
parameters.imgWidthForAnalysis = obj.automaticOptions.imgWidthForAnalysis;  % resize image to this size to speed-up the process
% use full resolution, when .imgWidthForAnalysis == 0
if parameters.imgWidthForAnalysis == 0; parameters.imgWidthForAnalysis = Width; end
PyramidLevels = obj.automaticOptions.amst.PyramidLevels;

if loadShifts == 0
    ratio = parameters.imgWidthForAnalysis/Width;
    
    % smooth image using median filter
    if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Step 2: Obtaining the dataset\nPlease wait...')); end
    movingImg = cell2mat(obj.mibModel.getData3D('image', NaN, NaN, parameters.colorCh, GetDataOpt));
    if ratio ~= 1   % resize if needed
        if obj.BatchOpt.showWaitbar; waitbar(0.33, parameters.waitbar, sprintf('Step 2: Resizing the dataset in %.3f times\nPlease wait...', ratio)); end
        movingImg = imresize(movingImg, ratio, 'bicubic');
    end
    if obj.BatchOpt.showWaitbar; waitbar(0.66, parameters.waitbar, sprintf('Step 2: Doing median filtering with Z-size %s\nPlease wait...', obj.BatchOpt.MedianSize)); end
    FilterOpt.SourceLayer = {'image'};
    %FilterOpt.DatasetType = {'3D, Stack'};
    FilterOpt.FilterName = {'Median'};
    FilterOpt.Mode3D = true;
    FilterOpt.showWaitbar = false;
    FilterOpt.NeighborhoodSize = sprintf('1, 1, %s', obj.BatchOpt.MedianSize);
    FilterOpt.Padding = {'replicate'};
    if obj.BatchOpt.UseParallelComputing == 0
        % without parallel pool, filter the whole stack at once
        %fixedImg = evalin('base','fixedImg'); % for debug
        fixedImg = mibDoImageFiltering2(movingImg, FilterOpt);
    else
        % with parallel pool brake dataset into subvolumes equal to number
        % of workers
        currentPool = gcp;  % get current parallel pool
        step = ceil(size(movingImg,1)/currentPool.NumWorkers);  % find slicing step
        xmaxVec = step:step:size(movingImg,1);  % generate brake points
        xmaxVec = [0 xmaxVec];  % add 0 as the first brake point
        xmaxVec(currentPool.NumWorkers+1) = size(movingImg,1);  % add the last brake point == height of the dataset
        
        movImg = cell([currentPool.NumWorkers,1]);  % allocate space
        fixImg = cell([currentPool.NumWorkers,1]);
        for worker = 1:currentPool.NumWorkers   % rearragene dataset to cell array
            movImg{worker} = movingImg(xmaxVec(worker)+1:xmaxVec(worker+1),:,:,:);
        end
        
        % do filtering
        parfor (worker = 1:currentPool.NumWorkers, parameters.cpuParallelLimit)
            fixImg{worker} = mibDoImageFiltering2(movImg{worker}, FilterOpt);
        end
        
        for worker = 1:currentPool.NumWorkers   % rearragene back from cell array
            fixedImg(xmaxVec(worker)+1:xmaxVec(worker+1),:,:,:) = fixImg{worker};
        end
        clear movImg fixImg;
    end
    %assignin('base','fixedImg',fixedImg);     % for debug
    if obj.BatchOpt.showWaitbar; waitbar(1, parameters.waitbar); end
    
    % prepare imregconfig for imregister
    [optimizer, metric] = imregconfig('monomodal');     % monomodal or multimodal
    %[optimizer, metric] = imregconfig('multimodal');     % monomodal or multimodal
    optimizer.MaximumIterations = obj.automaticOptions.amst.MaximumIterations;
    optimizer.GradientMagnitudeTolerance = obj.automaticOptions.amst.GradientMagnitudeTolerance;
    optimizer.MinimumStepLength = obj.automaticOptions.amst.MinimumStepLength;
    optimizer.MaximumStepLength = obj.automaticOptions.amst.MaximumStepLength;
    optimizer.RelaxationFactor = obj.automaticOptions.amst.RelaxationFactor;
    
    %wb = parameters.waitbar;
    showWaitbar = obj.BatchOpt.showWaitbar;
    TransformationType = obj.BatchOpt.TransformationType{1};
    
    % define usage of parallel computing
    if obj.BatchOpt.UseParallelComputing
        parforArg = parameters.cpuParallelLimit;    % Maximum number of workers running in parallel
    else
        parforArg = 0;      % Maximum number of workers running in parallel
    end
    
    % ticBytes(gcp);  % % to see memory usage during parfor
    
    % create waitbar for parallel computing
    if obj.BatchOpt.showWaitbar; pw = PoolWaitbar(Depth, sprintf('Step 3: Calculating transformations\nPlease wait...'), parameters.waitbar); end
    
    parfor (layer = 1:Depth, parforArg)
    %for layer = 1:Depth
        %% The first two methods are using imregdemons function that accepts local transformation, but it is better to use imregtform below
        % Detect features
        %         switch parameters.detectPointsType
        %             case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
        %                 detectOpt = obj.automaticOptions.detectSURFFeatures;
        %             case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
        %                 detectOpt = obj.automaticOptions.detectMSERFeatures;
        %             case 'Corners: Harris-Stephens algorithm'
        %                 detectOpt = obj.automaticOptions.detectHarrisFeatures;
        %             case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
        %                 detectOpt = obj.automaticOptions.detectBRISKFeatures;
        %             case 'Corners: Features from Accelerated Segment Test (FAST)'
        %                 detectOpt = obj.automaticOptions.detectFASTFeatures;
        %             case 'Corners: Minimum Eigenvalue algorithm'
        %                 detectOpt = obj.automaticOptions.detectMinEigenFeatures;
        %             case 'Oriented FAST and rotated BRIEF (ORB)'
        %                 detectOpt = obj.automaticOptions.detectORBFeatures;
        %         end
        %                     %% Procedure 1 imregdemons (when local deformations are acceptable)
        %                     % the local variations could be too large, number of
        %                     % iterations ([32, 16, 8]) seems to be low, but ok
        %                     ratio = 1;
        %                     currImg = cell2mat(obj.mibModel.getData2D('image', layer, 4, parameters.colorCh, optionsGetFixed));
        %                     fixedImg = currImg;
        %                     distortedImg = cell2mat(obj.mibModel.getData2D('image', layer, 4, parameters.colorCh, GetDataOpt));
        %                     movingImg = distortedImg;
        %
        %                     [D, movingReg] = imregdemons(movingImg, fixedImg, [32, 16, 8], 'PyramidLevels', 3, 'AccumulatedFieldSmoothing', 1.3, 'DisplayWaitbar', false);
        %                     I = imwarp(distortedImg, D, 'cubic', 'FillValues', double(backgroundColor));
        %                     obj.mibModel.setData2D('image',I, layer, 4, NaN, GetDataOpt);
        %                     if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 2: Align datasets\nPlease wait...')); end
        %                     continue;
        
        %                     %% Procedure 2 imregdemons (when local deformations are acceptable)
        %                     % same as 1, but done for the downsampled image with
        %                     % more iterations, give good results
        %                     currImg = cell2mat(obj.mibModel.getData2D('image', layer, 4, parameters.colorCh, optionsGetFixed));
        %                     fixedImg = imresize(currImg, ratio, 'bicubic');
        %                     distortedImg = cell2mat(obj.mibModel.getData2D('image', layer, 4, parameters.colorCh, GetDataOpt));
        %                     movingImg = imresize(distortedImg, ratio, 'bicubic');
        %
        %                     [D, movingReg] = imregdemons(movingImg, fixedImg, [500 400 200], 'PyramidLevels', 3, 'AccumulatedFieldSmoothing', 1.3, 'DisplayWaitbar', false);
        %                     D2 = imresize(D*(1/ratio), size(currImg), 'bicubic');
        %                     I = imwarp(distortedImg, D2, 'cubic', 'FillValues', double(backgroundColor));
        %                     obj.mibModel.setData2D('image',I, layer, 4, NaN, GetDataOpt);
        %                     if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 2: Align datasets\nPlease wait...')); end
        %                     continue;
        
        
        %% Procedure 3 imregister
        tform = imregtform(movingImg(:,:,:,layer), fixedImg(:,:,:,layer), TransformationType, optimizer, metric, 'PyramidLevels', PyramidLevels);
        %tform = imregtform(movingImgCell{layer}, fixedImgCell{layer}, TransformationType, optimizer, metric, 'PyramidLevels', 1);
        %tform = imregcorr(movingImg(:,:,:,layer), fixedImg(:,:,:,layer), 'similarity'); % alternative using phase-correlation, but can only be done for translation, rigid and similarity
        %
        % %                   % checks
        %                     refImgSize = imref2d(size(movingImg(:,:,:,layer)));  % reference image size
        %                     [iM, rbM] = imwarp(movingImg(:,:,:,layer), tform, 'cubic', 'OutputView', refImgSize, 'FillValues', 0);
        %                     Itest = zeros([size(fixedImg, 1) size(fixedImg, 2) 3], class(fixedImg));
        %                     Itest(:,:,1) = fixedImg(:,:,:,layer);
        %                     Itest(:,:,2) = iM;
        %                     imtool(Itest);
        %
        
        tform.T(3,1) = tform.T(3,1)*(1/ratio);
        tform.T(3,2) = tform.T(3,2)*(1/ratio);
        tformMatrix{layer} = tform;
        if showWaitbar; increment(pw); end
        %if showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 3: Calculating transformations\nPlease wait...')); end
    end
    % tocBytes(gcp)     % to see memory usage during parfor
    if obj.BatchOpt.showWaitbar; keepWaitbar = 1; pw.deletePoolWaitbar(keepWaitbar); end    % delete pw, but keep standard wb handles
    
    clear movingImg fixedImg;
    
    % ----------------------------------------------
    % correct drifts with running average filtering
    % ----------------------------------------------
    vec_length = numel(tformMatrix);
    x_stretch = arrayfun(@(objId) tformMatrix{objId}.T(1,1), 2:vec_length);
    y_stretch = arrayfun(@(objId) tformMatrix{objId}.T(2,2), 2:vec_length);
    x_shear = arrayfun(@(objId) tformMatrix{objId}.T(2,1), 2:vec_length);
    y_shear = arrayfun(@(objId) tformMatrix{objId}.T(1,2), 2:vec_length);
    
    fixDrifts2 = '';
    if parameters.useBatchMode == 0
        figure(125)
        subplot(2,1,1)
        plot(2:vec_length, x_stretch, 2:vec_length, y_stretch);
        title('Scaling');
        legend('x-axis','y-axis');
        subplot(2,1,2)
        plot(2:vec_length, x_shear, 2:vec_length, y_shear);
        title('Shear');
        legend('x-axis','y-axis');
        
        fixDrifts2 = questdlg('Align the stack using detected displacements?','Fix drifts', 'Yes', 'Subtract running average', 'Quit alignment', 'Yes');
        if strcmp(fixDrifts2, 'Quit alignment')
            if isdeployed == 0
                assignin('base', 'tformMatrix', tformMatrix);
                fprintf('Transformation matrix (tformMatrix) was exported to the Matlab workspace\nIt can be modified and saved to disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'');\n');
            end
            if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
            return;
        end
        
        if floor(Depth/2-1) > 25
            halfWidthDefault = '25';
        else
            halfWidthDefault = num2str(floor(Depth/2-1));
        end
        prompts = {'Fix stretching'; 'Fix shear'; 'Half-width of the averaging window'};
        defAns = {true; true; halfWidthDefault};
        dlgTitle = 'Correction settings';
        options.Title = 'Please select suitable settings for the correction';
    end
    
    if strcmp(fixDrifts2, 'Subtract running average') || obj.BatchOpt.SubtractRunningAverage == 1
        notOk = 1;
        while notOk
            if parameters.useBatchMode == 0
                [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer)
                    if isdeployed == 0
                        assignin('base', 'tformMatrix', tformMatrix);
                        fprintf('Transformation matrix (tformMatrix) was exported to the Matlab workspace\nIt can be modified and saved to disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'');\n');
                    end
                    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                    return;
                end
                obj.BatchOpt.SubtractRunningAverageFixStretch = logical(answer{1});
                obj.BatchOpt.SubtractRunningAverageFixShear = logical(answer{2});
                halfwidth = str2double(answer{3});
            else
                halfwidth = str2double(obj.BatchOpt.SubtractRunningAverageStep);
                notOk = 0;
                if obj.BatchOpt.SubtractRunningAverage == 1
                    fixDrifts = 'Yes';
                end
            end
            
            if halfwidth > floor(Depth/2-1)
                questdlg(sprintf('!!! Error !!!\n\nThe half-width should be smaller than the half depth of the dataset (%d) of the dataset!', floor(Depth/2-1)), 'Wrong half-width', 'Try again', 'Try again');
                continue;
            end
            
            if obj.BatchOpt.SubtractRunningAverageFixStretch
                % fixing the stretching
                x_stretch2 = x_stretch-windv(x_stretch, halfwidth)+1;   % stretch should be 1 when no changes
                y_stretch2 = y_stretch-windv(y_stretch, halfwidth)+1;
            else
                x_stretch2 = x_stretch;
                y_stretch2 = y_stretch;
            end
            if obj.BatchOpt.SubtractRunningAverageFixShear
                % fixing the shear
                x_shear2 = x_shear-windv(x_shear, halfwidth);        % shear should be 0 when no changes
                y_shear2 = y_shear-windv(y_shear, halfwidth);
            else
                x_shear2 = x_shear;
                y_shear2 = y_shear;
            end
            
            if parameters.useBatchMode == 0
                figure(125)
                subplot(2,1,1)
                plot(2:vec_length, x_stretch2, 2:vec_length, y_stretch2);
                title('Scaling, fixed');
                legend('x-axis','y-axis');
                subplot(2,1,2)
                plot(2:vec_length, x_shear2, 2:vec_length, y_shear2);
                title('Shear, fixed');
                legend('x-axis','y-axis');
                
                fixDrifts = questdlg('Align the stack using detected displacements?', 'Fix drifts', 'Yes', 'Change window size', 'Quit alignment', 'Yes');
                if strcmp(fixDrifts, 'Quit alignment')
                    if isdeployed == 0
                        assignin('base', 'tformMatrix', tformMatrix);
                        fprintf('Transformation matrix (tformMatrix) was exported to the Matlab workspace\nIt can be modified and saved to disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'');\n');
                    end
                    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                    return;
                end
                obj.BatchOpt.SubtractRunningAverage = true;
                obj.BatchOpt.SubtractRunningAverageStep = num2str(halfwidth);
            end
            
            if strcmp(fixDrifts, 'Yes')
                for i=2:vec_length
                    tformMatrix{i}.T(1,1) = x_stretch2(i-1);
                    tformMatrix{i}.T(2,2) = y_stretch2(i-1);
                    tformMatrix{i}.T(2,1) = x_shear2(i-1);
                    tformMatrix{i}.T(1,2) = y_shear2(i-1);
                end
                notOk = 0;
            end
        end
    end
end

refImgSize = imref2d([Height, Width]);  % reference image size
if strcmp(obj.BatchOpt.TransformationMode{1}, 'cropped') == 1    % the cropped view, faster and take less memory
    for layer=1:Depth
        if ~isempty(tformMatrix{layer})
            I = cell2mat(obj.mibModel.getData2D('image', layer, 4, NaN, GetDataOpt));
            [iMatrix{layer}, rbMatrix{layer}] = imwarp(I, tformMatrix{layer}, 'cubic', 'OutputView', refImgSize, 'FillValues', double(backgroundColor));
            obj.mibModel.setData2D('image', iMatrix{layer}, layer, 4, NaN, GetDataOpt);
            %                             A = imread('pout.tif');
            %                             Rin = imref2d(size(A))
            %                             Rin.XWorldLimits = Rin.XWorldLimits-mean(Rin.XWorldLimits);
            %                             Rin.YWorldLimits = Rin.YWorldLimits-mean(Rin.YWorldLimits);
            %                             out = imwarp(A,Rin,tform);
            
            if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
                I = cell2mat(obj.mibModel.getData2D('everything', layer, 4, NaN, GetDataOpt));
                I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                obj.mibModel.setData2D('everything', I, layer, 4, NaN, GetDataOpt);
            else
                if obj.mibModel.getImageProperty('modelExist')
                    I = cell2mat(obj.mibModel.getData2D('model', layer, 4, NaN, GetDataOpt));
                    I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                    obj.mibModel.setData2D('model', I, layer, 4, NaN, GetDataOpt);
                end
                if obj.mibModel.getImageProperty('maskExist')
                    I = cell2mat(obj.mibModel.getData2D('mask', layer, 4, NaN, GetDataOpt));
                    I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                    obj.mibModel.setData2D('mask', I, layer, 4, NaN, GetDataOpt);
                end
                if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                    I = cell2mat(obj.mibModel.getData2D('selection', layer, 4, NaN, GetDataOpt));
                    I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                    obj.mibModel.setData2D('selection', I, layer, 4, NaN, GetDataOpt);
                end
            end
            
            % transform annotations
            [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{GetDataOpt.id}.getSliceLabels(layer);
            if ~isempty(labelsList)
                [labelPositions(:,2), labelPositions(:,3)] = transformPointsForward(tformMatrix{layer}, labelPositions(:,2), labelPositions(:,3));
                obj.mibModel.I{GetDataOpt.id}.hLabels.updateLabels(indices, labelsList, labelPositions, labelValues);
            end
        end
        if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 4: Transforming the datasets\nPlease wait...')); end
    end
else  % the extended view
    error('not yet fixed')
    iMatrix = cell([numel(Depth), 1]);
    rbMatrix(1:Depth) = {refImgSize};
    
    for layer=1:Depth
        if ~isempty(tformMatrix{layer})
            I = cell2mat(obj.mibModel.getData2D('image', layer, 4, NaN, optionsGetData));
            [iMatrix{layer}, rbMatrix{layer}] = imwarp(I, tformMatrix{layer}, 'cubic', 'FillValues', double(backgroundColor));
            
            %I = cell2mat(obj.mibModel.getData2D('everything', layer, NaN, NaN, optionsGetData));
            %I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
            %obj.mibModel.setData2D('everything', I, layer, NaN, NaN, optionsGetData);
        else
            iMatrix{layer} = cell2mat(obj.mibModel.getData2D('image', layer, 4, NaN, optionsGetData));
        end
        if obj.BatchOpt.showWaitbar; waitbar((layer+Depth)/(Depth*4), parameters.waitbar, sprintf('Step 2: Transforming images\nPlease wait...')); end
    end
    
    xmin = zeros([numel(rbMatrix), 1]);
    xmax = zeros([numel(rbMatrix), 1]);
    ymin = zeros([numel(rbMatrix), 1]);
    ymax = zeros([numel(rbMatrix), 1]);
    % calculate shifts
    for layer=1:numel(rbMatrix)
        xmin(layer) = floor(rbMatrix{layer}.XWorldLimits(1));
        xmax(layer) = floor(rbMatrix{layer}.XWorldLimits(2));
        ymin(layer) = floor(rbMatrix{layer}.YWorldLimits(1));
        ymax(layer) = floor(rbMatrix{layer}.YWorldLimits(2));
    end
    dx = min(xmin);
    dy = min(ymin);
    nWidth = max(xmax)-min(xmin);
    nHeight = max(ymax)-min(ymin);
    Iout = zeros([nHeight, nWidth, size(iMatrix{1},3), numel(rbMatrix)], class(I)) + backgroundColor;
    for layer=1:numel(rbMatrix)
        x1 = xmin(layer)-dx+1;
        x2 = x1 + rbMatrix{layer}.ImageSize(2)-1;
        y1 = ymin(layer)-dy+1;
        y2 = y1 + rbMatrix{layer}.ImageSize(1)-1;
        Iout(y1:y2,x1:x2,:,layer) = iMatrix{layer};
        
        % transform annotations
        [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer);
        if ~isempty(labelsList)
            if ~isempty(tformMatrix{layer})
                [labelPositions(:,2), labelPositions(:,3)] = transformPointsForward(tformMatrix{layer}, labelPositions(:,2), labelPositions(:,3));
                labelPositions(:,2) = labelPositions(:,2) - dx - 1;
                labelPositions(:,3) = labelPositions(:,3) - dy - 1;
            else
                labelPositions(:,2) = labelPositions(:,2) + x1;
                labelPositions(:,3) = labelPositions(:,3) + y1;
            end
            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(indices, labelsList, labelPositions, labelValues);
        end
        if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*2)/(Depth*4), parameters.waitbar, sprintf('Step 3: Assembling transformed images\nPlease wait...')); end
    end
    obj.mibModel.setData4D('image', Iout);
    
    % aligning the model
    if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
        Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
        Model = cell2mat(obj.mibModel.getData4D('everything', 4, NaN, optionsGetData));
        for layer=1:Depth
            if ~isempty(tformMatrix{layer})
                I = imwarp(Model(:,:,layer), tformMatrix{layer}, 'nearest', 'FillValues', 0);
            else
                I = Model(:,:,layer);
            end
            x1 = xmin(layer)-dx+1;
            x2 = x1 + rbMatrix{layer}.ImageSize(2)-1;
            y1 = ymin(layer)-dy+1;
            y2 = y1 + rbMatrix{layer}.ImageSize(1)-1;
            Iout(y1:y2,x1:x2,layer) = I;
            if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed models\nPlease wait...')); end
        end
        obj.mibModel.setData4D('everything', Iout, NaN, NaN, optionsGetData);
    else
        % aligning the model layer
        if obj.mibModel.getImageProperty('modelExist')
            Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
            Model = cell2mat(obj.mibModel.getData4D('model', 4, NaN, optionsGetData));
            for layer=1:Depth
                if ~isempty(tformMatrix{layer})
                    I = imwarp(Model(:,:,layer), tformMatrix{layer}, 'nearest', 'FillValues', 0);
                else
                    I = Model(:,:,layer);
                end
                x1 = xmin(layer)-dx+1;
                x2 = x1 + rbMatrix{layer}.ImageSize(2)-1;
                y1 = ymin(layer)-dy+1;
                y2 = y1 + rbMatrix{layer}.ImageSize(1)-1;
                Iout(y1:y2,x1:x2,layer) = I;
                if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed model\nPlease wait...')); end
            end
            obj.mibModel.setData4D('model', Iout, 4, NaN, optionsGetData);
        end
        % aligning the mask layer
        if obj.mibModel.getImageProperty('maskExist')
            Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
            Model = cell2mat(obj.mibModel.getData4D('mask', 4, NaN, optionsGetData));
            for layer=1:Depth
                if ~isempty(tformMatrix{layer})
                    I = imwarp(Model(:,:,layer), tformMatrix{layer}, 'nearest', 'FillValues', 0);
                else
                    I = Model(:,:,layer);
                end
                x1 = xmin(layer)-dx+1;
                x2 = x1 + rbMatrix{layer}.ImageSize(2)-1;
                y1 = ymin(layer)-dy+1;
                y2 = y1 + rbMatrix{layer}.ImageSize(1)-1;
                Iout(y1:y2,x1:x2,layer) = I;
                if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed mask\nPlease wait...')); end
            end
            obj.mibModel.setData4D('mask', Iout, 4, NaN, optionsGetData);
        end
        % aligning the selection layer
        if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
            Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
            Model = cell2mat(obj.mibModel.getData4D('selection', 4, NaN, optionsGetData));
            for layer=1:Depth
                if ~isempty(tformMatrix{layer})
                    I = imwarp(Model(:,:,layer), tformMatrix{layer}, 'nearest', 'FillValues', 0);
                else
                    I = Model(:,:,layer);
                end
                x1 = xmin(layer)-dx+1;
                x2 = x1 + rbMatrix{layer}.ImageSize(2)-1;
                y1 = ymin(layer)-dy+1;
                y2 = y1 + rbMatrix{layer}.ImageSize(1)-1;
                Iout(y1:y2,x1:x2,layer) = I;
                if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed selection\nPlease wait...')); end
            end
            obj.mibModel.setData4D('selection', Iout, 4, NaN, optionsGetData);
        end
    end
    
    % calculate shift of the bounding box
    maxXshift = dx;   % maximal X shift in pixels vs the first slice
    maxYshift = dy;   % maximal Y shift in pixels vs the first slice
    if obj.mibModel.I{obj.mibModel.Id}.orientation == 4
        maxXshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;  % X shift in units vs the first slice
        maxYshift = maxYshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % Y shift in units vs the first slice
        maxZshift = 0;
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2
        maxYshift = maxYshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % Y shift in units vs the first slice
        maxZshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.z;  % X shift in units vs the first slice;
        maxXshift = 0;
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1
        maxXshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % X shift in units vs the first slice
        maxZshift = maxXshift*obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
        maxYshift = 0;                              % Y shift in units vs the first slice
    end
    obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, [maxXshift, maxYshift, maxZshift]);
end
toc;

if obj.BatchOpt.SaveShiftsToFile     % use preexisting parameters
    if parameters.useBatchMode == 1
        fn = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
        [obj.pathstr, name, ext] = fileparts(fn);
        fn = fullfile(obj.pathstr, [name '_align.coefXY']);
    else
        fn = obj.View.handles.saveShiftsXYpath.String;
    end
    save(fn, 'tformMatrix', 'rbMatrix');
    fprintf('alignment: tformMatrix and rbMatrix were saved to a file:\n%s\n', fn);
end

if ~isdeployed
    assignin('base', 'rbMatrix', rbMatrix);
    assignin('base', 'tformMatrix', tformMatrix);
    fprintf('Transform matrix (tformMatrix) and reference 2-D image to world coordinates (rbMatrix) were exported to the Matlab workspace (tformMatrix)\nThese variables can be modified and saved to a disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'', ''rbMatrix'');\n');
end

if loadShifts == 0
    logText = sprintf('Aligned using %s; type=%s, mode=%s, imgWidth=%d', 'AMST: median-smoothed template', obj.BatchOpt.TransformationType{1}, obj.BatchOpt.TransformationMode{1}, parameters.imgWidthForAnalysis);
    if strcmp(fixDrifts2, 'Subtract running average')
        logText = sprintf('%s, runaverage:%d, fixstretch:%d fix-shear:%d', logText, halfwidth, answer{1}, answer{2});
    end
else
    logText = sprintf('Aligned using %s', obj.View.handles.loadShiftsXYpath.String);
end
obj.mibModel.I{GetDataOpt.id}.updateImgInfo(logText);

if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
notify(obj.mibModel, 'newDataset');
notify(obj.mibModel, 'plotImage');

% for batch need to generate an event and send the BatchOptLoc
% structure with it to the macro recorder / mibBatchController
obj.returnBatchOpt(obj.BatchOpt);

if parameters.useBatchMode == 0; obj.closeWindow(); end
end