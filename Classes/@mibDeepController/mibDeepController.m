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

classdef mibDeepController < handle
    % @type mibDeepController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('mibDeepController'); // as GUI tool
    % @endcode
    % or
    % @code
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test'mib;  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('mibDeepController', [], BatchOpt); // start mibDeepController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibDeepController', [], NaN);
    % @endcode

    % Updates
    %

    properties
        mibModel
        % handles to mibModel
        mibController
        % handle to mib controller
        View
        % handle to the view / mibDeepGUI
        listener
        % a cell array with handles to listeners
        childControllers
        % list of opened subcontrollers
        childControllersIds
        % a cell array with names of initialized child controllers
        availableArchitectures
        % containers.Map with available architectures
        % keySet = {'2D Semantic', '2.5D Semantic', '3D Semantic', '2D Patch-wise', '2D Instance'};
        % valueSet{1} = {'DeepLab v3+', 'SegNet', 'U-net', 'U-net +Encoder'}; old: {'U-net', 'SegNet', 'DLv3 Resnet18', 'DLv3 Resnet50', 'DLv3 Xception', 'DLv3 Inception-ResNet-v2'}
        % valueSet{2} = {'Z2C + DLv3', 'Z2C + DLv3', 'Z2C + U-net', 'Z2C + U-net +Encoder'}; % 3DC + DLv3 Resnet18'
        % valueSet{3} = {'U-net', 'U-net Anisotropic'}
        % valueSet{4} = {'Resnet18', 'Resnet50', 'Resnet101', 'Xception'}
        % valueSet{5} = {'SOLOv2'} old: {'SOLOv2 Resnet18', 'SOLOv2 Resnet50'};
        availableEncoders
        % containers.Map with available encoders
        % keySet - is a mixture of workflow -space- architecture {'2D Semantic DeepLab v3+', '2D Semantic U-net +Encoder'}
        % encoders for each "workflow -space- architecture" combination, the last value shows the selected encoder
        % encodersList{1} = {'Resnet18', 'Resnet50', 'Xception', 'InceptionResnetv2', 1}; % for '2D Semantic DeepLab v3+'
        % encodersList{2} = {'Classic', 'Resnet18', 'Resnet50', 2}; % for '2D Semantic U-net +Encoder'
        % encodersList{3} = {'Resnet18', 'Resnet50', 1}; % for '2D Instance SOLOv2''
        BatchOpt
        % a structure compatible with batch operation
        % name of each field should be displayed in a tooltip of GUI
        % it is recommended that the Tags of widgets match the name of the
        % fields in this structure
        % .Parameter - [editbox], char/string
        % .Checkbox - [checkbox], logical value true or false
        % .Dropdown{1} - [dropdown],  cell string for the dropdown
        % .Dropdown{2} - [optional], an array with possible options
        % .Radio - [radiobuttons], cell string 'Radio1' or 'Radio2'...
        % .ParameterNumeric{1} - [numeric editbox], cell with a number
        % .ParameterNumeric{2} - [optional], vector with limits [min, max]
        % .ParameterNumeric{3} - [optional], string 'on' - to round the value, 'off' to do not round the value
        AugOpt2D
        % a structure with augumentation options for 2D unets, default
        % obtained from obj.mibModel.preferences.Deep.AugOpt2D, see getDefaultParameters.m
        % .FillValue = 0;
        % .RandXReflection = true;
        % .RandYReflection = true;
        % .RandRotation = [-10, 10];
        % .RandScale = [.95 1.05];
        % .RandXScale = [.95 1.05];
        % .RandYScale = [.95 1.05];
        % .RandXShear = [-5 5];
        % .RandYShear = [-5 5];
        Aug2DFuncNames
        % cell array with names of 2D augmenter functions
        Aug2DFuncProbability
        % probabilities of each 2D augmentation action to be triggered
        Aug3DFuncNames
        % cell array with names of 2D augmenter functions
        Aug3DFuncProbability
        % probabilities of each 3D augmentation action to be triggered
        gpuInfoFig
        % a handle for GPU info window
        AugOpt3D
        % .Fraction = .6;   % augment 60% of patches
        % .FillValue = 0;
        % .RandXReflection = true;
        % .RandYReflection = true;
        % .RandZReflection = true;
        % .Rotation90 = true;
        % .ReflectedRotation90 = true;
        ActivationLayerOpt
        % options for the activation layer
        DynamicMaskOpt
        % options for calculation of dynamic masks for prediction using blocked image mode
        % .Method = 'Keep above threshold';  % 'Keep above threshold' or 'Keep below threshold'
        % .ThresholdValue = 60;
        % .InclusionThreshold = 0.1;     % Inclusion threshold for mask blocks
        SegmentationLayerOpt
        % options for the segmentation layer
        InputLayerOpt
        % a structure with settings for the input layer
        % .Normalization = 'zerocenter';
        % .Mean = [];
        % .StandardDeviation = [];
        % .Min = [];
        % .Max = [];
        modelMaterialColors
        % colors of materials
        PatchPreviewOpt
        % structure with preview patch options
        % .noImages = 9, number of images in montage
        % .imageSize = 160, patch size for preview
        % .labelShow = true, display overlay labels with details
        % .labelSize = 9, font size for the label
        % .labelColor = 'black', color of the label
        % .labelBgColor = 'yellow', color of the label background
        % .labelBgOpacity = 0.6;   % opacity of the background
        SendReports
        % send email reports with progress of the training process
        % .T_SendReports = false;
        % .FROM_email = 'user@gmail.com';
        % .SMTP_server = 'smtp-relay.brevo.com';
        % .SMTP_port = '587';
        % .SMTP_auth = true;
        % .SMTP_starttls = true;
        % .SMTP_sername = 'user@gmail.com';
        % .SMTP_password = '';
        % .sendWhenFinished = false;
        % .sendDuringRun = false;
        TrainingOpt
        % a structure with training options, the default ones are obtained
        % from obj.mibModel.preferences.Deep.TrainingOpt, see getDefaultParameters.m
        % .solverName = 'adam';
        % .MaxEpochs = 50;
        % .Shuffle = 'once';
        % .InitialLearnRate = 0.0005;
        % .LearnRateSchedule = 'piecewise';
        % .LearnRateDropPeriod = 10;
        % .LearnRateDropFactor = 0.1;
        % .L2Regularization = 0.0001;
        % .Momentum = 0.9;
        % .ValidationFrequency = 400;
        % .Plots = 'training-progress';
        TrainingProgress
        % a structure to be used for the training progress plot for the
        % compiled version of MIB
        % .maxNoIter = max number of iteractions for during training
        % .iterPerEpoch - iterations per epoch
        % .stopTraining - logical switch that forces to stop training and
        % save all progress
        wb
        % handle to waitbar
        colormap6
        % colormap for 6 colors
        colormap20
        % colormap for 20 colors
        colormap255
        % colormap for 255 colors
        sessionSettings
        % structure for the session settings
        % .countLabelsDir - directory with labels to count, used in count labels function
        TrainEngine
        % temp property to test trainnet function for training: can be
        % 'trainnet' or 'trainNetwork'
    end

    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end

    methods (Static)
        function viewListner_Callback(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end

        function data = tif3DFileRead(filename)
            % data = tif3DFileRead(filename)
            % custom reading function to load tif files with stack of images
            % used in evaluate segmentation function
            meta = imfinfo(filename);
            data = zeros([meta(1).Height, meta(1).Width, numel(meta)], 'uint8');
            for sliceId = 1:numel(meta)
                data(:, :, sliceId) = imread(filename, 'Index', sliceId);
            end
        end

        function [outputLabeledImageBlock, scoreBlock] = segmentBlockedImage(block, net, dataDimension, patchwiseWorkflowSwitch, generateScoreFiles, executionEnvironment, padShift)
            % test function for utilization of blockedImage for prediction
            % The input block will be a batch of blocks from the a blockedImage.
            %
            % Parameters:
            % block: a structure with a block that is provided by
            % blockedImage/apply. The first and second iterations have
            % batch size==1, while the following have the batch size equal
            % to the selected. Below fields of the structure,
            %      .BlockSub: [1 1 1]
            %      .Start: [1 1 1]
            %      .End: [224 224 3]
            %      .Level: 1
            %      .ImageNumber: 1
            %      .BorderSize: [0 0 0]
            %      .BlockSize: [224 224 3]
            %      .BatchSize: 1
            %      .Data: [224×224×3 uint8]
            % net: a trained DAGNetwork
            % dataDimension: numeric switch that identify dataset dimension, can be 2, 2.5, 3
            % patchwiseWorkflowSwitch: logical switch indicating the patch-wise mode, when true->use patch mode, when false->use semantic segmentation
            % generateScoreFiles: variable to generate score files with probabilities of classes
            % 0-> do not generate
            % 1-> 'Use AM format'
            % 2-> 'Use Matlab non-compressed format'
            % 3-> 'Use Matlab compressed format'
            % 4-> 'Use Matlab non-compressed format (range 0-1)'
            % executionEnvironment: string with the environment to execute prediction
            % padShift: numeric, (y,x,z or y,x) value for the padding, used during the overlap mode to crop the output patch for export

            batchSizeDimension = numel(block.BlockSize) + 1;
            batchSize = size(block.Data, batchSizeDimension);

            % permute dataset for grayscale images when the batch size is
            % more than 1, otherwise give error for batch size>1 in the
            % patchwise mode
            if batchSizeDimension == 3 && batchSize > 1
                block.Data = permute(block.Data, [1 2 4 3]);
            end

            switch dataDimension
                case 2  % 2D case
                    if ~patchwiseWorkflowSwitch
                        if batchSizeDimension == 3 && ndims(block.Data) == 3 % second and other calls for grayscale images
                            % requres to permute the dataset to add a color channel
                            [outputLabeledImageBlock, ~, scoreBlock] = semanticseg(permute(block.Data, [1,2,4,3]), net, ...
                                'OutputType', 'uint8',...
                                'ExecutionEnvironment', executionEnvironment);
                        else
                            [outputLabeledImageBlock, ~, scoreBlock] = semanticseg(block.Data, net, ...
                                'OutputType', 'uint8',...
                                'ExecutionEnvironment', executionEnvironment);

                            %scores = predict(net, single(block.Data));
                            %[label,score] = scores2label(scores, {'bg', 'mito'});
                        end

                        % crop the output
                        if sum(padShift) ~= 0
                            y1 = padShift(1)+1;
                            y2 = padShift(1)+1+block.BlockSize(1)-1;
                            x1 = padShift(2)+1;
                            x2 = padShift(2)+1+block.BlockSize(2)-1;
                            outputLabeledImageBlock = outputLabeledImageBlock(y1:y2, x1:x2, :, :);
                            if generateScoreFiles > 0
                                scoreBlock = scoreBlock(y1:y2, x1:x2, :, :);
                            end
                        end

                        % Add singleton channel dimension to permit blocked image apply to
                        % reconstruct the full image from the processed blocks.
                        sz = size(outputLabeledImageBlock);
                        %outputLabeledImageBlock = reshape(outputLabeledImageBlock, [sz(1:2) 1 sz(3:end)]);
                        outputLabeledImageBlock = reshape(outputLabeledImageBlock, [sz(1:2) 1 batchSize]);
                        if generateScoreFiles > 0
                            sz = size(scoreBlock);
                            if generateScoreFiles < 4 %  convert to uint8
                                scoreBlock = uint8(scoreBlock*255);     % scale and convert to uint8
                            end
                            scoreBlock = reshape(scoreBlock, [sz(1:3) batchSize]);
                        else
                            scoreBlock = zeros([sz(1:2) 1 batchSize]);
                        end
                    else
                        [outputLabeledImageBlock, scoreBlock] = classify(net, block.Data, ...
                            'ExecutionEnvironment', executionEnvironment);

                        outputLabeledImageBlock = reshape(outputLabeledImageBlock, [1 batchSize]);
                        scoreBlock = reshape(scoreBlock', [1 1 size(scoreBlock,2) batchSize]);
                    end
                case 2.5  % 2D case
                    if batchSizeDimension == 4 && ndims(block.Data) == 4 % second and other calls for grayscale images
                        % requres to permute the dataset to add a color channel
                        [outputLabeledImageBlock, ~, scoreBlock] = semanticseg(permute(block.Data, [1,2,3,5,4]), net, ...
                            'OutputType', 'uint8',...
                            'ExecutionEnvironment', executionEnvironment);
                    else
                        [outputLabeledImageBlock, ~, scoreBlock] = semanticseg(block.Data, net, ...
                            'OutputType', 'uint8',...
                            'ExecutionEnvironment', executionEnvironment);
                    end

                    %[scores, pixelLabels] = max(scoreBlock(:,:,3,:,1,:), [], 4);

                    % crop the output
                    z = ceil(block.BlockSize(3)/2);
                    if sum(padShift) ~= 0
                        y1 = padShift(1)+1;
                        y2 = padShift(1)+1 + block.BlockSize(1)-1;
                        x1 = padShift(2)+1;
                        x2 = padShift(2)+1 + block.BlockSize(2)-1;
                        %z1 = padShift(3)+1;
                        %z2 = padShift(3)+1 + block.BlockSize(3)-1;
                        %outputLabeledImageBlock = outputLabeledImageBlock(y1:y2, x1:x2, z1:z2, :, :);
                        outputLabeledImageBlock = outputLabeledImageBlock(y1:y2, x1:x2, z, :, :);   % get a single slice
                        if generateScoreFiles > 0
                            %scoreBlock = scoreBlock(y1:y2, x1:x2, z1:z2, :, :);
                            scoreBlock = scoreBlock(y1:y2, x1:x2, z, :, :);
                        end
                    else
                        outputLabeledImageBlock = outputLabeledImageBlock(:, :, z, :, :);   % get a single slice
                        if generateScoreFiles > 0
                            scoreBlock = scoreBlock(:, :, z, :, :);
                        end
                    end

                    % Add singleton channel dimension to permit blocked image apply to
                    % reconstruct the full image from the processed blocks.
                    sz = size(outputLabeledImageBlock);
                    %outputLabeledImageBlock = reshape(outputLabeledImageBlock, [sz(1:3) 1 batchSize]);
                    outputLabeledImageBlock = reshape(outputLabeledImageBlock, [sz(1:2) 1 batchSize]);
                    if generateScoreFiles > 0
                        sz = size(scoreBlock);
                        if generateScoreFiles < 4 %  convert to uint8
                            scoreBlock = uint8(scoreBlock*255);     % scale and convert to uint8
                        end
                        % scoreBlock = reshape(scoreBlock, [sz(1:4) batchSize]);
                        scoreBlock = reshape(scoreBlock, [sz(1:2) sz(4) batchSize]);
                    else
                        %scoreBlock = zeros([sz(1:3) 1 batchSize]);
                        scoreBlock = zeros([sz(1:2) 1 batchSize]);
                    end
                case 3  % 3D case
                    if ~patchwiseWorkflowSwitch
                        if batchSizeDimension == 4 && ndims(block.Data) == 4 % second and other calls for grayscale images
                            % requres to permute the dataset to add a color channel
                            [outputLabeledImageBlock, ~, scoreBlock] = semanticseg(permute(block.Data, [1,2,3,5,4]), net, ...
                                'OutputType', 'uint8',...
                                'ExecutionEnvironment', executionEnvironment);
                        else
                            [outputLabeledImageBlock, ~, scoreBlock] = semanticseg(block.Data, net, ...
                                'OutputType', 'uint8',...
                                'ExecutionEnvironment', executionEnvironment);
                        end

                        % crop the output
                        if sum(padShift) ~= 0
                            y1 = padShift(1)+1;
                            y2 = padShift(1)+1 + block.BlockSize(1)-1;
                            x1 = padShift(2)+1;
                            x2 = padShift(2)+1 + block.BlockSize(2)-1;
                            z1 = padShift(3)+1;
                            z2 = padShift(3)+1 + block.BlockSize(3)-1;
                            outputLabeledImageBlock = outputLabeledImageBlock(y1:y2, x1:x2, z1:z2, :, :);
                            if generateScoreFiles > 0
                                scoreBlock = scoreBlock(y1:y2, x1:x2, z1:z2, :, :);
                            end
                        end

                        % Add singleton channel dimension to permit blocked image apply to
                        % reconstruct the full image from the processed blocks.
                        sz = size(outputLabeledImageBlock);
                        %outputLabeledImageBlock = reshape(outputLabeledImageBlock, [sz(1:2) 1 sz(3:end)]);
                        outputLabeledImageBlock = reshape(outputLabeledImageBlock, [sz(1:3) 1 batchSize]);
                        if generateScoreFiles > 0
                            sz = size(scoreBlock);
                            if generateScoreFiles < 4 %  convert to uint8
                                scoreBlock = uint8(scoreBlock*255);     % scale and convert to uint8
                            end
                            scoreBlock = reshape(scoreBlock, [sz(1:4) batchSize]);
                        else
                            scoreBlock = zeros([sz(1:3) 1 batchSize]);
                        end
                    else
                        error('not implemented');
                    end
            end
        end

        %         function img = loadAndTransposeImages(filename)
        %             img = mibLoadImages(filename);
        %             img = permute(img, [1 2 4 3]);  % transpose from [h,w,c,z] to [h,w,z,c]
        %         end
    end

    methods
        % declaration of functions in the external files, keep empty line in between for the doc generator

        [lgraph, outputPatchSize] = createNetwork(obj, previewSwitch) % generate network

        net = generateDeepLabV3Network(obj, imageSize, numClasses, targetNetwork) % generate DeepLab v3+ convolutional neural network for semantic image segmentation of 2D RGB images

        net = generate3DDeepLabV3Network(obj, imageSize, numClasses, downsamplingFactor, targetNetwork) % generate DeepLab v3+ convolutional neural network for semantic image segmentation of 2D RGB images

        [net, outputSize] = generateUnet2DwithEncoder(obj, imageSize, encoderNetwork) % enerate Unet convolutional neural network for semantic image segmentation of 2D RGB images using a specified encoder

        [patchOut, info, augList, augPars] = mibDeepAugmentAndCrop3dPatchMultiGPU(patchIn, info, inputPatchSize, outputPatchSize, mode, options) % augment patches for 3D in multi-gpu mode

        [patchOut, info, augList, augPars] = mibDeepAugmentAndCrop2dPatchMultiGPU(patchIn, info, inputPatchSize, outputPatchSize, mode, options) %  augment patches for 2D in multi-gpu mode

        TrainingOptions = preprareTrainingOptionsInstances(obj, valDS);     % prepare options for training of instance segmentation network

        function obj = mibDeepController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            obj.mibController = varargin{1};

            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget

            obj.TrainEngine = 'trainNetwork'; % original training engine

            % define available architectures
            workflowsList = {'2D Semantic', '2.5D Semantic', '3D Semantic', '2D Patch-wise', '2D Instance'};
            architectureList{1} = {'DeepLab v3+', 'SegNet', 'U-net', 'U-net +Encoder'};
            %architectureList{2} = {'3DC + DLv3 Resnet18', 'Z2C + DLv3 Resnet18', 'Z2C + DLv3 Resnet50', 'Z2C + U-net', 'Z2C + U-net +Encoder'};
            architectureList{2} = {'Z2C + DLv3', 'Z2C + U-net', 'Z2C + U-net +Encoder'}; % 3DC + DLv3 Resnet18'
            architectureList{3} = {'U-net', 'U-net Anisotropic'};
            architectureList{4} = {'Resnet18', 'Resnet50', 'Resnet101', 'Xception'};
            architectureList{5} = {'SOLOv2'};
            obj.availableArchitectures = containers.Map(workflowsList, architectureList);
            % define list of encoders for different architectures
            %workflowsArchList = {'2D Semantic DeepLab v3+', '2D Semantic U-net +Encoder', '2D Instance SOLOv2', '2.5D Semantic Z2C + U-net +Encoder', '2.5D Semantic Z2C + DLv3'};
            encodersList{1} = {'Resnet18', 'Resnet50', 'Xception', 'InceptionResnetv2', 1}; % for '2D Semantic DeepLab v3+'
            encodersList{2} = {'Classic', 'Resnet18', 'Resnet50', 2}; % for '2D Semantic U-net +Encoder'
            encodersList{3} = {'Resnet18', 'Resnet50', 1}; % for '2D Instance SOLOv2''
            encodersList{4} = {'Classic', 'Resnet18', 'Resnet50', 2}; % for '2D Semantic U-net +Encoder'
            encodersList{5} = {'Resnet18', 'Resnet50', 1}; % for '2.5D Semantic Z2C + DLv3'
            workflowsArchList = ["2D Semantic DeepLab v3+", "2D Semantic U-net +Encoder", "2D Instance SOLOv2", ...
                "2.5D Semantic Z2C + U-net +Encoder", "2.5D Semantic Z2C + DLv3"];
            %obj.availableEncoders = dictionary(workflowsArchList, encodersList); % dictionary available only from R2022b
            obj.availableEncoders = containers.Map(workflowsArchList, encodersList);

            obj.BatchOpt.NetworkFilename = fullfile(obj.mibModel.myPath, 'myLovelyNetwork.mibDeep');
            obj.BatchOpt.Workflow = {'2D Semantic'};
            obj.BatchOpt.Workflow{2} = workflowsList;
            obj.BatchOpt.Architecture = {'DeepLab v3+'};
            obj.BatchOpt.Architecture{2} = obj.availableArchitectures('2D Semantic');
            % 2D Semantic: {'U-net', 'SegNet', 'DLv3 Resnet18'}
            % 2.5D Semantic: {'3DC + DLv3 Resnet18', 'Z2C + U-net', 'Z2C + DLv3 Resnet18', 'Z2C + DLv3 Resnet50'}
            % 3D Semantic: {'U-net', '3D U-net Anisotropic'}
            % 2D Patch-wise: {'Resnet18', 'Resnet50', 'Resnet101', 'Xception'}
            obj.BatchOpt.Mode = {'Train'};
            obj.BatchOpt.Mode{2} = {'Train', 'Predict'};
            obj.BatchOpt.T_EncoderNetwork = {'Resnet18'};
            obj.BatchOpt.T_EncoderNetwork{2} = {'Classic', 'Resnet18', 'Resnet50'};
            obj.BatchOpt.T_ConvolutionPadding = {'same'};
            obj.BatchOpt.T_ConvolutionPadding{2} = {'same', 'valid'};
            obj.BatchOpt.T_InputPatchSize = '256 256 1 1';
            obj.BatchOpt.T_NumberOfClasses{1} = 2;
            obj.BatchOpt.T_NumberOfClasses{2} = [1 Inf];
            obj.BatchOpt.T_SegmentationLayer = {'dicePixelCustomClassificationLayer'};
            if verLessThan('matlab','9.8')  % 'focalLossLayer' - is available from R2020a
                obj.BatchOpt.T_SegmentationLayer{2} = {'pixelClassificationLayer', 'dicePixelClassificationLayer', 'dicePixelCustomClassificationLayer'};
            else
                obj.BatchOpt.T_SegmentationLayer{2} = {'pixelClassificationLayer', 'focalLossLayer', 'dicePixelClassificationLayer', 'dicePixelCustomClassificationLayer'};
            end
            obj.BatchOpt.T_ActivationLayer = {'reluLayer'};
            obj.BatchOpt.T_ActivationLayer{2} = {'clippedReluLayer', 'eluLayer', 'leakyReluLayer', 'reluLayer', 'swishLayer', 'tanhLayer'};
            obj.BatchOpt.T_EncoderDepth{1} = 3;
            obj.BatchOpt.T_EncoderDepth{2} = [1 Inf];
            obj.BatchOpt.T_NumFirstEncoderFilters{1} = 32;
            obj.BatchOpt.T_NumFirstEncoderFilters{2} = [1 Inf];
            obj.BatchOpt.T_FilterSize{1} = 3;
            obj.BatchOpt.T_FilterSize{2} = [3 Inf];
            obj.BatchOpt.T_UseImageNetWeights = false;
            obj.BatchOpt.T_PatchesPerImage{1} = 1;
            obj.BatchOpt.T_PatchesPerImage{2} = [1 Inf];
            obj.BatchOpt.T_MiniBatchSize{1} = obj.mibModel.preferences.Deep.MiniBatchSize;
            obj.BatchOpt.T_MiniBatchSize{2} = [1 Inf];
            obj.BatchOpt.T_augmentation = true;
            obj.BatchOpt.T_ExportTrainingPlots = true;
            obj.BatchOpt.T_SaveProgress = false;
            obj.BatchOpt.UseParallelComputing = false;
            obj.BatchOpt.T_RandomGeneratorSeed{1} = obj.mibModel.preferences.Deep.RandomGeneratorSeed;  % random seed generator for training
            obj.BatchOpt.T_RandomGeneratorSeed{2} = [0 Inf];
            obj.BatchOpt.T_RandomGeneratorSeed{3} = true;

            obj.BatchOpt.Bioformats = false;    % use bioformats file reader for prediction images
            obj.BatchOpt.BioformatsTraining = false;    % use bioformats file reader for training images
            obj.BatchOpt.BioformatsTrainingIndex{1} = 1;    % index of a serie to be used with bio-formats reader for training
            obj.BatchOpt.BioformatsTrainingIndex{2} = [1 Inf];
            obj.BatchOpt.BioformatsTrainingIndex{3} = true;
            obj.BatchOpt.BioformatsIndex{1} = 1; % index of a serie to be used with bio-formats reader for prediction
            obj.BatchOpt.BioformatsIndex{2} = [1 Inf];
            obj.BatchOpt.BioformatsIndex{3} = true;

            obj.BatchOpt.SingleModelTrainingFile = false;    % use single model file with the model
            obj.BatchOpt.ModelFilenameExtension = {'MODEL'};    % extension for model files
            obj.BatchOpt.ModelFilenameExtension{2} = {'MODEL', 'PNG', 'TIF', 'TIFF'};
            obj.BatchOpt.MaskFilenameExtension = {'MASK'};      % extension for mask files
            obj.BatchOpt.MaskFilenameExtension{2} = {'USE 0-s IN LABELS', 'MASK', 'PNG', 'TIF', 'TIFF'};

            if strcmp(obj.mibModel.preferences.Deep.OriginalTrainingImagesDir, '\')
                obj.BatchOpt.OriginalTrainingImagesDir = obj.mibModel.myPath;
                obj.BatchOpt.OriginalPredictionImagesDir = obj.mibModel.myPath;
                obj.BatchOpt.ResultingImagesDir = obj.mibModel.myPath;
            else
                obj.BatchOpt.OriginalTrainingImagesDir = obj.mibModel.preferences.Deep.OriginalTrainingImagesDir;
                obj.BatchOpt.OriginalPredictionImagesDir = obj.mibModel.preferences.Deep.OriginalPredictionImagesDir;
                obj.BatchOpt.ResultingImagesDir = obj.mibModel.preferences.Deep.ResultingImagesDir;
            end
            obj.BatchOpt.ImageFilenameExtension = obj.mibModel.preferences.Deep.ImageFilenameExtension;
            obj.BatchOpt.ImageFilenameExtension{2} = upper(obj.mibModel.preferences.System.Files.StdExt); %{'.AM', '.PNG', '.TIF'};
            obj.BatchOpt.ImageFilenameExtensionTraining = obj.mibModel.preferences.Deep.ImageFilenameExtension;
            obj.BatchOpt.ImageFilenameExtensionTraining{2} = upper(obj.mibModel.preferences.System.Files.StdExt); %{'.AM', '.PNG', '.TIF'};

            obj.BatchOpt.PreprocessingMode = {'Preprocessing is not required'};
            obj.BatchOpt.PreprocessingMode{2} = {'Training', 'Prediction', 'Training and Prediction', 'Preprocessing is not required', 'Split files for training/validation'};
            obj.BatchOpt.CompressProcessedImages = obj.mibModel.preferences.Deep.CompressProcessedImages;
            obj.BatchOpt.CompressProcessedModels = obj.mibModel.preferences.Deep.CompressProcessedModels;

            obj.BatchOpt.NormalizeImages = false;
            obj.BatchOpt.ValidationFraction{1} = obj.mibModel.preferences.Deep.ValidationFraction;
            obj.BatchOpt.ValidationFraction{2} = [0 1];
            obj.BatchOpt.ValidationFraction{3} = false;
            obj.BatchOpt.RandomGeneratorSeed{1} = obj.mibModel.preferences.Deep.RandomGeneratorSeed;
            obj.BatchOpt.RandomGeneratorSeed{2} = [0 Inf];
            obj.BatchOpt.RandomGeneratorSeed{3} = true;
            obj.BatchOpt.MaskAway = false;

            obj.BatchOpt.P_OverlappingTiles = true;
            obj.BatchOpt.P_OverlappingTilesPercentage{1} = 5;
            obj.BatchOpt.P_OverlappingTilesPercentage{2} = [1 100];
            obj.BatchOpt.P_OverlappingTilesPercentage{3} = true;
            obj.BatchOpt.P_PredictionMode = {'Blocked-image'};
            obj.BatchOpt.P_PredictionMode{2} = {'Blocked-image', 'Legacy'};
            obj.BatchOpt.P_ModelFiles = {'MIB Model format'};
            obj.BatchOpt.P_ModelFiles{2} = {'MIB Model format', 'TIF compressed format', 'TIF uncompressed format'};
            obj.BatchOpt.P_ScoreFiles = {'Use AM format'};
            obj.BatchOpt.P_ScoreFiles{2} = {'Do not generate', 'Use AM format', 'Use Matlab non-compressed format', 'Use Matlab compressed format', 'Use Matlab non-compressed format (range 0-1)'};
            obj.BatchOpt.P_ExtraPaddingPercentage{1} = 0;
            obj.BatchOpt.P_ExtraPaddingPercentage{2} = [0 100];
            obj.BatchOpt.P_ExtraPaddingPercentage{3} = false;
            obj.BatchOpt.P_ImageDownsamplingFactor{1} = 1;
            obj.BatchOpt.P_ImageDownsamplingFactor{2} = [1 Inf];
            obj.BatchOpt.P_ImageDownsamplingFactor{3} = false;
            obj.BatchOpt.P_MiniBatchSize{1} = 1;
            obj.BatchOpt.P_MiniBatchSize{2} = [1 Inf];
            obj.BatchOpt.P_MiniBatchSize{3} = true;
            obj.BatchOpt.P_PatchWiseUpsample = false;
            obj.BatchOpt.P_DynamicMasking = false;

            obj.BatchOpt.O_CustomTrainingProgressWindow = true;
            obj.BatchOpt.O_RefreshRateIter{1} = 5;
            obj.BatchOpt.O_RefreshRateIter{2} = [1 Inf];
            obj.BatchOpt.O_RefreshRateIter{3} = true;
            obj.BatchOpt.O_NumberOfPoints{1} = 1000;
            obj.BatchOpt.O_NumberOfPoints{2} = [50 Inf];
            obj.BatchOpt.O_NumberOfPoints{3} = true;
            obj.BatchOpt.O_PreviewImagePatches = true;
            obj.BatchOpt.O_FractionOfPreviewPatches{1} = .02;
            obj.BatchOpt.O_FractionOfPreviewPatches{2} = [0 1];

            obj.BatchOpt.showWaitbar = true;

            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Tools';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'mibDeep';           % name of the plugin
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.NetworkFilename = 'Network filename, a new filename for training or existing filename for prediction';
            obj.BatchOpt.mibBatchTooltip.Workflow = 'Targeted workflow to perform';
            obj.BatchOpt.mibBatchTooltip.Architecture = 'Architecture of the network';
            obj.BatchOpt.mibBatchTooltip.T_EncoderNetwork = 'Select backbone to modify the encoder part of the network';
            obj.BatchOpt.mibBatchTooltip.T_ConvolutionPadding = '"same": zero padding is applied to the inputs to convolution layers such that the output and input feature maps are the same size; "valid" - zero padding is not applied; the output feature map is smaller than the input feature map';
            obj.BatchOpt.mibBatchTooltip.Mode = 'Use tool in the training or prediction mode';
            obj.BatchOpt.mibBatchTooltip.T_InputPatchSize = 'Network input image size as [height width depth colors]';
            obj.BatchOpt.mibBatchTooltip.T_NumberOfClasses = 'Number of classes in the model including Exterior';
            obj.BatchOpt.mibBatchTooltip.T_ActivationLayer = 'Replace default activation layer with any one from this list';
            obj.BatchOpt.mibBatchTooltip.T_SegmentationLayer = 'Define the type of the last (segmentation) layer of the network';
            obj.BatchOpt.mibBatchTooltip.T_EncoderDepth = 'The depth of the network determines the number of times the input volumetric image is downsampled or upsampled during processing';
            obj.BatchOpt.mibBatchTooltip.T_NumFirstEncoderFilters = 'Number of output channels for the first encoder stage';
            obj.BatchOpt.mibBatchTooltip.T_FilterSize = 'Convolutional layer filter size, specified as a positive odd integer';
            obj.BatchOpt.mibBatchTooltip.T_UseImageNetWeights = 'Init the network with imagenet weights [MATLAB version of MIB only]';
            obj.BatchOpt.mibBatchTooltip.T_PatchesPerImage = 'Number of patches to extract from each image';
            obj.BatchOpt.mibBatchTooltip.T_MiniBatchSize = 'Number of observations that are returned in each batch';
            obj.BatchOpt.mibBatchTooltip.T_augmentation = 'Augment images during training';
            obj.BatchOpt.mibBatchTooltip.T_ExportTrainingPlots = 'When ticked, export training scores to files, which are placed to Results\ScoreNetwork folder';
            obj.BatchOpt.mibBatchTooltip.T_SaveProgress = 'When ticked the network progress is saved to Results\ScoreNetwork folder';
            obj.BatchOpt.mibBatchTooltip.OriginalTrainingImagesDir = 'Specify directory with original images and models. The images and models should be placed under "Images" and "Labels" subfolders correspondingly';
            obj.BatchOpt.mibBatchTooltip.OriginalPredictionImagesDir = 'Specify directory with original images for prediction';
            obj.BatchOpt.mibBatchTooltip.ImageFilenameExtension = 'Filename extension of original images used for prediction';
            obj.BatchOpt.mibBatchTooltip.ImageFilenameExtensionTraining = 'Filename extension of original images used for traininig';
            obj.BatchOpt.mibBatchTooltip.BioformatsTraining = 'Use Bioformats file reader for training images';
            obj.BatchOpt.mibBatchTooltip.BioformatsTrainingIndex = 'Index of a serie to be used with bio-formats reader or with TIFs for training';
            obj.BatchOpt.mibBatchTooltip.Bioformats = 'Use Bioformats file reader for prediction images';
            obj.BatchOpt.mibBatchTooltip.BioformatsIndex = 'Index of a serie to be used with bio-formats reader or with TIFs for prediction';
            obj.BatchOpt.mibBatchTooltip.ResultingImagesDir = 'Specify directory for resulting images for preprocessing and prediction, the following subfolders are used: TrainImages, TrainLabels, ValidationImages, ValidationLabels, PredictionImages';
            obj.BatchOpt.mibBatchTooltip.NormalizeImages = 'Normalize images during preprocessing, or use original images';
            obj.BatchOpt.mibBatchTooltip.CompressProcessedImages = 'Compression of images slows down performance but saves space';
            obj.BatchOpt.mibBatchTooltip.CompressProcessedModels = 'Compression of models slows down performance but saves space';
            obj.BatchOpt.mibBatchTooltip.PreprocessingMode = 'Preprocess images for prediction or training by splitting the datasets for training and validation';
            obj.BatchOpt.mibBatchTooltip.ValidationFraction = 'Fraction of images used for validation during training';
            obj.BatchOpt.mibBatchTooltip.RandomGeneratorSeed = 'Seed for random number generator used during splitting of test and validation datasets';
            obj.BatchOpt.mibBatchTooltip.T_RandomGeneratorSeed = 'Seed for random number generator used during initialization of training. Use 0 for random initialization each time or any other number for reproducibility';
            obj.BatchOpt.mibBatchTooltip.MaskAway = 'Mask away areas that should not be used for training, requires MIB *.mask files under Mask subfolder for preprocessing or use of 0s (Exterior) to specify mask out areas in models';
            obj.BatchOpt.mibBatchTooltip.SingleModelTrainingFile = 'When checked a single Model file with labels is used, when unchecked each image should have a corresponding model file with labels';
            obj.BatchOpt.mibBatchTooltip.ModelFilenameExtension = 'Extension for model filenames with labels, the files should be placed under "Labels" subfolder';
            obj.BatchOpt.mibBatchTooltip.MaskFilenameExtension = 'Extension for mask filenames, the files should be placed under "Masks" subfolder; when "Use 0-s IN LABELS" is selected mask is encoded with 0-indices, no preprocessing is required';
            obj.BatchOpt.mibBatchTooltip.P_MiniBatchSize = 'Number of patches processed simultaneously during prediction, increasing the MiniBatchSize value increases the efficiency, but it also takes up more GPU memory';
            obj.BatchOpt.mibBatchTooltip.P_OverlappingTiles = 'The ooverlapping tiles mode can be used with "same" padding. It is slower but in general expected to give better predictions';
            obj.BatchOpt.mibBatchTooltip.P_OverlappingTilesPercentage = 'Overlap percentage between tiles when predicting with the Overlapping tiles mode';
            obj.BatchOpt.mibBatchTooltip.P_ExtraPaddingPercentage = 'Add symmetric padding to images for prediction; it helps to minimize edge artefacts';
            obj.BatchOpt.mibBatchTooltip.P_ImageDownsamplingFactor = 'Downsample images by this number of times before prediction, [default=1, no downsampling]; for 2 classes predictions are also smoothed';
            obj.BatchOpt.mibBatchTooltip.P_DynamicMasking = 'When enabled, the images for predictions are thresholded to detect masked areas where segmentation occurs';
            obj.BatchOpt.mibBatchTooltip.P_PredictionMode = 'Main processing mode for prediction, the blocked image mode is recommended';
            obj.BatchOpt.mibBatchTooltip.P_ScoreFiles = 'tweak generation of score files showing probability of each class';
            obj.BatchOpt.mibBatchTooltip.P_ModelFiles = 'define output type for generated model files during prediction';
            obj.BatchOpt.mibBatchTooltip.P_PatchWiseUpsample = 'upsample generated patch predictions to match resolution of underlying images for direct comparison';
            obj.BatchOpt.mibBatchTooltip.O_CustomTrainingProgressWindow = 'When checked the custom progress plot is displayed during training, instead of Matlab default plot';
            obj.BatchOpt.mibBatchTooltip.O_RefreshRateIter = 'Refresh rate of the training progress window in iterations. Decrease for more frequent refresh, increase to speed up training performance';
            obj.BatchOpt.mibBatchTooltip.O_NumberOfPoints = 'Number of points in the training plot. Decrease to improve training performance, increase to see more detailed plot';
            obj.BatchOpt.mibBatchTooltip.O_PreviewImagePatches = 'Preview image patches that network is seeing with the cost of decreased training performance';
            obj.BatchOpt.mibBatchTooltip.O_FractionOfPreviewPatches = 'Fraction of image patches that has to be visualized. Decrease to improve performance, increase to see patches more frequently';

            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not waitbar');

            obj.AugOpt2D = obj.mibModel.preferences.Deep.AugOpt2D;
            obj.AugOpt3D = obj.mibModel.preferences.Deep.AugOpt3D;
            if isfield(obj.mibModel.preferences.Deep, 'PatchPreviewOpt')
                obj.PatchPreviewOpt = obj.mibModel.preferences.Deep.PatchPreviewOpt;
            else
                obj.PatchPreviewOpt.noImages = 9;         % number of images in montage
                obj.PatchPreviewOpt.imageSize = 160;         % patch image size for preview
                obj.PatchPreviewOpt.labelShow = true;   % display overlay labels with details
                obj.PatchPreviewOpt.labelSize = 9;      % font size for the label
                obj.PatchPreviewOpt.labelColor = 'black'; % color of the label
                obj.PatchPreviewOpt.labelBgColor = 'yellow'; % color of the label background
                obj.PatchPreviewOpt.labelBgOpacity = 0.6;   % opacity of the background
            end

            obj.InputLayerOpt = obj.mibModel.preferences.Deep.InputLayerOpt;
            obj.TrainingOpt = obj.mibModel.preferences.Deep.TrainingOpt;
            if ~isfield(obj.TrainingOpt, 'GradientDecayFactor')     % add new fields in MIB 2.71
                obj.TrainingOpt.GradientDecayFactor = 0.9;
                obj.TrainingOpt.SquaredGradientDecayFactor = 0.9;
                obj.TrainingOpt.ValidationPatience = Inf;
            end
            % dynamic masking properties
            obj.DynamicMaskOpt = obj.mibModel.preferences.Deep.DynamicMaskOpt;

            if isfield(obj.mibModel.preferences.Deep, 'ActivationLayerOpt')
                obj.ActivationLayerOpt = obj.mibModel.preferences.Deep.ActivationLayerOpt;
            else
                obj.ActivationLayerOpt.clippedReluLayer.Ceiling = 10;
                obj.ActivationLayerOpt.leakyReluLayer.Scale = 0.01;
                obj.ActivationLayerOpt.eluLayer.Alpha = 1;
            end

            if isfield(obj.mibModel.preferences.Deep, 'SegmentationLayerOpt')
                obj.SegmentationLayerOpt = obj.mibModel.preferences.Deep.SegmentationLayerOpt;
            else
                obj.SegmentationLayerOpt.focalLossLayer.Alpha = 0.25;
                obj.SegmentationLayerOpt.focalLossLayer.Gamma = 2;
                obj.mibModel.preferences.Deep.SegmentationLayerOpt.dicePixelCustom.ExcludeExerior = false;
            end

            % sending reports settings
            obj.SendReports = obj.mibModel.preferences.Deep.SendReports;

            obj.TrainingProgress = struct;
            obj.Aug2DFuncNames = [];    % names of augmentation functions for 2D
            obj.Aug3DFuncNames = [];    % names of augmentation functions for 3D
            obj.childControllers = {};    % initialize child controllers
            obj.childControllersIds = {};
            obj.gpuInfoFig = [];    % gpu info window
            obj.sessionSettings = struct();

            % set of default material colors for models
            obj.modelMaterialColors = [166 67 33; 71 178 126; 79 107 171; 150 169 213; 26 51 111; 255 204 102; 230 25 75; 255 225 25; 0 130 200; 245 130 48; 145 30 180; 70 240 240; 240 50 230; 210 245 60; 250 190 190; 0 128 128; 230 190 255; 170 110 40; 255 250 200; 128 0 0; 170 255 195; 128 128 0; 255 215 180; 0 0 128; 128 128 128; 60 180 75]/255;

            %% add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptIn = varargin{2};
                if isstruct(BatchOptIn) == 0
                    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 3rd parameter is required!'));
                    end
                    notify(obj, 'closeEvent');
                    return
                end
                % add/update BatchOpt with the provided fields in BatchOptIn
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptIn);

                obj.start();
                notify(obj, 'closeEvent');
                return;
            end

            guiName = 'mibDeepGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view

            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');

            % resize all elements of the GUI
            % mibRescaleWidgets(obj.View.gui); % this function is not yet
            % compatible with appdesigner

            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            % % this function is not yet
            global Font;
            if ~isempty(Font)
                if obj.View.handles.Workflow.FontSize ~= Font.FontSize + 4 ...   % guide font size is 4 points smaller than in appdesigner
                        || ~strcmp(obj.View.handles.Workflow.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end

            % add icons to buttons
            v = ver('Matlab');
            if str2num(v.Version) > 9.7
                obj.View.handles.LoadAndPreviewNetwork.Icon = obj.mibModel.sessionSettings.guiImages.eye;
            else
                obj.View.handles.LoadAndPreviewNetwork.Text = 'View';
            end
            obj.updateWidgets();

            % update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);

            obj.View.handles.PreprocessingParForWorkers.Limits = [0 obj.mibModel.cpuParallelLimit];
            obj.View.handles.PreprocessingParForWorkers.Value = obj.mibModel.cpuParallelLimit;

            % generate colormaps
            obj.colormap6 = [166 67 33; 71 178 126; 79 107 171; 150 169 213; 26 51 111; 255 204 102 ]/255;
            obj.colormap20 = [230 25 75; 255 225 25; 0 130 200; 245 130 48; 145 30 180; 70 240 240; 240 50 230; 210 245 60; 250 190 190; 0 128 128; 230 190 255; 170 110 40; 255 250 200; 128 0 0; 170 255 195; 128 128 0; 255 215 180; 0 0 128; 128 128 128; 60 180 75]/255;
            obj.colormap255 = rand([255,3]);

            %if isdeployed; obj.View.handles.ExportNetworkToONNXButton.Enable = 'off'; end

            obj.View.Figure.Figure.Visible = 'on';
            % obj.View.gui.WindowStyle = 'modal';     % make window modal

            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.viewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs

            % add drag-and-drop of the project config to the Network,
            % Preprocess, Train, Predict, Options panels
            DnD_uifigure(obj.View.handles.NetworkPanel, @(o, dat)obj.dnd_files_callback(o, dat));    % make sure that slashes are corrected to OS
            DnD_uifigure(obj.View.handles.Preprocess, @(o, dat)obj.dnd_files_callback(o, dat));
            DnD_uifigure(obj.View.handles.Train, @(o, dat)obj.dnd_files_callback(o, dat));
            DnD_uifigure(obj.View.handles.Predict, @(o, dat)obj.dnd_files_callback(o, dat));
            DnD_uifigure(obj.View.handles.Options, @(o, dat)obj.dnd_files_callback(o, dat));

            if gpuDeviceCount == 0
                obj.View.Figure.GPUDropDown.Items = {'CPU only', 'Parallel'};
                uialert(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nYou do not have compatible CUDA card or driver,\nwithout those the training will be extrelemy slow!'), ...
                    'Missing GPU', 'icon', 'warning');
            else
                clear gpuList;
                for deviceId = 1:gpuDeviceCount
                    gpuInfo = gpuDevice(deviceId);
                    gpuList{deviceId} = sprintf('%d. %s', deviceId, gpuInfo.Name); %#ok<AGROW>
                end
                if gpuDeviceCount > 1
                    gpuList{end+1} = 'Multi-GPU';
                end
                gpuList = [gpuList, {'CPU only'}, {'Parallel'}];
                obj.View.Figure.GPUDropDown.Items = gpuList;
                obj.View.Figure.GPUDropDown.Value = gpuList{1};
                gpuDevice(1);   % select 1st device
            end
        end

        function closeWindow(obj)
            % update preferences structure
            obj.mibModel.preferences.Deep.OriginalTrainingImagesDir = obj.BatchOpt.OriginalTrainingImagesDir;
            obj.mibModel.preferences.Deep.OriginalPredictionImagesDir = obj.BatchOpt.OriginalPredictionImagesDir;
            obj.mibModel.preferences.Deep.ImageFilenameExtension = obj.BatchOpt.ImageFilenameExtension;
            obj.mibModel.preferences.Deep.ResultingImagesDir = obj.BatchOpt.ResultingImagesDir;
            obj.mibModel.preferences.Deep.CompressProcessedImages = obj.BatchOpt.CompressProcessedImages;
            obj.mibModel.preferences.Deep.ValidationFraction = obj.BatchOpt.ValidationFraction{1};
            obj.mibModel.preferences.Deep.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
            obj.mibModel.preferences.Deep.RandomGeneratorSeed = obj.BatchOpt.RandomGeneratorSeed{1};
            %obj.mibModel.preferences.Deep.RelativePaths = obj.BatchOpt.RelativePaths;

            obj.mibModel.preferences.Deep.TrainingOpt = obj.TrainingOpt;
            obj.mibModel.preferences.Deep.AugOpt2D = obj.AugOpt2D;
            obj.mibModel.preferences.Deep.AugOpt3D = obj.AugOpt3D;
            obj.mibModel.preferences.Deep.InputLayerOpt = obj.InputLayerOpt;
            obj.mibModel.preferences.Deep.PatchPreviewOpt = obj.PatchPreviewOpt;
            obj.mibModel.preferences.Deep.ActivationLayerOpt = obj.ActivationLayerOpt;
            obj.mibModel.preferences.Deep.SegmentationLayerOpt = obj.SegmentationLayerOpt;
            obj.mibModel.preferences.Deep.DynamicMaskOpt = obj.DynamicMaskOpt;

            obj.mibModel.preferences.Deep.SendReports = obj.SendReports;

            % switch off warning for unetLayers
            warning('off', 'vision:semanticseg:unetLayersDeprecation')

            %obj.mibModel.preferences.Deep.AugOpt2D = obj.AugOpt2D;
            % close gpu into window if it is open
            if ~isempty(obj.gpuInfoFig) && isvalid(obj.gpuInfoFig)
                delete(obj.gpuInfoFig);
            end

            % closing mibDeepController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end

            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end

            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end

        function dnd_files_callback(obj, hWidget, dragIn)
            % function dnd_files_callback(obj, hWidget, dragIn)
            % drag and drop config name to obj.View.handles.NetworkPanel to
            % load it
            %
            % Parameters:
            % hWidget: a handle to the object where the drag action landed
            % dragIn: a structure containing the dragged object
            % .ctrlKey - 0/1 whether the control key was pressed
            % .shiftKey - 0/1 whether the control key was pressed
            % .names - cell array with filenames

            fullFilenameIn = dragIn.names{1};
            % fix the slash characters
            %fullFilenameIn = strrep(fullFilenameIn, '/', filesep);
            %fullFilenameIn = strrep(fullFilenameIn, '\', filesep);

            [pathIn, fnIn, extIn] = fileparts(fullFilenameIn);
            switch extIn
                case '.mibCfg'
                    obj.loadConfig(fullFilenameIn);
                case '.mibDeep'

            end
        end

        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window

            % updateWidgets normally triggered during change of MIB
            % buffers, make sure that any widgets related changes are
            % correctly propagated into the BatchOpt structure
            if isfield(obj.BatchOpt, 'id'); obj.BatchOpt.id = obj.mibModel.Id; end

            % update lined widgets
            event.Source.Tag = 'BioformatsTraining';
            obj.bioformatsCallback(event);
            event.Source.Tag = 'Bioformats';
            obj.bioformatsCallback(event);

            if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')
                obj.View.Figure.P_OverlappingTiles.Enable = 'on';
                obj.View.Figure.P_OverlappingTilesPercentage.Enable = 'on';
            else    % valid
                obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                obj.View.Figure.P_OverlappingTiles.Value = false;
                obj.BatchOpt.P_OverlappingTiles = false;
                obj.View.Figure.P_OverlappingTilesPercentage.Enable = 'off';
            end

            if strcmp(obj.BatchOpt.Workflow{1}, obj.View.handles.Workflow.Value) == 0
                obj.View.handles.Workflow.Value = obj.BatchOpt.Workflow{1};
                obj.selectWorkflow();
            end

            % when elements GIU needs to be updated, update obj.BatchOpt
            % structure and after that update elements of GUI by the
            % following function
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);    %

            % checking the folders
            foldersOk = 1;
            if ~isfolder(obj.BatchOpt.OriginalTrainingImagesDir)
                obj.BatchOpt.OriginalTrainingImagesDir = obj.mibModel.myPath;
                obj.View.Figure.OriginalTrainingImagesDir.Value = obj.mibModel.myPath;
                foldersOk = 0;
            end
            if ~isfolder(obj.BatchOpt.OriginalPredictionImagesDir)
                obj.BatchOpt.OriginalPredictionImagesDir = obj.mibModel.myPath;
                obj.View.Figure.OriginalPredictionImagesDir.Value = obj.mibModel.myPath;
                foldersOk = 0;
            end
            if ~isfolder(obj.BatchOpt.ResultingImagesDir)
                obj.BatchOpt.ResultingImagesDir = obj.mibModel.myPath;
                obj.View.Figure.ResultingImagesDir.Value = obj.mibModel.myPath;
                foldersOk = 0;
            end

            if obj.View.handles.UseParallelComputing.Value
                obj.View.handles.PreprocessingParForWorkers.Enable = 'on';
            else
                obj.View.handles.PreprocessingParForWorkers.Enable = 'off';
            end

            % sync number of classes between training and preprocessing tabs
            obj.View.handles.NumberOfClassesPreprocessing.Value = obj.BatchOpt.T_NumberOfClasses{1};

            obj.selectWorkflow();
            obj.singleModelTrainingFileValueChanged();

            % update preprocessing window widgets
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
                obj.View.handles.CompressProcessedImages.Enable = 'off';
                obj.View.handles.CompressProcessedModels.Enable = 'off';
            else
                if obj.BatchOpt.Workflow{1}(1) == '2'
                    obj.View.handles.SingleModelTrainingFile.Enable = 'on';
                end
                obj.View.handles.CompressProcessedImages.Enable = 'on';
                obj.View.handles.CompressProcessedModels.Enable = 'on';
            end

            if obj.BatchOpt.Workflow{1}(1) == '3'
                obj.View.handles.ModelFilenameExtension.Enable = 'off';
                obj.View.handles.MaskFilenameExtension.Enable = 'off';
            end

            % override settings when the instance segmentation mode is used
            if strcmp(obj.BatchOpt.Workflow{1}, '2D Instance')
                obj.View.handles.CompressProcessedImages.Enable = 'off'; % there is no image preprocessing for the instance segmentation
                obj.View.handles.NumberOfClassesPreprocessing.Enable = 'off';
                obj.View.handles.T_NumberOfClasses.Enable = 'off';
            else
                obj.View.handles.NumberOfClassesPreprocessing.Enable = 'on';
                obj.View.handles.T_NumberOfClasses.Enable = 'on';
            end

            % update widgets in Train panel
            obj.toggleAugmentations();
            obj.activationLayerChangeCallback();
            obj.setSegmentationLayer();

            % update widgets in Predict panel
            if strcmp(obj.BatchOpt.P_PredictionMode{1}, 'Blocked-image')
                obj.View.handles.P_DynamicMasking.Enable = 'on';
            else
                obj.View.handles.P_DynamicMasking.Enable = 'off';
            end

            % update widgets in Options panel
            if  obj.View.handles.O_CustomTrainingProgressWindow.Value
                obj.View.handles.O_RefreshRateIter.Enable = 'on';
                obj.View.handles.O_NumberOfPoints.Enable = 'on';
                obj.View.handles.O_PreviewImagePatches.Enable = 'on';
                if obj.View.handles.O_PreviewImagePatches.Value == 1
                    obj.View.handles.O_FractionOfPreviewPatches.Enable = 'on';
                else
                    obj.View.handles.O_FractionOfPreviewPatches.Enable = 'off';
                end
            else
                obj.View.handles.O_RefreshRateIter.Enable = 'off';
                obj.View.handles.O_NumberOfPoints.Enable = 'off';
                obj.View.handles.O_PreviewImagePatches.Enable = 'off';
                obj.View.handles.O_FractionOfPreviewPatches.Enable = 'off';
            end

            if foldersOk == 0 && obj.View.gui.Visible == true
                %warndlg(sprintf('!!! Warning !!!\n\nSome directories specified in the config file are missing!\nPlease check the directories in the Directories and Preprocessing tab'), 'Wrong directories');
                uialert(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nSome directories specified in the config file are missing!\nPlease check the directories in the Directories and Preprocessing tab'), ...
                    'Wrong directories', 'icon', 'warning');
            end

            obj.View.handles.T_SendReports.Value = obj.SendReports.T_SendReports;
        end

        function activationLayerChangeCallback(obj)
            % function activationLayerChangeCallback(obj)
            % callback for modification of the Activation Layer dropdown

            switch obj.View.handles.T_ActivationLayer.Value
                case {'leakyReluLayer', 'clippedReluLayer', 'eluLayer'}
                    obj.View.handles.T_ActivationLayerSettings.Enable = 'on';
                otherwise
                    obj.View.handles.T_ActivationLayerSettings.Enable = 'off';
            end
            obj.BatchOpt.T_ActivationLayer{1} = obj.View.handles.T_ActivationLayer.Value;
        end

        function setSegmentationLayer(obj)
            % function setSegmentationLayer(obj)
            % callback for modification of the Segmentation Layer dropdown

            switch obj.View.handles.T_SegmentationLayer.Value
                case {'focalLossLayer', 'dicePixelCustomClassificationLayer'}
                    obj.View.handles.T_SegmentationLayerSettings.Enable = 'on';
                otherwise   % classificationLayer, dicePixelClassificationLayer
                    obj.View.handles.T_SegmentationLayerSettings.Enable = 'off';
            end
            obj.BatchOpt.T_SegmentationLayer{1} = obj.View.handles.T_SegmentationLayer.Value;
        end

        function toggleAugmentations(obj)
            % function toggleAugmentations(obj)
            % callback for press of the T_augmentation checkbox
            if obj.View.handles.T_augmentation.Value == 1
                obj.View.handles.Augmentation2DSettings.Enable = 'on';
                obj.View.handles.Augmentation3DSettings.Enable = 'on';
                obj.View.handles.T_AugmentationPreview.Enable = 'on';
                obj.View.handles.T_AugmentationPreviewSettings.Enable = 'on';
            else
                obj.View.handles.Augmentation2DSettings.Enable = 'off';
                obj.View.handles.Augmentation3DSettings.Enable = 'off';
                obj.View.handles.T_AugmentationPreview.Enable = 'off';
                obj.View.handles.T_AugmentationPreviewSettings.Enable = 'off';
            end
            obj.BatchOpt.T_augmentation = logical(obj.View.handles.T_augmentation.Value);
        end

        function updateBatchOptFromGUI(obj, event)
            % function updateBatchOptFromGUI(obj, event)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % event: event from the callback

            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, event.Source);

            switch event.Source.Tag
                case 'P_PredictionMode'
                    switch event.Source.Value
                        case 'Blocked-image'
                            obj.View.handles.P_DynamicMasking.Enable = 'on';
                        case 'Legacy'
                            obj.View.handles.P_DynamicMasking.Enable = 'off';
                    end
                case 'T_ConvolutionPadding'
                    if strcmp(event.Source.Value, 'same')
                        obj.View.Figure.P_OverlappingTiles.Enable = 'on';
                        obj.View.Figure.P_OverlappingTilesPercentage.Enable = 'on';
                    else    % valid
                        obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                        obj.View.Figure.P_OverlappingTiles.Value = false;
                        obj.BatchOpt.P_OverlappingTiles = false;
                        obj.View.Figure.P_OverlappingTilesPercentage.Enable = 'off';
                    end
                case 'T_EncoderNetwork'
                    selectedEncoder = obj.BatchOpt.T_EncoderNetwork{1};
                    encoderKeyValue = [obj.BatchOpt.Workflow{1} ' ' obj.BatchOpt.Architecture{1}];
                    if isKey(obj.availableEncoders, encoderKeyValue)
                        if isa(obj.availableEncoders, 'containers.Map')
                            encodersList = obj.availableEncoders(encoderKeyValue);
                            selectedEncoderValue = find(ismember(encodersList(1:end-1), selectedEncoder));
                            obj.availableEncoders(encoderKeyValue) = [encodersList(1:end-1) {selectedEncoderValue}];
                        else % dictionary
                            obj.availableEncoders{encoderKeyValue}{end} = find(ismember(obj.availableEncoders{encoderKeyValue}(1:end-1), selectedEncoder));
                        end
                    end
            end
        end

        function singleModelTrainingFileValueChanged(obj, event)
            % function singleModelTrainingFileValueChanged(obj, event)
            % callback for press of SingleModelTrainingFile

            if nargin < 2; event.Source = obj.View.handles.SingleModelTrainingFile; end

            obj.updateBatchOptFromGUI(event);
            obj.View.handles.NumberOfClassesPreprocessing.Enable = 'on';
            if obj.BatchOpt.SingleModelTrainingFile
                
                obj.View.handles.ModelFilenameExtension.Enable = 'off';
                %obj.View.handles.MaskFilenameExtension.Enable = 'off';
                %obj.View.handles.NumberOfClassesPreprocessing.Enable = 'off';

                obj.View.handles.ModelFilenameExtension.Value = 'MODEL';
                obj.View.handles.MaskFilenameExtension.Value = 'MASK';
                event2.Source = obj.View.handles.ModelFilenameExtension;
                obj.updateBatchOptFromGUI(event2);
                event2.Source = obj.View.handles.MaskFilenameExtension;
                obj.updateBatchOptFromGUI(event2);
            else
                obj.View.handles.ModelFilenameExtension.Enable = 'on';
                obj.View.handles.MaskFilenameExtension.Enable = 'on';
            end
        end

        function selectWorkflow(obj, event)
            % function selectWorkflow(obj, event)
            % select deep learning workflow to perform
            if nargin < 2; event.Source = obj.View.handles.Workflow; end
            obj.updateBatchOptFromGUI(event);

            obj.View.handles.T_UseImageNetWeights.Enable = 'off';
            obj.View.handles.MaskAway.Enable = 'on';
            obj.View.handles.MaskFilenameExtension.Enable = 'on';

            switch obj.BatchOpt.Workflow{1}
                case '2D Semantic'
                    obj.BatchOpt.Architecture{2} = obj.availableArchitectures(obj.BatchOpt.Workflow{1});
                case '2.5D Semantic'
                    obj.BatchOpt.Architecture{2} = obj.availableArchitectures(obj.BatchOpt.Workflow{1});
                case '3D Semantic'
                    obj.BatchOpt.Architecture{2} = obj.availableArchitectures(obj.BatchOpt.Workflow{1});
                case '2D Patch-wise'
                    obj.BatchOpt.Architecture{2} = obj.availableArchitectures(obj.BatchOpt.Workflow{1});
                    obj.View.handles.T_UseImageNetWeights.Enable = 'on';
                    obj.View.handles.MaskAway.Enable = 'off';
                    obj.View.handles.MaskFilenameExtension.Enable = 'off';
                case '2D Instance'
                    obj.BatchOpt.Architecture{2} = obj.availableArchitectures(obj.BatchOpt.Workflow{1});
            end
            obj.View.handles.Architecture.Items = obj.BatchOpt.Architecture{2};
            obj.selectArchitecture();
        end

        function selectArchitecture(obj, event)
            % function selectArchitecture(obj, event)
            % select the target architecture

            if nargin < 2; event.Source = obj.View.handles.Architecture; end
            obj.updateBatchOptFromGUI(event);

            obj.View.handles.ModelFilenameExtension.Enable = 'on';
            obj.View.handles.SingleModelTrainingFile.Enable = 'on';

            obj.View.handles.T_EncoderNetwork.Enable = 'off';
            obj.View.handles.T_EncoderDepth.Enable = 'on';
            obj.View.handles.T_NumFirstEncoderFilters.Enable = 'on';
            obj.View.handles.T_FilterSize.Enable = 'on';
            obj.View.handles.T_ConvolutionPadding.Enable = 'on';
            obj.View.handles.T_EncoderDepth.Enable = 'on';
            obj.View.handles.T_PatchesPerImage.Enable = 'on';
            obj.View.handles.T_SegmentationLayer.Enable = 'on';
            obj.View.handles.P_OverlappingTiles.Enable = 'on';
            obj.View.handles.P_OverlappingTilesPercentage.Enable = 'on';
            obj.View.handles.P_PatchWiseUpsample.Enable = 'off';
            obj.View.handles.P_ExtraPaddingPercentage.Enable = 'on';
            obj.View.handles.T_EncoderNetwork.Enable = 'off';

            obj.TrainEngine = 'trainNetwork'; % original method

            switch obj.BatchOpt.Workflow{1}
                case '2D Semantic'
                    obj.View.handles.SingleModelTrainingFile.Enable = 'on';
                    switch obj.BatchOpt.Architecture{1}
                        case {'DeepLab v3+'}
                            obj.View.handles.T_EncoderDepth.Enable = 'off';
                            obj.View.handles.T_EncoderDepth.Value = 4;
                            obj.BatchOpt.T_EncoderDepth{1} = 4;
                            obj.View.handles.T_NumFirstEncoderFilters.Enable = 'off';
                            obj.View.handles.T_FilterSize.Enable = 'off';
                            obj.View.handles.T_EncoderNetwork.Enable = 'on';
                        case 'SegNet'
                            if obj.View.handles.SingleModelTrainingFile.Value == false
                                obj.View.handles.ModelFilenameExtension.Enable = 'on';
                            end
                            obj.View.Figure.T_ConvolutionPadding.Value = 'same';
                            obj.View.Figure.T_ConvolutionPadding.Enable = 'off';
                            obj.BatchOpt.T_ConvolutionPadding{1} = 'same';
                        case 'U-net'
                            obj.View.handles.SingleModelTrainingFile.Enable = 'on';
                            if obj.View.handles.SingleModelTrainingFile.Value == false
                                obj.View.handles.ModelFilenameExtension.Enable = 'on';
                            end
                        case 'U-net +Encoder'
                            obj.View.handles.T_EncoderNetwork.Enable = 'on';
                            obj.View.handles.SingleModelTrainingFile.Enable = 'on';
                            if obj.View.handles.SingleModelTrainingFile.Value == false
                                obj.View.handles.ModelFilenameExtension.Enable = 'on';
                            end
                            obj.TrainEngine = 'trainnet'; % new method for dlnetwork
                    end
                case '2.5D Semantic'
                    obj.View.handles.SingleModelTrainingFile.Enable = 'on';
                    switch obj.BatchOpt.Architecture{1}
                        case {'3DC + DLv3 Resnet18'}
                            obj.View.handles.T_EncoderDepth.Enable = 'off';
                            obj.View.handles.T_EncoderDepth.Value = 4;
                            obj.BatchOpt.T_EncoderDepth{1} = 4;
                        case {'Z2C + DLv3'}
                            obj.View.handles.T_EncoderDepth.Enable = 'off';
                            obj.View.handles.T_EncoderDepth.Value = 4;
                            obj.BatchOpt.T_EncoderDepth{1} = 4;
                            obj.View.handles.T_NumFirstEncoderFilters.Enable = 'off';
                            obj.View.handles.T_EncoderNetwork.Enable = 'on';
                        case {'Z2C + U-net'}
                            obj.View.handles.T_EncoderDepth.Enable = 'on';
                            obj.View.handles.T_EncoderDepth.Value = 3;
                            obj.BatchOpt.T_EncoderDepth{1} = 3;
                        case {'Z2C + U-net +Encoder'}
                            obj.View.handles.T_EncoderDepth.Enable = 'on';
                            obj.View.handles.T_EncoderDepth.Value = 3;
                            obj.BatchOpt.T_EncoderDepth{1} = 3;
                            obj.View.handles.T_EncoderNetwork.Enable = 'on';
                    end
                    obj.View.handles.SingleModelTrainingFile.Enable = 'off';
                    obj.View.handles.SingleModelTrainingFile.Value = false;
                case '3D Semantic'
                    obj.View.handles.SingleModelTrainingFile.Value = true;
                    event2.Source = obj.View.handles.SingleModelTrainingFile;
                    obj.singleModelTrainingFileValueChanged(event2);    % callback for press of Single MIB model checkbox
                    obj.View.handles.SingleModelTrainingFile.Enable = 'off';
                    obj.BatchOpt.SingleModelTrainingFile = false;
                case '2D Patch-wise'
                    % preprocessing tab
                    obj.View.handles.MaskAway.Enable = 'off';
                    obj.View.handles.MaskFilenameExtension.Enable = 'off';
                    obj.View.handles.NumberOfClassesPreprocessing.Enable = 'on';

                    % Train tab settings
                    obj.View.handles.T_ConvolutionPadding.Enable = 'off';
                    obj.View.handles.T_ConvolutionPadding.Value = 'same';
                    obj.BatchOpt.T_ConvolutionPadding{1} = 'same';
                    obj.View.handles.T_EncoderDepth.Enable = 'off';
                    obj.View.handles.T_PatchesPerImage.Enable = 'off';
                    obj.View.handles.T_SegmentationLayer.Enable = 'off';

                    % Prediction tab settings
                    obj.View.handles.P_PatchWiseUpsample.Enable = 'on';
                    obj.View.handles.P_ExtraPaddingPercentage.Enable = 'off';
                case '2D Instance'
                    obj.View.handles.T_EncoderNetwork.Enable = 'on';
            end

            if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                obj.View.Figure.P_OverlappingTilesPercentage.Enable = 'off';
            end

            % update encoders list
            encoderKeyValue = [obj.BatchOpt.Workflow{1} ' ' obj.BatchOpt.Architecture{1}];
            if isKey(obj.availableEncoders, encoderKeyValue)
                if isa(obj.availableEncoders, 'containers.Map')
                    encodersList = obj.availableEncoders(encoderKeyValue);
                    obj.BatchOpt.T_EncoderNetwork{2} = encodersList(1:end-1); % as the last value is the selected encoder
                    obj.BatchOpt.T_EncoderNetwork{1} = encodersList{encodersList{end}}; % as the last value is the selected encoder
                    obj.View.handles.T_EncoderNetwork.Items = obj.BatchOpt.T_EncoderNetwork{2};
                    obj.View.handles.T_EncoderNetwork.Value = obj.BatchOpt.T_EncoderNetwork{1};
                else % dictionary
                    obj.BatchOpt.T_EncoderNetwork{2} = obj.availableEncoders{encoderKeyValue}(1:end-1); % as the last value is the selected encoder
                    obj.BatchOpt.T_EncoderNetwork{1} = obj.availableEncoders{encoderKeyValue}{obj.availableEncoders{encoderKeyValue}{end}}; % as the last value is the selected encoder
                    obj.View.handles.T_EncoderNetwork.Items = obj.BatchOpt.T_EncoderNetwork{2};
                    obj.View.handles.T_EncoderNetwork.Value = obj.BatchOpt.T_EncoderNetwork{1};
                end
            end
        end

        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % via the notify 'syncBatch' event
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
            %
            if nargin < 2; BatchOptOut = obj.BatchOpt; end

            if isfield(BatchOptOut, 'id'); BatchOptOut = rmfield(BatchOptOut, 'id'); end  % remove id field
            % trigger syncBatch event to send BatchOptOut to mibBatchController
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end

        function bioformatsCallback(obj, event)
            % function bioformatsCallback(obj, event)
            % update available filename extensions
            %
            % Parameters:
            % event: an event structure of appdesigner

            extensionFieldName = 'ImageFilenameExtension';
            bioformatsFileName = 'Bioformats';
            indexFieldName = 'BioformatsIndex';
            if strcmp(event.Source.Tag, 'BioformatsTraining')
                extensionFieldName = 'ImageFilenameExtensionTraining';
                bioformatsFileName = 'BioformatsTraining';
                indexFieldName = 'BioformatsTrainingIndex';
            end

            obj.View.handles.(indexFieldName).Enable = 'on';
            if obj.BatchOpt.(bioformatsFileName)    % bio formats checkbox ticked
                obj.BatchOpt.(extensionFieldName){2} = upper(obj.mibModel.preferences.System.Files.BioFormatsExt); %{'.LEI', '.ZVI'};
            else
                obj.BatchOpt.(extensionFieldName){2} = upper(obj.mibModel.preferences.System.Files.StdExt); %{'.AM', '.PNG', '.TIF'};
                %                 if strcmp(indexFieldName, 'BioformatsTrainingIndex')
                %                     obj.View.handles.(indexFieldName).Enable = 'off';
                %                 end
            end
            if ~ismember(obj.BatchOpt.(extensionFieldName)(1), obj.BatchOpt.(extensionFieldName){2})
                obj.BatchOpt.(extensionFieldName)(1) = obj.BatchOpt.(extensionFieldName){2}(1);
            end

            obj.View.Figure.(extensionFieldName).Items = obj.BatchOpt.(extensionFieldName){2};
            obj.View.Figure.(extensionFieldName).Value = obj.BatchOpt.(extensionFieldName){1};
        end

        function net = selectNetwork(obj, networkName)
            % function net = selectNetwork(obj, networkName)
            % select a filename for a new network in the Train mode, or
            % select a network to use for the Predict mode
            %
            % Parameters:
            % networkName: optional parameter with the network full filename
            %
            % Return values:
            % net: trained network

            if nargin < 2; networkName = '';  end
            net = [];

            switch obj.BatchOpt.Mode{1}
                case 'Predict'
                    if isempty(networkName)
                        [file, path] = mib_uigetfile({'*.mibDeep;', 'Deep MIB network files (*.mibDeep)';
                            '*.mat', 'Mat files (*.mat)'}, 'Open network file', ...
                            obj.BatchOpt.NetworkFilename);
                        if isequal(file , 0); return; end
                        networkName = fullfile(path, file{1});
                    end
                    if exist(networkName, 'file') ~= 2
                        if obj.mibController.matlabVersion < 9.11 % 'Interpreter' is available only from R2021b
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nThe provided file does not exist!\n\n%s', networkName), ...
                                'Wrong network name', 'Icon', 'error');
                        else
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nThe provided file does not exist!\n\n%s', networkName), ...
                                'Wrong network name', 'Icon', 'error', 'Interpreter', 'html');
                        end
                        obj.View.Figure.NetworkFilename.Value = obj.BatchOpt.NetworkFilename;
                        % the two following commands are fix of sending the DeepMIB
                        % window behind main MIB window
                        drawnow;
                        figure(obj.View.gui);
                        return;
                    end

                    obj.wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Loading the network\nPlease wait...'), ...
                        'Title', 'Load network');

                    res = load(networkName, '-mat');     % loading 'net', 'TrainingOptions', 'classNames' variables
                    net = res.net;   % generate output network

                    % update waitbar
                    obj.wb.Value = 0.5;

                    % add/update BatchOpt with the provided fields in BatchOptIn
                    % combine fields from input and default structures
                    res.BatchOpt = rmfield(res.BatchOpt, ...
                        {'NetworkFilename', 'Mode', 'OriginalTrainingImagesDir', 'OriginalPredictionImagesDir', ...
                        'ResultingImagesDir', 'PreprocessingMode', 'CompressProcessedImages', 'showWaitbar', ...
                        'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'});

                    % update res.BatchOpt to be compatible with DeepMIB v2.83
                    res = obj.correctBatchOpt(res);
                    obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, res.BatchOpt);

                    try
                        if isfield(res.AugOpt2DStruct, 'ImageBlur') == 0
                            importFields = fieldnames(res.AugOpt2DStruct);
                            for fieldId = 1:length(importFields)
                                obj.AugOpt2D.(importFields{fieldId}) = res.AugOpt2DStruct.(importFields{fieldId});
                            end
                            uialert(obj.View.gui, sprintf('!!! Warning !!!\n\nYou are loading an old config file with a smaller number of augmentation options.\nThe loaded settings were merged with the current ones!'), 'Merge augmentation settings', 'icon', 'warning');
                        else
                            obj.AugOpt2D = mibConcatenateStructures(obj.AugOpt2D, res.AugOpt2DStruct);
                        end
                        obj.TrainingOpt = mibConcatenateStructures(obj.TrainingOpt, res.TrainingOptStruct);
                        if strcmp(obj.TrainingOpt.Plots, 'training-progress-Matlab'); obj.TrainingOpt.Plots = 'training-progress'; end
                        obj.InputLayerOpt = mibConcatenateStructures(obj.InputLayerOpt, res.InputLayerOpt);
                        obj.AugOpt3D = mibConcatenateStructures(obj.AugOpt3D, res.AugOpt3DStruct);

                        if ~isfield(obj.TrainingOpt, 'GradientDecayFactor')     % add new fields in MIB 2.71
                            obj.TrainingOpt.GradientDecayFactor = 0.9;
                            obj.TrainingOpt.SquaredGradientDecayFactor = 0.9;
                            obj.TrainingOpt.ValidationPatience = Inf;
                        end
                    catch err
                        % when the training was stopped before finish,
                        % those structures are not stored
                    end

                    obj.updateWidgets();

                    obj.wb.Value = 1;
                    delete(obj.wb);
                case {'Train', 'Preprocess'}
                    if isempty(networkName)
                        [file, path] = uiputfile({'*.mibDeep', 'mibDeep files (*.mibDeep)';
                            '*.mat', 'Mat files (*.mat)'}, 'Select network file', ...
                            obj.BatchOpt.NetworkFilename);
                        if file == 0; return; end
                        networkName = fullfile(path, file);
                    else
                        if exist(networkName, 'file') == 2
                            choice = questdlg(sprintf('!!! Warning !!!\n\nThe provided file already exist!\n\n%s\n\nWould you like to overwrite it for new training?', networkName), 'File exists!', 'Overwrite', 'Cancel', 'Cancel');
                            if strcmp(choice, 'Cancel')
                                obj.View.Figure.NetworkFilename.Value = obj.BatchOpt.NetworkFilename;
                                return;
                            end
                        end
                    end
            end
            obj.BatchOpt.NetworkFilename = networkName;
            obj.View.Figure.NetworkFilename.Value = obj.BatchOpt.NetworkFilename;
            % the two following commands are fix of sending the DeepMIB
            % window behind main MIB window
            drawnow;
            figure(obj.View.gui);
        end

        function selectDirerctories(obj, event)
            switch event.Source.Tag
                case 'SelectOriginalTrainingImagesDir'
                    fieldName = 'OriginalTrainingImagesDir';
                    title = 'Select directory with images and models for training';
                case 'SelectOriginalPredictionImagesDir'
                    fieldName = 'OriginalPredictionImagesDir';
                    title = 'Select directory with images for prediction';
                case 'SelectResultingImagesDir'
                    fieldName = 'ResultingImagesDir';
                    title = 'Select directory for results';
            end
            selpath = uigetdir(obj.BatchOpt.(fieldName), title);
            if selpath == 0; return; end
            % the two following commands are fix of sending the DeepMIB
            % window behind main MIB window
            drawnow;
            figure(obj.View.gui);
            obj.BatchOpt.(fieldName) = selpath;
            obj.View.Figure.(fieldName).Value = selpath;
        end

        function updateImageDirectoryPath(obj, event)
            % function updateImageDirectoryPath(obj, event)
            % update directories with images for training, prediction and
            % results
            fieldName = event.Source.Tag;
            value = obj.View.Figure.(fieldName).Value;
            if isfolder(value) == 0; obj.View.Figure.(fieldName).Value = obj.BatchOpt.(fieldName); return; end
            obj.BatchOpt.(fieldName) = value;
        end

        function checkNetwork(obj, fn)
            % function checkNetwork(obj, fn)
            % generate and check network using settings in the Train tab
            %
            % Parameters:
            % fn: optional string with filename (*.mibDeep) to preview its
            % configuration

            if nargin < 2; fn = []; end
            if ~isempty(fn) && exist(fn, 'file') == 0
                uialert(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nThe selected network file is empty!\n\nPlease check filename:\n%s', fn), ...
                    'Network file is missing!');
                return;
            end

            if isempty(fn)
                obj.wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Generating network\nPlease wait...'), ...
                    'Title', 'Generating network', 'Cancelable','on');
            else
                obj.wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('%s\nPlease wait...', fn), ...
                    'Title', 'Loading network', 'Cancelable','on');
            end
            if isempty(fn)
                previewSwitch = 1;  % indicate that the network is only for preview, the weights of classes won't be calculated
                [lgraph, outputPatchSize] = obj.createNetwork(previewSwitch);
                if isempty(lgraph); if ~isempty(obj.wb); delete(obj.wb); end; return; end
                if obj.wb.CancelRequested; delete(obj.wb); return; end

                architecture = obj.BatchOpt.Architecture{1};
                inputPatchSize = obj.BatchOpt.T_InputPatchSize;
                outputPatchSize = num2str(outputPatchSize);
            else
                try
                    loadedNet = load(fn, '-mat');   % load 'net'-variables
                    lgraph = loadedNet.net;
                    architecture = loadedNet.BatchOpt.Architecture{1};
                    inputPatchSize = loadedNet.BatchOpt.T_InputPatchSize;
                    outputPatchSize = num2str(loadedNet.outputPatchSize);
                catch err
                    %obj.showErrorDialog(err, 'Missing net-variable');
                    mibShowErrorDialog(obj.View.gui, err, 'Missing net-variable');
                    delete(obj.wb);
                    return;
                end
            end

            obj.wb.Value = 0.6;
            if ~isdeployed
                analyzeNetwork(lgraph);
            else
                uiFig = uifigure('Visible', 'off');
                ScreenSize = get(0, 'ScreenSize');
                FigPos(1) = 1/2*(ScreenSize(3)-800);
                FigPos(2) = 2/3*(ScreenSize(4)-900);
                uiFig.Position = [FigPos(1), FigPos(2), 800, 900];
                uiFig.Name = sprintf('Preview network (%s)', architecture);

                uiFigGridLayout = uigridlayout(uiFig);
                uiFigGridLayout.ColumnWidth = {'1x'};
                uiFigGridLayout.RowHeight = {40, '1x'};

                % Create previewTable
                previewTable = uitable(uiFigGridLayout);
                previewTable.ColumnName = {'Index'; 'Layer name'; 'Layer type'; 'Details'};
                previewTable.RowName = {};
                previewTable.Layout.Row = 2;
                previewTable.Layout.Column = 1;

                % text area
                textArea = uitextarea(uiFigGridLayout);
                textArea.Layout.Row = 1;
                textArea.Layout.Column = 1;

                % format lgraph into string
                layersStr = formattedDisplayText(lgraph.Layers);
                % split lines
                layerLines = splitlines(layersStr);
                % clip the header
                layerLines = layerLines(3:end);
                % allocate space for the table
                tableData = cell([numel(lgraph.Layers), 4]);
                for rowId=1:numel(layerLines)
                    if numel(layerLines{rowId}) > 1
                        % split line using more than 2 spaces
                        rowStr = strsplit(layerLines(rowId), '[ ]{3,}', 'DelimiterType', 'RegularExpression');
                        % populate the table data without the first empty entry
                        tableData(rowId,:) = rowStr(2:end).cellstr;
                    end
                end
                previewTable.Data = tableData;
                previewTable.ColumnWidth = {50, 'fit', 'fit','auto'};

                % add header
                textArea.Value = [  {sprintf('Architecture: %s', architecture)}; ...
                    {sprintf('Input patch size: %s   Output patch size: %s', inputPatchSize, outputPatchSize)} ];
                textArea.Editable = false;
                uiFig.Visible = 'on';

                % plot layer-graph, this function can not be included in uiFig
                figure;
                plot(lgraph);
                title(architecture);
            end
            obj.wb.Value = 1;
            delete(obj.wb);
        end

        function lgraph = updateNetworkInputLayer(obj, lgraph, inputPatchSize)
            % function lgraph = updateNetworkInputLayer(obj, lgraph, inputPatchSize)
            % update the input layer settings for lgraph
            % paramters are taken from obj.InputLayerOpt

            selectedWorkflow = obj.BatchOpt.Workflow{1};
            colorDimension = 4;
            if strcmp(selectedWorkflow, '2.5D Semantic') && strcmp(obj.BatchOpt.Architecture{1}(1:3), 'Z2C')
                selectedWorkflow = '2D Z2C';
                colorDimension = 3;
            end

            switch selectedWorkflow
                case {'2D Semantic',  '2D Z2C', '2D Patch-wise'}
                    % update the input layer settings
                    switch obj.InputLayerOpt.Normalization
                        case 'zerocenter'
                            inputLayer = imageInputLayer(inputPatchSize([1 2 colorDimension]), 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization, ...
                                'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]));
                        case 'zscore'
                            inputLayer = imageInputLayer(inputPatchSize([1 2 colorDimension]), 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization, ...
                                'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]), ...
                                'StandardDeviation', reshape(obj.InputLayerOpt.StandardDeviation, [1 1 numel(obj.InputLayerOpt.StandardDeviation)]));
                        case {'rescale-symmetric', 'rescale-zero-one'}
                            inputLayer = imageInputLayer(inputPatchSize([1 2 colorDimension]), 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization, ...
                                'Min', reshape(obj.InputLayerOpt.Min, [1 1 numel(obj.InputLayerOpt.Min)]), ...
                                'Max', reshape(obj.InputLayerOpt.Max, [1 1 numel(obj.InputLayerOpt.Max)]));
                        case 'none'
                            inputLayer = imageInputLayer(inputPatchSize([1 2 colorDimension]), 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization);
                        otherwise
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nWrong normlization paramter (%s)!\n\nUse one of those:\n - zerocenter\n - zscore\n - rescale-symmetric\n - rescale-zero-one\n - none', obj.InputLayerOpt.Normalization), ...
                                'Wrong normalization');
                            lgraph = [];
                            return;
                    end
                    switch obj.BatchOpt.Architecture{1}
                        case {'U-net', 'DeepLab v3+', 'Z2C + DLv3'}
                            try
                                %inputLayer.Name = 'data';
                                lgraph = replaceLayer(lgraph, lgraph.Layers(1).Name, inputLayer);
                                %lgraph = replaceLayer(lgraph, 'ImageInputLayer', inputLayer);
                            catch err
                                % when deeplabv3plusLayers used to generate
                                % one of the standard networks
                                lgraph = replaceLayer(lgraph, 'input_1', inputLayer);
                            end
                        case 'SegNet'
                            lgraph = replaceLayer(lgraph, 'inputImage', inputLayer);
                        case {'Resnet18', 'Resnet101'}
                            lgraph = replaceLayer(lgraph, 'data', inputLayer);
                        case {'Resnet50', 'Xception'}
                            lgraph = replaceLayer(lgraph, 'input_1', inputLayer);
                        case 'U-net +Encoder'
                            lgraph = replaceLayer(lgraph, lgraph.Layers(1).Name, inputLayer);
                    end
                case {'3D Semantic', '2.5D Semantic'}   % '2.5D Semantic' and '3D Semantic'
                    % update the input layer settings
                    switch obj.InputLayerOpt.Normalization
                        case 'zerocenter'
                            inputLayer = image3dInputLayer(inputPatchSize, 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization, ...
                                'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 1 numel(obj.InputLayerOpt.Mean)]));
                        case 'zscore'
                            inputLayer = image3dInputLayer(inputPatchSize, 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization, ...
                                'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]),...
                                'StandardDeviation', reshape(obj.InputLayerOpt.StandardDeviation, [1 1 1 numel(obj.InputLayerOpt.StandardDeviation)]));
                        case {'rescale-symmetric', 'rescale-zero-one'}
                            inputLayer = image3dInputLayer(inputPatchSize, 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization, ...
                                'Min', reshape(obj.InputLayerOpt.Min, [1 1 1 numel(obj.InputLayerOpt.Min)]), ...
                                'Max', reshape(obj.InputLayerOpt.Max, [1 1 1 numel(obj.InputLayerOpt.Max)]));
                        case 'none'
                            inputLayer = image3dInputLayer(inputPatchSize, 'Name', 'ImageInputLayer', ...
                                'Normalization', obj.InputLayerOpt.Normalization);
                        otherwise
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nWrong normlization paramter (%s)!\n\nUse one of those:\n - zerocenter\n - zscore\n - rescale-symmetric\n - rescale-zero-one\n - none', obj.InputLayerOpt.Normalization), ...
                                'Wrong normalization');
                            lgraph = [];
                            return;
                    end
                    lgraph = replaceLayer(lgraph, 'ImageInputLayer', inputLayer);
            end
        end

        function lgraph = updateActivationLayers(obj, lgraph)
            % update the activation layers depending on settings in
            % obj.BatchOpt.T_ActivationLayer and obj.ActivationLayerOpt

            % redefine the activation layers
            if ~strcmp(obj.BatchOpt.T_ActivationLayer{1}, 'reluLayer')
                ReLUIndices = zeros([numel(lgraph.Layers), 1]);
                % find indices of ReLU layers
                for layerId = 1:numel(lgraph.Layers)
                    if isa(lgraph.Layers(layerId), 'nnet.cnn.layer.ReLULayer')
                        ReLUIndices(layerId) = 1;
                    end
                end
                ReLUIndices = find(ReLUIndices);

                for id=1:numel(ReLUIndices)
                    layerId = ReLUIndices(id);
                    switch obj.BatchOpt.T_ActivationLayer{1}
                        case 'leakyReluLayer'
                            layer = leakyReluLayer(obj.ActivationLayerOpt.leakyReluLayer.Scale, 'Name', sprintf('leakyReLU-%d', id));
                        case 'clippedReluLayer'
                            layer = clippedReluLayer(obj.ActivationLayerOpt.clippedReluLayer.Ceiling, 'Name', sprintf('clippedReLU-%d', id));
                        case 'eluLayer'
                            layer = eluLayer(obj.ActivationLayerOpt.eluLayer.Alpha, 'Name', sprintf('ELU-%d', id));
                        case 'swishLayer'
                            layer = swishLayer('Name', sprintf('Swish-%d', id));
                        case 'tanhLayer'
                            layer = tanhLayer('Name', sprintf('Tahn-%d', id));
                            %case 'reluLayer'
                            %    layer = reluLayer('Name', sprintf('ReLU-%d', id));
                    end
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                end
            end
        end

        function lgraph = updateConvolutionLayers(obj, lgraph)
            % update the convolution layers by providing new set of weight
            % initializers

            weightsInitializer = 'glorot';
            % redefine the activation layers
            if ~strcmp(weightsInitializer, 'he')
                convIndices = zeros([numel(lgraph.Layers), 1]);
                % find indices of ReLU layers
                for layerId = 1:numel(lgraph.Layers)
                    if isa(lgraph.Layers(layerId), 'nnet.cnn.layer.Convolution2DLayer')
                        convIndices(layerId) = 1;
                    end
                end
                convIndices = find(convIndices);

                for id=1:numel(convIndices)
                    layerId = convIndices(id);
                    if strcmp(lgraph.Layers(layerId).PaddingMode, 'same')
                        layer = convolution2dLayer(lgraph.Layers(layerId).FilterSize, lgraph.Layers(layerId).NumFilters, ...
                            'Padding', 'same', ...
                            'Stride', lgraph.Layers(layerId).Stride, ...
                            'DilationFactor', lgraph.Layers(layerId).DilationFactor, ...
                            'NumChannels', lgraph.Layers(layerId).NumChannels, ...
                            'WeightsInitializer', weightsInitializer);
                    else
                        layer = convolution2dLayer(lgraph.Layers(layerId).FilterSize, lgraph.Layers(layerId).NumFilters, ...
                            'Stride', lgraph.Layers(layerId).Stride, ...
                            'DilationFactor', lgraph.Layers(layerId).DilationFactor, ...
                            'Padding', lgraph.Layers(layerId).PaddingSize, ...
                            'PaddingValue', lgraph.Layers(layerId).PaddingValue, ...
                            'NumChannels', lgraph.Layers(layerId).NumChannels, ...
                            'WeightsInitializer', weightsInitializer);
                    end

                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                end
            end
        end

        function lgraph = updateMaxPoolAndTransConvLayers(obj, lgraph, poolSize)
            % function lgraph = updateMaxPoolAndTransConvLayers(obj, lgraph, poolSize)
            % update maxPool and TransposedConvolution layers depending
            % on network downsampling factor only for U-net and SegNet.
            % This function is applied when the network downsampling factor
            % is different from 2

            if nargin < 3
                % downsampling factor
                poolSize = obj.View.handles.T_DownsamplingFactor.Value;
            end

            if poolSize ~= 2 && ismember(obj.BatchOpt.Architecture{1}, {'U-net', 'SegNet', 'Z2C + U-net'})
                maxPoolIndices = zeros([numel(lgraph.Layers), 1]);
                transConvIndices = zeros([numel(lgraph.Layers), 1]);
                % find indices of ReLU layers
                for layerId = 1:numel(lgraph.Layers)
                    if isa(lgraph.Layers(layerId), 'nnet.cnn.layer.MaxPooling2DLayer') || isa(lgraph.Layers(layerId), 'nnet.cnn.layer.MaxPooling3DLayer')
                        maxPoolIndices(layerId) = 1;
                    end
                    if isa(lgraph.Layers(layerId), 'nnet.cnn.layer.TransposedConvolution2DLayer') || isa(lgraph.Layers(layerId), 'nnet.cnn.layer.TransposedConvolution3DLayer')
                        transConvIndices(layerId) = 1;
                    end
                end
                maxPoolIndices = find(maxPoolIndices);
                transConvIndices = find(transConvIndices);

                for id=1:numel(maxPoolIndices)
                    layerId = maxPoolIndices(id);
                    switch obj.BatchOpt.Architecture{1}
                        case {'U-net', 'Z2C + U-net'}
                            if strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D') || strcmp(obj.BatchOpt.Workflow{1}(1:2), '2.')
                                layer = maxPooling2dLayer([poolSize, poolSize], 'Stride', [poolSize poolSize], ...
                                    'Name', lgraph.Layers(layerId).Name);
                            else
                                layer = maxPooling3dLayer([poolSize, poolSize, poolSize], 'Stride', [poolSize poolSize, poolSize], ...
                                    'Name', lgraph.Layers(layerId).Name);
                            end
                        case 'SegNet'
                            layer = maxPooling2dLayer([poolSize, poolSize], 'Stride', [poolSize poolSize], ...
                                'Name', lgraph.Layers(layerId).Name, ...
                                'HasUnpoolingOutputs', lgraph.Layers(layerId).HasUnpoolingOutputs);
                    end
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                end

                for id=1:numel(transConvIndices)
                    layerId = transConvIndices(id);
                    if strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D') || strcmp(obj.BatchOpt.Workflow{1}(1:2), '2.')
                        layer = transposedConv2dLayer(poolSize,  lgraph.Layers(layerId).NumFilters, 'Stride', poolSize, ...
                            'Name', lgraph.Layers(layerId).Name);
                    else
                        layer = transposedConv3dLayer(poolSize,  lgraph.Layers(layerId).NumFilters, 'Stride', [poolSize, poolSize, poolSize], ...
                            'Name', lgraph.Layers(layerId).Name);
                    end
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                end
            end
        end

        function lgraph = updateSegmentationLayer(obj, lgraph, classNames)
            % function lgraph = updateSegmentationLayer(obj, lgraph, classNames)
            % redefine the segmentation layer of lgraph based on
            % obj.BatchOpt settings
            %
            % Parameters:
            % classNames: cell array with class names, when not provided is 'auto' switch is used

            if nargin < 3; classNames = 'auto'; end

            switch obj.BatchOpt.T_SegmentationLayer{1}
                case 'weightedClassificationLayer'
                    %                         if previewSwitch == 0
                    %                             reset(pxds);
                    %                             Labels = read(pxds);
                    %                             for classId = 1:numel(obj.BatchOpt.T_NumberOfClasses{1})
                    %                                 classWeights(classId) = numel(find(Labels{1}==classNames{classId}));
                    %                             end
                    %                             classWeights = 1-(classWeights./sum(classWeights));
                    %                         else
                    %                             classWeights = ones([obj.BatchOpt.T_NumberOfClasses{1} 1])/obj.BatchOpt.T_NumberOfClasses{1};
                    %                         end
                    classWeights = [0.8251 0.1429 0.0283 0.0038];
                    outputLayer = weightedClassificationLayer('Segmentation-Layer', classWeights);
                    %if previewSwitch == 0; reset(pxds); end
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
                            outputLayerName = 'Custom Dice Segmentation Layer 3D';
                            dataDimension = 3;
                        case {'2D Semantic', '2D Patch-wise', '2.5D Semantic'}
                            if strcmp(obj.BatchOpt.Architecture{1}(1:3), 'Z2C') || strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D')
                                outputLayerName = 'Custom Dice Segmentation Layer 2D';
                                dataDimension = 2;
                            else    % '2.5D Semantic'
                                outputLayerName = 'Custom Dice Segmentation Layer 3D';
                                dataDimension = 2.5;
                            end
                    end
                    outputLayer = dicePixelCustomClassificationLayer(outputLayerName, dataDimension, useClasses);
                    outputLayer.Classes = classNames;
                    % check layer
                    %layer = dicePixelCustomClassificationLayer(outputLayerName);
                    %numClasses = 4;
                    %validInputSize = [4 4 numClasses];
                    %checkLayer(layer,validInputSize, 'ObservationDimension',4)
                case 'focalLossLayer'
                    segLayerInitString = sprintf('outputLayer = %s(''Alpha'', %.3f, ''Gamma'', %.3f, ''Classes'', classNames, ''Name'', ''Segmentation-Layer'');', ...
                        obj.BatchOpt.T_SegmentationLayer{1}, ...
                        obj.SegmentationLayerOpt.focalLossLayer.Alpha, obj.SegmentationLayerOpt.focalLossLayer.Gamma);
                    eval(segLayerInitString);
                otherwise
                    segLayerInitString = sprintf('outputLayer = %s(''Name'', ''Segmentation-Layer'', ''Classes'', classNames);', obj.BatchOpt.T_SegmentationLayer{1});
                    eval(segLayerInitString);
            end

            switch obj.BatchOpt.Workflow{1}
                case {'2D Semantic', '2.5D Semantic'}
                    switch obj.BatchOpt.Architecture{1}
                        case {'U-net', 'DeepLab v3+', ...
                                '3DC + DLv3 Resnet18', ...
                                'Z2C + U-net', 'Z2C + DLv3'}
                            try
                                lgraph = replaceLayer(lgraph, 'Segmentation-Layer', outputLayer);
                            catch err
                                if contains(lower(lgraph.Layers(end).Name), 'segmentation')
                                    lgraph = replaceLayer(lgraph, lgraph.Layers(end).Name, outputLayer);
                                else
                                    % when deeplabv3plusLayers used to generate
                                    % one of the standard networks
                                    lgraph = replaceLayer(lgraph, 'classification', outputLayer);
                                end
                            end
                        case 'SegNet'
                            lgraph = replaceLayer(lgraph, 'pixelLabels', outputLayer);
                    end
                case '3D Semantic'
                    if strcmp(obj.BatchOpt.Architecture{1}, 'U-net')
                        try
                            lgraph = replaceLayer(lgraph, 'Segmentation-Layer', outputLayer);
                        catch err
                            if contains(lower(lgraph.Layers(end).Name), 'segmentation')
                                lgraph = replaceLayer(lgraph, lgraph.Layers(end).Name, outputLayer);
                            else
                                % when deeplabv3plusLayers used to generate
                                % one of the standard networks
                                lgraph = replaceLayer(lgraph, 'classification', outputLayer);
                            end
                        end
                    end
                case '2D Patch-wise'
                    lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', outputLayer);
            end
        end

        function [status, augNumber] = setAugFuncHandles(obj, mode, augOptions)
            % function [status, augNumber] = setAugFuncHandles(obj, mode, augOptions)
            % define list of 2D/3D augmentation functions
            %
            % Parameters:
            % mode: string defining '2D' or '3D' augmentations
            % augOptions: a custom temporary structure with augmentation
            %    options to be used instead of obj.AugOpt2D and obj.AugOpt3D.
            %    It is used by mibDeepAugmentSettingsController to preview
            %    selected augmentations
            %
            % Return values:
            % status: a logical success switch (1-success, 0- fail)
            % augNumber: number of selected augmentations

            status = 0;
            augNumber = 0;

            if nargin < 3
                if strcmp(mode, '2D')
                    % an old legacy setting for augmentations that may
                    % sneak into the current set.
                    if isfield(obj.AugOpt2D, 'ImageNoise')
                        obj.AugOpt2D = rmfield(obj.AugOpt2D, 'ImageNoise');
                    end
                    augOptions = obj.AugOpt2D;
                else    % '2.5D Semantic' and '3D Semantic'
                    augOptions = obj.AugOpt3D;
                end
            end

            if strcmp(mode, '2D')
                switch2D = true;  % 2D mode switch
                AugFuncNamesField = 'Aug2DFuncNames';
                AugFuncProbabilityField = 'Aug2DFuncProbability';
            else    % '2.5D Semantic' and '3D Semantic'
                switch2D = false; % 3D mode
                AugFuncNamesField = 'Aug3DFuncNames';
                AugFuncProbabilityField = 'Aug3DFuncProbability';
            end

            obj.(AugFuncNamesField) = [];
            obj.(AugFuncProbabilityField) = [];  % probability of each augmentation to be triggered

            augmentationNames = fieldnames(augOptions);
            for augId=1:numel(augmentationNames)
                switch augmentationNames{augId}
                    case {'Fraction', 'FillValue'}
                        continue;
                    otherwise
                        if augOptions.(augmentationNames{augId}).Enable
                            obj.(AugFuncNamesField) = [obj.(AugFuncNamesField), augmentationNames(augId)];
                            obj.(AugFuncProbabilityField) = [obj.(AugFuncProbabilityField), augOptions.(augmentationNames{augId}).Probability];
                        end
                end
            end

            if isempty(obj.(AugFuncNamesField))
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nAugmentation filters were not selected or their probabilities are zero!\nPlease use set 2D augmentation settings dialog (Train tab->Augmentation->2D) to set them up'), ...
                    'Wrong augmentations');
                return;
            end
            augNumber = numel(obj.(AugFuncNamesField));
            status = 1;
        end

        function [dataOut, info] = classificationAugmentationPipeline(obj, dataIn, info, inputPatchSize, outputPatchSize, mode)
            dataOut = cell([size(dataIn,1),2]);

            for idx = 1:size(dataIn,1)
                temp = dataIn{idx};

                % Add randomized Gaussian blur
                temp = imgaussfilt(temp,1.5*rand);

                % Add salt and pepper noise
                temp = imnoise(temp,'salt & pepper');

                % Add randomized rotation and scale
                tform = randomAffine2d('Scale',[0.95,1.05],'Rotation',[-30 30]);
                outputView = affineOutputView(size(temp),tform);
                temp = imwarp(temp,tform,'OutputView',outputView);

                % Form second column expected by trainNetwork which is the expected response,
                % the categorical label in this case
                dataOut(idx,:) = {temp,info.Label(idx)};
            end
        end

        function setAugmentation3DSettings(obj)
            % function setAugmentation3DSettings(obj)
            % update settings for augmentation fo 3D images

            if ~isstruct(obj.AugOpt3D.RandScale)
                obj.AugOpt3D = mibDeepConvertOldAugmentationSettingsToNew(obj.AugOpt3D, '3D');
            end
            obj.startController('mibDeepAugmentSettingsController', obj, '3D');
        end

        function setActivationLayerOptions(obj)
            % function setActivationLayerOptions(obj)
            % update options for the activation layers
            global mibPath;
            switch obj.BatchOpt.T_ActivationLayer{1}
                case 'clippedReluLayer'
                    prompts = {'Ceiling for input clipping, positive scalar [default=10]'};
                    defAns = {num2str(obj.ActivationLayerOpt.clippedReluLayer.Ceiling)};
                    options.PromptLines = 2;
                case 'eluLayer'
                    prompts = {sprintf('Nonlinearity parameter alpha\nThe minimum value of the output of the ELU layer equals -Alpha and the slope at negative inputs approaching 0 is Alpha\nnumeric scalar [default=1]')};
                    defAns = {num2str(obj.ActivationLayerOpt.eluLayer.Alpha)};
                    options.PromptLines = 6;
                case 'leakyReluLayer'
                    prompts = {'Scalar multiplier for negative input values, numeric scalar [default=0.01]'};
                    defAns = {num2str(obj.ActivationLayerOpt.leakyReluLayer.Scale)};
                    options.PromptLines = 2;
            end
            dlgTitle = 'Activation layer options';
            options.WindowStyle = 'normal';
            %options.WindowWidth = 1;    % [optional] make window x1.2 times wider

            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            switch obj.BatchOpt.T_ActivationLayer{1}
                case 'clippedReluLayer'
                    obj.ActivationLayerOpt.clippedReluLayer.Ceiling = str2double(answer{1});
                case 'eluLayer'
                    obj.ActivationLayerOpt.eluLayer.Alpha = str2double(answer{1});
                case 'leakyReluLayer'
                    obj.ActivationLayerOpt.leakyReluLayer.Scale = str2double(answer{1});
            end
        end

        function setSegmentationLayerOptions(obj)
            % function setSegmentationLayerOptions(obj)
            % update options for the activation layers
            global mibPath;

            switch obj.BatchOpt.T_SegmentationLayer{1}
                case 'focalLossLayer'
                    prompts = {sprintf('Alpha, balancing parameter of the focal loss function\nThe Alpha value scales the loss function linearly, when decreasing Alpha, increase Gamma\npositive real number, [default=0.25]'); ...
                        sprintf('Gamma, focusing parameter of the focal loss function\nIncreasing the value of Gamma increases the sensitivity of the network to misclassified observations\npositive real number [default=2]')};
                    defAns = {num2str(obj.SegmentationLayerOpt.focalLossLayer.Alpha);...
                        num2str(obj.SegmentationLayerOpt.focalLossLayer.Gamma)};
                    options.PromptLines = [5 5];
                case 'dicePixelCustomClassificationLayer'
                    prompts = {sprintf('Exclude the Exterior (default: false)')};
                    defAns = {obj.SegmentationLayerOpt.dicePixelCustom.ExcludeExerior};
                    options.PromptLines = 3;
                    options.TitleLines = 4;
                    options.Title = sprintf('EXPERIMENTAL!\nExclude the Exterior (background) class\nfrom calculation of the loss function\n(disabled when 0-pixels used as mask)');
            end
            dlgTitle = 'Segmentation layer options';
            options.WindowStyle = 'normal';
            options.WindowWidth = 1.2;    % [optional] make window x1.2 times wider

            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            switch obj.BatchOpt.T_SegmentationLayer{1}
                case 'focalLossLayer'
                    obj.SegmentationLayerOpt.focalLossLayer.Alpha = str2double(answer{1});
                    obj.SegmentationLayerOpt.focalLossLayer.Gamma = str2double(answer{2});
                case 'dicePixelCustomClassificationLayer'
                    obj.SegmentationLayerOpt.dicePixelCustom.ExcludeExerior = logical(answer{1});
            end
        end

        function setAugmentation2DSettings(obj)
            % function setAugmentation2DSettings(obj)
            % update settings for augmentation fo 2D images
            if ~isstruct(obj.AugOpt2D.RandScale)
                obj.AugOpt2D = mibDeepConvertOldAugmentationSettingsToNew(obj.AugOpt2D, '2D');
            end
            obj.startController('mibDeepAugmentSettingsController', obj, '2D');
        end

        function setInputLayerSettings(obj)
            % update init settings for the input layer of networks
            global mibPath;

            prompts = {...
                sprintf('Data normalization\n"zerocenter" - subtract the mean specified by Mean\n"zscore" - subtract the mean specified by Mean and divide by StandardDeviation\n"rescale-symmetric" - rescale the input to be in the range [-1, 1] using the minimum and maximum values specified by Min and Max, respectively\n"rescale-zero-one" - rescale the input to be in the range [0, 1] using the minimum and maximum values specified by Min and Max, respectively\n"none" - do not normalize the input data'); ...
                sprintf('\nThe following fields may be empty for automatic calculations during training or be an array of values per channel or a numeric scalar\n\nMean [zerocenter or z-score]'); ...
                sprintf('Standard deviation for z-score normalization [z-score]'); ...
                sprintf('Minimum value for rescaling [rescale-symmetric or rescale-zero-one]');...
                sprintf('Maximum value for rescaling [rescale-symmetric or rescale-zero-one]')};

            defAns = {{'zerocenter', 'zscore', 'rescale-symmetric', 'rescale-zero-one', 'none', find(ismember({'zerocenter', 'zscore', 'rescale-symmetric', 'rescale-zero-one', 'none'}, obj.InputLayerOpt.Normalization))};...
                num2str(reshape(obj.InputLayerOpt.Mean, [1 numel(obj.InputLayerOpt.Mean)]));
                num2str(reshape(obj.InputLayerOpt.StandardDeviation, [1 numel(obj.InputLayerOpt.StandardDeviation)]));
                num2str(reshape(obj.InputLayerOpt.Min, [1 numel(obj.InputLayerOpt.Min)]));
                num2str(reshape(obj.InputLayerOpt.Max, [1 numel(obj.InputLayerOpt.Max)]))};
            dlgTitle = 'Input layer settings';
            options.WindowStyle = 'normal';
            options.PromptLines = [8, 5, 1, 1, 1];
            options.WindowWidth = 2.1;
            options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/nnet.cnn.layer.image3dinputlayer.html'; % [optional], an url for the Help button

            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            obj.InputLayerOpt.Normalization = answer{1};
            obj.InputLayerOpt.Mean = str2num(answer{2});
            obj.InputLayerOpt.StandardDeviation = str2num(answer{3});
            obj.InputLayerOpt.Min = str2num(answer{4});
            obj.InputLayerOpt.Max = str2num(answer{5});
        end

        function setTrainingSettings(obj)
            % update settings for training of networks
            global mibPath;

            prompts = {'solverName, solver for training network'; ...
                'MaxEpochs, maximum number of epochs to use for training [30]'; ...
                'Shuffle, options for data shuffling [once]'; ...
                'InitialLearnRate, used for training;  The default value is 0.01 for the "sgdm" solver and 0.001 for the "rmsprop" and "adam" solvers. If the learning rate is too low, then training takes a long time. If the learning rate is too high, then training might reach a suboptimal result or diverge'; ...
                'LearnRateSchedule, option for dropping learning rate during training [none]';...
                'LearnRateDropPeriod, [piecewise only] number of epochs for dropping the learning rate [50]';...
                'LearnRateDropFactor, [piecewise only] factor for dropping the learning rate, should be between 0 and 1 [0.9]';...
                'L2Regularization, factor for L2 regularization (weight decay) [0.0001]';...
                'Momentum, [sgdm only] contribution of the parameter update step of the previous iteration to the current iteration of sgdm [0.9]';...
                'Decay rate of gradient moving average [adam only], a non-negative scalar less than 1 [0.9]'; ...
                'Decay rate of squared gradient moving average for the Adam and RMSProp solvers [0.999 Adam, 0.9 PMSProp]'; ...
                'ValidationFrequency, number of validations per Epoch [0.2, i.e. once in 5 epochs]';...
                'Patience of validation stopping of network training, the number of times that the loss on the validation set can be larger than or equal to the previously smallest loss before network training stops [Inf]'; ...
                'Plots, plots to display during network training';
                'OutputNetwork, type of the returned network (R2021b)';
                'Frequency of saving checkpoint networks once per N epochs (R2022a)'};
            defAns = {{'adam', 'rmsprop', 'sgdm', find(ismember({'adam', 'rmsprop', 'sgdm'}, obj.TrainingOpt.solverName))};...
                num2str(obj.TrainingOpt.MaxEpochs);...
                {'once', 'never', 'every-epoch', find(ismember({'once', 'never', 'every-epoch'}, obj.TrainingOpt.Shuffle))};...
                num2str(obj.TrainingOpt.InitialLearnRate);...
                {'none', 'piecewise', find(ismember({'none', 'piecewise'}, obj.TrainingOpt.LearnRateSchedule))};...
                num2str(obj.TrainingOpt.LearnRateDropPeriod);...
                num2str(obj.TrainingOpt.LearnRateDropFactor);...
                num2str(obj.TrainingOpt.L2Regularization);...
                num2str(obj.TrainingOpt.Momentum);...
                num2str(obj.TrainingOpt.GradientDecayFactor);...
                num2str(obj.TrainingOpt.SquaredGradientDecayFactor);...
                num2str(obj.TrainingOpt.ValidationFrequency);...
                num2str(obj.TrainingOpt.ValidationPatience);...
                {'training-progress', 'none', find(ismember({'training-progress', 'none'}, obj.TrainingOpt.Plots))};...
                {'last-iteration', 'best-validation-loss', find(ismember({'last-iteration', 'best-validation-loss'}, obj.TrainingOpt.OutputNetwork))};...
                num2str(obj.TrainingOpt.CheckpointFrequency)};
            dlgTitle = 'Training settings';
            options.WindowStyle = 'normal';
            options.PromptLines = [1, 2, 1, 6, 2, ...
                2, 3, 2, 3, 2, 3, 2, 3, 1, 2, 2];   % [optional] number of lines for widget titles
            %options.Title = 'My test Input dialog';   % [optional] additional text at the top of the window
            %options.TitleLines = 2;                   % [optional] make it twice tall, number of text lines for the title
            options.WindowWidth = 1.9;    % [optional] make window x1.2 times wider
            options.Columns = 2;    % [optional] define number of columns
            options.Focus = 1;      % [optional] define index of the widget to get focus
            options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/trainingoptions.html'; % [optional], an url for the Help button
            %options.LastItemColumns = 1; % [optional] force the last entry to be on a single column

            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            obj.TrainingOpt.solverName = answer{1};
            obj.TrainingOpt.MaxEpochs = str2double(answer{2});
            obj.TrainingOpt.Shuffle = answer{3};
            obj.TrainingOpt.InitialLearnRate = str2double(answer{4});
            obj.TrainingOpt.LearnRateSchedule = answer{5};
            obj.TrainingOpt.LearnRateDropPeriod = str2double(answer{6});
            obj.TrainingOpt.LearnRateDropFactor = str2double(answer{7});
            obj.TrainingOpt.L2Regularization = str2double(answer{8});
            obj.TrainingOpt.Momentum = str2double(answer{9});
            obj.TrainingOpt.GradientDecayFactor = str2double(answer{10});
            obj.TrainingOpt.SquaredGradientDecayFactor = str2double(answer{11});
            obj.TrainingOpt.ValidationFrequency = str2double(answer{12});
            obj.TrainingOpt.ValidationPatience = str2double(answer{13});
            obj.TrainingOpt.Plots = answer{14};
            obj.TrainingOpt.OutputNetwork = answer{15};
            obj.TrainingOpt.CheckpointFrequency = str2double(answer{16});
        end

        function start(obj, event)
            % function start(obj, event)
            % start calcualtions, depending on the selected tab
            % preprocessing, training, or prediction is initialized

            global mibPath
            global mibDeepStopTraining     % variable to define stop of training (when true)

            if strcmp(obj.BatchOpt.Workflow{1}, '2D Instance')
                uialert(obj.View.gui, ...
                    'Coming soon...', 'In progress', 'Icon','info');
                return;
            end


            switch event.Source.Tag
                case 'PreprocessButton'
                    obj.startPreprocessing();
                case 'TrainButton'
                    switch obj.View.handles.TrainButton.Text
                        case 'Stop training'
                            % stop training by pressing the Stop Train button
                            % in the main DeepMIB window

                            mibDeepStopTraining = true;
                            obj.View.handles.TrainButton.Text = 'Stopping...';
                            obj.View.handles.TrainButton.BackgroundColor = [1 .5 0];
                            return;
                        case 'Stopping...'
                            obj.View.handles.TrainButton.Text = 'Train';
                            obj.View.handles.TrainButton.BackgroundColor = [0.7686    0.9020    0.9882];
                            return;
                    end

                    if strcmp(obj.View.Figure.GPUDropDown.Value, 'Multi-GPU')
                        if obj.BatchOpt.O_CustomTrainingProgressWindow
                            prompts = {'Follow the training progress using:'};
                            defAns = {{'Console printout', 'MATLAB progress window (requires MATLAB)', 1}};
                            dlgTitle = 'Progress window';
                            options.WindowStyle = 'normal';
                            options.Title = sprintf(['!!! Warning !!!\n\n' ...
                                'Multi-GPU training is not compatible with the custom MIB progress window!\n' ...
                                'Would you like to use any of these options?']);
                            options.TitleLines = 5;
                            options.WindowWidth = 1.2;
                            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                            if isempty(answer); return; end

                            % turn off custom progress plot
                            obj.View.handles.O_CustomTrainingProgressWindow.Value = 0;
                            customEvent.Source = obj.View.handles.O_CustomTrainingProgressWindow;
                            customEvent.Value = 0;
                            obj.customTrainingProgressWindow_Callback(customEvent);

                            switch answer{1}
                                case 'Console printout'
                                    obj.TrainingOpt.Plots = 'none';
                                case 'MATLAB progress window (requires MATLAB)'
                                    obj.TrainingOpt.Plots = 'training-progress';
                            end
                        end
                    end
                    if strcmp(obj.BatchOpt.Workflow{1}, '2D Instance')
                        obj.startTrainingInstances(); % do instance segmentation
                    else
                        obj.startTraining(); % do semantic segmentation
                    end
                case 'PredictButton'
                    if strcmp(obj.BatchOpt.P_PredictionMode{1}, 'Blocked-image')
                        if obj.mibController.matlabVersion < 9.10 % new syntax from R2021a
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nThe blocked image mode requires Matlab R2021a or newer!'), 'Not compatible');
                            return;
                        end
                        try
                            obj.startPredictionBlockedImage(); % new version for R2021a and MIB 2.83
                        catch err
                            %obj.showErrorDialog(err, 'BlockedImage prediction error');
                            mibShowErrorDialog(obj.View.gui, err, 'BlockedImage prediction error');
                            return;
                        end
                    else
                        if ismember(obj.BatchOpt.Workflow{1}, {'2D Patch-wise', '2.5D Semantic'})
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\n%s workflow can only be processed using the Blocked-image prediction mode\n\nSwitch the Prediction engine:\n    "Legacy" -> "Blocked-image"', obj.BatchOpt.Workflow{1}), ...
                                'Wrong prediction mode');
                            return;
                        end
                        if strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D')
                            obj.startPrediction2D();
                        else
                            obj.startPrediction3D();
                        end
                    end
            end

            % redraw the image if needed
            % notify(obj.mibModel, 'plotImage');

            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            %obj.returnBatchOpt();
        end

        function imgOut = channelWisePreProcess(obj, imgIn)
            % function imgOut = channelWisePreProcess(obj, imgIn)
            % Normalize images
            % As input has 4 channels (modalities), remove the mean and divide by the
            % standard deviation of each modality independently.
            %
            % Parameters:
            % imgIn: input image, as matrix [heigth, width, color, depth]
            %
            % Return values:
            % imgOut: resulting image, stretched between 0 and 1

            imgIn = single(imgIn);

            %             % zscore normalization
            %             chn_Mean = mean(imgIn, [1 2 4]);
            %             chn_Std = std(imgIn,0, [1 2 4]);
            %             imgOut = (imgIn - chn_Mean)./chn_Std;
            %
            %             rangeMin = -5;
            %             rangeMax = 5;
            %
            %             imgOut(imgOut > rangeMax) = rangeMax;     % remove outliers
            %             imgOut(imgOut < rangeMin) = rangeMin;
            %
            %             % Rescale the data to the range [0, 1].
            %             imgOut = (imgOut - rangeMin) / (rangeMax - rangeMin);

            % rescale-zeroone normalization
            chn_Min = min(imgIn, [], [1 2 4]);
            chn_Max = max(imgIn, [], [1 2 4]);
            imgOut = (imgIn - chn_Min) / (chn_Max - chn_Min);
        end

        function processImages(obj, preprocessFor)
            % function processImages(obj, preprocessFor)
            % Preprocess images for training and prediction
            %
            % Parameters:
            % preprocessFor: a string with target, 'training', 'prediction'

            if nargin < 2; uialert(obj.View.gui, 'processImages: the second parameter is required!', 'Preprocessing error'); return; end

            % init preprocessing images for the instance segmentation
            if strcmp(obj.BatchOpt.Workflow{1}, '2D Instance')
                obj.processImagesForInstanceSegmentation(preprocessFor);
                selection = uiconfirm(obj.View.gui, ...
                    sprintf('The labels were preprocessed!\n\nNow the preprocessed images needs to be split for training and validation.\nDo you want to do that now?'), ...
                    'Preprocessing labels',...
                    'Options', {'Split labels', 'Change preprocess to split but do not split', 'Do nothing'},...
                    'DefaultOption', 1, 'CancelOption', 3,...
                    'Icon', 'info');
                switch selection
                    case 'Do nothing'
                        obj.View.handles.PreprocessingMode.Value = 'Preprocessing is not required';
                        obj.BatchOpt.PreprocessingMode{1} = 'Preprocessing is not required';
                    case 'Change preprocess to split but do not split'
                        obj.View.handles.PreprocessingMode.Value = 'Split files for training/validation';
                        obj.BatchOpt.PreprocessingMode{1} = 'Split files for training/validation';
                    case 'Split labels'
                        obj.View.handles.PreprocessingMode.Value = 'Split files for training/validation';
                        obj.BatchOpt.PreprocessingMode{1} = 'Split files for training/validation';
                        obj.startPreprocessing();
                end
                %obj.View.handles.PreprocessingMode.Value = 'Preprocessing is not required';
                %obj.BatchOpt.PreprocessingMode{1} = 'Preprocessing is not required';
                return;
            end

            if strcmp(preprocessFor, 'training')
                imageDirIn = obj.BatchOpt.OriginalTrainingImagesDir;
                imageFilenameExtension = obj.BatchOpt.ImageFilenameExtensionTraining{1};
                trainingSwitch = 1;     % a switch indicating processing of images for training
                mibBioformatsCheck = obj.BatchOpt.BioformatsTraining;   % to use or not BioFormats reader
                BioFormatsIndices = obj.BatchOpt.BioformatsTrainingIndex{1};  % serie index for bio-formats
            elseif strcmp(preprocessFor, 'prediction')
                imageDirIn = obj.BatchOpt.OriginalPredictionImagesDir;
                imageFilenameExtension = obj.BatchOpt.ImageFilenameExtension{1};
                trainingSwitch = 0;
                mibBioformatsCheck = obj.BatchOpt.Bioformats;
                BioFormatsIndices = obj.BatchOpt.BioformatsIndex{1};  % serie index for bio-formats
            else
                uialert(obj.View.gui, 'processImages: the second parameter is wrong!', 'Preprocessing error'); return;
            end

            %% Load data
            if ~isfolder(fullfile(imageDirIn, 'Images'))
                uialert(obj.View.gui, sprintf('!!! Warning !!!\n\nThe images and models should be arranged in "Images" and "Labels" directories under\n\n%s\n\nCopy files there and try again!', imageDirIn), ...
                    'Old project or missing files', 'Icon', 'warning');
                return;
            end

            if obj.BatchOpt.showWaitbar
                pwb = PoolWaitbar(1, sprintf('Creating image datastore\nPlease wait...'), [], ...
                    sprintf('%s %s: processing for %s', obj.BatchOpt.Workflow{1}, obj.BatchOpt.Architecture{1}, preprocessFor), ...
                    obj.View.gui);
            else
                pwb = [];
            end
            warning('off', 'MATLAB:MKDIR:DirectoryExists');

            % make datastore for images
            try
                switch lower(['.' imageFilenameExtension])
                    case '.am'
                        getDataOptions.getMeta = false;     % do not process meta data in amiramesh files
                        getDataOptions.verbose = false;     % do not display info about loaded image
                        imgDS = imageDatastore(fullfile(imageDirIn, 'Images'), ...
                            'FileExtensions', lower(['.' imageFilenameExtension]),...
                            'IncludeSubfolders', false, ...
                            'ReadFcn', @(fn)amiraMesh2bitmap(fn, getDataOptions));

                    otherwise
                        getDataOptions.mibBioformatsCheck = mibBioformatsCheck;
                        getDataOptions.verbose = false;
                        getDataOptions.BioFormatsIndices = BioFormatsIndices;
                        imgDS = imageDatastore(fullfile(imageDirIn, 'Images'), ...
                            'FileExtensions', lower(['.' imageFilenameExtension]), ...
                            'IncludeSubfolders', false, ...
                            'ReadFcn', @(fn)mibLoadImages(fn, getDataOptions));
                end
            catch err
                %obj.showErrorDialog(err, 'Missing files');
                mibShowErrorDialog(obj.View.gui, err, 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(pwb); end
                return;
            end

            % preparing the directories
            % delete exising directories and files
            try
                if trainingSwitch
                    if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'))
                        rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'), 's');
                    end
                    if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'))
                        rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'), 's');
                    end
                    if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'))
                        rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'), 's');
                    end
                    if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels'))
                        rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels'), 's');
                    end
                else
                    if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels'))
                        rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels'), 's');
                    end
                    if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'))
                        rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), 's');
                    end
                end
            catch err
                %obj.showErrorDialog(err, 'Problems');
                mibShowErrorDialog(obj.View.gui, err, 'Problems with removing directories');
                if obj.BatchOpt.showWaitbar; delete(pwb); end
                return;
            end

            % make new directories
            if trainingSwitch
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'));
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'));
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'));
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels'));
            else
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'));
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels'));
            end

            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText(sprintf('Acquiring class names\nPlease wait...'));
            end

            GroundTruthModelSwitch = 0;     % models exists
            classNames = {'Exterior'};

            if strcmp(obj.BatchOpt.ModelFilenameExtension{1}, 'MODEL')
                % read number of materials for the first file
                files = dir(fullfile(imageDirIn, 'Labels', '*.model'));
                if isempty(files) && trainingSwitch
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nModel files are missing in\n%s', fullfile(imageDirIn, 'Labels')), ...
                        'Missing model files!');
                    if obj.BatchOpt.showWaitbar; delete(pwb); end
                    return;
                elseif ~isempty(files)
                    modelFn = fullfile(files(1).folder, files(1).name);
                    res = load(modelFn, '-mat', 'modelMaterialNames');
                    classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                    GroundTruthModelSwitch = 1;     % models exists
                end
            else
                classNames = arrayfun(@(x) sprintf('Class%.2d', x), 1:obj.BatchOpt.T_NumberOfClasses{1}-1, 'UniformOutput', false);
                classNames = [{'Exterior'}; classNames'];
                files = dir(fullfile(imageDirIn, 'Labels', lower(['*.' obj.BatchOpt.ModelFilenameExtension{1}]))); % extensions on Linux are case sensitive

                if ~isempty(files)
                    GroundTruthModelSwitch = 1;     % models exists
                end
            end

            % update number of classes variables
            if trainingSwitch
                obj.BatchOpt.T_NumberOfClasses{1} = numel(classNames);
                obj.View.handles.T_NumberOfClasses.Value = obj.BatchOpt.T_NumberOfClasses{1};
                obj.View.handles.NumberOfClassesPreprocessing.Value = obj.BatchOpt.T_NumberOfClasses{1};
            end

            %% Process images and split them to training and validation dirs
            NumFiles = length(imgDS.Files);

            if trainingSwitch
                % init random generator
                if obj.BatchOpt.RandomGeneratorSeed{1} == 0
                    rng('shuffle');
                else
                    rng(obj.BatchOpt.RandomGeneratorSeed{1}, 'twister');
                end
                randIndices = randperm(NumFiles);   % Random permutation of integers
                validationIndices = randIndices(1:ceil(obj.BatchOpt.ValidationFraction{1}*NumFiles));   % get indices of images to be used for validation
                if numel(validationIndices) == NumFiles
                    uialert(obj.View.gui, sprintf('!!! Warning !!!\n\nWith the current settings all images are assigned to the validation set!\nPlease decrease the value in the "Fraction of images for validation" edit box and try again!'), ...
                        'Validation set is too large', 'Icon', 'warning');
                    if obj.BatchOpt.showWaitbar; delete(pwb); end
                    return;
                end
            else
                validationIndices = zeros([NumFiles, 1]);   % do not create validation data
            end

            % define usage of parallel computing
            if obj.BatchOpt.UseParallelComputing
                parforArg = obj.View.handles.PreprocessingParForWorkers.Value;    % Maximum number of workers running in parallel
                if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
            else
                parforArg = 0;      % Maximum number of workers running in parallel, when 0 a single core used without parallel
            end

            % create local variables for parfor
            mode2D3DParFor = obj.BatchOpt.Workflow{1}(1:2);
            MaskAwayParFor = obj.BatchOpt.MaskAway;
            ResultingImagesDirParFor = obj.BatchOpt.ResultingImagesDir;
            showWaitbarParFor = obj.BatchOpt.showWaitbar;
            compressImages = obj.BatchOpt.CompressProcessedImages;
            compressModels = obj.BatchOpt.CompressProcessedModels;
            maskVariable = 'maskImg';   % variable that has mask inside *.mask files
            SingleModelTrainingFileParFor = obj.BatchOpt.SingleModelTrainingFile;

            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText(sprintf('Processing images\nPlease wait...'));
                pwb.setIncrement(10);  % set increment step to 10
            end

            maskDS = [];
            modDS = [];
            saveModelOpt = struct();

            if GroundTruthModelSwitch
                if strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D')  % preprocess files for 2D networks
                    if SingleModelTrainingFileParFor
                        fileList = dir(fullfile(imageDirIn, 'Labels', '*.model'));
                        fullModelPathFilenames = arrayfun(@(filename) fullfile(imageDirIn, 'Labels', cell2mat(filename)), {fileList.name}, 'UniformOutput', false);  % generate full paths
                        modDS = matfile(fullModelPathFilenames{1});     % models

                        if MaskAwayParFor && trainingSwitch     % do not use masks for prediction
                            fileList = dir(fullfile(imageDirIn, 'Masks', '*.mask'));
                            if ~isempty(fileList)
                                fullMaskPathFilenames = arrayfun(@(filename) fullfile(imageDirIn, 'Masks', cell2mat(filename)), {fileList.name}, 'UniformOutput', false);  % generate full paths
                                maskDS = matfile(fullMaskPathFilenames{1});
                            else
                                uialert(obj.View.gui, ...
                                    sprintf('!!! Error !!!\n\nThe mask files were not found!\nPlace *.mask files under\n\n%s', fullfile(imageDirIn, 'Masks')), ...
                                    'Mask is missing');
                                if obj.BatchOpt.showWaitbar; delete(pwb); end
                                return;
                            end
                        end
                    else
                        switch obj.BatchOpt.ModelFilenameExtension{1}
                            case 'MODEL'
                                modDS = imageDatastore(fullfile(imageDirIn, 'Labels'), ...
                                    'IncludeSubfolders', false, ...
                                    'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
                                % I = readimage(modDS,1);  % read model test
                                % reset(modDS);
                            otherwise
                                modDS = imageDatastore(fullfile(imageDirIn, 'Labels'), ...
                                    'IncludeSubfolders', false, ...
                                    'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                        end
                        if numel(modDS.Files) ~= numel(imgDS.Files)
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nIn this mode number of model files should match number of image files!'), 'Error');
                            if obj.BatchOpt.showWaitbar; delete(pwb); end
                            return;
                        end

                        if MaskAwayParFor && trainingSwitch     % do not use masks for prediction
                            try
                                switch obj.BatchOpt.MaskFilenameExtension{1}
                                    case 'MASK'
                                        maskDS = imageDatastore(fullfile(imageDirIn, 'Masks'), ...
                                            'IncludeSubfolders', false, ...
                                            'FileExtensions', '.mask', 'ReadFcn', @mibDeepStoreLoadImages);
                                    otherwise
                                        maskDS = imageDatastore(fullfile(imageDirIn, 'Masks'), ...
                                            'IncludeSubfolders', false, 'FileExtensions', lower(['.' obj.BatchOpt.MaskFilenameExtension{1}]));
                                end
                            catch err
                                %obj.showErrorDialog(err, 'Missing masks');
                                mibShowErrorDialog(obj.View.gui, err, 'Missing masks');
                                if obj.BatchOpt.showWaitbar; delete(pwb); end
                                return;
                            end

                            if numel(maskDS.Files) ~= numel(imgDS.Files)
                                uialert(obj.View.gui, ...
                                    sprintf('!!! Error !!!\n\nIn this mode number of mask files should match number of image files!'), 'Error');
                                if obj.BatchOpt.showWaitbar; delete(pwb); end
                                return;
                            end
                        end
                    end
                else    % preprocess files for 3D networks
                    % these variable needed for parfor loop
                    try
                        modDS = imageDatastore(fullfile(imageDirIn, 'Labels'), ...
                            'IncludeSubfolders', false, ...
                            'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
                        if MaskAwayParFor && trainingSwitch     % do not use masks for prediction
                            maskDS = imageDatastore(fullfile(imageDirIn, 'Masks'), ...
                                'IncludeSubfolders', false, ...
                                'FileExtensions', '.mask', 'ReadFcn', @mibDeepStoreLoadImages);
                        end
                    catch err
                        %obj.showErrorDialog(err, 'Missing files');
                        mibShowErrorDialog(obj.View.gui, err, 'Missing files');
                        if obj.BatchOpt.showWaitbar; delete(pwb); end
                        return;
                    end
                    %outModelFull = zeros([1 1 numel(imgDS.Files)]);
                    %maskDS = zeros([1 1 numel(imgDS.Files)]);
                end    % read corresponding model
            end

            % define saveModelOpt structure for saving files
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

            if strcmp(mode2D3DParFor, '2D')
                saveImageOpt.dimOrder = 'yxczt';
                saveModelOpt.dimOrder = 'yxczt';
            else
                saveImageOpt.dimOrder = 'yxzct';
                saveModelOpt.dimOrder = 'yxzct';
            end
            saveModelOpt.modelType = 63;
            saveModelOpt.modelMaterialNames = classNames;
            saveModelOpt.modelMaterialColors = classColors;

            if SingleModelTrainingFileParFor && ~isempty(modDS)
                if numel(modDS.Files) < NumFiles
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nNumber of slices in the model file is smaller than number of images\n\nYou may want to uncheck the "Single MIB model file" checkbox!'), ...
                        'Wrong model file');
                    if showWaitbarParFor; delete(pwb); end
                    return;
                end
            end

            convertToRGB = 0;
            %             if strcmp(obj.BatchOpt.Architecture{1}, 'DeepLab v3+')
            %                 mibImg = readimage(imgDS, 1);   % read image as [height, width, color, depth]
            %                 if size(mibImg,3) == 1 % grayscale image needs to be converted to RGB
            %                     convertToRGB = 1;
            %                 end
            %                 reset(imgDS);
            %             end

            if showWaitbarParFor
                pwb.setCurrentIteration(0);
                pwb.updateMaxNumberOfIterations(NumFiles);
            end

            parfor (imgId=1:NumFiles, parforArg)
                %for imgId=1:NumFiles
                % Define output directories
                % Split data into training, validation and test sets based
                % on obj.BatchOpt.ValidationFraction{1} value
                if trainingSwitch
                    if isempty(find(validationIndices == imgId, 1))    %(imgId <= floor((1-obj.BatchOpt.ValidationFraction{1})*NumFiles))
                        imDir = fullfile(ResultingImagesDirParFor, 'TrainImages');
                        labelDir = fullfile(ResultingImagesDirParFor, 'TrainLabels');
                    else
                        imDir = fullfile(ResultingImagesDirParFor, 'ValidationImages');
                        labelDir = fullfile(ResultingImagesDirParFor, 'ValidationLabels');
                    end
                else
                    imDir = fullfile(ResultingImagesDirParFor, 'PredictionImages');
                    labelDir = fullfile(ResultingImagesDirParFor, 'PredictionImages', 'GroundTruthLabels');
                end

                mibImg = readimage(imgDS, imgId);   % read image as [height, width, color, depth]
                if convertToRGB % grayscale image needs to be converted to RGB
                    mibImg = repmat(mibImg, [1, 1, 3, 1]);
                end

                [~, fnOut] = fileparts(imgDS.Files{imgId});    % get filename of the image
                %                 if obj.BatchOpt.NormalizeImages
                %                     fprintf('!!! Warning !!! Normalizing images!\n')
                %                     outImg = obj.channelWisePreProcess(outImg);     % normalize the signals, remove outliers and scale between 0 and 1
                %                 end

                if ndims(mibImg) == 4
                    mibImg = permute(mibImg, [1 2 4 3]);    % permute from [height, width, color, depth] -> [height, width, depth, color]
                end

                % saving image
                fn = fullfile(imDir, sprintf('%s.mibImg', fnOut));
                saveImageParFor(fn, mibImg, compressImages, saveImageOpt);

                if GroundTruthModelSwitch
                    if strcmp(mode2D3DParFor, '2D')
                        if SingleModelTrainingFileParFor
                            mibImg = modDS.(modDS.modelVariable)(:,:,imgId);    % get 2D slice from the model
                            [~, fnModOut] = fileparts(imgDS.Files{imgId});    % get filename for the model
                            fnModOut = sprintf('Labels_%s', fnModOut);  % generate name for the output model file

                            if MaskAwayParFor && trainingSwitch
                                maskImg = maskDS.(maskVariable)(:,:,imgId);
                                mibImg = single(mibImg);
                                mibImg(maskImg==1) = NaN;
                            end
                            mibImg = categorical(mibImg, 0:numel(classNames)-1, classNames);    % convert to categorial
                        else
                            mibImg = readimage(modDS, imgId);      % read corresponding model
                            if MaskAwayParFor && trainingSwitch
                                outMask = readimage(maskDS, imgId);
                                mibImg = single(mibImg);
                                mibImg(outMask==1) = NaN;
                            end
                            mibImg = categorical(mibImg, 0:numel(classNames)-1, classNames);    % convert to categorical
                            [~, fnModOut] = fileparts(modDS.Files{imgId});    % get filename for the model
                        end
                    else   % 3D case
                        mibImg = readimage(modDS, imgId);      % read corresponding model
                        if MaskAwayParFor && trainingSwitch
                            outMask = readimage(maskDS, imgId);
                            mibImg = single(mibImg);
                            mibImg(outMask==1) = NaN;
                        end
                        mibImg = categorical(mibImg, 0:numel(classNames)-1, classNames);    % convert to categorical
                        [~, fnModOut] = fileparts(modDS.Files{imgId});    % get filename for the model
                    end

                    fn = fullfile(labelDir, sprintf('%s.mibCat', fnModOut));
                    saveImageParFor(fn, mibImg, compressModels, saveModelOpt);
                end
                %if pwb.getCancelState(); delete(pwb); imgId = numFiles; end
                if showWaitbarParFor && mod(imgId, 10) == 1; increment(pwb); end
            end
            if obj.BatchOpt.showWaitbar; delete(pwb); end
        end

        function startPreprocessing(obj)
            % function startPreprocessing(obj)

            if strcmp(obj.BatchOpt.Workflow{1},  '2D Patch-wise')  % '2D Patch-wise Resnet18' or '2D Patch-wise Resnet50'
                if ismember(obj.BatchOpt.PreprocessingMode{1}, {'Training and Prediction', 'Training', 'Prediction'})
                    uialert(obj.View.gui, ...
                        sprintf('Preprocessing of images is not required for patch-wise workflows'), ...
                        'Not implemented');
                    return;
                end
            end

            switch obj.BatchOpt.PreprocessingMode{1}
                case 'Training and Prediction'
                    t1 = tic;   % init the timer
                    obj.processImages('training');     % process images for training
                    res1 = toc(t1);
                    t2 = tic;   % init the timer
                    obj.processImages('prediction');     % process images for training
                    res2 = toc(t2);
                    fprintf('Training images preprocessing time: %f seconds\n', res1);
                    fprintf('Prediction images preprocessing time: %f seconds\n', res2);
                case 'Training'
                    t1 = tic;   % init the timer
                    obj.processImages('training');     % process images for training
                    res1 = toc(t1);
                    fprintf('Training images preprocessing time: %f seconds\n', res1);
                case 'Prediction'
                    t2 = tic;   % init the timer
                    obj.processImages('prediction');     % process images for training
                    res2 = toc(t2);
                    fprintf('Prediction images preprocessing time: %f seconds\n', res2);
                case 'Split files for training/validation'
                    if strcmp(obj.BatchOpt.Workflow{1}, '2D Instance')
                        sourceLabelDir = 'LabelsInstances';
                        labelsFilenameExt = '*.mat';
                        labelsSourceDir = 'LabelsInstances';
                        splitForInstanceSegmentation = true;
                    else
                        sourceLabelDir = 'Labels';
                        labelsFilenameExt = lower(['*.' obj.BatchOpt.ModelFilenameExtension{1}]);
                        labelsSourceDir = 'Labels';
                        splitForInstanceSegmentation = false;
                    end
                    msg = sprintf('!!! Attention !!!\nThe following operation will split files in\n"%s"\n\n- Images\n- %s\n\nto\n- TrainImages, TrainLabels\n- ValidationImages, ValidationLabels', obj.BatchOpt.OriginalTrainingImagesDir, sourceLabelDir);

                    selection = uiconfirm(obj.View.gui, ...
                        msg, 'Split files',...
                        'Options',{'Split and copy', 'Split and move', 'Cancel'},...
                        'DefaultOption', 3, 'CancelOption', 3,...
                        'Icon', 'warning');
                    if strcmp(selection, 'Cancel'); return; end

                    if obj.BatchOpt.RandomGeneratorSeed{1} == 0
                        rng('shuffle');
                    else
                        rng(obj.BatchOpt.RandomGeneratorSeed{1}, 'twister');
                    end

                    if strcmp(obj.BatchOpt.Workflow{1},  '2D Patch-wise')  % '2D Patch-wise Resnet18' or '2D Patch-wise Resnet50'
                        imds = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Images'),...
                            'LabelSource', 'foldernames', 'IncludeSubfolders', true, ...
                            'FileExtensions', lower(['.' obj.BatchOpt.ImageFilenameExtensionTraining{1}]));
                        [imds_val, imds_train] = splitEachLabel(imds, obj.BatchOpt.ValidationFraction{1}, 'randomized');

                        % define output directories
                        outputTrainImagesDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages');
                        outputValidationImagesDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages');

                        try
                            if isfolder(outputTrainImagesDir)
                                msg = sprintf('!!! Warning !!!\nThe following subfolders\n- TrainImages\n- ValidationImages\nunder\n"%s"\n\nwill be removed!\nAre you sure?', obj.BatchOpt.OriginalTrainingImagesDir);
                                selection2 = uiconfirm(obj.View.gui, ...
                                    msg, 'Split files',...
                                    'Options',{'Delete folders', 'Cancel'},...
                                    'DefaultOption', 2, 'CancelOption', 2,...
                                    'Icon', 'warning');
                                if strcmp(selection2, 'Cancel'); return; end

                                rmdir(outputTrainImagesDir, 's');
                            end
                            if isfolder(outputValidationImagesDir)
                                rmdir(outputValidationImagesDir, 's');
                            end

                            mkdir(outputTrainImagesDir);
                            mkdir(outputValidationImagesDir);

                            classNames = unique(imds.Labels);
                            for classId = 1:numel(classNames)
                                mkdir(fullfile(outputTrainImagesDir, char(classNames(classId))));
                                mkdir(fullfile(outputValidationImagesDir, char(classNames(classId))));
                            end
                        catch err
                            %obj.showErrorDialog(err, 'Split images problem');
                            mibShowErrorDialog(obj.View.gui, err, 'Split images problem');
                            if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                            return;
                        end

                        wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Splitting and copying files\nPlease wait...'), ...
                            'Title', 'Split files', 'Cancelable','on');

                        noFiles = numel(imds_train.Files) + numel(imds_val.Files);
                        for fileId = 1:numel(imds_train.Files)
                            [path1, fn1, ext1] = fileparts(imds_train.Files{fileId});
                            [~, classFolderName] = fileparts(path1);
                            copyfile(imds_train.Files{fileId}, fullfile(outputTrainImagesDir, classFolderName, [fn1, ext1]));
                            if mod(fileId, 10) == 1; wb.Value = fileId/noFiles; end
                            if wb.CancelRequested; delete(wb); return; end
                        end
                        for fileId = 1:numel(imds_val.Files)
                            [path1, fn1, ext1] = fileparts(imds_val.Files{fileId});
                            [~, classFolderName] = fileparts(path1);
                            copyfile(imds_val.Files{fileId}, fullfile(outputValidationImagesDir, classFolderName, [fn1, ext1]));
                            if mod(fileId, 10) == 1; wb.Value = fileId/noFiles; end
                            if wb.CancelRequested; delete(wb); return; end
                        end
                        if strcmp(selection, 'Split and move')
                            % remove the empty dirs
                            rmdir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Images'), 's');
                        end
                    else            % split images for semantic segmentation
                        imageFiles = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Images', lower(['*.' obj.BatchOpt.ImageFilenameExtensionTraining{1}])));
                        labelsFiles = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, labelsSourceDir, labelsFilenameExt));

                        if numel(imageFiles) ~= numel(labelsFiles) || numel(imageFiles) == 0
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nThere are no files or number of files mismatch in\n\n%s\n\n- Images\n- Labels', obj.BatchOpt.OriginalTrainingImagesDir), ...
                                'Wrong files');
                            return;
                        end
                        noFiles = numel(imageFiles);
                        randIndices = randperm(noFiles);   % Random permutation of integers
                        validationIndices = randIndices(1:ceil(obj.BatchOpt.ValidationFraction{1}*noFiles));   % get indices of images to be used for validation

                        % define output directories
                        outputTrainImagesDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages');
                        outputTrainLabelsDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels');
                        outputValidationImagesDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages');
                        outputValidationLabelsDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels');

                        try
                            if isfolder(outputTrainImagesDir)
                                msg = sprintf('!!! Warning !!!\nThe following subfolders\n- TrainImages\n- TrainLabels\n- ValidationImages\n- ValidationLabels\n under\n"%s"\n\nwill be removed!\nAre you sure?', obj.BatchOpt.OriginalTrainingImagesDir);
                                selection2 = uiconfirm(obj.View.gui, ...
                                    msg, 'Split files',...
                                    'Options',{'Delete folders', 'Cancel'},...
                                    'DefaultOption', 2, 'CancelOption', 2,...
                                    'Icon', 'warning');
                                if strcmp(selection2, 'Cancel'); return; end

                                rmdir(outputTrainImagesDir, 's');
                            end
                            if isfolder(outputTrainLabelsDir)
                                rmdir(outputTrainLabelsDir, 's');
                            end
                            if isfolder(outputValidationImagesDir)
                                rmdir(outputValidationImagesDir, 's');
                            end
                            if isfolder(outputValidationLabelsDir)
                                rmdir(outputValidationLabelsDir, 's');
                            end

                            mkdir(outputTrainImagesDir);
                            mkdir(outputTrainLabelsDir);
                            if ~isempty(validationIndices)
                                mkdir(outputValidationImagesDir);
                                mkdir(outputValidationLabelsDir);
                            end
                        catch err
                            %obj.showErrorDialog(err, 'Split images problem');
                            mibShowErrorDialog(obj.View.gui, err, 'Split images problem');
                            if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                            return;
                        end

                        trainLogicalList = true([numel(imageFiles), 1]);   % indices of files for training
                        trainLogicalList(validationIndices) = false;   % indices of files for validation

                        if strcmp(selection, 'Split and copy')
                            wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Splitting and copying files\nPlease wait...'), ...
                                'Title', 'Split and copy files', 'Cancelable','on');

                            for fileId = 1:noFiles
                                if trainLogicalList(fileId)     % for training
                                    copyfile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputTrainImagesDir, imageFiles(fileId).name));
                                    copyfile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputTrainLabelsDir, labelsFiles(fileId).name));
                                else    % for validation
                                    copyfile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputValidationImagesDir, imageFiles(fileId).name));
                                    copyfile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputValidationLabelsDir, labelsFiles(fileId).name));
                                end
                                if wb.CancelRequested; delete(wb); return; end
                                if mod(fileId, 10) == 1; wb.Value = fileId/noFiles; end
                            end
                        elseif strcmp(selection, 'Split and move')
                            wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Splitting and copying files\nPlease wait...'), ...
                                'Title', 'Split and move files', 'Cancelable','on');
                            for fileId = 1:noFiles
                                if trainLogicalList(fileId)     % for training
                                    movefile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputTrainImagesDir, imageFiles(fileId).name));
                                    movefile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputTrainLabelsDir, labelsFiles(fileId).name));
                                else    % for validation
                                    movefile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputValidationImagesDir, imageFiles(fileId).name));
                                    movefile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputValidationLabelsDir, labelsFiles(fileId).name));
                                end
                                if wb.CancelRequested; delete(wb); return; end
                                if mod(fileId, 10) == 1;  wb.Value = fileId/noFiles; end
                            end
                            % remove the empty dirs
                            rmdir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Images'), 's');
                            rmdir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Labels'), 's');
                        end
                    end

                    obj.View.handles.PreprocessingMode.Value = 'Preprocessing is not required';
                    obj.BatchOpt.PreprocessingMode{1} = 'Preprocessing is not required';

                    delete(wb);
            end
            % Preprocessing for training, AM files 256x256x3x512
            % C:\MATLAB\Data\CNN_FileRead_Test /notebook
            %             R2019b
            %             DeepMIB ver1, no compression = [17.548520 17.203554 17.444283], average=17.3988 (100%)
            %             DeepMIB ver1, model compression = [17.202636 17.368104 16.817339], average=17.1294 (98%)
            %             DeepMIB ver1, image+model compression = [20.123545 20.309843 19.809388], average 20.0809 (115%)
            %             DeepMIB direct AM-read, model compression = [10.975879 10.601845 10.738362]; average=10.772 (62%)
            %             DeepMIB no-meta AM-read, model compression = [8.410581 8.541582 8.414153]; average = 8.4554 (49%)
            %             DeepMIB no-meta AM-read, model comp, waitbar x10 = [7.555503 7.618259 7.555017], average = 7.5763 (43%)
            %             DeepMIB with parfor [7.108081 8.261853 6.799513], average = 7.3898 (42%, 2workers, 17% 8workers)
            %
            %             R2020b
            %             DeepMIB ver1, no compression = [16.799966 16.688955 15.628009], average=16.3723 (100%) vs 2019b 94%
            %             DeepMIB ver1, model compression = [15.955620 15.851953 16.127321], average=15.9783 (98%)
            %             DeepMIB ver1, image+model compression = [19.077072 18.302455 18.434443], average 18.6047 (114%)
        end

        function TrainingOptions = preprareTrainingOptions(obj, valDS)
            % function TrainingOptions = preprareTrainingOptions(obj, valDS)
            % prepare trainig options for the network training
            %
            % Parameters:
            % valDS: datastore with images for validation

            global mibDeepTrainingProgressStruct

            TrainingOptions = struct();

            %% Specify Training Options
            % update ResetInputNormalization when obj.InputLayerOpt.Mean,
            % .StandardDeviation, .Min, .Max are defined
            ResetInputNormalization = true; %#ok<*NASGU>
            switch obj.InputLayerOpt.Normalization
                case 'zerocenter'
                    if ~isempty(obj.InputLayerOpt.Mean); ResetInputNormalization = false; end
                case 'zscore'
                    if ~isempty(obj.InputLayerOpt.Mean) && ~isempty(obj.InputLayerOpt.StandardDeviation); ResetInputNormalization = false; end
                case {'rescale-symmetric', 'rescale-zero-one'}
                    if ~isempty(obj.InputLayerOpt.Min) && ~isempty(obj.InputLayerOpt.Max); ResetInputNormalization = false; end
                case 'none'

            end

            verboseSwitch = false;
            if strcmp(obj.TrainingOpt.Plots, 'none')
                verboseSwitch = true;   % drop message into the command window when the plots are disabled
                mibDeepTrainingProgressStruct.useCustomProgressPlot = 0;
            else
                mibDeepTrainingProgressStruct.useCustomProgressPlot = obj.BatchOpt.O_CustomTrainingProgressWindow;
            end

            if isdeployed
                PlotsSwitch = 'none';
            else
                if mibDeepTrainingProgressStruct.useCustomProgressPlot
                    PlotsSwitch = 'none';
                else
                    PlotsSwitch = obj.TrainingOpt.Plots;
                end
            end

            CheckpointPath = '';
            if obj.BatchOpt.T_SaveProgress
                CheckpointPath = fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork');
            end

            try
                % select gpu or cpu for training
                % and define executionEnvironment
                selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
                switch obj.View.Figure.GPUDropDown.Value
                    case 'CPU only'
                        if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                            gpuDevice([]);  % CPU only mode
                        end
                        executionEnvironment = 'cpu';
                    case 'Multi-GPU'
                        executionEnvironment = 'multi-gpu';
                    case 'Parallel'
                        executionEnvironment = 'parallel';
                    otherwise
                        gpuDevice(selectedIndex);   % choose selected GPU device
                        executionEnvironment = 'gpu';
                end

                % recalculate validation frequency from epochs to
                % interations
                ValidationFrequencyInIterations = ceil(mibDeepTrainingProgressStruct.iterPerEpoch / obj.TrainingOpt.ValidationFrequency);

                evalTrainingOptions = join([
                    "TrainingOptions = trainingOptions(obj.TrainingOpt.solverName,"
                    "'MaxEpochs', obj.TrainingOpt.MaxEpochs,"
                    "'Shuffle', obj.TrainingOpt.Shuffle,"
                    "'InitialLearnRate', obj.TrainingOpt.InitialLearnRate,"
                    "'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule,"
                    "'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod,"
                    "'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor,"
                    "'L2Regularization', obj.TrainingOpt.L2Regularization,"
                    "'Plots', PlotsSwitch,"
                    "'Verbose', verboseSwitch,"
                    "'ResetInputNormalization', ResetInputNormalization,"
                    "'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1},"
                    "'CheckpointPath', CheckpointPath,"
                    "'ExecutionEnvironment', executionEnvironment,"
                    ], ' ');

                % Accuracy metric is only used in the classification tasks
                % for semantic segmentation tasks TrainAccuracy is empty
                if strcmp(obj.TrainEngine, 'trainnet')
                    evalTrainingOptions = join([evalTrainingOptions, ...
                        "'Metrics', 'accuracy',"
                        ], ' ');
                end

                % if strcmp(obj.TrainEngine, 'trainnet')
                %     evalTrainingOptions = join([evalTrainingOptions, ...
                %         "'Metrics', 'rmse',"
                %         ], ' ');
                % end

                if mibDeepTrainingProgressStruct.useCustomProgressPlot
                    % add output function and dispatch in background option
                    switch obj.View.Figure.GPUDropDown.Value
                        case {'Multi-GPU', 'Parallel'}
                            trainingProgressOptions = struct();
                            trainingProgressOptions.O_NumberOfPoints = obj.BatchOpt.O_NumberOfPoints{1};
                            trainingProgressOptions.NetworkFilename = obj.BatchOpt.NetworkFilename;
                            trainingProgressOptions.noColorChannels = str2num(obj.BatchOpt.T_InputPatchSize);
                            trainingProgressOptions.noColorChannels = trainingProgressOptions.noColorChannels(4);
                            trainingProgressOptions.Workflow = obj.BatchOpt.Workflow{1};
                            trainingProgressOptions.Architecture = obj.BatchOpt.Architecture{1};
                            trainingProgressOptions.refreshRateIter = obj.BatchOpt.O_RefreshRateIter{1};
                            trainingProgressOptions.matlabVersion = obj.mibController.matlabVersion;
                            trainingProgressOptions.gpuDevice = obj.View.Figure.GPUDropDown.Value;
                            trainingProgressOptions.iterPerEpoch = mibDeepTrainingProgressStruct.iterPerEpoch;
                            trainingProgressOptions.TrainingOpt = obj.TrainingOpt;
                            trainingProgressOptions.sendNextReportAtEpoch = -1;   % next epoch value to send training report
                            if obj.SendReports.T_SendReports && obj.SendReports.sendDuringRun
                                trainingProgressOptions.sendNextReportAtEpoch = obj.TrainingOpt.CheckpointFrequency+1; % the value is taken from the checkpoint frequency
                                trainingProgressOptions.sendReportToEmail = obj.SendReports.TO_email;
                            end

                            switch obj.TrainEngine
                                case 'trainNetwork'
                                    evalTrainingOptions = join([evalTrainingOptions
                                        "'OutputFcn', @(info)mibDeepCustomTrainingProgressDisplay(info, trainingProgressOptions),"
                                        ], ' ');
                                case 'trainnet'
                                    evalTrainingOptions = join([evalTrainingOptions
                                        "'OutputFcn', @(info)mibDeepCustomTrainingProgressDisplayTrainNet(info, trainingProgressOptions),"
                                        ], ' ');
                            end
                        otherwise
                            trainingProgressOptions = struct();
                            trainingProgressOptions.O_NumberOfPoints = obj.BatchOpt.O_NumberOfPoints{1};
                            trainingProgressOptions.NetworkFilename = obj.BatchOpt.NetworkFilename;
                            trainingProgressOptions.noColorChannels = str2num(obj.BatchOpt.T_InputPatchSize);
                            trainingProgressOptions.noColorChannels = trainingProgressOptions.noColorChannels(4);
                            trainingProgressOptions.Workflow = obj.BatchOpt.Workflow{1};
                            trainingProgressOptions.Architecture = obj.BatchOpt.Architecture{1};
                            trainingProgressOptions.refreshRateIter = obj.BatchOpt.O_RefreshRateIter{1};
                            trainingProgressOptions.matlabVersion = obj.mibController.matlabVersion;
                            trainingProgressOptions.gpuDevice = obj.View.Figure.GPUDropDown.Value;
                            trainingProgressOptions.iterPerEpoch = mibDeepTrainingProgressStruct.iterPerEpoch;
                            trainingProgressOptions.TrainingOpt = obj.TrainingOpt;
                            trainingProgressOptions.sendNextReportAtEpoch = -1;   % next epoch value to send training report
                            if obj.SendReports.T_SendReports && obj.SendReports.sendDuringRun
                                trainingProgressOptions.sendNextReportAtEpoch = obj.TrainingOpt.CheckpointFrequency+1; % the value is taken from the checkpoint frequency
                                trainingProgressOptions.sendReportToEmail = obj.SendReports.TO_email;
                            end

                            switch obj.TrainEngine
                                case 'trainNetwork'
                                    evalTrainingOptions = join([evalTrainingOptions
                                        "'OutputFcn', @(info)mibDeepCustomTrainingProgressDisplay(info, trainingProgressOptions),"
                                        ], ' ');
                                case 'trainnet'
                                    evalTrainingOptions = join([evalTrainingOptions
                                        "'OutputFcn', @(info)mibDeepCustomTrainingProgressDisplayTrainNet(info, trainingProgressOptions),"
                                        ], ' ');
                            end

                            % testing DispatchInBackground
                            % compatible only with matlab progress plot and
                            % with the console only
                            % par dispatch was about the same time as
                            % normal training

                            % evalTrainingOptions = join([evalTrainingOptions
                            %    "'DispatchInBackground', false,"
                            %    ], ' ');

                    end
                else
                    evalTrainingOptions = join([evalTrainingOptions
                        "'OutputFcn', @mibDeepStopTrainingWithoutPlots,"
                        ], ' ');
                end

                % define solver specific settings
                switch obj.TrainingOpt.solverName
                    case 'adam'
                        evalTrainingOptions = join([evalTrainingOptions
                            "'GradientDecayFactor', obj.TrainingOpt.GradientDecayFactor,"
                            "'SquaredGradientDecayFactor', obj.TrainingOpt.SquaredGradientDecayFactor,"
                            ], ' ');
                    case 'rmsprop'
                        evalTrainingOptions = join([evalTrainingOptions
                            "'SquaredGradientDecayFactor', obj.TrainingOpt.SquaredGradientDecayFactor,"
                            ], ' ');
                    case 'sgdm'
                        evalTrainingOptions = join([evalTrainingOptions
                            "'Momentum', obj.TrainingOpt.Momentum,"
                            ], ' ');
                end

                % add validation store
                if ~isempty(valDS)
                    evalTrainingOptions = join([evalTrainingOptions
                        "'ValidationData', valDS,"
                        "'ValidationFrequency', ValidationFrequencyInIterations,"
                        "'ValidationPatience', obj.TrainingOpt.ValidationPatience," ...
                        ], ' ');
                end

                % add output network selection method
                if obj.mibController.matlabVersion >= 9.11 % R2021b
                    if strcmp(obj.TrainingOpt.OutputNetwork, 'best-validation-loss') && isempty(valDS)
                        selection = uiconfirm(obj.View.gui, ...
                            sprintf('The current training options have OutputNetwork parameter set to "best-validation-loss" to return the network corresponding to the training iteration with the lowest validation loss.\n\nPlease hit Cancel and provide images for validation (Directories and preprocessing->Fraction of images for validation) and start training again.\n\nAlternatively press "Continue using last-iteration output" to return the network corresponding to the last training iteration.'), ...
                            'Missing validation images',...
                            'Options',{'Continue using last-iteration output', 'Cancel'}, ...
                            'DefaultOption', 'Cancel', ...
                            'Icon','warning');
                        if strcmp(selection, 'Cancel'); delete(obj.wb); return; end
                        obj.TrainingOpt.OutputNetwork = 'last-iteration';
                    end

                    evalTrainingOptions = join([evalTrainingOptions
                        "'OutputNetwork', obj.TrainingOpt.OutputNetwork,"
                        ], ' ');
                end

                % add frequency of checkpoint generations
                if obj.mibController.matlabVersion >= 9.12 % R2022a
                    if obj.BatchOpt.T_SaveProgress
                        evalTrainingOptions = join([evalTrainingOptions
                            "'CheckpointFrequency', obj.TrainingOpt.CheckpointFrequency,"
                            ], ' ');
                    end
                end
                evalTrainingOptions = char(evalTrainingOptions);
                evalTrainingOptions = [evalTrainingOptions(1:end-1), ');'];
                % generate TrainingOptions structure
                eval(evalTrainingOptions);
            catch err
                mibShowErrorDialog(obj.View.gui, err, 'Wrong training options');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); return; end
            end
        end

        function updatePreprocessingMode(obj)
            % function updatePreprocessingMode(obj)
            % callback for change of selection in the Preprocess for dropdown

            obj.BatchOpt.PreprocessingMode{1} = obj.View.handles.PreprocessingMode.Value;
            % if strcmp(obj.View.handles.PreprocessingMode.Value, 'Preprocessing is not required') || strcmp(obj.View.handles.PreprocessingMode.Value, 'Split files for training/validation')
            %     obj.BatchOpt.MaskAway = false;
            %     obj.BatchOpt.SingleModelTrainingFile = false;
            % else
            %
            % end
            obj.updateWidgets();
        end


        function saveConfig(obj, configName)
            % function saveConfig(obj, filename)
            % save Deep MIB configuration to a file
            %
            % Parameters:
            % configName: [optional] string, full filename to the config file

            if nargin < 2
                [projectPath, file] = fileparts(obj.BatchOpt.NetworkFilename);
                [file, projectPath]  = uiputfile({'*.mibCfg', 'mibDeep config files (*.mibCfg)';
                    '*.mat', 'Mat files (*.mat)'}, 'Select config file', ...
                    fullfile(projectPath, file));
                if file == 0; return; end

                configName = fullfile(projectPath, file);
            else
                projectPath = fileparts(configName);
            end
            % if ~strcmp(path(end), filesep)   % remove the ending slash
            %     path = [path filesep];
            % end

            if strcmp(projectPath(end), filesep)   % remove the ending slash
                projectPath = projectPath(1:end-1);
            end

            BatchOpt = obj.BatchOpt; %#ok<*PROPLC>
            % generate TrainingOptStruct, because TrainingOptions is
            % 'TrainingOptionsADAM' class
            AugOpt2DStruct = obj.AugOpt2D;
            AugOpt3DStruct = obj.AugOpt3D;
            InputLayerOpt = obj.InputLayerOpt;
            TrainingOptStruct = obj.TrainingOpt;
            ActivationLayerOpt = obj.ActivationLayerOpt;
            SegmentationLayerOpt = obj.SegmentationLayerOpt;
            DynamicMaskOpt = obj.DynamicMaskOpt;

            % try to export path as relatives
            BatchOpt.NetworkFilename = convertAbsoluteToRelativePath(BatchOpt.NetworkFilename, projectPath, '[RELATIVE]');
            BatchOpt.OriginalTrainingImagesDir = convertAbsoluteToRelativePath(BatchOpt.OriginalTrainingImagesDir, projectPath, '[RELATIVE]');
            BatchOpt.OriginalPredictionImagesDir = convertAbsoluteToRelativePath(BatchOpt.OriginalPredictionImagesDir, projectPath, '[RELATIVE]');
            BatchOpt.ResultingImagesDir = convertAbsoluteToRelativePath(BatchOpt.ResultingImagesDir, projectPath, '[RELATIVE]');

            % add MIB version to the saved config
            mibVersion.mibVersion = obj.mibController.mibVersion;
            mibVersion.mibVersionNumeric = obj.mibController.mibVersionNumeric;

            % generate config file; the config file is the same as *.mibDeep but without 'net' field
            save(configName, ...
                'TrainingOptStruct', 'AugOpt2DStruct', 'AugOpt3DStruct', ...
                'SegmentationLayerOpt', 'ActivationLayerOpt', 'DynamicMaskOpt',...
                'InputLayerOpt', 'BatchOpt', 'mibVersion', '-mat', '-v7.3');
        end

        function res = correctBatchOpt(obj, res)
            % function res = correctBatchOpt(obj, res)
            % correct loaded BatchOpt structure if it is not compatible
            % with the current version of DeepMIB
            %
            % Parameters:
            % res: BatchOpt structure loaded from a file

            % update res.BatchOpt to be compatible with DeepMIB v2.83
            if ~isfield(res.BatchOpt, 'Workflow')
                %obj.BatchOpt.Architecture = {};
                switch res.BatchOpt.Architecture{1}
                    case {'2D U-net', '2D SegNet', '2D DLv3 Resnet18', '2D DeepLabV3 Resnet18', '2D DeepLabV3 Resnet50'}
                        res.BatchOpt.Workflow = {'2D Semantic'};
                        res.BatchOpt.Architecture{1} = res.BatchOpt.Architecture{1}(4:end);
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('2D Semantic');
                    case {'3D U-net', '3D U-net Anisotropic'}
                        res.BatchOpt.Workflow = {'3D Semantic'};
                        res.BatchOpt.Architecture{1} = res.BatchOpt.Architecture{1}(4:end);
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('3D Semantic');
                    case {'2D Patch-wise Resnet18', '2D Patch-wise Resnet50'}
                        res.BatchOpt.Workflow = {'2D Patch-wise'};
                        res.BatchOpt.Architecture{1} = res.BatchOpt.Architecture{1}(15:end);
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('2D Patch-wise');
                end
                res.BatchOpt.Workflow{2} = obj.BatchOpt.Workflow{2}; % {'2D U-net', '2D SegNet', '2D DLv3 Resnet18', '3D U-net', '3D U-net Anisotropic', '2D Patch-wise Resnet18', '2D Patch-wise Resnet50'}
            end

            % correct Architecture names
            if obj.mibController.mibVersionNumeric > 2.9020
                % replace DeepLabV3 to DeepLabV3+ from MIB v2.9020
                switch res.BatchOpt.Architecture{1}
                    case {'Segnet', 'Unet'}

                    case {'DLv3 Resnet18', 'DeepLabV3 Resnet18'}
                        res.BatchOpt.Architecture{1} = 'DeepLab v3+';
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('2D Semantic');
                        res.BatchOpt.T_EncoderNetwork{1} = 'Resnet18';
                        res.BatchOpt.T_EncoderNetwork{2} = {'Resnet18', 'Resnet50', 'Xception', 'InceptionResnetv2'};
                    case {'DLv3 Resnet50', 'DeepLabV3 Resnet50'}
                        res.BatchOpt.Architecture{1} = 'DeepLab v3+';
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('2D Semantic');
                        res.BatchOpt.T_EncoderNetwork{1} = 'Resnet50';
                        res.BatchOpt.T_EncoderNetwork{2} = {'Resnet18', 'Resnet50', 'Xception', 'InceptionResnetv2'};
                    case {'DLv3 Xception', 'DeepLabV3 Xception'}
                        res.BatchOpt.Architecture{1} = 'DeepLab v3+';
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('2D Semantic');
                        res.BatchOpt.T_EncoderNetwork{1} = 'Xception';
                        res.BatchOpt.T_EncoderNetwork{2} = {'Resnet18', 'Resnet50', 'Xception', 'InceptionResnetv2'};
                    case {'DLv3 Inception-ResNet-v2', 'DeepLabV3 Inception-ResNet-v2'}
                        res.BatchOpt.Architecture{1} = 'DeepLab v3+';
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('2D Semantic');
                        res.BatchOpt.T_EncoderNetwork{1} = 'InceptionResnetv2';
                        res.BatchOpt.T_EncoderNetwork{2} = {'Resnet18', 'Resnet50', 'Xception', 'InceptionResnetv2'};
                    case {'Z2C + DLv3 Resnet18', 'Z2C + DLv3 Resnet50'}
                        res.BatchOpt.T_EncoderNetwork{1} = res.BatchOpt.Architecture{1}(end-7:end);
                        res.BatchOpt.T_EncoderNetwork{2} = {'Resnet18', 'Resnet50'};
                        res.BatchOpt.Architecture{1} = 'Z2C + DLv3';
                        res.BatchOpt.Architecture{2} = obj.availableArchitectures('2.5D Semantic');
                end
            elseif obj.mibController.mibVersionNumeric >= 2.85
                % replace DeepLabV3 to DLv3 from MIB v2.85
                res.BatchOpt.Architecture{1} = strrep(res.BatchOpt.Architecture{1}, 'DeepLabV3', 'DLv3');
            end

            switch res.BatchOpt.Architecture{1}
                case {'3DC+DLv3 Resnet18', '3DUnet+DLv3 Resnet18'}
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nThis architecture (%s) is not available in the current version of MIB', res.BatchOpt.Architecture{1}), ...
                        'Wrong architecture', 'Icon', 'error');
                    return;
                    % res.BatchOpt.Architecture{1} = '3DC + DLv3 Resnet18';
            end

            if ~isfield(res.AugOpt2DStruct, 'RandScale') || ~isstruct(res.AugOpt2DStruct.RandScale)
                res.AugOpt2DStruct = mibDeepConvertOldAugmentationSettingsToNew(res.AugOpt2DStruct, '2D');
            end
            if ~isfield(res.AugOpt3DStruct, 'RandScale') || ~isstruct(res.AugOpt3DStruct.RandScale)
                res.AugOpt3DStruct = mibDeepConvertOldAugmentationSettingsToNew(res.AugOpt3DStruct, '3D');
            end
        end

        function loadConfig(obj, configName)
            % function loadConfig(obj, configName)
            % load config file with Deep MIB settings
            %
            % Parameters:
            % configName: full filename for the config file to load

            if nargin < 2
                [file, projectPath] = mib_uigetfile({'*.mibCfg;', 'Deep MIB config files (*.mibCfg)';
                    '*.mat', 'Mat files (*.mat)'}, 'Open network file', ...
                    obj.BatchOpt.NetworkFilename);
                if isequal(file, 0); return; end
                file = file{1};
                configName = fullfile(projectPath, file);
            else
                projectPath = fileparts(configName);
            end

            % remove slash from the end of the path
            if strcmp(projectPath(end), filesep); projectPath = projectPath(1:end-1); end

            obj.wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Loading config file\nPlease wait...'), ...
                'Title', 'Load config');

            res = load(configName, '-mat');
            obj.wb.Value = 0.2;
            
            % correct the slash characters depending on OS
            if ispc
                res.BatchOpt.NetworkFilename = strrep(res.BatchOpt.NetworkFilename, '/', filesep);
                res.BatchOpt.OriginalTrainingImagesDir = strrep(res.BatchOpt.OriginalTrainingImagesDir, '/', filesep);
                res.BatchOpt.OriginalPredictionImagesDir = strrep(res.BatchOpt.OriginalPredictionImagesDir, '/', filesep);
                res.BatchOpt.ResultingImagesDir = strrep(res.BatchOpt.ResultingImagesDir, '/', filesep);
            else
                res.BatchOpt.NetworkFilename = strrep(res.BatchOpt.NetworkFilename, '\', filesep);
                res.BatchOpt.OriginalTrainingImagesDir = strrep(res.BatchOpt.OriginalTrainingImagesDir, '\', filesep);
                res.BatchOpt.OriginalPredictionImagesDir = strrep(res.BatchOpt.OriginalPredictionImagesDir, '\', filesep);
                res.BatchOpt.ResultingImagesDir = strrep(res.BatchOpt.ResultingImagesDir, '\', filesep);
            end

            % restore full paths from relative
            if isempty(strfind(res.BatchOpt.NetworkFilename, '[RELATIVE]\'))
                % older version of configs, where the relative path encoded
                % as "[RELATIVE]subdir", i.e. without slash
                res.BatchOpt.NetworkFilename = strrep(res.BatchOpt.NetworkFilename, '[RELATIVE]', [projectPath filesep]); %#ok<*PROP>
                res.BatchOpt.OriginalTrainingImagesDir = strrep(res.BatchOpt.OriginalTrainingImagesDir, '[RELATIVE]', [projectPath filesep]);
                res.BatchOpt.OriginalPredictionImagesDir = strrep(res.BatchOpt.OriginalPredictionImagesDir, '[RELATIVE]', [projectPath filesep]);
                res.BatchOpt.ResultingImagesDir = strrep(res.BatchOpt.ResultingImagesDir, '[RELATIVE]', [projectPath filesep]);
            else
                % newer version of configs, where the relative path encoded
                % as "[RELATIVE]\subdir", i.e. with slash
                res.BatchOpt.NetworkFilename = convertRelativeToAbsolutePath(res.BatchOpt.NetworkFilename, projectPath, '[RELATIVE]'); %#ok<*PROP>
                res.BatchOpt.OriginalTrainingImagesDir = convertRelativeToAbsolutePath(res.BatchOpt.OriginalTrainingImagesDir, projectPath, '[RELATIVE]');
                res.BatchOpt.OriginalPredictionImagesDir = convertRelativeToAbsolutePath(res.BatchOpt.OriginalPredictionImagesDir, projectPath, '[RELATIVE]');
                res.BatchOpt.ResultingImagesDir = convertRelativeToAbsolutePath(res.BatchOpt.ResultingImagesDir, projectPath, '[RELATIVE]');
            end

            if ~isfield(res.BatchOpt, 'T_ActivationLayer')
                res.BatchOpt.T_ActivationLayer = {'reluLayer'};
                res.BatchOpt.T_ActivationLayer{2} = {'clippedReluLayer', 'eluLayer', 'leakyReluLayer', 'reluLayer', 'swishLayer', 'tanhLayer'};
            end

            % update res.BatchOpt to be compatible with DeepMIB v2.83
            res = correctBatchOpt(obj, res);
            if isempty(res); delete(obj.wb); return; end
            obj.wb.Value = 0.4;

            % remove ImageNoise that may somehow sneak when importing old projects
            if isfield(res.AugOpt2DStruct, 'ImageNoise');  res.AugOpt2DStruct = rmfield(res.AugOpt2DStruct, 'ImageNoise'); end

            % compare current vs the loaded workflow
            if ~strcmp(obj.BatchOpt.Workflow{1}, res.BatchOpt.Workflow{1})
                obj.View.handles.Workflow.Value = res.BatchOpt.Workflow{1};
                obj.selectWorkflow();
            end
            % compare current vs the loaded architecture
            if ~strcmp(obj.BatchOpt.Architecture{1}, res.BatchOpt.Architecture{1})
                obj.View.handles.Architecture.Value = res.BatchOpt.Architecture{1};
                obj.selectArchitecture();
            end

            % add/update BatchOpt with the provided fields in BatchOptIn
            % combine fields from input and default structures
            obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, res.BatchOpt);
            if ~strcmp(obj.View.handles.T_EncoderNetwork.Value, obj.BatchOpt.T_EncoderNetwork{1})
                obj.View.handles.T_EncoderNetwork.Value = obj.BatchOpt.T_EncoderNetwork{1};
                event.Source = obj.View.handles.T_EncoderNetwork;
                obj.updateBatchOptFromGUI(event);
            end
            obj.wb.Value = 0.8;

            try
                if isstruct(obj.AugOpt2D.RandScale)
                    obj.AugOpt2D = mibConcatenateStructures(obj.AugOpt2D, res.AugOpt2DStruct);
                    obj.AugOpt3D = mibConcatenateStructures(obj.AugOpt3D, res.AugOpt3DStruct);
                else
                    % the current obj.AugOpt2D is in the old format, thus
                    % overwrite it with settings from the config file
                    obj.AugOpt2D = res.AugOpt2DStruct;
                    obj.AugOpt3D = res.AugOpt3DStruct;
                end
                obj.TrainingOpt = mibConcatenateStructures(obj.TrainingOpt, res.TrainingOptStruct);
                % fix an old parameter that is no longer in use
                if strcmp(obj.TrainingOpt.Plots, 'training-progress-Matlab'); obj.TrainingOpt.Plots = 'training-progress'; end
                obj.InputLayerOpt = mibConcatenateStructures(obj.InputLayerOpt, res.InputLayerOpt);

                if isfield(res, 'ActivationLayerOpt')   % new in MIB 2.71
                    obj.ActivationLayerOpt = mibConcatenateStructures(obj.ActivationLayerOpt, res.ActivationLayerOpt);
                    obj.SegmentationLayerOpt = mibConcatenateStructures(obj.SegmentationLayerOpt, res.SegmentationLayerOpt);
                end
                if isfield(res, 'DynamicMaskOpt')   % new in MIB 2.83
                    obj.DynamicMaskOpt = mibConcatenateStructures(obj.DynamicMaskOpt, res.DynamicMaskOpt);
                end
            catch err
                % when the training was stopped before finish,
                % those structures are not stored
            end

            obj.updateWidgets();

            obj.wb.Value = 1;
            delete(obj.wb);

            % the two following commands are fix of sending the DeepMIB
            % window behind main MIB window
            drawnow;
            figure(obj.View.gui);
        end

        function startPredictionBlockedImage(obj)
            % function startPredictionBlockedImage(obj)
            % predict 2D/3D datasets using the blockedImage class
            % requires R2021a or newer

            % detect 2D or 3D architecture
            if ismember(obj.BatchOpt.Workflow{1}, {'3D Semantic'})
                if obj.BatchOpt.P_DynamicMasking == true
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nUnfortunately, the dynamic masking mode is not yet implemented for 3D architectures!\n\nPlease uncheck "Dynamic masking" checkbox in the Predict tab'), ...
                        'Not yet implemented');
                    return;
                end
            end

            % detect dimension for the data
            switch obj.BatchOpt.Workflow{1}
                case {'2D Semantic', '2D Patch-wise'}
                    dataDimension = 2;
                case '2.5D Semantic'
                    dataDimension = 2.5;
                case '3D Semantic'
                    dataDimension = 3;
            end

            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Training')
                preprocessedSwitch = false;

                msg = sprintf('!!! Warning !!!\nYou are going to start prediction without preprocessing!\nConfirm that your images are located under\n\n%s\n\n%s\n%s\n\n%s', ...
                    obj.BatchOpt.OriginalPredictionImagesDir, ...
                    '- Images', '- Labels (optionally, when ground truth is present)', ...
                    'Patch-wise mode is also allowing to have patches stored in subfolders');

                selection = uiconfirm(obj.View.gui, ...
                    msg, 'Preprocessing',...
                    'Options',{'Confirm', 'Cancel'},...
                    'DefaultOption', 1, 'CancelOption', 2,...
                    'Icon', 'warning');
                if strcmp(selection, 'Cancel'); return; end
            else
                preprocessedSwitch = true;
                msg = sprintf('Have images for prediction were preprocessed?\n\nIf not, please switch to the Directories and Preprocessing tab and preprocess images for prediction');
                selection = uiconfirm(obj.View.gui, ...
                    msg, 'Preprocessing',...
                    'Options',{'Yes', 'No'},...
                    'DefaultOption', 1, 'CancelOption', 2);
                if strcmp(selection, 'No'); return; end
            end

            % detect patch-wise mode
            patchwiseWorkflowSwitch = false;
            patchwisePatchesPredictSwitch = false; % additional switch specifying prediction of patches that are stored in subfolders within Predict directory
            if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise')
                patchwiseWorkflowSwitch = true;
            end

            % get settings for export of score files
            % {'Do not generate', 'Use AM format', 'Use Matlab non-compressed format', 'Use Matlab compressed format', 'Use Matlab non-compressed format (range 0-1)'};
            if strcmp(obj.BatchOpt.P_ScoreFiles{1}, 'Do not generate')
                generateScoreFiles = 0;
            else
                % check for grayscale images, in R2021a-R2022a they can not be generated
                if str2double(obj.BatchOpt.T_InputPatchSize(end)) == 1 && verLessThan('matlab', '9.13')
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nUnfortunately generation of score files for grayscale datasets for the block-image processing mode is only possible in R2022b or newer!\n\nPlease select:\nScore files: "Do not generate"\n\nor use the legacy mode instead!'), ...
                        'Score files error');
                    return;
                end

                generateScoreFiles = find(ismember(obj.BatchOpt.P_ScoreFiles{2}, obj.BatchOpt.P_ScoreFiles{1}))-1;
                % 1-> 'Use AM format'
                % 2-> 'Use Matlab non-compressed format'
                % 3-> 'Use Matlab compressed format'
                % 4-> 'Use Matlab non-compressed format (range 0-1)'

                saveImageOpt.dimOrder = 'yxczt';    % for 2D or saveImageOpt.dimOrder = 'yxzct'; for 3D
            end

            if obj.BatchOpt.showWaitbar
                % make uiprogressdlg based waitbar
                pwb = PoolWaitbar(1, 'Creating image store for prediction...', [], 'Predicting dataset', obj.View.gui);
            end

            % creating output directories
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            % check whether the output folder exists and whether there are
            % some files in there
            noOutputModelFiles = 0;
            noOutputScoreFiles = 0;
            if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'))
                outputList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
                noOutputModelFiles = abs(sum([outputList.isdir]-1));
            end
            if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'))
                outputList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
                noOutputScoreFiles = abs(sum([outputList.isdir]-1));
            end
            if noOutputModelFiles > 0 || noOutputScoreFiles > 0
                selection = uiconfirm(obj.View.gui, ...
                    sprintf(['!!! Warning !!!\n\n' ...
                    'The destination directories:\n- PredictionImages/ResultsModels\n- PredictionImages/ResultsScores\n\n' ...
                    'in\n%s\n\n' ...
                    'are not empty!\n\nShell the destination folders be emptied and prediction started?'], obj.BatchOpt.ResultingImagesDir), ...
                    'Destination folders are not empty',...
                    'Icon','warning');
                if strcmp(selection, 'Cancel'); if obj.BatchOpt.showWaitbar; delete(obj.wb); end; return; end
                if noOutputModelFiles > 0
                    delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', '*'));
                end
                if noOutputScoreFiles > 0
                    delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', '*'));
                end
            end

            % isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'))
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));

            % prepare options for loading of images
            mibDeepStoreLoadImagesOpt.mibBioformatsCheck = obj.BatchOpt.Bioformats;
            mibDeepStoreLoadImagesOpt.BioFormatsIndices = obj.BatchOpt.BioformatsIndex{1};
            mibDeepStoreLoadImagesOpt.Workflow = obj.BatchOpt.Workflow{1};

            % make a datastore for images
            try
                if preprocessedSwitch   % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), ...
                        'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepStoreLoadImages);
                else    % without preprocessing
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]);
                    if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise' )
                        filelist = dir(obj.BatchOpt.OriginalPredictionImagesDir);
                        if sum([filelist.isdir]) == 2  % no directories present, predict images under obj.BatchOpt.OriginalPredictionImagesDir
                            imgDS = imageDatastore(obj.BatchOpt.OriginalPredictionImagesDir, ...
                                'FileExtensions', fnExtention, ...
                                'IncludeSubfolders', false, ...
                                'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                        else
                            if isfolder(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'))
                                imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'), ...
                                    'FileExtensions', fnExtention, ...
                                    'IncludeSubfolders', false, ...
                                    'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                            else
                                % patch-wise segmentation of individual patches
                                % stored under subfolders
                                imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir), ...
                                    'FileExtensions', fnExtention, ...
                                    'IncludeSubfolders', true, ...
                                    "LabelSource", "foldernames", ...
                                    'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                                if numel(unique(imgDS.Labels)) < 1
                                    ME = MException('MyComponent:noSuchVariable:MissingFiles', ...
                                        ['For the patch-wise mode the files needs to be arranged under "Images"/"Labels" subfolders\n' ...
                                        'or under subfolders with names of each image class!\n\n' ...
                                        'Please check directory with images for Prediction']);
                                    throw(ME);
                                end
                                patchwisePatchesPredictSwitch = true;
                            end
                        end
                    else
                        imagesSubfolder = 'Images';
                        if ~isfolder(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'))
                            res = uiconfirm(obj.View.gui, ...
                                sprintf(['It is recommended to keep images for prediction under "Images" subfolder within the directory specified in \n\n' ...
                                '"Directories and Preprocessing" -> \n\t\t\t"Directory with images for prediction"\n\n' ...
                                'However "Images" subfolder was not found!\n\nWould you like to continue and predict images that are located under:\n' ...
                                '%s'], obj.BatchOpt.OriginalPredictionImagesDir), ...
                                'Missing Images subfolder', ...
                                'Options', {'Predict images','Cancel'}, ...
                                'Icon', 'warning');
                            if strcmp(res, 'Cancel');  if obj.BatchOpt.showWaitbar; delete(obj.wb); end; return; end
                            imagesSubfolder = [];
                        end

                        % semantic segmentation or patch-wise segmentation of large images
                        imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, imagesSubfolder), ...
                            'FileExtensions', fnExtention, ...
                            'IncludeSubfolders', false, ...
                            'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                    end

                    % if isfolder(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'))
                    %     % semantic segmentation or patch-wise segmentation of large images
                    %     imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'), ...
                    %         'FileExtensions', fnExtention, ...
                    %         'IncludeSubfolders', false, ...
                    %         'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                    % else
                    %     % patch-wise segmentation of individual patches
                    %     % stored under subfolders
                    %     imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir), ...
                    %         'FileExtensions', fnExtention, ...
                    %         'IncludeSubfolders', true, ...
                    %         "LabelSource", "foldernames", ...
                    %         'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                    %     if numel(unique(imgDS.Labels)) < 2
                    %         ME = MException('MyComponent:noSuchVariable:MissingFiles', ...
                    %             ['For the patch-wise mode the files needs to be arranged under "Images"/"Labels" subfolders\n' ...
                    %             'or under subfolders with names of each image class!\n\n' ...
                    %             'Please check directory with images for Prediction']);
                    %         throw(ME);
                    %     end
                    %     patchwisePatchesPredictSwitch = true;
                    % end
                end
            catch err
                %obj.showErrorDialog(err, 'Missing files');
                mibShowErrorDialog(obj.View.gui, err, 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end

            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                extraWaitbarInfo = '';
                if patchwisePatchesPredictSwitch; extraWaitbarInfo = ' for the patch-wise mode'; end
                pwb.updateText(sprintf('Loading network%s\nPlease wait...', extraWaitbarInfo));
            end
            % loading: 'net', 'TrainingOptStruct', 'classNames',
            % 'inputPatchSize', 'outputPatchSize', 'BatchOpt' variables
            load(obj.BatchOpt.NetworkFilename, '-mat');

            numClasses = numel(classNames); %#ok<USENS>
            if exist('classColors', 'var')
                modelMaterialColors = classColors;  %#ok<PROP> % loaded from network file
            else
                modelMaterialColors = rand([numClasses, 3]);
            end

            % correct tile overlapping strategy for the valid padding
            if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                obj.BatchOpt.P_OverlappingTiles = false;
                obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                obj.View.Figure.P_OverlappingTiles.Value = false;
                obj.View.Figure.P_OverlappingTilesPercentage.Enable = 'off';
            end

            %% Start prediction
            % Use the overlap-tile strategy to predict the labels for each volume.
            % Each test volume is padded to make the input size a multiple of the output size
            % of the network and compensates for the effects of valid convolution.
            % The overlap-tile algorithm selects overlapping patches, predicts the labels
            % for each patch by using the semanticseg function, and then recombines the patches.

            noFiles = numel(imgDS.Files);
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end   % check for cancel
                pwb.updateText(sprintf('Starting prediction%s\nPlease wait...', extraWaitbarInfo));
            end
            id = 1;     % indices of files

            %% TO DO:
            % 1. check situation, when the dataset for prediction is
            % smaller that then dataset for training: 2D and 3D cases
            % 2. check different padvalue in the code below: volPadded = padarray (vol, padSize, 0, 'post');

            % select gpu or cpu for prediction and define executionEnvironment
            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            switch obj.View.Figure.GPUDropDown.Value
                case 'CPU only'
                    if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                        gpuDevice([]);  % CPU only mode
                    end
                    executionEnvironment = 'cpu';
                case 'Multi-GPU'
                    if patchwiseWorkflowSwitch
                        % in the patchwise workflow classify function
                        % compatible with multi-gpu is used
                        executionEnvironment = 'multi-gpu';
                    else
                        % in other workflows semanticseg is used with is
                        % not compatible with multi-gpu
                        executionEnvironment = 'gpu';
                    end

                case 'Parallel'
                    executionEnvironment = 'parallel';
                otherwise
                    gpuDevice(selectedIndex);   % choose selected GPU device
                    executionEnvironment = 'gpu';
            end

            if patchwisePatchesPredictSwitch % images in Predict folder is stored in subfolders named as class names
                filenamesCell = strrep(imgDS.Files, imgDS.Folders, '');
                classNamesStr = repmat(strjoin(string(classNames'), ', '), [noFiles, 1]);
                try
                    % works in R2023b, but does not in R2023a
                    path1 = arrayfun(@fileparts, imgDS.Files, 'UniformOutput', true);
                    [~, realClassCell] = arrayfun(@fileparts, path1, 'UniformOutput', true);
                catch err
                    % works in R2023a
                    path1 = arrayfun(@fileparts, imgDS.Files, 'UniformOutput', false);
                    [~, realClassCell] = arrayfun(@fileparts, path1, 'UniformOutput', false);
                end
                predictedClassCell = cell([noFiles, 1]);
                probabilityMatrix = zeros([noFiles, numel(classNames)]);
                patchWiseOutout = table(filenamesCell, classNamesStr, realClassCell, predictedClassCell, probabilityMatrix);
                patchWiseOutout.Properties.VariableNames = {'Filename', 'ClassNames', 'RealClass', 'PredictedClass', 'MaxProbability'};
            end

            % use %% type of the progress dialog to use 5% increments, i.e.
            % for each file the progress bar will be updated 20 times to
            % follow the progress
            %if strcmp(obj.BatchOpt.Workflow{1}, '2.5D Semantic') && obj.BatchOpt.showWaitbar
            progressUpdatesPerFile = 1;
            if obj.BatchOpt.showWaitbar
                progressUpdatesPerFile = 20;
                pwb.updateMaxNumberOfIterations(noFiles*progressUpdatesPerFile);
            end

            t1 = tic;

            while hasdata(imgDS)
                % check for Cancel
                if obj.BatchOpt.showWaitbar && pwb.getCancelState(); delete(pwb); return; end

                % update block size
                if dataDimension == 2         % 2D case
                    padShift = [0 0]; % pad shift for the overlap mode
                    blockSize = [inputPatchSize(1) inputPatchSize(2)];
                else                % 2.5D and 3D case dataDimension == 2.5 or dataDimension == 3
                    padShift = [0 0 0]; % pad shift for the overlap mode
                    blockSize = [inputPatchSize(1) inputPatchSize(2) inputPatchSize(3)];
                end

                % correct block size depending on padding method and overlap mode
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same') && obj.BatchOpt.P_OverlappingTiles % same padding + overlap mode
                    %padShift = ceil(inputPatchSize(1)*obj.BatchOpt.P_OverlappingTilesPercentage{1}/100);
                    padShift = ceil(inputPatchSize(1:numel(blockSize))*obj.BatchOpt.P_OverlappingTilesPercentage{1}/100);  % padShift(y,x,z) or padShift(y,x)
                    blockSize = blockSize-padShift*2;
                elseif strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')    % valid padding
                    if dataDimension == 2 % 2D case
                        blockSize = outputPatchSize(1:2);
                    else    % 2.5D and 3D case dataDimension == 2.5 or dataDimension == 3
                        blockSize = outputPatchSize(1:numel(outputPatchSize)-1);
                    end
                end

                % read image
                vol = read(imgDS);
                [~, fn] = fileparts(imgDS.Files{id});

                % downsample the input image corresponding to the
                % downsampling factor
                if obj.BatchOpt.P_ImageDownsamplingFactor{1} ~= 1
                    imResizeOpt.imgType = '3D';
                    imResizeOpt.showWaitbar = false;
                    if dataDimension == 2
                        [imgHeight, imgWidth, noColors] = size(vol);
                        imgDepth = 1;
                    else
                        [imgHeight, imgWidth, imgDepth, noColors] = size(vol);
                    end
                    if noColors > 1; imResizeOpt.imgType = '4D'; end
                    imResizeOpt.width = round(imgWidth/obj.BatchOpt.P_ImageDownsamplingFactor{1});  % new width value, overrides the scale parameter
                    imResizeOpt.height = round(imgHeight/obj.BatchOpt.P_ImageDownsamplingFactor{1});  % new height value, overrides the scale parameter
                    imResizeOpt.depth = imgDepth;
                    if dataDimension == 3 % for 3D downsample all dimensions
                        imResizeOpt.depth = round(imgDepth/obj.BatchOpt.P_ImageDownsamplingFactor{1}); % % new depth value, overrides the scale parameter
                    end
                    vol = mibResize3d(vol, [], imResizeOpt);
                end

                % depth of the volume
                volDepth = size(vol, 3);
                nextWaitbarIterationFromZ = volDepth/progressUpdatesPerFile; % z-value when the progress bar needs to be updated

                if strcmp(obj.BatchOpt.Workflow{1}, '2.5D Semantic')
                    blockSize(3) = inputPatchSize(3);   % update blockSize for 2.5D networks
                    padShift(3) = 0;
                    paddingValue = floor(inputPatchSize(3)/2);

                    for zValue = 1:volDepth
                        if zValue <= paddingValue
                            subVol = padarray(vol(:,:,max([zValue-paddingValue,1]):zValue+paddingValue), [0, 0, paddingValue-zValue+1], 'symmetric', 'pre');
                        elseif zValue > volDepth-paddingValue
                            subVol = padarray(vol(:,:, zValue-paddingValue:min([zValue+paddingValue,volDepth])), [0, 0, zValue-volDepth+paddingValue], 'symmetric', 'post');
                        else
                            subVol = vol(:,:,zValue-paddingValue:zValue+paddingValue);
                        end

                        [outputLabelsCurrent, scoreImgCurrent] = obj.processBlocksBlockedImage(subVol, zValue, net, ...
                            inputPatchSize, outputPatchSize, blockSize, padShift, ...
                            dataDimension, patchwiseWorkflowSwitch, patchwisePatchesPredictSwitch, ...
                            classNames, generateScoreFiles, executionEnvironment, fn);

                        if zValue == 1
                            outputLabels = zeros([size(outputLabelsCurrent,1), size(outputLabelsCurrent,2), volDepth], 'uint8');
                            if generateScoreFiles > 0
                                scoreImg = zeros([size(scoreImgCurrent,1), size(scoreImgCurrent,2), size(scoreImgCurrent,3), volDepth], 'uint8');
                            else
                                scoreImg = 0;
                            end
                        end
                        outputLabels(:,:,zValue) = outputLabelsCurrent; % (:,:,paddingValue+1);
                        if generateScoreFiles > 0
                            scoreImg(:,:,:,zValue) = scoreImgCurrent; % (:,:,:,paddingValue+1);
                        end

                        % check for Cancel
                        if obj.BatchOpt.showWaitbar && pwb.getCancelState(); delete(pwb); return; end

                        % update progress bar
                        if obj.BatchOpt.showWaitbar && zValue >= nextWaitbarIterationFromZ
                            elapsedTime = toc(t1);
                            currIteration = pwb.getCurrentIteration()+1;
                            timerValue = elapsedTime/currIteration*(pwb.getMaxNumberOfIterations()-currIteration);
                            pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                            pwb.increment();
                            nextWaitbarIterationFromZ = nextWaitbarIterationFromZ + volDepth/progressUpdatesPerFile;
                        end
                    end
                else   % '2D Semantic', '3D Semantic', '2D Patch-wise'
                    % detect whether to use 2D net with 3D datasets, in this
                    % case the full volume will be loaded and processed
                    % slice-by-slice
                    if dataDimension == 2       % 2D case
                        if volDepth > 3 && size(vol, 3) ~= inputPatchSize(4)
                            use3DdatasetWith2Dnet = true;
                            pwb.setIncrement(1);
                        else
                            use3DdatasetWith2Dnet = false;
                            pwb.setIncrement(progressUpdatesPerFile);
                        end
                    elseif dataDimension == 3
                        use3DdatasetWith2Dnet = false;
                        pwb.setIncrement(progressUpdatesPerFile);
                    else
                        use3DdatasetWith2Dnet = false;
                        pwb.setIncrement(1);
                    end

                    if use3DdatasetWith2Dnet
                        for zValue = 1:volDepth
                            [outputLabelsCurrent, scoreImgCurrent] = obj.processBlocksBlockedImage(squeeze(vol(:,:,zValue,:)), zValue, net, ...
                                inputPatchSize, outputPatchSize, blockSize, padShift, ...
                                dataDimension, patchwiseWorkflowSwitch, patchwisePatchesPredictSwitch, ...
                                classNames, generateScoreFiles, executionEnvironment, fn);
                            if zValue == 1
                                outputLabels = zeros([size(outputLabelsCurrent,1), size(outputLabelsCurrent,2), volDepth], 'uint8');
                                if generateScoreFiles > 0
                                    scoreImg = zeros([size(scoreImgCurrent,1), size(scoreImgCurrent,2), size(scoreImgCurrent,3), volDepth], 'uint8');
                                else
                                    scoreImg = 0;
                                end
                            end
                            outputLabels(:,:,zValue) = outputLabelsCurrent;
                            if generateScoreFiles > 0
                                scoreImg(:,:,:,zValue) = scoreImgCurrent;
                            end

                            % check for Cancel
                            if obj.BatchOpt.showWaitbar && pwb.getCancelState(); delete(pwb); return; end
                            % update progress bar
                            if obj.BatchOpt.showWaitbar && zValue >= nextWaitbarIterationFromZ
                                elapsedTime = toc(t1);
                                currIteration = pwb.getCurrentIteration()+1;
                                timerValue = elapsedTime/currIteration*(pwb.getMaxNumberOfIterations()-currIteration);
                                pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                                pwb.increment();
                                nextWaitbarIterationFromZ = nextWaitbarIterationFromZ + volDepth/progressUpdatesPerFile;
                            end
                        end
                    else
                        zValue = NaN;
                        [outputLabels, scoreImg] = obj.processBlocksBlockedImage(vol, zValue, net, ...
                            inputPatchSize, outputPatchSize, blockSize, padShift, ...
                            dataDimension, patchwiseWorkflowSwitch, patchwisePatchesPredictSwitch, ...
                            classNames, generateScoreFiles, executionEnvironment, fn);

                        % check for Cancel
                        if obj.BatchOpt.showWaitbar && pwb.getCancelState(); delete(pwb); return; end
                        % update progress bar
                        if obj.BatchOpt.showWaitbar
                            elapsedTime = toc(t1);
                            currIteration = pwb.getCurrentIteration()+1;
                            timerValue = elapsedTime/currIteration*(pwb.getMaxNumberOfIterations()-currIteration);
                            pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                            pwb.increment();
                        end
                    end
                end

                % upsample results beased on downsampling factor
                if obj.BatchOpt.P_ImageDownsamplingFactor{1} ~= 1
                    imResizeOpt.imgType = '3D';
                    imResizeOpt.width = imgWidth;  % upsample width value, overrides the scale parameter
                    imResizeOpt.height = imgHeight;  % upsample height value, overrides the scale parameter
                    imResizeOpt.depth = imgDepth;
                    imResizeOpt.method = 'nearest';
                    outputLabels = mibResize3d(outputLabels, [], imResizeOpt);

                    % % smooth models for 2 classes outputs
                    if numClasses == 2
                        smoothOptions.dataType = '3D';
                        smoothOptions.fitType = 'Gaussian';
                        smoothOptions.showWaitbar = false;
                        smoothOptions.sigma = obj.BatchOpt.P_ImageDownsamplingFactor{1}+1;
                        if dataDimension == 3
                            smoothOptions.filters3DCheck = 1;
                            smoothOptions.hSize = [obj.BatchOpt.P_ImageDownsamplingFactor{1}*2+1 obj.BatchOpt.P_ImageDownsamplingFactor{1}*2+1];
                        else
                            smoothOptions.filters3DCheck = 0;
                            smoothOptions.hSize = obj.BatchOpt.P_ImageDownsamplingFactor{1}*2+1;
                        end
                        outputLabels = mibDoImageFiltering(outputLabels, smoothOptions);
                    end

                    if generateScoreFiles > 0
                        imResizeOpt.imgType = '4D';
                        scoreImg = mibResize3d(scoreImg, [], imResizeOpt);
                    end
                end

                % Save results
                if ~patchwisePatchesPredictSwitch % standard semantic segmentation mode or patch-wise mode when prediction images are not in patches
                    % depending on the selected output type
                    switch obj.BatchOpt.P_ModelFiles{1}
                        case 'MIB Model format'
                            modelMaterialNames = classNames;
                            if ~patchwiseWorkflowSwitch; modelMaterialNames(1) = []; end % remove Exterior

                            modelMaterialColors = [modelMaterialColors; obj.modelMaterialColors]; %#ok<AGROW,PROP>
                            filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.model']);
                            modelVariable = 'outputLabels';
                            modelType = 63;
                            if exist('BoundingBox','var') == 0
                                save(filename, 'outputLabels', 'modelMaterialNames', 'modelMaterialColors', ...
                                    'modelVariable', 'modelType', '-mat', '-v7.3');
                            else
                                save(filename, 'outputLabels', 'modelMaterialNames', 'modelMaterialColors', ...
                                    'BoundingBox', 'modelVariable', 'modelType', '-mat', '-v7.3');
                            end
                        case {'TIF compressed format', 'TIF uncompressed format'}
                            if strcmp(obj.BatchOpt.P_ModelFiles{1}, 'TIF compressed format')
                                tifCompression = 'lzw';
                            else
                                tifCompression = 'none';
                            end
                            filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.tif']);
                            imwrite(outputLabels(:,:,1), filename, 'tif', 'WriteMode', 'overwrite', 'Description', sprintf('DeepMIB segmentation: $s %s', obj.BatchOpt.Workflow{1}, obj.BatchOpt.Architecture{1}), 'Compression', tifCompression);
                            if dataDimension ~= 2 || use3DdatasetWith2Dnet % 2.5D and 3D case dataDimension == 2.5 or dataDimension == 3
                                for sliceId = 2:size(outputLabels, 3)
                                    imwrite(outputLabels(:,:,sliceId), filename, 'tif', 'WriteMode', 'append', 'Compression', tifCompression);
                                end
                            end
                    end
                    %
                    %                     % save score map
                    if generateScoreFiles > 0
                        if generateScoreFiles == 1    % 'Use AM format'
                            filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.am']);
                            amiraOpt.overwrite = 1;
                            amiraOpt.showWaitbar = 0;
                            amiraOpt.verbose = false;
                            bitmap2amiraMesh(filename, scoreImg, [], amiraOpt);
                        elseif generateScoreFiles == 4   %  4=='Use Matlab non-compressed format (range 0-1)'
                            filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mat']);
                            saveImageParFor(filename, scoreImg, false, saveImageOpt);
                        else  % 2=='Use Matlab non-compressed format', 3=='Use Matlab compressed format'
                            filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mibImg']);
                            saveImageParFor(filename, scoreImg, generateScoreFiles, saveImageOpt);
                        end
                    end
                else    % patchwisePatchesPredictSwitch == true, patch-wise mode, when each patch is contained in its own subfolder
                    %                     outputLabels = gather(outputLabels, 'Level', 1); % convert blocked image to normal matrix
                    patchWiseOutout.PredictedClass{id} = char(outputLabels);
                    scoreImg = gather(scoreImg, 'Level', 1); % convert blocked image to normal matrix
                    patchWiseOutout.MaxProbability(id,:) = squeeze(max(scoreImg,[], 1:2))';
                end
                id=id+1;
            end

            % save the resulting file
            if patchwisePatchesPredictSwitch == true
                % generate CSV files for the patch-wise segmentations
                filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'patchPredictionResults.csv');
                writetable(patchWiseOutout, filename, 'FileType' , 'Text');
                filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'patchPredictionResults.mat');
                save(filename, 'patchWiseOutout', '-mat');
            end
            fprintf('Prediction finished: ');
            toc(t1)

            % count user's points
            obj.mibModel.preferences.Users.Tiers.numberOfInferencedDeepNetworks = obj.mibModel.preferences.Users.Tiers.numberOfInferencedDeepNetworks+1;
            eventdata = ToggleEventData(4);    % scale scoring by factor 5
            notify(obj.mibModel, 'updateUserScore', eventdata);
            if obj.BatchOpt.showWaitbar; delete(pwb); end
        end

        function [outputLabels, scoreImg] = processBlocksBlockedImage(obj, vol, zValue, net, ...
                inputPatchSize, outputPatchSize, blockSize, padShift, ...
                dataDimension, patchwiseWorkflowSwitch, patchwisePatchesPredictSwitch, ...
                classNames, generateScoreFiles, executionEnvironment, fn)
            % dataDimension: numeric switch that identify dataset dimension, can be 2, 2.5, 3

            % define padding method for blocks
            if verLessThan('matlab', '9.14')
                padMethod = 'replicate';
            else
                padMethod = 'symmetric';
            end

            if dataDimension == 2 && size(vol, 3) ~= inputPatchSize(4)
                % dynamically convert grayscale to RGB if needed
                vol = repmat(vol, [1, 1, 3]);
            end

            extraPaddingPixels = 0;
            if obj.View.handles.P_ExtraPaddingPercentage.Value > 0 && ~patchwiseWorkflowSwitch % pad the image
                extraPaddingPixels = ceil(max(inputPatchSize(1:2))*obj.View.handles.P_ExtraPaddingPercentage.Value/100);
                vol = padarray(vol, [extraPaddingPixels extraPaddingPixels], 'symmetric', 'both');
            end

            % get number of colors in vol
            if strcmp(obj.BatchOpt.Architecture{1}(1:3), 'Z2C')
                noColors = size(vol, numel(blockSize));
                dataDimension = 2;
            else
                noColors = size(vol, numel(blockSize)+1);
            end

            vol = blockedImage(vol, ...     % % [height, width, color] or  [height, width, depth, color]
                'Adapter', images.blocked.InMemory);    % convert to blockedimage

            % detect blocks for the dynamic masking mode
            if obj.BatchOpt.P_DynamicMasking
                bls = obj.generateDynamicMaskingBlocks(vol, blockSize, noColors);
            else
                % just init with something to make sure that the following
                % condition will work
                bls.ImageNumber = 1;
            end

            if numel(bls.ImageNumber) > 0
                blockedImageWaitBarStatus = false; % due to a bug switch off waitbar for blockedImage/apply
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')     % same
                    if obj.BatchOpt.P_OverlappingTiles == false
                        if obj.BatchOpt.P_DynamicMasking
                            [outputLabels, scoreImg] = apply(vol, ...       % apply(blockedImage, function, parameters)
                                @(block, blockInfo) mibDeepController.segmentBlockedImage(block, net, dataDimension, patchwiseWorkflowSwitch, generateScoreFiles, executionEnvironment, padShift), ...
                                'Adapter', images.blocked.InMemory, ...
                                'Level', 1, ...
                                'PadPartialBlocks', true, ...
                                'UseParallel', false,...
                                'DisplayWaitbar', blockedImageWaitBarStatus, ...
                                'BatchSize', obj.BatchOpt.P_MiniBatchSize{1}, ...
                                'PadMethod', padMethod, ...
                                'BlockLocationSet', bls);
                        else
                            [outputLabels, scoreImg] = apply(vol, ...       % apply(blockedImage, function, parameters)
                                @(block, blockInfo) mibDeepController.segmentBlockedImage(block, net, dataDimension, patchwiseWorkflowSwitch, generateScoreFiles, executionEnvironment, padShift), ...
                                'Adapter', images.blocked.InMemory, ...
                                'Level', 1, ...
                                'PadPartialBlocks', true, ...
                                'BlockSize', blockSize,...
                                'UseParallel', false,...
                                'DisplayWaitbar', blockedImageWaitBarStatus, ...
                                'PadMethod', padMethod, ...
                                'BatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                        end
                    else % same + overlap
                        %padShift = ceil(inputPatchSize(1)*obj.BatchOpt.P_OverlappingTilesPercentage{1}/100);
                        if obj.BatchOpt.P_DynamicMasking
                            [outputLabels, scoreImg] = apply(vol, ...       % apply(blockedImage, function, parameters)
                                @(block, blockInfo) mibDeepController.segmentBlockedImage(block, net, dataDimension, patchwiseWorkflowSwitch, generateScoreFiles, executionEnvironment, padShift), ...
                                'Adapter', images.blocked.InMemory, ...
                                'Level', 1, ...
                                'PadPartialBlocks', true, ...
                                'BorderSize', padShift,... %'BorderSize', repmat(padShift, [1, numel(blockSize)]),...
                                'UseParallel', false,...
                                'DisplayWaitbar', blockedImageWaitBarStatus, ...
                                'PadMethod', padMethod, ...
                                'BatchSize', obj.BatchOpt.P_MiniBatchSize{1}, ...
                                'BlockLocationSet', bls);
                        else
                            [outputLabels, scoreImg] = apply(vol, ...       % apply(blockedImage, function, parameters)
                                @(block, blockInfo) mibDeepController.segmentBlockedImage(block, net, dataDimension, patchwiseWorkflowSwitch, generateScoreFiles, executionEnvironment, padShift), ...
                                'Adapter', images.blocked.InMemory, ...
                                'Level', 1, ...
                                'PadPartialBlocks', true, ...
                                'BlockSize', blockSize,...  % blockSize-padShift*2
                                'BorderSize', padShift,...   % 'BorderSize', repmat(padShift, [1, numel(blockSize)]),...
                                'UseParallel', false,...
                                'DisplayWaitbar', blockedImageWaitBarStatus, ...
                                'PadMethod', padMethod, ...
                                'BatchSize', obj.BatchOpt.P_MiniBatchSize{1}); % 'PadMethod', 'replicate', ... % 'symmetric'
                        end
                    end
                else    % valid padding
                    if obj.BatchOpt.P_DynamicMasking
                        [outputLabels, scoreImg] = apply(vol, ...       % apply(blockedImage, function, parameters)
                            @(block, blockInfo) mibDeepController.segmentBlockedImage(block, net, dataDimension, patchwiseWorkflowSwitch, generateScoreFiles, executionEnvironment, padShift), ...
                            'Adapter', images.blocked.InMemory, ...
                            'Level', 1, ...
                            'PadPartialBlocks', true, ...
                            'BorderSize', (inputPatchSize(1:numel(blockSize)) - outputPatchSize(1:numel(blockSize))) / 2,...  %  [(inputPatchSize(1)-outputPatchSize(1))/2 (inputPatchSize(2)-outputPatchSize(2))/2]
                            'UseParallel', false,...
                            'DisplayWaitbar', blockedImageWaitBarStatus, ...
                            'BatchSize', obj.BatchOpt.P_MiniBatchSize{1}, ...
                            'PadMethod', padMethod, ...
                            'BlockLocationSet', bls);
                    else
                        [outputLabels, scoreImg] = apply(vol, ...       % apply(blockedImage, function, parameters)
                            @(block, blockInfo) mibDeepController.segmentBlockedImage(block, net, dataDimension, patchwiseWorkflowSwitch, generateScoreFiles, executionEnvironment, padShift), ...
                            'Adapter', images.blocked.InMemory, ...
                            'Level', 1, ...
                            'PadPartialBlocks', true, ...
                            'BlockSize', blockSize,...  	% outputPatchSize(1:numel(outputPatchSize)-1) or [outputPatchSize(1) outputPatchSize(2)]
                            'BorderSize', (inputPatchSize(1:numel(blockSize)) - outputPatchSize(1:numel(blockSize))) / 2,...  %  [(inputPatchSize(1)-outputPatchSize(1))/2 (inputPatchSize(2)-outputPatchSize(2))/2]
                            'UseParallel', false,...
                            'PadMethod', padMethod, ...
                            'DisplayWaitbar', blockedImageWaitBarStatus, ...
                            'BatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                    end
                end
            else
                if dataDimension == 2
                    outputLabels = blockedImage(ones([vol.Size(1) vol.Size(2)], 'uint8'), ...     % % [height, width] or  [height, width, depth]
                        'Adapter', images.blocked.InMemory);    % convert to blockedimage
                    scoreImg = blockedImage(ones([vol.Size(1) vol.Size(2), numel(classNames)], 'uint8'), ...     % % [height, width, classes]
                        'Adapter', images.blocked.InMemory);    % convert to blockedimage
                elseif dataDimension == 2.5
                    outputLabels = blockedImage(ones([vol.Size(1) vol.Size(2)], 'uint8'), ...     % [height, width, classes]
                        'Adapter', images.blocked.InMemory);    % convert to blockedimage
                    scoreImg = blockedImage(ones([vol.Size(1) vol.Size(2),  numel(classNames)], 'uint8'), ...     % % [height, width, classes]
                        'Adapter', images.blocked.InMemory);    % convert to blockedimage
                else    % 3D case dataDimension == 2.5 or dataDimension == 3
                    outputLabels = blockedImage(ones([vol.Size(1) vol.Size(2), vol.Size(3)], 'uint8'), ...     % [height, width, depth, classes]
                        'Adapter', images.blocked.InMemory);    % convert to blockedimage
                    scoreImg = blockedImage(ones([vol.Size(1) vol.Size(2),  vol.Size(3), numel(classNames)], 'uint8'), ...     % % [height, width, classes]
                        'Adapter', images.blocked.InMemory);    % convert to blockedimage
                end
            end

            %[~, fn] = fileparts(imgDS.Files{id});
            if ~patchwisePatchesPredictSwitch % standard semantic segmentation mode or patch-wise mode when prediction images are not in patches
                outputLabels = gather(outputLabels, 'Level', 1); % convert blocked image to normal matrix

                if ~patchwiseWorkflowSwitch
                    outputLabels = outputLabels - 1;    % remove the first "exterior" class

                    % additional cropping from the right-side may be required
                    if dataDimension < 3         % 2D and 2.5D cases
                        if sum(abs(size(outputLabels) - vol.Size(1:2))) ~= 0
                            outputLabels = outputLabels(1:size(vol.Source, 1), 1:size(vol.Source, 2), :);
                        end
                    else                % 2.5D and 3D case dataDimension == 2.5 or dataDimension == 3
                        if sum(abs(size(outputLabels) - vol.Size(1:3))) ~= 0
                            outputLabels = outputLabels(1:size(vol.Source, 1), 1:size(vol.Source, 2), 1:size(vol.Source, 3), :);
                        end
                    end
                else
                    outputLabels = uint8(outputLabels);
                    % generate CSV files for the patch-wise segmentations
                    if isnan(zValue)
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', sprintf('Labels_%s_%.4d.csv', fn, zValue));
                    else
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', sprintf('Labels_%s.csv', fn));
                    end
                    writematrix(outputLabels, filename, 'FileType' , 'Text');

                    % upscale the resulting labels
                    if obj.BatchOpt.P_PatchWiseUpsample
                        if obj.BatchOpt.P_OverlappingTiles
                            outHeight = (inputPatchSize(1)-padShift(1)*2)*size(outputLabels,1);
                            outWidth = (inputPatchSize(2)-padShift(2)*2)*size(outputLabels,2);
                        else
                            outHeight = inputPatchSize(1)*size(outputLabels,1);
                            outWidth = inputPatchSize(2)*size(outputLabels,2);
                        end
                        dummyLabels = imresize(outputLabels, [outHeight, outWidth], 'nearest');
                        outputLabels = dummyLabels(1:size(vol.Source, 1), 1:size(vol.Source, 2));
                    end
                end

                % remove additional padding
                if extraPaddingPixels > 0
                    outputLabels = outputLabels(extraPaddingPixels+1:end-extraPaddingPixels, extraPaddingPixels+1:end-extraPaddingPixels, :, :);
                end

                % save/generate score map
                if generateScoreFiles > 0
                    scoreImg = gather(scoreImg, 'Level', 1); % convert blocked image to normal matrix
                    % additional cropping from the right-side may be required
                    if dataDimension < 3         % 2D case
                        if ~patchwiseWorkflowSwitch
                            % trim the long end if needed
                            if sum(abs(size(scoreImg, 1:2) - vol.Size(1:2))) ~= 0
                                scoreImg = scoreImg(1:size(vol.Source, 1), 1:size(vol.Source, 2), :);
                            end
                        else
                            % generate CSV files for the patch-wise segmentations
                            if isnan(zValue)
                                filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', sprintf('Score_%s_%.4d.csv', fn, zValue));
                            else
                                filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', sprintf('Score_%s.csv', fn));
                            end

                            % generate score table with probabilities
                            % of each class
                            T = table();
                            for classId = 1:size(scoreImg, 3)
                                T.(classNames{classId}) =  scoreImg(:,:,classId);
                            end
                            writetable(T, filename, 'FileType' , 'Text');

                            scoreImg = uint8(scoreImg*255); % convert to uint8 and scale 0-255
                            if obj.BatchOpt.P_PatchWiseUpsample
                                % upscale the resulting scores
                                dummyLabels = zeros([inputPatchSize(1)*size(scoreImg,1), inputPatchSize(2)*size(scoreImg,2), size(scoreImg, 3)], 'uint8');
                                for colCh=1:size(scoreImg, 3)
                                    dummyLabels(:,:,colCh) = imresize(scoreImg(:,:,colCh), [inputPatchSize(1)*size(scoreImg,1), inputPatchSize(2)*size(scoreImg,2)], 'nearest');
                                end
                                scoreImg = dummyLabels(1:size(vol.Source, 1), 1:size(vol.Source, 2), :);
                            end
                        end
                    else                % 3D case
                        if sum(abs(size(scoreImg, 1:3) - vol.Size(1:3))) ~= 0
                            scoreImg = scoreImg(1:size(vol.Source, 1), 1:size(vol.Source, 2), 1:size(vol.Source, 3), :);
                        end
                        scoreImg = permute(scoreImg, [1 2 4 3]);    % convert to [height, width, color, depth]
                    end

                    % remove extra padding from the full image
                    if extraPaddingPixels > 0
                        scoreImg = scoreImg(extraPaddingPixels+1:end-extraPaddingPixels, extraPaddingPixels+1:end-extraPaddingPixels, :, :);
                    end
                end
            else    % patchwisePatchesPredictSwitch == true, patch-wise mode, when each patch is contained in its own subfolder
                outputLabels = gather(outputLabels, 'Level', 1); % convert blocked image to normal matrix
                %patchWiseOutout.PredictedClass{id} = char(outputLabels);
                %scoreImg = gather(scoreImg, 'Level', 1); % convert blocked image to normal matrix
                %patchWiseOutout.MaxProbability(id,:) = squeeze(max(scoreImg,[], 1:2))';
            end
        end

        function startPrediction2D(obj)
            % function startPrediction2D(obj)
            % predict datasets for 2D taken to a separate function for
            % better performance

            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Training')
                preprocessedSwitch = false;

                msg = sprintf('!!! Warning !!!\nYou are going to start prediction without preprocessing!\nConfirm that your images are located under\n\n%s\n\n%s\n%s\n\n', ...
                    obj.BatchOpt.OriginalPredictionImagesDir, ...
                    '- Images', '- Labels (optionally, when ground truth is present)');

                selection = uiconfirm(obj.View.gui, ...
                    msg, 'Preprocessing',...
                    'Options',{'Confirm', 'Cancel'},...
                    'DefaultOption', 1, 'CancelOption', 2,...
                    'Icon', 'warning');
                if strcmp(selection, 'Cancel'); return; end
            else
                preprocessedSwitch = true;
                msg = sprintf('Have images for prediction were preprocessed?\n\nIf not, please switch to the Directories and Preprocessing tab and preprocess images for prediction');
                selection = uiconfirm(obj.View.gui, ...
                    msg, 'Preprocessing',...
                    'Options',{'Yes', 'No'},...
                    'DefaultOption', 1, 'CancelOption', 2);
                if strcmp(selection, 'No'); return; end
            end

            % get settings for export of score files
            % {'Do not generate', 'Use AM format', 'Use Matlab non-compressed format', 'Use Matlab compressed format'};
            if strcmp(obj.BatchOpt.P_ScoreFiles{1}, 'Do not generate')
                generateScoreFiles = 0;
            else
                generateScoreFiles = find(ismember(obj.BatchOpt.P_ScoreFiles{2}, obj.BatchOpt.P_ScoreFiles{1}))-1;
                % 1-> 'Use AM format'
                % 2-> 'Use Matlab non-compressed format'
                % 3-> 'Use Matlab compressed format'
                % 4-> 'Use Matlab non-compressed format (range 0-1)'
                saveImageOpt.dimOrder = 'yxczt';    % for 2D or saveImageOpt.dimOrder = 'yxzct'; for 3D
            end

            if obj.BatchOpt.showWaitbar; pwb = PoolWaitbar(1, 'Creating image store for prediction...', [], 'Predicting dataset', obj.View.gui); end

            % creating output directories
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            % check whether the output folder exists and whether there are
            % some files in there
            noOutputModelFiles = 0;
            noOutputScoreFiles = 0;
            if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'))
                outputList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
                noOutputModelFiles = abs(sum([outputList.isdir]-1));
            end
            if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'))
                outputList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
                noOutputScoreFiles = abs(sum([outputList.isdir]-1));
            end
            if noOutputModelFiles > 0 || noOutputScoreFiles > 0
                selection = uiconfirm(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nThe destination directories:\n- PredictionImages/ResultsModels\n- PredictionImages/ResultsScores\n\nare not empty!\n\nShell the destination folders be emptied and prediction started?'), ...
                    'Destination folders are not empty',...
                    'Icon','warning');
                if strcmp(selection, 'Cancel'); if obj.BatchOpt.showWaitbar; delete(obj.wb); end; return; end
                if noOutputModelFiles > 0
                    delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', '*'));
                end
                if noOutputScoreFiles > 0
                    delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', '*'));
                end
            end

            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));

            % prepare options for loading of images
            mibDeepStoreLoadImagesOpt.mibBioformatsCheck = obj.BatchOpt.Bioformats;
            mibDeepStoreLoadImagesOpt.BioFormatsIndices = obj.BatchOpt.BioformatsIndex{1};
            mibDeepStoreLoadImagesOpt.Workflow = obj.BatchOpt.Workflow{1};
            % make a datastore for images
            try
                if preprocessedSwitch   % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), ...
                        'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepStoreLoadImages);
                else    % without preprocessing
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]);
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                end
            catch err
                %obj.showErrorDialog(err, 'Missing files');
                mibShowErrorDialog(obj.View.gui, err, 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end

            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText('Loading network...');
            end
            % loading: 'net', 'TrainingOptStruct', 'classNames',
            % 'inputPatchSize', 'outputPatchSize', 'BatchOpt' variables
            load(obj.BatchOpt.NetworkFilename, '-mat');

            numClasses = numel(classNames); %#ok<USENS>
            if exist('classColors', 'var')
                modelMaterialColors = classColors;  %#ok<PROP> % loaded from network file
            else
                modelMaterialColors = rand([numClasses, 3]);
            end

            % correct tile overlapping strategy for the valid padding
            if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                obj.BatchOpt.P_OverlappingTiles = false;
                obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                obj.View.Figure.P_OverlappingTiles.Value = false;
            end

            %% Start prediction
            % Use the overlap-tile strategy to predict the labels for each volume.
            % Each test volume is padded to make the input size a multiple of the output size
            % of the network and compensates for the effects of valid convolution.
            % The overlap-tile algorithm selects overlapping patches, predicts the labels
            % for each patch by using the semanticseg function, and then recombines the patches.
            t1 = tic;
            noFiles = numel(imgDS.Files);
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText(sprintf('Starting prediction\nPlease wait...'));
                pwb.increaseMaxNumberOfIterations(noFiles);
            end
            id = 1;     % indices of files
            patchCount = 1; % counter of processed patches
            nDims = 2;  % number of dimensions for data, 2

            % select gpu or cpu for prediction and define executionEnvironment
            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            switch obj.View.Figure.GPUDropDown.Value
                case 'CPU only'
                    if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                        gpuDevice([]);  % CPU only mode
                    end
                    executionEnvironment = 'cpu';
                case 'Multi-GPU'
                    uialert(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nMulti-GPU mode cannot be yet used for prediction. Please select a GPU from the list and restart prediction!'), ...
                        'Not available', 'icon', 'warning');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                    return;
                    %executionEnvironment = 'multi-gpu';
                case 'Parallel'
                    executionEnvironment = 'parallel';
                otherwise
                    gpuDevice(selectedIndex);   % choose selected GPU device
                    executionEnvironment = 'gpu';
            end

            while hasdata(imgDS)
                vol = read(imgDS);  % [height, width, color] for 2D
                if size(vol, 3) ~= inputPatchSize(4)
                    % dynamically convert grayscale to RGB if needed
                    vol = repmat(vol, [1, 1, 3]);
                end

                volSize = size(vol, (1:2));
                [height, width, color] = size(vol);
                [~, fn] = fileparts(imgDS.Files{id});

                % for tiled procedure see ToDo\CoderGPU\StartPrediction2D_tiled_strategy.m
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')     % same
                    if obj.BatchOpt.P_OverlappingTiles == false
                        if height == inputPatchSize(1) && width == inputPatchSize(2)
                            [outputLabels, ~, scoreImg] = semanticseg(squeeze(vol), net, ...
                                'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment, ...
                                'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                            if generateScoreFiles > 0 && generateScoreFiles < 4
                                scoreImg = uint8(scoreImg*255);
                            end
                        else
                            % find padding size for the dataset to match
                            % input patch size
                            padSize(1) = ceil(height/inputPatchSize(1))*inputPatchSize(1) - height;
                            padSize(2) = ceil(width/inputPatchSize(2))*inputPatchSize(2) - width;
                            padSizePre = floor(padSize/2);
                            padSizePost = ceil(padSize/2);
                            volPadded = vol;
                            if sum(padSizePre)>0; volPadded = padarray(volPadded, padSizePre, 'symmetric', 'pre'); end
                            if sum(padSizePost)>0; volPadded = padarray(volPadded, padSizePost, 'symmetric', 'post'); end

                            [outputLabels, ~, scoreImg] = semanticseg(squeeze(volPadded), net, ...
                                'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment,...
                                'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1}');

                            % Remove the padding if needed
                            if sum(padSizePre)+sum(padSizePost)>0
                                outputLabels = outputLabels(padSizePre(1)+1:end-padSizePost(1), ...
                                    padSizePre(2)+1:end-padSizePost(2));
                                if generateScoreFiles > 0
                                    scoreImg = scoreImg(padSizePre(1)+1:end-padSizePost(1), ...
                                        padSizePre(2)+1:end-padSizePost(2), :);
                                    if generateScoreFiles < 4
                                        scoreImg = uint8(scoreImg*255);
                                    end
                                end
                            end

                        end
                    else        % the section below is for obj.BatchOpt.P_OverlappingTiles == true
                        % pad the image to include extended areas due to
                        % the overlapping strategy
                        if strcmp(obj.BatchOpt.Architecture{1}, 'DeepLab v3+')
                            obj.BatchOpt.T_EncoderDepth{1} = 4;
                        end

                        %padShift = (obj.BatchOpt.T_FilterSize{1}-1)*obj.BatchOpt.T_EncoderDepth{1};
                        padShift = ceil(inputPatchSize(1)*obj.BatchOpt.P_OverlappingTilesPercentage{1}/100);

                        padSize  = repmat(padShift, [1 nDims]);
                        volPadded = padarray(vol, padSize, 0, 'both');

                        % pad image to have dimensions as multiples of patchSize
                        [heightPad, widthPad, colorPad] = size(volPadded);
                        outputPatchSize = max(inputPatchSize-padShift*2, 1);  % recompute output patch size, it is smaller than input patch size

                        padSize(1) = ceil(heightPad/outputPatchSize(1))*outputPatchSize(1) + padShift*2 - heightPad;
                        padSize(2) = ceil(widthPad/outputPatchSize(2))*outputPatchSize(2) + padShift*2 - widthPad;
                        volPadded = padarray(volPadded, padSize, 0, 'post');

                        [heightPad, widthPad, colorPad] = size(volPadded);
                        outputLabels = zeros([heightPad, widthPad], 'uint8');
                        if generateScoreFiles > 0 && generateScoreFiles < 4
                            scoreImg = zeros([heightPad, widthPad, numClasses], 'uint8');
                            multiplyScoreFactor = 255;
                        elseif generateScoreFiles == 4
                            scoreImg = zeros([heightPad, widthPad, numClasses], 'single');
                            multiplyScoreFactor = 1;
                        end


                        for j = 1:outputPatchSize(2):widthPad-outputPatchSize(2)+1
                            for i = 1:outputPatchSize(1):heightPad-outputPatchSize(1)+1
                                patch = volPadded( i:i+inputPatchSize(1)-1,...
                                    j:j+inputPatchSize(2)-1, :);
                                [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, ...
                                    'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment,...
                                    'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                                x1 = i + padShift - 1;
                                y1 = j + padShift - 1;

                                outputLabels(x1:x1+outputPatchSize(1)-1, ...
                                    y1:y1+outputPatchSize(2)-1) = patchSeg(padShift:padShift+outputPatchSize(1)-1, ...
                                    padShift:padShift+outputPatchSize(2)-1);

                                if generateScoreFiles > 0
                                    scoreImg(x1:x1+outputPatchSize(1)-1, ...
                                        y1:y1+outputPatchSize(2)-1,:) = scoreBlock(padShift:padShift+outputPatchSize(1)-1, ...
                                        padShift:padShift+outputPatchSize(2)-1, ...
                                        :)*multiplyScoreFactor;
                                end
                                patchCount = patchCount + 1;
                            end
                        end

                        % Remove the padding
                        outputLabels = outputLabels(padShift+1:padShift+height, padShift+1:padShift+width);
                        if generateScoreFiles > 0
                            scoreImg = scoreImg(padShift+1:padShift+height, padShift+1:padShift+width, :);
                        end
                    end
                else    % the section below is for obj.BatchOpt.T_ConvolutionPadding{1} == 'valid'
                    padSizePre  = (inputPatchSize(1:2)-outputPatchSize(1:2))/2; %+ BatchOpt.T_EncoderDepth{1}/2;
                    padSizePost = (inputPatchSize(1:2)-outputPatchSize(1:2))/2 + (outputPatchSize(1:2)-mod(volSize, outputPatchSize(1:2)));
                    volPadded = vol;
                    volPadded = padarray(volPadded, padSizePre, 'symmetric', 'pre');
                    volPadded = padarray(volPadded, padSizePost, 'symmetric', 'post');

                    % add correction factor for padding of input images
                    encDepth = obj.BatchOpt.T_EncoderDepth{1};     % encoder depth
                    filterSize = obj.BatchOpt.T_FilterSize{1}; % filter size
                    % Amount of pixels to be excluded due to downsampling in the network
                    excludedPixels = sum(2.^(1:encDepth).*(filterSize-1));
                    % Compute the input size required to produce even sizes at the max pooling layers.
                    reqImageSize = 2^encDepth.* ceil((size(volPadded) - excludedPixels ) / 2^encDepth) + excludedPixels;
                    % Compute the additional amount of padding needed to meet the size requirements.
                    additionalPaddingPost = reqImageSize - size(volPadded);
                    % Add additional padding
                    volPadded = padarray(volPadded, additionalPaddingPost(1:2), 'symmetric', 'post');

                    [outputLabels, ~, scoreImg] = semanticseg(squeeze(volPadded), net, ...
                        'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment, ...
                        'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});

                    % Crop out the extra padded region.
                    outputLabels = outputLabels(1:volSize(1), 1:volSize(2));
                    if generateScoreFiles > 0 && generateScoreFiles < 4
                        scoreImg = uint8(scoreImg(1:volSize(1), 1:volSize(2), :)*255);
                    elseif generateScoreFiles == 4
                        scoreImg = scoreImg(1:volSize(1), 1:volSize(2), :);
                    end
                end

                % Save generated model files
                outputLabels = outputLabels - 1;    % remove the first "exterior" class

                % get filename template
                [~, fn] = fileparts(imgDS.Files{id});
                % depending on the selected output type
                switch obj.BatchOpt.P_ModelFiles{1}
                    case 'MIB Model format'
                        modelMaterialNames = classNames;
                        modelMaterialNames(1) = [];     % remove Exterior
                        modelMaterialColors = [modelMaterialColors; obj.modelMaterialColors]; %#ok<AGROW,PROP>
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.model']);
                        %rawFn = ls(fullfile(projDir, ImageSource, '01_input_images', '*.am'));
                        %amHeader = getAmiraMeshHeader(fullfile(projDir, ImageSource, '01_input_images', rawFn));
                        %BoundingBox = amHeader(find(ismember({amHeader.Name}', 'BoundingBox'))).Value;
                        modelVariable = 'outputLabels';
                        modelType = 63;
                        if exist('BoundingBox','var') == 0
                            save(filename, 'outputLabels', 'modelMaterialNames', 'modelMaterialColors', ...
                                'modelVariable', 'modelType', '-mat', '-v7.3');
                        else
                            save(filename, 'outputLabels', 'modelMaterialNames', 'modelMaterialColors', ...
                                'BoundingBox', 'modelVariable', 'modelType', '-mat', '-v7.3');
                        end
                    case 'TIF compressed format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.tif']);
                        imwrite(outputLabels, filename, 'tif', 'WriteMode', 'overwrite', 'Description', sprintf('DeepMIB segmentation: %s %s', obj.BatchOpt.Workflow{1}, obj.BatchOpt.Architecture{1}), 'Compression', 'lzw');
                    case 'TIF uncompressed format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.tif']);
                        imwrite(outputLabels, filename, 'tif', 'WriteMode', 'overwrite', 'Description', sprintf('DeepMIB segmentation: %s %s', obj.BatchOpt.Workflow{1}, obj.BatchOpt.Architecture{1}), 'Compression', 'none');
                end

                % save score map
                if generateScoreFiles > 0
                    if generateScoreFiles == 1    % 'Use AM format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.am']);
                        amiraOpt.overwrite = 1;
                        amiraOpt.showWaitbar = 0;
                        amiraOpt.verbose = false;
                        bitmap2amiraMesh(filename, scoreImg, [], amiraOpt);
                    elseif generateScoreFiles == 4   %  4=='Use Matlab non-compressed format (range 0-1)'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mat']);
                        saveImageParFor(filename, scoreImg, false, saveImageOpt);
                    else  % 2=='Use Matlab non-compressed format', 3=='Use Matlab compressed format',
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mibImg']);
                        saveImageParFor(filename, scoreImg, generateScoreFiles, saveImageOpt);
                    end
                end

                % copy original file to the results for easier evaluation
                if obj.BatchOpt.showWaitbar
                    if pwb.getCancelState(); delete(pwb); return; end
                    elapsedTime = toc(t1);
                    timerValue = elapsedTime/id*(noFiles-id);
                    pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                    pwb.increment();
                end
                id=id+1;
            end
            fprintf('Prediction finished: ');
            toc(t1)
            % count user's points
            obj.mibModel.preferences.Users.Tiers.numberOfInferencedDeepNetworks = obj.mibModel.preferences.Users.Tiers.numberOfInferencedDeepNetworks+1;
            eventdata = ToggleEventData(4);    % scale scoring by factor 5
            notify(obj.mibModel, 'updateUserScore', eventdata);

            if obj.BatchOpt.showWaitbar; delete(pwb); end
        end

        function startPrediction3D(obj)
            % function startPrediction3D(obj)
            % predict datasets for 3D networks taken to a separate function
            % to improve performance

            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Training')
                preprocessedSwitch = false;

                msg = sprintf('!!! Warning !!!\nYou are going to start prediction without preprocessing!\nConfirm that your images are located under\n\n%s\n\n%s\n%s\n\n', ...
                    obj.BatchOpt.OriginalPredictionImagesDir, ...
                    '- Images', '- Labels (optionally, when ground truth is present)');

                selection = uiconfirm(obj.View.gui, ...
                    msg, 'Preprocessing',...
                    'Options',{'Confirm', 'Cancel'},...
                    'DefaultOption', 1, 'CancelOption', 2,...
                    'Icon', 'warning');
                if strcmp(selection, 'Cancel'); return; end
            else
                preprocessedSwitch = true;
                msg = sprintf('Have images for prediction were preprocessed?\n\nIf not, please switch to the Directories and Preprocessing tab and preprocess images for prediction');
                selection = uiconfirm(obj.View.gui, ...
                    msg, 'Preprocessing',...
                    'Options',{'Yes', 'No'},...
                    'DefaultOption', 1, 'CancelOption', 2);
                if strcmp(selection, 'No'); return; end
            end

            % get settings for export of score files
            % {'Do not generate', 'Use AM format', 'Use Matlab non-compressed format', 'Use Matlab compressed format'};
            if strcmp(obj.BatchOpt.P_ScoreFiles{1}, 'Do not generate')
                generateScoreFiles = 0;
            else
                generateScoreFiles = find(ismember(obj.BatchOpt.P_ScoreFiles{2}, obj.BatchOpt.P_ScoreFiles{1}))-1;
                % 1-> 'Use AM format'
                % 2-> 'Use Matlab non-compressed format'
                % 3-> 'Use Matlab compressed format'
                % 4-> 'Use Matlab non-compressed format (range 0-1)'
                saveImageOpt.dimOrder = 'yxzct';
            end

            if obj.BatchOpt.showWaitbar; pwb = PoolWaitbar(1, 'Creating image store for prediction...', [], 'Predicting dataset', obj.View.gui); end

            % creating output directories
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            % check whether the output folder exists and whether there are
            % some files in there
            noOutputModelFiles = 0;
            noOutputScoreFiles = 0;
            if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'))
                outputList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
                noOutputModelFiles = abs(sum([outputList.isdir]-1));
            end
            if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'))
                outputList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
                noOutputScoreFiles = abs(sum([outputList.isdir]-1));
            end
            if noOutputModelFiles > 0 || noOutputScoreFiles > 0
                selection = uiconfirm(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nThe destination directories:\n- PredictionImages/ResultsModels\n- PredictionImages/ResultsScores\n\nare not empty!\n\nShell the destination folders be emptied and prediction started?'), ...
                    'Destination folders are not empty',...
                    'Icon','warning');
                if strcmp(selection, 'Cancel'); if obj.BatchOpt.showWaitbar; delete(obj.wb); end; return; end
                if noOutputModelFiles > 0
                    delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', '*'));
                end
                if noOutputScoreFiles > 0
                    delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', '*'));
                end
            end

            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));

            % prepeare options for loading of images
            mibDeepStoreLoadImagesOpt.mibBioformatsCheck = obj.BatchOpt.Bioformats;
            mibDeepStoreLoadImagesOpt.BioFormatsIndices = obj.BatchOpt.BioformatsIndex{1};
            mibDeepStoreLoadImagesOpt.Workflow = obj.BatchOpt.Workflow{1};

            % make a datastore for images
            try
                if preprocessedSwitch   % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), ...
                        'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepStoreLoadImages);
                else    % without preprocessing
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]);
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)mibDeepStoreLoadImages(fn, mibDeepStoreLoadImagesOpt));
                end
            catch err
                %obj.showErrorDialog(err, 'Missing files');
                mibShowErrorDialog(obj.View.gui, err, 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end

            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText('Loading network...');
            end
            % loading: 'net', 'TrainingOptStruct', 'classNames',
            % 'inputPatchSize', 'outputPatchSize', 'BatchOpt' variables
            load(obj.BatchOpt.NetworkFilename, '-mat');

            numClasses = numel(classNames); %#ok<USENS>
            if exist('classColors', 'var')
                modelMaterialColors = classColors;  %#ok<PROP> % loaded from network file
            else
                modelMaterialColors = rand([numClasses, 3]);
            end

            % correct tile overlapping strategy for the valid padding
            if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                obj.BatchOpt.P_OverlappingTiles = false;
                obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                obj.View.Figure.P_OverlappingTiles.Value = false;
            end

            %% Start prediction
            % Use the overlap-tile strategy to predict the labels for each volume.
            % Each test volume is padded to make the input size a multiple of the output size
            % of the network and compensates for the effects of valid convolution.
            % The overlap-tile algorithm selects overlapping patches, predicts the labels
            % for each patch by using the semanticseg function, and then recombines the patches.
            t1 = tic;
            noFiles = numel(imgDS.Files);
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText(sprintf('Starting prediction\nPlease wait...'));
            end
            id = 1;     % indices of files
            patchCount = 1; % counter of processed patches

            %% TO DO:
            % 1. check situation, when the dataset for prediction is
            % smaller that then dataset for training: 2D and 3D cases
            % 2. check different padvalue in the code below: volPadded = padarray (vol, padSize, 0, 'post');

            nDims = 3;  % number of dimensions for data, 2 or 3

            % select gpu or cpu for prediction and define executionEnvironment
            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            switch obj.View.Figure.GPUDropDown.Value
                case 'CPU only'
                    if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                        gpuDevice([]);  % CPU only mode
                    end
                    executionEnvironment = 'cpu';
                case 'Multi-GPU'
                    uialert(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nMulti-GPU mode cannot be yet used for prediction. Please select a GPU from the list and restart prediction!'), ...
                        'Not available', 'icon', 'warning');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                    return;
                    %executionEnvironment = 'multi-gpu';
                case 'Parallel'
                    executionEnvironment = 'parallel';
                otherwise
                    gpuDevice(selectedIndex);   % choose selected GPU device
                    executionEnvironment = 'gpu';
            end

            while hasdata(imgDS)
                vol = read(imgDS);
                volSize = size(vol, (1:3));
                [height, width, depth, color] = size(vol);
                [~, fn] = fileparts(imgDS.Files{id});

                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')     % same
                    if obj.BatchOpt.P_OverlappingTiles == false
                        if height == inputPatchSize(1) && width == inputPatchSize(2)  && depth == inputPatchSize(3)     % 3.5552
                            [outputLabels, ~, scoreImg] = semanticseg(squeeze(vol), net, ...
                                'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment, ...
                                'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                            if generateScoreFiles > 0 && generateScoreFiles < 4; scoreImg = uint8(scoreImg*255); end
                        else    % 5.6641 sec
                            % pad image to have dimensions as multiples of patchSize
                            % see more in
                            % \\ad.helsinki.fi\home\i\ibelev\Documents\MATLAB\Examples\R2019b\deeplearning_shared\SemanticSegOfMultispectralImagesUsingDeepLearningExample\segmentImage.m
                            padSize(1) = inputPatchSize(1) - mod(height, inputPatchSize(1));
                            padSize(2) = inputPatchSize(2) - mod(width, inputPatchSize(2));
                            padSize(3) = inputPatchSize(3) - mod(depth, inputPatchSize(3));
                            volPadded = padarray(vol, padSize, 0, 'post');

                            [heightPad, widthPad, depthPad, colorPad] = size(volPadded);

                            outputLabels = zeros([heightPad, widthPad, depthPad], 'uint8');
                            if generateScoreFiles > 1 && generateScoreFiles < 4
                                scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'uint8');
                                multipleScoreFactor = 255;
                            elseif generateScoreFiles == 4
                                scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'single');
                                multipleScoreFactor = 1;
                            end

                            if obj.BatchOpt.showWaitbar
                                if pwb.getCancelState(); delete(pwb); return; end
                                iterNo = numel(1:inputPatchSize(3):depthPad) * ...
                                    numel(1:inputPatchSize(2):widthPad) * ...
                                    numel(1:inputPatchSize(1):heightPad);
                                pwb.increaseMaxNumberOfIterations(iterNo);
                            end

                            for k = 1:inputPatchSize(3):depthPad
                                for j = 1:inputPatchSize(2):widthPad
                                    for i = 1:inputPatchSize(1):heightPad
                                        patch = volPadded( i:i+inputPatchSize(1)-1,...
                                            j:j+inputPatchSize(2)-1,...
                                            k:k+inputPatchSize(3)-1,:);
                                        [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, ...
                                            'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment, ...
                                            'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});

                                        % act0 = activations(net, squeeze(patch),'ImageInputLayer');
                                        % imtool(act0,[]);
                                        % lName = 'Encoder-Stage-1-Conv-1';
                                        % lName = 'Encoder-Stage-3-Conv-1';
                                        % act1 = activations(net, squeeze(patch),lName);
                                        % sz = size(act1);
                                        % act1 = reshape(act1,[sz(1) sz(2) 1 sz(3)]);
                                        % I = imtile(mat2gray(act1(:,:,:,1:min([size(act1, 4), 36]))),'GridSize',[6 6]);
                                        % figure(1)
                                        % imshow(I)

                                        outputLabels(i:i+outputPatchSize(1)-1, ...
                                            j:j+outputPatchSize(2)-1, ...
                                            k:k+outputPatchSize(3)-1) = patchSeg;
                                        if generateScoreFiles > 0
                                            scoreImg(i:i+outputPatchSize(1)-1, ...
                                                j:j+outputPatchSize(2)-1, ...
                                                k:k+outputPatchSize(3)-1,:) = scoreBlock*multipleScoreFactor;
                                        end
                                        if obj.BatchOpt.showWaitbar
                                            if pwb.getCancelState(); delete(pwb); return; end
                                            elapsedTime = toc(t1);
                                            if mod(patchCount, 10)
                                                timerValue = elapsedTime/patchCount*(pwb.getMaxNumberOfIterations()-patchCount);
                                                pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                                            end
                                            pwb.increment();
                                        end
                                        patchCount = patchCount + 1;
                                    end
                                end
                            end
                            % Remove the padding
                            outputLabels = outputLabels(1:height, 1:width, 1:depth);
                            if generateScoreFiles > 0; scoreImg = scoreImg(1:height, 1:width, 1:depth, :); end
                        end
                    else        % the section below is for obj.BatchOpt.P_OverlappingTiles == true
                        % pad the image to include extended areas due to the overlapping strategy
                        %padShift = (obj.BatchOpt.T_FilterSize{1}-1)*obj.BatchOpt.T_EncoderDepth{1};
                        padShift = ceil(inputPatchSize(1)*obj.BatchOpt.P_OverlappingTilesPercentage{1}/100);
                        padSize  = repmat(padShift, [1 nDims]);
                        volPadded = padarray(vol, padSize, 0, 'both');

                        % pad image to have dimensions as multiples of patchSize
                        [heightPad, widthPad, depthPad, colorPad] = size(volPadded);
                        outputPatchSize = max(inputPatchSize-padShift*2, 1);  % recompute output patch size, it is smaller than input patch size

                        padSize(1) = ceil(heightPad/outputPatchSize(1))*outputPatchSize(1) + padShift*2 - heightPad;
                        padSize(2) = ceil(widthPad/outputPatchSize(2))*outputPatchSize(2) + padShift*2 - widthPad;
                        padSize(3) = ceil(depthPad/outputPatchSize(3))*outputPatchSize(3) + padShift*2 - depthPad;
                        volPadded = padarray(volPadded, padSize, 0, 'post');

                        [heightPad, widthPad, depthPad, colorPad] = size(volPadded);
                        outputLabels = zeros([heightPad, widthPad, depthPad], 'uint8');
                        if generateScoreFiles > 0 && multipleScoreFactor < 4
                            scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'uint8');
                            multipleScoreFactor = 255;
                        elseif generateScoreFiles == 4
                            scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'single');
                            multipleScoreFactor = 1;
                        end

                        if obj.BatchOpt.showWaitbar
                            iterNo = numel(1:outputPatchSize(3):depthPad-outputPatchSize(3)+1) * ...
                                numel(1:outputPatchSize(2):widthPad-outputPatchSize(2)+1) * ...
                                numel(1:outputPatchSize(1):heightPad-outputPatchSize(1)+1);
                            pwb.increaseMaxNumberOfIterations(iterNo);
                        end

                        for k = 1:outputPatchSize(3):depthPad-outputPatchSize(3)+1
                            for j = 1:outputPatchSize(2):widthPad-outputPatchSize(2)+1
                                for i = 1:outputPatchSize(1):heightPad-outputPatchSize(1)+1
                                    %try
                                    patch = volPadded( i:i+inputPatchSize(1)-1,...
                                        j:j+inputPatchSize(2)-1,...
                                        k:k+inputPatchSize(3)-1,:);
                                    %catch err
                                    %    0
                                    %end
                                    [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, ...
                                        'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment, ...
                                        'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                                    x1 = i + padShift - 1;
                                    y1 = j + padShift - 1;
                                    z1 = min(k + padShift - 1, depthPad);

                                    outputLabels(x1:x1+outputPatchSize(1)-1, ...
                                        y1:y1+outputPatchSize(2)-1, ...
                                        z1:z1+outputPatchSize(3)-1) = patchSeg(padShift:padShift+outputPatchSize(1)-1, ...
                                        padShift:padShift+outputPatchSize(2)-1, ...
                                        padShift:padShift+outputPatchSize(3)-1);
                                    if generateScoreFiles > 0
                                        scoreImg(x1:x1+outputPatchSize(1)-1, ...
                                            y1:y1+outputPatchSize(2)-1, ...
                                            z1:z1+outputPatchSize(3)-1,:) = scoreBlock(padShift:padShift+outputPatchSize(1)-1, ...
                                            padShift:padShift+outputPatchSize(2)-1, ...
                                            padShift:padShift+outputPatchSize(3)-1,:)*multipleScoreFactor;
                                    end

                                    if obj.BatchOpt.showWaitbar
                                        if pwb.getCancelState(); delete(pwb); return; end
                                        elapsedTime = toc(t1);
                                        if mod(patchCount, 10)
                                            timerValue = elapsedTime/patchCount*(pwb.getMaxNumberOfIterations()-patchCount);
                                            pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                                        end
                                        pwb.increment();
                                    end
                                    patchCount = patchCount + 1;
                                end
                            end
                        end

                        % Remove the padding
                        outputLabels = outputLabels(padShift+1:padShift+height, padShift+1:padShift+width, padShift+1:padShift+depth);
                        if generateScoreFiles > 0
                            scoreImg = scoreImg(padShift+1:padShift+height, padShift+1:padShift+width, padShift+1:padShift+depth, :);
                        end
                    end
                else    % the section below is for obj.BatchOpt.T_ConvolutionPadding{1} == 'valid'
                    padSizePre  = (inputPatchSize(1:3)-outputPatchSize(1:3))/2;
                    padSizePost = (inputPatchSize(1:3)-outputPatchSize(1:3))/2 + (outputPatchSize(1:3)-mod(volSize,outputPatchSize(1:3)));
                    volPadded = padarray(vol, padSizePre, 'symmetric', 'pre');
                    volPadded = padarray(volPadded, padSizePost, 'symmetric', 'post');

                    [heightPad, widthPad, depthPad, colorPad] = size(volPadded);

                    outputLabels = zeros([height, width, depth], 'uint8');
                    if generateScoreFiles > 0 && generateScoreFiles < 4
                        scoreImg = zeros([height, width, depth, numClasses], 'uint8');
                        multipleScoreFactor = 255;
                    elseif generateScoreFiles == 4
                        scoreImg = zeros([height, width, depth, numClasses], 'single');
                        multipleScoreFactor = 1;
                    end

                    if obj.BatchOpt.showWaitbar
                        if pwb.getCancelState(); delete(pwb); return; end
                        iterNo = numel(1:outputPatchSize(3):depthPad-inputPatchSize(3)+1) * ...
                            numel(1:outputPatchSize(2):widthPad-inputPatchSize(2)+1) * ...
                            numel(1:outputPatchSize(1):heightPad-inputPatchSize(1)+1);
                        pwb.increaseMaxNumberOfIterations(iterNo);
                    end

                    %                     % ----- test making patches for parallel computing ----
                    %                     patchIndex = 1;
                    %                     for k = 1:outputPatchSize(3):depthPad-inputPatchSize(3)+1
                    %                         for j = 1:outputPatchSize(2):widthPad-inputPatchSize(2)+1
                    %                             for i = 1:outputPatchSize(1):heightPad-inputPatchSize(1)+1
                    %                                 patch{patchIndex} = squeeze(volPadded( i:i+inputPatchSize(1)-1,...
                    %                                     j:j+inputPatchSize(2)-1,...
                    %                                     k:k+inputPatchSize(3)-1,:));
                    %                                 patchIndex = patchIndex + 1;
                    %                             end
                    %                         end
                    %                     end
                    %
                    %                     scoreBlock = cell([patchIndex-1 1]);
                    %                     parfor (patchId = 1:patchIndex-1, 2)
                    %                         [patch{patchId}, ~, scoreBlock{patchId}] = semanticseg(patch{patchId}, net, 'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment);
                    %                     end
                    %
                    %                     patchId = 1;
                    %                     for k = 1:outputPatchSize(3):depthPad-inputPatchSize(3)+1
                    %                         for j = 1:outputPatchSize(2):widthPad-inputPatchSize(2)+1
                    %                             for i = 1:outputPatchSize(1):heightPad-inputPatchSize(1)+1
                    %                                 outputLabels(i:i+outputPatchSize(1)-1, ...
                    %                                              j:j+outputPatchSize(2)-1, ...
                    %                                              k:k+outputPatchSize(3)-1) = patch{patchId};
                    %                                 scoreImg(i:i+outputPatchSize(1)-1, ...
                    %                                          j:j+outputPatchSize(2)-1, ...
                    %                                          k:k+outputPatchSize(3)-1,:) = scoreBlock{patchId}*255;
                    %                                 patchId = patchId + 1;
                    %                             end
                    %                         end
                    %                     end
                    %                     % ------------- end of parfor procedure ------

                    % Overlap-tile strategy for segmentation of volumes.
                    for k = 1:outputPatchSize(3):depthPad-inputPatchSize(3)+1
                        for j = 1:outputPatchSize(2):widthPad-inputPatchSize(2)+1
                            for i = 1:outputPatchSize(1):heightPad-inputPatchSize(1)+1
                                patch = volPadded( i:i+inputPatchSize(1)-1,...
                                    j:j+inputPatchSize(2)-1,...
                                    k:k+inputPatchSize(3)-1,:);
                                [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, ...
                                    'OutputType', 'uint8', 'ExecutionEnvironment', executionEnvironment, ...
                                    'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});

                                outputLabels(i:i+outputPatchSize(1)-1, ...
                                    j:j+outputPatchSize(2)-1, ...
                                    k:k+outputPatchSize(3)-1) = patchSeg;
                                if generateScoreFiles > 0
                                    scoreImg(i:i+outputPatchSize(1)-1, ...
                                        j:j+outputPatchSize(2)-1, ...
                                        k:k+outputPatchSize(3)-1,:) = scoreBlock*multipleScoreFactor;
                                end
                                if obj.BatchOpt.showWaitbar
                                    if pwb.getCancelState(); delete(pwb); return; end
                                    elapsedTime = toc(t1);
                                    if mod(patchCount, 10)
                                        timerValue = elapsedTime/patchCount*(pwb.getMaxNumberOfIterations()-patchCount);
                                        pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                                    end
                                    pwb.increment();
                                end
                                patchCount = patchCount + 1;
                            end
                        end
                    end

                    % Crop out the extra padded region.
                    outputLabels = outputLabels(1:height, 1:width, 1:depth);
                    if generateScoreFiles > 1; scoreImg = scoreImg(1:height, 1:width, 1:depth, :); end
                end
                if obj.BatchOpt.showWaitbar; pwb.updateText('Saving results...'); end

                % Save results
                outputLabels = outputLabels - 1;    % remove the first "exterior" class
                % get filename template
                [~, fn] = fileparts(imgDS.Files{id});

                % depending on the selected output type
                switch obj.BatchOpt.P_ModelFiles{1}
                    case 'MIB Model format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.model']);

                        %modelMaterialNames = {classNames{2:end}}';
                        modelMaterialNames = classNames;
                        modelMaterialNames(1) = [];
                        modelMaterialColors = [modelMaterialColors; obj.modelMaterialColors]; %#ok<AGROW,PROP>

                        %rawFn = ls(fullfile(projDir, ImageSource, '01_input_images', '*.am'));
                        %amHeader = getAmiraMeshHeader(fullfile(projDir, ImageSource, '01_input_images', rawFn));
                        %BoundingBox = amHeader(find(ismember({amHeader.Name}', 'BoundingBox'))).Value;
                        modelVariable = 'outputLabels';
                        modelType = 63;
                        if exist('BoundingBox','var') == 0
                            save(filename, 'outputLabels', 'modelMaterialNames', 'modelMaterialColors', ...
                                'modelVariable', 'modelType', '-mat', '-v7.3');
                        else
                            save(filename, 'outputLabels', 'modelMaterialNames', 'modelMaterialColors', ...
                                'BoundingBox', 'modelVariable', 'modelType', '-mat', '-v7.3');
                        end
                    case {'TIF compressed format', 'TIF uncompressed format'}
                        if strcmp(obj.BatchOpt.P_ModelFiles{1}, 'TIF compressed format')
                            tifCompression = 'lzw';
                        else
                            tifCompression = 'none';
                        end
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.tif']);
                        imwrite(outputLabels(:,:,1), filename, 'tif', 'WriteMode', 'overwrite', 'Description', sprintf('DeepMIB segmentation: %s %s', obj.BatchOpt.Workflow{1}, obj.BatchOpt.Architecture{1}), 'Compression', tifCompression);
                        for sliceId = 2:size(outputLabels, 3)
                            imwrite(outputLabels(:,:,sliceId), filename, 'tif', 'WriteMode', 'append', 'Compression', tifCompression);
                        end
                end

                % check for cancel
                if obj.BatchOpt.showWaitbar && pwb.getCancelState(); delete(pwb); return; end

                % save score map
                if generateScoreFiles > 0
                    if generateScoreFiles == 1    % 'Use AM format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.am']);
                        %scoreImg = uint8(scoreImg*255);     % convert to 8bit and scale between 0-255
                        scoreImg = permute(scoreImg, [1 2 4 3]);    % convert to [height, width, color, depth]

                        amiraOpt.overwrite = 1;
                        amiraOpt.showWaitbar = 0;
                        amiraOpt.verbose = false;
                        bitmap2amiraMesh(filename, scoreImg, [], amiraOpt);
                    elseif generateScoreFiles == 4   %  4=='Use Matlab non-compressed format (range 0-1)'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mat']);
                        saveImageParFor(filename, scoreImg, false, saveImageOpt);
                    else    % 2=='Use Matlab non-compressed format', 3=='Use Matlab compressed format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mibImg']);
                        saveImageParFor(filename, scoreImg, generateScoreFiles-2, saveImageOpt);
                    end
                end

                % copy original file to the results for easier evaluation
                %copyfile(fullfile(projDir, ImageSource, '01_input_images', rawFn), outputDir);
                if obj.BatchOpt.showWaitbar
                    if obj.BatchOpt.showWaitbar && pwb.getCancelState(); delete(pwb); return; end
                    elapsedTime = toc(t1);
                    timerValue = elapsedTime/id*(noFiles-id);
                    pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                    pwb.increment();
                end
                id=id+1;
            end
            fprintf('Prediction finished: ');
            toc(t1)
            % count user's points
            obj.mibModel.preferences.Users.Tiers.numberOfInferencedDeepNetworks = obj.mibModel.preferences.Users.Tiers.numberOfInferencedDeepNetworks+1;
            eventdata = ToggleEventData(4);    % scale scoring by factor 5
            notify(obj.mibModel, 'updateUserScore', eventdata);

            if obj.BatchOpt.showWaitbar; delete(pwb); end
        end

        function bls = generateDynamicMaskingBlocks(obj, vol, blockSize, noColors)
            % function bls = generateDynamicMaskingBlocks(obj, vol, blockSize, noColors)
            % generate blocks using dynamic masking parameters acquired in obj.DynamicMaskOpt
            %
            % Parameters:
            % vol:  blocked image to process
            % blockSize: block size
            % noColors: number of color channels in the blocked image
            %
            % Return values:
            % bls: calculated  blockLocationSet
            %    .ImageNumber
            %    .BlockOrigin
            %    .BlockSize
            %    .Levels

            % generate the mask
            switch obj.DynamicMaskOpt.Method
                case 'Keep above threshold'
                    if noColors == 1
                        bmask = apply(vol, @(bs) bs.Data > obj.DynamicMaskOpt.ThresholdValue, "Level", 1);
                    elseif noColors == 3
                        bmask = apply(vol, @(bs)rgb2gray(bs.Data) > obj.DynamicMaskOpt.ThresholdValue, "Level", 1);
                    else
                        bmask = apply(vol, @(bs)max(bs.Data, [], 3) > obj.DynamicMaskOpt.ThresholdValue, "Level", 1);
                    end
                case 'Keep below threshold'
                    if noColors == 1
                        bmask = apply(vol, @(bs) bs.Data < obj.DynamicMaskOpt.ThresholdValue, "Level", 1);
                    elseif noColors == 3
                        bmask = apply(vol, @(bs)rgb2gray(bs.Data) < obj.DynamicMaskOpt.ThresholdValue, "Level", 1);
                    else
                        bmask = apply(vol, @(bs)max(bs.Data, [], 3) < obj.DynamicMaskOpt.ThresholdValue, "Level", 1);
                    end
            end

            % calculate block locations
            bls = selectBlockLocations(vol, 'Mask', bmask, "InclusionThreshold", obj.DynamicMaskOpt.InclusionThreshold, ...
                'Levels', 1, 'BlockSize', blockSize);
            %                             % % preview
            %                             figure(1); bigimageshow(bmask);
            %                             blockedWH = fliplr(bls.BlockSize(1,1:2));
            %                             for ind = 1:size(bls.BlockOrigin,1)
            %                                 % BlockOrigin is already in x,y order.
            %                                 drawrectangle('Position', [bls.BlockOrigin(ind,1:2),blockedWH]);
            %                             end
        end

        function previewPredictions(obj)
            % function previewPredictions(obj)
            % load images of prediction scores into MIB

            scoreDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores');

            switch obj.BatchOpt.P_ScoreFiles{1}
                case 'Use AM format'
                    fnList = dir(fullfile(scoreDir, '*.am'));
                case {'Use Matlab non-compressed format', 'Use Matlab compressed format'}
                    fnList = dir(fullfile(scoreDir, '*.mibImg'));
                otherwise
                    fnList = [];
            end

            if isempty(fnList)
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nNo files with predictions were found in\n%s\n\nPlease update the Directory with resulting images field of the Directories and Preprocessing tab!', scoreDir), ...
                    'Missing files', 'Icon', 'error');
                return;
            end
            if strcmp(obj.BatchOpt.Workflow{1}(1:2), '3D')  % take only the first file for 3D case
                BatchOptIn.Filenames = {{fullfile(scoreDir, fnList(1).name)}};
            else
                BatchOptIn.Filenames = {arrayfun(@(filename) fullfile(scoreDir, cell2mat(filename)), {fnList.name}, 'UniformOutput', false)};  % generate full paths
            end
            BatchOptIn.UseBioFormats = false;
            obj.mibController.mibFilesListbox_cm_Callback([], BatchOptIn);
        end

        function previewModels(obj, loadImagesSwitch)
            % function previewModels(obj, loadImagesSwitch)
            % load images for predictions and the resulting modelsinto MIB
            %
            % Parameters:
            % loadImagesSwitch: [logical], load or not (assuming that
            % images have already been preloaded) images. When true, both
            % images and models are loaded, when false - only models are
            % loaded

            imgDir = 0;
            if loadImagesSwitch
                imagesSubfolder = 'Images';
                if ~isfolder(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'))
                    res = uiconfirm(obj.View.gui, ...
                        sprintf(['It is recommended to keep images for prediction under "Images" subfolder within the directory specified in \n\n' ...
                        '"Directories and Preprocessing" -> \n\t\t\t"Directory with images for prediction"\n\n' ...
                        'However "Images" subfolder was not found!\n\nWould you like to continue and load images that are located under:\n' ...
                        '%s'], obj.BatchOpt.OriginalPredictionImagesDir), ...
                        'Missing Images subfolder', ...
                        'Options', {'Load images for prediction','Cancel'}, ...
                        'Icon', 'warning');
                    if strcmp(res, 'Cancel');  if obj.BatchOpt.showWaitbar; delete(obj.wb); end; return; end
                    imagesSubfolder = [];
                end

                imgDir = fullfile(obj.BatchOpt.OriginalPredictionImagesDir, imagesSubfolder);
                imgList = dir(fullfile(imgDir, ['*.' lower(obj.BatchOpt.ImageFilenameExtension{1})]));
            else
                imgList = 0; % init with a number
            end
            modelDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels');
            switch obj.BatchOpt.P_ModelFiles{1}
                case 'MIB Model format'
                    modelFileExtension = '*.model';
                case {'TIF compressed format', 'TIF uncompressed format'}
                    modelFileExtension = '*.tif';
            end
            modelList = dir(fullfile(modelDir, lower(modelFileExtension)));

            if isempty(imgList) || isempty(modelList)
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nFiles were not found in\n%s\n[--> %d file(s)]\n\n%s\n[--> %d file(s)]\n\n- Update the Directory prediction and resulting images fields of the Directories and Preprocessing tab\n- Make sure that the model type is properly choosen under "Predict->Model files"', imgDir, numel(imgList), modelDir, numel(modelList)), ...
                    'Missing files', 'Icon', 'error');
                return;
            end

            if strcmp(obj.BatchOpt.Workflow{1}(1:2), '3D')  % take only the first file for 3D case
                if loadImagesSwitch
                    BatchOptIn1.Filenames = {{fullfile(imgDir, imgList(1).name)}};
                end
                BatchOptIn2.DirectoryName = {modelDir};
                BatchOptIn2.FilenameFilter = modelList(1).name;
            else
                if loadImagesSwitch
                    BatchOptIn1.Filenames = {arrayfun(@(filename) fullfile(imgDir, cell2mat(filename)), {imgList.name}, 'UniformOutput', false)};  % generate full paths
                end
                BatchOptIn2.DirectoryName = {modelDir};
                BatchOptIn2.FilenameFilter = modelFileExtension;
            end

            if loadImagesSwitch % load images
                BatchOptIn1.UseBioFormats = obj.BatchOpt.Bioformats;
                BatchOptIn1.BioFormatsIndices = num2str(obj.BatchOpt.BioformatsIndex{1});
                BatchOptIn1.verbose = false;    % do not display loading files into the main command window
                obj.mibModel.myPath = imgDir;
                obj.mibController.mibFilesListbox_cm_Callback([], BatchOptIn1);     % load images
            end
            obj.mibModel.loadModel([], BatchOptIn2);  % load models
        end

        function evaluateSegmentationPatches(obj)
            % function evaluateSegmentationPatches(obj)
            % evaluate segmentation results for the patches in the
            % patch-wise mode

            filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'patchPredictionResults.mat');
            load(filename, 'patchWiseOutout', '-mat');

            C = confusionmat(patchWiseOutout.RealClass, patchWiseOutout.PredictedClass);
            figure(randi(1000))
            confusionchart(C, strsplit(patchWiseOutout.ClassNames{1}, ', '));
            [~, fn, ext] = fileparts(obj.BatchOpt.NetworkFilename);
            title(sprintf('%s %s, %s', obj.BatchOpt.Workflow{1}, obj.BatchOpt.Architecture{1}, [fn, ext]));
        end

        function evaluateSegmentation(obj)
            % function evaluateSegmentation(obj)
            % evaluate segmentation results by comparing predicted models
            % with the ground truth models
            global mibPath;

            % check for evaluation of patches in the patch-wise mode
            if exist(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'patchPredictionResults.mat'), 'file') == 2
                obj.evaluateSegmentationPatches();
                return;
            end

            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation') || ...
                    strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Training')
                preprocessedSwitch = false;
                truthDir = fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Labels');
                truthList = dir(fullfile(truthDir, lower(['*.' obj.BatchOpt.ModelFilenameExtension{1}])));
            else
                preprocessedSwitch = true;
                truthDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels');
                truthList = dir(fullfile(truthDir, '*.mibCat'));
            end

            predictionDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels');
            switch obj.BatchOpt.P_ModelFiles{1}
                case 'MIB Model format'
                    modelFileExtension = '*.model';
                case {'TIF compressed format', 'TIF uncompressed format'}
                    modelFileExtension = '*.tif';
            end
            predictionList = dir(fullfile(predictionDir, lower(modelFileExtension)));

            if isempty(truthList) && isempty(predictionList)
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nModels were not found in\n%s\n\n%s\n\nPlease update the Directory prediction and resulting images fields of the Directories and Preprocessing tab!', truthDir, predictionDir), ...
                    'Missing files');
                return;
            end

            prompts = { 'Accuracy: the percentage of correctly identified pixels for each class';...
                'bfscore: the boundary F1 (BF) contour matching score indicates how well the predicted boundary of each class aligns with the true boundary';...
                'Global Accuracy: the ratio of correctly classified pixels, regardless of class, to the total number of pixels'; ...
                'IOU (Jaccard similarity coefficient): Intersection over union, a statistical accuracy measurement that penalizes false positives'; ...
                'Weighted IOU: average IoU of each class, weighted by the number of pixels in that class';
                };
            defAns = {obj.mibModel.preferences.Deep.Metrics.Accuracy; ...
                obj.mibModel.preferences.Deep.Metrics.BFscore; ...
                obj.mibModel.preferences.Deep.Metrics.GlobalAccuracy; ...
                obj.mibModel.preferences.Deep.Metrics.IOU; ...
                obj.mibModel.preferences.Deep.Metrics.WeightedIOU; ...
                };

            dlgTitle = 'Evaluation settings';
            options.Title = sprintf('Please select the metrics from the options below\nKeep in mind that the evaluation processs in rather slow\nRatio of execution times for each metric: 0.10 x 0.78 x 0.04 x 0.03 x 0.05');
            options.WindowStyle = 'normal';
            options.PromptLines = [1, 1, 1, 1, 1];
            options.WindowWidth = 2.45;
            options.TitleLines = 3;
            options.HelpUrl = 'https://se.mathworks.com/help/vision/ref/evaluatesemanticsegmentation.html';

            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            obj.mibModel.preferences.Deep.Metrics.Accuracy = logical(answer{1});
            obj.mibModel.preferences.Deep.Metrics.BFscore = logical(answer{2});
            obj.mibModel.preferences.Deep.Metrics.GlobalAccuracy = logical(answer{3});
            obj.mibModel.preferences.Deep.Metrics.IOU = logical(answer{4});
            obj.mibModel.preferences.Deep.Metrics.WeightedIOU = logical(answer{5});

            metricsList = {};
            if obj.mibModel.preferences.Deep.Metrics.Accuracy;          metricsList = [metricsList, {'accuracy'}]; end
            if obj.mibModel.preferences.Deep.Metrics.BFscore;           metricsList = [metricsList, {'bfscore'}]; end
            if obj.mibModel.preferences.Deep.Metrics.GlobalAccuracy;    metricsList = [metricsList, {'global-accuracy'}]; end
            if obj.mibModel.preferences.Deep.Metrics.IOU;               metricsList = [metricsList, {'iou'}]; end
            if obj.mibModel.preferences.Deep.Metrics.WeightedIOU;       metricsList = [metricsList, {'weighted-iou'}]; end
            if isempty(metricsList); return; end

            % get class names
            switch obj.BatchOpt.P_ModelFiles{1}
                case 'MIB Model format'
                    modelFn = fullfile(predictionList(1).folder, predictionList(1).name);
                    res = load(modelFn, '-mat', 'modelMaterialNames');
                    classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                case {'TIF compressed format', 'TIF uncompressed format'}
                    if preprocessedSwitch   % for tifs get the class names from the preprocessed file
                        res = load(fullfile(truthDir, truthList(1).name), '-mat', 'options');
                        classNames = res.options.modelMaterialNames;
                    else % if it is not available, try to get from model file or generate fake names
                        switch obj.BatchOpt.ModelFilenameExtension{1}
                            case 'MODEL'
                                res = load(fullfile(truthDir, truthList(1).name), '-mat', 'modelMaterialNames');
                                classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                            otherwise
                                % material names not present generate fake ones
                                classNames = arrayfun(@(x) sprintf('Class%.2d', x), 1:obj.BatchOpt.T_NumberOfClasses{1}-1, 'UniformOutput', false);
                                classNames = [{'Exterior'}; classNames'];
                        end
                    end
            end
            if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise') % patch-wise mode
                classNames(ismember(classNames, 'Exterior')) = [];
                pixelLabelID = 1:numel(classNames);
            else
                pixelLabelID = 0:numel(classNames)-1;
            end

            try
                fullPathFilenames = arrayfun(@(filename) fullfile(truthDir, cell2mat(filename)), {truthList.name}, 'UniformOutput', false);  % generate full paths
                if preprocessedSwitch
                    dsTruth = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                        'FileExtensions', '.mibCat', 'ReadFcn', @mibDeepStoreLoadImages);
                else
                    switch obj.BatchOpt.ModelFilenameExtension{1}
                        case 'MODEL'
                            dsTruth = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                                'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
                            % I = readimage(dsTruth,1);  % read model test
                            % reset(dsTruth);
                        otherwise
                            dsTruth = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                                'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                    end
                end
            catch err
                optionalSuffix = sprintf('Check the ground truth directory:\n%s', truthDir);
                mibShowErrorDialog(obj.View.gui, err, 'Wrong class name', '', optionalSuffix);
                %obj.showErrorDialog(err, 'Wrong class name', '', optionalSuffix);
                return;
            end

            fullPathFilenames = arrayfun(@(filename) fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', cell2mat(filename)), {predictionList.name}, 'UniformOutput', false);  % generate full paths
            switch obj.BatchOpt.P_ModelFiles{1}
                case 'MIB Model format'
                    dsResults = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                        'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
                case {'TIF compressed format', 'TIF uncompressed format'}
                    if strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D')
                        dsResults = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                            'FileExtensions', '.tif');
                    else
                        % for 3D tif have to use a separate reading function
                        dsResults = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                            'FileExtensions', '.tif', 'ReadFcn', @mibDeepController.tif3DFileRead);
                    end
            end

            tic
            pw = PoolWaitbar(2, sprintf('Starting evaluation\nit may take a while...'), [], 'Evaluate segmentation');
            try
                ssm = evaluateSemanticSegmentation(dsResults, dsTruth, 'Metrics', metricsList);
            catch err
                optionalSuffix = 'Most likely the class names in the GroundTruth do not match the class names of the model\nor alternatively, the ground truth model is in a single .MODEL file (preprecess the dataset in this case)';
                mibShowErrorDialog(obj.View.gui, err, 'Wrong class names', '', optionalSuffix);
                %obj.showErrorDialog(err, 'Wrong class names', '', optionalSuffix);
            end
            pw.increment();

            % convert ssm object to standard structure
            ssmFields = fieldnames(ssm);
            ssmStruct = struct();
            % add additional info to ssmStruct
            ssmStruct.Info.NetworkName = obj.BatchOpt.NetworkFilename;
            ssmStruct.Info.PredictionResultsDirectory = predictionDir;
            ssmStruct.Info.GroundTruthDirectory = truthDir;
            % crate a table with name of files
            fnTable = table({predictionList.name}', {truthList.name}', 'VariableNames', {'ModelFilename', 'GroundTruthFilename'});
            % add calculated fields
            for i=1:numel(ssmFields)
                ssmStruct.(ssmFields{i}) = ssm.(ssmFields{i});
            end
            % insert filenames into ssmStruct.ImageMetrics
            ssmStruct.ImageMetrics = [fnTable ssmStruct.ImageMetrics];
            pw.increment();
            pw.deletePoolWaitbar();
            toc

            normConfMatData = ssm.NormalizedConfusionMatrix.Variables;
            hF = figure;
            screenSize = get (0,'screensize');
            hF.Position(2) = screenSize(4)*.1;
            hF.Position(4) = screenSize(4)*.7;
            hF.Position(3) = hF.Position(4)*0.9;
            clf
            h = heatmap(classNames,classNames,100*normConfMatData, 'Position', [.15 .45 .7 .48]);
            h.XLabel = 'Predicted Class';
            h.YLabel = 'True Class';
            [~, netName] = fileparts(obj.BatchOpt.NetworkFilename);
            h.Title = sprintf('Normalized Confusion Matrix\n(%s)', strrep(netName, '_', '-'));
            if max(ismember({'Accuracy','IoU','MeanBFScore'}, ssm.ClassMetrics.Properties.VariableNames))
                %h2 = heatmap(ssm.ClassMetrics.Properties.RowNames, {'IoU'}, ssm.ClassMetrics.IoU', 'Position', [.15 .02 .7 .15]);
                h2 = heatmap(ssm.ClassMetrics.Properties.RowNames, ssm.ClassMetrics.Properties.VariableNames, table2array(ssm.ClassMetrics)', ...
                    'Position', [.15 .16 .7 .18]);
                h2.Title = 'Class metrics';
            end
            if numel(ssm.DataSetMetrics.Properties.VariableNames) > 0
                h3 = heatmap(ssm.DataSetMetrics.Properties.VariableNames, {'Dataset'}, table2array(ssm.DataSetMetrics), ...
                    'Position', [.15 .07 .7 .045]);
            end

            % display results
            metricName = ssm.DataSetMetrics.Properties.VariableNames;
            metricValue = table2array(ssm.DataSetMetrics);

            s = sprintf('Evaluation results\nfor details press the Help button and follow to the Metrics section\n\n');
            s = sprintf('%sGlobalAccuracy: ratio of correctly classified pixels to total pixels, regardless of class\n', s);
            s = sprintf('%sMeanAccuracy: ratio of correctly classified pixels to total pixels, averaged over all classes in the image\n', s);
            s = sprintf('%sMeanIoU: (Jaccard similarity coefficient) average intersection over union (IoU) of all classes in the image\n', s);
            s = sprintf('%sWeightedIoU: average IoU of all classes in the image, weighted by the number of pixels in each class\n', s);
            s = sprintf('%sMeanBFScore: average boundary F1 (BF) score of each class in the image\n\n', s);

            for i=1:numel(metricName)
                s = sprintf('%s%s: %f            ', s, metricName{i}, metricValue(:,i));
                if mod(i,2) == 0; s = sprintf('%s\n', s); end
            end

            if ismember('IoU', ssm.ClassMetrics.Properties.VariableNames)
                s = sprintf('%s\nIoU (Jaccard) metric for each class:\n', s);
                for i=1:numel(ssm.ClassMetrics.Properties.RowNames)
                    s = sprintf('%s%s:               %f\n', s, ssm.ClassMetrics.Properties.RowNames{i}, ssm.ClassMetrics.IoU(i));
                end
            end
            options.Title = s;
            options.TitleLines = numel(strfind(s, sprintf('\n'))); %#ok<SPRINTFN>
            options.HelpUrl = 'https://se.mathworks.com/help/vision/ref/evaluatesemanticsegmentation.html';
            options.WindowWidth = 2.0;
            options.PromptLines = [1, 1, 1, 1, 3, 1, 1, 1];
            prompts = {'Export to Matlab'; 'Save as Matlab file'; 'Save as Excel file'; 'Save as CSV file';...
                'Calculate occurrence of labels in ground truth and resulting images and Sørensen-Dice similarity (takes extra time)';...
                ''; ''; '';};
            defAns = {false; false; false; false; ...
                {'Do not calculate', 'Calculate occurrence', 'Calculate Sørensen-Dice similarity', 'Calculate everything', 1}; ...
                NaN; NaN; NaN; };
            options.Columns = 2;
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Evaluation results', options);
            if isempty(answer); return; end


            if ~strcmp(answer{5}, 'Do not calculate')
                calcOccurrenceSwitch = 0;
                calcSorensenSwitch = 0;
                if strcmp(answer{5}, 'Calculate occurrence') || strcmp(answer{5}, 'Calculate everything'); calcOccurrenceSwitch = 1; end
                if strcmp(answer{5}, 'Calculate Sørensen-Dice similarity') || strcmp(answer{5}, 'Calculate everything'); calcSorensenSwitch = 1; end

                % define usage of parallel computing
                if obj.BatchOpt.UseParallelComputing
                    parforArg = obj.View.handles.PreprocessingParForWorkers.Value;    % Maximum number of workers running in parallel
                    TitleTest = 'Evaluate segmentation (parallel)';
                    if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
                else
                    parforArg = 0;      % Maximum number of workers running in parallel
                    TitleTest = 'Evaluate segmentation (single)';
                end
                % reset datastores
                dsTruth.reset();
                dsResults.reset();

                % make waitbar
                pw = PoolWaitbar(numel(dsTruth.Files), sprintf('Starting evaluation\nit may take a while...'), [], TitleTest);
                pw.setIncrement(10);
                occurrenceGT = [];
                occurrenceRes = [];
                similarity = [];

                if calcOccurrenceSwitch
                    occurrenceGT = cell([numel(dsTruth.Files), 1]);
                    occurrenceRes = cell([numel(dsTruth.Files), 1]);
                end
                if calcSorensenSwitch
                    similarity = zeros([numel(dsTruth.Files), numel(ssm.ClassMetrics.Properties.RowNames)]);     % allocate space
                end

                parfor (fileId=1:numel(dsTruth.Files), parforArg)
                    %for fileId = 1:numel(dsTruth.Files)
                    gtImg = readimage(dsTruth, fileId);
                    resImg = readimage(dsResults, fileId);
                    if calcSorensenSwitch
                        similarity(fileId, :) = dice(resImg, gtImg);   % returns vector of values for each class
                    end

                    if calcOccurrenceSwitch
                        catList = categories(gtImg(:));
                        catCounts = countcats(gtImg(:));
                        occurrenceGT{fileId}(ismember(classNames, catList)) = catCounts;
                        catList = categories(resImg(:));
                        catCounts = countcats(resImg(:));
                        occurrenceRes{fileId}(ismember(classNames, catList)) = catCounts;
                    end

                    if mod(fileId, 10) == 1; increment(pw); end     % update waitbar
                end

                % populate ssmStruct with new metric
                if calcSorensenSwitch
                    for classId = 1:numel(classNames)
                        ssmStruct.ImageMetrics.(['Dice_' ssm.ClassMetrics.Properties.RowNames{classId}]) = similarity(:,classId);
                    end
                end
                if calcOccurrenceSwitch
                    occurrenceGT = cell2mat(occurrenceGT);
                    occurrenceRes = cell2mat(occurrenceRes);

                    for classId = 1:numel(classNames)
                        %ssmStruct.ImageMetrics.(['GT_' ssm.ClassMetrics.Properties.RowNames{classId}]) = occurrenceGT(:,classId);
                        ssmStruct.ImageMetrics.(['GT_' classNames{classId}]) = occurrenceGT(:,classId);
                    end
                    for classId = 1:numel(classNames)
                        ssmStruct.ImageMetrics.(['Model_' ssm.ClassMetrics.Properties.RowNames{classId}]) = occurrenceRes(:,classId);
                    end
                end

                pw.deletePoolWaitbar();
            end

            % make output directories
            outputPath = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages');
            if exist(outputPath, 'dir') == false; mkdir(outputPath); end
            outputPath = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels');
            if exist(outputPath, 'dir') == false; mkdir(outputPath); end

            if answer{1}    % export to Matlab
                assignin('base', 'ssm', ssmStruct);
                fprintf('A variable "ssm" was created in Matlab\n');
            end
            if answer{2}    % save in Matlab format
                fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationResults.mat');
                save(fn, 'ssmStruct', '-v7.3');
                fprintf('Evaluation results were saved to:\n%s\n', fn);
            end
            if answer{3}    % save in Excel format
                wbar = uiprogressdlg(obj.View.gui, 'Message', sprintf('Saving to Excel\nPlease wait...'), ...
                    'Title', 'Export');

                clear excelHeader;
                fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationResults.xls');
                if exist(fn, 'file') == 2; delete(fn); end
                excelHeader{1} = sprintf('Evaluation metrics for %s', obj.BatchOpt.NetworkFilename);

                try
                    writecell(excelHeader, fn, 'FileType', 'spreadsheet', 'Sheet', 'ClassMetrics', 'Range', 'A1');
                    writetable(ssm.ClassMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'ClassMetrics', 'WriteRowNames', true, 'Range', 'A3');
                catch err
                    uialert(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nThe destination Excel file can not be overwritten!\nIt may be open elsewhere...\n\n%s', fn), ...
                        'Excel file overwrite');
                    delete(wbar);
                    return;
                end
                wbar.Value = 0.2;
                excelHeader{2,1} = 'Prediction results directory:';  excelHeader{2,2} = predictionDir;
                excelHeader{3,1} = 'Ground truth directory:';excelHeader{3,2} = truthDir;
                writecell(excelHeader, fn, 'FileType', 'spreadsheet', 'Sheet', 'ImageMetrics', 'Range', 'A1');
                writetable(ssmStruct.ImageMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'ImageMetrics', 'WriteRowNames', true, 'Range', 'A5');

                wbar.Value = 0.4;
                writecell(excelHeader(1), fn, 'FileType', 'spreadsheet', 'Sheet', 'DataSetMetrics', 'Range', 'A1');
                writetable(ssm.DataSetMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'DataSetMetrics', 'WriteRowNames', true, 'Range', 'A3');
                wbar.Value = 0.6;
                writecell(excelHeader(1), fn, 'FileType', 'spreadsheet', 'Sheet', 'ConfusionMatrix', 'Range', 'A1');
                writetable(ssm.ConfusionMatrix, fn, 'FileType', 'spreadsheet', 'Sheet', 'ConfusionMatrix', 'WriteRowNames', true, 'Range', 'A3');
                wbar.Value = 0.8;
                writecell(excelHeader(1), fn, 'FileType', 'spreadsheet', 'Sheet', 'NormalizedConfusionMatrix', 'Range', 'A1');
                writetable(ssm.NormalizedConfusionMatrix, fn, 'FileType', 'spreadsheet', 'Sheet', 'NormalizedConfusionMatrix', 'WriteRowNames', true, 'Range', 'A3');

                wbar.Value = 1;
                fprintf('Evaluation results were saved to:\n%s\n', fn);
                delete(wbar);
            end

            if answer{4}    % save in CSV format
                wbar = uiprogressdlg(obj.View.gui, 'Message', sprintf('Saving to CSV format\nPlease wait...'), ...
                    'Title', 'Export');
                fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationClassMetrics.csv');
                if exist(fn, 'file') == 2; delete(fn); end
                try
                    writetable(ssm.ClassMetrics, fn, 'FileType', 'text', 'WriteRowNames', true);

                    wbar.Value = 0.2;
                    fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationImageMetrics.csv');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(ssmStruct.ImageMetrics, fn, 'FileType', 'text', 'WriteRowNames', true);

                    wbar.Value = 0.4;
                    fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationDataSetMetrics.csv');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(ssm.DataSetMetrics, fn, 'FileType', 'text', 'WriteRowNames', true);

                    wbar.Value = 0.6;
                    fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationConfusionMatrix.csv');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(ssm.ConfusionMatrix, fn, 'FileType', 'text', 'WriteRowNames', true);

                    wbar.Value = 0.8;
                    fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationNormalizedConfusionMatrix.csv');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(ssm.NormalizedConfusionMatrix, fn, 'FileType', 'text', 'WriteRowNames', true);

                catch err
                    uialert(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nThe destination CSV file can not be overwritten!\nIt may be open elsewhere...\n\n%s', fn), ...
                        'Excel file overwrite');
                    delete(wbar);
                    return;
                end
                wbar.Value = 1;
                fprintf('Evaluation results were saved to:\n%s\n', fn);
                delete(wbar);
            end
        end

        function selectGPUDevice(obj)
            % function selectGPUDevice(obj)
            % select environment for computations
            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            if ismember(obj.View.Figure.GPUDropDown.Value, {'CPU only', 'Multi-GPU', 'Parallel'})
                if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                    gpuDevice([]);  % CPU only mode
                end
            else
                g = gpuDevice(selectedIndex);   % choose selected GPU device
                reset(g);
            end
        end

        function gpuInfo(obj)
            % function gpuInfo(obj)
            % display information about the selected GPU

            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            switch obj.View.Figure.GPUDropDown.Value
                case 'CPU only'
                    msg = sprintf('Use only a single CPU for training or prediction');
                case 'Multi-GPU'
                    msg = sprintf('Use multiple GPUs on one machine, using a local parallel pool based on your default cluster profile.\nIf there is no current parallel pool, the software starts a parallel pool with pool size equal to the number of available GPUs.\nThis option is only shown when multiple GPUs are present on the system');
                case 'Parallel'
                    msg = sprintf('Use a local or remote parallel pool based on your default cluster profile.\nIf there is no current parallel pool, the software starts one using the default cluster profile.\nIf the pool has access to GPUs, then only workers with a unique GPU perform training computation.\nIf the pool does not have GPUs, then training takes place on all available CPU workers instead');
                otherwise
                    D = gpuDevice(selectedIndex);   % choose selected GPU device
                    fNames = fieldnames(D);
                    msg = '';
                    for fId = 1:numel(fNames)
                        switch class(D.(fNames{fId}))
                            case 'datetime'
                                msg = sprintf('%s%s:\t\t%s\n', msg, fNames{fId}, D.(fNames{fId}));
                            otherwise
                                msg = sprintf('%s%s:\t\t%s\n', msg, fNames{fId}, num2str(D.(fNames{fId})));
                        end
                    end
            end

            obj.gpuInfoFig = uifigure('Name', 'GPU Info');
            hGrid = uigridlayout(obj.gpuInfoFig, [3, 1], 'RowHeight', {'1x', '12x', '1x'});
            hl = uilabel(hGrid, 'Text', sprintf('Properties of %s', obj.View.Figure.GPUDropDown.Value));
            h2 = uipanel(hGrid);
            h3 = uibutton(hGrid, 'push', 'Text', 'Close window', 'ButtonPushedFcn', 'closereq');

            hGridMiddle = uigridlayout(h2, [1, 1], 'RowHeight', {'1x'});
            h2b = uitextarea(hGridMiddle, 'Value', msg, ...
                'Editable', false);
        end

        function exportNetwork(obj)
            % function exportNetwork(obj)
            % convert and export network to ONNX or TensorFlow formats
            global mibPath;

            if exist(obj.BatchOpt.NetworkFilename, 'file') ~= 2
                uialert(obj.View.gui, sprintf('!!! Error !!!\n\nThe network file:\n%s\ncan not be found!', obj.BatchOpt.NetworkFilename), 'Missing file');
                return;
            end

            prompts = {'Output format'; 'Alter the final segmentation layer as'; 'Version of ONNX operator set'};
            defAns = {{'ONNX', 'TensorFlow', 1};{'Keep as it is', 'Remove the layer', 'pixelClassificationLayer', 'dicePixelClassificationLayer', 1};  {'6', '7', '8', '9','10','11','12','13', 4}; };
            dlgTitle = 'Export network';
            options.PromptLines = [1, 1, 1];
            options.Title = sprintf('Convert and export the network to ONNX or TensorFlow format');
            options.TitleLines = 1;
            options.WindowWidth = 1.2;
            options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/exportonnxnetwork.html';

            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            exportFormat = answer{1};
            finalSegmentationLayer = answer{2};
            opsetVersion = str2double(answer{3});

            [currDir, fn] = fileparts(obj.BatchOpt.NetworkFilename);

            switch exportFormat
                case 'ONNX'
                    outoutFilename = fullfile(currDir, [fn '.onnx']);
                    [filename, pathname] = uiputfile( ...
                        {'*.onnx','ONNX-files (*.onnx)';...
                        '*.*',  'All Files (*.*)'}, ...
                        'Set output file', outoutFilename);
                    if filename == 0; return; end
                    outoutFilename = fullfile(pathname, filename);
                case 'TensorFlow'
                    outoutFilename = uigetdir(currDir, 'TensorFlow: define model package name');
                    if outoutFilename == 0; return; end
            end

            wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Exporting to %s\nPlease wait...', exportFormat), ...
                'Title', 'Export network');
            % load the model
            Model = load(obj.BatchOpt.NetworkFilename, '-mat');
            wb.Value = 0.4;

            % correct for dlnetwork that final layer (softmax) should be
            % kept as it is
            if isa(Model.net, 'dlnetwork')
                finalSegmentationLayer = 'Keep as it is';
            end

            if ~strcmp(finalSegmentationLayer, 'Keep as it is')
                lgraph = layerGraph(Model.net);

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
                switch answer{2}
                    case 'pixelClassificationLayer'
                        outLayer = pixelClassificationLayer('Name', 'Segmentation-Layer', 'Classes', outLayer.Classes);
                        lgraph = replaceLayer(lgraph, outPutLayerName{1}, outLayer);
                    case 'dicePixelClassificationLayer'
                        outLayer = dicePixelClassificationLayer('Name', 'Segmentation-Layer', 'Classes', outLayer.Classes);
                        lgraph = replaceLayer(lgraph, outPutLayerName{1}, outLayer);
                    case 'Remove the layer'
                        lgraph = removeLayers(lgraph, outPutLayerName{1});
                end
            else
                lgraph = Model.net;
            end

            switch exportFormat
                case 'ONNX'
                    try
                        exportONNXNetwork(lgraph, outoutFilename, 'OpsetVersion', opsetVersion);
                    catch err
                        % when addSpkgBinPath is not patched a second attempt to export is needed
                        % line 6: should be "if isempty(pathSet) && ~isdeployed"
                        try
                            exportONNXNetwork(lgraph, outoutFilename, 'OpsetVersion', opsetVersion);
                        catch err2
                            delete(wb);
                            reply = uiconfirm(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\n%s\n\n%s\n\nThe error message was copied to clipboard', err2.identifier, err2.message), ...
                                'ONNX export', ...
                                'Options',{'Copy error message to clipboard and close', 'Close'}, 'Icon', 'error');
                            if strcmp(reply, 'Copy error message to clipboard and close'); clipboard('copy', err2.message); end
                            return;
                        end
                    end
                case 'TensorFlow'
                    try
                        exportNetworkToTensorFlow(lgraph, outoutFilename);
                    catch err
                        mibShowErrorDialog(obj.View.gui, err, 'Export to TensorFlow');
                        delete(wb); return;
                    end
            end
            wb.Value = 1;
            delete(wb);
            uialert(obj.View.gui, sprintf('Export finished!\n%s', outoutFilename), 'Done!', 'Icon', 'success');
        end

        function transferLearning(obj)
            % function transferLearning(obj)
            % perform fine-tuning of the loaded network to a different
            % number of classes

            global mibPath;

            obj.BatchOpt.Mode{1} = 'Predict';   % change the mode, so that selectNetwork function loads the network
            net = obj.selectNetwork();
            if isempty(net); return; end
            dlnetwork_flag = false; % type of the loaded model
            if isa(net, 'dlnetwork'); dlnetwork_flag = true; end
            obj.BatchOpt.Mode{1} =  'Train';    % restore the mode

            [outPath, outNetworkName, outExt] = fileparts(obj.BatchOpt.NetworkFilename);
            outNetworkName = [outNetworkName '_TrLrn'];

            options.Title = sprintf('!!! Attention !!!\nYou are going to modify number of output classes!\nThis operation should be followed with retraining of the network!');
            options.TitleLines = 3;
            prompts = { 'Define new number of classes (including Exterior):';...
                'Segmentation layer:';...
                'New network name:'};
            defAns = {num2str(obj.BatchOpt.T_NumberOfClasses{1}); ...
                [obj.View.Figure.T_SegmentationLayer.Items find(ismember(obj.View.Figure.T_SegmentationLayer.Items, obj.BatchOpt.T_SegmentationLayer{1}))];...
                outNetworkName
                };

            dlgTitle = 'Transfer learning';
            options.WindowStyle = 'normal';
            options.PromptLines = [1, 1, 1];   % [optional] number of lines for widget titles
            options.WindowWidth = 1.3;    % [optional] make window x1.2 times wider
            %options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/imagedataaugmenter.html'; % [optional], an url for the Help button

            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            obj.wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Performing transfer learning\nPlease wait...'), ...
                'Title', 'Transfer learning');

            newNoClasses = str2double(answer{1});
            newSegLayer = answer{2};
            outNetworkName = answer{3};
            outConfigName = fullfile(outPath, [outNetworkName '.mibCfg']);
            outNetworkName = fullfile(outPath, [outNetworkName, outExt]);

            % generate a new network to obtain the ending part
            obj.BatchOpt.T_NumberOfClasses{1} = newNoClasses;  % redefine number of classes
            obj.BatchOpt.T_SegmentationLayer{1} = newSegLayer;  % update segmentation layer

            [lgraph, outputPatchSize] = obj.createNetwork();
            if isempty(lgraph)
                if ~isempty(obj.wb); delete(obj.wb); end
                return;
            end
            obj.wb.Value = 0.3;

            % find layer after which all layers should be replaced
            switch obj.BatchOpt.Architecture{1}
                case 'SegNet'
                    layerName = 'decoder1_conv1';   % 2D segnet
                case {'DeepLab v3+', 'Z2C + DLv3'}
                    layerName = 'scorer';   % 2D DeepLabV3
                case {'U-net +Encoder', 'Z2C + U-net +Encoder'}
                    layerName = 'encoderDecoderFinalConvLayer'; % 2D Unet with encoders
                otherwise
                    layerName = 'Final-ConvolutionLayer';
            end

            segmLayerId = numel(net.Layers);
            notOk = 1;
            while notOk
                if ~strcmp(net.Layers(segmLayerId).Name, layerName)
                    segmLayerId = segmLayerId - 1;
                else
                    notOk = 0;
                end

                if segmLayerId == 0
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nThe original network does not have %s layer', layerName), ...
                        'Transfer learning!', 'Icon', 'error');
                    delete(obj.wb);
                    return;
                end
            end
            obj.wb.Value = 0.5;

            % convert DAG object to LayerGraph object to allow
            % modification of layers
            net = layerGraph(net);
            for layerId=segmLayerId:numel(net.Layers)
                net = replaceLayer(net, net.Layers(layerId).Name, lgraph.Layers(layerId));
            end
            obj.wb.Value = 0.6;

            obj.BatchOpt.NetworkFilename = outNetworkName;
            if dlnetwork_flag; net = dlnetwork(net); end
            save(outNetworkName, 'net', '-mat', '-v7.3');
            obj.saveConfig(outConfigName);
            obj.wb.Value = 0.9;

            % update elements of GUI
            obj.View.Figure.NetworkFilename.Value = obj.BatchOpt.NetworkFilename;
            obj.View.Figure.T_NumberOfClasses.Value = obj.BatchOpt.T_NumberOfClasses{1};
            obj.View.Figure.NumberOfClassesPreprocessing.Value = obj.BatchOpt.T_NumberOfClasses{1};
            obj.View.Figure.T_SegmentationLayer.Value = obj.BatchOpt.T_SegmentationLayer{1};

            obj.wb.Value = 1;
            fprintf('The transfer learning finished:\n%s\n', outNetworkName);
            delete(obj.wb);
        end

        function importNetwork(obj)
            % function importNetwork(obj)
            % import an externally trained or designed network to be used
            % with DeepMIB
            %
            % Example:
            % % generate a network:
            % net = deeplabv3plusLayers([512 512 3], 5, 'resnet18');
            % % save network to a file
            % save('myNewNetwork.mat', 'net', '-mat');
            % % use Import opetation to load and adapt the network for use with DeepMIB
            global mibPath;

            if obj.mibController.matlabVersion < 9.11 % 'Interpreter' is available only from R2021b
                selection = uiconfirm(obj.View.gui,...
                    sprintf('[BETA] The following operation is allowing to import a network designed or trained externally\nResult of the operation is generation of "mibCfg" and "mibDeep" files that can be used with DeepMIB\n\nBefore proceeding please make sure that the most closest architecture is selected in DeepMIB settings and all other relevant parameter (e.g. directories) are specified. Check <a href="http://mib.helsinki.fi/help/main2/ug_gui_menu_tools_deeplearning.html#6">Help</a> for details.\n\nSupported formats:\n-Matlab'),...
                    '[BETA] Import network', 'Options', {'Continue', 'Cancel'}, 'Icon', 'info');
            else
                selection = uiconfirm(obj.View.gui,...
                    sprintf('[BETA] The following operation is allowing to import a network designed or trained externally\nResult of the operation is generation of "mibCfg" and "mibDeep" files that can be used with DeepMIB\n\nBefore proceeding please make sure that the most closest architecture is selected in DeepMIB settings and all other relevant parameter (e.g. directories) are specified. Check <a href="http://mib.helsinki.fi/help/main2/ug_gui_menu_tools_deeplearning.html#6">Help</a> for details.\n\nSupported formats:\n-Matlab'),...
                    '[BETA] Import network', 'Options', {'Continue', 'Cancel'}, 'Icon', 'info', 'Interpreter', 'html');
            end
            if strcmp(selection, 'Cancel'); return; end

            fileFilters = {'*.mat;', 'Matlab format (*.mat)';
                '*.*', 'All files (*.*)'};
            [filenameIn, pathIn, selectedIndx] = mib_uigetfile(fileFilters, 'Select network file', obj.mibModel.myPath);
            if isequal(filenameIn, 0); return; end
            filenameIn = filenameIn{1};

            switch fileFilters{selectedIndx, 2}
                case 'Matlab format (*.mat)'
                    import = load(fullfile(pathIn, filenameIn), '-mat');
                    % generate list of available variables and allow selection
                    fieldNames = fieldnames(import);
                    if numel(fieldNames) > 1
                        fieldNamesList = [];
                        for i=1:numel(fieldNames)
                            fieldNamesList = [fieldNamesList {sprintf('%s (%s)', fieldNames{i}, class(import.(fieldNames{i})))}];
                        end

                        prompts = {'Select the variable containing the network:'};
                        defAns = {fieldNamesList, 1};
                        dlgTitle = 'Import network';
                        [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle);
                        if isempty(answer); return; end

                        wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Importing the network\nPlease wait...'), ...
                            'Title', 'Import network');

                        net = import.(fieldNames{selIndex});
                    else
                        wb = uiprogressdlg(obj.View.gui, 'Message', sprintf('Importing the network\nPlease wait...'), ...
                            'Title', 'Import network');
                        net = import.(fieldNames{1});
                    end

                    %                     wb = uiprogressdlg(obj.View.gui,...
                    %                         'Message', sprintf('Importing the network\nPlease wait...'), ...
                    %                         'Title', 'Importing network', ...
                    %                         'Cancelable', 'on', ...
                    %                         'Value',0);
                    %                     if wb.CancelRequested; delete(wb); return; end

                    % generate new filenames
                    [~, outputNetworkName] = fileparts(filenameIn);
                    networkFileName = fullfile(pathIn, [outputNetworkName '.mibDeep']);
                    configFileName = fullfile(pathIn, [outputNetworkName '.mibCfg']);
                    if isfile(networkFileName)
                        selection = uiconfirm(obj.View.gui,...
                            sprintf('!!! Warning !!!\n\n%s\n\nalready exist!\nDo you want to overwrite it?', networkFileName),...
                            'Owerwrite existing network', 'Options', {'Overwrite', 'Cancel'} );
                        if strcmp(selection, 'Cancel'); return; end
                    end

                    obj.View.handles.NetworkFilename.Value = networkFileName;

                    inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);     % as [height, width, depth, colors]
                    % generate names for the classes
                    classNames = cell([1, obj.BatchOpt.T_NumberOfClasses{1}]);
                    classNames{1} = 'Exterior';
                    for classId = 2:obj.BatchOpt.T_NumberOfClasses{1}
                        classNames{classId} = sprintf('Class%.2d', classId-1);
                    end
                    wb.Value = 0.4;

                    outputPatchSize = [inputPatchSize([1 2 3]) numel(classNames)];
                    prompts = {sprintf('Confirm output patch size\n(height width depth number_of_classes):')};
                    defAns = {num2str(outputPatchSize)};
                    dlgTitle = 'Import network';
                    inputDlgOpt.PromptLines = 2;
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, inputDlgOpt);
                    if isempty(answer); delete(wb); return; end
                    outputPatchSize = str2num(answer{1});

                    % generate colormaps
                    obj.colormap6 = [166 67 33; 71 178 126; 79 107 171; 150 169 213; 26 51 111; 255 204 102 ]/255;
                    obj.colormap20 = [230 25 75; 255 225 25; 0 130 200; 245 130 48; 145 30 180; 70 240 240; 240 50 230; 210 245 60; 250 190 190; 0 128 128; 230 190 255; 170 110 40; 255 250 200; 128 0 0; 170 255 195; 128 128 0; 255 215 180; 0 0 128; 128 128 128; 60 180 75]/255;
                    obj.colormap255 = rand([255,3]);
                    if numel(classNames) < 7
                        classColors = obj.colormap6;
                    elseif numel(classNames) < 21
                        classColors = obj.colormap20;
                    else
                        classColors = obj.colormap255;
                    end
                    wb.Value = 0.5;

                    % update batch opt to take into account new parameters
                    obj.BatchOpt.NetworkFilename = networkFileName;

                    % save config file
                    obj.saveConfig(configFileName)
                    wb.Value = 0.6;

                    % define path to the parameters file with settings
                    importedParameters = load(configFileName, '-mat');

                    % update fields and generate fields for mibDeep file
                    TrainingOptStruct = importedParameters.TrainingOptStruct;
                    AugOpt2DStruct = importedParameters.AugOpt2DStruct;
                    AugOpt3DStruct = importedParameters.AugOpt3DStruct;
                    InputLayerOpt = importedParameters.InputLayerOpt;
                    BatchOpt = importedParameters.BatchOpt;
                    ActivationLayerOpt = importedParameters.ActivationLayerOpt;
                    SegmentationLayerOpt = importedParameters.SegmentationLayerOpt;
                    DynamicMaskOpt = importedParameters.DynamicMaskOpt;

                    wb.Value = 0.7;

                    % save network
                    save(networkFileName, 'net', 'TrainingOptStruct', 'AugOpt2DStruct', 'AugOpt3DStruct', 'InputLayerOpt', ...
                        'ActivationLayerOpt', 'SegmentationLayerOpt', 'DynamicMaskOpt', ...
                        'classNames', 'classColors', 'inputPatchSize', 'outputPatchSize', 'BatchOpt', '-mat', '-v7.3');
                    wb.Value = 1;
                    delete(wb);
                case 'All files (*.*)'
                    uialert(obj.View.gui, 'Please select correct file format for the network to import!', 'Wrong format');
                    return;
            end
        end

        function updateDynamicMaskSettings(obj)
            % function updateDynamicMaskSettings(obj)
            % update settings for calculation of dynamic masks during
            % prediction using blockedimage mode
            % the settings are stored in obj.DynamicMaskOpt

            global mibPath;

            % 'Keep above threshold' or 'Keep below threshold'
            prompts = {...
                sprintf('Masking method:\n"Keep above threshold" - threshold the image and process only the areas that are above the specified threshold\n"Keep below threshold" - threshold the image and process only the areas that are below the specified threshold'); ...
                sprintf('Intensity threshold value');...
                sprintf('Inclusion threshold (0-1):\nwhen 0, select a block with at least one pixel in the corresponding mask block is nonzero\nwhen 1, select a block only when all pixels in the mask block are nonzero')};

            defAns = {{'Keep above threshold', 'Keep below threshold', find(ismember({'Keep above threshold', 'Keep below threshold'}, obj.DynamicMaskOpt.Method))};...
                num2str(obj.DynamicMaskOpt.ThresholdValue);
                num2str(obj.DynamicMaskOpt.InclusionThreshold)};
            dlgTitle = 'Dynamic masking settings';
            options.WindowStyle = 'normal';
            options.PromptLines = [3, 1, 3];
            options.WindowWidth = 2.0;
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            if str2double(answer{3}) < 0 || str2double(answer{3}) > 1
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nInclusion threshold value should be between 0 and 1!'), ...
                    'Wrong inclusion threshold');
                return;
            end

            obj.DynamicMaskOpt.Method = answer{1};
            obj.DynamicMaskOpt.ThresholdValue = str2double(answer{2});
            obj.DynamicMaskOpt.InclusionThreshold = str2double(answer{3});
        end

        function saveCheckpointNetworkCheck(obj)
            % function saveCheckpointNetworkCheck(obj)
            % callback for press of Save checkpoint networks (obj.View.handles.T_SaveProgress)
            global mibPath;

            obj.BatchOpt.T_SaveProgress = obj.View.handles.T_SaveProgress.Value;
            if obj.mibController.matlabVersion >= 9.11 && obj.BatchOpt.T_SaveProgress
                prompts = {'Frequency of saving checkpoint networks, once in N epochs:'};
                defAns = {num2str(obj.TrainingOpt.CheckpointFrequency)};
                dlgTitle = 'Checkpoint frequency';
                options.PromptLines = 2;
                answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer); return; end
                obj.TrainingOpt.CheckpointFrequency = str2double(answer{1});
            end
        end

        function previewDynamicMask(obj)
            % function previewDynamicMask(obj)
            % preview results for the dynamic mode

            wb = uiprogressdlg(obj.View.gui, 'Message', 'Please wait...', ...
                'Title', 'Generating blocks');

            % get current image
            getDataOpt.blockModeSwitch = true;
            img = obj.mibModel.getData2D('image', NaN, NaN, NaN, getDataOpt);
            noColors = size(img, 3);
            inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);
            img = blockedImage(img{1}, ...              % % [height, width, color]
                'Adapter', images.blocked.InMemory);    % convert to blockedimage
            wb.Value = 0.3;
            inputPatchSize(1:2) = inputPatchSize(1:2);
            bls = obj.generateDynamicMaskingBlocks(img, inputPatchSize(1:2), noColors);
            wb.Value = 0.6;

            % show
            figure(randi(1024));
            bigimageshow(img);
            blockedWH = fliplr(bls.BlockSize(1,1:2));
            for ind = 1:size(bls.BlockOrigin,1)
                % BlockOrigin is already in x,y order.
                drawrectangle('Position', [bls.BlockOrigin(ind,1:2),blockedWH]);
            end
            wb.Value = 1;
            delete(wb);
        end

        function exploreActivations(obj)
            % explore activations within the trained network
            obj.startController('mibDeepActivationsController', obj);
        end

        function countLabels(obj)
            % count occurrences of labels in model files
            % callback for press of the "Count labels" in the Options panel
            global mibPath;

            % define directory with label files
            if ~isfield(obj.sessionSettings, 'countLabelsDir')
                obj.sessionSettings.countLabelsDir = obj.BatchOpt.OriginalTrainingImagesDir;
            end
            selpath = uigetdir(obj.sessionSettings.countLabelsDir, 'Select folder with labels');
            if selpath == 0; return; end
            obj.sessionSettings.countLabelsDir = selpath;
            % define extension of the label files
            prompts = {'Label filenames extension:'; 'Number of classes including exterior, (for TIF and PNG or put largest possible value):'};
            defAns = {{'model', 'mibCat', 'png', 'tif', 'tiff', 1}, num2str(obj.BatchOpt.T_NumberOfClasses{1})};
            dlgTitle = 'Options';
            dlgOptions.PromptLines = [1, 2];
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, dlgOptions);
            if isempty(answer); return; end
            labelExtension = answer{1};
            numClasses = str2double(answer{2});

            % get list of files
            labelFileList = dir(fullfile(obj.sessionSettings.countLabelsDir, lower(['*.' labelExtension])));
            if numel(labelFileList) == 0
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nDirectory:\n%s\ndoes not contain any files with "%s" extension', obj.sessionSettings.countLabelsDir, labelExtension), ...
                    'Missing label files', 'icon', 'error');
                return
            end

            % generate class names
            classNames = {};
            if strcmp(labelExtension, 'model')
                modelFn = fullfile(labelFileList(1).folder, labelFileList(1).name);
                res = load(modelFn, '-mat', 'modelMaterialNames');
                classNames = [{'Exterior'}; res.modelMaterialNames];
            elseif strcmp(labelExtension, 'mibCat')
                modelFn = fullfile(labelFileList(1).folder, labelFileList(1).name);
                res = load(modelFn, '-mat', 'options');
                classNames = res.options.modelMaterialNames;
            else
                for i=0:numClasses-1
                    classNames = [classNames; {sprintf('Class%.3d', i)}]; %#ok<AGROW>
                end
            end
            pixelLabelID = 0:numel(classNames)-1;

            % make datastores
            try
                fullPathFilenames = arrayfun(@(filename) fullfile(obj.sessionSettings.countLabelsDir, cell2mat(filename)), ...
                    {labelFileList.name}, 'UniformOutput', false);  % generate full paths
                switch labelExtension
                    case 'model'
                        dsLabels = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                            'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
                    case 'mibCat'
                        %dsLabels = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                        %    'FileExtensions', '.mibCat', 'ReadFcn', @mibDeepStoreLoadImages);
                        dsLabels = imageDatastore(fullPathFilenames, ...
                            'FileExtensions', '.mibCat', 'IncludeSubfolders', false, ...
                            'ReadFcn', @mibDeepStoreLoadCategorical);
                    otherwise
                        dsLabels = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                            'FileExtensions', lower(['.' labelExtension]));
                end
            catch err
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\n%s\n\n%s\n\nCheck the ground truth directory:\n%s', err.identifier, err.message, obj.sessionSettings.countLabelsDir), ...
                    'Wrong class name');
                return;
            end

            % generate output structure
            % add list of files
            [~, ImageMetrics.GroundTruthFilename] = arrayfun(@(fn) fileparts(cell2mat(fn)), dsLabels.Files, 'UniformOutput', false);

            % define usage of parallel computing
            if obj.BatchOpt.UseParallelComputing
                parforArg = obj.View.handles.PreprocessingParForWorkers.Value;    % Maximum number of workers running in parallel
                TitleTest = 'Count labels (parallel)';
                if isempty(gcp('nocreate')); parpool(parforArg); end  % create parpool
            else
                parforArg = 0;      % Maximum number of workers running in parallel
                TitleTest = 'Count labels (single)';
            end
            % reset datastores
            dsLabels.reset();

            % make waitbar
            pw = PoolWaitbar(numel(dsLabels.Files), sprintf('Counting labels\nit may take a while...'), [], TitleTest);
            pw.setIncrement(10);
            occurrenceGT = cell([numel(dsLabels.Files), 1]);

            parfor (fileId=1:numel(dsLabels.Files), parforArg)
                % for fileId = 1:numel(dsLabels.Files)
                gtImg = readimage(dsLabels, fileId);
                if iscell(gtImg(1)); gtImg = gtImg{1}; end

                catList = categories(gtImg(:));
                catCounts = countcats(gtImg(:));
                occurrenceGT{fileId}(ismember(classNames, catList)) = catCounts;

                if mod(fileId, 10) == 1; increment(pw); end     % update waitbar
            end
            occurrenceGT = cell2mat(occurrenceGT);
            for classId = 1:numel(classNames)
                ImageMetrics.(['GT_' classNames{classId}]) = occurrenceGT(:,classId);
            end
            % convert to table
            tableOut = struct2table(ImageMetrics);
            pw.deletePoolWaitbar();

            fn = fullfile(obj.sessionSettings.countLabelsDir, 'labelCounts.mat');
            [filename, pathname, filterindex] = uiputfile( ...
                {'*.mat','MAT-files (*.mat)';...
                '*.xls', 'Microsoft Excel';...
                '*.csv','Comma-separated values';...
                '*.*',  'All Files (*.*)'}, 'Output filename', fn);
            if filename == 0; return; end
            fn = fullfile(pathname, filename);

            switch filterindex
                case 1  % mat
                    save(fn, 'tableOut', '-v7.3');
                    fprintf('Label counts were were saved to:\n%s\n', fn);
                case 2  % excel
                    wbar = waitbar(0, sprintf('Saving to Excel\nPlease wait...'), 'Name', 'Export');
                    clear excelHeader;
                    if exist(fn, 'file') == 2; delete(fn); end
                    excelHeader{1} = sprintf('Label counts for %s\\*.%s', obj.sessionSettings.countLabelsDir, labelExtension);
                    writecell(excelHeader, fn, 'FileType', 'spreadsheet', 'Sheet', 'LabelCounts', 'Range', 'A1');
                    writetable(tableOut, fn, 'FileType', 'spreadsheet', 'Sheet', 'LabelCounts', 'WriteRowNames', true, 'Range', 'A3');
                    waitbar(1, wbar);
                    fprintf('Label counts were were saved to:\n%s\n', fn);
                    delete(wbar);
                case 3  % csv
                    wbar = waitbar(0, sprintf('Saving to CSV format\nPlease wait...'), 'Name', 'Export');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(tableOut, fn, 'FileType', 'text', 'WriteRowNames', true);
                    fprintf('Label counts were were saved to:\n%s\n', fn);
                    delete(wbar);
            end
        end

        function balanceClasses(obj)
            % balance classes before training
            % see example from here:
            % https://se.mathworks.com/help/vision/ref/balancepixellabels.html
            global mibPath;

            if ~isfield(obj.sessionSettings, 'numBalanceObservations'); obj.sessionSettings.numBalanceObservations = 200; end
            if ~isfield(obj.sessionSettings, 'balanceObservationsParallel'); obj.sessionSettings.balanceObservationsParallel = false; end

            % Set block size of the images.
            inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);
            blockSize = [inputPatchSize(1) inputPatchSize(2)];

            prompts = {sprintf('Number of patches in the balanced dataset to generate:'); 'Output patch size:'; 'Number of classes (incl. Exterior):'; 'Use parallel processing:'};
            defAns = {num2str(obj.sessionSettings.numBalanceObservations); num2str(blockSize); obj.BatchOpt.T_NumberOfClasses{1}; obj.sessionSettings.balanceObservationsParallel};
            dlgTitle = 'Settings';
            inputDlgOpt.PromptLines = 1;
            inputDlgOpt.Title = sprintf(['This is a beta procedure to balance rare classes in the dataset\n' ...
                'The procedure is implemented only for the 2D Semantic workflow and only for images and labels that are ' ...
                'stored in standard image formats (e.g. TIF, PNG, JPG).\n' ...
                'The images and labels needs to be placed in "Images" and "Labels" subfolders under ' ...
                '"Directories with images and labels for training" specified in the "Directories and preprocessing" tab\n' ...
                'The balanced results are generated under the same directory in ' ...
                '"ImagesBalanced" and "LabelsBalanced" subfolders']);
            inputDlgOpt.TitleLines = 10;
            inputDlgOpt.WindowWidth = 1.4;
            inputDlgOpt.helpBtnText = 'Info example';
            inputDlgOpt.HelpUrl = 'https://se.mathworks.com/help/vision/ref/balancepixellabels.html';
            inputDlgOpt.WindowStyle = 'normal';
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, inputDlgOpt);
            if isempty(answer); return; end

            % Speciy number of block locations to sample from the dataset.
            obj.sessionSettings.numBalanceObservations = str2double(answer{1});
            blockSize = str2num(answer{2});
            numberOfClasses = str2double(answer{3});
            obj.sessionSettings.balanceObservationsParallel = logical(answer{4});

            parforArg = 0;  % no parallel pool
            if obj.sessionSettings.balanceObservationsParallel
                parforArg = obj.View.handles.PreprocessingParForWorkers.Value;    % Maximum number of workers running in parallel
                if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
            end

            % check for the proper workflow
            if ~strcmp(obj.BatchOpt.Workflow{1}, '2D Semantic')
                uialert(obj.View.gui, ...
                    sprintf(['!!! Error !!!\n\n' ...
                    'Balancing of labels is implemented only for the 2D Semantic workflow!']), ...
                    'Wrong workflow', 'icon', 'error');
                return
            end
            tic;

            % define input directories for images and labels
            try
                imageDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Images');
                labelDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Labels');
                imageSet = matlab.io.datastore.FileSet(imageDir, "FileExtensions", {['.' obj.BatchOpt.ImageFilenameExtensionTraining{1}]});
                labelSet = matlab.io.datastore.FileSet(labelDir, "FileExtensions", {['.' obj.BatchOpt.ModelFilenameExtension{1}]});
            catch err
                %obj.showErrorDialog(err, 'Missing files');
                mibShowErrorDialog(obj.View.gui, err, 'Missing files');
                return;
            end
            % check that number of image and label files match
            if imageSet.NumFiles ~= labelSet.NumFiles
                uialert(obj.View.gui, ...
                    sprintf(['!!! Error !!!\n\n' ...
                    'Directories with images and labels should have equal number of files!\n\n' ...
                    'Directory with images:\n%s\n\nDirectory with labels:\n%s\n'], imageDir, labelDir), ...
                    'Number of files mismatch', 'icon', 'error');
                return
            end

            pw = PoolWaitbar(imageSet.NumFiles, sprintf('Balancing labels\nPlease wait...'));

            % Create an array of labeled images from the dataset.
            blockedLabelsList = blockedImage(labelSet);
            blockedImagesList = blockedImage(imageSet);

            % Create a blockedImageDatastore from the image array.
            blockedLabelsDS = blockedImageDatastore(blockedLabelsList, 'BlockSize', blockSize);

            % Count pixel label occurrences of each class. The classes in the pixel label images are not balanced.
            if numberOfClasses == 2
                pixelLabelID = 0:numberOfClasses-1; %  exclude exterior
                classNames = {'Exterior', 'Class01'};
            else
                pixelLabelID = 1:numberOfClasses-1; %  exclude exterior
                classNames = arrayfun(@(x) sprintf('Class%.2d', x), 1:numberOfClasses-1, 'UniformOutput', false);
            end

            % Select block locations from the labeled images to achieve class.
            locationSet = balancePixelLabels(blockedLabelsList, blockSize, obj.sessionSettings.numBalanceObservations,...
                'Classes', classNames, 'PixelLabelIDs', pixelLabelID);

            % Create a blockedImageDatastore using the block locations after balancing.
            blockLabeldsBalanced = blockedImageDatastore(blockedLabelsList, 'BlockLocationSet', locationSet);
            blockImagesBalanced = blockedImageDatastore(blockedImagesList, 'BlockLocationSet', locationSet);

            outImgDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ImagesBalanced');
            outLabelDir = fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'LabelsBalanced');
            if isfolder(outImgDir); rmdir(outImgDir, 's'); end
            if isfolder(outLabelDir); rmdir(outLabelDir, 's'); end
            mkdir(outImgDir);
            mkdir(outLabelDir);

            pw.updateMaxNumberOfIterations(blockImagesBalanced.TotalNumBlocks);
            pw.setIncrement(20);  % set increment step to 20

            fnIndex = 1;
            parfor (fnIndex = 1:blockImagesBalanced.TotalNumBlocks, parforArg)
                [imgIn, imgInfo] = read(blockImagesBalanced);
                [labelIn, labelInfo] = read(blockLabeldsBalanced);
                fn = sprintf('img_%.3d.tif', fnIndex);
                imwrite(imgIn{1}, fullfile(outImgDir, fn));
                imwrite(labelIn{1}, fullfile(outLabelDir, fn));
                if mod(fnIndex, 20) == 1; increment(pw); end
            end

            pw.updateText(sprintf('Counting labels\nPlease wait...'));
            pw.updateMaxNumberOfIterations(3);
            pw.setIncrement(1);  % set increment step to 20
            increment(pw);

            if numberOfClasses == 2
                classNamesCounting = classNames;
                pixelLabelIDCounting = 0:numberOfClasses-1;
            else
                %classNamesCounting = ['Ext', classNames];
                %pixelLabelIDCounting = 0:numberOfClasses-1;
                classNamesCounting = classNames;
                pixelLabelIDCounting = 1:numberOfClasses-1;
            end

            labelCounts = countEachLabel(blockedLabelsDS,...
                'Classes', classNamesCounting, 'PixelLabelIDs', pixelLabelIDCounting);
            increment(pw);

            % Recalculate the pixel label occurrences for the balanced dataset.
            labelCountsBalanced = countEachLabel(blockLabeldsBalanced,...
                'Classes', classNamesCounting, 'PixelLabelIDs', pixelLabelIDCounting);
            increment(pw);

            % Compare the original unbalanced labels and labels after label balancing.
            figure(321);
            h1 = histogram('Categories',labelCounts.Name,...
                'BinCounts',labelCounts.PixelCount);
            title(h1.Parent,'Original dataset labels')

            figure(322);
            h2 = histogram('Categories',labelCountsBalanced.Name,...
                'BinCounts',labelCountsBalanced.PixelCount);
            title(h2.Parent, sprintf('Balanced labels, N=%d', obj.sessionSettings.numBalanceObservations));
            fprintf('Balancing of classes is over!\n');
            toc;
            pw.deletePoolWaitbar();
        end

        function customTrainingProgressWindow_Callback(obj, event)
            % function customTrainingProgressWindow_Callback(obj, event)
            % callback for click on
            % obj.View.handles.O_CustomTrainingProgressWindow checkbox

            if obj.View.handles.O_CustomTrainingProgressWindow.Value
                obj.View.handles.O_RefreshRateIter.Enable = 'on';
                obj.View.handles.O_NumberOfPoints.Enable = 'on';
                obj.View.handles.O_PreviewImagePatches.Enable = 'on';
                obj.View.handles.O_FractionOfPreviewPatches.Enable = 'on';
            else
                obj.View.handles.O_RefreshRateIter.Enable = 'off';
                obj.View.handles.O_NumberOfPoints.Enable = 'off';
                obj.View.handles.O_PreviewImagePatches.Enable = 'off';
                obj.View.handles.O_FractionOfPreviewPatches.Enable = 'off';
            end
            obj.updateBatchOptFromGUI(event);
            event2.Source = obj.View.handles.O_PreviewImagePatches;
            obj.previewImagePatches_Callback(event2);
        end

        function previewImagePatches_Callback(obj, event)
            % function previewImagePatches_Callback(obj, event)
            % callback for value change of obj.View.handles.O_PreviewImagePatches

            if obj.View.handles.O_PreviewImagePatches.Value && strcmp(obj.View.handles.O_PreviewImagePatches.Enable, 'on')
                obj.View.handles.O_FractionOfPreviewPatches.Enable = 'on';
            else
                obj.View.handles.O_FractionOfPreviewPatches.Enable = 'off';
            end
            obj.updateBatchOptFromGUI(event);
        end

        function sendReportsCallback(obj)
            % function sendReportsCallback(obj)
            % define parameters for sending progress report to the user's
            % email address

            global mibPath;

            obj.SendReports.T_SendReports = obj.View.handles.T_SendReports.Value;
            if obj.SendReports.T_SendReports == 0; return; end

            prompts = {'Destination email:', ...
                'SMTP server address', 'SMTP server port', 'SMTP authentication', 'SMTP use starttls', ...
                'SMTP username', 'SMTP password', 'Check to see the password in plain text after OK press', ...
                'Send email when training is finished', 'Send progress emails (defined by frequency of checkpoint saves)'};
            defAns = {obj.SendReports.TO_email, ...
                obj.SendReports.SMTP_server, obj.SendReports.SMTP_port, obj.SendReports.SMTP_auth, obj.SendReports.SMTP_starttls, ...
                obj.SendReports.SMTP_username, '**************', false, ...
                obj.SendReports.sendWhenFinished, obj.SendReports.sendDuringRun};
            dlgTitle = 'Send progress reports';
            options.PromptLines = [1,1,1,1,1,1,1,2,2,2];
            options.WindowWidth = 1.4;
            options.helpBtnText = 'Test connection';
            options.Title = sprintf(['Use this dialog to specify settings for email notifications' ...
                'that are sent to your inbox.\nConnection can be checked by pressing ' ...
                'the "Test connection" button in the left bottom corner.' ...
                'To check connection reopen this dialog!']);
            options.TitleLines = 5;
            options.HelpUrl = sprintf('sendmail("%s", "Greetings from DeepMIB", "If you received this email, connection from DeepMIB to your email works fine!");', obj.SendReports.TO_email);
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end

            obj.SendReports.TO_email = answer{1};
            obj.SendReports.SMTP_server = answer{2};
            obj.SendReports.SMTP_port = answer{3};
            obj.SendReports.SMTP_auth = logical(answer{4});
            obj.SendReports.SMTP_starttls = logical(answer{5});
            obj.SendReports.SMTP_username = answer{6};
            if ~strcmp(answer{7}, '**************')
                obj.SendReports.SMTP_password = answer{7};
            end
            if answer{8} % show password as text
                prompts2 = {'Here is the password for connection to SMTP server:'};
                defAns2 = {obj.SendReports.SMTP_password};
                options2.okBtnText = 'Update';
                options2.WindowWidth = 2;
                answer2 = mibInputMultiDlg({mibPath}, prompts2, defAns2, 'SMTP password', options2);
                if ~isempty(answer2); obj.SendReports.SMTP_password = answer2{1}; end
            end
            obj.SendReports.sendWhenFinished = logical(answer{9});
            obj.SendReports.sendDuringRun = logical(answer{10});

            % Apply prefs and props
            props = java.lang.System.getProperties;
            props.setProperty('mail.smtp.port', obj.SendReports.SMTP_port);
            if obj.SendReports.SMTP_auth
                props.setProperty('mail.smtp.auth', 'true');
            else
                props.setProperty('mail.smtp.auth', 'false');
            end
            if obj.SendReports.SMTP_starttls
                props.setProperty('mail.smtp.starttls.enable', 'true');
            else
                props.setProperty('mail.smtp.starttls.enable', 'false');
            end

            setpref('Internet','E_mail', obj.SendReports.TO_email);
            setpref('Internet','SMTP_Server', obj.SendReports.SMTP_server);
            setpref('Internet','SMTP_Username', obj.SendReports.SMTP_username);
            setpref('Internet','SMTP_Password', obj.SendReports.SMTP_password);

            %sendmail(obj.SendReports.TO_email, 'test', 'This is test');

        end

        % function updateEncoderNetwork(obj)
        %     % function updateEncoderNetwork(obj)
        %     % update encoder network upon user selection
        %
        %     selectedEncoder = obj.View.handles.T_EncoderNetwork.Value;
        %     encoderKeyValue = [obj.BatchOpt.Workflow{1} ' ' obj.BatchOpt.Architecture{1}];
        %
        %     obj.availableEncoders{encoderKeyValue}{end} = find(ismember(obj.availableEncoders{encoderKeyValue}(1:end-1), selectedEncoder));
        %
        %     %encodersList = obj.availableEncoders(encoderKeyValue);
        %     %encodersList{end} = find(ismember(encodersList(1:end-1), selectedEncoder));
        %     %obj.availableEncoders(encoderKeyValue) = encodersList;
        %     obj.BatchOpt.T_EncoderNetwork{1} = selectedEncoder;
        %
        % end

        function helpButton_callback(obj)
            % function helpButton_callback(obj)
            % show Help sections
            global mibPath;

            switch obj.View.handles.Mode.SelectedTab.Title
                case 'Directories and Preprocessing'
                    web(fullfile(mibPath, 'techdoc', 'html', 'ug_gui_menu_tools_deeplearning_dirs.html'), '-helpbrowser');
                case 'Train'
                    web(fullfile(mibPath, 'techdoc', 'html', 'ug_gui_menu_tools_deeplearning_train.html'), '-helpbrowser');
                case 'Predict'
                    web(fullfile(mibPath, 'techdoc', 'html', 'ug_gui_menu_tools_deeplearning_predict.html'), '-helpbrowser');
                case 'Options'
                    web(fullfile(mibPath, 'techdoc', 'html', 'ug_gui_menu_tools_deeplearning_options.html'), '-helpbrowser');
            end
        end

        function duplicateConfigAndNetwork(obj)
            % function duplicateConfigAndNetwork(obj)
            % copy the network file and its config to a new filename

            currPath = fileparts(obj.BatchOpt.NetworkFilename);
            [currFile, currPath] = mib_uigetfile({'*.mibDeep', 'mibDeep Files (*.mibDeep)'}, ...
                'Select source network', currPath);
            if isequal(currFile, 0); return; end
            currFile = currFile{1};

            [newFile, newPath]  = uiputfile({'*.mibDeep', 'mibDeep files (*.mibDeep)';
                '*.mat', 'Mat files (*.mat)'}, 'Set target network name', ...
                fullfile(currPath, currFile));
            if newFile == 0; return; end

            wb = uiprogressdlg(obj.View.gui, 'Message', 'Please wait...', ...
                'Title', 'Saving network and config');

            % copy network file
            newNetworkFile = fullfile(newPath, newFile);
            if isfile(fullfile(currPath, currFile))
                copyfile(fullfile(currPath, currFile), newNetworkFile);
            else
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nThe network file to copy is missing!\nPlease select the network file and try again'), ...
                    'Network file is missing');
                delete(wb);
                return;
            end
            wb.Value = 0.5;

            % save config
            oldConfigName = fullfile(currPath, replace(currFile,'.mibDeep', '.mibCfg'));
            newConfigName = replace(newNetworkFile,'.mibDeep', '.mibCfg');
            if isfile(oldConfigName)
                copyfile(oldConfigName, newConfigName);
                % update network filename in the new config file
                matObj = matfile(newConfigName, 'Writable', true);
                BatchOpt = matObj.BatchOpt;
                BatchOpt.NetworkFilename = ['[RELATIVE]' newFile];
                matObj.BatchOpt = BatchOpt;
            end
            wb.Value = 1;
            delete(wb);

            % load the duplicated config
            res = uiconfirm(obj.View.gui, ...
                'Would you like to load the duplicated config into DeepMIB now?', ...
                'Load the duplicated config', ...
                'Options', {'Load the duplicated config','Keep the current'}, ...
                'Icon', 'question');
            if strcmp(res, 'Load the duplicated config')
                obj.loadConfig(newConfigName);
            end


        end

    end
end