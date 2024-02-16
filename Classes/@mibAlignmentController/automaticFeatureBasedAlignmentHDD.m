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

function result = automaticFeatureBasedAlignmentHDD(obj, parameters)
% function result = automaticFeatureBasedAlignmentHDD(obj, parameters)
% perform automatic alignment based on detected features in HDD mode when
% images are processed on the hard drive without combining them all in MIB

% Updates
% 

global mibPath;
result = false;

% define size of the parallel pool
if parameters.UseParallelComputing
    parforArg = obj.mibModel.cpuParallelLimit;
    if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
else
    parforArg = 0;
end
showWaitbar = obj.BatchOpt.showWaitbar;

answer = questdlg(sprintf('!!! Warning !!!\n\nBefore proceeding further please load the first image of the dataset into MIB!'), ...
    'Warning', ...
    'Yes it is already loaded', 'Stop to load the dataset', 'Stop to load the dataset');
if strcmp(answer, 'Stop to load the dataset'); return; end

if showWaitbar
    pw = PoolWaitbar(1, sprintf('Setting datastore\nPlease wait...'), parameters.waitbar);
    pw.setIncrement(10);  % set increment step to 10
end

% make datastore for images
try
    switch lower(['.' obj.BatchOpt.HDD_InputFilenameExtension{1}])
        case '.am'
            getDataOptions.getMeta = false;     % do not process meta data in amiramesh files
            getDataOptions.verbose = false;     % do not display info about loaded image
            imgDS = imageDatastore(obj.BatchOpt.HDD_InputDir, ...
                'FileExtensions', lower(['.' obj.BatchOpt.HDD_InputFilenameExtension{1}]),...
                'IncludeSubfolders', false, ...
                'ReadFcn', @(fn)amiraMesh2bitmap(fn, getDataOptions));
        otherwise
            getDataOptions.mibBioformatsCheck = obj.BatchOpt.HDD_BioformatsReader;
            getDataOptions.verbose = false;
            getDataOptions.BioFormatsIndices = str2num(obj.BatchOpt.HDD_BioformatsIndex);
            imgDS = imageDatastore(obj.BatchOpt.HDD_InputDir, ...
                'FileExtensions', lower(['.' obj.BatchOpt.HDD_InputFilenameExtension{1}]), ...
                'IncludeSubfolders', false, ...
                'ReadFcn', @(fn)mibLoadImages(fn, getDataOptions));
    end
catch err
    errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
    if showWaitbar; pw.delete(); end
    return;
end

numFiles = length(imgDS.Files);
% allocate space
iMatrix = cell([numFiles,1]);      % cell array with transformed images
tformMatrix = cell([numFiles,1]);  % for transformation matrix, https://se.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html
rbMatrix = cell([numFiles,1]);     % cell array with spatial referencing information associated with the transformed images
loadShifts = 0;
if parameters.useBatchMode == 0
    if obj.View.handles.loadShiftsCheck.Value == 1
        tformMatrix = obj.shiftsX;
        rbMatrix = obj.shiftsY;
        loadShifts = 1;
    end
end
obj.shiftsX = zeros(1, numFiles);
obj.shiftsY = zeros(1, numFiles);

if showWaitbar
    pw.updateMaxNumberOfIterations(numFiles*(3-loadShifts));
end

% update automatic detection options
% the batch mode will use session settings
if parameters.useBatchMode == 0 && loadShifts == 0
    status = obj.updateAutomaticOptions();
    if status == 0
        if showWaitbar; pw.delete(); end
        return;
    end
end

timerStart = tic;
optionsGetData.blockModeSwitch = 0;
[Height, Width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, optionsGetData);

% define background color
if isnumeric(parameters.backgroundColor)
    backgroundColor = parameters.backgroundColor;
else
    if strcmp(parameters.backgroundColor,'black')
        backgroundColor = 0;
    elseif strcmp(parameters.backgroundColor,'white')
        backgroundColor = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
    else
        backgroundColor = mean(mean(cell2mat(obj.mibModel.getData2D('image', 1, NaN, parameters.colorCh, optionsGetData))));
    end
end

% allocate space to store image dimensions for files
heightVec = zeros([numFiles, 1]);
widthVec = zeros([numFiles, 1]);
colorsVec = zeros([numFiles, 1]);

if obj.automaticOptions.imgWidthForAnalysis == 0
    parameters.imgWidthForAnalysis = Width;
else
    parameters.imgWidthForAnalysis = obj.automaticOptions.imgWidthForAnalysis;  % resize image to this size to speed-up the process
end
ratio = parameters.imgWidthForAnalysis/Width;

if loadShifts == 0
    if showWaitbar; pw.updateText(sprintf('Step 1: detecting features\nPlease wait...')); end
    
    original = cell2mat(obj.mibModel.getData2D('image', 1, 4, parameters.colorCh, optionsGetData));
    [heightVec(1), widthVec(1), colorsVec(1)]  = size(original);
    
    tt1 = tic;

    % add tformMatrix{1} for the first slice
    tformMatrix{1} = affine2d;
    tformMatrix{1}.T = single(tformMatrix{1}.T);

    featuresList = repmat({}, [numFiles, 1]);
    validPtsList = repmat({}, [numFiles, 1]);

    % prepare variables for parfor
    switch parameters.detectPointsType
        case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
            detectOpt = obj.automaticOptions.detectSURFFeatures;
        case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
            detectOpt = obj.automaticOptions.detectMSERFeatures;
        case 'Corners: Harris-Stephens algorithm'
            detectOpt = obj.automaticOptions.detectHarrisFeatures;
        case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
            detectOpt = obj.automaticOptions.detectBRISKFeatures;
        case 'Corners: Features from Accelerated Segment Test (FAST)'
            detectOpt = obj.automaticOptions.detectFASTFeatures;
        case 'Corners: Minimum Eigenvalue algorithm'
            detectOpt = obj.automaticOptions.detectMinEigenFeatures;
        case 'Oriented FAST and rotated BRIEF (ORB)'
            detectOpt = obj.automaticOptions.detectORBFeatures;
    end
    colorCh = parameters.colorCh;
    detectPointsType = parameters.detectPointsType;
    rotationInvariance = obj.automaticOptions.rotationInvariance;
    metricThreshold = NaN; if isfield(detectOpt, 'MetricThreshold'); metricThreshold = detectOpt.MetricThreshold; end
    numOctaves = NaN; if isfield(detectOpt, 'NumOctaves'); numOctaves = detectOpt.NumOctaves; end
    numScaleLevels = NaN; if isfield(detectOpt, 'NumScaleLevels'); numScaleLevels = detectOpt.NumScaleLevels; end
    thresholdDelta = NaN; if isfield(detectOpt, 'ThresholdDelta'); thresholdDelta = detectOpt.ThresholdDelta; end
    regionAreaRange = NaN; if isfield(detectOpt, 'RegionAreaRange'); regionAreaRange = detectOpt.RegionAreaRange; end
    maxAreaVariation = NaN; if isfield(detectOpt, 'MaxAreaVariation'); maxAreaVariation = detectOpt.MaxAreaVariation; end
    minQuality = NaN; if isfield(detectOpt, 'MinQuality'); minQuality = detectOpt.MinQuality; end
    filterSize = NaN; if isfield(detectOpt, 'FilterSize'); filterSize = detectOpt.FilterSize; end
    minContrast = NaN; if isfield(detectOpt, 'MinContrast'); minContrast = detectOpt.MinContrast; end
    scaleFactor = NaN; if isfield(detectOpt, 'ScaleFactor'); scaleFactor = detectOpt.ScaleFactor; end
    
    parfor (layer = 1:numFiles, parforArg)
        distorted = readimage(imgDS, layer);
        [heightVec(layer), widthVec(layer), colorsVec(layer)]  = size(distorted);

        % extrct color channel to use
        if size(distorted, 3) > 1; distorted = distorted(:, :, colorCh); end
        
        % resize if needed
        if ratio ~= 1; distorted = imresize(distorted, ratio, 'bicubic'); end

        % Detect features
        ptsDistorted = NaN;
        switch detectPointsType
            case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
                ptsDistorted  = detectSURFFeatures(distorted,  'MetricThreshold', metricThreshold, 'NumOctaves', numOctaves, 'NumScaleLevels', numScaleLevels);
            case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
                ptsDistorted  = detectMSERFeatures(distorted, 'ThresholdDelta', thresholdDelta, 'RegionAreaRange', regionAreaRange, 'MaxAreaVariation', maxAreaVariation);
            case 'Corners: Harris-Stephens algorithm'
                ptsDistorted  = detectHarrisFeatures(distorted, 'MinQuality', minQuality, 'FilterSize', filterSize);
            case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
                ptsDistorted  = detectBRISKFeatures(distorted, 'MinContrast', minContrast, 'MinQuality', minQuality, 'NumOctaves', numOctaves);
            case 'Corners: Features from Accelerated Segment Test (FAST)'
                ptsDistorted  = detectFASTFeatures(distorted, 'MinQuality', minQuality, 'MinContrast', minContrast);
            case 'Corners: Minimum Eigenvalue algorithm'
                ptsDistorted  = detectMinEigenFeatures(distorted, 'MinQuality', minQuality, 'FilterSize', filterSize);
            case 'Oriented FAST and rotated BRIEF (ORB)'
                ptsDistorted  = detectORBFeatures(distorted, 'ScaleFactor', scaleFactor, 'NumLevels', numLevels);
        end

        % Extract feature descriptors.
        if ~strcmp(detectPointsType, 'Oriented FAST and rotated BRIEF (ORB)')
            [featuresList{layer}, validPtsList{layer}] = extractFeatures(distorted, ptsDistorted, 'Upright', rotationInvariance);
        else
            [featuresList{layer}, validPtsList{layer}] = extractFeatures(distorted, ptsDistorted);
        end
        % recalculate points to full resolution
        validPtsList{layer}.Location = validPtsList{layer}.Location / ratio;
        
        if showWaitbar && mod(layer, 10)==0; pw.increment(); end
    end

    for layer = 2:numFiles
        if showWaitbar; pw.updateText(sprintf('Step 2: matching the points\nPlease wait...')); end
        % Match features by using their descriptors.
        indexPairs = matchFeatures(featuresList{layer-1}, featuresList{layer});

        % Retrieve locations of corresponding points for each image.
        matchedOriginal  = validPtsList{layer-1}(indexPairs(:,1));
        matchedDistorted = validPtsList{layer}(indexPairs(:,2));

        if size(matchedOriginal, 1) < 3
            warndlg(sprintf('!!! Warning !!!\n\nThe number of detected points is not enough (slice number: %d) for the alignement\ntry to change the point detection settings to produce more points', layer-1));
            if showWaitbar; pw.delete(); end
            notify(obj.mibModel, 'stopProtocol');
            return;
        end

        % Show putative point matches.
        %                     figure;
        %                     matchedOriginalTemp = matchedOriginal;
        %                     matchedOriginalTemp.Location = matchedOriginalTemp.Location * ratio;
        %                     matchedDistortedTemp = matchedDistorted;
        %                     matchedDistortedTemp.Location = matchedDistortedTemp.Location * ratio;
        %                     showMatchedFeatures(original,distorted,matchedOriginalTemp,matchedDistortedTemp);
        %                     title('Putatively matched points (including outliers)');

        % Find a transformation corresponding to the matching point pairs using the
        % statistically robust M-estimator SAmple Consensus (MSAC) algorithm, which
        % is a variant of the RANSAC algorithm. It removes outliers while computing
        % the transformation matrix. You may see varying results of the transformation
        % computation because of the random sampling employed by the MSAC algorithm.
        %[tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
        %    matchedDistorted, matchedOriginal, parameters.TransformationType);

        [tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
            matchedDistorted, matchedOriginal, parameters.TransformationType, ...,
            'MaxNumTrials', obj.automaticOptions.estGeomTransform.MaxNumTrials, ...
            'Confidence', obj.automaticOptions.estGeomTransform.Confidence, ...
            'MaxDistance', obj.automaticOptions.estGeomTransform.MaxDistance);

%         [tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
%             matchedDistorted, matchedOriginal, 'rigid', ...,
%             'MaxNumTrials', obj.automaticOptions.estGeomTransform.MaxNumTrials, ...
%             'Confidence', obj.automaticOptions.estGeomTransform.Confidence, ...
%             'MaxDistance', obj.automaticOptions.estGeomTransform.MaxDistance);

%         [tform,inlierIndex, status] = estgeotform2d(matchedDistorted,matchedOriginal,parameters.TransformationType, ...
%             'MaxNumTrials', obj.automaticOptions.estGeomTransform.MaxNumTrials, ...
%             'Confidence', obj.automaticOptions.estGeomTransform.Confidence, ...
%             'MaxDistance', obj.automaticOptions.estGeomTransform.MaxDistance);


        % recalculate transformations
        % https://se.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html
        if isempty(tformMatrix{layer})
            tformMatrix(layer:end) = {tform};
        else
            tform.T = tform.T*tformMatrix{layer}.T;
            tformMatrix(layer:end) = {tform};
        end
        
        if showWaitbar && mod(layer, 10)==0; pw.increment(); end
    end
    toc(tt1)

    % ----------------------------------------------
    % correct drifts with running average filtering
    % ----------------------------------------------
    vec_length = numel(tformMatrix);
    x_stretch = arrayfun(@(objId) tformMatrix{objId}.T(1,1), 1:vec_length);
    y_stretch = arrayfun(@(objId) tformMatrix{objId}.T(2,2), 1:vec_length);
    x_shear = arrayfun(@(objId) tformMatrix{objId}.T(2,1), 1:vec_length);
    y_shear = arrayfun(@(objId) tformMatrix{objId}.T(1,2), 1:vec_length);

    fixDrifts2 = '';
    if parameters.useBatchMode == 0
        figure(125)
        subplot(2,1,1)
        plot(1:vec_length, x_stretch, 1:vec_length, y_stretch);
        title('Scaling');
        legend('x-axis','y-axis');
        subplot(2,1,2)
        plot(1:vec_length, x_shear, 1:vec_length, y_shear);
        title('Shear');
        legend('x-axis','y-axis');

        fixDrifts2 = questdlg('Align the stack using detected displacements?','Fix drifts', 'Yes', 'Subtract running average', 'Quit alignment', 'Yes');
        if strcmp(fixDrifts2, 'Quit alignment')
            if isdeployed == 0
                assignin('base', 'tformMatrix', tformMatrix);
                fprintf('Transformation matrix (tformMatrix) was exported to the Matlab workspace\nIt can be modified and saved to disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'');\n');
            end
            if showWaitbar; pw.delete(); end
            return;
        elseif strcmp(fixDrifts2, 'Yes')
            obj.BatchOpt.SubtractRunningAverage = 0;
        end

        if floor(numFiles/2-1) > 25
            halfWidthDefault = '25';
        else
            halfWidthDefault = num2str(floor(numFiles/2-1));
        end
        prompts = {'Fix stretching'; 'Fix shear'; 'Half-width of the averaging window'; 'Exclude stretch peaks higher than this value from the running average:'; 'Exclude shear peaks higher than this value from the running average:'};
        defAns = {true; true; halfWidthDefault; obj.BatchOpt.SubtractRunningAverageExcludeStretchPeaks; obj.BatchOpt.SubtractRunningAverageExcludeShearPeaks};
        dlgTitle = 'Correction settings';
        options.Title = 'Please select suitable settings for the correction';
        options.PromptLines = [1, 1, 1, 2, 2];
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
                    if showWaitbar; pw.delete(); end
                    return;
                end
                obj.BatchOpt.SubtractRunningAverageFixStretch = logical(answer{1});
                obj.BatchOpt.SubtractRunningAverageFixShear = logical(answer{2});
                halfwidth = str2double(answer{3});
                excludeStretchPeaks = str2double(answer{4});
                obj.BatchOpt.SubtractRunningAverageExcludeStretchPeaks = answer{4};
                excludeShearPeaks = str2double(answer{5});
                obj.BatchOpt.SubtractRunningAverageExcludeShearPeaks = answer{5};
            else
                halfwidth = str2double(obj.BatchOpt.SubtractRunningAverageStep);
                excludeStretchPeaks = str2double(obj.BatchOpt.SubtractRunningAverageExcludeStretchPeaks);
                excludeShearPeaks = str2double(obj.BatchOpt.SubtractRunningAverageExcludeShearPeaks);

                notOk = 0;
                if obj.BatchOpt.SubtractRunningAverage == 1
                    fixDrifts = 'Yes';
                end
            end

            if halfwidth > floor(numFiles/2-1)
                questdlg(sprintf('!!! Error !!!\n\nThe half-width should be smaller than the half depth of the dataset (%d) of the dataset!', floor(numFiles/2-1)), 'Wrong half-width', 'Try again', 'Try again');
                continue;
            end

            if obj.BatchOpt.SubtractRunningAverageFixStretch
                % fixing the stretching
                x_stretch2 = mibRunningAverageSmoothPoints(x_stretch, halfwidth, excludeStretchPeaks) + 1; % stretch should be 1 when no changes
                y_stretch2 = mibRunningAverageSmoothPoints(y_stretch, halfwidth, excludeStretchPeaks) + 1;
            else
                x_stretch2 = x_stretch;
                y_stretch2 = y_stretch;
            end

            if obj.BatchOpt.SubtractRunningAverageFixShear
                % fixing the shear
                x_shear2 = mibRunningAverageSmoothPoints(x_shear, halfwidth, excludeShearPeaks); % shear should be 0 when no changes
                y_shear2 = mibRunningAverageSmoothPoints(y_shear, halfwidth, excludeShearPeaks);
            else
                x_shear2 = x_shear;
                y_shear2 = y_shear;
            end

            if parameters.useBatchMode == 0
                figure(125)
                subplot(2,1,1)
                plot(1:vec_length, x_stretch2, 1:vec_length, y_stretch2);
                title('Scaling, fixed');
                legend('x-axis','y-axis');
                subplot(2,1,2)
                plot(1:vec_length, x_shear2, 1:vec_length, y_shear2);
                title('Shear, fixed');
                legend('x-axis','y-axis');

                fixDrifts = questdlg('Align the stack using detected displacements?', 'Fix drifts', 'Yes', 'Change window size', 'Quit alignment', 'Yes');
                if strcmp(fixDrifts, 'Quit alignment')
                    if isdeployed == 0
                        assignin('base', 'tformMatrix', tformMatrix);
                        fprintf('Transformation matrix (tformMatrix) was exported to the Matlab workspace\nIt can be modified and saved to disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'');\n');
                    end
                    if showWaitbar; pw.delete(); end
                    return;
                end
                obj.BatchOpt.SubtractRunningAverage = true;
                obj.BatchOpt.SubtractRunningAverageStep = num2str(halfwidth);
            end

            if strcmp(fixDrifts, 'Yes')
                for i=2:vec_length
                    tformMatrix{i}.T(1,1) = x_stretch2(i);
                    tformMatrix{i}.T(2,2) = y_stretch2(i);
                    tformMatrix{i}.T(2,1) = x_shear2(i);
                    tformMatrix{i}.T(1,2) = y_shear2(i);
                end
                notOk = 0;
            else
                defAns = {obj.BatchOpt.SubtractRunningAverageFixStretch; obj.BatchOpt.SubtractRunningAverageFixShear; halfwidth; obj.BatchOpt.SubtractRunningAverageExcludeStretchPeaks; obj.BatchOpt.SubtractRunningAverageExcludeShearPeaks};
            end
        end
    end
else
    if parameters.useBatchMode == 1
        fn = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
        [obj.pathstr, name, ext] = fileparts(fn);
        fn = fullfile(obj.pathstr, [name '_align.coefXY']);
    else
        fn = obj.View.handles.loadShiftsXYpath.String;
    end
    load(fn, '-mat'); % Load these veriables: 'tformMatrix', 'rbMatrix', 'heightVec', 'widthVec'
end
% ----------------------------------------------
% start the transformation procedure
% ----------------------------------------------
if showWaitbar; pw.updateText(sprintf('Step 3: Align datasets\nPlease wait...')); end
imgDS.reset(); % reset image datastore

% create output directory
outputDir = fullfile(obj.BatchOpt.HDD_InputDir, obj.BatchOpt.HDD_OutputSubfolderName);
if ~isfolder(outputDir); mkdir(outputDir); end

% settings for saving images
saveImageOptions.showWaitbar = false;
switch obj.BatchOpt.HDD_OutputFileExtension{1}
    case 'AM'
        saveImageOptions.Format = 'Amira Mesh binary (*.am)';
    case 'JPG'
        saveImageOptions.Format = 'Joint Photographic Experts Group (*.jpg)';
    case 'MRC'
        saveImageOptions.Format = 'MRC format for IMOD (*.mrc)';
    case 'NRRD'
        saveImageOptions.Format = 'NRRD Data Format (*.nrrd)';
    case 'PNG'
        saveImageOptions.Format = 'Portable Network Graphics (*.png)';
    case 'TIF'
        saveImageOptions.Format = 'TIF format uncompressed (*.tif)';
end

% prepare variables for parfor
HDD_OutputSubfolderName = obj.BatchOpt.HDD_OutputSubfolderName;
HDD_OutputFileExtension = obj.BatchOpt.HDD_OutputFileExtension{1};

if strcmp(parameters.TransformationMode, 'cropped') == 1    % the cropped view, faster and take less memory
    % update dimensions
    Height = heightVec(1);
    Width = widthVec(1);
    refImgSize = imref2d([Height, Width]);  % reference image size

    parfor (layer=1:numFiles, parforArg)
    %for layer=1:numFiles
        if ~isempty(tformMatrix{layer})
            [imgIn, fileinfo] = readimage(imgDS, layer);

            [iMatrix, rbMatrix{layer}] = imwarp(imgIn, tformMatrix{layer}, 'cubic', 'OutputView', refImgSize, 'FillValues', double(backgroundColor));

            % saving results
            [pathIn, filenameIn, extIn] = fileparts(fileinfo.Filename);
            fnOut = fullfile(pathIn, HDD_OutputSubfolderName, [filenameIn lower(['.' HDD_OutputFileExtension])]);
            mibImg = mibImage(iMatrix);
            mibImg.saveImageAsDialog(fnOut, saveImageOptions);
        end
        if showWaitbar && mod(layer, 10)==0; pw.increment(); end
    end
else  % the extended view
    % update dimensions
    Height = max(heightVec);
    Width = max(widthVec);
    refImgSize = imref2d([Height, Width]);  % reference image size
    rbMatrix(1:numFiles) = {refImgSize};

    for layer=1:numFiles
        rbMatrix{layer} = affineOutputView([Height Width], tformMatrix{layer}, "BoundsStyle", "CenterOutput");
        %rbMatrix{layer} = affineOutputView([Height Width], tformMatrix{layer}, "BoundsStyle", "FollowOutput");
        %rbMatrix{layer} = affineOutputView([heightVec(layer) widthVec(layer)], tformMatrix{layer}, "BoundsStyle", "FollowOutput");
        %rbMatrix{layer} = affineOutputView([heightVec(layer) widthVec(layer)], tformMatrix{layer}, "BoundsStyle", "CenterOutput");
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
    nWidth = max(xmax)-min(xmin) + abs(dx);
    nHeight = max(ymax)-min(ymin) + abs(dy);

    parfor (layer=1:numel(rbMatrix), parforArg)
    %for layer=1:numel(rbMatrix)
        %x1 = xmin(layer)-dx+1;
        rbMatrix{layer}.XWorldLimits = rbMatrix{layer}.XWorldLimits - ceil((max(widthVec)-min(widthVec))/2) - dx*2; % - x1;
        %x2 = x1 + rbMatrix{layer}.ImageSize(2)-1;
        %y1 = ymin(layer)-dy+1;
        %rbMatrix{layer}.YWorldLimits = rbMatrix{layer}.YWorldLimits - y1; % - ceil(heightVec(layer)/2);
        rbMatrix{layer}.YWorldLimits = rbMatrix{layer}.YWorldLimits - (max(heightVec)-min(heightVec)) - dy; % - ceil(heightVec(layer)/2) + ymin(layer);
        %y2 = y1 + rbMatrix{layer}.ImageSize(1)-1;
        %Iout(y1:y2,x1:x2,:,layer) = iMatrix{layer};
        rbMatrix{layer}.ImageSize = [nHeight nWidth];

        [imgIn, fileinfo] = readimage(imgDS, layer);
        iMatrix = imwarp(imgIn, tformMatrix{layer}, 'cubic', 'OutputView', rbMatrix{layer}, 'FillValues', double(backgroundColor));

        % saving results
        [pathIn, filenameIn, extIn] = fileparts(fileinfo.Filename);
        fnOut = fullfile(pathIn, HDD_OutputSubfolderName, [filenameIn lower(['.' HDD_OutputFileExtension])]);
        mibImg = mibImage(iMatrix);
        mibImg.saveImageAsDialog(fnOut, saveImageOptions);
        
        if showWaitbar && mod(layer, 10)==0; pw.increment(); end
    end
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
    save(fn, 'tformMatrix', 'rbMatrix', 'heightVec', 'widthVec');
    fprintf('alignment: tformMatrix and rbMatrix were saved to a file:\n%s\n', fn);
end

if ~isdeployed
    assignin('base', 'rbMatrix', rbMatrix);
    assignin('base', 'tformMatrix', tformMatrix);
    fprintf('Transform matrix (tformMatrix) and reference 2-D image to world coordinates (rbMatrix) were exported to the Matlab workspace (tformMatrix)\nThese variables can be modified and saved to a disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'', ''rbMatrix'');\n');
end

% if loadShifts == 0
%     logText = sprintf('Aligned using %s; relative to %d, type=%s, mode=%s, points=%s, imgWidth=%d, rotation=%d', parameters.method, parameters.refFrame, parameters.TransformationType, parameters.TransformationMode, parameters.detectPointsType, parameters.imgWidthForAnalysis, 1-obj.automaticOptions.rotationInvariance);
%     if strcmp(fixDrifts2, 'Subtract running average')
%         logText = sprintf('%s, runaverage:%d, fixstretch:%d fix-shear:%d', logText, halfwidth, answer{1}, answer{2});
%     end
% else
%     logText = sprintf('Aligned using %s', obj.View.handles.loadShiftsXYpath.String);
% end
% obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(logText);

if showWaitbar; pw.delete(); end

finalTime = toc(timerStart);
fprintf('Alignement total time: %f seconds\n', finalTime);


% for batch need to generate an event and send the BatchOptLoc
% structure with it to the macro recorder / mibBatchController
obj.returnBatchOpt(obj.BatchOpt);

%if parameters.useBatchMode == 0; obj.closeWindow(); end

end