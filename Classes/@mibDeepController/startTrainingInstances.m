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
% Date: 08.05.2023

function startTrainingInstances(obj)
% function startTrainingInstances(obj)
% perform training of instance segmentation network

global mibPath;
global counter;     % for patch test
global mibDeepStopTraining
global mibDeepTrainingProgressStruct

counter = 1;
mibDeepTrainingProgressStruct.emergencyBrake = false;   % emergency brake without finishing the weights

msg = sprintf('!!! Warning !!!\nYou are going to start training of an instance segmentation network!\n\nConfirm that your images located under\n\n%s\n\n%s\n%s\n%s\n%s\n\nPlease also make sure that number of files with labels match number of files with images!', ...
    obj.BatchOpt.OriginalTrainingImagesDir, ...
    '- TrainImages', '- TrainLabels', ...
    '- ValidationImages', '- ValidationLabels');

selection = uiconfirm(obj.View.gui, ...
    msg, 'Preprocessing',...
    'Options',{'Confirm', 'Cancel'},...
    'DefaultOption',1,'CancelOption',2,...
    'Icon', 'warning');
if strcmp(selection, 'Cancel'); return; end


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
        'Please provide the "Input patch size" (BatchOpt.T_InputPatchSize) as 4 numbers that define\n' ...
        'height, width, depth, colors\n\nFor example:\n' ...
        '"800, 800, 1, 3" for SOLOv2 of 3 color channel images\n' ...
        '"1280, 800, 1, 1" for SOLOv2 of 1 color channel images\n\n' ...
        'Please note that the width and height should be multiples of 32 and color are 1 or 3']), ...
        'Wrong patch size');
    return;
end

%   check for rectangular shape of the input patch
if inputPatchSize(1)~=inputPatchSize(2) && obj.BatchOpt.T_augmentation
    if (strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D') && obj.AugOpt2D.Rotation90.Enable )
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
    showWaitbarLocal = false;
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

        % imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), ...
        %     'FileExtensions', fnExtension, ...
        %     'IncludeSubfolders', false, ...
        %     'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));

        imgDS = fileDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), ...
            'FileExtensions', fnExtension, ...
            'IncludeSubfolders', false, ...
            'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));

        noFiles = numel(imgDS.Files);
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
            'Solve by (one of the options):\n-Decrease mini-batch size\n' ...
            '-Increase patches per image\n' ...
            '-Increase number of files used for training'], ...
            obj.BatchOpt.T_MiniBatchSize{1}, obj.BatchOpt.T_PatchesPerImage{1}, noFiles, noFiles*obj.BatchOpt.T_PatchesPerImage{1}), ...
            'Wrong configuration');
        if showWaitbarLocal; delete(obj.wb); end
        return;
    end

    % init random generator
    if obj.BatchOpt.T_RandomGeneratorSeed{1} == 0
        rng('shuffle');
    else
        rng(obj.BatchOpt.T_RandomGeneratorSeed{1}, 'twister');
    end

    % labelsDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
    %     'FileExtensions', '.mat', 'IncludeSubfolders', false, ...
    %     'ReadFcn', @matReadInstanceLabels);

    labelsDS = fileDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
        'FileExtensions', '.mat', 'IncludeSubfolders', false, ...
        'ReadFcn', @(fn)matReadInstanceLabels(fn, mibDeepStoreLoadImagesOpt));

    if numel(labelsDS.Files) ~= noFiles
        uialert(obj.View.gui, ...
            sprintf('!!! Error !!!\n\nNumber of model files should match number of image files!\n\nCheck that number of files match in\n\n%s\n\n%s', ...
            fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels')), ...
            'Error');
        if showWaitbarLocal; delete(obj.wb); end
        return;
    end

    %% Create Datastore for Validation
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        obj.wb.Value = 0.25;
        obj.wb.Message = 'Create a datastore for validation...';
    end

    fileList = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages', ['*' fnExtension]));
    if ~isempty(fileList)
        valImgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'), ...
            'FileExtensions', fnExtension, ...
            'IncludeSubfolders', false, ...
            'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));

        valLabelsDS = fileDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels'), ...
            'FileExtensions', '.mat', 'IncludeSubfolders', false, ...
            'ReadFcn', @(fn)matReadInstanceLabels(fn, mibDeepStoreLoadImagesOpt));

        if numel(valLabelsDS.Files) ~= numel(valImgDS.Files)
            uialert(obj.View.gui, ...
                sprintf('!!! Error !!!\n\nNumber of MAT-files should match number of image files!\n\nCheck that number of files match in\n\n%s\n\n%s', ...
                fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'), fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels')), ...
                'Error');
            if showWaitbarLocal; delete(obj.wb); end
            return;
        end
    else    % do not use validation
        valImgDS = [];
        valLabelsDS = [];
    end
    
    % randomPatchExtractionDatastore -> not compatible with fileDatastore
    % %% generate random patch datastores
    % switch obj.BatchOpt.Workflow{1}(1:2)
    %     case {'3D', '2.'}   % ; '2.5D Semantic' and '3D Semantic'
    %         randomStoreInputPatchSize = inputPatchSize(1:3);
    %     case '2D'
    %         randomStoreInputPatchSize = inputPatchSize(1:2);
    % end
    % 
    % % Augmenter needs to be applied to the patches later
    % % after initialization using transform function
    % patchDS = randomPatchExtractionDatastore(imgDS, labelsDS, randomStoreInputPatchSize, ...
    %     'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1});
    % 
    % patchDS.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
    % 
    % % create random patch extraction datastore for validation
    % if ~isempty(valImgDS)
    %     valPatchDS = randomPatchExtractionDatastore(valImgDS, valLabelsDS, randomStoreInputPatchSize, ...
    %         'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1});
    % else
    %     valPatchDS = [];
    % end
    % if ~isempty(valPatchDS)
    %     valPatchDS.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
    % end
    % %                     % test
    % %                     imgTest = read(AugTrainDS);
    % %                     imtool(imgTest.InputImage{1});
    % %                     imtool(uint8(imgTest.ResponsePixelLabelImage{1}), []);
    % %                     reset(AugTrainDS);


    %% create network
    if showWaitbarLocal
        if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
        obj.wb.Message = 'Creating the network...';
        obj.wb.Value = 0.4;
    end

    previewSwitch = 0; % 1 - the generated network is only for preview, i.e. weights of classes won't be calculated
    
    % get input patch size
    inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);
    inputPatchSize = [inputPatchSize([1 2]) 3];
    outputPatchSize = inputPatchSize;

    try
        if isempty(checkPointRestoreFile)
            switch obj.BatchOpt.Architecture{1}
                case 'SOLOv2'
                    switch obj.BatchOpt.T_EncoderNetwork{1}
                        case 'Resnet18'
                            detectorName = 'light-resnet18-coco';
                        case 'Resnet50'
                            detectorName = 'resnet50-coco';
                    end
            end
            lgraph = solov2(detectorName, ...
                "object", ...
                "InputSize", inputPatchSize);
        else
            error('Instance segmentation: load checkpoint - not implemented')
            res = load(checkPointRestoreFile, '-mat');
            if isfield(res, 'outputPatchSize')
                outputPatchSize = res.outputPatchSize;
            else
                [lgraph, outputPatchSize] = obj.createNetwork(previewSwitch);
                if isempty(lgraph)
                    if showWaitbarLocal; delete(obj.wb); end
                    return;
                end
            end
        end
    catch err
        mibShowErrorDialog(obj.View.gui, err, 'Network initialization problem');
        if showWaitbarLocal; delete(obj.wb); end
        return;
    end

    % %% Augment the training and validation data by using the transform function with custom preprocessing
    % if showWaitbarLocal
    %     if obj.wb.CancelRequested; mibDeepStopTrainingCallback(obj.wb); return; end
    %     obj.wb.Message = 'Defing augmentation...';
    %     obj.wb.Value = 0.75;
    % end
    % 
    % % operations specified by the helper function augmentAndCrop3dPatch.
    % % The augmentAndCrop3dPatch function performs these operations:
    % % Randomly rotate and reflect training data to make the training more robust.
    % % The function does not rotate or reflect validation data.
    % % Crop response patches to the output size of the network (outputPatchSize: height x width x depth x classes)
    % switch obj.BatchOpt.Workflow{1}(1:2)
    %     case {'3D', '2.'}   % '2.5D Semantic' and '3D Semantic'
    %         % define options for the augmenter function
    %         mibDeepAugmentOpt.Workflow = obj.BatchOpt.Workflow{1};
    %         mibDeepAugmentOpt.Aug3DFuncNames = obj.Aug3DFuncNames;
    %         mibDeepAugmentOpt.AugOpt3D = obj.AugOpt3D;
    %         mibDeepAugmentOpt.Aug3DFuncProbability = obj.Aug3DFuncProbability;
    %         mibDeepAugmentOpt.T_ConvolutionPadding = obj.BatchOpt.T_ConvolutionPadding{1};
    % 
    %         mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
    %         mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
    %         mibDeepAugmentOpt.T_NumberOfClasses = obj.BatchOpt.T_NumberOfClasses{1};
    % 
    %         augmentFunctionHandle = @mibDeepAugmentAndCrop3dPatchMultiGPU; % make a handle to the function to use
    % 
    %         % % define augmenting function; the functions are essentially the same, but the multi-gpu
    %         % % version does not have access to mibDeepController and obj.TrainingProgress
    %         % if ismember(obj.View.Figure.GPUDropDown.Value, {'Multi-GPU', 'Parallel'})
    %         %     augmentFunctionHandle = @mibDeepAugmentAndCrop3dPatchMultiGPU; % make a handle to the function to use
    %         % else
    %         %     mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
    %         %     mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
    %         %     augmentFunctionHandle = @obj.augmentAndCrop3dPatch; % make a handle to the function to use
    %         % end
    % 
    %         if obj.BatchOpt.T_augmentation
    %             status  = obj.setAugFuncHandles('3D');
    %             if status == 0
    %                 if showWaitbarLocal; delete(obj.wb); end
    %                 return;
    %             end
    % 
    %             AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'aug', mibDeepAugmentOpt), 'IncludeInfo', true);
    %             if ~isempty(valPatchDS)
    %                 valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
    %             else
    %                 valDS = [];
    %             end
    %         else
    %             if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
    %                 % crop responses to the output size of the network
    %                 AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
    %                 if ~isempty(valPatchDS)
    %                     valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize(1:3), outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
    %                 else
    %                     valDS = [];
    %                 end
    % 
    %             else
    %                 % no cropping needed for the same padding
    %                 AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'show', mibDeepAugmentOpt), 'IncludeInfo', true);
    %                 valDS = valPatchDS;
    %             end
    %         end
    %     case '2D'
    %         % define options for the augmenter function
    %         mibDeepAugmentOpt.Workflow = obj.BatchOpt.Workflow{1};
    %         mibDeepAugmentOpt.Aug2DFuncNames = obj.Aug2DFuncNames;
    %         mibDeepAugmentOpt.AugOpt2D = obj.AugOpt2D;
    %         mibDeepAugmentOpt.Aug2DFuncProbability = obj.Aug2DFuncProbability;
    %         mibDeepAugmentOpt.T_ConvolutionPadding = obj.BatchOpt.T_ConvolutionPadding{1};
    % 
    %         % define augmenting function; the functions are essentially the same, but the multi-gpu
    %         % version does not have access to mibDeepController and obj.TrainingProgress
    %         mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
    %         mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
    %         mibDeepAugmentOpt.T_NumberOfClasses = obj.BatchOpt.T_NumberOfClasses{1};
    % 
    %         augmentFunctionHandle = @mibDeepAugmentAndCrop2dPatchMultiGPU; % make a handle to the function to use
    % 
    %         % if ismember(obj.View.Figure.GPUDropDown.Value, {'Multi-GPU', 'Parallel'})
    %         %     augmentFunctionHandle = @mibDeepAugmentAndCrop2dPatchMultiGPU; % make a handle to the function to use
    %         % else
    %         %     mibDeepAugmentOpt.O_PreviewImagePatches = obj.BatchOpt.O_PreviewImagePatches;
    %         %     mibDeepAugmentOpt.O_FractionOfPreviewPatches = obj.BatchOpt.O_FractionOfPreviewPatches{1};
    %         %     augmentFunctionHandle = @obj.augmentAndCrop2dPatch; % make a handle to the function to use
    %         % end
    % 
    %         if obj.BatchOpt.T_augmentation
    %             % define augmentation
    %             status = obj.setAugFuncHandles('2D');
    %             if status == 0
    %                 if showWaitbarLocal; delete(obj.wb); end
    %                 return;
    %             end
    % 
    %             AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'aug', mibDeepAugmentOpt), ...
    %                 'IncludeInfo', true);
    %             %                         for i=1:50
    %             %                             I = read(AugTrainDS);
    %             %                             if size(I.inpVol{1},3) == 2
    %             %                                 I.inpVol{1}(:,:,3) = zeros([size(I.inpVol{1}, 1), size(I.inpVol{1}, 2)]);
    %             %                             end
    %             %                             figure(1)
    %             %                             imshowpair(I.inpVol{1}, uint8(I.inpResponse{1}),'montage');
    %             %                         end
    % 
    %             if ~isempty(valPatchDS)
    %                 valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
    %             else
    %                 valDS = [];
    %             end
    %         else
    %             if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
    %                 % crop responses to the output size of the network
    %                 AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
    %                 if ~isempty(valPatchDS)
    %                     valDS = transform(valPatchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'crop', mibDeepAugmentOpt), 'IncludeInfo', true);
    %                 else
    %                     valDS = [];
    %                 end
    %             else
    %                 AugTrainDS = transform(patchDS, @(patchIn, info)augmentFunctionHandle(patchIn, info, inputPatchSize, outputPatchSize, 'show', mibDeepAugmentOpt), 'IncludeInfo', true);
    %                 % https://se.mathworks.com/help/deeplearning/ug/image-augmentation-using-image-processing-toolbox.html
    %                 valDS = valPatchDS;
    %             end
    %         end
    % end

    % calculate max number of iterations
    mibDeepTrainingProgressStruct.maxNoIter = ...        % as noImages*PatchesPerImage*MaxEpochs/Minibatch
        ceil((noFiles-mod(noFiles, obj.BatchOpt.T_MiniBatchSize{1}))/obj.BatchOpt.T_MiniBatchSize{1}) * obj.TrainingOpt.MaxEpochs;

    mibDeepTrainingProgressStruct.iterPerEpoch = ...
        mibDeepTrainingProgressStruct.maxNoIter / obj.TrainingOpt.MaxEpochs;

    % generate training options structure
    
    if ~isempty(valLabelsDS) && numel(valLabelsDS.Files) > 0
        msg = sprintf(['!!! Warning !!!\n\n' ...
            'Due to MATLAB limitations training of SOLOv2 network is implemeted only without validation set!']);

        selection = uiconfirm(obj.View.gui, ...
            msg, 'Validation is not available',...
            'Options',{'Continue', 'Cancel'},...
            'DefaultOption',1,'CancelOption',2,...
            'Icon', 'warning');
        if strcmp(selection, 'Cancel')
            if showWaitbarLocal; delete(obj.wb); end
            return;
        end
        valLabelsDS = []; % there is a bug
    end
    TrainingOptions = obj.preprareTrainingOptionsInstances(valLabelsDS);

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
        if isa(net, 'nnet.cnn.LayerGraph')     % from transfer learninig
            lgraph = net;
        else
            lgraph = layerGraph(net);   % DAG object after normal training
        end

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

    [net, info] = trainSOLOV2(...
        labelsDS, ...
        lgraph, ...
        TrainingOptions, ...
        'FreezeSubNetwork', 'backbone');
    %'ExperimentMonitor', 'none');
catch err
    mibShowErrorDialog(obj.View.gui, err, 'Train instance network error');
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

save(obj.BatchOpt.NetworkFilename, 'net', 'TrainingOptStruct', 'AugOpt2DStruct', 'AugOpt3DStruct', 'InputLayerOpt', ...
    'ActivationLayerOpt', 'SegmentationLayerOpt', 'DynamicMaskOpt', ...
    'classNames', 'classColors', 'inputPatchSize', 'outputPatchSize', 'BatchOpt', '-mat', '-v7.3');

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
        writematrix(info.(fieldNames{fieldId}), ...
            fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', [fnTemplate '_' fieldNames{fieldId} '.csv']));
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

if obj.SendReports.T_SendReports && numel(info.TrainingLoss) >= mibDeepTrainingProgressStruct.maxNoIter && ...
        obj.SendReports.sendWhenFinished && ...
        mibDeepTrainingProgressStruct.sendNextReportAtEpoch ~= -1
    [~, fn] = fileparts(obj.BatchOpt.NetworkFilename);
    if mibDeepTrainingProgressStruct.useCustomProgressPlot
        mgsText = sprintf(['DeepMIB training of "%s" network\n' ...
            '%s\n' ...
            'Iteration Number: %s\n\n' ...
            '%s\n%s\n%s\n\n' ...
            'Training Loss: %f\n' ...
            'Training Accuracy: %f\n' ...
            'Validation Loss: %f\n' ...
            'Validation Accuracy: %f\n' ...
            'Final Validation Loss: %f\n' ...
            'Final Validation Accuracy: %f\n' ...
            'Output Network Iteration: %d\n'], ...
            fn, ...
            mibDeepTrainingProgressStruct.Epoch.Text, mibDeepTrainingProgressStruct.IterationNumberValue.Text, ...
            mibDeepTrainingProgressStruct.StartTime.Text, mibDeepTrainingProgressStruct.ElapsedTime.Text, mibDeepTrainingProgressStruct.TimeToGo.Text, ...
            info.TrainingLoss(end), info.TrainingAccuracy(end), ...
            info.ValidationLoss(end), info.ValidationAccuracy(end), ...
            info.FinalValidationLoss, info.FinalValidationAccuracy, ...
            info.OutputNetworkIteration);
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

