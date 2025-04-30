function AutomaticFeatureBasedAlignmentV2(obj, parameters)
% function AutomaticFeatureBasedAlignmentV2(obj, parameters)Frangi
% perform automatic alignment based on detected features
%
% test of the updated function that is using estgeotform2d
% function available from R2022b
global mibPath;

optionsGetData.blockModeSwitch = 0;
[height, width, colors, Depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, optionsGetData);

% allocate space
pairwiseTforms = cell([Depth, 1]); % store all pairwise transformations
cumulativeTforms = cell([Depth, 1]); % Cumulative transformations relative to the first image
translations = zeros([Depth, 2]); % [tx, ty]
rotations = zeros([Depth, 1]);    % theta (for rigid, similarity)
scales = ones([Depth, 1]);        % s (for similarity, affine)
affine_params = zeros([Depth, 4]);     % [a, b, c, d] (for affine)
affine_params(:, [1 4]) = 1;
iMatrix = cell([Depth, 1]);      % cell array with transformed images
rbMatrix = cell([Depth, 1]);     % cell array with spatial referencing information associated with the transformed images

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
    if strcmp(parameters.backgroundColor,'black')
        backgroundColor = 0;
    elseif strcmp(parameters.backgroundColor,'white')
        backgroundColor = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
    else
        backgroundColor = mean(mean(cell2mat(obj.mibModel.getData2D('image', 1, NaN, parameters.colorCh, optionsGetData))));
    end
end

if obj.automaticOptions.imgWidthForAnalysis == 0
    parameters.imgWidthForAnalysis = width;
else
    parameters.imgWidthForAnalysis = obj.automaticOptions.imgWidthForAnalysis;  % resize image to this size to speed-up the process
end

if loadShifts == 0
    ratio = parameters.imgWidthForAnalysis/width;
    optionsGetData.blockModeSwitch = 0;
    original = cell2mat(obj.mibModel.getData2D('image', 1, 4, parameters.colorCh, optionsGetData));
    if ratio ~= 1; original = imresize(original, ratio, 'bicubic'); end  % resize if neeeded

    % detect feature-points
    ptsOriginal = mibAlignmentDetectFeatures(original, parameters.detectPointsType, obj.automaticOptions);

    % extract feature descriptors.
    if ~strcmp(parameters.detectPointsType, 'Oriented FAST and rotated BRIEF (ORB)')
        [featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal, 'Upright', obj.automaticOptions.rotationInvariance);
    else
        [featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal);
    end
    % recalculate points to full resolution
    validPtsOriginal.Location = validPtsOriginal.Location / ratio;

    for layer = 2:Depth
        distorted = cell2mat(obj.mibModel.getData2D('image', layer, 4, parameters.colorCh, optionsGetData));
        if ratio ~= 1; distorted = imresize(distorted, ratio, 'bicubic'); end % resize if needed

        % detect feature-points
        ptsDistorted = mibAlignmentDetectFeatures(distorted, parameters.detectPointsType, obj.automaticOptions);

        % Extract feature descriptors.
        if ~strcmp(parameters.detectPointsType, 'Oriented FAST and rotated BRIEF (ORB)')
            [featuresDistorted, validPtsDistorted] = extractFeatures(distorted, ptsDistorted, 'Upright', obj.automaticOptions.rotationInvariance);
        else
            [featuresDistorted, validPtsDistorted] = extractFeatures(distorted, ptsDistorted);
        end
        % recalculate points to full resolution
        validPtsDistorted.Location = validPtsDistorted.Location / ratio;

        % Match features by using their descriptors.
        indexPairs = matchFeatures(featuresOriginal, featuresDistorted);

        % % debug
        % figure(321);
        % % Retrieve locations of corresponding points for each image.
        % matchedOriginal  = validPtsOriginal(indexPairs(:,1));
        % matchedDistorted = validPtsDistorted(indexPairs(:,2));
        % showMatchedFeatures(original, distorted, matchedOriginal, matchedDistorted);
        % title('Putatively matched points (including outliers)');

        % Retrieve locations of corresponding points for each image.
        matchedOriginal  = validPtsOriginal(indexPairs(:,1));
        matchedDistorted = validPtsDistorted(indexPairs(:,2));

        if size(matchedOriginal, 1) < 3
            warndlg(sprintf('!!! Warning !!!\n\nThe number of detected points is not enough (slice number: %d) for the alignement\ntry to change the point detection settings to produce more points', layer-1));
            if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
            notify(obj.mibModel, 'stopProtocol');
            return;
        end

        % % Show putative point matches.
        % figure;
        % matchedOriginalTemp = matchedOriginal;
        % matchedOriginalTemp.Location = matchedOriginalTemp.Location * ratio;
        % matchedDistortedTemp = matchedDistorted;
        % matchedDistortedTemp.Location = matchedDistortedTemp.Location * ratio;
        % showMatchedFeatures(original,distorted,matchedOriginalTemp,matchedDistortedTemp);
        % title('Putatively matched points (including outliers)');

        % https://se.mathworks.com/help/images/migrate-geometric-transformations-to-premultiply-convention.html?requestedDomain=
        [tform, inlierIdx] = estgeotform2d(matchedDistorted, matchedOriginal, parameters.TransformationType, ...
            'MaxNumTrials', obj.automaticOptions.estGeomTransform.MaxNumTrials, ...
            'Confidence', obj.automaticOptions.estGeomTransform.Confidence, ...
            'MaxDistance', obj.automaticOptions.estGeomTransform.MaxDistance);
        
        pairwiseTforms{layer} = affinetform2d(tform.A);
        T = tform.A;

        % % debug preview
        % figure(1234);
        % showMatchedFeatures(original,distorted,matchedOriginal,matchedDistorted);
        % title("Matched Points");
        % figure(1235);
        % inlierPtsDistorted = matchedDistorted(inlierIdx,:);
        % inlierPtsOriginal  = matchedOriginal(inlierIdx,:);
        % showMatchedFeatures(original,distorted,inlierPtsOriginal,inlierPtsDistorted);
        % title("Removed outliers");

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

        % rearrange Distorted to Original
        featuresOriginal = featuresDistorted;
        validPtsOriginal = validPtsDistorted;

        if obj.BatchOpt.showWaitbar; waitbar(layer/(Depth*2), parameters.waitbar, sprintf('Step 1: matching the points\nPlease wait...')); end
    end
    
    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
    
    % ----------------------------------------------
    % correct drifts with running average filtering
    % ----------------------------------------------
    % Compute cumulative sums
    cumulativeTranslations = cumsum(translations, 1);
    cumulativeRotations = cumsum(rotations, 1);
    cumulativeScales = cumprod(scales, 1);
    % cumulativeAffineParams = cumsum(affine_params, 1); will not correct
    % affine, so commulative affines are not needed, but will show them as
    % plots
    
    fixDrifts2 = false;
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
        if floor(Depth/2-1) > 25
            halfWidthDefault = '25';
        else
            halfWidthDefault = num2str(floor(Depth/2-1));
        end

        hFig125 = figure(125);
        subplot(noRows, noCols, 1)
        plot(2:Depth, cumulativeTranslations(2:end, 1), '.-', 2:Depth, cumulativeTranslations(2:end, 2), '.-');
        title('Translation');
        legend('x-axis', 'y-axis', 'Location', 'best');
        grid;
        prompts = {'Half-width of the averaging window'; 'Fix translation'; 'Exclude jumps higher than:'};
        defAns = {halfWidthDefault; true; obj.BatchOpt.SubtractRunningAverageExcludeTranslationJumps};
        dlgTitle = 'Correction settings';
        %options.Title = 'Select suitable settings for the running average correction';
        options.PromptLines = [1, 1, 1];
        options.WindowWidth = 1;
        options.okBtnText = 'Continue';
        if ismember(parameters.TransformationType, {'rigid', 'similarity', 'affine'})
            subplot(noRows,noCols, 2)
            plot(2:Depth, cumulativeRotations(2:end), '.-');
            title('Rotations');
            grid;
            prompts = [prompts; {'Fix rotations'; 'Exclude jumps higher than:'}];
            defAns = [defAns; {true; obj.BatchOpt.SubtractRunningAverageExcludeRotationJumps}];
            options.PromptLines = [options.PromptLines, 1, 1];
        end
        if ismember(parameters.TransformationType, {'similarity', 'affine'})
            subplot(noRows,noCols, 3)
            plot(2:Depth, cumulativeScales(2:end), '.-');
            title('Scales');
            grid;
            prompts = [prompts; {'Fix scales'; 'Exclude jumps higher than:'}];
            defAns = [defAns; {true; obj.BatchOpt.SubtractRunningAverageExcludeScaleJumps}];
            options.PromptLines = [options.PromptLines, 1, 1];
        end
        if strcmp(parameters.TransformationType, 'affine')
            subplot(noRows,noCols, 5);
            plot(2:Depth, affine_params(2:end, 1), '.-');
            title('Affine a (scaling/shear/rotation, ~1)');
            grid;
            subplot(noRows,noCols, 6);
            plot(2:Depth, affine_params(2:end, 2), '.-');
            title('Affine b (shear/rotation, ~0)');
            grid;
            subplot(noRows,noCols, 7);
            plot(2:Depth, affine_params(2:end, 3), '.-');
            title('Affine c (shear/rotation, ~0)');
            grid;
            subplot(noRows,noCols, 8);
            plot(2:Depth, affine_params(2:end, 4), '.-');
            title('Affine d (scaling/shear/rotation, ~1)');
            grid;
        end
        mibQuestDlgOpt.ButtonWidth = [70 90 90];
        mibQuestDlgOpt.WindowHeight = 70;
        fixDriftsQuestion = mibQuestDlg({mibPath}, 'Align the stack using detected displacements?', ...
            {'Quit alignment'; 'Fix drifts'; 'Apply current values'}, 'Align dataset', mibQuestDlgOpt);
        if isempty(fixDriftsQuestion) || strcmp(fixDriftsQuestion, 'Quit alignment')
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

            if halfwidth > floor(Depth/2-1)
                questdlg(sprintf('!!! Error !!!\n\nThe half-width should be smaller than the half depth of the dataset (%d) of the dataset!', floor(Depth/2-1)), 'Wrong half-width', 'Try again', 'Try again');
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
                plot(2:Depth, smoothedTranslations(2:end, 1), '.-', 2:Depth, smoothedTranslations(2:end, 2), '.-');
                title('Translation');
                legend('x-axis', 'y-axis', 'Location', 'best');
                grid;
                if ismember(parameters.TransformationType, {'rigid', 'similarity', 'affine'})
                    subplot(noRows,noCols, 2)
                    plot(2:Depth, smoothedRotations(2:end), '.-');
                    title('Rotations');
                    grid;
                end
                if ismember(parameters.TransformationType, {'similarity', 'affine'})
                    subplot(noRows,noCols, 3)
                    plot(2:Depth, smoothedScales(2:end), '.-');
                    title('Scales');
                    grid;
                end
                if strcmp(parameters.TransformationType, 'affine')
                    subplot(noRows,noCols, 5);
                    plot(2:Depth, affine_params(2:end, 1), '.-');
                    title('Affine a (scaling/shear/rotation, ~1)');
                    grid;
                    subplot(noRows,noCols, 6);
                    plot(2:Depth, affine_params(2:end, 2), '.-');
                    title('Affine b (shear/rotation, ~0)');
                    grid;
                    subplot(noRows,noCols, 7);
                    plot(2:Depth, affine_params(2:end, 3), '.-');
                    title('Affine c (shear/rotation, ~0)');
                    grid;
                    subplot(noRows,noCols, 8);
                    plot(2:Depth, affine_params(2:end, 4), '.-');
                    title('Affine d (scaling/shear/rotation, ~1)');
                    grid;
                end
                
                fixDriftsQuestion2 = mibQuestDlg({mibPath}, 'Align the stack using detected displacements?', ...
                    {'Quit alignment'; 'Change window size'; 'Apply current values'}, 'Align dataset', mibQuestDlgOpt);
                if isempty(fixDriftsQuestion2) || strcmp(fixDriftsQuestion2, 'Quit alignment')
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

    if obj.BatchOpt.showWaitbar; parameters.waitbar = waitbar(0, sprintf('Step 2: Transforming images\nPlease wait...'), 'Name', 'Alignment and drift correction'); end

    % Regenerate cumulativeTforms
    cumulativeTforms{1} = affinetform2d(eye(3));
    for layer = 2:Depth
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
            if layer == Depth
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
    for i = 1:Depth
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

if strcmp(parameters.TransformationMode, 'cropped') == 1    % the cropped view, faster and take less memory
    for layer=1:Depth
        I = cell2mat(obj.mibModel.getData2D('image', layer, 4, NaN, optionsGetData));
        [iMatrix{layer}, rbMatrix{layer}] = imwarp(I, cumulativeTforms{layer}, 'cubic', 'OutputView', refImgSize, 'FillValues', double(backgroundColor));
        obj.mibModel.setData2D('image', iMatrix{layer}, layer, 4, NaN, optionsGetData);

        if obj.mibModel.preferences.System.EnableSelection == 1     % correct selection, model, mask layers
            if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
                I = cell2mat(obj.mibModel.getData2D('everything', layer, 4, NaN, optionsGetData));
                I = imwarp(I, cumulativeTforms{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                obj.mibModel.setData2D('everything', I, layer, 4, NaN, optionsGetData);
            else
                if obj.mibModel.getImageProperty('modelExist')
                    I = cell2mat(obj.mibModel.getData2D('model', layer, 4, NaN, optionsGetData));
                    I = imwarp(I, cumulativeTforms{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                    obj.mibModel.setData2D('model', I, layer, 4, NaN, optionsGetData);
                end
                if obj.mibModel.getImageProperty('maskExist')
                    I = cell2mat(obj.mibModel.getData2D('mask', layer, 4, NaN, optionsGetData));
                    I = imwarp(I, cumulativeTforms{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                    obj.mibModel.setData2D('mask', I, layer, 4, NaN, optionsGetData);
                end
                if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                    I = cell2mat(obj.mibModel.getData2D('selection', layer, 4, NaN, optionsGetData));
                    I = imwarp(I, cumulativeTforms{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                    obj.mibModel.setData2D('selection', I, layer, 4, NaN, optionsGetData);
                end
            end
        end

        % transform annotations
        [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer);
        if ~isempty(labelsList)
            [labelPositions(:,2), labelPositions(:,3)] = transformPointsForward(cumulativeTforms{layer}, labelPositions(:,2), labelPositions(:,3));
            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(indices, labelsList, labelPositions, labelValues);
        end
        %end
        if obj.BatchOpt.showWaitbar; waitbar((layer+Depth)/(Depth*2), parameters.waitbar, sprintf('Step 2: Align datasets\nPlease wait...')); end
    end
else  % the extended view
    for layer = 1:Depth
        I = cell2mat(obj.mibModel.getData2D('image', layer, 4, NaN, optionsGetData));
        if layer == 1
            Iout = zeros([refImgSize.ImageSize(1), refImgSize.ImageSize(2), size(I, 3), Depth], class(original)) + backgroundColor;
        end
        Iout(:,:,:,layer) = imwarp(I, cumulativeTforms{layer}, 'FillValues', backgroundColor, 'OutputView', refImgSize);

        % transform annotations
        [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer);
        if ~isempty(labelsList)
            [labelPositions(:, 2), labelPositions(:, 3)] = transformPointsForward(cumulativeTforms{layer}, labelPositions(:,2), labelPositions(:,3));
            labelPositions(:, 2) = labelPositions(:, 2) - minX; % shift X
            labelPositions(:, 3) = labelPositions(:, 3) - minY; % shift Y
            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(indices, labelsList, labelPositions, labelValues);
        end

        if obj.BatchOpt.showWaitbar; waitbar((layer+Depth)/(Depth*4), parameters.waitbar, sprintf('Step 2: Transforming images\nPlease wait...')); end
    end
    obj.mibModel.setData4D('image', Iout);

    % aligning the model
    if obj.mibModel.preferences.System.EnableSelection == 1
        if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
            Model = cell2mat(obj.mibModel.getData4D('everything', 4, NaN, optionsGetData));
            Iout = zeros([refImgSize.ImageSize(1), refImgSize.ImageSize(2), Depth], class(Model));
            for layer=1:Depth
                Iout(:,:,layer) = imwarp(Model(:,:,layer), cumulativeTforms{layer}, 'nearest', 'FillValues', 0, 'OutputView', refImgSize);
                if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed models\nPlease wait...')); end
            end
            obj.mibModel.setData4D('everything', Iout, NaN, NaN, optionsGetData);
        else
            % aligning the model layer
            if obj.mibModel.getImageProperty('modelExist')
                Model = cell2mat(obj.mibModel.getData4D('model', 4, NaN, optionsGetData));
                Iout = zeros([refImgSize.ImageSize(1), refImgSize.ImageSize(2), Depth], class(Model));
                for layer=1:Depth
                    Iout(:,:,layer) = imwarp(Model(:,:,layer), cumulativeTforms{layer}, 'nearest', 'FillValues', 0, 'OutputView', refImgSize);
                    if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed model\nPlease wait...')); end
                end
                obj.mibModel.setData4D('model', Iout, 4, NaN, optionsGetData);
            end
            % aligning the mask layer
            if obj.mibModel.getImageProperty('maskExist')
                Model = cell2mat(obj.mibModel.getData4D('mask', 4, NaN, optionsGetData));
                Iout = zeros([refImgSize.ImageSize(1), refImgSize.ImageSize(2), Depth], class(Model));
                for layer=1:Depth
                    Iout(:,:,layer) = imwarp(Model(:,:,layer), cumulativeTforms{layer}, 'nearest', 'FillValues', 0, 'OutputView', refImgSize);
                    if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed mask\nPlease wait...')); end
                end
                obj.mibModel.setData4D('mask', Iout, 4, NaN, optionsGetData);
            end
            % aligning the selection layer
            if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                Model = cell2mat(obj.mibModel.getData4D('selection', 4, NaN, optionsGetData));
                Iout = zeros([refImgSize.ImageSize(1), refImgSize.ImageSize(2), Depth], class(Model));
                for layer=1:Depth
                    Iout(:,:,layer) = imwarp(Model(:,:,layer), cumulativeTforms{layer}, 'nearest', 'FillValues', 0, 'OutputView', refImgSize);
                    if obj.BatchOpt.showWaitbar; waitbar((layer+Depth*3)/(Depth*4), parameters.waitbar, sprintf('Step 4: Assembling transformed selection\nPlease wait...')); end
                end
                obj.mibModel.setData4D('selection', Iout, 4, NaN, optionsGetData);
            end
        end
    end

    % calculate shift of the bounding box
    maxXshift = minX;   % maximal X shift in pixels vs the first slice
    maxYshift = minY;   % maximal Y shift in pixels vs the first slice
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

if loadShifts == 0
    logText = sprintf('Aligned using %s; relative to %d, type=%s, mode=%s, points=%s, imgWidth=%d, rotation=%d', parameters.method, parameters.refFrame, parameters.TransformationType, parameters.TransformationMode, parameters.detectPointsType, parameters.imgWidthForAnalysis, 1-obj.automaticOptions.rotationInvariance);
    if strcmp(fixDriftsQuestion, 'Fix drifts')
        logText = sprintf('%s, runaverage half-width:%d', logText, halfwidth);
    end
else
    logText = sprintf('Aligned using %s', obj.View.handles.loadShiftsXYpath.String);
end
obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(logText);

if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
notify(obj.mibModel, 'newDataset');
notify(obj.mibModel, 'plotImage');

% for batch need to generate an event and send the BatchOptLoc
% structure with it to the macro recorder / mibBatchController
obj.returnBatchOpt(obj.BatchOpt);

%if parameters.useBatchMode == 0; obj.closeWindow(); end
end
