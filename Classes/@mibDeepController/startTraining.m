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

function startTraining(obj)
% function startTraining(obj)
% perform training of the network

global mibPath;
global counter;     % for patch test
global mibDeepStopTraining
global mibDeepTrainingProgressStruct

%obj.TrainEngine = 'trainNetwork'; % use this later as one of the parameters for main obj.BatchOpt
%obj.TrainEngine = 'trainnet'; % use this later as one of the parameters for main obj.BatchOpt
if  obj.mibController.matlabVersion < 24.1; obj.TrainEngine = 'trainNetwork'; end

counter = 1;
mibDeepTrainingProgressStruct.emergencyBrake = false;   % emergency brake without finishing the weights

if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
    preprocessedSwitch = false;

    if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
        msg = sprintf('!!! Warning !!!\nYou are going to start training without preprocessing!\nConfirm that your images located under\n\n%s\n\n%s\n%s\n\nImage patches needs to be arranged as each class inside its own directory', ...
            obj.BatchOpt.OriginalTrainingImagesDir, ...
            '- TrainImages', '- ValidationImages');
    else
        msg = sprintf('!!! Warning !!!\nYou are going to start training without preprocessing!\nConfirm that your images located under\n\n%s\n\n%s\n%s\n%s\n%s\n\nPlease also make sure that number of files with labels match number of files with images!', ...
            obj.BatchOpt.OriginalTrainingImagesDir, ...
            '- TrainImages', '- TrainLabels', ...
            '- ValidationImages', '- ValidationLabels');
    end

    selection = uiconfirm(obj.View.gui, ...
        msg, 'Preprocessing',...
        'Options',{'Confirm', 'Cancel'},...
        'DefaultOption',1,'CancelOption',2,...
        'Icon', 'warning');
    if strcmp(selection, 'Cancel'); return; end
else
    preprocessedSwitch = true;
    msg = sprintf('Have images for training were preprocessed?\n\nIf not, please switch to the Directories and Preprocessing tab and preprocess images for training');
    selection = uiconfirm(obj.View.gui, ...
        msg, 'Preprocessing',...
        'Options',{'Yes', 'No'},...
        'DefaultOption',1,'CancelOption',2);
    if strcmp(selection, 'No'); return; end
end

% Reset GPU
obj.selectGPUDevice();

%% Create Random Patch Extraction Datastore for Training
% create image data store
% obj.TrainingProgress = struct();
% obj.TrainingProgress.stopTraining = false;
% obj.TrainingProgress.emergencyBrake = false;

% check input patch size
inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize); %#ok<ST2NM>
if numel(inputPatchSize) ~= 4
    uialert(obj.View.gui, ...
        sprintf(['!!! Error !!!\n\n' ...
        'Please provide the input patch size (BatchOpt.T_InputPatchSize) as 4 numbers that define\n' ...
        'height, width, depth, colors\n\nFor example:\n' ...
        '"32, 32, 1, 3" for 2D U-net of 3 color channel images\n' ...
        '"64, 64, 64, 1" for 3D U-net of 1 color channel images']), ...
        'Wrong patch size');
    return;
end

%   check for rectangular shape of the input patch
if inputPatchSize(1)~=inputPatchSize(2) && obj.BatchOpt.T_augmentation
    if (strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D') && obj.AugOpt2D.Rotation90.Enable ) || ...
            (strcmp(obj.BatchOpt.Workflow{1}(1:2), '3D') && obj.AugOpt3D.Rotation90.Enable ) || ...
            (strcmp(obj.BatchOpt.Workflow{1}(1:2), '2.') && obj.AugOpt3D.Rotation90.Enable )
        uialert(obj.View.gui, ...
            sprintf(['!!! Error !!!\n\n' ...
            'Rotation augmentations are only implemented for input patches that have a square shape!\n\n' ...
            'How to fix (one of these options):\n   a) set probability of Rotation90 augmentations to 0\n' ...
            '   b) make sure that the input patch size has a square shape as "%d %d %d %d"\n' ...
            '   c)   if Rotation90 is required rotate the original dataset (images and labels) and save it as ' ...
            'additional files to be used for training'], ...
            inputPatchSize(1), inputPatchSize(1), inputPatchSize(3), inputPatchSize(4)), ...
            'Rotation90 is not available', 'Icon', 'error');
        return;
    end

end

% check input patch size for 2D Patch-wise workflow
if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
    if obj.mibController.matlabVersion < 9.13 && inputPatchSize(4) ~= 3
        % blockedImage function can not properly process
        % 1-single channel images in R2022a, hopefully be fixed
        % in R2022b
        uialert(obj.View.gui, ...
            sprintf(['!!! Warning !!!\n\n' ...
            '2D Patch-wise training requires a model with 3 color channels;\n' ...
            'the grayscale images are automatically converted to RGB during training and prediction\n\n' ...
            'Solve by:\n- change input patch size to: "%d %d %d 3" '], ...
            inputPatchSize(1), inputPatchSize(2), inputPatchSize(3)), ...
            'Wrong configuration', 'Icon', 'warning');
        return;
    end
end

% fix the 3rd value in the input patch size for 2D networks
if strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D') && inputPatchSize(3) > 1
    inputPatchSize(3) = 1;
    obj.BatchOpt.T_InputPatchSize = num2str(inputPatchSize);
    obj.View.handles.T_InputPatchSize.Value = obj.BatchOpt.T_InputPatchSize;
end

% check whether it is needed to continue the previous training
% or start a new one
checkPointRestoreFile = '';     % selected FULL filename for the network restore
checkPointFiles = {'Start new training'};  % place maker for the checkpoint networks

if exist(obj.BatchOpt.NetworkFilename, 'file') == 2
    [~, currentNetFile, netExt] = fileparts(obj.BatchOpt.NetworkFilename);
    currentNetFile = {[currentNetFile netExt]};     % already existing network
    checkPointFiles = [checkPointFiles, currentNetFile];
end

if obj.BatchOpt.T_SaveProgress  % checkpoint networks
    warning('off', 'MATLAB:MKDIR:DirectoryExists');
    mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork'));
end

if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork'))
    progressFiles = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.mat'));
    if ~isempty(progressFiles)
        [~, idx]=sort([progressFiles.datenum], 'descend');      % sort in time order
        checkPointFiles = [checkPointFiles {progressFiles(idx).name}];
    end
end

if numel(checkPointFiles) > 1
    prompts = {'Select the check point:'};
    defAns = {checkPointFiles, 1};
    dlgTitle = 'Select checkpoint';
    options.PromptLines = 1;
    options.Title = sprintf(['Files with training checkpoints were detected.\n' ...
        'Please select the checkpoint to continue, if you choose "Start new training" the checkpoint directory ' ...
        'will be cleared from the older checkpoints and the new training session initiated:']);
    options.TitleLines = 5;
    options.WindowWidth = 1.4;
    [answer, selPosition] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); return; end

    switch selPosition
        case 1  % start new training
            if obj.BatchOpt.T_SaveProgress
                delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.mat'));     % delete all score matlab files
            end
            % make directories for export of the training scores
            if obj.BatchOpt.T_ExportTrainingPlots
                delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.csv'));     % delete all csv files
                delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.score'));     % delete all score matlab files
            end
        case 2  % continue from the loaded net
            if exist(obj.BatchOpt.NetworkFilename, 'file') == 2     % when the mibDeep file is present
                checkPointRestoreFile = obj.BatchOpt.NetworkFilename;
            else    % if mibDeep file is not present
                checkPointRestoreFile = fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', answer{1});
            end
        otherwise  % continue from the checkpoint
            checkPointRestoreFile = fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', answer{1});
    end
else
    % make directories for export of the training scores
    if obj.BatchOpt.T_ExportTrainingPlots
        delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.csv'));     % delete all csv files
        delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.score'));     % delete all score matlab files
    end
end

trainTimer = tic;

try
    showWaitbarLocal = obj.BatchOpt.showWaitbar;
    if showWaitbarLocal
        obj.wb = uiprogressdlg(obj.View.gui, 'Message', 'Creating datastores...', ...
            'Title', 'Preparing training', 'Cancelable', 'on');
    end
    
    % the other options are not available, require to process images
    fnExtension = lower(['.' obj.BatchOpt.ImageFilenameExtensionTraining{1}]);
    try
        % prepare options for loading of images
        mibDeepStoreLoadImagesOpt.mibBioformatsCheck = obj.BatchOpt.BioformatsTraining;
        mibDeepStoreLoadImagesOpt.BioFormatsIndices = obj.BatchOpt.BioformatsTrainingIndex{1};
        mibDeepStoreLoadImagesOpt.Workflow = obj.BatchOpt.Workflow{1};
    
        if preprocessedSwitch   % with preprocessing
            imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'), ...
                'FileExtensions', '.mibImg', 'IncludeSubfolders', false, ...
                'ReadFcn', @mibDeepStoreLoadImages);
            noFiles = numel(imgDS.Files);
        else    % without preprocessing
            if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
                % name this as patchDS because each image is
                % matching the input patch size
                
                patchDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), ...
                    'FileExtensions', fnExtension, ...
                    'IncludeSubfolders', true, ...
                    "LabelSource", "foldernames", ...
                    'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                I = readimage(patchDS, 1);
                if inputPatchSize(1) < size(I,1) || inputPatchSize(2) < size(I,2)
                    selection = uiconfirm(obj.View.gui, ...
                        sprintf(['!!! Warning !!!\n\n' ...
                        'The desired input patch size (%d x %d) is smaller than the size of individual image patches (%d x %d) ' ...
                        'that are present in the directory with images for training!\n\nIf you continue, a random image patch with ' ...
                        'size (%d x %d) will be used for training!'], ...
                        inputPatchSize(1), inputPatchSize(2), size(I,1), size(I,2), inputPatchSize(1), inputPatchSize(2)), ...
                        'Input patch size mismatch',...
                        'Options',{'Continue', 'Cancel'},...
                        'DefaultOption', 1, 'CancelOption', 2,...
                        'Icon', 'warning');
                    if strcmp(selection, 'Cancel'); if showWaitbarLocal; delete(obj.wb); end;return; end

                    mibDeepStoreLoadImagesOpt.randomCrop = [inputPatchSize(1) inputPatchSize(2)]; % perform random crop of the image
                    patchDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), ...
                        'FileExtensions', fnExtension, ...
                        'IncludeSubfolders', true, ...
                        "LabelSource", "foldernames", ...
                        'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                end
                noFiles = numel(patchDS.Files);
            else
                imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), ...
                    'FileExtensions', fnExtension, ...
                    'IncludeSubfolders', false, ...
                    'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                noFiles = numel(imgDS.Files);
            end
        end
    catch err
        mibShowErrorDialog(obj.View.gui, err, 'Missing files');
        if showWaitbarLocal; delete(obj.wb); end
        return;
    end
    
    % check that number of files larger than minibatch size
    if noFiles*obj.BatchOpt.T_PatchesPerImage{1} < obj.BatchOpt.T_MiniBatchSize{1}
        uialert(obj.View.gui, ...
            sprintf(['!!! Error !!!\n\n' ...
            'The Mini-batch size (%d) should be smaller than result of\n' ...
            'Patches_per_image (%d) x Number_of_images (%d) = %d\n\n' ...
            'Solve by:\n-Decrease mini-batch size\n' ...
            '-Increase patches per image\n' ...
            '-Increase number of files used for training'], ...
            obj.BatchOpt.T_MiniBatchSize{1}, obj.BatchOpt.T_PatchesPerImage{1}, noFiles, noFiles*obj.BatchOpt.T_PatchesPerImage{1}), ...
            'Wrong configuration');
        if showWaitbarLocal; delete(obj.wb); end
        return;
    end
    
    % get class names
    if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
        classNames = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'));
        classNames = {classNames.name};
        classNames(ismember(classNames, {'.', '..'})) = [];
        classNames = classNames';
    else
        switch obj.BatchOpt.ModelFilenameExtension{1}
            case 'MODEL'
                if preprocessedSwitch   % with preprocessing
                    modelDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Labels', '*.model');
                    files = dir(modelDir);
                else                    % without preprocessing
                    modelDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels', '*.model');
                    files = dir(modelDir);
                end
    
                if numel(files) < 1
                    prompts = {'Material names (comma-separated list):'};
                    defAns = arrayfun(@(x) sprintf('Class%.2d', x), 1:obj.BatchOpt.T_NumberOfClasses{1}, 'UniformOutput', false);
                    defAns = [{'Exterior'}, defAns];
                    defAns = {strjoin(defAns, ', ')};
                    dlgTitle = 'Missing the model file';
                    warning('off', 'MATLAB:printf:BadEscapeSequenceInFormat');  % turn off possible warnings about sprintf syntax
                    options.Title = (sprintf(['Attention!\nThe model file is missing in\n%s\n\n' ...
                        'Enter material names used during preprocessing or ' ...
                        'restore the model file and restart the training'], modelDir));
    
                    options.TitleLines = 5;
                    options.WindowWidth = 2;
    
                    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer)
                        if showWaitbarLocal; delete(obj.wb); end
                        return;
                    end
                    classNames = strtrim(split(answer{1}, ','));    % get class names
                else
                    modelFn = fullfile(files(1).folder, files(1).name);
                    res = load(modelFn, '-mat', 'modelMaterialNames', 'modelMaterialColors');
                    classColors = res.modelMaterialColors;  % get colors
                    if preprocessedSwitch == 0 && obj.BatchOpt.MaskAway && strcmp(obj.BatchOpt.MaskFilenameExtension{1}, 'USE 0-s IN LABELS')
                        % do not add Exterior as in this case the Exterior is completely taken by the mask
                        % note that in case, when the mask is provided as a
                        % separate file, the background material (index==0)
                        % can still exist!
                        classNames = res.modelMaterialNames;    
                        % make sure that all materials are used to
                        % calculate the loss function
                        obj.SegmentationLayerOpt.dicePixelCustom.ExcludeExerior = false;
                    else
                        classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                    end
                end
            otherwise
                if preprocessedSwitch == 0 && obj.BatchOpt.MaskAway && strcmp(obj.BatchOpt.MaskFilenameExtension{1}, 'USE 0-s IN LABELS')
                    % generate class names from 1:to number of classes -1
                    classNames = arrayfun(@(x) sprintf('Class%.2d', x), 1:obj.BatchOpt.T_NumberOfClasses{1}-1, 'UniformOutput', false);
                    % make sure that all materials are used to
                    % calculate the loss function
                    obj.SegmentationLayerOpt.dicePixelCustom.ExcludeExerior = false;
                else
                    classNames = arrayfun(@(x) sprintf('Class%.2d', x), 1:obj.BatchOpt.T_NumberOfClasses{1}-1, 'UniformOutput', false);
                    classNames = [{'Exterior'}; classNames'];
                end
        end
    end
    if preprocessedSwitch == 0 && obj.BatchOpt.MaskAway && strcmp(obj.BatchOpt.MaskFilenameExtension{1}, 'USE 0-s IN LABELS')
        pixelLabelIDs = 1:numel(classNames);   % pixelIds start from 1, making 0-as mask to skip during training
    else
        pixelLabelIDs = 0:numel(classNames)-1;
    end
    
    % update number of classes variables
    if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise') 
        obj.BatchOpt.T_NumberOfClasses{1} = numel(classNames)+1;
    else
        obj.BatchOpt.T_NumberOfClasses{1} = numel(classNames);
    end
    obj.View.handles.T_NumberOfClasses.Value = obj.BatchOpt.T_NumberOfClasses{1};
    obj.View.handles.NumberOfClassesPreprocessing.Value = obj.BatchOpt.T_NumberOfClasses{1};
    
    % generate colors
    if exist('classColors', 'var') == 0
        if numel(classNames) < 7
            classColors = obj.colormap6;
        elseif numel(classNames) < 21
            classColors = obj.colormap20;
        else
            classColors = obj.colormap255;
        end
    end
    
    % init random generator
    if obj.BatchOpt.T_RandomGeneratorSeed{1} == 0
        rng('shuffle');
    else
        rng(obj.BatchOpt.T_RandomGeneratorSeed{1}, 'twister');
    end
    
    if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
        labelsDS = [];
    else
        if preprocessedSwitch   % with preprocessing
            labelsDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'), ...
                'FileExtensions', '.mibCat', 'IncludeSubfolders', false, ...
                'ReadFcn', @mibDeepStoreLoadCategorical);
        else                    % without preprocessing
            switch obj.BatchOpt.ModelFilenameExtension{1}
                case 'MODEL'
                    labelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
                        classNames, pixelLabelIDs, ...
                        'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
    
                    % I = readimage(labelsDS,1);  % read model test
                    % reset(modDS);
                otherwise
                    if strcmp(obj.BatchOpt.Workflow{1}, '2.5D Semantic')
                        % have to use custom reader, the lower part may
                        % also be switched with this code, but it has to be
                        % tested
                        labelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
                            classNames, pixelLabelIDs, ...
                            'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]), ...
                            'ReadFcn', @mibDeepStoreLoadImages);
                    else
                        labelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
                            classNames, pixelLabelIDs, ...
                            'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
    
                        %labelsDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
                        %    'IncludeSubfolders', false, ...
                        %    'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                    end
            end
    
            if numel(labelsDS.Files) ~= noFiles
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nIn this mode number of model files should match number of image files!\n\nCheck\n%s\n\n%s', ...
                    fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels')), ...
                    'Error');
                if showWaitbarLocal; delete(obj.wb); end
                return;
            end
        end
    end
    
    %% Create Random Patch Extraction Datastore for Validation
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        obj.wb.Value = 0.25;
        obj.wb.Message = 'Create a datastore for validation...';
    end
    
    if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
        % named as valPatchDS because each image is matching the
        % input patch size of the network
        if isfolder(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'))
            valPatchDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'), ...
                'FileExtensions', fnExtension, ...
                'IncludeSubfolders', true, ...
                "LabelSource", "foldernames", ...
                'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
        else
            valPatchDS = [];
        end
    else
        if preprocessedSwitch   % with preprocessing
            fileList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages', '*.mibImg'));
            if ~isempty(fileList)
                %fullPathFilenames = arrayfun(@(filename) fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages', cell2mat(filename)), {fileList.name}, 'UniformOutput', false);  % generate full paths
                valImgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'), ...
                    'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepStoreLoadImages);
    
                valLabelsDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels'), ...
                    'FileExtensions', '.mibCat', 'ReadFcn', @mibDeepStoreLoadCategorical);
            else    % do not use validation
                valImgDS = [];
                valLabelsDS = [];
            end
        else    % without preprocessing
            fileList = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages', ['*' fnExtension]));
            if ~isempty(fileList)
                valImgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'), ...
                    'FileExtensions', fnExtension, ...
                    'IncludeSubfolders', false, ...
                    'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
    
                switch obj.BatchOpt.ModelFilenameExtension{1}
                    case 'MODEL'
                        valLabelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels'), ...
                            classNames, pixelLabelIDs, ...
                            'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
                    otherwise
                        if strcmp(obj.BatchOpt.Workflow{1}, '2.5D Semantic')
                            % have to use custom reader, the lower part may
                            % also be switched with this code, but it has to be
                            % tested
                            valLabelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels'), ...
                                classNames, pixelLabelIDs, ...
                                'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]), ...
                                'ReadFcn', @mibDeepStoreLoadImages);
                        else
                            valLabelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels'), ...
                                classNames, pixelLabelIDs, ...
                                'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                        end
                end
    
                if numel(valLabelsDS.Files) ~= numel(valImgDS.Files)
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nIn this mode number of model files should match number of image files!\n\nCheck\n%s\n\n%s', ...
                        fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'), fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels')), ...
                        'Error');
                    if showWaitbarLocal; delete(obj.wb); end
                    return;
                end
            else    % do not use validation
                valImgDS = [];
                valLabelsDS = [];
            end
        end
    end
    
    if ~strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
        % generate random patch datastores
        switch obj.BatchOpt.Workflow{1}(1:2)
            case {'3D', '2.'}   % ; '2.5D Semantic' and '3D Semantic'
                randomStoreInputPatchSize = inputPatchSize(1:3);
            case '2D'
                randomStoreInputPatchSize = inputPatchSize(1:2);
        end
    
        % Augmenter needs to be applied to the patches later
        % after initialization using transform function
        patchDS = randomPatchExtractionDatastore(imgDS, labelsDS, randomStoreInputPatchSize, ...
            'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1}); 
    
        patchDS.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
    
        % create random patch extraction datastore for validation
        if ~isempty(valImgDS)
            valPatchDS = randomPatchExtractionDatastore(valImgDS, valLabelsDS, randomStoreInputPatchSize, ...
                'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1});
        else
            valPatchDS = [];
        end
        if ~isempty(valPatchDS)
            valPatchDS.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
        end
        %                     % test
        %                     imgTest = read(AugTrainDS);
        %                     imtool(imgTest.InputImage{1});
        %                     imtool(uint8(imgTest.ResponsePixelLabelImage{1}), []);
        %                     reset(AugTrainDS);
    end
    
    %% create network
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        obj.wb.Message = 'Creating the network...';
        obj.wb.Value = 0.4;
    end
    
    previewSwitch = 0; % 1 - the generated network is only for preview, i.e. weights of classes won't be calculated
    try
        if isempty(checkPointRestoreFile)
            [lgraph, outputPatchSize] = obj.createNetwork(previewSwitch);
            if isempty(lgraph)
                if showWaitbarLocal; delete(obj.wb); end
                return;
            end
        else
            res = load(checkPointRestoreFile, '-mat');
            if isfield(res, 'outputPatchSize')
                outputPatchSize = res.outputPatchSize;
                lgraph = res.net;
            else
                [lgraph, outputPatchSize] = obj.createNetwork(previewSwitch);
                if isempty(lgraph)
                    if showWaitbarLocal; delete(obj.wb); end
                    return;
                end
            end
        end
    catch err
        mibShowErrorDialog(obj.View.gui, err, 'Network problem');
        if showWaitbarLocal; delete(obj.wb); end
        return;
    end

    % just in case, controlled from selection of architectures at the moment
    if isa(lgraph, 'dlnetwork')
        obj.TrainEngine = 'trainnet'; % new training method for dlnetwork
    else
        obj.TrainEngine = 'trainNetwork'; % original training method
    end

    if isempty(outputPatchSize)
        if isdeployed
            uialert(obj.View.gui, ...
                sprintf('Unfortunately, 3D U-Net Anisotropic architecture with the "valid" padding is not yet available in the deployed version of MIB\n\nPlease use the "same" padding instead'), ...
                'Not implemented', 'Icon', 'error');
            if showWaitbarLocal; delete(obj.wb); end
            return;
        else
            analyzeNetwork(lgraph);
            prompts = {'Output patch size:'};
            defAns = {obj.BatchOpt.T_InputPatchSize};
            dlgTitle = 'Define output patch size';
            options.Title = (sprintf('Attention!\nDue to Matlab limitations you have to set the output patch size manually\nPlease enter the output patch size from the Network Analyzer window. It is displayer in the Activations column for the Softmax-Layer'));
            options.TitleLines = 8;
    
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer)
                if showWaitbarLocal; delete(obj.wb); end
                return;
            end
            outputPatchSize = str2num(answer{1});
        end
    end
    
    % analyzeNetwork(lgraph);
    % network can be modified by using Deep Network Designer App
    % deepNetworkDesigner;
    
    %% Augment the training and validation data by using the transform function with custom preprocessing
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        obj.wb.Message = 'Defing augmentation...';
        obj.wb.Value = 0.75;
    end
    
    % operations specified by the helper function augmentAndCrop3dPatch.
    % The augmentAndCrop3dPatch function performs these operations:
    % Randomly rotate and reflect training data to make the training more robust.
    % The function does not rotate or reflect validation data.
    % Crop response patches to the output size of the network (outputPatchSize: height x width x depth x classes)
    switch obj.BatchOpt.Workflow{1}(1:2)
        case {'3D', '2.'}   % '2.5D Semantic' and '3D Semantic'
            % define options for the augmenter function
            mibDeepAugmentOpt.Workflow = obj.BatchOpt.Workflow{1};
            mibDeepAugmentOpt.Aug3DFuncNames = obj.Aug3DFuncNames;
            mibDeepAugmentOpt.AugOpt3D = obj.AugOpt3D;
            mibDeepAugmentOpt.Aug3DFuncProbability = obj.Aug3DFuncProbability;
            mibDeepAugmentOpt.T_ConvolutionPadding = obj.BatchOpt.T_ConvolutionPadding{1};
    
            mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
            mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
            mibDeepAugmentOpt.T_NumberOfClasses = obj.BatchOpt.T_NumberOfClasses{1};
            
            augmentFunctionHandle = @mibDeepAugmentAndCrop3dPatchMultiGPU; % make a handle to the function to use
    
            % % define augmenting function; the functions are essentially the same, but the multi-gpu
            % % version does not have access to mibDeepController and obj.TrainingProgress
            % if ismember(obj.View.Figure.GPUDropDown.Value, {'Multi-GPU', 'Parallel'})
            %     augmentFunctionHandle = @mibDeepAugmentAndCrop3dPatchMultiGPU; % make a handle to the function to use
            % else
            %     mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
            %     mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
            %     augmentFunctionHandle = @obj.augmentAndCrop3dPatch; % make a handle to the function to use
            % end
    
            if obj.BatchOpt.T_augmentation
                status  = obj.setAugFuncHandles('3D');
                if status == 0
                    if showWaitbarLocal; delete(obj.wb); end
                    return;
                end
                
                AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'aug', mibDeepAugmentOpt), 'IncludeInfo', true);
                if ~isempty(valPatchDS)
                    valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
                else
                    valDS = [];
                end
            else
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                    % crop responses to the output size of the network
                    AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
                    if ~isempty(valPatchDS)
                        valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
                    else
                        valDS = [];
                    end
    
                else
                    % no cropping needed for the same padding
                    AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'show', mibDeepAugmentOpt), 'IncludeInfo', true);
                    valDS = valPatchDS;
                end
            end
        case '2D'
            % define options for the augmenter function
            mibDeepAugmentOpt.Workflow = obj.BatchOpt.Workflow{1};
            mibDeepAugmentOpt.Aug2DFuncNames = obj.Aug2DFuncNames;
            mibDeepAugmentOpt.AugOpt2D = obj.AugOpt2D;
            mibDeepAugmentOpt.Aug2DFuncProbability = obj.Aug2DFuncProbability;
            mibDeepAugmentOpt.T_ConvolutionPadding = obj.BatchOpt.T_ConvolutionPadding{1};
            
            % define augmenting function; the functions are essentially the same, but the multi-gpu
            % version does not have access to mibDeepController and obj.TrainingProgress
            mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
            mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
            mibDeepAugmentOpt.T_NumberOfClasses = obj.BatchOpt.T_NumberOfClasses{1};
    
            augmentFunctionHandle = @mibDeepAugmentAndCrop2dPatchMultiGPU; % make a handle to the function to use
    
            % if ismember(obj.View.Figure.GPUDropDown.Value, {'Multi-GPU', 'Parallel'})
            %     augmentFunctionHandle = @mibDeepAugmentAndCrop2dPatchMultiGPU; % make a handle to the function to use
            % else
            %     mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
            %     mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
            %     augmentFunctionHandle = @obj.augmentAndCrop2dPatch; % make a handle to the function to use
            % end
            
            if obj.BatchOpt.T_augmentation
                % define augmentation
                status = obj.setAugFuncHandles('2D');
                if status == 0
                    if showWaitbarLocal; delete(obj.wb); end
                    return;
                end
                
                AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'aug', mibDeepAugmentOpt), ...
                    'IncludeInfo', true);
                %                         for i=1:50
                %                             I = read(AugTrainDS);
                %                             if size(I.inpVol{1},3) == 2
                %                                 I.inpVol{1}(:,:,3) = zeros([size(I.inpVol{1}, 1), size(I.inpVol{1}, 2)]);
                %                             end
                %                             figure(1)
                %                             imshowpair(I.inpVol{1}, uint8(I.inpResponse{1}),'montage');
                %                         end
    
                if ~isempty(valPatchDS)
                    valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
                else
                    valDS = [];
                end
            else
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                    % crop responses to the output size of the network
                    AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
                    if ~isempty(valPatchDS)
                        valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
                    else
                        valDS = [];
                    end
                else
                    AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'show', mibDeepAugmentOpt), 'IncludeInfo', true);
                    % https://se.mathworks.com/help/deeplearning/ug/image-augmentation-using-image-processing-toolbox.html
                    valDS = valPatchDS;
                end
            end
    end
    
    % calculate max number of iterations
    if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
        mibDeepTrainingProgressStruct.maxNoIter = ...        % as noImages*PatchesPerImage*MaxEpochs/Minibatch
            ceil((numel(patchDS.Files)-mod(numel(patchDS.Files), obj.BatchOpt.T_MiniBatchSize{1}))/obj.BatchOpt.T_MiniBatchSize{1}) * obj.TrainingOpt.MaxEpochs;
    else
        mibDeepTrainingProgressStruct.maxNoIter = ...        % as noImages*PatchesPerImage*MaxEpochs/Minibatch
            ceil((patchDS.NumObservations-mod(patchDS.NumObservations, obj.BatchOpt.T_MiniBatchSize{1}))/obj.BatchOpt.T_MiniBatchSize{1}) * obj.TrainingOpt.MaxEpochs;
    end
    mibDeepTrainingProgressStruct.iterPerEpoch = ...
        mibDeepTrainingProgressStruct.maxNoIter / obj.TrainingOpt.MaxEpochs;
    
    % generate training options structure
    TrainingOptions = obj.preprareTrainingOptions(valDS);
    
    %% Train Network
    % After configuring the training options and the data source, train the 3-D U-Net network
    % by using the trainNetwork function.
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        obj.wb.Message = 'Starting trainining...';
        obj.wb.Value = 0.9;
    end
    modelDateTime = datestr(now, 'dd-mmm-yyyy-HH-MM-SS');
    
    % load the checkpoint to resume training
    if ~isempty(checkPointRestoreFile)
        if showWaitbarLocal
            if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
            obj.wb.Message = 'Loading checkpoint...';
        end
        load(checkPointRestoreFile, 'net', '-mat');
        switch class(net)
            case 'nnet.cnn.LayerGraph'     % from transfer learninig
                lgraph = net;
            case 'dlnetwork'
                lgraph = net;
            otherwise
                lgraph = layerGraph(net);   % DAG object after normal training
        end
    
        if ~isa(lgraph, 'dlnetwork')
            % find index of the output layer
            outPutLayerName = lgraph.OutputNames;
            notFound = 1;
            layerId = numel(lgraph.Layers) + 1;
            while notFound
                layerId = layerId - 1;
                if strcmp(lgraph.Layers(layerId).Name, outPutLayerName) || layerId == 0
                    notFound = 0;
                end
            end
            outLayer = lgraph.Layers(layerId);
            if sum(ismember(cellstr(outLayer.Classes), classNames)) ~= numel(classNames)
                selection = uiconfirm(obj.View.gui, ...
                    sprintf(['!!! Warning !!!\n\n' ...
                    'The class names of the loaded network do not match class names of the training model\n\n' ...
                    'Model classes:%s\nNetwork classes: %s\n\n' ...
                    'Press "Update network" to modify the network with new model class names'], ...
                    strjoin(string(classNames), ', '), strjoin(cellstr(outLayer.Classes), ', ')),...
                    'Class names mismatch', 'Options', {'Update network', 'Cancel'}, 'Icon', 'warning');
                if strcmp(selection, 'Cancel')
                    if showWaitbarLocal; delete(obj.wb); end
                    return;
                end
                % redefine the segmentation layer to update the names of classes
                lgraph = obj.updateSegmentationLayer(lgraph, classNames);
            end
        end
    end
    
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        obj.wb.Message = 'Preparing structures and saving configs...';
        obj.wb.Value = 0.95;
    end
    BatchOpt = obj.BatchOpt;
    % generate TrainingOptStruct, because TrainingOptions is 'TrainingOptionsADAM' class
    AugOpt2DStruct = obj.AugOpt2D;
    AugOpt3DStruct = obj.AugOpt3D;
    InputLayerOpt = obj.InputLayerOpt;
    TrainingOptStruct = obj.TrainingOpt;
    ActivationLayerOpt = obj.ActivationLayerOpt;
    SegmentationLayerOpt = obj.SegmentationLayerOpt;
    DynamicMaskOpt = obj.DynamicMaskOpt;
    
    % generate config file; the config file is the same as *.mibDeep but without 'net' field
    [configPath, configFn] = fileparts(obj.BatchOpt.NetworkFilename);
    obj.saveConfig(fullfile(configPath, [configFn '.mibCfg']));
    
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        delete(obj.wb);
    end
catch err
    mibShowErrorDialog(obj.View.gui, err, 'Network problem');
    if showWaitbarLocal; delete(obj.wb); end
    return;
end

obj.View.handles.TrainButton.Text = 'Stop training';
obj.View.handles.TrainButton.BackgroundColor = 'g'; %[1 .5 0]; % 0.7686    0.9020    0.9882
drawnow;
fprintf('Preparation for training is finished, elapsed time: %f\n', toc(trainTimer));

trainTimer = tic;
try
    mibDeepStopTraining = false;
    %obj.TrainEngine = 'trainNetwork'; % use this later as one of the parameters for main obj.BatchOpt
    %obj.TrainEngine = 'trainnet'; % use this later as one of the parameters for main obj.BatchOpt
    switch obj.TrainEngine
        case 'trainNetwork'
            [net, info] = trainNetwork(AugTrainDS, lgraph, TrainingOptions);
        case 'trainnet'
            % testing trainnet

            % requires to update prediction part using
            % X = single(im);
            % scores = predict(net,X);
            % [label,score] = scores2label(scores,classNames);

            % convert old type of network model into dlnetwork
            if isa(lgraph, 'dlnetwork')
                net = lgraph;
            else
                % remove the last layer as it is not used in trainnet
                lgraph2 = removeLayers(lgraph,  lgraph.Layers(end).Name);
                % convert to dlnetwork object 
                net = dlnetwork(lgraph2); 
            end

            switch obj.BatchOpt.T_SegmentationLayer{1} % define the loss function
                case 'pixelClassificationLayer'
                    [net, info] = trainnet(AugTrainDS, net, 'crossentropy', TrainingOptions);  % 10.89 vs 15.69 seconds
                    %[net, info] = trainnet(AugTrainDS, net, 'binary-crossentropy', TrainingOptions); 
                case 'weightedCrossEntropy'
                    weights = [1 1 1]; % needs to be specified
                    [net, info] = trainnet(AugTrainDS, net, @(Y,T)crossentropy(Y, T, weights), TrainingOptions);
                case 'dicePixelCustomClassificationLayer'
                    if obj.SegmentationLayerOpt.dicePixelCustom.ExcludeExerior
                        % exclude the background class from calculation of
                        % the loss function
                        useClasses = 2:obj.BatchOpt.T_NumberOfClasses{1};
                    else
                        useClasses = [];
                    end

                    switch obj.BatchOpt.Workflow{1}
                        case '3D Semantic'
                            dataDimension = 3;
                        case {'2D Semantic', '2D Patch-wise', '2.5D Semantic'}
                            if strcmp(obj.BatchOpt.Architecture{1}(1:3), 'Z2C') || strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D')
                                dataDimension = 2;
                            else    % '2.5D Semantic'
                                dataDimension = 2.5;
                            end
                    end
                    [net, info] = trainnet(AugTrainDS, net, @(Y,T)customDiceForwardLoss(Y,T, dataDimension, useClasses), TrainingOptions);
                    fprintf('DeepMIB stop reason: %s\n', info.StopReason);
                %case 'focalLossLayer'
                    % focalLoss = focalCrossEntropy(dlX, targets, ...
                    %     'Gamma', obj.SegmentationLayerOpt.focalLossLayer.Gamma, ...
                    %     'Alpha', obj.SegmentationLayerOpt.focalLossLayer.Alpha, ...
                    %     'DataFormat','SSCB', ...
                    %     'Reduction','mean', 'ClassificationMode', 'multilabel');
                    
                    % focalLoss = focalCrossEntropy(dlX, targets, ...
                    %     'Gamma', obj.SegmentationLayerOpt.focalLossLayer.Gamma, ...
                    %     'Alpha', obj.SegmentationLayerOpt.focalLossLayer.Alpha, ...
                    %     'DataFormat','SSCB', ...
                    %     'Reduction','mean', 'ClassificationMode', 'single-label');
                    % 
                    % [net, info] = trainnet(AugTrainDS, net, focalLoss, TrainingOptions);
                    % [net, info] = trainnet(AugTrainDS, net, @(Y,T)mibFocalCrossEntropyLoss(Y,T, obj.SegmentationLayerOpt.focalLossLayer.Alpha, obj.SegmentationLayerOpt.focalLossLayer.Gamma), TrainingOptions);
                case {'focalLossLayer', 'dicePixelClassificationLayer'}
                % case 'dicePixelClassificationLayer'
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\n%s is not yet implemented for the trainnet engine!\nSwitch to another segmentation layer or use trainNetwork engine', obj.BatchOpt.T_SegmentationLayer{1}), ...
                        'Not implemented', 'Icon', 'error');
                    return;
            end
    end
catch err
    mibShowErrorDialog(obj.View.gui, err, 'Train network error');
    return;
end

if showWaitbarLocal
    obj.wb = uiprogressdlg(obj.View.gui, 'Message', 'Finalizing training...', ...
        'Title', 'Finalize training', 'Cancelable', 'on');
end

if mibDeepTrainingProgressStruct.useCustomProgressPlot && isfield(info, 'OutputNetworkIteration')
    % add line at the selected iteration indicating the picked network
    hold(mibDeepTrainingProgressStruct.UILossAxes, 'on');
    mibDeepTrainingProgressStruct.hPlot(3) = plot(mibDeepTrainingProgressStruct.UILossAxes, [info.OutputNetworkIteration, info.OutputNetworkIteration], mibDeepTrainingProgressStruct.UILossAxes.YLim, '-');
    mibDeepTrainingProgressStruct.hPlot(3).Color = [0 .7 0];
    mibDeepTrainingProgressStruct.UILossAxes.Legend.String = {'Training'  'Validation'  sprintf('Picked iteration: %d', info.OutputNetworkIteration)};
    % add last point to the plot
    if mibDeepTrainingProgressStruct.hPlot(1).XData(end) < numel(info.TrainingLoss)
        warning('off','MATLAB:gui:array:InvalidArrayShape');
        mibDeepTrainingProgressStruct.hPlot(1).XData = [mibDeepTrainingProgressStruct.hPlot(1).XData, numel(info.TrainingLoss)];
        mibDeepTrainingProgressStruct.hPlot(1).YData = [mibDeepTrainingProgressStruct.hPlot(1).YData, info.TrainingLoss(end)];
        if isfield(info, 'ValidationLoss')
            mibDeepTrainingProgressStruct.hPlot(2).XData = [mibDeepTrainingProgressStruct.hPlot(2).XData numel(info.ValidationLoss)];
            mibDeepTrainingProgressStruct.hPlot(2).YData = [mibDeepTrainingProgressStruct.hPlot(2).YData info.ValidationLoss(end)];
        end
        warning('on','MATLAB:gui:array:InvalidArrayShape');
    end
    hold(mibDeepTrainingProgressStruct.UILossAxes, 'off');
end

if showWaitbarLocal
    if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
    obj.wb.Message = 'Saving network...';
    obj.wb.Value = 0.3;
end

% do emergency brake, use the recent check point for restoring the network parameters
if mibDeepTrainingProgressStruct.emergencyBrake && (obj.BatchOpt.Workflow{1}(1) == '3' || strcmp(obj.BatchOpt.Workflow{1}, 'SegNet'))
    if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork'))
        progressFiles = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.mat'));
        if ~isempty(progressFiles)
            [~, idx]=sort([progressFiles.datenum], 'descend');      % sort in time order
            checkPointRestoreFile = fullfile(progressFiles(idx(1)).folder, progressFiles(idx(1)).name);
            load(checkPointRestoreFile, 'net', '-mat');
        end
    end
end

% add MIB version to the saved config
mibVersion.mibVersion = obj.mibController.mibVersion;
mibVersion.mibVersionNumeric = obj.mibController.mibVersionNumeric;

% save training plot figure
save(obj.BatchOpt.NetworkFilename, 'net', 'TrainingOptStruct', 'AugOpt2DStruct', 'AugOpt3DStruct', 'InputLayerOpt', ...
    'ActivationLayerOpt', 'SegmentationLayerOpt', 'DynamicMaskOpt', ...
    'classNames', 'classColors', 'inputPatchSize', 'outputPatchSize', 'BatchOpt', 'mibVersion', '-mat', '-v7.3');

if showWaitbarLocal
    if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
    obj.wb.Message = 'Exporting training plots...';
    obj.wb.Value = 0.7;
end

if obj.BatchOpt.T_ExportTrainingPlots
    %if showWaitbarLocal; if ~isvalid(obj.wb); return; end; waitbar(0.99, obj.wb, 'Saving training plots...'); end
    datetimeTag = char(datetime('now', 'format', 'yyMMddHHmm'));
    [~, fnTemplate] = fileparts(obj.BatchOpt.NetworkFilename);
    fnTemplate = [datetimeTag, '_', fnTemplate];
    if exist(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork'), 'dir') ~= 7
        mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork'));
    end
    save(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', [fnTemplate '.score']), 'info', '-mat', '-v7.3');

    fieldNames = fieldnames(info);
    for fieldId = 1:numel(fieldNames)
        if istable(info.(fieldNames{fieldId}))  % trainnet engine
            writetable(info.(fieldNames{fieldId}), ...
                fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', [fnTemplate '_' fieldNames{fieldId} '.csv']));
        else % trainNetwork engine
            writematrix(info.(fieldNames{fieldId}), ...
                fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', [fnTemplate '_' fieldNames{fieldId} '.csv']));
        end
    end

    if obj.BatchOpt.O_CustomTrainingProgressWindow
        try
            fn_out = fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', [datetimeTag '_Train_',  fnTemplate '.png']);
            mibDeepTrainingProgressStruct.UIFigure.focus;
            mibDeepSaveTrainingPlot([], [], mibDeepTrainingProgressStruct, fn_out);
            fn_out = fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', [datetimeTag '_Train_',  fnTemplate '.fig']);
            savefig(mibDeepTrainingProgressStruct.UIFigure, fn_out)
        catch err
        end
    end
end

if showWaitbarLocal
    obj.wb.Value = 1;
    delete(obj.wb);
end

if mibDeepTrainingProgressStruct.useCustomProgressPlot
    mibDeepTrainingProgressStruct.StopTrainingButton.BackgroundColor = [0 1 0];
    mibDeepTrainingProgressStruct.StopTrainingButton.Text = 'Finished!!!';
end

% when trainNetwork engine info has following fields:
% .TrainingLoss: [0.7940 0.7566 0.6457 0.4848 0.3220 … ] (1×22 double)
% .TrainingAccuracy: [8.1182 29.2371 90.4357 96.1761 97.1811 … ] (1×22 double)
% .BaseLearnRate: [0.0050 0.0050 0.0050 0.0050 0.0050 … ] (1×22 double)
% .OutputNetworkIteration: 22
% when trainnet engine info:
% .TrainingHistory: [22×5 table]
% .ValidationHistory: [0×0 table]
% .OutputNetworkIteration: 22
% .StopReason: "Stopped by OutputFcn"


if obj.SendReports.T_SendReports && info.OutputNetworkIteration >= mibDeepTrainingProgressStruct.maxNoIter && ...
        obj.SendReports.sendWhenFinished && ...
        mibDeepTrainingProgressStruct.sendNextReportAtEpoch ~= -1
    [~, fn] = fileparts(obj.BatchOpt.NetworkFilename);
    if mibDeepTrainingProgressStruct.useCustomProgressPlot
        mgsText = sprintf(['DeepMIB training of "%s" network\n' ...
                '%s\n' ...
                'Iteration Number: %s\n\n' ...
                '%s\n%s\n%s\n\n'], ...
                fn, ...
                mibDeepTrainingProgressStruct.Epoch.Text, mibDeepTrainingProgressStruct.IterationNumberValue.Text, ...
                mibDeepTrainingProgressStruct.StartTime.Text, mibDeepTrainingProgressStruct.ElapsedTime.Text, mibDeepTrainingProgressStruct.TimeToGo.Text);
        if isfield(info, 'TrainingLoss')  % obj.TrainEngine == 'trainNetwork'
            mgsText = sprintf(['%s' ...
                'Training Loss: %f\n' ...
                'Training Accuracy: %f\n' ...
                'Validation Loss: %f\n' ...
                'Validation Accuracy: %f\n' ...
                'Final Validation Loss: %f\n' ...
                'Final Validation Accuracy: %f\n'], ...
                mgsText, ...
                info.TrainingLoss(end), info.TrainingAccuracy(end), ...
                info.ValidationLoss(end), info.ValidationAccuracy(end), ...
                info.FinalValidationLoss, info.FinalValidationAccuracy);
        else   % obj.TrainEngine == 'trainnet'
            mgsText = sprintf(['%s' ...
                'Training Loss: %f\n' ...
                'Training Accuracy: %f\n'], ...
                mgsText, info.TrainingHistory.Loss(end), info.TrainingHistory.Accuracy(end));
            if ~isempty(info.ValidationHistory)
                mgsText = sprintf(['%s' ...
                    'Validation Loss: %f\n' ...
                    'Validation Accuracy: %f\n'], ...
                mgsText, info.ValidationHistory.Loss(end), info.ValidationHistory.Accuracy(end));

            end
        end
        mgsText = sprintf(['%s' ...
                'Output Network Iteration: %d\n'], ...
                mgsText, info.OutputNetworkIteration);
    else
        mgsText = sprintf(['DeepMIB training of "%s" network\n' ...
            'Training Loss: %f\n' ...
            'Training Accuracy: %f\n' ...
            'Validation Loss: %f\n' ...
            'Validation Accuracy: %f\n' ...
            'Final Validation Loss: %f\n' ...
            'Final Validation Accuracy: %f\n' ...
            'Output Network Iteration: %d\n'], ...
            fn, info.TrainingLoss(end), info.TrainingAccuracy(end), ...
            info.ValidationLoss(end), info.ValidationAccuracy(end), ...
            info.FinalValidationLoss, info.FinalValidationAccuracy, ...
            info.OutputNetworkIteration);
    end
    sendmail(obj.SendReports.TO_email, sprintf('DeepMIB: training of %s is over!', fn), mgsText);
end

% count user's points
obj.mibModel.preferences.Users.Tiers.numberOfTrainedDeepNetworks = obj.mibModel.preferences.Users.Tiers.numberOfTrainedDeepNetworks+1;
eventdata = ToggleEventData(10);    % scale scoring by factor 5
notify(obj.mibModel, 'updateUserScore', eventdata);

mibDeepTrainingProgressStruct =  struct();
obj.View.handles.TrainButton.Text = 'Train';
obj.View.handles.TrainButton.BackgroundColor = [0.7686    0.9020    0.9882];

fprintf('Training is finished, elapsed time: %f\n', toc(trainTimer));
end

