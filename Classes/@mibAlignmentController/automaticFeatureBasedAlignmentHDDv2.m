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
% Date: 12.03.2025

function result = automaticFeatureBasedAlignmentHDDv2(obj, parameters)
% function result = automaticFeatureBasedAlignmentHDDv2(obj, parameters)
% perform automatic alignment based on detected features in HDD mode when
% images are processed on the hard drive without combining them all in MIB
% The updated version that is using estgeotform2d
%
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

qDlgOpt.ButtonWidth = [100 100];
answer = mibQuestDlg({mibPath}, sprintf('!!! Warning !!!\n\nBefore proceeding further please load the first image of the dataset into MIB!'), ...
    {'Stop to load the dataset', 'Yes it is already loaded'}, 'Warning', qDlgOpt);

% answer = questdlg(sprintf('!!! Warning !!!\n\nBefore proceeding further please load the first image of the dataset into MIB!'), ...
%     'Warning', ...
%     'Yes it is already loaded', 'Stop to load the dataset', 'Stop to load the dataset');
if isempty(answer) || strcmp(answer, 'Stop to load the dataset'); return; end

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
pairwiseTforms = cell([numFiles, 1]); % store all pairwise transformations
cumulativeTforms = cell([numFiles, 1]); % Cumulative transformations relative to the first image
translations = zeros([numFiles, 2]); % [tx, ty]
rotations = zeros([numFiles, 1]);    % theta (for rigid, similarity)
scales = ones([numFiles, 1]);        % s (for similarity, affine)
affine_params = zeros([numFiles, 4]);     % [a, b, c, d] (for affine)
affine_params(:, [1 4]) = 1;
iMatrix = cell([numFiles, 1]);      % cell array with transformed images
rbMatrix = cell([numFiles, 1]);     % cell array with spatial referencing information associated with the transformed images

loadShifts = 0;
if parameters.useBatchMode == 0
    if obj.View.handles.loadShiftsCheck.Value == 1
        pairwiseTforms = obj.shiftsX.pairwiseTforms;
        cumulativeTforms = obj.shiftsX.cumulativeTforms;
        translations = obj.shiftsX.translations;
        rotations = obj.shiftsX.rotations;
        scales = obj.shiftsX.scales;
        affine_params = obj.shiftsX.affine_params;
        rbMatrix = obj.shiftsX.rbMatrix;

        loadShifts = 1;
    end
end

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
[height, width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, optionsGetData);

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

parameters.imgDownsamplingFactor = obj.automaticOptions.imgDownsamplingFactorForAnalysis;

if loadShifts == 0
    if showWaitbar; pw.updateText(sprintf('Step 1: detecting features\nPlease wait...')); end
    
    ratio = 1/parameters.imgDownsamplingFactor;
    %original = cell2mat(obj.mibModel.getData2D('image', 1, 4, parameters.colorCh, optionsGetData));
    %[heightVec(1), widthVec(1), colorsVec(1)]  = size(original);
    
    tt1 = tic;

    featuresList = repmat({}, [numFiles, 1]);
    validPtsList = repmat({}, [numFiles, 1]);
    
    colorCh = parameters.colorCh;
    detectPointsType = parameters.detectPointsType;
    automaticOptions = obj.automaticOptions;
    rotationInvariance = obj.automaticOptions.rotationInvariance;

    parfor (layer = 1:numFiles, parforArg)
        distorted = readimage(imgDS, layer);
        [heightVec(layer), widthVec(layer), colorsVec(layer)]  = size(distorted);

        % extrct color channel to use
        if size(distorted, 3) > 1; distorted = distorted(:, :, colorCh); end
        
        % resize if needed
        if ratio ~= 1; distorted = imresize(distorted, ratio, 'bicubic'); end

        % detect feature-points
        ptsDistorted = mibAlignmentDetectFeatures(distorted, detectPointsType, automaticOptions);

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

        % https://se.mathworks.com/help/images/migrate-geometric-transformations-to-premultiply-convention.html?requestedDomain=
        [tform, inlierIdx] = estgeotform2d(matchedDistorted, matchedOriginal, parameters.TransformationType, ...
            'MaxNumTrials', obj.automaticOptions.estGeomTransform.MaxNumTrials, ...
            'Confidence', obj.automaticOptions.estGeomTransform.Confidence, ...
            'MaxDistance', obj.automaticOptions.estGeomTransform.MaxDistance);

        pairwiseTforms{layer} = affinetform2d(tform.A);
        T = tform.A;

        % T = [ a,  b,  tx ]
        %     [ c,  d,  ty ]
        %     [ 0,  0,   1 ]
        % the top-left 2x2 block ([a, b; c, d]) handles scaling, rotation, and shear
        % the third column ([tx, ty]) handles translation.
        % the last row is always [0, 0, 1] for 2D transformations
        %
        % TRANSLATION:
        % T = [ 1,  0,  tx ]
        %     [ 0,  1,  ty ]
        %     [ 0,  0,   1 ]
        % where
        % T(1,1) = a = 1: No scaling or rotation (identity)
        % T(1,2) = b = 0: No shear or rotation
        % T(2,1) = c = 0: No shear or rotation
        % T(2,2) = d = 1: No scaling or rotation (identity)
        % T(1,3) = tx: Translation in x-direction
        % T(2,3) = ty: Translation in y-direction
        %
        % RIGID (preserves distances and angles (rotation + translation, no scaling))
        % T = [ cos(θ), -sin(θ),  tx ]
        %     [ sin(θ),  cos(θ),  ty ]
        %     [      0,       0,   1 ]
        % where
        % T(1,1) = a = cos(θ): Cosine of rotation angle.
        % T(1,2) = b = -sin(θ): Negative sine of rotation angle.
        % T(2,1) = c = sin(θ): Sine of rotation angle.
        % T(2,2) = d = cos(θ): Cosine of rotation angle.
        %
        % SIMILARITY (preserves angles (rotation + uniform scaling + translation))
        %   T = [ s*cos(θ), -s*sin(θ),  tx ]
        %       [ s*sin(θ),  s*cos(θ),  ty ]
        %       [        0,         0,   1 ]
        % where
        % T(1,1) = a = s * cos(θ): Scale times cosine of rotation angle.
        % T(1,2) = b = -s * sin(θ): Negative scale times sine of rotation angle.
        % T(2,1) = c = s * sin(θ): Scale times sine of rotation angle.
        % T(2,2) = d = s * cos(θ): Scale times cosine of rotation angle.
        %
        % AFFINE (full affine transformation (scaling, rotation, shear, translation))
        % T = [ a,  b,  tx ]
        %     [ c,  d,  ty ]
        %     [ 0,  0,   1 ]
        % T(1,1) = a: General scaling/shear/rotation component (diagonal ~1 for identity-like).
        % T(1,2) = b: Shear/rotation component (off-diagonal ~0 for identity-like).
        % T(2,1) = c: Shear/rotation component (off-diagonal ~0 for identity-like).
        % T(2,2) = d: General scaling/shear/rotation component (diagonal ~1 for identity-like).

        translations(layer, :) = [T(1, 3), T(2, 3)];
        if ismember(parameters.TransformationType, {'rigid', 'similarity', 'affine'})
            rotations(layer) = atan2(T(2, 1), T(1, 1));
        end
        if ismember(parameters.TransformationType, {'similarity', 'affine'})
            scales(layer) = sqrt(T(1, 1)^2 + T(2, 1)^2);
        end
        if strcmp(parameters.TransformationType, 'affine')
            affine_params(layer, :) = [T(1, 1), T(1, 2), T(2, 1), T(2, 2)];
        end
        
        if showWaitbar && mod(layer, 10)==0; pw.increment(); end
    end
    toc(tt1)

    % ----------------------------------------------
    % correct drifts with running average filtering
    % ----------------------------------------------
    % Compute cumulative sums
    cumulativeTranslations = cumsum(translations, 1);
    cumulativeRotations = cumsum(rotations, 1);
    cumulativeScales = cumprod(scales, 1);
    % cumulativeAffineParams = cumsum(affine_params, 1); will not correct
    % affine, so commulative affines are not needed, but will show them as plots

    fixDrifts2 = '';
    if parameters.useBatchMode == 0
        % define parameters for plots
        switch parameters.TransformationType
            case 'translation'
                noRows = 1;
                noCols = 1;
            case 'rigid'
                noRows = 1;
                noCols = 2;
            case 'similarity'
                noRows = 1;
                noCols = 3;
            case 'affine'
                noRows = 2;
                noCols = 4;
        end

        obj.BatchOpt.SubtractRunningAverageExcludeTranslationJumps = 0;
        obj.BatchOpt.SubtractRunningAverageExcludeRotationJumps = 0;
        obj.BatchOpt.SubtractRunningAverageExcludeScaleJumps = 0;

        % generate default halfWidth
        if floor(numFiles/2-1) > 25
            halfWidthDefault = '25';
        else
            halfWidthDefault = num2str(floor(numFiles/2-1));
        end

        hFig125 = figure(125);
        subplot(noRows, noCols, 1)
        plot(2:numFiles, cumulativeTranslations(2:end, 1), '.-', 2:numFiles, cumulativeTranslations(2:end, 2), '.-');
        title('Translation');
        grid;
        legend('x-axis', 'y-axis', 'Location', 'best');
        prompts = {'Half-width of the averaging window'; 'Fix translation'; 'Exclude jumps higher than:'};
        defAns = {halfWidthDefault; true; obj.BatchOpt.SubtractRunningAverageExcludeTranslationJumps};
        dlgTitle = 'Correction settings';
        %options.Title = 'Select suitable settings for the running average correction';
        options.PromptLines = [1, 1, 1];
        options.WindowWidth = 1;
        options.okBtnText = 'Continue';
        if ismember(parameters.TransformationType, {'rigid', 'similarity', 'affine'})
            subplot(noRows,noCols, 2)
            plot(2:numFiles, cumulativeRotations(2:end), '.-');
            title('Rotations');
            grid;
            prompts = [prompts; {'Fix rotations'; 'Exclude jumps higher than:'}];
            defAns = [defAns; {true; obj.BatchOpt.SubtractRunningAverageExcludeRotationJumps}];
            options.PromptLines = [options.PromptLines, 1, 1];
        end
        if ismember(parameters.TransformationType, {'similarity', 'affine'})
            subplot(noRows,noCols, 3)
            plot(2:numFiles, cumulativeScales(2:end), '.-');
            title('Scales');
            grid;
            prompts = [prompts; {'Fix scales'; 'Exclude jumps higher than:'}];
            defAns = [defAns; {true; obj.BatchOpt.SubtractRunningAverageExcludeScaleJumps}];
            options.PromptLines = [options.PromptLines, 1, 1];
        end
        if strcmp(parameters.TransformationType, 'affine')
            subplot(noRows,noCols, 5);
            plot(2:numFiles, affine_params(2:end, 1), '.-');
            title('Affine a (scaling/shear/rotation, ~1)');
            grid;
            subplot(noRows,noCols, 6);
            plot(2:numFiles, affine_params(2:end, 2), '.-');
            title('Affine b (shear/rotation, ~0)');
            grid;
            subplot(noRows,noCols, 7);
            plot(2:numFiles, affine_params(2:end, 3), '.-');
            title('Affine c (shear/rotation, ~0)');
            grid;
            subplot(noRows,noCols, 8);
            plot(2:numFiles, affine_params(2:end, 4), '.-');
            title('Affine d (scaling/shear/rotation, ~1)');
            grid;
        end
        mibQuestDlgOpt.ButtonWidth = [70 90 90];
        mibQuestDlgOpt.WindowHeight = 70;
        fixDriftsQuestion = mibQuestDlg({mibPath}, 'Align the stack using detected displacements?', ...
            {'Quit alignment'; 'Fix drifts'; 'Apply current values'}, 'Align dataset', mibQuestDlgOpt);
        if isempty(fixDriftsQuestion) || strcmp(fixDriftsQuestion, 'Quit alignment')
            if showWaitbar; pw.delete(); end
            return;
        end
    end

    fixTranslation = false;
    fixRotation = false;
    fixScale = false;
    exludeTranslationJumps = [];
    exludeRotationJumps = [];
    exludeScaleJumps = [];
  
    if strcmp(fixDriftsQuestion, 'Fix drifts') || obj.BatchOpt.SubtractRunningAverage == 1
        notOk = 1;
        while notOk
            if parameters.useBatchMode == 0
                [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer)
                    %if isdeployed == 0
                    %assignin('base', 'tformMatrix', tformMatrix);
                    %fprintf('Transformation matrix (tformMatrix) was exported to the Matlab workspace\nIt can be modified and saved to disk using the following command:\nsave(''myfile.mat'', ''tformMatrix'');\n');
                    %end
                    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                    return;
                end

                halfwidth = str2double(answer{1});
                obj.BatchOpt.SubtractRunningAverageFixTranslation = logical(answer{2});
                obj.BatchOpt.SubtractRunningAverageExcludeTranslationJumps = answer{3};
                fixTranslation = obj.BatchOpt.SubtractRunningAverageFixTranslation;
                exludeTranslationJumps = str2double(obj.BatchOpt.SubtractRunningAverageExcludeTranslationJumps);
                if numel(answer) > 3
                    obj.BatchOpt.SubtractRunningAverageFixRotation = logical(answer{4});
                    obj.BatchOpt.SubtractRunningAverageExcludeRotationJumps = answer{5};
                    fixRotation = obj.BatchOpt.SubtractRunningAverageFixRotation;
                    exludeRotationJumps = str2double(obj.BatchOpt.SubtractRunningAverageExcludeRotationJumps);
                end
                if numel(answer) > 5
                    obj.BatchOpt.SubtractRunningAverageFixScale = logical(answer{6});
                    obj.BatchOpt.SubtractRunningAverageExcludeScaleJumps = answer{7};
                    fixScale = obj.BatchOpt.SubtractRunningAverageFixScale;
                    exludeScaleJumps = str2double(obj.BatchOpt.SubtractRunningAverageExcludeScaleJumps);
                end
            else
                % halfwidth = str2double(obj.BatchOpt.SubtractRunningAverageStep);
                % exludeTranslationJumps = str2double(obj.BatchOpt.SubtractRunningAverageExcludeTranslationJumps);
                % exludeRotationJumps = str2double(obj.BatchOpt.SubtractRunningAverageExcludeRotationJumps);
                % exludeScaleJumps = str2double(obj.BatchOpt.SubtractRunningAverageExcludeScaleJumps);
                % exludeAffineJumps = str2double(obj.BatchOpt.SubtractRunningAverageExcludeAffineJumps);
                %
                % notOk = 0;
                % if obj.BatchOpt.SubtractRunningAverage == 1
                %     fixDrifts = true;
                % end
            end

            if halfwidth > floor(numFiles/2-1)
                questdlg(sprintf('!!! Error !!!\n\nThe half-width should be smaller than the half depth of the dataset (%d) of the dataset!', floor(numFiles/2-1)), 'Wrong half-width', 'Try again', 'Try again');
                continue;
            end

            smoothedTranslations = cumulativeTranslations;
            if fixTranslation
                smoothedTranslations(:, 1) = mibRunningAverageSmoothPoints(cumulativeTranslations(:, 1), halfwidth, exludeTranslationJumps);
                smoothedTranslations(:, 2) = mibRunningAverageSmoothPoints(cumulativeTranslations(:, 2), halfwidth, exludeTranslationJumps);

                % debug
                % figure(1212)
                % xVec = 1:size(cumulativeTranslations,1);
                % plot(xVec, cumulativeTranslations(:,1), xVec, smoothedTranslations(:,1), xVec, cumulativeTranslations(:,2), xVec, smoothedTranslations(:,2));
                % legend('X orig', 'X smoothed', 'Y orig', 'Y smoothed');
            end

            smoothedRotations = cumulativeRotations;
            if fixRotation
                smoothedRotations = mibRunningAverageSmoothPoints(cumulativeRotations, halfwidth, exludeRotationJumps);
            end

            smoothedScales = cumulativeScales;
            if fixScale
                smoothedScales = mibRunningAverageSmoothPoints(cumulativeScales, halfwidth, exludeScaleJumps) + 1; % Adjust scale to center around 1
            end
            
            if parameters.useBatchMode == 0
                hFig126 = figure(126);
                hFig126.Position = hFig125.Position;
                subplot(noRows, noCols, 1)
                plot(2:numFiles, smoothedTranslations(2:end, 1), '.-', 2:numFiles, smoothedTranslations(2:end, 2), '.-');
                title('Translation');
                grid;
                legend('x-axis', 'y-axis', 'Location', 'best');
                if ismember(parameters.TransformationType, {'rigid', 'similarity', 'affine'})
                    subplot(noRows,noCols, 2)
                    plot(2:numFiles, smoothedRotations(2:end), '.-');
                    title('Rotations');
                    grid;
                end
                if ismember(parameters.TransformationType, {'similarity', 'affine'})
                    subplot(noRows,noCols, 3)
                    plot(2:numFiles, smoothedScales(2:end), '.-');
                    title('Scales');
                    grid;
                end
                if strcmp(parameters.TransformationType, 'affine')
                    subplot(noRows,noCols, 5);
                    plot(2:numFiles, affine_params(2:end, 1), '.-');
                    title('Affine a (scaling/shear/rotation, ~1)');
                    grid;
                    subplot(noRows,noCols, 6);
                    plot(2:numFiles, affine_params(2:end, 2), '.-');
                    title('Affine b (shear/rotation, ~0)');
                    grid;
                    subplot(noRows,noCols, 7);
                    plot(2:numFiles, affine_params(2:end, 3), '.-');
                    title('Affine c (shear/rotation, ~0)');
                    grid;
                    subplot(noRows,noCols, 8);
                    plot(2:numFiles, affine_params(2:end, 4), '.-');
                    title('Affine d (scaling/shear/rotation, ~1)');
                    grid;
                end
                
                fixDriftsQuestion2 = mibQuestDlg({mibPath}, 'Align the stack using detected displacements?', ...
                    {'Quit alignment'; 'Change window size'; 'Apply current values'}, 'Align dataset', mibQuestDlgOpt);
                if isempty(fixDriftsQuestion2) || strcmp(fixDriftsQuestion2, 'Quit alignment')
                    if showWaitbar; pw.delete(); end
                    return;
                end

                %obj.BatchOpt.SubtractRunningAverage = true;
                obj.BatchOpt.SubtractRunningAverageStep = num2str(halfwidth);
            end

            if strcmp(fixDriftsQuestion2, 'Apply current values')
                cumulativeTranslations = smoothedTranslations;
                cumulativeRotations = smoothedRotations;
                cumulativeScales = smoothedScales;
                notOk = false;
            else
                defAns = answer;
            end
        end
    end

    % Regenerate cumulativeTforms
    cumulativeTforms{1} = affinetform2d(eye(3));
    for layer = 2:numFiles
        if strcmp(fixDriftsQuestion, 'Fix drifts') || obj.BatchOpt.SubtractRunningAverage == 1
            T_corrected = pairwiseTforms{layer}.A; % Start with pairwise matrix
            % Override translation with smoothed values
            T_corrected(1, 3) = cumulativeTranslations(layer, 1);
            T_corrected(2, 3) = cumulativeTranslations(layer, 2);

            % Optionally adjust rotation/scale for rigid/similarity
            if strcmp(parameters.TransformationType, 'rigid')
                theta = cumulativeRotations(layer);
                R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
                T_corrected(1:2, 1:2) = R;
            elseif strcmp(parameters.TransformationType, 'similarity') || strcmp(parameters.TransformationType, 'affine')
                theta = cumulativeRotations(layer);
                s = cumulativeScales(layer);
                R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
                T_corrected(1:2, 1:2) = s * R;
            end
            % For 'affine', keep the original 2x2 block, only smooth translations
        else
            T_corrected = pairwiseTforms{layer}.A * cumulativeTforms{layer-1}.A;
        end
        cumulativeTforms{layer} = affinetform2d(T_corrected);

        % % round translations, otherwise the images got resampled resulting in blurred results
        if strcmp(parameters.TransformationType, 'translation')
            cumulativeTforms{layer-1}.A(1,3) = round(cumulativeTforms{layer-1}.A(1,3));
            cumulativeTforms{layer-1}.A(2,3) = round(cumulativeTforms{layer-1}.A(2,3));
            if layer == numFiles
                cumulativeTforms{layer}.A(1,3) = round(cumulativeTforms{layer}.A(1,3));
                cumulativeTforms{layer}.A(2,3) = round(cumulativeTforms{layer}.A(2,3));
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
    load(fn, '-mat'); % Load these veriables: 'pairwiseTforms', 'cumulativeTforms', 'translations', 'rotations', 'scales', 'affine_params', 'rbMatrix'
end

% Determine output size and reference for warping
if strcmp(parameters.TransformationMode, 'extended')
    corners = [1, 1; width, 1; width, height; 1, height];
    allX = []; allY = [];
    for i = 1:numFiles
        tform = cumulativeTforms{i};
        transformedCorners = [corners, ones(4, 1)] * tform.A';
        allX = [allX; transformedCorners(:, 1)];
        allY = [allY; transformedCorners(:, 2)];
    end
    minX = floor(min(allX)); maxX = ceil(max(allX));
    minY = floor(min(allY)); maxY = ceil(max(allY));
    outputWidth = maxX - minX + 1;
    outputHeight = maxY - minY + 1;
    refImgSize = imref2d([outputHeight, outputWidth], [minX, maxX], [minY, maxY]);
else % 'cropped'
    refImgSize = imref2d([height, width]);
    minX = 0;
    minY = 0;
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

parfor (layer=1:numFiles, parforArg)
    %for layer=1:numFiles
    [imgIn, fileinfo] = readimage(imgDS, layer);
    [iMatrix, rbMatrix{layer}] = imwarp(imgIn, cumulativeTforms{layer}, 'cubic', 'OutputView', refImgSize, 'FillValues', double(backgroundColor));

    % saving results
    [pathIn, filenameIn, extIn] = fileparts(fileinfo.Filename);
    fnOut = fullfile(pathIn, HDD_OutputSubfolderName, [filenameIn lower(['.' HDD_OutputFileExtension])]);
    mibImg = mibImage(iMatrix);
    mibImg.saveImageAsDialog(fnOut, saveImageOptions);

    if showWaitbar && mod(layer, 10)==0; pw.increment(); end
end
toc;

% generate structure for output
alignStruct = struct();
alignStruct.pairwiseTforms = pairwiseTforms;
alignStruct.cumulativeTforms = cumulativeTforms;
alignStruct.translations = translations;
alignStruct.rotations = rotations;
alignStruct.scales = scales;
alignStruct.affine_params = affine_params;
alignStruct.rbMatrix = rbMatrix;

if obj.BatchOpt.SaveShiftsToFile     % use save shifts to a file
    if parameters.useBatchMode == 1
        fn = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
        [obj.pathstr, name, ext] = fileparts(fn);
        fn = fullfile(obj.pathstr, [name '_align.coefXY']);
    else
        fn = obj.View.handles.saveShiftsXYpath.String;
    end
    save(fn, '-struct', 'alignStruct');
    fprintf('alignment: alignment parameters as structure ("alignStruct") were saved to a file:\n%s\n', fn);
end

if ~isdeployed
    assignin('base', 'alignStruct', alignStruct);
    fprintf('alignment: alignment parameters as structure ("alignStruct") were exported in the base MATLAB workspace\nThese variables can be modified and saved to a disk using the following command:\n ----->> save(''myfile.mat'', ''-struct'', ''alignStruct'');\n');
end
if showWaitbar; pw.delete(); end

finalTime = toc(timerStart);
fprintf('Alignement total time: %f seconds\n', finalTime);

% for batch need to generate an event and send the BatchOptLoc
% structure with it to the macro recorder / mibBatchController
obj.returnBatchOpt(obj.BatchOpt);

%if parameters.useBatchMode == 0; obj.closeWindow(); end

end