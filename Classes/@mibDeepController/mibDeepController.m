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
    
    % Copyright (C) 17.09.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    %
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    %
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
        % probabilities of each augmentation action to be triggered
        Aug3DFuncNames
        % cell array with names of 2D augmenter functions
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
        % .noImages = 25, number of images in montage
        % .labelShow = true, display overlay labels with details
        % .labelSize = 9, font size for the label
        % .labelColor = 'black', color of the label
        % .labelBgColor = 'yellow', color of the label background
        % .labelBgOpacity = 0.6;   % opacity of the background
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
        
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
        
        function model = readModel(filename)
            % function model = readModel(filename)
            % to be used with pixelLabelDatastore to load MIB models
            res = load(filename, '-mat');
            model = res.(res.modelVariable);
        end
        
        function data = matlabCategoricalFileRead(filename)
            % function data = matlabCategoricalFileRead(filename)
            % read categorical dataset and return it as a cell similar to pixelLabelDatastore
            
            inp = load(filename, '-mat');
            if isfield(inp, 'imgVariable')
                data = {inp.(inp.imgVariable)};
            else
                f = fields(inp);
                data = {inp.(f{1})};
            end
        end
        
        function data = mibImgFileRead(filename)
            % function data = mibImgFileRead(filename)
            % read mibImg file for datastore
            
            inp = load(filename, '-mat');
            if isfield(inp, 'imgVariable')
                data = inp.(inp.imgVariable);
            else
                f = fields(inp);
                data = inp.(f{1});
            end
        end
        
        function [outputLabeledImageBlock, scoreBlock] = segmentBlockedImage(block, net, generateScoreFiles, ExecutionEnvironment)
            % test function for utilization of bigimage for prediction
            % The input block will be a batch of blocks from the bigimage.
            
            [outputLabeledImageBlock, ~, scoreBlock] = semanticseg(block, net, ...
                'OutputType', 'uint8',...
                'ExecutionEnvironment', ExecutionEnvironment);
            
            % Add singleton channel dimension to permit bigimage apply to
            % reconstruct the full image from the processed blocks.
            sz = size(outputLabeledImageBlock);
            outputLabeledImageBlock = reshape(outputLabeledImageBlock, [sz(1:2) 1 sz(3:end)]);
            if generateScoreFiles
                sz = size(scoreBlock);
                scoreBlock = uint8(scoreBlock*255);     % scale and convert to uint8
                scoreBlock = reshape(scoreBlock, [sz(1:2) sz(3:end)]);
            else
                scoreBlock = zeros([sz(1:2) 1 sz(3:end)]);
            end
        end
        
        %         function img = loadAndTransposeImages(filename)
        %             img = mibLoadImages(filename);
        %             img = permute(img, [1 2 4 3]);  % transpose from [h,w,c,z] to [h,w,z,c]
        %         end
    end
    
    methods
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
            
            obj.BatchOpt.NetworkFilename = fullfile(obj.mibModel.myPath, 'myLovelyNetwork.mibDeep');
            obj.BatchOpt.Architecture = {'2D U-net'};
            obj.BatchOpt.Architecture{2} = {'2D U-net', '2D SegNet', '3D U-net', '3D U-net Anisotropic'};
            obj.BatchOpt.Mode = {'Train'};
            obj.BatchOpt.Mode{2} = {'Train', 'Predict'};
            obj.BatchOpt.T_ConvolutionPadding = {'same'};
            obj.BatchOpt.T_ConvolutionPadding{2} = {'same', 'valid'};
            obj.BatchOpt.T_InputPatchSize = '64 64 1 1';
            obj.BatchOpt.T_NumberOfClasses{1} = 2;
            obj.BatchOpt.T_NumberOfClasses{2} = [1 Inf];
            obj.BatchOpt.T_SegmentationLayer = {'dicePixelCustomClassificationLayer'};
            if verLessThan('matlab','9.8')  % 'focalLossLayer' - is available from R2020a
                obj.BatchOpt.T_SegmentationLayer{2} = {'pixelClassificationLayer', 'dicePixelClassificationLayer', 'dicePixelCustomClassificationLayer'};
            else
                obj.BatchOpt.T_SegmentationLayer{2} = {'pixelClassificationLayer', 'focalLossLayer', 'dicePixelClassificationLayer', 'dicePixelCustomClassificationLayer'};
            end
            obj.BatchOpt.T_ActivationLayer = {'reluLayer'};
            obj.BatchOpt.T_ActivationLayer{2} = {'reluLayer', 'leakyReluLayer', 'clippedReluLayer', 'eluLayer', 'tanhLayer'};
            obj.BatchOpt.T_EncoderDepth{1} = 3;
            obj.BatchOpt.T_EncoderDepth{2} = [1 Inf];
            obj.BatchOpt.T_NumFirstEncoderFilters{1} = 32;
            obj.BatchOpt.T_NumFirstEncoderFilters{2} = [1 Inf];
            obj.BatchOpt.T_FilterSize{1} = 3;
            obj.BatchOpt.T_FilterSize{2} = [3 Inf];
            obj.BatchOpt.T_PatchesPerImage{1} = 32;
            obj.BatchOpt.T_PatchesPerImage{2} = [1 Inf];
            obj.BatchOpt.T_MiniBatchSize{1} = obj.mibModel.preferences.Deep.MiniBatchSize;
            obj.BatchOpt.T_MiniBatchSize{2} = [1 Inf];
            obj.BatchOpt.T_augmentation = true;
            obj.BatchOpt.T_ExportTrainingPlots = true;
            obj.BatchOpt.T_SaveProgress = false;
            obj.BatchOpt.P_OverlappingTiles = true;
            obj.BatchOpt.P_ScoreFiles = {'Use AM format'};
            obj.BatchOpt.P_ScoreFiles{2} = {'Do not generate', 'Use AM format', 'Use Matlab non-compressed format', 'Use Matlab compressed format'};
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
            
            obj.BatchOpt.SingleModelTrainingFile = true;    % use single model file with the model
            obj.BatchOpt.ModelFilenameExtension = {'MODEL'};    % extension for model files
            obj.BatchOpt.ModelFilenameExtension{2} = {'MODEL', 'PNG', 'TIF', 'TIFF'};
            obj.BatchOpt.MaskFilenameExtension = {'MASK'};      % extension for mask files
            obj.BatchOpt.MaskFilenameExtension{2} = {'MASK', 'PNG', 'TIF', 'TIFF'};
            
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
            
            obj.BatchOpt.PreprocessingMode = {'Training and Prediction'};
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
            
            obj.BatchOpt.P_MiniBatchSize{1} = 1;
            obj.BatchOpt.P_MiniBatchSize{2} = [1 Inf];
            obj.BatchOpt.P_MiniBatchSize{3} = true;
            
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
            obj.BatchOpt.mibBatchTooltip.Architecture = 'Architecture of the network';
            obj.BatchOpt.mibBatchTooltip.T_ConvolutionPadding = '"same": zero padding is applied to the inputs to convolution layers such that the output and input feature maps are the same size; "valid" - zero padding is not applied; the output feature map is smaller than the input feature map';
            obj.BatchOpt.mibBatchTooltip.Mode = 'Use tool in the training or prediction mode';
            obj.BatchOpt.mibBatchTooltip.T_InputPatchSize = 'Network input image size as [height width depth colors]';
            obj.BatchOpt.mibBatchTooltip.T_NumberOfClasses = 'Number of classes in the model including Exterior';
            obj.BatchOpt.mibBatchTooltip.T_ActivationLayer = 'Replace default activation layer with any one from this list';
            obj.BatchOpt.mibBatchTooltip.T_SegmentationLayer = 'Define the type of the last (segmentation) layer of the network';
            obj.BatchOpt.mibBatchTooltip.T_EncoderDepth = 'The depth of the network determines the number of times the input volumetric image is downsampled or upsampled during processing';
            obj.BatchOpt.mibBatchTooltip.T_NumFirstEncoderFilters = 'Number of output channels for the first encoder stage';
            obj.BatchOpt.mibBatchTooltip.T_FilterSize = 'Convolutional layer filter size, specified as a positive odd integer';
            obj.BatchOpt.mibBatchTooltip.T_PatchesPerImage = 'Number of patches to extract from each image';
            obj.BatchOpt.mibBatchTooltip.T_MiniBatchSize = 'Number of observations that are returned in each batch';
            obj.BatchOpt.mibBatchTooltip.T_augmentation = 'Augment images during training';
            obj.BatchOpt.mibBatchTooltip.T_ExportTrainingPlots = 'When ticked, export training scores to files, which are placed to Results\ScoreNetwork folder';
            obj.BatchOpt.mibBatchTooltip.T_SaveProgress = 'When ticked the network progress is saved to Results\ScoreNetwork folder';
            obj.BatchOpt.mibBatchTooltip.P_OverlappingTiles = 'when enabled use overlapping tiles during prediction, it is slower but may give better results';
            obj.BatchOpt.mibBatchTooltip.P_ScoreFiles = 'tweak generation of score files showing probability of each class';
            obj.BatchOpt.mibBatchTooltip.OriginalTrainingImagesDir = 'Specify directory with original images and models. The images and models should be placed under "Images" and "Labels" subfolders correspondingly';
            obj.BatchOpt.mibBatchTooltip.OriginalPredictionImagesDir = 'Specify directory with original images for prediction';
            obj.BatchOpt.mibBatchTooltip.ImageFilenameExtension = 'Filename extension of original images used for prediction';
            obj.BatchOpt.mibBatchTooltip.ImageFilenameExtensionTraining = 'Filename extension of original images used for traininig';
            obj.BatchOpt.mibBatchTooltip.BioformatsTraining = 'Use Bioformats file reader for training images';
            obj.BatchOpt.mibBatchTooltip.BioformatsTrainingIndex = 'Index of a serie to be used with bio-formats reader for training';
            obj.BatchOpt.mibBatchTooltip.Bioformats = 'Use Bioformats file reader for prediction images';
            obj.BatchOpt.mibBatchTooltip.BioformatsIndex = 'Index of a serie to be used with bio-formats reader for prediction';
            obj.BatchOpt.mibBatchTooltip.ResultingImagesDir = 'Specify directory for resulting images for preprocessing and prediction, the following subfolders are used: TrainImages, TrainLabels, ValidationImages, ValidationLabels, PredictionImages';
            obj.BatchOpt.mibBatchTooltip.NormalizeImages = 'Normalize images during preprocessing, or use original images';
            obj.BatchOpt.mibBatchTooltip.CompressProcessedImages = 'Compression of images slows down performance but saves space';
            obj.BatchOpt.mibBatchTooltip.CompressProcessedModels = 'Compression of models slows down performance but saves space';
            obj.BatchOpt.mibBatchTooltip.PreprocessingMode = 'Preprocess images for prediction or training by splitting the datasets for training and validation';
            obj.BatchOpt.mibBatchTooltip.ValidationFraction = 'Fraction of images used for validation during training';
            obj.BatchOpt.mibBatchTooltip.RandomGeneratorSeed = 'Seed for random number generator used during splitting of test and validation datasets';
            obj.BatchOpt.mibBatchTooltip.T_RandomGeneratorSeed = 'Seed for random number generator used during initialization of training. Use 0 for random initialization each time or any other number for reproducibility';
            obj.BatchOpt.mibBatchTooltip.MaskAway = 'Mask away areas that should not be used for training, requires MIB *.mask files next to the model files';
            obj.BatchOpt.mibBatchTooltip.SingleModelTrainingFile = 'When checked a single Model file with labels is used, when unchecked each image should have a corresponding model file with labels';
            obj.BatchOpt.mibBatchTooltip.ModelFilenameExtension = 'Extension for model filenames with labels, the files should be placed under "Labels" subfolder';
            obj.BatchOpt.mibBatchTooltip.MaskFilenameExtension = 'Extension for mask filenames, the files should be placed under "Masks" subfolder';
            obj.BatchOpt.mibBatchTooltip.P_MiniBatchSize = 'Number of patches processed simultaneously during prediction, increasing the MiniBatchSize value increases the efficiency, but it also takes up more GPU memory';
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
                obj.PatchPreviewOpt.noImages = 25;         % number of images in montage
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
                obj.SegmentationLayerOpt.focalLossLayer.Alpha = 2;
                obj.SegmentationLayerOpt.focalLossLayer.Gamma = 0.25;
            end
            
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
                
                obj.Start();
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
            %             global Font;
            %             if ~isempty(Font)
            %               if obj.View.handles.text1.FontSize ~= Font.FontSize ...
            %                     || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
            %                   mibUpdateFontSize(obj.View.gui, Font);
            %               end
            %             end
            
            obj.updateWidgets();
            
            % update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);

            obj.View.handles.PreprocessingParForWorkers.Limits = [0 obj.mibModel.cpuParallelLimit];  
            obj.View.handles.PreprocessingParForWorkers.Value = obj.mibModel.cpuParallelLimit;
            
            % generate colormaps
            obj.colormap6 = [166 67 33; 71 178 126; 79 107 171; 150 169 213; 26 51 111; 255 204 102 ]/255;
            obj.colormap20 = [230 25 75; 255 225 25; 0 130 200; 245 130 48; 145 30 180; 70 240 240; 240 50 230; 210 245 60; 250 190 190; 0 128 128; 230 190 255; 170 110 40; 255 250 200; 128 0 0; 170 255 195; 128 128 0; 255 215 180; 0 0 128; 128 128 128; 60 180 75]/255;
            obj.colormap255 = rand([255,3]);
            
            if isdeployed; obj.View.handles.ExportNetworkToONNXButton.Enable = 'off'; end
            
            obj.View.Figure.Figure.Visible = 'on';
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
            
            if gpuDeviceCount == 0
                obj.View.Figure.GPUDropDown.Items = {'CPU only'; 'Parallel'};
                uialert(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nYou do not have compatible CUDA card or driver,\nwithout those the training will be extrelemy slow!'), ...
                    'Missing GPU', 'icon', 'warning');
            else
                for deviceId = 1:gpuDeviceCount
                    gpuInfo = gpuDevice(deviceId);
                    gpuList{deviceId} = gpuInfo.Name; %#ok<AGROW>
                end
                if numel(gpuList) > 1; gpuList = gpuList'; end
                if gpuDeviceCount > 1
                    gpuList{end} = 'Multi-GPU';
                end
                gpuList = [gpuList; {'CPU only'}; {'Parallel'}];
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
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            
            % updateWidgets normally triggered during change of MIB
            % buffers, make sure that any widgets related changes are
            % correctly propagated into the BatchOpt structure
            if isfield(obj.BatchOpt, 'id'); obj.BatchOpt.id = obj.mibModel.Id; end
            
            % update lined widgets
            event.Source.Tag = 'BioformatsTraining';
            obj.BioformatsCallback(event);
            event.Source.Tag = 'Bioformats';
            obj.BioformatsCallback(event);
            
            if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')
                obj.View.Figure.P_OverlappingTiles.Enable = 'on';
            else    % valid
                obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                obj.View.Figure.P_OverlappingTiles.Value = false;
                obj.BatchOpt.P_OverlappingTiles = false;
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
            if foldersOk == 0
                warndlg(sprintf('!!! Warning !!!\n\nSome directories specified in the config file are missing!\nPlease check the directories in the Directories and Preprocessing tab'), 'Wrong directories');
            end
            
            if obj.View.handles.UseParallelComputing.Value
                obj.View.handles.PreprocessingParForWorkers.Enable = 'on';
            else
                obj.View.handles.PreprocessingParForWorkers.Enable = 'off';
            end
            
            % sync number of classes between training and preprocessing tabs
            obj.View.handles.NumberOfClassesPreprocessing.Value = obj.BatchOpt.T_NumberOfClasses{1};
            
            obj.ArchitectureValueChanged();
            obj.SingleModelTrainingFileValueChanged();
            
            % update preprocessing window widgets
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
                obj.View.handles.MaskAway.Enable = 'off';
                obj.View.handles.SingleModelTrainingFile.Enable = 'off';
                obj.View.handles.CompressProcessedImages.Enable = 'off';
                obj.View.handles.CompressProcessedModels.Enable = 'off';
                obj.View.handles.MaskFilenameExtension.Enable = 'off';
            else
                obj.View.handles.MaskAway.Enable = 'on';
                if obj.BatchOpt.Architecture{1}(1) == '2'
                    obj.View.handles.SingleModelTrainingFile.Enable = 'on';
                end
                obj.View.handles.CompressProcessedImages.Enable = 'on';
                obj.View.handles.CompressProcessedModels.Enable = 'on';
                obj.View.handles.MaskFilenameExtension.Enable = 'on';
            end
            
            if obj.BatchOpt.Architecture{1}(1) == '3'
                obj.View.handles.ModelFilenameExtension.Enable = 'off';
                obj.View.handles.MaskFilenameExtension.Enable = 'off';
            end
            
            % update widgets in Train panel
            obj.T_augmentationCallback();
            obj.T_ActivationLayerCallback();
            obj.T_SegmentationLayerCallback();
            
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
        end
        
        function T_ActivationLayerCallback(obj)
            % function T_ActivationLayerCallback(obj)
            % callback for modification of the Activation Layer dropdown
            
            switch obj.View.handles.T_ActivationLayer.Value
                case {'leakyReluLayer', 'clippedReluLayer', 'eluLayer'}
                    obj.View.handles.T_ActivationLayerSettings.Enable = 'on';
                otherwise
                    obj.View.handles.T_ActivationLayerSettings.Enable = 'off';
            end
            obj.BatchOpt.T_ActivationLayer{1} = obj.View.handles.T_ActivationLayer.Value;
        end
        
        function T_SegmentationLayerCallback(obj)
            % function T_SegmentationLayerCallback(obj)
            % callback for modification of the Segmentation Layer dropdown
            switch obj.View.handles.T_SegmentationLayer.Value
                case 'focalLossLayer'
                    obj.View.handles.T_SegmentationLayerSettings.Enable = 'on';
                otherwise   % classificationLayer, dicePixelClassificationLayer
                    obj.View.handles.T_SegmentationLayerSettings.Enable = 'off';
            end
            obj.BatchOpt.T_SegmentationLayer{1} = obj.View.handles.T_SegmentationLayer.Value;
        end
        
        function T_augmentationCallback(obj)
            % function T_augmentationCallback(obj)
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
                case 'Architecture'
                    switch obj.BatchOpt.Architecture{1}
                        case '2D SegNet'
                            obj.View.Figure.T_ConvolutionPadding.Value = 'same';
                            obj.View.Figure.T_ConvolutionPadding.Enable = 'off';
                            obj.BatchOpt.T_ConvolutionPadding{1} = 'same';
                            obj.View.Figure.P_OverlappingTiles.Enable = 'on';
                        otherwise
                            obj.View.Figure.T_ConvolutionPadding.Enable = 'on';
                    end
                case 'T_ConvolutionPadding'
                    if strcmp(event.Source.Value, 'same')
                        obj.View.Figure.P_OverlappingTiles.Enable = 'on';
                    else    % valid
                        obj.View.Figure.P_OverlappingTiles.Enable = 'off';
                        obj.View.Figure.P_OverlappingTiles.Value = false;
                        obj.BatchOpt.P_OverlappingTiles = false;
                    end
            end
        end
        
        function SingleModelTrainingFileValueChanged(obj, event)
            % function SingleModelTrainingFileValueChanged(obj, event)
            % callback for press of SingleModelTrainingFile
            
            if nargin < 2; event.Source = obj.View.handles.SingleModelTrainingFile; end
            
            obj.updateBatchOptFromGUI(event);
            if obj.BatchOpt.SingleModelTrainingFile
                obj.View.handles.ModelFilenameExtension.Enable = 'off';
                obj.View.handles.MaskFilenameExtension.Enable = 'off';
                obj.View.handles.NumberOfClassesPreprocessing.Enable = 'off';
                
                obj.View.handles.ModelFilenameExtension.Value = 'MODEL';
                obj.View.handles.MaskFilenameExtension.Value = 'MASK';
                event2.Source = obj.View.handles.ModelFilenameExtension;
                obj.updateBatchOptFromGUI(event2);
                event2.Source = obj.View.handles.MaskFilenameExtension;
                obj.updateBatchOptFromGUI(event2);
            else
                obj.View.handles.ModelFilenameExtension.Enable = 'on';
                obj.View.handles.MaskFilenameExtension.Enable = 'on';
                obj.View.handles.NumberOfClassesPreprocessing.Enable = 'on';
            end
        end
        
        function ArchitectureValueChanged(obj, event)
            % function ArchitectureValueChanged(obj, event)
            % callback for change of Architecture
            if nargin < 2; event.Source = obj.View.handles.Architecture; end
            obj.updateBatchOptFromGUI(event);
            
            if obj.BatchOpt.Architecture{1}(1) == '3' % 3D nets
                obj.View.handles.SingleModelTrainingFile.Value = 1;
                event2.Source = obj.View.handles.SingleModelTrainingFile;
                obj.SingleModelTrainingFileValueChanged(event2);    % callback for press of Single MIB model checkbox
                obj.View.handles.SingleModelTrainingFile.Enable = 'off';
                obj.View.handles.SingleModelTrainingFile.Value = false;
                obj.BatchOpt.SingleModelTrainingFile = false;
            else    % 2D nets
                obj.View.handles.SingleModelTrainingFile.Enable = 'on';
                if obj.View.handles.SingleModelTrainingFile.Value == false
                    obj.View.handles.ModelFilenameExtension.Enable = 'on';
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
        
        function BioformatsCallback(obj, event)
            % function BioformatsCallback(obj, event)
            % update available filename extensions
            %
            % Parameters:
            % event: an event structure of appdesigner
            
            extentionFieldName = 'ImageFilenameExtension';
            bioformatsFileName = 'Bioformats';
            indexFieldName = 'BioformatsIndex';
            if strcmp(event.Source.Tag, 'BioformatsTraining')
                extentionFieldName = 'ImageFilenameExtensionTraining';
                bioformatsFileName = 'BioformatsTraining';
                indexFieldName = 'BioformatsTrainingIndex';
            end
            
            if obj.BatchOpt.(bioformatsFileName)    % bio formats checkbox ticked
                obj.BatchOpt.(extentionFieldName){2} = upper(obj.mibModel.preferences.System.Files.BioFormatsExt); %{'.LEI', '.ZVI''};
                obj.View.handles.(indexFieldName).Enable = 'on';
            else
                obj.BatchOpt.(extentionFieldName){2} = upper(obj.mibModel.preferences.System.Files.StdExt); %{'.AM', '.PNG', '.TIF'};
                obj.View.handles.(indexFieldName).Enable = 'off';
            end
            if ~ismember(obj.BatchOpt.(extentionFieldName)(1), obj.BatchOpt.(extentionFieldName){2})
                obj.BatchOpt.(extentionFieldName)(1) = obj.BatchOpt.(extentionFieldName){2}(1);
            end
            
            obj.View.Figure.(extentionFieldName).Items = obj.BatchOpt.(extentionFieldName){2};
            obj.View.Figure.(extentionFieldName).Value = obj.BatchOpt.(extentionFieldName){1};
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
                        if file == 0; return; end
                        networkName = fullfile(path, file);
                    end
                    if exist(networkName, 'file') ~= 2
                        errordlg(sprintf('!!! Error !!!\n\nThe provided file does not exist!\n\n%s', networkName), 'Wrong network name');
                        obj.View.Figure.NetworkFilename.Value = obj.BatchOpt.NetworkFilename;
                        return;
                    end
                    
                    obj.wb = waitbar(0, sprintf('Loadning the network\nPlease wait...'));
                    
                    res = load(networkName, '-mat');     % loading 'net', 'TrainingOptions', 'classNames' variables
                    net = res.net;   % generate output network
                    
                    % add/update BatchOpt with the provided fields in BatchOptIn
                    % combine fields from input and default structures
                    res.BatchOpt = rmfield(res.BatchOpt, ...
                        {'NetworkFilename', 'Mode', 'OriginalTrainingImagesDir', 'OriginalPredictionImagesDir', ...
                        'ResultingImagesDir', 'PreprocessingMode', 'CompressProcessedImages', 'showWaitbar', ...
                        'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'});
                    
                    % DELETE THIS LATER, it is for older extension dialog
                    % with front dot
                    %if res.BatchOpt.ImageFilenameExtension{1}(1) == '.'; res.BatchOpt.ImageFilenameExtension{1} = res.BatchOpt.ImageFilenameExtension{1}(2:end); end
                    
                    obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, res.BatchOpt);
                    
                    try
                        if isfield(res.AugOpt2DStruct, 'ImageBlur') == 0
                            importFields = fieldnames(res.AugOpt2DStruct);
                            for fieldId = 1:length(importFields)
                                obj.AugOpt2D.(importFields{fieldId}) = res.AugOpt2DStruct.(importFields{fieldId});
                            end
                            uialert(obj.View.gui, sprintf('!!! Warning !!!\n\nYou are loading an old config file with a smaller number of augmentation options.\nThe loaded settings were merged with the current ones!'), 'Merge augmentation settings', 'icon', 'warning');
                        else
                            obj.AugOpt2D = res.AugOpt2DStruct;
                        end
                        obj.TrainingOpt = res.TrainingOptStruct;
                        if strcmp(obj.TrainingOpt.Plots, 'training-progress-Matlab'); obj.TrainingOpt.Plots = 'training-progress'; end
                        obj.InputLayerOpt = res.InputLayerOpt;
                        obj.AugOpt3D = res.AugOpt3DStruct;
                        
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
                    
                    waitbar(1, obj.wb);
                    delete(obj.wb);
                case 'Train'
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
        end
        
        function SelectDirerctories(obj, event)
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
        
        function ImageDirectoriesValueChanged(obj, event)
            fieldName = event.Source.Tag;
            value = obj.View.Figure.(fieldName).Value;
            if isfolder(value) == 0; obj.View.Figure.(fieldName).Value = obj.BatchOpt.(fieldName); return; end
            obj.BatchOpt.(fieldName) = value;
        end
        
        function CheckNetwork(obj)
            obj.wb = waitbar(0, sprintf('Generating network\nPlease wait...'));
            previewSwitch = 1;  % indicate that the network is only for preview, the weights of classes won't be calculated
            [lgraph, outputPatchSize] = obj.createNetwork(previewSwitch);
            if isempty(lgraph); return; end
            waitbar(0.6, obj.wb);
            if ~isdeployed
                analyzeNetwork(lgraph);
            else
                lgraph.Layers
                figure;
                plot(lgraph);
                msgbox(sprintf('!!! Warning !!!\n\nThe network preview is limited in the standalone version of MIB\n\nInput patch size: %s\nOutput patch size: %s', obj.BatchOpt.T_InputPatchSize, num2str(outputPatchSize)), 'Info');
            end
            waitbar(0.6, obj.wb);
            delete(obj.wb);
        end
        
        %%
        function [lgraph, outputPatchSize] = createNetwork(obj, previewSwitch)
            % function lgraph = createNetwork(obj, previewSwitch)
            % generate network
            % Parameters:
            % previewSwitch: logical switch, when 1 - the generated network
            % is only for preview, i.e. weights of classes won't be
            % calculated
            %
            % Return values:
            % lgraph: network object
            % outputPatchSize: output patch size as [height, width, depth, color]
            
            if nargin < 2; previewSwitch = 0; end
            lgraph = [];
            outputPatchSize = [];
            InputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);    % as [height, width, depth, color]
            
            try
                switch obj.BatchOpt.Architecture{1}
                    case '3D U-net Anisotropic'
                        % 3D U-net for anisotropic datasets, the first
                        % convolutional and max pooling layers are 2D
                        
                        % [lgraph, outputPatchSize] = create3DUnetAnisotripic(obj.BatchOpt, obj.InputLayerOpt);
                        switch obj.BatchOpt.T_ConvolutionPadding{1}
                            case 'same'
                                PaddingValue = 'same';
                            case 'valid'
                                PaddingValue = 0;
                        end
                        
                        % generate standard 3D Unet
                        [lgraph, outputPatchSize] = unet3dLayers(...
                            InputPatchSize, obj.BatchOpt.T_NumberOfClasses{1}, ...
                            'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
                            'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, 'EncoderDepth', obj.BatchOpt.T_EncoderDepth{1});
                        
                        % replace first convolution layers of the 1 lvl of the net
                        %lgraph.Layers(2).Name
                        layerId = find(ismember({lgraph.Layers.Name}, 'Encoder-Stage-1-Conv-1')==1);
                        layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                            'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                        lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                        
                        layerId = find(ismember({lgraph.Layers.Name}, 'Encoder-Stage-1-Conv-2')==1);
                        layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                            'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                        lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                        
                        
                        layerId = find(ismember({lgraph.Layers.Name}, 'Encoder-Stage-1-MaxPool')==1);
                        layer = maxPooling3dLayer([2 2 1], ...
                            'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name, ...
                            'Stride', [2 2 1]);
                        lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                        
                        %analyzeNetwork(lgraph);
                        % get index of the final convolution layer
                        finalConvId = find(ismember({lgraph.Layers.Name}, 'Final-ConvolutionLayer')==1);
                        % using name of the previous level find index of the last decoder stage
                        layerName = lgraph.Layers(finalConvId-1).Name;  % 'Decoder-Stage-2-ReLU-2'
                        dashIds = strfind(layerName, '-');  % positions of dashes
                        stageId = layerName(dashIds(2)+1:dashIds(3)-1);     % get stage id
                        
                        layerId = find(ismember({lgraph.Layers.Name}, sprintf('Decoder-Stage-%s-UpConv', stageId))==1);
                        layer = transposedConv3dLayer([2 2 1], lgraph.Layers(layerId).NumFilters, ...
                            'Stride', [2 2 1], 'Name', lgraph.Layers(layerId).Name);
                        lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                        
                        layerId = find(ismember({lgraph.Layers.Name}, sprintf('Decoder-Stage-%s-Conv-1', stageId))==1);
                        layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                            'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                        lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                        
                        layerId = find(ismember({lgraph.Layers.Name}, sprintf('Decoder-Stage-%s-Conv-2', stageId))==1);
                        layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                            'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                        lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                        
                        % update the input layer settings
                        switch obj.InputLayerOpt.Normalization
                            case 'zerocenter'
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 1 numel(obj.InputLayerOpt.Mean)]));
                            case 'zscore'
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]),...
                                    'StandardDeviation', reshape(obj.InputLayerOpt.StandardDeviation, [1 1 1 numel(obj.InputLayerOpt.StandardDeviation)]));
                            case {'rescale-symmetric', 'rescale-zero-one'}
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Min', reshape(obj.InputLayerOpt.Min, [1 1 1 numel(obj.InputLayerOpt.Min)]), ...
                                    'Max', reshape(obj.InputLayerOpt.Max, [1 1 1 numel(obj.InputLayerOpt.Max)]));
                            case 'none'
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization);
                            otherwise
                                errordlg(sprintf('!!! Error !!!\n\nWrong normlization paramter (%s)!\n\nUse one of those:\n - zerocenter\n - zscore\n - rescale-symmetric\n - rescale-zero-one\n - none', obj.InputLayerOpt.Normalization), 'Wrong normalization');
                                return;
                        end
                        lgraph = replaceLayer(lgraph, 'ImageInputLayer', inputLayer);
                        if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                            outputPatchSize = [];
                            %                             TrainingOptions = trainingOptions('adam', ...
                            %                                 'MaxEpochs', 1, ...
                            %                                 'Shuffle', 'never', ...
                            %                                 'Verbose', 0, ...
                            %                                 'MiniBatchSize', 1);
                            %
                            %                             imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'), ...
                            %                                 'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
                            %                             % get class names
                            %                             files = dir([obj.BatchOpt.OriginalTrainingImagesDir, filesep '*.model']);
                            %                             modelFn = fullfile(files(1).folder, files(1).name);
                            %                             res = load(modelFn, '-mat', 'modelMaterialNames', 'modelMaterialColors');
                            %                             classColors = res.modelMaterialColors;  % get colors
                            %                             classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                            %                             pixelLabelID = 0:numel(classNames) - 1;
                            %                             labelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'), ...
                            %                                 classNames, pixelLabelID, 'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
                            %                             patchDS = randomPatchExtractionDatastore(imgDS, labelsDS, InputPatchSize(1:3), ...
                            %                                 'PatchesPerImage', 1, 'PatchesPerImage', 1);
                            %                             AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, InputPatchSize(1:3), outputPatchSize, 1));
                            %
                            %                             [net, info] = trainNetwork(patchDS, lgraph, TrainingOptions);
                            %                             imageActivation = activations(lgraph, imgBlock, obj.BatchOpt.NetworkLayerName{1});
                        end
                    case '3D U-net'
                        [lgraph, outputPatchSize] = unet3dLayers(...
                            InputPatchSize, obj.BatchOpt.T_NumberOfClasses{1}, ...
                            'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
                            'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, 'EncoderDepth', obj.BatchOpt.T_EncoderDepth{1}); %#ok<*ST2NM>
                        
                        % update the input layer settings
                        switch obj.InputLayerOpt.Normalization
                            case 'zerocenter'
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 1 numel(obj.InputLayerOpt.Mean)]));
                            case 'zscore'
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]),...
                                    'StandardDeviation', reshape(obj.InputLayerOpt.StandardDeviation, [1 1 1 numel(obj.InputLayerOpt.StandardDeviation)]));
                            case {'rescale-symmetric', 'rescale-zero-one'}
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Min', reshape(obj.InputLayerOpt.Min, [1 1 1 numel(obj.InputLayerOpt.Min)]), ...
                                    'Max', reshape(obj.InputLayerOpt.Max, [1 1 1 numel(obj.InputLayerOpt.Max)]));
                            case 'none'
                                inputLayer = image3dInputLayer(InputPatchSize, 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization);
                            otherwise
                                errordlg(sprintf('!!! Error !!!\n\nWrong normlization paramter (%s)!\n\nUse one of those:\n - zerocenter\n - zscore\n - rescale-symmetric\n - rescale-zero-one\n - none', obj.InputLayerOpt.Normalization), 'Wrong normalization');
                                return;
                        end
                        lgraph = replaceLayer(lgraph, 'ImageInputLayer', inputLayer);
                    case '2D U-net'
                        [lgraph, outputPatchSize] = unetLayers(...
                            InputPatchSize([1 2 4]), obj.BatchOpt.T_NumberOfClasses{1}, ...
                            'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
                            'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, 'EncoderDepth', obj.BatchOpt.T_EncoderDepth{1}); %#ok<*ST2NM>
                        outputPatchSize = [outputPatchSize(1), outputPatchSize(2), 1, outputPatchSize(3)];  % reformat to [height, width, depth, color]
                        
                        % update the input layer settings
                        switch obj.InputLayerOpt.Normalization
                            case 'zerocenter'
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]));
                            case 'zscore'
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]), ...
                                    'StandardDeviation', reshape(obj.InputLayerOpt.StandardDeviation, [1 1 numel(obj.InputLayerOpt.StandardDeviation)]));
                            case {'rescale-symmetric', 'rescale-zero-one'}
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Min', reshape(obj.InputLayerOpt.Min, [1 1 numel(obj.InputLayerOpt.Min)]), ...
                                    'Max', reshape(obj.InputLayerOpt.Max, [1 1 numel(obj.InputLayerOpt.Max)]));
                            case 'none'
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization);
                            otherwise
                                errordlg(sprintf('!!! Error !!!\n\nWrong normlization paramter (%s)!\n\nUse one of those:\n - zerocenter\n - zscore\n - rescale-symmetric\n - rescale-zero-one\n - none', obj.InputLayerOpt.Normalization), 'Wrong normalization');
                                return;
                        end
                        lgraph = replaceLayer(lgraph, 'ImageInputLayer', inputLayer);
                        
                    case '2D SegNet'
                        lgraph = segnetLayers(InputPatchSize([1 2 4]), obj.BatchOpt.T_NumberOfClasses{1}, obj.BatchOpt.T_EncoderDepth{1}, ...
                            'NumOutputChannels', obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                            'FilterSize', obj.BatchOpt.T_FilterSize{1});
                        outputPatchSize = InputPatchSize;  % as [height, width, depth, color]
                        
                        % update the input layer settings
                        switch obj.InputLayerOpt.Normalization
                            case 'zerocenter'
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]));
                            case 'zscore'
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]), ...
                                    'StandardDeviation', reshape(obj.InputLayerOpt.StandardDeviation, [1 1 numel(obj.InputLayerOpt.StandardDeviation)]));
                            case {'rescale-symmetric', 'rescale-zero-one'}
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization, ...
                                    'Min', reshape(obj.InputLayerOpt.Min, [1 1 numel(obj.InputLayerOpt.Min)]), ...
                                    'Max', reshape(obj.InputLayerOpt.Max, [1 1 numel(obj.InputLayerOpt.Max)]));
                            case 'none'
                                inputLayer = imageInputLayer(InputPatchSize([1 2 4]), 'Name', 'ImageInputLayer', ...
                                    'Normalization', obj.InputLayerOpt.Normalization);
                        end
                        lgraph = replaceLayer(lgraph, 'inputImage', inputLayer);
                        
                end     % end of switch obj.BatchOpt.Architecture{1}
            catch err
                delete(obj.wb);
                warndlg(err.message, 'Network configuration error');
                return;
            end
            
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
                        case 'tanhLayer'
                            layer = tanhLayer('Name', sprintf('Tahn-%d', id));
                    end
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);
                end
            end
            
            % redefine the last layer
            if ~strcmp(obj.BatchOpt.T_SegmentationLayer{1}, 'pixelClassificationLayer')
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
                        switch obj.BatchOpt.Architecture{1}
                            case {'3D U-net', '3D U-net Anisotropic'}
                                outputLayerName = 'Custom Dice Segmentation Layer 3D';
                            case {'2D U-net', '2D SegNet'}
                                outputLayerName = 'Custom Dice Segmentation Layer 2D';
                        end
                        outputLayer = dicePixelCustomClassificationLayer(outputLayerName);
                        
                        % check layer
                        %layer = dicePixelCustomClassificationLayer(outputLayerName);
                        %numClasses = 4;
                        %validInputSize = [4 4 numClasses];
                        %checkLayer(layer,validInputSize, 'ObservationDimension',4)
                        
                    case 'focalLossLayer'
                        segLayerInitString = sprintf('outputLayer = %s(''Alpha'', %.3f, ''Gamma'', %.3f, ''Name'', ''Segmentation-Layer'');', ...
                            obj.BatchOpt.T_SegmentationLayer{1}, ...
                            obj.SegmentationLayerOpt.focalLossLayer.Alpha, obj.SegmentationLayerOpt.focalLossLayer.Gamma);
                        eval(segLayerInitString);
                    otherwise
                        segLayerInitString = sprintf('outputLayer = %s(''Name'', ''Segmentation-Layer'');', obj.BatchOpt.T_SegmentationLayer{1});
                        eval(segLayerInitString);
                end
                switch obj.BatchOpt.Architecture{1}
                    case {'3D U-net', '2D U-net'}
                        lgraph = replaceLayer(lgraph, 'Segmentation-Layer', outputLayer);
                    case '2D SegNet'
                        lgraph = replaceLayer(lgraph, 'pixelLabels', outputLayer);
                end
                
            else
                %outputLayer = pixelClassificationLayer('Name', 'Segmentation-Layer2', 'Classes', {'Exterior', 'Triangles'});
                %lgraph = replaceLayer(lgraph, 'Segmentation-Layer', outputLayer);
            end
        end
        
        function status = setAug2DFuncHandles(obj, inputPatchSize)
            % function status = setAug2DFuncHandles(obj, inputPatchSize)
            % define list of 2D augmentation functions
            %
            % Parameters:
            % inputPatchSize: input patch size as [height, width, depth, color]
            %
            % Return values:
            % status: a logical success switch (1-success, 0- fail)
            status = 0;
            
            obj.Aug2DFuncNames = [];
            obj.Aug2DFuncProbability = [];  % probability of each augmentation to be triggered
            
            if numel(obj.AugOpt2D.RandXReflection) == 1
                augFields = fieldnames(obj.AugOpt2D);
                augList = '';
                for fieldId = 1:numel(augFields)
                    augList = sprintf('%s\n%s: %s', augList, augFields{fieldId}, num2str(obj.AugOpt2D.(augFields{fieldId})));
                end
                
                msgText = sprintf('!!! Error !!!\n\nThe settings for the data augmentation are not compatible with the current version of MIB!\n\nTo proceed further reset the augmentations using:\nOptions tab->Reset 2D augmentation\nand reconfigure them using Training tab->2D augmentation settings!\n\nCurrent settings are: %s', augList);
                res = uiconfirm(obj.View.gui, ...
                    msgText, ...
                    'Incompatible augmentations', ...
                    'Options', {'Copy message to clipboard','Close'}, ...
                    'Icon', 'error');
                if strcmp(res, 'Copy message to clipboard');  clipboard('copy', msgText); end
                return;
            end
            
            % X-reflections, 0-off or 1-on
            if obj.AugOpt2D.RandXReflection(1) == 1 && obj.AugOpt2D.RandXReflection(2) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandXReflection'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandXReflection(2)];
            end
            
            % Y-reflections, 0-off or 1-on
            if obj.AugOpt2D.RandYReflection(1) == 1 && obj.AugOpt2D.RandYReflection(2) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandYReflection'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandYReflection(2)];
            end
            
            % 90 and 270 degree rotations, 0-off or 1-on
            if obj.AugOpt2D.Rotation90(1) == 1 && obj.AugOpt2D.Rotation90(2) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'Rotation90'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.Rotation90(2)];
            end
            
            % reflected rotations, 0-off or 1-on
            if obj.AugOpt2D.ReflectedRotation90(1) == 1 && obj.AugOpt2D.ReflectedRotation90(2) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'ReflectedRotation90'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.ReflectedRotation90(2)];
            end
            
            % random rotation
            if (obj.AugOpt2D.RandRotation(1) ~= 0 || obj.AugOpt2D.RandRotation(2) ~= 0) && obj.AugOpt2D.RandRotation(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandRotation'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandRotation(3)];
            end
            
            % random scale
            if (obj.AugOpt2D.RandScale(1) ~= 1 || obj.AugOpt2D.RandScale(2) ~= 1) && obj.AugOpt2D.RandScale(3)  > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandScale'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandScale(3)];
            end
            
            % random x scale
            if (obj.AugOpt2D.RandXScale(1) ~= 1 || obj.AugOpt2D.RandXScale(2) ~= 1) && obj.AugOpt2D.RandXScale(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandXScale'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandXScale(3)];
            end
            
            % random y scale
            if (obj.AugOpt2D.RandYScale(1) ~= 1 || obj.AugOpt2D.RandYScale(2) ~= 1) && obj.AugOpt2D.RandYScale(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandYScale'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandYScale(3)];
            end
            
            % random xshear
            if (obj.AugOpt2D.RandXShear(1) ~= 0 || obj.AugOpt2D.RandXShear(2) ~= 0) && obj.AugOpt2D.RandXShear(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandXShear'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandXShear(3)];
            end
            
            % random yshear
            if (obj.AugOpt2D.RandYShear(1) ~= 0 || obj.AugOpt2D.RandYShear(2) ~= 0) && obj.AugOpt2D.RandYShear(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'RandYShear'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.RandYShear(3)];
            end
            
            % Gaussian image noise
            if (obj.AugOpt2D.GaussianNoise(1) ~= 0 || obj.AugOpt2D.GaussianNoise(2) ~= 0) && obj.AugOpt2D.GaussianNoise(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'GaussianNoise'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.GaussianNoise(3)];
            end
            
            % Poisson image noise
            if obj.AugOpt2D.PoissonNoise(1) == 1 && obj.AugOpt2D.PoissonNoise(2) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'PoissonNoise'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.PoissonNoise(2)];
            end
            
            % random Hue jitter
            if (obj.AugOpt2D.HueJitter(1) ~= 0 || obj.AugOpt2D.HueJitter(2) ~= 0) && inputPatchSize(4) == 3 && obj.AugOpt2D.HueJitter(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'HueJitter'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.HueJitter(3)];
            end
            
            % random Saturation jitter
            if (obj.AugOpt2D.SaturationJitter(1) ~= 0 || obj.AugOpt2D.SaturationJitter(2) ~= 0) && inputPatchSize(4) == 3 && obj.AugOpt2D.SaturationJitter(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'SaturationJitter'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.SaturationJitter(3)];
            end
            
            % random Brightness jitter
            if (obj.AugOpt2D.BrightnessJitter(1) ~= 0 || obj.AugOpt2D.BrightnessJitter(2) ~= 0) &&  obj.AugOpt2D.BrightnessJitter(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'BrightnessJitter'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.BrightnessJitter(3)];
            end
            
            % random Contrast jitter
            if (obj.AugOpt2D.ContrastJitter(1) ~= 1 || obj.AugOpt2D.ContrastJitter(2) ~= 1) && obj.AugOpt2D.ContrastJitter(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'ContrastJitter'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.ContrastJitter(3)];
            end
            
            % random image blur jitter
            if (obj.AugOpt2D.ImageBlur(1) ~= 0 || obj.AugOpt2D.ImageBlur(2) ~= 0) && obj.AugOpt2D.ImageBlur(3) > 0
                obj.Aug2DFuncNames = [obj.Aug2DFuncNames, {'ImageBlur'}];
                obj.Aug2DFuncProbability = [obj.Aug2DFuncProbability, obj.AugOpt2D.ImageBlur(3)];
            end
            
            if isempty(obj.Aug2DFuncNames)
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nAugmentation filters were not selected or their probabilities are zero!\nPlease use set 2D augmentation settings dialog (Train tab->Augmentation->2D) to set them up'), ...
                    'Wrong augmentations');
                return;
            end
            status = 1;
        end
        
        
        function status = setAug3DFuncHandles(obj, inputPatchSize)
            % function status = setAug3DFuncHandles(obj, inputPatchSize)
            % define list of 3D augmentation functions
            %
            % Parameters:
            % inputPatchSize: input patch size as [height, width, depth, color]
            %
            % Return values:
            % status: a logical success switch (1-success, 0- fail)
            status = 0;
            obj.Aug3DFuncNames = [];
            
            % X-reflections, true or false
            if obj.AugOpt3D.RandXReflection
                obj.Aug3DFuncNames = [obj.Aug3DFuncNames, {'RandXReflection'}];
            end
            
            % Y-reflections, true or false
            if obj.AugOpt3D.RandYReflection
                obj.Aug3DFuncNames = [obj.Aug3DFuncNames, {'RandYReflection'}];
            end
            
            if obj.AugOpt3D.RandZReflection
                obj.Aug3DFuncNames = [obj.Aug3DFuncNames, {'RandZReflection'}];
            end
            
            if obj.AugOpt3D.Rotation90
                obj.Aug3DFuncNames = [obj.Aug3DFuncNames, {'Rotation90'}];
            end
            
            if obj.AugOpt3D.ReflectedRotation90
                obj.Aug3DFuncNames = [obj.Aug3DFuncNames, {'ReflectedRotation90'}];
            end
            
            if isempty(obj.Aug3DFuncNames)
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nAugmentation types were not selected!\nPlease use set 3D augmentation settings dialog'), ...
                    'Wrong augmentations');
                return;
            end
            status = 1;
            
        end
        
        function [patchOut, augList, augPars] = augmentAndCrop2dPatch(obj, patchIn, inputPatchSize, outputPatchSize, mode)
            % function [patchOut, augList, augPars] = augmentAndCrop2dPatch(obj, patchIn, inputPatchSize, outputPatchSize, mode)
            %
            % Augment training data by set of operations encoded in
            % obj.AugOpt2D and/or crop the response to the network's output size.
            %
            % Parameters:
            % patchIn:
            % inputPatchSize: input patch size as [height, width, depth, color]
            % outputPatchSize: output patch size as [height, width, depth, classes]
            % mode: string
            % 'show' - do not transform/augment, do not crop, only show
            % 'crop' - do not transform/augment, only crop and show
            % 'aug' - transform/augment, crop and show
            %
            % Return values:
            % patchOut: return the image patches in a two-column table as required by the trainNetwork function for
            % single-input networks.
            % augList: cell array with used augmentation operations
            % augPars: matrix with used values, NaN if the value was not
            % used, the second column is the parameter for blend of Hue+Sat
            % jitters
            
            augList = {};    % list of used aug functions
            augPars = [];       % array with used parameters
            
            if obj.TrainingProgress.emergencyBrake == 1   % stop training, return. This function is still called multiple times after stopping the training
                patchOut = [];
                return;
            end
            
            if ismember('ResponsePixelLabelImage', patchIn.Properties.VariableNames)  % this one for pixelLabelDatastore
                fieldId = 'ResponsePixelLabelImage';
            else    % this one for imageDatastore
                fieldId = 'ResponseImage';
            end
            
            if strcmp(mode, 'show')
                inpVol = patchIn.InputImage;
                inpResponse = patchIn.(fieldId);
            else
                numAugFunc = numel(obj.Aug2DFuncNames);    % number of functions to be used
                
                inpVol = cell(size(patchIn,1), 1);
                inpResponse = cell(size(patchIn,1), 1);
                augList = cell(size(patchIn,1), 1);
                augPars = nan([size(patchIn,1), 17]); % allocate space for augmentation parameters
                
                diffPatchY = (inputPatchSize(1)-outputPatchSize(1))/2;
                diffPatchX = (inputPatchSize(2)-outputPatchSize(2))/2;
                
                cropSwitch = 0;
                if diffPatchY ~=0 || diffPatchX ~=0
                    y1 = diffPatchY+1;
                    y2 = inputPatchSize(1)-diffPatchY;
                    x1 = diffPatchX+1;
                    x2 = inputPatchSize(2)-diffPatchX;
                    cropSwitch = 1;   % crop resulting image to match output patch
                end
                
                for id=1:size(patchIn, 1)
                    if strcmp(mode, 'crop')  % do only crop
                        if cropSwitch
                            inpResponse{id, 1} = patchIn.(fieldId){id}(y1:y2, x1:x2, :, :);
                        else
                            inpResponse{id, 1} = patchIn.(fieldId){id};
                        end
                        inpVol{id, 1}= patchIn.InputImage{id};
                    else    % augment and crop
                        rndIdx = randi(100, 1)/100;
                        if rndIdx > obj.AugOpt2D.Fraction   % if index lower than obj.AugOpt2D.Fraction -> augment the data
                            out =  patchIn.InputImage{id};
                            respOut = patchIn.(fieldId){id};
                            augList{id} = {'Original'};
                        else
                            if numAugFunc == 0
                                uialert(obj.View.gui, ...
                                    sprintf('!!! Error !!!\n\nThe augmentation functions were not selected!'), ...
                                    'Missing augmentation fuctions');
                                return;
                            end
                            
                            % find augmentations, based on probability
                            if numAugFunc > 1   % calculate only for number of aug. filters > 1
                                notOk = 1;
                                while notOk
                                    randVector = rand([2, numAugFunc]);
                                    randVector(2,:) = obj.Aug2DFuncProbability;
                                    [~, index] = min(randVector, [], 1);
                                    augFuncIndeces = find(index == 1);
                                    if numel(augFuncIndeces)>0; notOk = 0; end
                                end
                            else
                                augFuncIndeces = 1;
                            end
                            
                            augList{id} = obj.Aug2DFuncNames(augFuncIndeces);
                            out = patchIn.InputImage{id};
                            respOut = patchIn.(fieldId){id};
                            for augId = 1:numel(augList{id})
                                switch augList{id}{augId}
                                    case 'RandXReflection'
                                        out = fliplr(out);
                                        respOut = fliplr(respOut);
                                    case 'RandYReflection'
                                        out = flipud(out);
                                        respOut = flipud(respOut);
                                    case 'Rotation90'
                                        if randi(2) == 1
                                            out = rot90(out);
                                            respOut = rot90(respOut);
                                        else
                                            out = rot90(out,3);
                                            respOut = rot90(respOut,3);
                                        end
                                    case 'ReflectedRotation90'
                                        out = rot90(fliplr(out));
                                        respOut = rot90(fliplr(respOut));
                                    case 'RandRotation'
                                        augPars(id,augId) = obj.AugOpt2D.RandRotation(1) + (obj.AugOpt2D.RandRotation(2)-obj.AugOpt2D.RandRotation(1))*rand;
                                        tform = randomAffine2d('Rotation', [augPars(id,augId) augPars(id,augId)]);
                                        outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                        out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                        respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView);
                                    case 'RandScale'
                                        augPars(id,augId) = obj.AugOpt2D.RandScale(1) + (obj.AugOpt2D.RandScale(2)-obj.AugOpt2D.RandScale(1))*rand;
                                        tform = randomAffine2d('Scale', [augPars(id,augId) augPars(id,augId)]);
                                        outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                        out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                        respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView);
                                    case 'RandXScale'
                                        augPars(id,augId) = obj.AugOpt2D.RandXScale(1) + (obj.AugOpt2D.RandXScale(2)-obj.AugOpt2D.RandXScale(1))*rand;
                                        T = [augPars(id,augId) 0 0; 0 1 0; 0 0 1];
                                        tform = affine2d(T);
                                        outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                        out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                        respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView);
                                    case 'RandYScale'
                                        augPars(id,augId) = obj.AugOpt2D.RandYScale(1) + (obj.AugOpt2D.RandYScale(2)-obj.AugOpt2D.RandYScale(1))*rand;
                                        T = [1 0 0; 0 augPars(id,augId) 0; 0 0 1];
                                        tform = affine2d(T);
                                        outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                        out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                        respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView);
                                    case 'RandXShear'
                                        augPars(id,augId) = obj.AugOpt2D.RandXShear(1) + (obj.AugOpt2D.RandXShear(2)-obj.AugOpt2D.RandXShear(1))*rand;
                                        tform = randomAffine2d('XShear', [augPars(id,augId) augPars(id,augId)]);
                                        outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                        out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                        respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView);
                                    case 'RandYShear'
                                        augPars(id,augId) = obj.AugOpt2D.RandYShear(1) + (obj.AugOpt2D.RandYShear(2)-obj.AugOpt2D.RandYShear(1))*rand;
                                        tform = randomAffine2d('YShear', [augPars(id,augId) augPars(id,augId)]);
                                        outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                        out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                        respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView);
                                    case 'GaussianNoise'
                                        augPars(id,augId) = obj.AugOpt2D.GaussianNoise(1) + (obj.AugOpt2D.GaussianNoise(2)-obj.AugOpt2D.GaussianNoise(1))*rand;
                                        out =  imnoise(out, 'gaussian', 0, augPars(id,augId));
                                        %respOut = patchIn.(fieldId){id};
                                    case 'PoissonNoise'
                                        out =  imnoise(out, 'poisson');
                                        %respOut = patchIn.(fieldId){id};
                                    case 'HueJitter'
                                        if size(out, 3) == 3
                                            augPars(id,augId) = obj.AugOpt2D.HueJitter(1) + (obj.AugOpt2D.HueJitter(2)-obj.AugOpt2D.HueJitter(1))*rand;
                                            out = jitterColorHSV(out, 'Hue', [augPars(id,augId) augPars(id,augId)]);
                                            %else
                                            %    out = out;
                                        end
                                        %respOut = patchIn.(fieldId){id};
                                    case 'SaturationJitter'
                                        if size(out, 3) == 3
                                            augPars(id,augId) = obj.AugOpt2D.SaturationJitter(1) + (obj.AugOpt2D.SaturationJitter(2)-obj.AugOpt2D.SaturationJitter(1))*rand;
                                            out = jitterColorHSV(out, 'Saturation', [augPars(id,augId) augPars(id,augId)]);
                                            %else
                                            %    out = patchIn.InputImage{id};
                                        end
                                        %respOut = patchIn.(fieldId){id};
                                    case 'BrightnessJitter'
                                        augPars(id,augId) = obj.AugOpt2D.BrightnessJitter(1) + (obj.AugOpt2D.BrightnessJitter(2)-obj.AugOpt2D.BrightnessJitter(1))*rand;
                                        if size(out, 3) == 3
                                            out = jitterColorHSV(out, 'Brightness', [augPars(id,augId) augPars(id,augId)]);
                                        else
                                            out = out + augPars(id,augId)*255;
                                        end
                                        %respOut = patchIn.(fieldId){id};
                                    case 'ContrastJitter'
                                        augPars(id,augId) = obj.AugOpt2D.ContrastJitter(1) + (obj.AugOpt2D.ContrastJitter(2)-obj.AugOpt2D.ContrastJitter(1))*rand;
                                        if size(out, 3) == 3
                                            out = jitterColorHSV(out, 'Contrast', [augPars(id,augId) augPars(id,augId)]);
                                        else
                                            out = out.*augPars(id,augId);
                                        end
                                        %respOut = patchIn.(fieldId){id};
                                    case 'ImageBlur'
                                        augPars(id,augId) = obj.AugOpt2D.ImageBlur(1) + (obj.AugOpt2D.ImageBlur(2)-obj.AugOpt2D.ImageBlur(1))*rand;
                                        out =  imgaussfilt(out, augPars(id,augId));
                                        %respOut = patchIn.(fieldId){id};
                                end
                            end
                        end
                        
                        if cropSwitch
                            inpResponse{id, 1} = respOut(y1:y2, x1:x2, :, :);
                        else
                            inpResponse{id, 1} = respOut;
                        end
                        inpVol{id, 1} = out;
                        
                    end
                end
            end
            
            %             global counter
            %             figure(1)
            %             imshow(inpVol{1, 1});
            %             for ii=1:numel(inpVol)
            %                 fn = sprintf('d:\\Matlab\\Data\\DeepMIB_patch_Test\\PatchOut\\Case1\\patch_%.2d.tif', counter);
            %                 imwrite(inpVol{1, 1}, fn, 'tif');
            %                 counter = counter + 1
            %             end
            
            %             if counter == 26
            %                 counter = 1;
            %                 figure(1)
            %                 imds = imageDatastore('d:\\Matlab\\Data\\DeepMIB_patch_Test\\PatchOut\\Case1\\');
            %                 montage(imds, 'BackgroundColor', [1 1 1], 'BorderSize', [8 8]);
            %                 error('');
            %             end
            
            if obj.BatchOpt.O_PreviewImagePatches && rand < obj.BatchOpt.O_FractionOfPreviewPatches{1}
                if isfield(obj.TrainingProgress, 'UIFigure')
                    if size(inpVol{1}, 3) == 3 || size(inpVol{1}, 3) == 1
                        image(obj.TrainingProgress.imgPatch, inpVol{1});
                    elseif size(inpVol{1}, 3) == 2
                        out2 = inpVol{1};
                        out2(:,:,3) = zeros([size(inpVol{1},1) size(inpVol{1},2)]);
                        image(obj.TrainingProgress.imgPatch, out2);
                    end
                    %image(obj.TrainingProgress.labelPatch, uint8(inpResponse{1}), 'CDataMapping', 'scaled');
                    if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                        padSize = ceil((size(inpVol{1},1)- size(inpResponse{1},1))/2);
                        previewLabel = padarray(uint8(inpResponse{1}),[padSize, padSize], 0, 'both');
                        imagesc(obj.TrainingProgress.labelPatch, previewLabel, [0 obj.BatchOpt.T_NumberOfClasses{1}]);
                    else
                        imagesc(obj.TrainingProgress.labelPatch, uint8(inpResponse{1}), [0 obj.BatchOpt.T_NumberOfClasses{1}]);
                    end
                    drawnow;
                end
                %figure(112345)
                %imshowpair(out, uint8(respOut), 'montage');
            end
            
            patchOut = table(inpVol, inpResponse);
            % imtool(patchOut.inpVol{1}(:,:,32,1), [])
        end
        
        
        function [patchOut, augList, augPars] = augmentAndCrop3dPatch(obj, patchIn, inputPatchSize, outputPatchSize, mode)
            % function [patchOut, augList, augPars] = augmentAndCrop3dPatch(obj, patchIn, inputPatchSize, outputPatchSize, mode)
            %
            % Augment training data by set of operations encoded in
            % obj.AugOpt3D and/or crop the response to the network's output size.
            %
            % Parameters:
            % patchIn:
            % inputPatchSize: input patch size as [height, width, depth, color]
            % outputPatchSize: output patch size as [height, width, depth, classes]
            % % mode: string
            % 'show' - do not transform/augment, do not crop, only show
            % 'crop' - do not transform/augment, only crop and show
            % 'aug' - transform/augment, crop and show
            %
            % Return values:
            % patchOut: return the image patches in a two-column table as required by the trainNetwork function for
            % single-input networks.
            % augList: cell array with used augmentation operations
            % augPars: array with used values
            
            augList = {};    % list of used aug functions
            augPars = [];       % array with used parameters
            if obj.TrainingProgress.emergencyBrake == 1   % stop training, return. This function is still called multiple times after stopping the training
                patchOut = [];
                return;
            end
            
            if ismember('ResponsePixelLabelImage', patchIn.Properties.VariableNames)  % this one for pixelLabelDatastore
                fieldId = 'ResponsePixelLabelImage';
            else    % this one for imageDatastore
                fieldId = 'ResponseImage';
            end
            
            if strcmp(mode, 'show')
                inpVol = patchIn.InputImage;
                inpResponse = patchIn.(fieldId);
            else
                numAugFunc = numel(obj.Aug3DFuncNames);    % number of functions to be used
                
                inpVol = cell(size(patchIn,1), 1);
                inpResponse = cell(size(patchIn,1), 1);
                augList = cell(size(patchIn,1), 1);
                augPars = nan([size(patchIn,1), 1]);
                
                diffPatchY = (inputPatchSize(1)-outputPatchSize(1))/2;
                diffPatchX = (inputPatchSize(2)-outputPatchSize(2))/2;
                diffPatchZ = (inputPatchSize(3)-outputPatchSize(3))/2;
                
                cropSwitch = 0;
                if diffPatchY ~=0 || diffPatchX ~=0 || diffPatchZ ~=0
                    y1 = diffPatchY+1;
                    y2 = inputPatchSize(1)-diffPatchY;
                    x1 = diffPatchX+1;
                    x2 = inputPatchSize(2)-diffPatchX;
                    z1 = diffPatchZ+1;
                    z2 = inputPatchSize(3)-diffPatchZ;
                    cropSwitch = 1;   % crop resulting image to match output patch
                end
                
                for id=1:size(patchIn, 1)
                    if strcmp(mode, 'crop')  % do only crop
                        if cropSwitch
                            inpResponse{id, 1} = patchIn.(fieldId){id}(y1:y2, x1:x2, z1:z2, :, :);
                        else
                            inpResponse{id, 1} = patchIn.(fieldId){id};
                        end
                        inpVol{id, 1}= patchIn.InputImage{id};
                    else    % augment and crop
                        rndIdx = randi(100, 1)/100;
                        if rndIdx > obj.AugOpt3D.Fraction   % if index lower than obj.AugOpt3D.Fraction -> augment the data
                            out =  patchIn.InputImage{id};
                            respOut = patchIn.(fieldId){id};
                            augList{id} = {'Original'};
                        else
                            if numAugFunc == 0
                                uialert(obj.View.gui, ...
                                    sprintf('!!! Error !!!\n\nThe augmentation functions were not selected!'), ...
                                    'Missing augmentation fuctions');
                                return;
                            end
                            
                            augFuncIndex = randi(numAugFunc, 1);
                            augList{id} = obj.Aug3DFuncNames(augFuncIndex);
                            
                            switch obj.Aug3DFuncNames{augFuncIndex}
                                case 'RandXReflection'
                                    out = fliplr(patchIn.InputImage{id});
                                    respOut = fliplr(patchIn.(fieldId){id});
                                case 'RandYReflection'
                                    out = flipud(patchIn.InputImage{id});
                                    respOut = flipud(patchIn.(fieldId){id});
                                case 'RandZReflection'
                                    out = flip(patchIn.InputImage{id}, 3);
                                    respOut = flip(patchIn.(fieldId){id}, 3);
                                case 'Rotation90'
                                    if randi(2) == 1
                                        out = rot90(patchIn.InputImage{id});
                                        respOut = rot90(patchIn.(fieldId){id});
                                    else
                                        out = rot90(patchIn.InputImage{id}, 3);
                                        respOut = rot90(patchIn.(fieldId){id}, 3);
                                    end
                                case 'ReflectedRotation90'
                                    out = rot90(fliplr(patchIn.InputImage{id}));
                                    respOut = rot90(fliplr(patchIn.(fieldId){id}));
                            end
                        end
                        % Crop the response to to the network's output.
                        %respFinal=respOut(45:end-44,45:end-44,:);
                        if cropSwitch
                            inpResponse{id, 1} = respOut(y1:y2, x1:x2, z1:z2, :, :);
                        else
                            inpResponse{id, 1} = respOut;
                        end
                        inpVol{id, 1}= out;
                    end
                end
            end
            
            if obj.BatchOpt.O_PreviewImagePatches && rand < obj.BatchOpt.O_FractionOfPreviewPatches{1}
                if isfield(obj.TrainingProgress, 'UIFigure')
                    zVal = ceil(size(inpVol{1}, 3)/2);  % calculate position of mid-slice
                    if size(inpVol{1}, 4) == 3 || size(inpVol{1}, 4) == 1
                        image(obj.TrainingProgress.imgPatch, squeeze(inpVol{1}(:,:,zVal,:)));
                    elseif size(inpVol{1}, 4) == 2
                        out2 = squeeze(inpVol{1}(:,:,zVal,:));
                        out2(:,:,3) = zeros([size(inpVol{1},1) size(inpVol{1},2)]);
                        image(obj.TrainingProgress.imgPatch, out2);
                    end
                    
                    zValResp = ceil(size(inpResponse{1}, 3)/2);  % calculate position of mid-slice
                    if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                        padSize = ceil((size(inpVol{1},1)- size(inpResponse{1},1))/2);
                        previewLabel = padarray(uint8(inpResponse{1}(:,:,zValResp)),[padSize, padSize], 0, 'both');
                        imagesc(obj.TrainingProgress.labelPatch, previewLabel, [0 obj.BatchOpt.T_NumberOfClasses{1}]);
                    else
                        imagesc(obj.TrainingProgress.labelPatch, uint8(inpResponse{1}(:,:,zValResp)), [0 obj.BatchOpt.T_NumberOfClasses{1}]);
                    end
                    drawnow;
                end
                %figure(112345)
                %imshowpair(out, uint8(respOut), 'montage');
            end
            
            patchOut = table(inpVol, inpResponse);
            % imtool(patchOut.inpVol{1}(:,:,32,1), [])
        end
        
        function setAugmentation3DSettings(obj)
            % function setAugmentation3DSettings(obj)
            % update settings for augmentation fo 3D images
            global mibPath;
            
            % rot90,fliplr,flipud,rot90(fliplr)
            prompts = { 'Fraction: fraction of patches to augment';...
                'FillValue: fill value used to define out-of-bounds points when resampling or rotating [NOT IN USE AT THE MOMENT]';...
                'RandXReflection: random reflection in the left-right direction'; ...
                'RandYReflection: random reflection in the up-down direction'; ...
                'RandZReflection: random reflection in the top-bottom direction'; ...
                'Rotation90: allow 90 degree rotation clock and anticlockwise directions'; ...
                'ReflectedRotation90: allow 90 degree rotation of the left-right reflected dataset'};
            defAns = {num2str(obj.AugOpt3D.Fraction); ...
                num2str(obj.AugOpt3D.FillValue); ...
                obj.AugOpt3D.RandXReflection; ...
                obj.AugOpt3D.RandYReflection; ...
                obj.AugOpt3D.RandZReflection; ...
                obj.AugOpt3D.Rotation90; ...
                obj.AugOpt3D.ReflectedRotation90 ...
                };
            
            dlgTitle = '3D augmentation settings';
            options.WindowStyle = 'normal';
            options.PromptLines = [1, 2, 1, 1, 1, 1, 1];   % [optional] number of lines for widget titles
            options.WindowWidth = 2;    % [optional] make window x1.2 times wider
            options.Columns = 1;    % [optional] define number of columns
            options.Focus = 1;      % [optional] define index of the widget to get focus
            %options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/imagedataaugmenter.html'; % [optional], an url for the Help button
            %options.LastItemColumns = 1; % [optional] force the last entry to be on a single column
            
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            Fraction = str2double(answer{1});
            if isnan(Fraction); errordlg('Fraction parameter should be a positive number'); return; end
            obj.AugOpt3D.Fraction = Fraction;
            FillValue = str2double(answer{2});
            if isnan(FillValue); errordlg('FillValue parameter should be a positive number'); return; end
            obj.AugOpt3D.FillValue = FillValue;
            obj.AugOpt3D.RandXReflection = logical(answer{3});
            obj.AugOpt3D.RandYReflection = logical(answer{4});
            obj.AugOpt3D.RandZReflection = logical(answer{5});
            obj.AugOpt3D.Rotation90 = logical(answer{6});
            obj.AugOpt3D.ReflectedRotation90 = logical(answer{7});
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
                    prompts = {sprintf('Alpha, balancing parameter of the focal loss function\nThe Alpha value scales the loss function linearly, when decreasing Alpha, increase Gamma\npositive real number, [default=2]'); ...
                        sprintf('Gamma, focusing parameter of the focal loss function\nIncreasing the value of Gamma increases the sensitivity of the network to misclassified observations\npositive real number [default=0.25]')};
                    defAns = {num2str(obj.SegmentationLayerOpt.focalLossLayer.Alpha);...
                        num2str(obj.SegmentationLayerOpt.focalLossLayer.Gamma)};
                    options.PromptLines = [5 5];
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
            end
        end
        
        function reset2Daugmentation(obj)
            % function reset2Daugmentation(obj)
            % reset 2D augmentation settings to default
            
            %             if newaugmentationsystemCheckBox == 1
            obj.AugOpt2D = struct();
            obj.AugOpt2D.Fraction = .9;
            obj.AugOpt2D.FillValue = 255;
            obj.AugOpt2D.RandXReflection = [1 0.05];
            obj.AugOpt2D.RandYReflection = [1 0.05];
            obj.AugOpt2D.Rotation90 = [1 0.05];
            obj.AugOpt2D.ReflectedRotation90 = [1 0.05];
            obj.AugOpt2D.RandRotation = [-10 10 0.05];
            obj.AugOpt2D.RandXScale = [1 1.1 0.05];
            obj.AugOpt2D.RandYScale = [1 1.1 0.05];
            obj.AugOpt2D.RandScale = [1 1.1 0.05];
            obj.AugOpt2D.RandXShear = [-10 10 0.05];
            obj.AugOpt2D.RandYShear = [-10 10 0.05];
            obj.AugOpt2D.HueJitter = [-0.03 0.03 0.05];
            obj.AugOpt2D.SaturationJitter = [-.05 .05 0.05];
            obj.AugOpt2D.BrightnessJitter = [-.1 .1 0.05];
            obj.AugOpt2D.ContrastJitter = [.9 1.1 0.05];
            obj.AugOpt2D.GaussianNoise = [0 0.005 0.05]; % variance
            obj.AugOpt2D.PoissonNoise = [1 0.05];
            obj.AugOpt2D.ImageBlur = [0 .5 0.05];
            %             else
            %                 obj.AugOpt2D = struct();
            %                 obj.AugOpt2D.Fraction = .9;
%                 obj.AugOpt2D.FillValue = 255;
%                 obj.AugOpt2D.RandXReflection = true;
%                 obj.AugOpt2D.RandYReflection = true;
%                 obj.AugOpt2D.Rotation90 = true;
%                 obj.AugOpt2D.ReflectedRotation90 = true;
%                 obj.AugOpt2D.RandRotation = [-10 10];
%                 obj.AugOpt2D.RandXScale = [1 1.1];
%                 obj.AugOpt2D.RandYScale = [1 1.1];
%                 obj.AugOpt2D.RandScale = [1 1.1];
%                 obj.AugOpt2D.RandXShear = [-10 10];
%                 obj.AugOpt2D.RandYShear = [-10 10];
%                 obj.AugOpt2D.HueJitter = [-0.03 0.03];
%                 obj.AugOpt2D.SaturationJitter = [-.05 .05];
%                 obj.AugOpt2D.BrightnessJitter = [-.1 .1];
%                 obj.AugOpt2D.ContrastJitter = [.9 1.1];
%                 obj.AugOpt2D.GaussianNoise = [0 0.005]; % variance
%                 obj.AugOpt2D.PoissonNoise = true;
%                 obj.AugOpt2D.ImageBlur = [0 .5];
%             end
            uialert(obj.View.gui, 'The augmentation 2D settings were reset to default ones!', 'Success!', 'icon', 'info');
        end
        
        function disable2Daugmentation(obj)
            % function disable2Daugmentation(obj)
            % disable all 2D augmentations
            
            obj.AugOpt2D = struct();
            obj.AugOpt2D.Fraction = .9;
            obj.AugOpt2D.FillValue = 255;
            obj.AugOpt2D.RandXReflection = [1 0];
            obj.AugOpt2D.RandYReflection = [1 0];
            obj.AugOpt2D.Rotation90 = [1 0];
            obj.AugOpt2D.ReflectedRotation90 = [1 0];
            obj.AugOpt2D.RandRotation = [-10 10 0];
            obj.AugOpt2D.RandXScale = [1 1.1 0];
            obj.AugOpt2D.RandYScale = [1 1.1 0];
            obj.AugOpt2D.RandScale = [1 1.1 0];
            obj.AugOpt2D.RandXShear = [-10 10 0];
            obj.AugOpt2D.RandYShear = [-10 10 0];
            obj.AugOpt2D.HueJitter = [-0.03 0.03 0];
            obj.AugOpt2D.SaturationJitter = [-.05 .05 0];
            obj.AugOpt2D.BrightnessJitter = [-.1 .1 0];
            obj.AugOpt2D.ContrastJitter = [.9 1.1 0];
            obj.AugOpt2D.GaussianNoise = [0 0.005 0]; % variance
            obj.AugOpt2D.PoissonNoise = [1 0];
            obj.AugOpt2D.ImageBlur = [0 .5 0];
            
            obj.View.handles.T_augmentation.Value = false;
            
            obj.T_augmentationCallback();
            uialert(obj.View.gui, 'The augmentation 2D settings were disabled!', 'Success!', 'icon', 'info');
        end
        
        function setAugmentation2DSettings(obj)
            % function setAugmentation2DSettings(obj)
            % update settings for augmentation fo 2D images
            global mibPath;
            
            %if newaugmentationsystemCheckBox == 1
                prompts = {'Fraction: fraction of images to be augmented [0-1, def=0.9]'; ...
                    'FillValue: fill value for out-of-bounds points when rotating [0-Inf, def=255]'; ...
                    'RandXReflection: random left-right reflections, def=[1 0.05], off=[0 0.05]'; ...
                    'RandYReflection: random top-bottom reflection, def=[1 0.05], off=[0 0.05]'; ...
                    'Rotation90: rotation to 90 or 270 degrees, def=[1 0.05], off=[0 0.05]'; ...
                    'ReflectedRotation90: 90 degree rotation and left-right reflection, def=[1 0.05], off=[0 0.05]'; ...
                    'RandRotation: random rotations, in degrees from -90 to 90, def=[-10 10 0.05], off=[0 0 0.05]'; ...
                    'RandScale: random scaling, range (0-Inf), def=[1 1.1 0.05], off=[1 1 0.05]'; ...
                    'RandXScale: random X scaling, range (0-Inf), def=[1 1.1 0.05], off=[1 1 0.05]'; ...
                    'RandYScale: random Y scaling, range (0-Inf), def=[1 1.1 0.05], off=[1 1 0.05]'; ...
                    'RandXShear: horizontal random shear, in degrees in the range (-90  90), def=[-10 10 0.05], off=[0 0 0.05]'; ...
                    'RandYShear: vertical random shear, in degrees in the range (-90  90), def=[-10 10 0.05], off=[0 0 0.05]'; ...
                    'GaussianNoise: add Gaussian noise using a random variance in range (0 Inf), def=[0. 005 0.05], off=[0 0 0.05]'; ...
                    'PoissonNoise: allow Poisson noise, def=[1 0.05], off=[0 0.05]'; ...
                    'HueJitter: jitter of Hue using a random value in the range (-1 1), def=[-0.03 0.03 0.05], off=[0 0 0.05]'; ...
                    'SaturationJitter: jitter of Saturation using a random value in the range (-1 1), def=[-0.05 0.05 0.05], off=[0 0 0.05]'; ...
                    'BrightnessJitter: jitter of Brightness using a random value in the range (-1 1), def=[-0.1 0.1 0.05], off=[0 0 0.05]'; ...
                    'ContrastJitter: jitter of Contrast using a random value in the range (0 Inf), def=[0.9 1.1 0.05], off=[1 1 0.05]'; ...
                    'ImageBlur: allow Gaussian blur defined as sigma in the range (0 Inf), def=[0 0.5 0.05], off=[0 0 0.05]';...
                    };

                defAns = {  num2str(obj.AugOpt2D.Fraction); ...
                    num2str(obj.AugOpt2D.FillValue); ...
                    num2str(obj.AugOpt2D.RandXReflection); ...
                    num2str(obj.AugOpt2D.RandYReflection); ...
                    num2str(obj.AugOpt2D.Rotation90); ...
                    num2str(obj.AugOpt2D.ReflectedRotation90); ...
                    num2str(obj.AugOpt2D.RandRotation); ...
                    num2str(obj.AugOpt2D.RandScale); ...
                    num2str(obj.AugOpt2D.RandXScale); ...
                    num2str(obj.AugOpt2D.RandYScale); ...
                    num2str(obj.AugOpt2D.RandXShear); ...
                    num2str(obj.AugOpt2D.RandYShear);...
                    num2str(obj.AugOpt2D.GaussianNoise); ...
                    num2str(obj.AugOpt2D.PoissonNoise); ...
                    num2str(obj.AugOpt2D.HueJitter); ...
                    num2str(obj.AugOpt2D.SaturationJitter); ...
                    num2str(obj.AugOpt2D.BrightnessJitter); ...
                    num2str(obj.AugOpt2D.ContrastJitter); ...
                    num2str(obj.AugOpt2D.ImageBlur); ...
                    };

                dlgTitle = '2D augmentation settings';
                options.WindowStyle = 'normal';
                options.PromptLines = [2, 2, 2, 2, 2, 2, 3, ...
                                       2, 2, 2, 3, 3, 3, 2, ...
                                       3, 3, 3, 3, 3];   % [optional] number of lines for widget titles
                options.Title = 'Each augmentation is defined with 2 or 3 values, the first value(s) define variation of the augmentation filter, while the last value specify probability of triggering the augmentation. The resulting augmented patch may be made from a cocktail of many augmentations'; 
                options.TitleLines = 2;                   % [optional] make it twice tall, number of text lines for the title
                options.WindowWidth = 3;    % [optional] make window x1.2 times wider
                options.Columns = 3;    % [optional] define number of columns
                options.Focus = 1;      % [optional] define index of the widget to get focus
                options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/imagedataaugmenter.html'; % [optional], an url for the Help button
                %options.LastItemColumns = 1; % [optional] force the last entry to be on a single column
                
                [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer); return; end

                Value = str2double(answer{1});
                if isnan(Value); errordlg('Fraction parameter should be a positive number between 0 and 1'); return; end
                if Value < 0 || Value > 1; errordlg('Fraction parameter should be a positive number between 0 and 1'); return; end
                obj.AugOpt2D.Fraction =  Value;

                Value = str2double(answer{2});
                if isnan(Value); errordlg('Fill value should be a positive number between 0 and max value the image class can handle, for example 255 for uint8 or 65535 for uint16'); return; end
                if Value < 0; errordlg('Fill value should be a positive number between 0 and max value the image class can handle, for example 255 for uint8 or 65535 for uint16'); return; end
                obj.AugOpt2D.FillValue =  Value;

                % check for errors
                range = zeros([22, 2]);
                range(3,:) = [0 1];     % RandXReflection
                range(4,:) = [0 1];     % RandYReflection
                range(5,:) = [0 1];     % Rotation90
                range(6,:) = [0 1];     % ReflectedRotation90
                range(7,:) = [-90 90];  % RandRotation
                range(8,:) = [0 Inf];   % RandScale
                range(9,:) = [0 Inf];   % RandXScale
                range(10,:) = [0 Inf];  % RandYScale
                range(11,:) = [-90 90]; % RandXShear
                range(12,:) = [-90 90]; % RandYShear
                range(13,:) = [0 Inf];  % GaussianNoise
                range(14,:) = [0 1];    % PoissonNoise
                range(15,:) = [-1 1];   % HueJitter
                range(16,:) = [-1 1];   % SaturationJitter
                range(17,:) = [-1 1];   % BrightnessJitter
                range(18,:) = [0 Inf];  % ContrastJitter
                range(19,:) = [0 Inf];  % ImageBlur
                
                tripleValIndices = 3:19;
                doubleValIndices = [3, 4, 5, 6, 14];     % indices of fields that should have 2 values
                tripleValIndices(ismember(tripleValIndices, doubleValIndices)) = [];     % remove doubleValIndices
                
                for i = doubleValIndices
                    Value = str2num(answer{i});
                    if isempty(Value) || numel(Value) ~= 2 || Value(1) < range(i,1) || Value(1) > range(i,2) || ...
                        Value(2) < 0 || Value(2) > 1
                        errordlg(sprintf('!!! Error !!!\n\n%s\n\nthe entry should be made of 2 numbers!\nThe first number should be 0-off or 1-on, while the second value defines probability of the augmentation and should be in the range 0-1', prompts{i}));
                        return;
                    end
                end
                
                for i = tripleValIndices
                    Value = str2num(answer{i});
                    if isempty(Value) || numel(Value) ~= 3 || Value(1) < range(i,1) || Value(2) > range(i,2) || ...
                        Value(3) < 0 || Value(3) > 1
                        errordlg(sprintf('!!! Error !!!\n\n%s\n\nthe entry should be made of 3 numbers!\nThe first and second numbers should be within the range (see above), while the third value defines probability of the augmentation and should be in the range 0-1', prompts{i}));
                        return;
                    end
                end
                
                obj.AugOpt2D.RandXReflection = str2num(answer{3});
                obj.AugOpt2D.RandYReflection = str2num(answer{4});
                obj.AugOpt2D.Rotation90 = str2num(answer{5});
                obj.AugOpt2D.ReflectedRotation90 = str2num(answer{6});
                obj.AugOpt2D.RandRotation = str2num(answer{7});
                obj.AugOpt2D.RandScale = str2num(answer{8});
                obj.AugOpt2D.RandXScale = str2num(answer{9});
                obj.AugOpt2D.RandYScale = str2num(answer{10});
                obj.AugOpt2D.RandXShear = str2num(answer{11});
                obj.AugOpt2D.RandYShear = str2num(answer{12});
                obj.AugOpt2D.GaussianNoise = str2num(answer{13});
                obj.AugOpt2D.PoissonNoise = str2num(answer{14});
                obj.AugOpt2D.HueJitter = str2num(answer{15});
                obj.AugOpt2D.SaturationJitter = str2num(answer{16});
                obj.AugOpt2D.BrightnessJitter = str2num(answer{17});
                obj.AugOpt2D.ContrastJitter = str2num(answer{18});
                obj.AugOpt2D.ImageBlur = str2num(answer{19});
%             else
%                 prompts = {'Fraction: fraction of images to be augmented [0-1, def=0.9]'; ...
%                     'FillValue: fill value for out-of-bounds points when rotating [0-Inf, def=255]'; ...
%                     'RandXReflection: random left-right reflections'; ...
%                     'RandYReflection: random top-bottom reflection'; ...
%                     'Rotation90: rotation to 90 or 270 degrees'; ...
%                     'ReflectedRotation90: 90 degree rotation and left-right reflection'; ...
%                     'RandRotation: random rotations, in degrees from -90 to 90, def=[-10 10], off=[0 0]'; ...
%                     'RandScale: random scaling, range (0-Inf), def=[1 1.1], off=[1 1]'; ...
%                     'RandXScale: random X scaling, range (0-Inf), def=[1 1.1], off=[1 1]'; ...
%                     'RandYScale: random Y scaling, range (0-Inf), def=[1 1.1], off=[1 1]'; ...
%                     'RandXShear: horizontal random shear, in degrees in the range (-90  90), def=[-10 10], off=[0 0]'; ...
%                     'RandYShear: vertical random shear, in degrees in the range (-90  90), def=[-10 10], off=[0 0]'; ...
%                     'HueJitter: jitter of Hue using a random value in the range (-1 1), def=[-0.03 0.03], off=[0 0]'; ...
%                     'SaturationJitter: jitter of Saturation using a random value in the range (-1 1), def=[-0.05 0.05], off=[0 0]'; ...
%                     'BrightnessJitter: jitter of Brightness using a random value in the range (-1 1), def=[-0.1 0.1], off=[0 0]'; ...
%                     'ContrastJitter: jitter of Contrast using a random value in the range (0 Inf), def=[0.9 1.1], off=[1 1]'; ...
%                     'ImageBlur: allow Gaussian blur defined as sigma in the range (0 Inf), def=[0 0.5], off=[0 0]';...
%                     'GaussianNoise: add Gaussian noise using a random variance in range (0 Inf), def=[0. 005], off=[0 0]'; ...
%                     'PoissonNoise: allow Poisson noise'; ...
%                     };
% 
%                 defAns = {  num2str(obj.AugOpt2D.Fraction); ...
%                     num2str(obj.AugOpt2D.FillValue); ...
%                     obj.AugOpt2D.RandXReflection; ...
%                     obj.AugOpt2D.RandYReflection; ...
%                     obj.AugOpt2D.Rotation90; ...
%                     obj.AugOpt2D.ReflectedRotation90; ...
%                     num2str(obj.AugOpt2D.RandRotation); ...
%                     num2str(obj.AugOpt2D.RandScale); ...
%                     num2str(obj.AugOpt2D.RandXScale); ...
%                     num2str(obj.AugOpt2D.RandYScale); ...
%                     num2str(obj.AugOpt2D.RandXShear); ...
%                     num2str(obj.AugOpt2D.RandYShear);...
%                     num2str(obj.AugOpt2D.HueJitter); ...
%                     num2str(obj.AugOpt2D.SaturationJitter); ...
%                     num2str(obj.AugOpt2D.BrightnessJitter); ...
%                     num2str(obj.AugOpt2D.ContrastJitter); ...
%                     num2str(obj.AugOpt2D.ImageBlur); ...
%                     num2str(obj.AugOpt2D.GaussianNoise); ...
%                     obj.AugOpt2D.PoissonNoise};
%                 dlgTitle = '2D augmentation settings';
%                 options.WindowStyle = 'normal';
%                 options.PromptLines = [2, 2, 1, 1, 1, 1, 2, 2, 2, ...
%                     2, 2, 2, 2, 2, 2, 2, 2, 3, 1];   % [optional] number of lines for widget titles
%                 %options.Title = 'My test Input dialog';   % [optional] additional text at the top of the window
%                 %options.TitleLines = 2;                   % [optional] make it twice tall, number of text lines for the title
%                 options.WindowWidth = 2.2;    % [optional] make window x1.2 times wider
%                 options.Columns = 2;    % [optional] define number of columns
%                 options.Focus = 1;      % [optional] define index of the widget to get focus
%                 options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/imagedataaugmenter.html'; % [optional], an url for the Help button
%                 %options.LastItemColumns = 1; % [optional] force the last entry to be on a single column
%                 
%                 [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
%                 if isempty(answer); return; end
% 
%                 Value = str2double(answer{1});
%                 if isnan(Value); errordlg('Fraction parameter should be a positive number between 0 and 1'); return; end
%                 if Value < 0 || Value > 1; errordlg('Fraction parameter should be a positive number between 0 and 1'); return; end
%                 obj.AugOpt2D.Fraction =  Value;
% 
%                 Value = str2double(answer{2});
%                 if isnan(Value); errordlg('Fill value should be a positive number between 0 and max value the image class can handle, for example 255 for uint8 or 65535 for uint16'); return; end
%                 if Value < 0; errordlg('Fill value should be a positive number between 0 and max value the image class can handle, for example 255 for uint8 or 65535 for uint16'); return; end
%                 obj.AugOpt2D.FillValue =  Value;
% 
%                 obj.AugOpt2D.RandXReflection = logical(answer{3});
%                 obj.AugOpt2D.RandYReflection = logical(answer{4});
%                 obj.AugOpt2D.Rotation90 = logical(answer{5});
%                 obj.AugOpt2D.ReflectedRotation90 = logical(answer{6});
% 
%                 range = zeros([18, 2]);
%                 range(7,:) = [-90 90];  % RandRotation
%                 range(8,:) = [0 Inf];   % RandScale
%                 range(9,:) = [0 Inf];   % RandXScale
%                 range(10,:) = [0 Inf];   % RandYScale
%                 range(11,:) = [-90 90];  % RandXShear
%                 range(12,:) = [-90 90]; % RandYShear
%                 range(13,:) = [-1 1];   % HueJitter
%                 range(14,:) = [-1 1];   % SaturationJitter
%                 range(15,:) = [-1 1];   % BrightnessJitter
%                 range(16,:) = [0 Inf];  % ContrastJitter
%                 range(17,:) = [0 Inf];  % ImageBlur
%                 range(18,:) = [0 Inf];  % GaussianNoise
% 
%                 for i=7:18
%                     Value = str2num(answer{i});
%                     if isempty(Value) || numel(Value) ~= 2 || Value(1) < range(i,1) || Value(2) > range(i,2)
%                         errordlg(sprintf('!!! Error !!!\n\n%s\n\nshould be made of 2 numbers', prompts{i}));
%                         return;
%                     end
%                 end
% 
%                 obj.AugOpt2D.RandRotation = str2num(answer{7});
%                 obj.AugOpt2D.RandScale = str2num(answer{8});
%                 obj.AugOpt2D.RandXScale = str2num(answer{9});
%                 obj.AugOpt2D.RandYScale = str2num(answer{10});
%                 obj.AugOpt2D.RandXShear = str2num(answer{11});
%                 obj.AugOpt2D.RandYShear = str2num(answer{12});
%                 obj.AugOpt2D.HueJitter = str2num(answer{13});
%                 obj.AugOpt2D.SaturationJitter = str2num(answer{14});
%                 obj.AugOpt2D.BrightnessJitter = str2num(answer{15});
%                 obj.AugOpt2D.ContrastJitter = str2num(answer{16});
%                 obj.AugOpt2D.ImageBlur = str2num(answer{17});
%                 obj.AugOpt2D.GaussianNoise = str2num(answer{18});
%                 obj.AugOpt2D.PoissonNoise = logical(answer{19});
%             end
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
            options.WindowWidth = 2.4;
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
                'LearnRateDropPeriod, [piecewise only] number of epochs for dropping the learning rate [10]';...
                'LearnRateDropFactor, [piecewise only] factor for dropping the learning rate, should be between 0 and 1 [0.1]';...
                'L2Regularization, factor for L2 regularization (weight decay) [0.0001]';...
                'Momentum, [sgdm only] contribution of the parameter update step of the previous iteration to the current iteration of sgdm [0.9]';...
                'Decay rate of gradient moving average [adam only], a non-negative scalar less than 1 [0.9]'
                'Decay rate of squared gradient moving average for the Adam and RMSProp solvers [0.999 Adam, 0.9 PMSProp]'
                'ValidationFrequency, number of validations per Epoch [2]';...
                'Patience of validation stopping of network training, the number of times that the loss on the validation set can be larger than or equal to the previously smallest loss before network training stops [Inf]'
                'Plots, plots to display during network training'};
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
                {'training-progress', 'none', find(ismember({'training-progress', 'none'}, obj.TrainingOpt.Plots))} };
            dlgTitle = 'Training settings';
            options.WindowStyle = 'normal';
            options.PromptLines = [1, 2, 1, 6, 2, ...
                2, 3, 2, 3, 2, 3, 2, 3, 1];   % [optional] number of lines for widget titles
            %options.Title = 'My test Input dialog';   % [optional] additional text at the top of the window
            %options.TitleLines = 2;                   % [optional] make it twice tall, number of text lines for the title
            options.WindowWidth = 2.2;    % [optional] make window x1.2 times wider
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
        end
        
        function Start(obj, event)
            % start main calculation of the plugin
            switch event.Source.Tag
                case 'PreprocessButton'
                    obj.StartPreprocessing();
                case 'TrainButton'
                    obj.StartTraining();
                case 'PredictButton'
                    if obj.View.handles.bigImageMode.Value
                        obj.StartPredictionBigImage2D();
                    else
                        if strcmp(obj.BatchOpt.Architecture{1}(1:2), '2D')
                            obj.StartPrediction2D();
                        else
                            obj.StartPrediction3D();
                        end
                    end
            end
            
            % redraw the image if needed
            %notify(obj.mibModel, 'plotImage');
            
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
            
            if nargin < 2; errordlg('processImages: the second parameter is required!', 'Preprocessing error'); return; end
            
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
                errordlg('processImages: the second parameter is wrong!', 'Preprocessing error'); return;
            end
            
            %% Load data
            if ~isfolder(fullfile(imageDirIn, 'Images'))
                uialert(obj.View.gui, sprintf('!!! Warning !!!\n\nThe images and models should be arranged in "Images" and "Labels" directories under\n\n%s\n\nCopy files there and try again!', imageDirIn), ...
                    'Old project or missing files', 'Icon', 'warning');
                return;
            end
            
            if obj.BatchOpt.showWaitbar
                obj.wb = waitbar(0, sprintf('Creating image datastore\nPlease wait...'), ...
                    'Name', sprintf('%s: processing for %s', obj.BatchOpt.Architecture{1}, preprocessFor));
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
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
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
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Problems');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
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
            
            if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, sprintf('Acquiring class names\nPlease wait...')); end
            
            GroundTruthModelSwitch = 0;     % models exists
            classNames = {'Exterior'};
            
            if strcmp(obj.BatchOpt.ModelFilenameExtension{1}, 'MODEL')
                % read number of materials for the first file
                files = dir(fullfile(imageDirIn, 'Labels', '*.model'));
                if isempty(files) && trainingSwitch
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nModel files are missing in\n%s', fullfile(imageDirIn, 'Labels')), ...
                        'Missing model files!');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
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
                files = dir(fullfile(imageDirIn, 'Labels', ['*.' obj.BatchOpt.ModelFilenameExtension{1}]));
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
                rng(obj.BatchOpt.RandomGeneratorSeed{1});
                randIndices = randperm(NumFiles);   % Random permutation of integers
                validationIndices = randIndices(1:ceil(obj.BatchOpt.ValidationFraction{1}*NumFiles));   % get indices of images to be used for validation
                if numel(validationIndices) == NumFiles
                    uialert(obj.View.gui, sprintf('!!! Warning !!!\n\nWith the current settings all images are assigned to the validation set!\nPlease decrease the value in the "Fraction of images for validation" edit box and try again!'), ...
                        'Validation set is too large', 'Icon', 'warning');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                    return;
                end
            else
                validationIndices = zeros([NumFiles, 1]);   % do not create validation data
            end
            
            % define usage of parallel computing
            if obj.BatchOpt.UseParallelComputing
                parforArg = obj.View.handles.PreprocessingParForWorkers.Value;    % Maximum number of workers running in parallel
            else
                parforArg = 0;      % Maximum number of workers running in parallel, when 0 a single core used without parallel
            end
            
            % create local variables for parfor
            ArchitectureParFor = obj.BatchOpt.Architecture{1}(1:2);
            MaskAwayParFor = obj.BatchOpt.MaskAway;
            ResultingImagesDirParFor = obj.BatchOpt.ResultingImagesDir;
            showWaitbarParFor = obj.BatchOpt.showWaitbar;
            compressImages = obj.BatchOpt.CompressProcessedImages;
            compressModels = obj.BatchOpt.CompressProcessedModels;
            maskVariable = 'maskImg';   % variable that has mask inside *.mask files
            SingleModelTrainingFileParFor = obj.BatchOpt.SingleModelTrainingFile;
            
            if obj.BatchOpt.showWaitbar
                pw = PoolWaitbar(NumFiles, sprintf('Processing images\nPlease wait...'), obj.wb);
                pw.setIncrement(10);  % set increment step to 10
            end
            
            maskDS = [];
            modDS = [];
            saveModelOpt = struct();
            
            if GroundTruthModelSwitch
                if strcmp(obj.BatchOpt.Architecture{1}(1:2), '2D')  % preprocess filed for 2D networks
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
                                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                                return;
                            end
                        end
                    else
                        switch obj.BatchOpt.ModelFilenameExtension{1}
                            case 'MODEL'
                                modDS = imageDatastore(fullfile(imageDirIn, 'Labels'), ...
                                    'IncludeSubfolders', false, ...
                                    'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
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
                            if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                            return;
                        end
                        
                        if MaskAwayParFor && trainingSwitch     % do not use masks for prediction
                            try
                                switch obj.BatchOpt.MaskFilenameExtension{1}
                                    case 'MASK'
                                        maskDS = imageDatastore(fullfile(imageDirIn, 'Masks'), ...
                                            'IncludeSubfolders', false, ...
                                            'FileExtensions', '.mask', 'ReadFcn', @mibDeepController.mibImgFileRead);
                                    otherwise
                                        maskDS = imageDatastore(fullfile(imageDirIn, 'Masks'), ...
                                            'IncludeSubfolders', false, 'FileExtensions', lower(['.' obj.BatchOpt.MaskFilenameExtension{1}]));
                                end
                            catch err
                                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing masks');
                                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                                return;
                            end
                            
                            if numel(maskDS.Files) ~= numel(imgDS.Files)
                                uialert(obj.View.gui, ...
                                    sprintf('!!! Error !!!\n\nIn this mode number of mask files should match number of image files!'), 'Error');
                                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                                return;
                            end
                        end
                    end
                else    % preprocess files for 3D networks
                    % these variable needed for parfor loop
                    try
                        modDS = imageDatastore(fullfile(imageDirIn, 'Labels'), ...
                            'IncludeSubfolders', false, ...
                            'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                        if MaskAwayParFor && trainingSwitch     % do not use masks for prediction
                            maskDS = imageDatastore(fullfile(imageDirIn, 'Masks'), ...
                                'IncludeSubfolders', false, ...
                                'FileExtensions', '.mask', 'ReadFcn', @mibDeepController.mibImgFileRead);
                        end
                    catch err
                        errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                        if obj.BatchOpt.showWaitbar; delete(obj.wb); end
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
            
            if strcmp(ArchitectureParFor, '2D')
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
                if size(modDS.(modDS.modelVariable), 3) < NumFiles
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nNumber of slices in the model file is smaller than number of images\n\nYou may want to uncheck the "Single MIB model file" checkbox!'), ...
                        'Wrong model file');
                    if showWaitbarParFor; pw.deletePoolWaitbar(); end
                    return;
                end
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
                [~, fnOut] = fileparts(imgDS.Files{imgId});    % get filename of the image
                %                 if obj.BatchOpt.NormalizeImages
                %                     fprintf('!!! Warning !!! Normalizing images!\n')
                %                     outImg = obj.channelWisePreProcess(outImg);     % normalize the signals, remove outliers and scale between 0 and 1
                %                 end
                
                if ndims(mibImg) == 4   % strcmp(obj.BatchOpt.Architecture{1}, '3D U-net')
                    mibImg = permute(mibImg, [1 2 4 3]);    % permute from [height, width, color, depth] -> [height, width, depth, color]
                end
                
                % saving image
                fn = fullfile(imDir, sprintf('%s.mibImg', fnOut));
                saveImageParFor(fn, mibImg, compressImages, saveImageOpt);
                
                if GroundTruthModelSwitch
                    if strcmp(ArchitectureParFor, '2D')
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
                if showWaitbarParFor && mod(imgId, 10) == 1; increment(pw); end
            end
            keepWaitbar = 1;
            pw.deletePoolWaitbar(keepWaitbar);  % delete pw, while keeping obj.wb
            if obj.BatchOpt.showWaitbar; waitbar(1, obj.wb); delete(obj.wb); end
        end
        
        function StartPreprocessing(obj)
            % function StartPreprocessing(obj)
            
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
                    msg = sprintf('!!! Attention !!!\nThe following operation will split files in\n"%s"\n- Images\n- Labels\nto\n- TrainImages, TrainLabels\n- ValidationImages, ValidationLabels', obj.BatchOpt.OriginalTrainingImagesDir);
                    selection = uiconfirm(obj.View.gui, ...
                        msg, 'Split files',...
                        'Options',{'Split and copy', 'Split and move', 'Cancel'},...
                        'DefaultOption', 3, 'CancelOption', 3,...
                        'Icon', 'warning');
                    if strcmp(selection, 'Cancel'); return; end
                    
                    imageFiles = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Images', lower(['*.' obj.BatchOpt.ImageFilenameExtensionTraining{1}])));
                    labelsFiles = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Labels', lower(['*.' obj.BatchOpt.ModelFilenameExtension{1}])));
                    if numel(imageFiles) ~= numel(labelsFiles) || numel(imageFiles) == 0
                        uialert(obj.View.gui, ...
                            sprintf('!!! Error !!!\n\nThere are no files or number of files mismatch in\n\n%s\n\n- Images\n- Labels', obj.BatchOpt.OriginalTrainingImagesDir), ...
                            'Wrong files');
                        return;
                    end
                    
                    noFiles = numel(imageFiles);
                    
                    rng(obj.BatchOpt.RandomGeneratorSeed{1});
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
                        errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Problems');
                        if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                        return;
                    end
                    
                    trainLogicalList = true([numel(imageFiles), 1]);   % indices of files for training
                    trainLogicalList(validationIndices) = false;   % indices of files for validation
                    
                    if strcmp(selection, 'Split and copy')
                        wb = waitbar(0, sprintf('Splitting and copying files\nPlease wait...'), 'Name', 'Split and copy files');
                        for fileId = 1:noFiles
                            if trainLogicalList(fileId)     % for training
                                copyfile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputTrainImagesDir, imageFiles(fileId).name));
                                copyfile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputTrainLabelsDir, labelsFiles(fileId).name));
                            else    % for validation
                                copyfile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputValidationImagesDir, imageFiles(fileId).name));
                                copyfile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputValidationLabelsDir, labelsFiles(fileId).name));
                            end
                            if mod(fileId, 10) == 1; waitbar(fileId/noFiles, wb); end
                        end
                    elseif strcmp(selection, 'Split and move')
                        wb = waitbar(0, sprintf('Splitting and moving files\nPlease wait...'), 'Name', 'Split and move files');
                        for fileId = 1:noFiles
                            if trainLogicalList(fileId)     % for training
                                movefile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputTrainImagesDir, imageFiles(fileId).name));
                                movefile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputTrainLabelsDir, labelsFiles(fileId).name));
                            else    % for validation
                                movefile(fullfile(imageFiles(fileId).folder, imageFiles(fileId).name), fullfile(outputValidationImagesDir, imageFiles(fileId).name));
                                movefile(fullfile(labelsFiles(fileId).folder, labelsFiles(fileId).name), fullfile(outputValidationLabelsDir, labelsFiles(fileId).name));
                            end
                            if mod(fileId, 10) == 1; waitbar(fileId/noFiles, wb); end
                        end
                        % remove the empty dirs
                        rmdir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Images'), 's');
                        rmdir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'Labels'), 's');
                    end
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
        
        function imOut = loadImages(obj, fn, extension, trainingSwitch)
            % function loadImages(obj)
            % load image function for the imagedatastore
            %
            % Parameters:
            % fn: filename
            % extension: filename extension
            % trainingSwitch: logical switch, true - load for training,
            % false for prediction
            %
            
            switch extension
                case '.am'
                    getDataOptions.getMeta = false;     % do not process meta data in amiramesh files
                    getDataOptions.verbose = false;     % do not display info about loaded image
                    imOut = amiraMesh2bitmap(fn, getDataOptions);
                case {'.tif', '.png'}
                    if obj.BatchOpt.Architecture{1}(1) == '2'   % 2D networks
                        imOut = imread(fn, extension(2:end));
                    else    % 3D networks, have to use mibLoadImages function
                        getDataOptions.mibBioformatsCheck = obj.BatchOpt.BioformatsTraining;
                        getDataOptions.verbose = false;
                        imOut = mibLoadImages(fn, getDataOptions);
                    end
                otherwise
                    getDataOptions.verbose = false;
                    if trainingSwitch   % load for training
                        getDataOptions.mibBioformatsCheck = obj.BatchOpt.BioformatsTraining;
                        getDataOptions.BioFormatsIndices = obj.BatchOpt.BioformatsTrainingIndex{1};
                    else    % load for prediction
                        getDataOptions.mibBioformatsCheck = obj.BatchOpt.Bioformats;
                        getDataOptions.BioFormatsIndices = obj.BatchOpt.BioformatsIndex{1};
                    end
                    imOut = mibLoadImages(fn, getDataOptions);
            end
            
            if ndims(imOut) == 4   % strcmp(obj.BatchOpt.Architecture{1}, '3D U-net')
                imOut = permute(imOut, [1 2 4 3]);    % permute from [height, width, color, depth] -> [height, width, depth, color]
            end
        end
        
        function StartTraining(obj)
            % function StartTraining(obj)
            % perform training of the network
            global mibPath;
            global counter;     % for patch test
            counter = 1;
            
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
                preprocessedSwitch = false;
                
                msg = sprintf('!!! Warning !!!\nYou are going to start training without preprocessing!\nConfirm that your images are located under\n\n%s\n\n%s\n%s\n%s\n%s\n\nPlease also make sure that number of files with labels match number of files with images!', ...
                    obj.BatchOpt.OriginalTrainingImagesDir, ...
                    '- TrainImages', '- TrainLabels', ...
                    '- ValidationImages', '- ValidationLabels');
                
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
            obj.TrainingProgress = struct();
            obj.TrainingProgress.stopTraining = false;
            obj.TrainingProgress.emergencyBrake = false;
            trainingSwitch = 1;     % needed for providing correct data for loadImages function
            
            inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);
            if numel(inputPatchSize) ~= 4
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nPlease provide the input patch size (BatchOpt.T_InputPatchSize) as 4 numbers that define\nheight, width, depth, colors\n\nFor example:\n"32, 32, 1, 3" for 2D U-net of 3 color channel images\n"64, 64, 64, 1" for 3D U-net of 1 color channel images'), ...
                    'Wrong patch size');
                return;
            end
            
            % fix the 3rd value in the input patch size for 2D networks
            if strcmp(obj.BatchOpt.Architecture{1}(1:2), '2D') && inputPatchSize(3) > 1
                inputPatchSize(3) = 1;
                obj.BatchOpt.T_InputPatchSize = num2str(inputPatchSize);
                obj.View.handles.T_InputPatchSize.Value = obj.BatchOpt.T_InputPatchSize;
            end
            
            % make directories for export of the training scores
            if obj.BatchOpt.T_ExportTrainingPlots
                delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.csv'));     % delete all csv files
                delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.score'));     % delete all score matlab files
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
                options.Title = sprintf('Files with training checkpoints were detected.\nPlease select the checkpoint to continue, if you choose "Start new training" the checkpoint directory will be cleared from the older checkpoints and the new training session initiated:');
                options.TitleLines = 5;
                options.WindowWidth = 1.4;
                [answer, selPosition] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer); return; end
                
                switch selPosition
                    case 1  % start new training
                        if obj.BatchOpt.T_SaveProgress
                            delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.mat'));     % delete all score matlab files
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
            end
            
            trainTimer = tic;
            if obj.BatchOpt.showWaitbar
                obj.wb = waitbar(0, sprintf('Creating datastores\nPlease wait...'), ...
                    'Name', 'Training network', ...
                    'CreateCancelBtn', @obj.stopTrainingCallback);
            end
            
            % the other options are not available, require to process images
            try
                if preprocessedSwitch   % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'), ...
                        'FileExtensions', '.mibImg', 'IncludeSubfolders', false, 'ReadFcn', @mibDeepController.mibImgFileRead);
                else    % without preprocessing
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtensionTraining{1}]);
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)obj.loadImages(fn, fnExtention, trainingSwitch));
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            % get class names
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
                        options.Title = (sprintf('Attention!\nThe model file is missing in\n%s\n\nEnter material names used during preprocessing or restore the model file and restart the training', modelDir));
                        
                        options.TitleLines = 5;
                        options.WindowWidth = 2;
                        
                        answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                        if isempty(answer)
                            if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                            return;
                        end
                        classNames = strtrim(split(answer{1}, ','));    % get class names
                    else
                        modelFn = fullfile(files(1).folder, files(1).name);
                        res = load(modelFn, '-mat', 'modelMaterialNames', 'modelMaterialColors');
                        classColors = res.modelMaterialColors;  % get colors
                        classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                    end
                otherwise
                    classNames = arrayfun(@(x) sprintf('Class%.2d', x), 1:obj.BatchOpt.T_NumberOfClasses{1}-1, 'UniformOutput', false);
                    classNames = [{'Exterior'}; classNames'];
            end
            
            pixelLabelIDs = 0:numel(classNames)-1;
            
            % update number of classes variables
            obj.BatchOpt.T_NumberOfClasses{1} = numel(classNames);
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
                rng(obj.BatchOpt.T_RandomGeneratorSeed{1});
            end
            
            if preprocessedSwitch   % with preprocessing
                labelsDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'), ...
                    'FileExtensions', '.mibCat', 'IncludeSubfolders', false, ...
                    'ReadFcn', @mibDeepController.matlabCategoricalFileRead);
            else                    % without preprocessing
                switch obj.BatchOpt.ModelFilenameExtension{1}
                    case 'MODEL'
                        labelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
                            classNames, pixelLabelIDs, ...
                            'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                        
                        % I = readimage(modDS,1);  % read model test
                        % reset(modDS);
                    otherwise
                        labelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
                            classNames, pixelLabelIDs, ...
                            'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                        
                        %labelsDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels'), ...
                        %    'IncludeSubfolders', false, ...
                        %    'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                end
                
                if numel(labelsDS.Files) ~= numel(imgDS.Files)
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nIn this mode number of model files should match number of image files!\n\nCheck\n%s\n\n%s', ...
                        fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainLabels')), ...
                        'Error');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                    return;
                end
            end
            
            %% Create Random Patch Extraction Datastore for Validation
            if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, 'Create a datastore for validation ...'); end
            
            if preprocessedSwitch   % with preprocessing
                fileList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages', '*.mibImg'));
                if ~isempty(fileList)
                    %fullPathFilenames = arrayfun(@(filename) fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages', cell2mat(filename)), {fileList.name}, 'UniformOutput', false);  % generate full paths
                    valImgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'), ...
                        'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepController.mibImgFileRead);
                    
                    valLabelsDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels'), ...
                        'FileExtensions', '.mibCat', 'ReadFcn', @mibDeepController.matlabCategoricalFileRead);
                else    % do not use validation
                    valImgDS = [];
                    valLabelsDS = [];
                end
            else    % without preprocessing
                fnExtension = lower(['*.' obj.BatchOpt.ImageFilenameExtensionTraining{1}]);
                fileList = dir(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages', fnExtension));
                if ~isempty(fileList)
                    valImgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)obj.loadImages(fn, fnExtension, trainingSwitch));
                    
                    switch obj.BatchOpt.ModelFilenameExtension{1}
                        case 'MODEL'
                            valLabelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels'), ...
                                classNames, pixelLabelIDs, ...
                                'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                        otherwise
                            valLabelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels'), ...
                                classNames, pixelLabelIDs, ...
                                'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                    end
                    
                    if numel(valLabelsDS.Files) ~= numel(valImgDS.Files)
                        uialert(obj.View.gui, ...
                            sprintf('!!! Error !!!\n\nIn this mode number of model files should match number of image files!\n\nCheck\n%s\n\n%s', ...
                            fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationImages'), fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'ValidationLabels')), ...
                            'Error');
                        if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                        return;
                    end
                else    % do not use validation
                    valImgDS = [];
                    valLabelsDS = [];
                end
            end
            
            % generate random patch datastores
            switch obj.BatchOpt.Architecture{1}(1:2)
                case '3D'
                    randomStoreInputPatchSize = inputPatchSize(1:3);
                case '2D'
                    randomStoreInputPatchSize = inputPatchSize(1:2);
            end
            
            % Augmenter needs to be applied to the patches later
            % after initialization using transform function
            patchDS = randomPatchExtractionDatastore(imgDS, labelsDS, randomStoreInputPatchSize, ...
                'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1}); %#ok<ST2NM>
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
            
            %% create network
            if obj.BatchOpt.showWaitbar
                if obj.TrainingProgress.stopTraining == true; if isvalid(obj.wb); delete(obj.wb); end; return; end
                waitbar(0, obj.wb, 'Creating the network...');
            end
            
            previewSwitch = 0; % 1 - the generated network is only for preview, i.e. weights of classes won't be calculated
            [lgraph, outputPatchSize] = obj.createNetwork(previewSwitch);
            if isempty(lgraph); return; end
            
            if isempty(outputPatchSize)
                if isdeployed
                    errordlg(sprintf('Unfortunately, 3D U-Net Anisotropic architecture with the "valid" padding is not yet available in the deployed version of MIB\n\nPlease use the "same" padding instead'), 'Not implemented');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
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
                        if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                        return;
                    end
                    outputPatchSize = str2num(answer{1});
                end
            end
            
            % analyzeNetwork(lgraph);
            % network can be modified by using Deep Network Designer App
            % deepNetworkDesigner;
            
            %% Augment the training and validation data by using the transform function with custom preprocessing
            if obj.BatchOpt.showWaitbar
                if obj.TrainingProgress.stopTraining == true; if isvalid(obj.wb); delete(obj.wb); end; return; end
                waitbar(0, obj.wb, 'Defing augmentation...');
            end
            
            % operations specified by the helper function augmentAndCrop3dPatch.
            % The augmentAndCrop3dPatch function performs these operations:
            % Randomly rotate and reflect training data to make the training more robust.
            % The function does not rotate or reflect validation data.
            % Crop response patches to the output size of the network (outputPatchSize: height x width x depth x classes)
            switch obj.BatchOpt.Architecture{1}(1:2)
                case '3D'
                    if obj.BatchOpt.T_augmentation
                        status = obj.setAug3DFuncHandles(inputPatchSize);
                        if status == 0
                            if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                            return;
                        end
                        
                        AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 'aug'));
                        if ~isempty(valPatchDS)
                            valDS = transform(valPatchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 'crop'));
                        else
                            valDS = [];
                        end
                    else
                        if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                            % crop responses to the output size of the network
                            AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 'crop'));
                            if ~isempty(valPatchDS)
                                valDS = transform(valPatchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 'crop'));
                            else
                                valDS = [];
                            end
                            
                        else
                            % no cropping needed for the same padding
                            AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize, outputPatchSize, 'show'));
                            valDS = valPatchDS;
                        end
                    end
                case '2D'
                    if obj.BatchOpt.T_augmentation
                        % define augmentation
                        status = obj.setAug2DFuncHandles(inputPatchSize);
                        if status == 0
                            if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                            return;
                        end
                        AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop2dPatch(patchIn, inputPatchSize, outputPatchSize, 'aug'));
                        
                        %                         for i=1:50
                        %                             I = read(AugTrainDS);
                        %                             if size(I.inpVol{1},3) == 2
                        %                                 I.inpVol{1}(:,:,3) = zeros([size(I.inpVol{1}, 1), size(I.inpVol{1}, 2)]);
                        %                             end
                        %                             figure(1)
                        %                             imshowpair(I.inpVol{1}, uint8(I.inpResponse{1}),'montage');
                        %                         end
                        
                        if ~isempty(valPatchDS)
                            valDS = transform(valPatchDS, @(patchIn)obj.augmentAndCrop2dPatch(patchIn, inputPatchSize, outputPatchSize, 'crop'));
                        else
                            valDS = [];
                        end
                    else
                        if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                            % crop responses to the output size of the network
                            AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop2dPatch(patchIn, inputPatchSize, outputPatchSize, 'crop'));
                            if ~isempty(valPatchDS)
                                valDS = transform(valPatchDS, @(patchIn)obj.augmentAndCrop2dPatch(patchIn, inputPatchSize, outputPatchSize, 'crop'));
                            else
                                valDS = [];
                            end
                        else
                            %AugTrainDS = patchDS;  % no cropping needed for the same padding
                            %valDS = valPatchDS;
                            AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop2dPatch(patchIn, inputPatchSize, outputPatchSize, 'show'));
                            valDS = valPatchDS;
                        end
                    end
            end
            
            % calculate max number of iterations
            %obj.TrainingProgress.maxNoIter = ...        % as noImages*PatchesPerImage*MaxEpochs/Minibatch
            %    patchDS.NumObservations*obj.TrainingOpt.MaxEpochs/obj.BatchOpt.T_MiniBatchSize{1};
            obj.TrainingProgress.maxNoIter = ...        % as noImages*PatchesPerImage*MaxEpochs/Minibatch
                ceil((patchDS.NumObservations-mod(patchDS.NumObservations, obj.BatchOpt.T_MiniBatchSize{1}))/obj.BatchOpt.T_MiniBatchSize{1}) * obj.TrainingOpt.MaxEpochs;
            obj.TrainingProgress.iterPerEpoch = ...
                obj.TrainingProgress.maxNoIter / obj.TrainingOpt.MaxEpochs;
            
            % generate training options structure
            TrainingOptions = obj.preprareTrainingOptions(valDS);
            
            %% Train Network
            % After configuring the training options and the data source, train the 3-D U-Net network
            % by using the trainNetwork function.
            
            if obj.BatchOpt.showWaitbar
                if obj.TrainingProgress.stopTraining == true; if isvalid(obj.wb); delete(obj.wb); end; return; end
                if ~isvalid(obj.wb); return; end
                waitbar(0, obj.wb, sprintf('Trainining\nPlease wait...'));
            end
            
            modelDateTime = datestr(now, 'dd-mmm-yyyy-HH-MM-SS');
            
            % load the checkpoint to resume training
            if ~isempty(checkPointRestoreFile)
                if obj.BatchOpt.showWaitbar; if ~isvalid(obj.wb); return; end; waitbar(0, obj.wb, sprintf('Loading checkpoint...\nPlease wait...')); end
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
                        sprintf('!!! Warning !!!\n\nThe class names of the loaded network do not match class names of the training model\n\nModel classes:%s\nNetwork classes: %s\n\nPress "Update network" to modify the network with new model class names', ...
                        strjoin(string(classNames), ', '), strjoin(cellstr(outLayer.Classes), ', ')),...
                        'Class names mismatch', 'Options',{'Update network','Cancel'}, 'Icon', 'warning');
                    if strcmp(selection, 'Cancel')
                        if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                        return;
                    end
                    
                    %outLayer.Classes = categorical(classNames);    % this syntax gives an error in trainNetwork when used with tranfer learning
                    outLayer.Classes = classNames;
                    lgraph = replaceLayer(lgraph, outPutLayerName{1}, outLayer);
                end
                if obj.BatchOpt.showWaitbar; if ~isvalid(obj.wb); return; end; waitbar(0.06, obj.wb, sprintf('Loading checkpoint...done\nPlease wait...')); end
            end
            
            if obj.BatchOpt.showWaitbar; if ~isvalid(obj.wb); return; end; waitbar(0.08, obj.wb, sprintf('Preparing structures\nand saving configs...')); end
            BatchOpt = obj.BatchOpt;
            % generate TrainingOptStruct, because TrainingOptions is
            % 'TrainingOptionsADAM' class
            AugOpt2DStruct = obj.AugOpt2D;
            AugOpt3DStruct = obj.AugOpt3D;
            InputLayerOpt = obj.InputLayerOpt;
            TrainingOptStruct = obj.TrainingOpt;
            
            % generate config file; the config file is the same as *.mibDeep but without 'net' field
            [configPath, configFn] = fileparts(obj.BatchOpt.NetworkFilename);
            obj.saveConfig(fullfile(configPath, [configFn '.mibCfg']));
            
            if obj.BatchOpt.showWaitbar; if ~isvalid(obj.wb); return; end; waitbar(0.1, obj.wb, sprintf('Training network\nplease wait...')); end
            fprintf('Preparation for training is finished, elapsed time: %f\n', toc(trainTimer));
            trainTimer = tic;
            try
                [net, info] = trainNetwork(AugTrainDS, lgraph, TrainingOptions);
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s', err.message), 'Train network error');
                if obj.BatchOpt.showWaitbar; if isvalid(obj.wb); delete(obj.wb); end; end
                return;
            end
            
            %save(fullfile(outputDir, ['Trained3DUNet-' modelDateTime '-Epoch-' num2str(options.MaxEpochs) '.net']), 'net');
            if obj.BatchOpt.showWaitbar;  if ~isvalid(obj.wb); return; end; waitbar(0.98, obj.wb, 'Saving network...'); end
            %[outputDir, netName, Ext] = fileparts(obj.BatchOpt.NetworkFilename);
            %save(fullfile(outputDir, ['Trained3DUNet_' ProjectName '.net']), 'net');
            
            % do emergency brake, use the recent check point for restoring the
            % network parameters
            if obj.TrainingProgress.emergencyBrake && (obj.BatchOpt.Architecture{1}(1) == '3' || strcmp(obj.BatchOpt.Architecture{1}, '2D SegNet'))
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
                'classNames', 'classColors', 'inputPatchSize', 'outputPatchSize', 'BatchOpt', '-mat', '-v7.3');
            
            if obj.BatchOpt.T_ExportTrainingPlots
                if obj.BatchOpt.showWaitbar; if ~isvalid(obj.wb); return; end; waitbar(0.99, obj.wb, 'Saving training plots...'); end
                [~, fnTemplate] = fileparts(obj.BatchOpt.NetworkFilename);
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
            if obj.BatchOpt.showWaitbar; if ~isvalid(obj.wb); return; end; waitbar(1, obj.wb, 'Done!'); delete(obj.wb); end
            obj.TrainingProgress.StopTrainingButton.BackgroundColor = [0 1 0];
            obj.TrainingProgress.StopTrainingButton.Text = 'Finished!!!'; 
            fprintf('Training is finished, elapsed time: %f\n', toc(trainTimer));
        end
        
        function TrainingOptions = preprareTrainingOptions(obj, valDS)
            % function TrainingOptions = preprareTrainingOptions(obj, valDS)
            % prepare trainig options for the network training
            %
            % Parameters:
            % valDS: datastore with images for validation
            
            
            %% Specify Training Options
            % update ResetInputNormalization when obj.InputLayerOpt.Mean,
            % .StandardDeviation, .Min, .Max are defined
            ResetInputNormalization = true;
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
                obj.TrainingProgress.useCustomProgressPlot = 0;
            else
                obj.TrainingProgress.useCustomProgressPlot = obj.BatchOpt.O_CustomTrainingProgressWindow;
            end
            
            if isdeployed
                PlotsSwitch = 'none';
            else
                if obj.TrainingProgress.useCustomProgressPlot
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
                % and define ExecutionEnvironment
                selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
                switch obj.View.Figure.GPUDropDown.Value
                    case 'CPU only'
                        if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                            gpuDevice([]);  % CPU only mode
                        end
                        ExecutionEnvironment = 'cpu';
                    case 'Multi-GPU'
                        ExecutionEnvironment = 'multi-gpu';
                    case 'Parallel'
                        ExecutionEnvironment = 'parallel';
                    otherwise
                        gpuDevice(selectedIndex);   % choose selected GPU device
                        ExecutionEnvironment = 'gpu';
                end
                
                % recalculate validation frequency from epochs to
                % interations
                ValidationFrequencyInIterations = ceil(obj.TrainingProgress.iterPerEpoch / obj.TrainingOpt.ValidationFrequency);
                
                switch obj.TrainingOpt.solverName
                    case 'adam'
                        if ~isempty(valDS)
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'GradientDecayFactor', obj.TrainingOpt.GradientDecayFactor, ...
                                'SquaredGradientDecayFactor', obj.TrainingOpt.SquaredGradientDecayFactor, ...
                                'ValidationData', valDS, ...
                                'ValidationFrequency', ValidationFrequencyInIterations, ...
                                'ValidationPatience', obj.TrainingOpt.ValidationPatience, ...
                                'Plots', PlotsSwitch, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1},...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath,...
                                'ExecutionEnvironment', ExecutionEnvironment);
                        else
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'GradientDecayFactor', obj.TrainingOpt.GradientDecayFactor, ...
                                'SquaredGradientDecayFactor', obj.TrainingOpt.SquaredGradientDecayFactor, ...
                                'Plots', PlotsSwitch, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1},...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath, ...
                                'ExecutionEnvironment', ExecutionEnvironment);
                        end
                    case 'rmsprop'
                        if ~isempty(valDS)
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'SquaredGradientDecayFactor', obj.TrainingOpt.SquaredGradientDecayFactor, ...
                                'ValidationData', valDS, ...
                                'ValidationFrequency', ValidationFrequencyInIterations, ...
                                'ValidationPatience', obj.TrainingOpt.ValidationPatience, ...
                                'Plots', PlotsSwitch, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1},...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath,...
                                'ExecutionEnvironment', ExecutionEnvironment);
                        else
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'SquaredGradientDecayFactor', obj.TrainingOpt.SquaredGradientDecayFactor, ...
                                'Plots', PlotsSwitch, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1},...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath, ...
                                'ExecutionEnvironment', ExecutionEnvironment);
                        end
                    case 'sgdm'
                        if ~isempty(valDS)
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'Momentum', obj.TrainingOpt.Momentum, ...
                                'Plots', PlotsSwitch, ...
                                'ValidationData', valDS, ...
                                'ValidationFrequency', ValidationFrequencyInIterations, ...
                                'ValidationPatience', obj.TrainingOpt.ValidationPatience, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1}, ...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath,...
                                'ExecutionEnvironment', ExecutionEnvironment);
                        else
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'Momentum', obj.TrainingOpt.Momentum, ...
                                'Plots', PlotsSwitch, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1}, ...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath, ...
                                'ExecutionEnvironment', ExecutionEnvironment);
                        end
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Wrong training options');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); return; end
            end
        end
        
        function updatePreprocessingMode(obj)
            % function updatePreprocessingMode(obj)
            % callback for change of selection in the Preprocess for dropdown
            
            obj.BatchOpt.PreprocessingMode{1} = obj.View.handles.PreprocessingMode.Value;
            if strcmp(obj.View.handles.PreprocessingMode.Value, 'Preprocessing is not required') || strcmp(obj.View.handles.PreprocessingMode.Value, 'Split files for training/validation')
                obj.BatchOpt.MaskAway = false;
                obj.BatchOpt.SingleModelTrainingFile = false;
            else
                
            end
            obj.updateWidgets();
        end
        
        
        function saveConfig(obj, configName)
            % function saveConfig(obj, filename)
            % save Deep MIB configuration to a file
            %
            % Parameters:
            % configName: [optional] string, full filename for the config
            % file
            
            if nargin < 2
                [path, file] = fileparts(obj.BatchOpt.NetworkFilename);
                [file, path]  = uiputfile({'*.mibCfg', 'mibDeep config files (*.mibCfg)';
                    '*.mat', 'Mat files (*.mat)'}, 'Select config file', ...
                    fullfile(path, file));
                if file == 0; return; end
                
                configName = fullfile(path, file);
            else
                path = fileparts(configName);
            end
            if ~strcmp(path(end), filesep)   % remove the ending slash
                path = [path filesep];
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
            
            % try to export path as relatives
            BatchOpt.NetworkFilename = strrep(BatchOpt.NetworkFilename, path, '[RELATIVE]'); %#ok<*PROP>
            BatchOpt.OriginalTrainingImagesDir = strrep(BatchOpt.OriginalTrainingImagesDir, path, '[RELATIVE]');
            BatchOpt.OriginalPredictionImagesDir = strrep(BatchOpt.OriginalPredictionImagesDir, path, '[RELATIVE]');
            BatchOpt.ResultingImagesDir = strrep(BatchOpt.ResultingImagesDir, path, '[RELATIVE]');
            
            % generate config file; the config file is the same as *.mibDeep but without 'net' field
            save(configName, ...
                'TrainingOptStruct', 'AugOpt2DStruct', 'AugOpt3DStruct', ...
                'SegmentationLayerOpt', 'ActivationLayerOpt', ...
                'InputLayerOpt', 'BatchOpt', '-mat', '-v7.3');
        end
        
        function loadConfig(obj)
            % function loadConfig(obj)
            % load config file with Deep MIB settings
            
            [file, path] = mib_uigetfile({'*.mibCfg;', 'Deep MIB config files (*.mibCfg)';
                '*.mat', 'Mat files (*.mat)'}, 'Open network file', ...
                obj.BatchOpt.NetworkFilename);
            if file == 0; return; end
            configName = fullfile(path, file);
            
            obj.wb = waitbar(0, sprintf('Loading config file\nPlease wait...'));
            
            res = load(configName, '-mat');
            
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
            res.BatchOpt.NetworkFilename = strrep(res.BatchOpt.NetworkFilename, '[RELATIVE]', path); %#ok<*PROP>
            res.BatchOpt.OriginalTrainingImagesDir = strrep(res.BatchOpt.OriginalTrainingImagesDir, '[RELATIVE]', path);
            res.BatchOpt.OriginalPredictionImagesDir = strrep(res.BatchOpt.OriginalPredictionImagesDir, '[RELATIVE]', path);
            res.BatchOpt.ResultingImagesDir = strrep(res.BatchOpt.ResultingImagesDir, '[RELATIVE]', path);
            
            if ~isfield(res.BatchOpt, 'T_ActivationLayer')
                res.BatchOpt.T_ActivationLayer = {'reluLayer'};
                res.BatchOpt.T_ActivationLayer{2} = {'reluLayer', 'leakyReluLayer', 'clippedReluLayer', 'eluLayer', 'tanhLayer'};
            end
            
            % add/update BatchOpt with the provided fields in BatchOptIn
            % combine fields from input and default structures
            obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, res.BatchOpt);
            
            try
                obj.AugOpt2D = mibConcatenateStructures(obj.AugOpt2D, res.AugOpt2DStruct);
                obj.AugOpt3D = mibConcatenateStructures(obj.AugOpt3D, res.AugOpt3DStruct);
                obj.TrainingOpt = mibConcatenateStructures(obj.TrainingOpt, res.TrainingOptStruct);
                % fix an old parameter that is no longer in use
                if strcmp(obj.TrainingOpt.Plots, 'training-progress-Matlab'); obj.TrainingOpt.Plots = 'training-progress'; end
                obj.InputLayerOpt = mibConcatenateStructures(obj.InputLayerOpt, res.InputLayerOpt);
                
                if isfield(res, 'ActivationLayerOpt')   % new in MIB 2.71
                    obj.ActivationLayerOpt = mibConcatenateStructures(obj.ActivationLayerOpt, res.ActivationLayerOpt);
                    obj.SegmentationLayerOpt = mibConcatenateStructures(obj.SegmentationLayerOpt, res.SegmentationLayerOpt);
                end
            catch err
                % when the training was stopped before finish,
                % those structures are not stored
            end
            
            obj.updateWidgets();
            
            waitbar(1, obj.wb);
            delete(obj.wb);
        end
        
        function stopTrainingCallback(obj, varargin)
            % callback for press of the Stop traininig button
            
            if strcmp(obj.TrainingProgress.StopTrainingButton.Text, 'Finished!!!'); return; end
            
            obj.TrainingProgress.stopTraining = true;
            if strcmp(varargin{2}.Source.Tag, 'TMWWaitbar')     % waitbar
                delete(varargin{2}.Source);
                return;
            end
            if strcmp(varargin{2}.EventName, 'Close')   % close training progress window
                if isfield(obj.TrainingProgress, 'UIFigure')    % otherwise it will try to trigger this upon X-button press of the waitbar
                    delete(obj.TrainingProgress.UIFigure);
                end
            end
            
            % instant training stop with generation of mibDeep file from
            % the recent checkpoint
            if isprop(varargin{1}, 'Text') && strcmp(varargin{1}.Text, 'Emergency Brake')
                if obj.BatchOpt.Architecture{1}(1) == '3' || strcmp(obj.BatchOpt.Architecture{1}, '2D SegNet')
                    answer = questdlg(sprintf('!!! Warning !!!\n\nThe current network architecture has BatchNormalization layers which requires calculation of final means and variances to finalize the network.\n\nIf you are not planning to use the network or planning to continue training in future this step may be skipped (Stop immediately), otherwise cancel and stop the run normally (Stop and finalize)'), ...
                        'Emergency brake', ...
                        'Stop immediately', 'Stop and finalize', 'Stop and finalize');
                    if strcmp(answer, 'Stop immediately')
                        obj.TrainingProgress.emergencyBrake = true;
                        return;
                    end
                else
                    obj.TrainingProgress.emergencyBrake = true;
                end
            end
            obj.TrainingProgress.StopTrainingButton.Text = 'Stopping...';
            obj.TrainingProgress.StopTrainingButton.BackgroundColor = [1 .5 0];
        end
        
        function result = trainingProgressDisplay(obj, ProgressStruct)
            % function res = trainingProgressDisplay(obj, ProgressStruct)
            % display network training progress for the compiled MIB
            %
            % Parameters:
            % ProgressStruct: a structure with various training parameters
            %
            % Return values:
            % result: a logical switch controlling stop of the training.
            % When false - continue, when true - stop
            
            % this block controls execusion in MIB-Matlab and when verbose
            % is on
            
            if ~obj.TrainingProgress.useCustomProgressPlot  % for debug of isdeploy
                if strcmp(obj.TrainingOpt.Plots, 'none') || ~isdeployed()
                    result = obj.TrainingProgress.stopTraining;
                    drawnow;
                    return;
                end   % skip gui window if the progress plot is none
            end
            
            result = false;
            maxPoints = obj.BatchOpt.O_NumberOfPoints{1};     % max number of points in the plots, should be an even number
            if ProgressStruct.Iteration == 0
                obj.TrainingProgress.TrainXvec = zeros([maxPoints, 1]);  % vector of iteration numbers for training
                obj.TrainingProgress.TrainLoss = zeros([maxPoints, 1]);  % training loss vector
                obj.TrainingProgress.TrainAccuracy = zeros([maxPoints, 1]);  % training accuracy vector
                obj.TrainingProgress.ValidationXvec = zeros([maxPoints, 1]);     % vector of iteration numbers for validation
                obj.TrainingProgress.ValidationLoss = zeros([maxPoints, 1]); % validation loss vector
                obj.TrainingProgress.ValidationAccuracy = zeros([maxPoints, 1]); % validation accuracy vector
                obj.TrainingProgress.TrainXvecIndex = 1;    % index of the next point to be added to the training vectors
                obj.TrainingProgress.ValidationXvecIndex = 1; % index of the next point to be added to the validation vectors
                
                % Create progress window
                [~, netName] = fileparts(obj.BatchOpt.NetworkFilename);
                obj.TrainingProgress.UIFigure = uifigure('Visible', 'off');
                ScreenSize = get(0, 'ScreenSize');
                FigPos(1) = 1/2*(ScreenSize(3)-800);
                FigPos(2) = 2/3*(ScreenSize(4)-600);
                obj.TrainingProgress.UIFigure.Position = [FigPos(1), FigPos(2), 800, 600];
                obj.TrainingProgress.UIFigure.Name = sprintf('Training progress (%s)', netName);
                
                % Create GridLayouts
                obj.TrainingProgress.GridLayout = uigridlayout(obj.TrainingProgress.UIFigure);
                obj.TrainingProgress.GridLayout.ColumnWidth = {'1x'};
                
                obj.TrainingProgress.GridLayout2 = uigridlayout(obj.TrainingProgress.GridLayout);
                obj.TrainingProgress.GridLayout2.ColumnWidth = {'0.8x', '3.2x', '2x'};
                obj.TrainingProgress.GridLayout2.RowHeight = {'1x'};
                obj.TrainingProgress.GridLayout2.Layout.Row = 2;
                obj.TrainingProgress.GridLayout2.Layout.Column = 1;
                
                % Create Panels
                obj.TrainingProgress.AccuracyPanel = uipanel(obj.TrainingProgress.GridLayout2);
                obj.TrainingProgress.AccuracyPanel.Title = 'Accuracy';
                obj.TrainingProgress.AccuracyPanel.Layout.Row = 1;
                obj.TrainingProgress.AccuracyPanel.Layout.Column = 1;
                
                obj.TrainingProgress.InformationPanel = uipanel(obj.TrainingProgress.GridLayout2);
                obj.TrainingProgress.InformationPanel.Title = 'Information';
                obj.TrainingProgress.InformationPanel.Layout.Row = 1;
                obj.TrainingProgress.InformationPanel.Layout.Column = 2;
                
                obj.TrainingProgress.InputPatchPreviewPanel = uipanel(obj.TrainingProgress.GridLayout2);
                obj.TrainingProgress.InputPatchPreviewPanel.Title = 'Input patch preview';
                obj.TrainingProgress.InputPatchPreviewPanel.Layout.Row = 1;
                obj.TrainingProgress.InputPatchPreviewPanel.Layout.Column = 3;
                
                % Create widgets
                obj.TrainingProgress.AccTrainGauge = uigauge(obj.TrainingProgress.AccuracyPanel, 'linear');
                obj.TrainingProgress.AccTrainGauge.Orientation = 'vertical';
                obj.TrainingProgress.AccTrainGauge.Position = [6 28 40 190];
                
                obj.TrainingProgress.AccValGauge = uigauge(obj.TrainingProgress.AccuracyPanel, 'linear');
                obj.TrainingProgress.AccValGauge.Orientation = 'vertical';
                obj.TrainingProgress.AccValGauge.Position = [54 28 40 190];
                
                obj.TrainingProgress.TrainingLabel = uilabel(obj.TrainingProgress.AccuracyPanel);
                obj.TrainingProgress.TrainingLabel.Position = [10 221 48 22];
                obj.TrainingProgress.TrainingLabel.Text = 'Train';
                
                obj.TrainingProgress.ValidationLabel = uilabel(obj.TrainingProgress.AccuracyPanel);
                obj.TrainingProgress.ValidationLabel.HorizontalAlignment = 'center';
                obj.TrainingProgress.ValidationLabel.Position = [46 221 57 22];
                obj.TrainingProgress.ValidationLabel.Text = 'Valid.';
                
                obj.TrainingProgress.AccTrainingValue = uilabel(obj.TrainingProgress.AccuracyPanel);
                obj.TrainingProgress.AccTrainingValue.Position = [7 3 48 22];
                obj.TrainingProgress.AccTrainingValue.Text = '0';
                
                obj.TrainingProgress.AccValidationValue = uilabel(obj.TrainingProgress.AccuracyPanel);
                obj.TrainingProgress.AccValidationValue.Position = [55 3 48 22];
                obj.TrainingProgress.AccValidationValue.Text = '0';
                
                obj.TrainingProgress.TrainingProgress = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.TrainingProgress.FontWeight = 'bold';
                obj.TrainingProgress.TrainingProgress.Position = [7 218 107 22];
                obj.TrainingProgress.TrainingProgress.Text = 'Training progress';
                
                obj.TrainingProgress.StartTime = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.StartTime.Position = [7 196 175 22];
                obj.TrainingProgress.StartTime.Text = sprintf('Started: %s', datetime(now,'ConvertFrom','datenum'));
                
                obj.TrainingProgress.ElapsedTime = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.ElapsedTime.Position = [7 176 175 22];
                obj.TrainingProgress.ElapsedTime.Text = 'Elapsed: --.--.--';
                
                obj.TrainingProgress.TimeToGo = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.TimeToGo.Position = [7 156 175 22];
                obj.TrainingProgress.TimeToGo.Text = 'Time to go: --.--.--';
                
                obj.TrainingProgress.ProgressGauge = uigauge(obj.TrainingProgress.InformationPanel, 'semicircular');
                obj.TrainingProgress.ProgressGauge.Position = [30 5 120 65];
                
                obj.TrainingProgress.Epoch = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.Epoch.Position = [7 120 170 22];
                obj.TrainingProgress.Epoch.Text = sprintf('Epoch: 0 of %d', obj.TrainingOpt.MaxEpochs);
                
                obj.TrainingProgress.IterationNumber = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.IterationNumber.Position = [7 100 170 22];
                obj.TrainingProgress.IterationNumber.Text = 'Iteration number:';
                
                obj.TrainingProgress.IterationNumberValue = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.IterationNumberValue.Position = [26 80 160 22];
                obj.TrainingProgress.IterationNumberValue.Text = sprintf('0 of %d', obj.TrainingProgress.iterPerEpoch*obj.TrainingOpt.MaxEpochs);
                
                obj.TrainingProgress.TrainingOptions = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.TrainingOptions.FontWeight = 'bold';
                obj.TrainingProgress.TrainingOptions.Position = [192 217 99 22];
                obj.TrainingProgress.TrainingOptions.Text = 'Training options';
                
                obj.TrainingProgress.IterationsPerEpoch = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.IterationsPerEpoch.Position = [192 196 202 22];
                obj.TrainingProgress.IterationsPerEpoch.Text = sprintf('Iterations per epoch: %d', obj.TrainingProgress.iterPerEpoch);
                
                obj.TrainingProgress.Solver = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.Solver.Position = [192 176 202 22];
                obj.TrainingProgress.Solver.Text = sprintf('Solver name: %s', obj.TrainingOpt.solverName);
                
                obj.TrainingProgress.Shuffle = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.Shuffle.Position = [192 156 202 22];
                obj.TrainingProgress.Shuffle.Text = sprintf('Shuffle: %s', obj.TrainingOpt.Shuffle);
                
                obj.TrainingProgress.LearnRateSchedule = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.LearnRateSchedule.Position = [192 136 202 22];
                obj.TrainingProgress.LearnRateSchedule.Text = sprintf('Learn rate schedule: %s', obj.TrainingOpt.LearnRateSchedule);
                
                obj.TrainingProgress.InitialLearnRate = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.InitialLearnRate.Position = [192 106 202 22];
                obj.TrainingProgress.InitialLearnRate.Text = sprintf('Initial learn rate: %f', obj.TrainingOpt.InitialLearnRate);
                
                obj.TrainingProgress.LearnRateDropPeriod = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.LearnRateDropPeriod.Position = [192 86 202 22];
                obj.TrainingProgress.LearnRateDropPeriod.Text = sprintf('LearnRate Drop Period: %d', obj.TrainingOpt.LearnRateDropPeriod);
                
                obj.TrainingProgress.ValidationPatience = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.ValidationPatience.Position = [192 66 202 22];
                obj.TrainingProgress.ValidationPatience.Text = sprintf('Validation patience: %d', obj.TrainingOpt.ValidationPatience);
                
                obj.TrainingProgress.ValidationFrequency = uilabel(obj.TrainingProgress.InformationPanel);
                obj.TrainingProgress.ValidationFrequency.Position = [192 46 202 22];
                obj.TrainingProgress.ValidationFrequency.Text = sprintf('Validation frequency: %.1f /epoch', obj.TrainingOpt.ValidationFrequency);
                
                obj.TrainingProgress.StopTrainingButton = uibutton(obj.TrainingProgress.InputPatchPreviewPanel, 'push',...
                    'ButtonPushedFcn', @obj.stopTrainingCallback);
                obj.TrainingProgress.StopTrainingButton.BackgroundColor = [0 1 0];
                obj.TrainingProgress.StopTrainingButton.Position = [140 8 100 22];
                obj.TrainingProgress.StopTrainingButton.Text = 'Stop training';
                obj.TrainingProgress.StopTrainingButton.Tooltip = 'Stop and finalize the run, it may take significant time for large datasets';
                
                obj.TrainingProgress.EmergencyBrakeButton = uibutton(obj.TrainingProgress.InputPatchPreviewPanel, 'push',...
                    'ButtonPushedFcn', @obj.stopTrainingCallback);
                obj.TrainingProgress.EmergencyBrakeButton.BackgroundColor = [1 0 0];
                obj.TrainingProgress.EmergencyBrakeButton.Position = [101 39 139 22];
                obj.TrainingProgress.EmergencyBrakeButton.Text = 'Emergency brake';
                obj.TrainingProgress.EmergencyBrakeButton.Tooltip = 'Instantly stop the run, the final network file will be generated from the recent existing checkpoint';
                
                % Create axes
                obj.TrainingProgress.UILossAxes = uiaxes(obj.TrainingProgress.GridLayout);
                obj.TrainingProgress.UILossAxes.Units = 'pixels';
                title(obj.TrainingProgress.UILossAxes, 'Loss function plot');
                xlabel(obj.TrainingProgress.UILossAxes, 'Iteration');
                ylabel(obj.TrainingProgress.UILossAxes, {'Loss value'; ''});
                obj.TrainingProgress.UILossAxes.XGrid = 'on';
                obj.TrainingProgress.UILossAxes.YGrid = 'on';
                obj.TrainingProgress.UILossAxes.Layout.Row = 1;
                obj.TrainingProgress.UILossAxes.Layout.Column = 1;
                obj.TrainingProgress.hPlot = plot(obj.TrainingProgress.UILossAxes, 0, 0, '-', 0, 0, '-o');
                obj.TrainingProgress.hPlot(2).MarkerSize = 4;
                obj.TrainingProgress.hPlot(2).MarkerFaceColor = 'r';
                legend(obj.TrainingProgress.UILossAxes, 'Training', 'Validation');
                
                obj.TrainingProgress.imgPatch = uiaxes(obj.TrainingProgress.InputPatchPreviewPanel);
                obj.TrainingProgress.imgPatch.XTick = [];
                obj.TrainingProgress.imgPatch.XTickLabel = '';
                obj.TrainingProgress.imgPatch.YTick = [];
                obj.TrainingProgress.imgPatch.YTickLabel = '';
                obj.TrainingProgress.imgPatch.XColor = 'none';
                obj.TrainingProgress.imgPatch.YColor = 'none';
                obj.TrainingProgress.imgPatch.Position = [6 123 116 116];
                obj.TrainingProgress.imgPatch.Box = 'on';
                obj.TrainingProgress.imgPatch.Units = 'pixels';
                obj.TrainingProgress.imgPatch.DataAspectRatio = [1 1 1];
                noColors = str2num(obj.BatchOpt.T_InputPatchSize);  % set colormap
                noColors = noColors(4);
                if noColors == 1; obj.TrainingProgress.imgPatch.Colormap = colormap(gray); end
                
                obj.TrainingProgress.labelPatch = uiaxes(obj.TrainingProgress.InputPatchPreviewPanel);
                obj.TrainingProgress.labelPatch.XTick = [];
                obj.TrainingProgress.labelPatch.XTickLabel = '';
                obj.TrainingProgress.labelPatch.YTick = [];
                obj.TrainingProgress.labelPatch.YTickLabel = '';
                obj.TrainingProgress.labelPatch.XColor = 'none';
                obj.TrainingProgress.labelPatch.YColor = 'none';
                obj.TrainingProgress.labelPatch.Position = [127 123 116 116];
                obj.TrainingProgress.labelPatch.Box = 'on';
                obj.TrainingProgress.labelPatch.Units = 'pixels';
                obj.TrainingProgress.labelPatch.DataAspectRatio = [1 1 1];
                
                % Show the figure after all components are created
                obj.TrainingProgress.UIFigure.Visible = 'on';
                obj.TrainingProgress.maxIter = obj.TrainingProgress.iterPerEpoch*obj.TrainingOpt.MaxEpochs;
                obj.TrainingProgress.stopTraining = false;
                
            else
                if obj.TrainingProgress.stopTraining == true % stop training
                    result = true;
                    return;
                end
                
                % draw plot for eath 5th iteration or for validation loss
                % check
                if mod(ProgressStruct.Iteration, obj.BatchOpt.O_RefreshRateIter{1}) ~= 1 && isempty(ProgressStruct.ValidationLoss); return; end
                
                obj.TrainingProgress.TrainXvec(obj.TrainingProgress.TrainXvecIndex) = ProgressStruct.Iteration;
                obj.TrainingProgress.TrainLoss(obj.TrainingProgress.TrainXvecIndex) = ProgressStruct.TrainingLoss;
                obj.TrainingProgress.TrainAccuracy(obj.TrainingProgress.TrainXvecIndex) = ProgressStruct.TrainingAccuracy;
                obj.TrainingProgress.TrainXvecIndex = obj.TrainingProgress.TrainXvecIndex + 1;
                
                obj.TrainingProgress.hPlot(1).XData = obj.TrainingProgress.TrainXvec(1:obj.TrainingProgress.TrainXvecIndex-1);
                obj.TrainingProgress.hPlot(1).YData = obj.TrainingProgress.TrainLoss(1:obj.TrainingProgress.TrainXvecIndex-1);
                obj.TrainingProgress.AccTrainGauge.Value = ProgressStruct.TrainingAccuracy;
                obj.TrainingProgress.AccTrainingValue.Text = sprintf('%.2f%%', ProgressStruct.TrainingAccuracy);
                
                obj.TrainingProgress.ElapsedTime.Text = ...
                    sprintf('Elapsed time: %.0f h %.0f min %.2d sec', floor(ProgressStruct.TimeSinceStart/3600), floor(mod(round(ProgressStruct.TimeSinceStart),3600)/60), mod(round(ProgressStruct.TimeSinceStart),60));
                timerValue = ProgressStruct.TimeSinceStart/ProgressStruct.Iteration*(obj.TrainingProgress.maxNoIter-ProgressStruct.Iteration);
                obj.TrainingProgress.TimeToGo.Text = ...
                    sprintf('Time to go: ~%.0f h %.0f min %.2d sec', floor(timerValue/3600), floor(mod(round(timerValue),3600)/60), mod(round(timerValue),60));
                obj.TrainingProgress.Epoch.Text = sprintf('Epoch: %d of %d', ProgressStruct.Epoch, obj.TrainingOpt.MaxEpochs);
                obj.TrainingProgress.IterationNumberValue.Text = sprintf('%d of %d', ProgressStruct.Iteration, round(obj.TrainingProgress.maxIter));
                obj.TrainingProgress.ProgressGauge.Value = ProgressStruct.Iteration/obj.TrainingProgress.maxIter*100;
                
                if ~isempty(ProgressStruct.ValidationLoss)
                    obj.TrainingProgress.ValidationXvec(obj.TrainingProgress.ValidationXvecIndex) = ProgressStruct.Iteration;
                    obj.TrainingProgress.ValidationLoss(obj.TrainingProgress.ValidationXvecIndex) = ProgressStruct.ValidationLoss;
                    obj.TrainingProgress.ValidationAccuracy(obj.TrainingProgress.ValidationXvecIndex) = ProgressStruct.ValidationAccuracy;
                    obj.TrainingProgress.ValidationXvecIndex = obj.TrainingProgress.ValidationXvecIndex + 1;
                    
                    obj.TrainingProgress.hPlot(2).XData = obj.TrainingProgress.ValidationXvec(1:obj.TrainingProgress.ValidationXvecIndex-1);
                    obj.TrainingProgress.hPlot(2).YData = obj.TrainingProgress.ValidationLoss(1:obj.TrainingProgress.ValidationXvecIndex-1);
                    obj.TrainingProgress.AccValGauge.Value = ProgressStruct.ValidationAccuracy;
                    obj.TrainingProgress.AccValidationValue.Text = sprintf('%.2f%%', ProgressStruct.ValidationAccuracy);
                    
                end
                drawnow;
                
                % decrease number of points
                if obj.TrainingProgress.TrainXvecIndex > maxPoints
                    obj.TrainingProgress.TrainXvecIndex = maxPoints/2+1;
                    linvec = linspace(1, obj.TrainingProgress.TrainXvec(maxPoints), maxPoints/2);
                    obj.TrainingProgress.TrainLoss(1:maxPoints/2) = ...
                        interp1(obj.TrainingProgress.TrainXvec, obj.TrainingProgress.TrainLoss, linvec);
                    obj.TrainingProgress.TrainAccuracy(1:maxPoints/2) = ...
                        interp1(obj.TrainingProgress.TrainXvec, obj.TrainingProgress.TrainAccuracy, linvec);
                    obj.TrainingProgress.TrainXvec(1:maxPoints/2) = linvec;
                end
                
                if obj.TrainingProgress.ValidationXvecIndex > maxPoints
                    obj.TrainingProgress.ValidationXvecIndex = maxPoints/2+1;
                    linvec = linspace(1, obj.TrainingProgress.ValidationXvec(maxPoints), maxPoints/2);
                    obj.TrainingProgress.ValidationLoss(1:maxPoints/2) = ...
                        interp1(obj.TrainingProgress.ValidationXvec, obj.TrainingProgress.ValidationLoss, linvec);
                    obj.TrainingProgress.ValidationAccuracy(1:maxPoints/2) = ...
                        interp1(obj.TrainingProgress.ValidationXvec, obj.TrainingProgress.ValidationAccuracy, linvec);
                    obj.TrainingProgress.ValidationXvec(1:maxPoints/2) = linvec;
                    
                    obj.TrainingProgress.ValidationLoss(2:maxPoints/2) = ...
                        (obj.TrainingProgress.ValidationLoss(2:2:maxPoints-1) + obj.TrainingProgress.ValidationLoss(3:2:maxPoints)) / 2;
                    obj.TrainingProgress.ValidationAccuracy(2:maxPoints/2) = ...
                        (obj.TrainingProgress.ValidationAccuracy(2:2:maxPoints-1) + obj.TrainingProgress.ValidationAccuracy(3:2:maxPoints)) / 2;
                end
            end
        end
        
        function StartPredictionBigImage2D(obj)
            % function StartPredictionBigImage2D(obj)
            % predict datasets for 2D using bigimage method
            
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
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
                generateScoreFiles = 1;
                saveImageOpt.dimOrder = 'yxczt';    % for 2D or saveImageOpt.dimOrder = 'yxzct'; for 3D
                switch obj.BatchOpt.P_ScoreFiles{1}
                    case 'Use AM format'
                        generateScoreFilesFormat = 1;
                    case 'Use Matlab non-compressed format'
                        generateScoreFilesFormat = 2;
                    case 'Use Matlab compressed format'
                        generateScoreFilesFormat = 3;
                end
            end
            
            if obj.BatchOpt.showWaitbar; pwb = PoolWaitbar(1, 'Creating image store for prediction...', [], 'Predicting dataset'); end
            
            % creating output directories
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
            trainingSwitch = 0;     % required for correct reading of files with bioformats reader
            % make a datastore for images
            try
                if preprocessedSwitch   % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), ...
                        'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepController.mibImgFileRead);
                else    % without preprocessing
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]);
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)obj.loadImages(fn, fnExtention, trainingSwitch));
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            if obj.BatchOpt.showWaitbar;  pwb.updateText('Loading network...'); end
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
                pwb.updateText(sprintf('Starting prediction\nPlease wait...'));
                pwb.increaseMaxNumberOfIterations(noFiles);
            end
            id = 1;     % indices of files
            patchCount = 1; % counter of processed patches
            %% TO DO:
            % 1. check situation, when the dataset for prediction is
            % smaller that then dataset for training: 2D and 3D cases
            % 2. check different padvalue in the code below: volPadded = padarray (vol, padSize, 0, 'post');
            
            nDims = 2;  % number of dimensions for data, 2
            
            % select gpu or cpu for prediction and define ExecutionEnvironment
            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            switch obj.View.Figure.GPUDropDown.Value
                case 'CPU only'
                    if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                        gpuDevice([]);  % CPU only mode
                    end
                    ExecutionEnvironment = 'cpu';
                case 'Multi-GPU'
                    ExecutionEnvironment = 'multi-gpu';
                case 'Parallel'
                    ExecutionEnvironment = 'parallel';
                otherwise
                    gpuDevice(selectedIndex);   % choose selected GPU device
                    ExecutionEnvironment = 'gpu';
            end
            
            while hasdata(imgDS)
                vol = read(imgDS);  % [height, width, color] for 2D
                vol = bigimage(vol, 'BlockSize', [inputPatchSize(1) inputPatchSize(2)]);    % convert to bigimage
                
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')     % same
                    if obj.BatchOpt.P_OverlappingTiles == false
                        [outputLabels, scoreImg] = apply(vol, 1, ...       % apply(bigimage, level, function)
                            @(block, blockInfo) mibDeepController.segmentBlockedImage(block, net, generateScoreFiles, ExecutionEnvironment), ...
                            'PadPartialBlocks', true, ...
                            'BlockSize', [inputPatchSize(1) inputPatchSize(2)],...
                            'UseParallel', false,...
                            'IncludeBlockInfo', false,...
                            'DisplayWaitbar', false, ...    % do not show waitbar
                            'OutputFolder', fullfile(tempdir, 'deepmib'), ...
                            'BatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                    else
                        
                    end
                else    % valid padding
                    
                end
                
                % Save results
                outputLabels = getFullLevel(outputLabels);  % convert bigimage to normal matrix
                outputLabels = outputLabels - 1;    % remove the first "exterior" class
                
                [~, fn] = fileparts(imgDS.Files{id});
                filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.model']);
                
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
                
                % save score map
                if generateScoreFiles == 1
                    scoreImg = getFullLevel(scoreImg);  % convert bigimage to normal matrix
                    if generateScoreFilesFormat == 1    % 'Use AM format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.am']);
                        amiraOpt.overwrite = 1;
                        amiraOpt.showWaitbar = 0;
                        amiraOpt.verbose = false;
                        bitmap2amiraMesh(filename, uint8(scoreImg*255), [], amiraOpt);
                    else  % 2=='Use Matlab non-compressed format', 3=='Use Matlab compressed format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mibImg']);
                        saveImageParFor(filename, scoreImg, generateScoreFilesFormat-2, saveImageOpt);
                    end
                end
                
                % copy original file to the results for easier evaluation
                if obj.BatchOpt.showWaitbar
                    elapsedTime = toc(t1);
                    timerValue = elapsedTime/id*(noFiles-id);
                    pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                    pwb.increment();
                end
                id=id+1;
            end
            fprintf('Prediction finished: ');
            toc(t1)
            if obj.BatchOpt.showWaitbar; delete(pwb); end
            
        end
        
        function StartPrediction2D(obj)
            % function StartPrediction2D(obj)
            % predict datasets for 2D taken to a separate function for
            % better performance
            
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
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
                generateScoreFiles = 1;
                saveImageOpt.dimOrder = 'yxczt';    % for 2D or saveImageOpt.dimOrder = 'yxzct'; for 3D
                switch obj.BatchOpt.P_ScoreFiles{1}
                    case 'Use AM format'
                        generateScoreFilesFormat = 1;
                    case 'Use Matlab non-compressed format'
                        generateScoreFilesFormat = 2;
                    case 'Use Matlab compressed format'
                        generateScoreFilesFormat = 3;
                        
                end
            end
            
            if obj.BatchOpt.showWaitbar; pwb = PoolWaitbar(1, 'Creating image store for prediction...', [], 'Predicting dataset'); end
            
            % creating output directories
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
            trainingSwitch = 0;     % required for correct reading of files with bioformats reader
            % make a datastore for images
            try
                if preprocessedSwitch   % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), ...
                        'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepController.mibImgFileRead);
                else    % without preprocessing
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]);
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)obj.loadImages(fn, fnExtention, trainingSwitch));
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            if obj.BatchOpt.showWaitbar;  pwb.updateText('Loading network...'); end
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
                pwb.updateText(sprintf('Starting prediction\nPlease wait...'));
                pwb.increaseMaxNumberOfIterations(noFiles);
            end
            id = 1;     % indices of files
            patchCount = 1; % counter of processed patches
            nDims = 2;  % number of dimensions for data, 2
            
            % select gpu or cpu for prediction and define ExecutionEnvironment
            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            switch obj.View.Figure.GPUDropDown.Value
                case 'CPU only'
                    if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                        gpuDevice([]);  % CPU only mode
                    end
                    ExecutionEnvironment = 'cpu';
                case 'Multi-GPU'
                    uialert(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nMulti-GPU mode cannot be yet used for prediction. Please select a GPU from the list and restart prediction!'), ...
                        'Not available', 'icon', 'warning');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                    return;
                    %ExecutionEnvironment = 'multi-gpu';
                case 'Parallel'
                    ExecutionEnvironment = 'parallel';
                otherwise
                    gpuDevice(selectedIndex);   % choose selected GPU device
                    ExecutionEnvironment = 'gpu';
            end
           
            
            while hasdata(imgDS)
                vol = read(imgDS);  % [height, width, color] for 2D
                volSize = size(vol, (1:2));
                [height, width, color] = size(vol);
                [~, fn] = fileparts(imgDS.Files{id});
                
                % for tiled procedure see ToDo\CoderGPU\StartPrediction2D_tiled_strategy.m
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')     % same
                    if obj.BatchOpt.P_OverlappingTiles == false
                        if height == inputPatchSize(1) && width == inputPatchSize(2)
                            [outputLabels, ~, scoreImg] = semanticseg(squeeze(vol), net, ...
                                'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment, ...
                                'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                            if generateScoreFiles == 1; scoreImg = uint8(scoreImg*255); end
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
                                'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment,...
                                'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1}');
                            
                            % Remove the padding if needed
                            if sum(padSizePre)+sum(padSizePost)>0
                                outputLabels = outputLabels(padSizePre(1)+1:end-padSizePost(1), ...
                                    padSizePre(2)+1:end-padSizePost(2));
                                if generateScoreFiles == 1
                                    scoreImg = scoreImg(padSizePre(1)+1:end-padSizePost(1), ...
                                        padSizePre(2)+1:end-padSizePost(2), :);
                                end
                            end
                            
                        end
                    else        % the section below is for obj.BatchOpt.P_OverlappingTiles == true
                        % pad the image to include extended areas due to
                        % the overlapping strategy
                        padShift = (obj.BatchOpt.T_FilterSize{1}-1)*obj.BatchOpt.T_EncoderDepth{1};
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
                        if generateScoreFiles == 1; scoreImg = zeros([heightPad, widthPad, numClasses], 'uint8'); end
                        
                        for j = 1:outputPatchSize(2):widthPad-outputPatchSize(2)+1
                            for i = 1:outputPatchSize(1):heightPad-outputPatchSize(1)+1
                                patch = volPadded( i:i+inputPatchSize(1)-1,...
                                    j:j+inputPatchSize(2)-1, :);
                                [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, ...
                                    'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment,...
                                    'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                                x1 = i + padShift - 1;
                                y1 = j + padShift - 1;
                                
                                outputLabels(x1:x1+outputPatchSize(1)-1, ...
                                    y1:y1+outputPatchSize(2)-1) = patchSeg(padShift:padShift+outputPatchSize(1)-1, ...
                                    padShift:padShift+outputPatchSize(2)-1);
                                
                                if generateScoreFiles == 1
                                    scoreImg(x1:x1+outputPatchSize(1)-1, ...
                                        y1:y1+outputPatchSize(2)-1,:) = scoreBlock(padShift:padShift+outputPatchSize(1)-1, ...
                                        padShift:padShift+outputPatchSize(2)-1, ...
                                        :)*255;
                                end
                                patchCount = patchCount + 1;
                            end
                        end
                        
                        % Remove the padding
                        outputLabels = outputLabels(padShift+1:padShift+height, padShift+1:padShift+width);
                        if generateScoreFiles == 1
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
                        'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment, ...
                        'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                    
                    % Crop out the extra padded region.
                    outputLabels = outputLabels(1:volSize(1), 1:volSize(2));
                    if generateScoreFiles == 1; scoreImg = scoreImg(1:volSize(1), 1:volSize(2), :); end
                end
                
                % Save results
                outputLabels = outputLabels - 1;    % remove the first "exterior" class
                
                [~, fn] = fileparts(imgDS.Files{id});
                filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', ['Labels_' fn '.model']);
                
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
                
                % save score map
                if generateScoreFiles == 1
                    if generateScoreFilesFormat == 1    % 'Use AM format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.am']);
                        amiraOpt.overwrite = 1;
                        amiraOpt.showWaitbar = 0;
                        amiraOpt.verbose = false;
                        bitmap2amiraMesh(filename, uint8(scoreImg*255), [], amiraOpt);  % convert to 8-bit and scale between 0-255
                    else  % 2=='Use Matlab non-compressed format', 3=='Use Matlab compressed format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mibImg']);
                        saveImageParFor(filename, scoreImg, generateScoreFilesFormat-2, saveImageOpt);
                    end
                end
                
                % copy original file to the results for easier evaluation
                if obj.BatchOpt.showWaitbar
                    elapsedTime = toc(t1);
                    timerValue = elapsedTime/id*(noFiles-id);
                    pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                    pwb.increment();
                end
                id=id+1;
            end
            fprintf('Prediction finished: ');
            toc(t1)
            if obj.BatchOpt.showWaitbar; delete(pwb); end
        end
        
        
        function StartPrediction3D(obj)
            % function StartPrediction3D(obj)
            % predict datasets for 3D networks taken to a separate function
            % to improve performance
            
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
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
                generateScoreFiles = 1;
                saveImageOpt.dimOrder = 'yxzct';
                switch obj.BatchOpt.P_ScoreFiles{1}
                    case 'Use AM format'
                        generateScoreFilesFormat = 1;
                    case 'Use Matlab non-compressed format'
                        generateScoreFilesFormat = 2;
                    case 'Use Matlab compressed format'
                        generateScoreFilesFormat = 3;
                end
            end
            
            if obj.BatchOpt.showWaitbar; pwb = PoolWaitbar(1, 'Creating image store for prediction...', [], 'Predicting dataset'); end
            
            % creating output directories
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
            trainingSwitch = 0;     % needed for correct image reading using bioformats
            
            % make a datastore for images
            try
                if preprocessedSwitch   % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), ...
                        'FileExtensions', '.mibImg', 'ReadFcn', @mibDeepController.mibImgFileRead);
                else    % without preprocessing
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]);
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)obj.loadImages(fn, fnExtention, trainingSwitch));
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            if obj.BatchOpt.showWaitbar;  pwb.updateText('Loading network...'); end
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
                pwb.updateText(sprintf('Starting prediction\nPlease wait...'));
            end
            id = 1;     % indices of files
            patchCount = 1; % counter of processed patches
            
            %% TO DO:
            % 1. check situation, when the dataset for prediction is
            % smaller that then dataset for training: 2D and 3D cases
            % 2. check different padvalue in the code below: volPadded = padarray (vol, padSize, 0, 'post');
            
            nDims = 3;  % number of dimensions for data, 2 or 3
            
            % select gpu or cpu for prediction and define ExecutionEnvironment
            selectedIndex = find(ismember(obj.View.Figure.GPUDropDown.Items, obj.View.Figure.GPUDropDown.Value));
            switch obj.View.Figure.GPUDropDown.Value
                case 'CPU only'
                    if numel(obj.View.Figure.GPUDropDown.Items) > 2 % i.e. GPU is present
                        gpuDevice([]);  % CPU only mode
                    end
                    ExecutionEnvironment = 'cpu';
                case 'Multi-GPU'
                    uialert(obj.View.gui, ...
                        sprintf('!!! Warning !!!\n\nMulti-GPU mode cannot be yet used for prediction. Please select a GPU from the list and restart prediction!'), ...
                        'Not available', 'icon', 'warning');
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                    return;
                    %ExecutionEnvironment = 'multi-gpu';
                case 'Parallel'
                    ExecutionEnvironment = 'parallel';
                otherwise
                    gpuDevice(selectedIndex);   % choose selected GPU device
                    ExecutionEnvironment = 'gpu';
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
                                'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment, ...
                                'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                            if generateScoreFiles == 1; scoreImg = uint8(scoreImg*255); end
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
                            if generateScoreFiles == 1; scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'uint8'); end
                            
                            if obj.BatchOpt.showWaitbar
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
                                            'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment, ...
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
                                        if generateScoreFiles == 1
                                            scoreImg(i:i+outputPatchSize(1)-1, ...
                                                j:j+outputPatchSize(2)-1, ...
                                                k:k+outputPatchSize(3)-1,:) = scoreBlock*255;
                                        end
                                        if obj.BatchOpt.showWaitbar
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
                            if generateScoreFiles == 1; scoreImg = scoreImg(1:height, 1:width, 1:depth, :); end
                        end
                    else        % the section below is for obj.BatchOpt.P_OverlappingTiles == true
                        % pad the image to include extended areas due to
                        % the overlapping strategy
                        padShift = (obj.BatchOpt.T_FilterSize{1}-1)*obj.BatchOpt.T_EncoderDepth{1};
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
                        if generateScoreFiles == 1; scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'uint8'); end
                        
                        if obj.BatchOpt.showWaitbar
                            iterNo = numel(1:outputPatchSize(3):depthPad-outputPatchSize(3)+1) * ...
                                numel(1:outputPatchSize(2):widthPad-outputPatchSize(2)+1) * ...
                                numel(1:outputPatchSize(1):heightPad-outputPatchSize(1)+1);
                            pwb.increaseMaxNumberOfIterations(iterNo);
                        end
                        
                        for k = 1:outputPatchSize(3):depthPad-outputPatchSize(3)+1
                            for j = 1:outputPatchSize(2):widthPad-outputPatchSize(2)+1
                                for i = 1:outputPatchSize(1):heightPad-outputPatchSize(1)+1
                                    patch = volPadded( i:i+inputPatchSize(1)-1,...
                                        j:j+inputPatchSize(2)-1,...
                                        k:k+inputPatchSize(3)-1,:);
                                    [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, ...
                                        'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment, ...
                                        'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                                    x1 = i + padShift - 1;
                                    y1 = j + padShift - 1;
                                    z1 = min(k + padShift - 1, depthPad);
                                    
                                    outputLabels(x1:x1+outputPatchSize(1)-1, ...
                                        y1:y1+outputPatchSize(2)-1, ...
                                        z1:z1+outputPatchSize(3)-1) = patchSeg(padShift:padShift+outputPatchSize(1)-1, ...
                                        padShift:padShift+outputPatchSize(2)-1, ...
                                        padShift:padShift+outputPatchSize(3)-1);
                                    if generateScoreFiles == 1
                                        scoreImg(x1:x1+outputPatchSize(1)-1, ...
                                            y1:y1+outputPatchSize(2)-1, ...
                                            z1:z1+outputPatchSize(3)-1,:) = scoreBlock(padShift:padShift+outputPatchSize(1)-1, ...
                                            padShift:padShift+outputPatchSize(2)-1, ...
                                            padShift:padShift+outputPatchSize(3)-1,:)*255;
                                    end
                                    
                                    if obj.BatchOpt.showWaitbar
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
                        if generateScoreFiles == 1
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
                    if generateScoreFiles == 1; scoreImg = zeros([height, width, depth, numClasses], 'uint8'); end
                    
                    if obj.BatchOpt.showWaitbar
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
                    %                         [patch{patchId}, ~, scoreBlock{patchId}] = semanticseg(patch{patchId}, net, 'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment);
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
                                    'OutputType', 'uint8', 'ExecutionEnvironment', ExecutionEnvironment, ...
                                    'MiniBatchSize', obj.BatchOpt.P_MiniBatchSize{1});
                                
                                outputLabels(i:i+outputPatchSize(1)-1, ...
                                    j:j+outputPatchSize(2)-1, ...
                                    k:k+outputPatchSize(3)-1) = patchSeg;
                                if generateScoreFiles == 1
                                    scoreImg(i:i+outputPatchSize(1)-1, ...
                                        j:j+outputPatchSize(2)-1, ...
                                        k:k+outputPatchSize(3)-1,:) = scoreBlock*255;
                                end
                                if obj.BatchOpt.showWaitbar
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
                    if generateScoreFiles == 1; scoreImg = scoreImg(1:height, 1:width, 1:depth, :); end
                end
                if obj.BatchOpt.showWaitbar; pwb.updateText('Saving results...'); end
                
                % Save results
                outputLabels = outputLabels - 1;    % remove the first "exterior" class
                
                [~, fn] = fileparts(imgDS.Files{id});
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
                
                % save score map
                if generateScoreFiles == 1
                    if generateScoreFilesFormat == 1    % 'Use AM format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.am']);
                        scoreImg = uint8(scoreImg*255);     % convert to 8bit and scale between 0-255
                        scoreImg = permute(scoreImg, [1 2 4 3]);    % convert to [height, width, color, depth]
                        
                        amiraOpt.overwrite = 1;
                        amiraOpt.showWaitbar = 0;
                        amiraOpt.verbose = false;
                        bitmap2amiraMesh(filename, scoreImg, [], amiraOpt);
                    else    % 2=='Use Matlab non-compressed format', 3=='Use Matlab compressed format'
                        filename = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores', ['Score_' fn '.mibImg']);
                        saveImageParFor(filename, scoreImg, generateScoreFilesFormat-2, saveImageOpt);
                    end
                end
                
                % copy original file to the results for easier evaluation
                %copyfile(fullfile(projDir, ImageSource, '01_input_images', rawFn), outputDir);
                if obj.BatchOpt.showWaitbar
                    elapsedTime = toc(t1);
                    timerValue = elapsedTime/id*(noFiles-id);
                    pwb.updateText(sprintf('%s\nHold on ~%.0f:%.2d mins left...', fn, floor(timerValue/60), mod(round(timerValue),60)));
                    pwb.increment();
                end
                id=id+1;
            end
            fprintf('Prediction finished: ');
            toc(t1)
            if obj.BatchOpt.showWaitbar; delete(pwb); end
        end
        
        function previewPredictions(obj)
            % function previewPredictions(obj)
            % load images of prediction scores into MIB
            
            scoreDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores');
            fnList = dir(fullfile(scoreDir, '*.am'));
            if isempty(fnList)
                errordlg(sprintf('!!! Error !!!\n\nNo files with predictions were found in\n%s\n\nPlease update the Directory with resulting images field of the Directories and Preprocessing tab!', scoreDir), 'Missing files');
                return;
            end
            if strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D')  % take only the first file for 3D case
                BatchOptIn.Filenames = {{fullfile(scoreDir, fnList(1).name)}};
            else
                BatchOptIn.Filenames = {arrayfun(@(filename) fullfile(scoreDir, cell2mat(filename)), {fnList.name}, 'UniformOutput', false)};  % generate full paths
            end
            BatchOptIn.UseBioFormats = false;
            obj.mibController.mibFilesListbox_cm_Callback([], BatchOptIn);
        end
        
        function previewModels(obj)
            % function previewModels(obj)
            % load images for predictions and the resulting modelsinto MIB
            
            imgDir = fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Images');
            imgList = dir(fullfile(imgDir, ['*.' lower(obj.BatchOpt.ImageFilenameExtension{1})]));
            modelDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels');
            modelList = dir(fullfile(modelDir, '*.model'));
            
            if isempty(imgList) || isempty(modelList)
                errordlg(sprintf('!!! Error !!!\n\nFiles were not found in\n%s\n\n%s\n\nPlease update the Directory prediction and resulting images fields of the Directories and Preprocessing tab!', imgDir, modelDir), 'Missing files');
                return;
            end
            
            if strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D')  % take only the first file for 3D case
                BatchOptIn1.Filenames = {{fullfile(imgDir, imgList(1).name)}};
                BatchOptIn2.DirectoryName = {modelDir};
                BatchOptIn2.FilenameFilter = modelList(1).name;
            else
                BatchOptIn1.Filenames = {arrayfun(@(filename) fullfile(imgDir, cell2mat(filename)), {imgList.name}, 'UniformOutput', false)};  % generate full paths
                BatchOptIn2.DirectoryName = {modelDir};
                BatchOptIn2.FilenameFilter = '*.model';
            end
            
            BatchOptIn1.UseBioFormats = obj.BatchOpt.Bioformats;
            BatchOptIn1.BioFormatsIndices = num2str(obj.BatchOpt.BioformatsIndex{1});
            BatchOptIn1.verbose = false;    % do not display loading files into the main command window
            obj.mibModel.myPath = imgDir;
            obj.mibController.mibFilesListbox_cm_Callback([], BatchOptIn1);     % load images
            obj.mibModel.loadModel([], BatchOptIn2);  % load models
        end
        
        function EvaluateSegmentation(obj)
            % function EvaluateSegmentation(obj)
            % evaluate segmentation results by comparing predicted models
            % with the ground truth models
            global mibPath;
            
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
                preprocessedSwitch = false;
                truthDir = fullfile(obj.BatchOpt.OriginalPredictionImagesDir, 'Labels');
                truthList = dir(fullfile(truthDir, lower(['*.' obj.BatchOpt.ModelFilenameExtension{1}])));
            else
                preprocessedSwitch = true;
                truthDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels');
                truthList = dir(fullfile(truthDir, '*.mibCat'));
            end
            
            predictionDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels');
            predictionList = dir(fullfile(predictionDir, '*.model'));
            
            if isempty(truthList) && isempty(predictionList)
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nModels were not found in\n%s\n\n%s\n\nPlease update the Directory prediction and resulting images fields of the Directories and Preprocessing tab!', truthDir, predictionDir), ...
                    'Missing files');
                return;
            end
            
            %             obj.mibModel.preferences.Deep.Metrics.Accuracy = true;  % parameters for metrics evaluation
            %             obj.mibModel.preferences.Deep.Metrics.BFscore = false;
            %             obj.mibModel.preferences.Deep.Metrics.GlobalAccuracy = true;
            %             obj.mibModel.preferences.Deep.Metrics.IOU = true;
            %             obj.mibModel.preferences.Deep.Metrics.WeightedIOU = true;
            
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
            options.WindowWidth = 3;
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
            modelFn = fullfile(predictionList(1).folder, predictionList(1).name);
            res = load(modelFn, '-mat', 'modelMaterialNames');
            classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
            pixelLabelID = 0:numel(classNames)-1;
            
            try
                fullPathFilenames = arrayfun(@(filename) fullfile(truthDir, cell2mat(filename)), {truthList.name}, 'UniformOutput', false);  % generate full paths
                if preprocessedSwitch
                    dsTruth = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                        'FileExtensions', '.mibCat', 'ReadFcn', @mibDeepController.mibImgFileRead);
                else
                    switch obj.BatchOpt.ModelFilenameExtension{1}
                        case 'MODEL'
                            dsTruth = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                                'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                            % I = readimage(dsTruth,1);  % read model test
                            % reset(dsTruth);
                        otherwise
                            dsTruth = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                                'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
                    end
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s\n\nCheck the ground truth directory:\n%s', err.identifier, err.message, truthDir), 'Wrong class name');
                return;
            end
            
            fullPathFilenames = arrayfun(@(filename) fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', cell2mat(filename)), {predictionList.name}, 'UniformOutput', false);  % generate full paths
            dsResults = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
            
            tic
            pw = PoolWaitbar(2, sprintf('Starting evaluation\nit may take a while...'), [], 'Evaluate segmentation');
            try
                ssm = evaluateSemanticSegmentation(dsResults, dsTruth, 'Metrics', metricsList);
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s\n\nMost likely the class names in the GroundTruth do not match the class names of the model', err.identifier, err.message), 'Wrong class names');
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
            figure
            h = heatmap(classNames,classNames,100*normConfMatData);
            h.XLabel = 'Predicted Class';
            h.YLabel = 'True Class';
            [~, netName] = fileparts(obj.BatchOpt.NetworkFilename);
            h.Title = sprintf('Normalized Confusion Matrix\n(%s)', netName);
            
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
            options.WindowWidth = 2.2;
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
                wbar = waitbar(0, sprintf('Saving to Excel\nPlease wait...'), 'Name', 'Export');
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
                waitbar(0.2, wbar);
                excelHeader{2,1} = 'Prediction results directory:';  excelHeader{2,2} = predictionDir;
                excelHeader{3,1} = 'Ground truth directory:';excelHeader{3,2} = truthDir;
                writecell(excelHeader, fn, 'FileType', 'spreadsheet', 'Sheet', 'ImageMetrics', 'Range', 'A1');
                writetable(ssmStruct.ImageMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'ImageMetrics', 'WriteRowNames', true, 'Range', 'A5');
                
                waitbar(0.4, wbar);
                writecell(excelHeader(1), fn, 'FileType', 'spreadsheet', 'Sheet', 'DataSetMetrics', 'Range', 'A1');
                writetable(ssm.DataSetMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'DataSetMetrics', 'WriteRowNames', true, 'Range', 'A3');
                waitbar(0.6, wbar);
                writecell(excelHeader(1), fn, 'FileType', 'spreadsheet', 'Sheet', 'ConfusionMatrix', 'Range', 'A1');
                writetable(ssm.ConfusionMatrix, fn, 'FileType', 'spreadsheet', 'Sheet', 'ConfusionMatrix', 'WriteRowNames', true, 'Range', 'A3');
                waitbar(0.8, wbar);
                writecell(excelHeader(1), fn, 'FileType', 'spreadsheet', 'Sheet', 'NormalizedConfusionMatrix', 'Range', 'A1');
                writetable(ssm.NormalizedConfusionMatrix, fn, 'FileType', 'spreadsheet', 'Sheet', 'NormalizedConfusionMatrix', 'WriteRowNames', true, 'Range', 'A3');
                
                waitbar(1, wbar);
                fprintf('Evaluation results were saved to:\n%s\n', fn);
                delete(wbar);
            end
            
            if answer{4}    % save in CSV format
                wbar = waitbar(0, sprintf('Saving to CSV format\nPlease wait...'), 'Name', 'Export');
                
                fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationClassMetrics.csv');
                if exist(fn, 'file') == 2; delete(fn); end
                try
                    writetable(ssm.ClassMetrics, fn, 'FileType', 'text', 'WriteRowNames', true);
                    
                    waitbar(0.2, wbar);
                    fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationImageMetrics.csv');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(ssmStruct.ImageMetrics, fn, 'FileType', 'text', 'WriteRowNames', true);
                    
                    waitbar(0.4, wbar);
                    fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationDataSetMetrics.csv');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(ssm.DataSetMetrics, fn, 'FileType', 'text', 'WriteRowNames', true);
                    
                    waitbar(0.6, wbar);
                    fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationConfusionMatrix.csv');
                    if exist(fn, 'file') == 2; delete(fn); end
                    writetable(ssm.ConfusionMatrix, fn, 'FileType', 'text', 'WriteRowNames', true);
                    
                    waitbar(0.8, wbar);
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
                waitbar(1, wbar);
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
                        msg = sprintf('%s%s:\t\t%s\n', msg, fNames{fId}, num2str(D.(fNames{fId})));
                    end
            end
            
            obj.gpuInfoFig = uifigure('Name', 'GPU Info');
            hGrid = uigridlayout(obj.gpuInfoFig, [3, 1], 'RowHeight', {'1x', '12x', '1x'});
            hl = uilabel(hGrid, 'Text', sprintf('Properties of %s', obj.View.Figure.GPUDropDown.Value));
            h2 = uipanel(hGrid);
            h3 = uibutton(hGrid, 'push', 'Text', 'Close window', 'ButtonPushedFcn', 'closereq');
            drawnow;
            h2b = uitextarea(h2, 'Value', msg, ...
                'Position', [10 10 h2.Position(3)-20 h2.Position(4)-20], ...
                'Editable', false);
            
        end
        
        function setPreviewAugmentationSettings(obj)
            % function setPreviewAugmentationSettings(obj)
            % update settings for preview of augmented patches
            global mibPath;
            
            colorList = {'blue', 'green', 'red', 'cyan', 'magenta', 'yellow','black', 'white'};
            prompts = { 'Number of patches to show [def=25]';...
                'Show information label [def=true]';...
                'Label size [def=9]'; ...
                'Label color [def=black]'; ...
                'Label background color [def=yellow]'; ...
                'Label background opacity [def=0.6]'};
            defAns = {num2str(obj.PatchPreviewOpt.noImages); ...
                obj.PatchPreviewOpt.labelShow; ...
                num2str(obj.PatchPreviewOpt.labelSize); ...
                [colorList, {find(ismember(colorList, obj.PatchPreviewOpt.labelColor)==1)}]; ...
                [colorList, {find(ismember(colorList, obj.PatchPreviewOpt.labelBgColor)==1)}]; ...
                num2str(obj.PatchPreviewOpt.labelBgOpacity) };
            
            dlgTitle = 'Augmented patch preview settings';
            options.WindowStyle = 'normal';
            options.Columns = 1;    % [optional] define number of columns
            options.Focus = 1;      % [optional] define index of the widget to get focus
            
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            obj.PatchPreviewOpt.noImages = round(str2double(answer{1}));
            obj.PatchPreviewOpt.labelShow = logical(answer{2});
            obj.PatchPreviewOpt.labelSize = round(str2double(answer{3}));
            obj.PatchPreviewOpt.labelColor = answer{4};
            obj.PatchPreviewOpt.labelBgColor = answer{5};
            obj.PatchPreviewOpt.labelBgOpacity = str2double(answer{6});
        end
        
        function ExportNetworkToONNXButton(obj)
            % function ExportNetworkToONNXButton(obj)
            % convert and export network to ONNX format
            global mibPath;
            
            if exist(obj.BatchOpt.NetworkFilename, 'file') ~= 2
                uialert(obj.View.gui, sprintf('!!! Error !!!\n\nThe network file:\n%s\ncan not be found!', obj.BatchOpt.NetworkFilename), 'Missing file');
                return;
            end
            
            [dir, fn] = fileparts(obj.BatchOpt.NetworkFilename);
            outoutFilename = fullfile(dir, [fn '.onnx']);
            [filename, pathname] = uiputfile( ...
                {'*.onnx','ONNX-files (*.onnx)';...
                '*.*',  'All Files (*.*)'}, ...
                'Set output file', outoutFilename);
            if filename == 0; return; end
            outoutFilename = fullfile(pathname, filename);
            
            prompts = {'Version of ONNX operator set'; 'Alter the final segmentation layer as'};
            defAns = {{'6', '7', '8', '9', 4}; {'Keep as it is', 'Remove the layer', 'pixelClassificationLayer', 'dicePixelClassificationLayer', 1}};
            dlgTitle = 'Export to ONNX';
            options.PromptLines = [1, 1];
            options.Title = sprintf('Convert and export the network to ONNX format');
            options.TitleLines = 1;
            options.WindowWidth = 1.2;
            options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/exportonnxnetwork.html';
            
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            % load the model
            Model = load(obj.BatchOpt.NetworkFilename, '-mat');
            
            try
                switch answer{2}
                    case 'Keep as it is'
                        exportONNXNetwork(Model.net, outoutFilename, 'OpsetVersion', str2double(answer{1}));
                    otherwise
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
                        exportONNXNetwork(lgraph, outoutFilename, 'OpsetVersion', str2double(answer{1}));
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'ONNX export');
                return;
            end
            uialert(obj.View.gui, sprintf('Export finished!\n%s', outoutFilename), 'Done!', 'Icon', 'success');
        end
        
        function previewAugmentations(obj)
            % function previewAugmentations(obj)
            % preview selected augmentations
            
            if obj.BatchOpt.T_RandomGeneratorSeed{1} == 0
                rng('shuffle');
            else
                rng(obj.BatchOpt.T_RandomGeneratorSeed{1});
            end
            
            obj.TrainingProgress = struct();    % reset obj.TrainingProgress to make sure that it is closed
            obj.TrainingProgress.emergencyBrake = false;    % to make sure that it won't stop inside transform structure
            inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);
            trainingSwitch = 1;     % required for correct file reading with bioformats
            
            % the other options are not available, require to process images
            try
                if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Preprocessing is not required') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Split files for training/validation')
                    fnExtention = lower(['.' obj.BatchOpt.ImageFilenameExtensionTraining{1}]);
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.OriginalTrainingImagesDir, 'TrainImages'), ...
                        'FileExtensions', fnExtention, ...
                        'IncludeSubfolders', false, ...
                        'ReadFcn', @(fn)obj.loadImages(fn, fnExtention, trainingSwitch));
                else        % with preprocessing
                    imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'), ...
                        'FileExtensions', '.mibImg', 'IncludeSubfolders', false, 'ReadFcn', @mibDeepController.mibImgFileRead);
                    %labelsDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'), ...
                    %    'FileExtensions', '.mibCat', 'IncludeSubfolders', false, ...
                    %    'ReadFcn', @mibDeepController.matlabCategoricalFileRead);
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            % generate random patch datastores
            switch obj.BatchOpt.Architecture{1}(1:2)
                case '3D'
                    randomStoreInputPatchSize = inputPatchSize(1:3);
                    status = setAug3DFuncHandles(obj, inputPatchSize);
                    if status == 0; return; end
                case '2D'
                    randomStoreInputPatchSize = inputPatchSize(1:2);
                    status = setAug2DFuncHandles(obj, inputPatchSize);
                    if status == 0; return; end
            end
            
            
            patchDS = randomPatchExtractionDatastore(imgDS, imgDS, randomStoreInputPatchSize, ...
                'PatchesPerImage', 1); %#ok<ST2NM>
            patchDS.MiniBatchSize = 1;
            
            patchIn = read(patchDS);
            
            Iout = cell([obj.PatchPreviewOpt.noImages, 1]);
            augOperation = cell([obj.PatchPreviewOpt.noImages, 1]);
            augParameter = zeros([obj.PatchPreviewOpt.noImages, 17]);
            t1 = tic;
            for z=1:obj.PatchPreviewOpt.noImages
                if strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D')
                    [augPatch, augOperation(z), augParameter(z,:)] = obj.augmentAndCrop3dPatch(patchIn, inputPatchSize, inputPatchSize, 'aug'); %#ok<ASGLU>
                    Iout{z} = squeeze(augPatch.inpVol{1}(:,:, ceil(size(augPatch.inpVol{1},3)/2),:));
                else
                    [augPatch, augOperation(z), augParameter(z,:)] = obj.augmentAndCrop2dPatch(patchIn, inputPatchSize, inputPatchSize, 'aug'); %#ok<ASGLU>
                    Iout{z} = augPatch.inpVol{1};
                end
                
                if inputPatchSize(4) == 2
                    Iout{z}(:,:,3) = zeros([inputPatchSize(1) inputPatchSize(2)]);
                end
            end
            t2 = toc(t1);
            if obj.PatchPreviewOpt.labelShow
                for z=1:obj.PatchPreviewOpt.noImages
                    textString = sprintf('%s\n%s', strjoin(augOperation{z}, ','), num2str(augParameter(z, 1:numel(augOperation{z}))));
                    Iout{z} = insertText(Iout{z}, [1 1], ...
                        textString, 'FontSize', obj.PatchPreviewOpt.labelSize, ...
                        'TextColor', obj.PatchPreviewOpt.labelColor, ...
                        'BoxColor', obj.PatchPreviewOpt.labelBgColor, ...
                        'BoxOpacity', obj.PatchPreviewOpt.labelBgOpacity);
                end
            end
            
            rng('shuffle');
            hFig = figure(randi(1000));
            montage(Iout, 'BorderSize', 5);
            uicontrol(hFig, 'style', 'text', ...
                'Position', [20, 20, 300, 20], ...
                'String', sprintf('Calculation performance: %f seconds per image', t2/obj.PatchPreviewOpt.noImages));
        end
        
        function transferLearning(obj)
            % function transferLearning(obj)
            % perform fine-tuning of the loaded network to a different
            % number of classes
            
            global mibPath;
            
            obj.BatchOpt.Mode{1} = 'Predict';   % change the mode, so that selectNetwork function loads the network
            net = obj.selectNetwork();
            if isempty(net); return; end
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
            options.WindowWidth = 1.4;    % [optional] make window x1.2 times wider
            %options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/imagedataaugmenter.html'; % [optional], an url for the Help button
            
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            wbar = waitbar(0, sprintf('Performing transfer learning\nPlease wait...'), 'Name', 'Transfer learning');
            
            newNoClasses = str2double(answer{1});
            newSegLayer = answer{2};
            outNetworkName = answer{3};
            outConfigName = fullfile(outPath, [outNetworkName '.mibCfg']);
            outNetworkName = fullfile(outPath, [outNetworkName, outExt]);
            
            % generate a new network to obtain the ending part
            obj.BatchOpt.T_NumberOfClasses{1} = newNoClasses;  % redefine number of classes
            obj.BatchOpt.T_SegmentationLayer{1} = newSegLayer;  % update segmentation layer
            
            [lgraph, outputPatchSize] = obj.createNetwork();
            waitbar(0.3, wbar);
            
            % find layer after which all layers should be replaced
            if strcmp(obj.BatchOpt.Architecture{1}, '2D SegNet')
                layerName = 'decoder1_conv1';   % 2D segnet
            else    % 2D, 3D Unets
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
                    delete(wbar);
                    return;
                end
            end
            waitbar(0.5, wbar);
            
            % convert DAG object to LayerGraph object to allow
            % modification of layers
            net = layerGraph(net);
            for layerId=segmLayerId:numel(net.Layers)
                net = replaceLayer(net, net.Layers(layerId).Name, lgraph.Layers(layerId));
            end
            waitbar(0.6, wbar);
            
            obj.BatchOpt.NetworkFilename = outNetworkName;
            save(outNetworkName, 'net', '-mat', '-v7.3');
            obj.saveConfig(outConfigName);
            waitbar(0.9, wbar);
            
            % update elements of GUI
            obj.View.Figure.NetworkFilename.Value = obj.BatchOpt.NetworkFilename;
            obj.View.Figure.T_NumberOfClasses.Value = obj.BatchOpt.T_NumberOfClasses{1};
            obj.View.Figure.NumberOfClassesPreprocessing.Value = obj.BatchOpt.T_NumberOfClasses{1};
            obj.View.Figure.T_SegmentationLayer.Value = obj.BatchOpt.T_SegmentationLayer{1};
            
            waitbar(1, wbar);
            fprintf('The transfer learning finished:\n%s\n', outNetworkName);
            delete(wbar);
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
                                    'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                    case 'mibCat'
                        %dsLabels = pixelLabelDatastore(fullPathFilenames, classNames, pixelLabelID, ...
                        %    'FileExtensions', '.mibCat', 'ReadFcn', @mibDeepController.mibImgFileRead);
                        dsLabels = imageDatastore(fullPathFilenames, ...
                            'FileExtensions', '.mibCat', 'IncludeSubfolders', false, ...
                            'ReadFcn', @mibDeepController.matlabCategoricalFileRead);
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
        
        function ExploreActivations(obj)
            obj.startController('mibDeepActivationsController', obj);
        end
        
        
    end
end