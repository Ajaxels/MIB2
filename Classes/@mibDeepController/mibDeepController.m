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
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
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
        % obtained from obj.mibModel.preferences.deep.AugOpt2D, see getDefaultParameters.m
        % .FillValue = 0;  
        % .RandXReflection = true;
        % .RandYReflection = true;
        % .RandRotation = [-10, 10];  
        % .RandScale = [.95 1.05];
        % .RandXScale = [.95 1.05];
        % .RandYScale = [.95 1.05];
        % .RandXShear = [-5 5];
        % .RandYShear = [-5 5];
        AugOpt3D
        % .Fraction = .6;   % augment 60% of patches
        % .FillValue = 0;    
        % .RandXReflection = true;
        % .RandYReflection = true;
        % .RandZReflection = true;
        % .Rotation90 = true;
        % .ReflectedRotation90 = true;
        InputLayerOpt
        % a structure with settings for the input layer
        % .Normalization = 'zerocenter';
        % .Mean = [];
        % .StandardDeviation = [];
        % .Min = [];
        % .Max = [];
        modelMaterialColors
        % colors of materials
        TrainingOpt
        % a structure with training options, the default ones are obtained
        % from obj.mibModel.preferences.deep.TrainingOpt, see getDefaultParameters.m
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
        
        function data = matlabFileRead(filename)
            % function data = matlabFileRead(filename)
            % read mat file for datastore
            
            inp = load(filename);
            f = fields(inp);
            data = inp.(f{1});
        end
        
        function img = loadAndTransposeImages(filename)
            img = mibLoadImages(filename);
            img = permute(img, [1 2 4 3]);  % transpose from [h,w,c,z] to [h,w,z,c]
        end
        
        function patch = crop2dPatchForValid(patch, inputPatchSize, outputPatchSize)
            % function patch = crop2dPatchForValid(patch, inputPatchSize, outputPatchSize)
            % crop the the response to the network's output size.
            % Return the image patches in a two-column table as required by the trainNetwork function for
            % single-input networks.
            %
            % Parameters:
            % patch: a table [MinibatchSize; InputImage ResponsePixelLabelImage] patches to be cropped 
            % inputPatchSize: input patch size as [height, width, depth, color]
            % outputPatchSize: output patch size as [height, width, depth, classes]
            %
            % Return values:
            % patch: a table [MinibatchSize; InputImage ResponsePixelLabelImage], 
            %        where ResponsePixelLabelImage was cropped to outputPatchSize
            
            % allocate space for the output
            %inpVol = cell(size(patchIn,1), 1);
            %inpResponse = cell(size(patchIn,1), 1);
            
            diffPatchY = (inputPatchSize(1)-outputPatchSize(1))/2;
            diffPatchX = (inputPatchSize(2)-outputPatchSize(2))/2;
            y1 = diffPatchY+1;
            y2 = inputPatchSize(1)-diffPatchY;
            x1 = diffPatchX+1;
            x2 = inputPatchSize(2)-diffPatchX;
            
            for id=1:size(patch, 1)
                patch.ResponsePixelLabelImage{id} = patch.ResponsePixelLabelImage{id}(y1:y2, x1:x2, :);
            end
        end
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
            
            obj.BatchOpt.Bioformats = false;    % use bioformats file reader for prediction images 
            obj.BatchOpt.BioformatsTraining = false;    % use bioformats file reader for training images 
            obj.BatchOpt.NetworkFilename = fullfile(obj.mibModel.myPath, 'myLovelyNetwork.mibDeep');
            obj.BatchOpt.Architecture = {'2D U-net'};
            obj.BatchOpt.Architecture{2} = {'2D U-net', '2D SegNet', '3D U-net', '3D U-net Anisotropic'};
            obj.BatchOpt.Mode = {'Train'};
            obj.BatchOpt.Mode{2} = {'Train', 'Predict'};
            obj.BatchOpt.T_ConvolutionPadding = {'same'};
            obj.BatchOpt.T_ConvolutionPadding{2} = {'same', 'valid'};
            obj.BatchOpt.T_InputPatchSize = '64 64 64 1';
            obj.BatchOpt.T_NumberOfClasses{1} = 2;
            obj.BatchOpt.T_NumberOfClasses{2} = [1 Inf];
            obj.BatchOpt.T_SegmentationLayer = {'dicePixelCustomClassificationLayer'};
            obj.BatchOpt.T_SegmentationLayer{2} = {'pixelClassificationLayer', 'dicePixelClassificationLayer', 'dicePixelCustomClassificationLayer'};
            obj.BatchOpt.T_EncoderDepth{1} = 3;
            obj.BatchOpt.T_EncoderDepth{2} = [1 Inf];
            obj.BatchOpt.T_NumFirstEncoderFilters{1} = 32;
            obj.BatchOpt.T_NumFirstEncoderFilters{2} = [1 Inf];
            obj.BatchOpt.T_FilterSize{1} = 3;
            obj.BatchOpt.T_FilterSize{2} = [3 Inf];
            obj.BatchOpt.T_PatchesPerImage{1} = 32;
            obj.BatchOpt.T_PatchesPerImage{2} = [1 Inf];
            obj.BatchOpt.T_MiniBatchSize{1} = obj.mibModel.preferences.deep.MiniBatchSize;
            obj.BatchOpt.T_MiniBatchSize{2} = [1 Inf];
            obj.BatchOpt.T_augmentation = true;
            obj.BatchOpt.T_ExportTrainingPlots = true;
            obj.BatchOpt.T_SaveProgress = false;
            obj.BatchOpt.P_OverlappingTiles = true;
            
            if strcmp(obj.mibModel.preferences.deep.OriginalTrainingImagesDir, '\')
                obj.BatchOpt.OriginalTrainingImagesDir = obj.mibModel.myPath;
                obj.BatchOpt.OriginalPredictionImagesDir = obj.mibModel.myPath;
                obj.BatchOpt.ResultingImagesDir = obj.mibModel.myPath;    
            else
                obj.BatchOpt.OriginalTrainingImagesDir = obj.mibModel.preferences.deep.OriginalTrainingImagesDir;
                obj.BatchOpt.OriginalPredictionImagesDir = obj.mibModel.preferences.deep.OriginalPredictionImagesDir;
                obj.BatchOpt.ResultingImagesDir = obj.mibModel.preferences.deep.ResultingImagesDir;    
            end
            obj.BatchOpt.ImageFilenameExtension = obj.mibModel.preferences.deep.ImageFilenameExtension;
            obj.BatchOpt.ImageFilenameExtension{2} = upper(obj.mibModel.preferences.Filefilter.stdExt); %{'.AM', '.PNG', '.TIF'};
            obj.BatchOpt.ImageFilenameExtensionTraining = obj.mibModel.preferences.deep.ImageFilenameExtension;
            obj.BatchOpt.ImageFilenameExtensionTraining{2} = upper(obj.mibModel.preferences.Filefilter.stdExt); %{'.AM', '.PNG', '.TIF'};
            
            obj.BatchOpt.PreprocessingMode = {'Training and Prediction'};
            obj.BatchOpt.PreprocessingMode{2} = {'Prediction', 'Training', 'Training and Prediction'};
            obj.BatchOpt.CompressProcessedImages = obj.mibModel.preferences.deep.CompressProcessedImages;
            obj.BatchOpt.CompressProcessedModels = obj.mibModel.preferences.deep.CompressProcessedModels;
            
            obj.BatchOpt.NormalizeImages = false;
            obj.BatchOpt.ValidationFraction{1} = obj.mibModel.preferences.deep.ValidationFraction;
            obj.BatchOpt.ValidationFraction{2} = [0 1];
            obj.BatchOpt.ValidationFraction{3} = false;
            obj.BatchOpt.RandomGeneratorSeed{1} = obj.mibModel.preferences.deep.RandomGeneratorSeed;
            obj.BatchOpt.RandomGeneratorSeed{2} = [0 Inf];
            obj.BatchOpt.RandomGeneratorSeed{3} = true;
            %obj.BatchOpt.RelativePaths = obj.mibModel.preferences.deep.RelativePaths;
            obj.BatchOpt.showWaitbar = true;
            
            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Tools';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'mibDeep';           % name of the plugin
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Bioformats = 'Use Bioformats file reader for prediction images';
            obj.BatchOpt.mibBatchTooltip.BioformatsTraining = 'Use Bioformats file reader for training images';
            obj.BatchOpt.mibBatchTooltip.NetworkFilename = 'Network filename, a new filename for training or existing filename for prediction';
            obj.BatchOpt.mibBatchTooltip.Architecture = 'Architecture of the network';
            obj.BatchOpt.mibBatchTooltip.T_ConvolutionPadding = '"same": zero padding is applied to the inputs to convolution layers such that the output and input feature maps are the same size; "valid" - zero padding is not applied; the output feature map is smaller than the input feature map';
            obj.BatchOpt.mibBatchTooltip.Mode = 'Use tool in the training or prediction mode';
            obj.BatchOpt.mibBatchTooltip.T_InputPatchSize = 'Network input image size as [height width depth colors]';
            obj.BatchOpt.mibBatchTooltip.T_NumberOfClasses = 'Number of classes in the model including Exterior';
            obj.BatchOpt.mibBatchTooltip.T_SegmentationLayer = 'Define the type of the last (segmentation) layer of the network';
            obj.BatchOpt.mibBatchTooltip.T_EncoderDepth = 'The depth of the network determines the number of times the input volumetric image is downsampled or upsampled during processing';
            obj.BatchOpt.mibBatchTooltip.T_NumFirstEncoderFilters = 'Number of output channels for the first encoder stage';
            obj.BatchOpt.mibBatchTooltip.T_FilterSize = 'Convolutional layer filter size, specified as a positive odd integer';
            obj.BatchOpt.mibBatchTooltip.T_PatchesPerImage = 'Number of patches to extract from each image';
            obj.BatchOpt.mibBatchTooltip.T_MiniBatchSize = 'Number of observations that are returned in each batch';
            obj.BatchOpt.mibBatchTooltip.T_augmentation = 'Augment images during training';
            obj.BatchOpt.mibBatchTooltip.T_ExportTrainingPlots = 'When ticked export training scores to files, which are placed to Results\ScoreNetwork folder';
            obj.BatchOpt.mibBatchTooltip.T_SaveProgress = 'When ticked the network progress is saved to Results\ScoreNetwork folder';
            obj.BatchOpt.mibBatchTooltip.P_OverlappingTiles = 'when enabled use overlapping tiles during prediction, it is slower but may give better results';
            obj.BatchOpt.mibBatchTooltip.OriginalTrainingImagesDir = 'Specify directory with original images and models in the MIB *.model format';
            obj.BatchOpt.mibBatchTooltip.OriginalPredictionImagesDir = 'Specify directory with original images for prediction';
            obj.BatchOpt.mibBatchTooltip.ImageFilenameExtension = 'Filename extension of original images used for prediction';
            obj.BatchOpt.mibBatchTooltip.ImageFilenameExtensionTraining = 'Filename extension of original images used for traininig';
            obj.BatchOpt.mibBatchTooltip.ResultingImagesDir = 'Specify directory for resulting images for preprocessing and prediction, the following subfolders are used: TrainImages, TrainLabels, ValidationImages, ValidationLabels, PredictionImages';
            obj.BatchOpt.mibBatchTooltip.NormalizeImages = 'Normalize images during preprocessing, or use original images';
            obj.BatchOpt.mibBatchTooltip.CompressProcessedImages = 'Compression of images slows down performance but saves space';
            obj.BatchOpt.mibBatchTooltip.CompressProcessedModels = 'Compression of models slows down performance but saves space';
            obj.BatchOpt.mibBatchTooltip.PreprocessingMode = 'Preprocess images for prediction or training by splitting the datasets for training and validation';
            obj.BatchOpt.mibBatchTooltip.ValidationFraction = 'Fraction of images used for validation during training';
            obj.BatchOpt.mibBatchTooltip.RandomGeneratorSeed = 'Seed for random number generator used during splitting of test and validation datasets';
            %obj.BatchOpt.mibBatchTooltip.RelativePaths = 'Store paths of all directories as relative to location of the network file';
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not waitbar');
            
            obj.AugOpt2D = obj.mibModel.preferences.deep.AugOpt2D;
            obj.AugOpt3D = obj.mibModel.preferences.deep.AugOpt3D;
            obj.InputLayerOpt = obj.mibModel.preferences.deep.InputLayerOpt;
            obj.TrainingOpt = obj.mibModel.preferences.deep.TrainingOpt;
            obj.TrainingProgress = struct;
            
            obj.childControllers = {};    % initialize child controllers
            obj.childControllersIds = {};
            
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
            obj.View.Figure.Figure.Visible = 'on';
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
            
            try 
                gpuInfo = gpuDevice;
                obj.View.Figure.GPULabel.Text = sprintf('GPU: %s', gpuInfo(1).Name);
            catch err
                obj.View.Figure.GPULabel.Text = 'GPU: none';
                warndlg(sprintf('!!! Warning !!!\n\nYou do not have compatible CUDA card/driver! Without those the training will be extrelemy slow!\n\n%s', err.message), 'Missing GPU');
            end
        end
        
        function closeWindow(obj)
            % update preferences structure
            obj.mibModel.preferences.deep.OriginalTrainingImagesDir = obj.BatchOpt.OriginalTrainingImagesDir;
            obj.mibModel.preferences.deep.OriginalPredictionImagesDir = obj.BatchOpt.OriginalPredictionImagesDir;
            obj.mibModel.preferences.deep.ImageFilenameExtension = obj.BatchOpt.ImageFilenameExtension;
            obj.mibModel.preferences.deep.ResultingImagesDir = obj.BatchOpt.ResultingImagesDir;
            obj.mibModel.preferences.deep.CompressProcessedImages = obj.BatchOpt.CompressProcessedImages;
            obj.mibModel.preferences.deep.ValidationFraction = obj.BatchOpt.ValidationFraction{1};
            obj.mibModel.preferences.deep.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
            obj.mibModel.preferences.deep.RandomGeneratorSeed = obj.BatchOpt.RandomGeneratorSeed{1};
            %obj.mibModel.preferences.deep.RelativePaths = obj.BatchOpt.RelativePaths;
            
            obj.mibModel.preferences.deep.TrainingOpt = obj.TrainingOpt;
            obj.mibModel.preferences.deep.AugOpt2D = obj.AugOpt2D;
            obj.mibModel.preferences.deep.AugOpt3D = obj.AugOpt3D;
            obj.mibModel.preferences.deep.InputLayerOpt = obj.InputLayerOpt;
            
            
            %obj.mibModel.preferences.deep.AugOpt2D = obj.AugOpt2D;
            
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
            if strcmp(event.Source.Tag, 'BioformatsTraining')
                extentionFieldName = 'ImageFilenameExtensionTraining';
                bioformatsFileName = 'BioformatsTraining';
            end
            
            if obj.BatchOpt.(bioformatsFileName)
                obj.BatchOpt.(extentionFieldName){2} = upper(obj.mibModel.preferences.Filefilter.bioExt); %{'.AM', '.PNG', '.TIF'};
            else
                obj.BatchOpt.(extentionFieldName){2} = upper(obj.mibModel.preferences.Filefilter.stdExt); %{'.AM', '.PNG', '.TIF'};
            end
            if ~ismember(obj.BatchOpt.(extentionFieldName)(1), obj.BatchOpt.(extentionFieldName){2})
                obj.BatchOpt.(extentionFieldName)(1) = obj.BatchOpt.(extentionFieldName){2}(1);
            end
            
            obj.View.Figure.(extentionFieldName).Items = obj.BatchOpt.(extentionFieldName){2};
            obj.View.Figure.(extentionFieldName).Value = obj.BatchOpt.(extentionFieldName){1};
        end
        
        function selectNetwork(obj, networkName)
            % function selectNetwork(obj, networkName)
            % select a filename for a new network in the Train mode, or
            % select a network to use for the Predict mode
            %
            % Parameters:
            % networkName: optional parameter with the network full filename
            
            if nargin < 2; networkName = '';  end
            
            switch obj.BatchOpt.Mode{1}
                case 'Predict'
                    if isempty(networkName)
                        [file, path] = uigetfile({'*.mibDeep;', 'Deep MIB network files (*.mibDeep)';
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
                        obj.AugOpt2D = res.AugOpt2DStruct;
                        obj.TrainingOpt = res.TrainingOptStruct;
                        obj.InputLayerOpt = res.InputLayerOpt;
                        obj.AugOpt3D = res.AugOpt3DStruct;
                    catch err
                        % when the training was stopped before finish,
                        % those structures are not stored
                    end
                    
                    obj.updateWidgets();
                    
                    waitbar(1, obj.wb);
                    delete(obj.wb);
                case 'Train'
                    if isempty(networkName)
                        [file, path] = uiputfile({'*.mibDeep;', 'mibDeep files (*.mibDeep)';
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
                        useMaskedAway = 0;
                        outputLayer = dicePixelCustomClassificationLayer(outputLayerName, useMaskedAway);
                        
                        % check layer
                        %layer = dicePixelCustomClassificationLayer(outputLayerName, useMaskedAway);
                        %numClasses = 4;
                        %validInputSize = [4 4 numClasses];
                        %checkLayer(layer,validInputSize, 'ObservationDimension',4)
                        
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
        
        function patchOut = augmentAndCrop3dPatch(obj, patchIn, inputPatchSize, outputPatchSize, cropOnlySwitch)
            % function patchOut = augmentAndCrop3dPatch(obj, patchIn, inputPatchSize, outputPatchSize, cropOnlySwitch)
            %
            % Augment training data by set of operations encoded in
            % obj.AugOpt3D and/or crop the response to the network's output size. 
            % 
            % Parameters:
            % patchIn:
            % inputPatchSize: input patch size as [height, width, depth, color]
            % outputPatchSize: output patch size as [height, width, depth, classes]
            % cropOnlySwitch: a logical switch to just crop the data used
            % for the valid padding and validation of the 'same' padding
            % images
            %
            % Return values:
            % patchOut: return the image patches in a two-column table as required by the trainNetwork function for
            % single-input networks.
            
            augType = [];
            if cropOnlySwitch == 0
                if obj.AugOpt3D.RandXReflection; augType = [augType, {@fliplr}]; end
                if obj.AugOpt3D.RandYReflection; augType = [augType, {@flipud}]; end
                if obj.AugOpt3D.RandZReflection
                    flipZ = @(x) flip(x, 3);
                    augType = [augType, {flipZ}]; 
                end
                if obj.AugOpt3D.Rotation90
                    rot270 = @(x) rot90(x, 3);
                    augType = [augType, {@rot90}, {rot270}]; 
                end
                if obj.AugOpt3D.ReflectedRotation90
                    fliprot = @(x) rot90(fliplr(x));
                    augType = [augType, {fliprot}]; 
                end
                if isempty(augType)
                    errordlg(sprintf('!!! Error !!!\n\nAugmentation types were not selected!\nPlease use set 3D augmentation settings dialog'), 'Wrong augmentation');
                    return;
                end
                numAugFunc = numel(augType);    % number of functions to be used
            end
            
            inpVol = cell(size(patchIn,1), 1);
            inpResponse = cell(size(patchIn,1), 1);
            
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
                if cropOnlySwitch == 1  % do only crop
                    if cropSwitch
                        inpResponse{id, 1} = patchIn.ResponsePixelLabelImage{id}(y1:y2, x1:x2, z1:z2, :, :);
                    else
                        inpResponse{id, 1} = patchIn.ResponsePixelLabelImage{id};
                    end
                    inpVol{id, 1}= patchIn.InputImage{id};
                else    % augment and crop
                    rndIdx = randi(100, 1)/100;
                    if rndIdx > obj.AugOpt3D.Fraction   % if index lower than obj.AugOpt3D.Fraction -> augment the data
                        out =  patchIn.InputImage{id};
                        respOut = patchIn.ResponsePixelLabelImage{id};
                    else
                        augFuncIndex = randi(numAugFunc, 1);
                        out =  augType{augFuncIndex}(patchIn.InputImage{id});
                        respOut = augType{augFuncIndex}(patchIn.ResponsePixelLabelImage{id});
                    end
                    % Crop the response to to the network's output.
                    %respFinal=respOut(45:end-44,45:end-44,45:end-44,:);
                    if cropSwitch
                        inpResponse{id, 1} = respOut(y1:y2, x1:x2, z1:z2, :, :);
                    else
                        inpResponse{id, 1} = respOut;
                    end
                    inpVol{id, 1}= out;
                end
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
        
        function setAugmentation2DSettings(obj)
            % function setAugmentation2DSettings(obj)
            % update settings for augmentation fo 2D images
            global mibPath;
            
            prompts = { 'FillValue: Fill value used to define out-of-bounds points when resampling or rotating';...
                        'RandXReflection: random reflection in the left-right direction'; ...
                        'RandYReflection: random reflection in the top-bottom direction'; ...
                        'RandRotation: range of rotation, in degrees specified with two numbers, the rotation angle is picked randomly from a continuous uniform distribution between these numbers'; ...
                        'RandScale: range of uniform (isotropic) scaling applied to the input image specified with 2 numbers'; ...
                        'RandXScale: range of horizontal scaling applied to the input image, specified with 2 numbers'; ...
                        'RandYScale: range of vertical scaling applied to the input image, specified with 2 numbers'; ...
                        'RandXShear: range of horizontal shear applied to the input image, specified with 2 numbers. It is measured as an angle in degrees, and is in the range (-90, 90)'; ...
                        'RandYShear: range of vertical shear applied to the input image, specified with 2 numbers. It is measured as an angle in degrees, and is in the range (-90, 90)'};
        
            defAns = {num2str(obj.AugOpt2D.FillValue); ...
                        obj.AugOpt2D.RandXReflection; ...
                        obj.AugOpt2D.RandYReflection; ...
                        num2str(obj.AugOpt2D.RandRotation); ...
                        num2str(obj.AugOpt2D.RandScale); ...
                        num2str(obj.AugOpt2D.RandXScale); ...
                        num2str(obj.AugOpt2D.RandYScale); ...
                        num2str(obj.AugOpt2D.RandXShear); ...
                        num2str(obj.AugOpt2D.RandYShear)};
            dlgTitle = '2D augmentation settings';
            options.WindowStyle = 'normal';
            options.PromptLines = [2, 1, 1, 2, 1, ...
                                   1, 1, 2, 2];   % [optional] number of lines for widget titles
            %options.Title = 'My test Input dialog';   % [optional] additional text at the top of the window
            %options.TitleLines = 2;                   % [optional] make it twice tall, number of text lines for the title
            options.WindowWidth = 2;    % [optional] make window x1.2 times wider
            options.Columns = 1;    % [optional] define number of columns
            options.Focus = 1;      % [optional] define index of the widget to get focus
            options.HelpUrl = 'https://se.mathworks.com/help/deeplearning/ref/imagedataaugmenter.html'; % [optional], an url for the Help button
            %options.LastItemColumns = 1; % [optional] force the last entry to be on a single column
            
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            FillValue = str2double(answer{1});
            if isnan(FillValue); errordlg('FillValue parameter should be a positive number'); return; end
            obj.AugOpt2D.FillValue = FillValue;
            obj.AugOpt2D.RandXReflection = logical(answer{2});
            obj.AugOpt2D.RandYReflection = logical(answer{3});
            RandRotation = str2num(answer{4});
            if sum(isnan(RandRotation)) > 0 || numel(RandRotation) ~= 2; errordlg('RandRotation parameter should contain two numbers between -90 and 90'); return; end
            obj.AugOpt2D.RandRotation = RandRotation;
            RandScale = str2num(answer{5});
            if sum(isnan(RandScale)) > 0 || numel(RandScale) ~= 2; errordlg('RandScale parameter should contain two positive numbers around 1'); return; end
            obj.AugOpt2D.RandScale = RandScale;
            RandXScale = str2num(answer{6});
            if sum(isnan(RandXScale)) > 0 || numel(RandXScale) ~= 2; errordlg('RandXScale parameter should contain two positive numbers around 1'); return; end
            obj.AugOpt2D.RandXScale = RandXScale;
            RandYScale = str2num(answer{7});
            if sum(isnan(RandYScale)) > 0 || numel(RandYScale) ~= 2; errordlg('RandYScale parameter should contain two positive numbers around 1'); return; end
            obj.AugOpt2D.RandYScale = RandYScale;
            RandXShear = str2num(answer{8});
            if sum(isnan(RandXShear)) > 0 || numel(RandXShear) ~= 2; errordlg('RandXShear parameter should contain two numbers in the range -90:90'); return; end
            obj.AugOpt2D.RandXShear = RandXShear;
            RandYShear = str2num(answer{9});
            if sum(isnan(RandYShear)) > 0 || numel(RandYShear) ~= 2; errordlg('RandYShear parameter should contain two numbers in the range -90:90'); return; end
            obj.AugOpt2D.RandYShear = RandYShear;
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
                'MaxEpochs, maximum number of epochs to use for training'; ...
                'Shuffle, options for data shuffling'; ...
                'InitialLearnRate, used for training;  The default value is 0.01 for the "sgdm" solver and 0.001 for the "rmsprop" and "adam" solvers. If the learning rate is too low, then training takes a long time. If the learning rate is too high, then training might reach a suboptimal result or diverge'; ...
                'LearnRateSchedule, option for dropping learning rate during training';...
                'LearnRateDropPeriod, [piecewise only] number of epochs for dropping the learning rate';...
                'LearnRateDropFactor, [piecewise only] factor for dropping the learning rate, should be between 0 and 1';...
                'L2Regularization, factor for L2 regularization (weight decay)';...
                'Momentum, [sgdm only] contribution of the parameter update step of the previous iteration to the current iteration of sgdm';...
                'ValidationFrequency, frequency of network validation in number of iterations';...
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
                num2str(obj.TrainingOpt.ValidationFrequency);...
                {'training-progress', 'none', find(ismember({'training-progress', 'none'}, obj.TrainingOpt.Plots))} };
            dlgTitle = 'Training settings';
            options.WindowStyle = 'normal';
            options.PromptLines = [1, 2, 1, 6, 2, ...
                2, 3, 2, 3, 2, 1];   % [optional] number of lines for widget titles
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
            obj.TrainingOpt.ValidationFrequency = str2double(answer{10});
            obj.TrainingOpt.Plots = answer{11};
        end
        
        function Start(obj, event)
            % start main calculation of the plugin
            switch event.Source.Tag
                case 'PreprocessButton'
                    obj.StartPreprocessing();
                case 'TrainButton'
                    obj.StartTraining();
                case 'PredictButton'
                    obj.StartPrediction();
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
        
        function [skipTrainingPreprocessing, skipPredictionPreprocessing] = proceedWithPreprocessing(obj)
            % function [skipTrainingPreprocessing, skipPredictionPreprocessing] = proceedWithPreprocessing(obj)
            % check whether the number of preprocessed image files matches number
            % of input image files
            %
            % Return values:
            % skipTrainingPreprocessing: logical switch, when false - number of files dismatch and preprocessing of images for training is required
            % skipPredictionPreprocessing: logical switch, when false - number of files dismatch and preprocessing of images for prediction is required
            
            skipTrainingPreprocessing = 1;
            skipPredictionPreprocessing = 1;
            if ismember(obj.BatchOpt.PreprocessingMode{1}, {'Already preprocessed', 'Use images without preprocessing'}); return; end    % do not perform processing
            
            fnExtension = ['.' obj.BatchOpt.ImageFilenameExtension{1}];
            
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Training') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Training and Prediction')
                totalNumFiles = 0;  % counter of image files in the original image directories
                numFiles = 0;   % counter of image files in the processing directory
                
                files = dir(obj.BatchOpt.OriginalTrainingImagesDir);
                files([files.isdir]) = [];  % remove directories
                for i=1:numel(files)
                    if contains(files(i).name, lower(fnExtension))
                        totalNumFiles = totalNumFiles + 1;
                    end
                end
                
                if exist(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'), 'dir')
                    tmp1 = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'));
                    numFiles = numFiles + sum(~vertcat(tmp1.isdir));
                end
                
                if exist(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'), 'dir')
                    tmp1 = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'));
                    numFiles = numFiles + sum(~vertcat(tmp1.isdir));
                end
                % If total number of preprocessed files is not equal to the number of
                % files in the dataset, perform preprocessing. Otherwise, preprocessing has
                % already been completed and can be skipped.
                skipTrainingPreprocessing = (numFiles == totalNumFiles);
            end
            
            if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Prediction') || strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Training and Prediction')
                totalNumFiles = 0;  % counter of image files in the original image directories
                numFiles = 0;   % counter of image files in the processing directory
                
                files = dir(obj.BatchOpt.OriginalPredictionImagesDir);
                files([files.isdir]) = [];  % remove directories
                for i=1:numel(files)
                    if contains(files(i).name, lower(fnExtension))
                        totalNumFiles = totalNumFiles + 1;
                    end
                end
                
                if exist(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'),'dir')
                    tmp1 = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'));
                    numFiles = numFiles + sum(~vertcat(tmp1.isdir));
                end
                % If total number of preprocessed files is not equal to the number of
                % files in the dataset, perform preprocessing. Otherwise, preprocessing has
                % already been completed and can be skipped.
                skipPredictionPreprocessing = (numFiles == totalNumFiles);
            end
            
        end
        
        function processImagesForTraining(obj)
            % function processImagesForTraining(obj)
            % Normalize datasets by subtracting the mean and dividing by
            % the standard deviation and stretching between 0 and 1
            
            %% Load data
            % If the directory for preprocessed data does not exist, or only a partial
            % set of the data files have been processed, process the data
            
            %[skipTrainingPreprocessing, ~] = obj.proceedWithPreprocessing();
            %if skipTrainingPreprocessing == 1; return; end
            
            % skip processing images for training if already processed or
            % prediction mode is selected
            if ismember(obj.BatchOpt.PreprocessingMode{1}, {'Already preprocessed', 'Prediction'}); return; end

            if obj.BatchOpt.showWaitbar; obj.wb = waitbar(0, sprintf('Creating image datastore\nPlease wait...'), 'Name', sprintf('%s: processing for training', obj.BatchOpt.Architecture{1})); end
            
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            
            % make datastore for images
            try
                getDataOptions.mibBioformatsCheck = obj.BatchOpt.BioformatsTraining;
                imgDS = imageDatastore(obj.BatchOpt.OriginalTrainingImagesDir, 'FileExtensions', ...
                    lower(['.' obj.BatchOpt.ImageFilenameExtensionTraining{1}]), 'ReadFcn', @(fn)mibLoadImages(fn, getDataOptions));
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            % preparing the directories
            % delete exising directories and files
            try
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
            catch err    
                
            end
            % make new directories
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels'));
            
            if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, sprintf('Creating model datastore\nPlease wait...')); end
            % make datastore for models
            % read number of materials for the first file
            files = dir([obj.BatchOpt.OriginalTrainingImagesDir, filesep '*.model']);
            if isempty(files)
                errordlg(sprintf('!!! Error !!!\n\nModel files are missing in\n%s', obj.BatchOpt.OriginalTrainingImagesDir), 'Missing model files!');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            modelFn = fullfile(files(1).folder, files(1).name);
            res = load(modelFn, '-mat', 'modelMaterialNames');
            classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
            pixelLabelID = 0:numel(classNames)-1;
            
            try
                modDS = pixelLabelDatastore(obj.BatchOpt.OriginalTrainingImagesDir, classNames, pixelLabelID, ...
                    'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
            catch err
                extraText = '';
                if strfind(err.message, 'The value of ''classNames'' is invalid')
                    extraText = sprintf('\n\nTip: materials of the model should have distinct names (for example: "material_1") and numbers 1, 2, 3, etc are not allowed!\nPlease rename materials of the model and try again');
                end
                errordlg(sprintf('!!! Error !!!\n\n%s%s', err.message, extraText));
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            % I = readimage(modDS,1);  % read model test
            reset(modDS);
            
            %% Process images and split them to training and validation dirs
            NumFiles = length(imgDS.Files);
            % init random generator
            rng(obj.BatchOpt.RandomGeneratorSeed{1});     
            randIndices = randperm(NumFiles);   % Random permutation of integers
            validationIndices = randIndices(1:ceil(obj.BatchOpt.ValidationFraction{1}*NumFiles));   % get indices of images to be used for validation
            
            id = 1;
            if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, sprintf('Processing images\nPlease wait...')); end
            while hasdata(imgDS)
                outImg = read(imgDS);   % read image as [height, width, color, depth]
                [~, fnOut] = fileparts(imgDS.Files{id});    % get filename of the image
                
                % Data set with a valid size for 3-D U-Net (multiple of 8).
                % ind = floor(size(tcropVol)/8)*8;    % find the optimal size of the dataset for U-net
                % incropVol = tcropVol(1:ind(1),1:ind(2),1:ind(3),:);     % crop volume
                
                if obj.BatchOpt.NormalizeImages
                    fprintf('!!! Warning !!! Normalizing images!\n')
                    outImg = obj.channelWisePreProcess(outImg);     % normalize the signals, remove outliers and scale between 0 and 1
                end
                if ndims(outImg) == 4   % strcmp(obj.BatchOpt.Architecture{1}, '3D U-net')
                    outImg = permute(outImg, [1 2 4 3]);    % permute from [height, width, color, depth] -> [height, width, depth, color]
                    %outImg = single(outImg);
                end
                
                if strcmp(obj.BatchOpt.Architecture{1}(1:2), '2D')
                    if id == 1; outModelFull = readNumeric(modDS);  end    % read corresponding model
                    outModel = outModelFull(:,:,id);    % get 2D slice from the model
                    [~, fnModOut] = fileparts(imgDS.Files{id});    % get filename for the model
                    fnModOut = sprintf('Labels_%s', fnModOut);  % generate name for the output model file
                else
                    outModel = readNumeric(modDS);      % read corresponding model
                    [~, fnModOut] = fileparts(modDS.Files{id});    % get filename for the model
                end
                
                % Split data into training, validation and test sets based
                % on obj.BatchOpt.ValidationFraction{1} value
                if isempty(find(validationIndices == id, 1))    %(id <= floor((1-obj.BatchOpt.ValidationFraction{1})*NumFiles))
                    imDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages');
                    labelDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels');
                else
                    imDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages');
                    labelDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels');
                end
                
                % saving image
                if obj.BatchOpt.CompressProcessedImages
                    save(fullfile(imDir, sprintf('%s.mat', fnOut)), 'outImg');   % save image file
                else
                    save(fullfile(imDir, sprintf('%s.mat', fnOut)), 'outImg','-nocompression');   % save image file
                end
                % saving models
                if obj.BatchOpt.CompressProcessedModels
                    save(fullfile(labelDir, sprintf('%s.mat', fnModOut)), 'outModel');  % save model file
                else
                    save(fullfile(labelDir, sprintf('%s.mat', fnModOut)), 'outModel', '-nocompression');  % save model file
                end
                
                if obj.BatchOpt.showWaitbar; waitbar(id/NumFiles, obj.wb); end
                id = id + 1;
            end
            if obj.BatchOpt.showWaitbar; waitbar(1, obj.wb); delete(obj.wb); end
        end
        
        function result = processImagesForPrediction(obj)
            % function result = processImagesForPrediction(obj)
            % Normalize datasets by subtracting the mean and dividing by
            % the standard deviation and stretching between 0 and 1
            
            result = 0;
            %% Load data
            % If the directory for preprocessed data does not exist, or only a partial
            % set of the data files have been processed, process the data
            %[~, skipPredictionPreprocessing] = obj.proceedWithPreprocessing();
            %if skipPredictionPreprocessing == 1; return; end
            
            % skip processing images for training if already processed or
            % training mode is selected
            if ismember(obj.BatchOpt.PreprocessingMode{1}, {'Already preprocessed', 'Training'}); return; end

            if obj.BatchOpt.showWaitbar; obj.wb = waitbar(0, sprintf('Creating image datastore\nPlease wait...'), 'Name', sprintf('%s: processing for prediction', obj.BatchOpt.Architecture{1})); end
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            
            try
                getDataOptions.mibBioformatsCheck = obj.BatchOpt.Bioformats;
                imgDS = imageDatastore(obj.BatchOpt.OriginalPredictionImagesDir, 'FileExtensions', lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]), ...
                    'ReadFcn', @(fn)mibLoadImages(fn, getDataOptions));
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            try %#ok<TRYNC>
                if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels'))
                    rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels'), 's');
                end
                if isfolder(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'))
                    rmdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), 's');
                end
            end
            
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));
            reset(imgDS);
            
            % preprocessing of ground truth models is needed only for 2D
            % case, for 3D case the evaluation will be done over original files
            if strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D') 
                groundFiles = dir(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, '*.model'));
            else
                groundFiles = dir(fullfile(obj.BatchOpt.OriginalPredictionImagesDir, '*.model'));
            end
            if ~isempty(groundFiles)
                if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, sprintf('Creating ground trooth model datastore\nPlease wait...')); end
                labelDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels');
                
                mkdir(labelDir);
                
                % make datastore for models with ground truth
                % read number of materials for the first file
                modelFn = fullfile(groundFiles(1).folder, groundFiles(1).name);
                res = load(modelFn, '-mat', 'modelMaterialNames');
                classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                pixelLabelID = 0:numel(classNames)-1;

                try
                    modDS = pixelLabelDatastore(obj.BatchOpt.OriginalPredictionImagesDir, classNames, pixelLabelID, ...
                        'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                catch err
                    extraText = '';
                    if strfind(err.message, 'The value of ''classNames'' is invalid')
                        extraText = sprintf('\n\nTip: materials of the model should have distinct names (for example: "material_1") and numbers 1, 2, 3, etc are not allowed!\nPlease rename materials of the model and try again');
                    end
                    errordlg(sprintf('!!! Error !!!\n\n%s%s', err.message, extraText));
                    if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                    return;
                end
                % I = readimage(modDS,1);  % read model test
                reset(modDS);
            end
            NumFiles = length(imgDS.Files);
            
            %% Process images
            imgId = 1;
            if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, sprintf('Processing images\nPlease wait...')); end
            while hasdata(imgDS)
                outImg = read(imgDS);   % read image
                [~, fnOut] = fileparts(imgDS.Files{imgId});    % get filename of the image
                
                if ~isempty(groundFiles)
                    if strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D')
                        outModel = readNumeric(modDS); 
                    else
                        if imgId == 1; outModelFull = readNumeric(modDS);  end    % read ground truth model
                        outModel = outModelFull(:,:,imgId);    % get 2D slice from the model
                    end
                    [~, fnModOut] = fileparts(imgDS.Files{imgId});    % get filename for the model
                    fnModOut = sprintf('Labels_%s', fnModOut);  % generate name for the output model file
                end
                
                % Data set with a valid size for 3-D U-Net (multiple of 8).
                % ind = floor(size(tcropVol)/8)*8;    % find the optimal size of the dataset for U-net
                % incropVol = tcropVol(1:ind(1),1:ind(2),1:ind(3),:);     % crop volume
                if obj.BatchOpt.NormalizeImages
                    outImg = obj.channelWisePreProcess(outImg);     % normalize the signals, remove outliers and scale between 0 and 1
                end
                if ndims(outImg) == 4   % strcmp(obj.BatchOpt.Architecture{1}, '3D U-net')
                    outImg = permute(outImg, [1 2 4 3]);    % permute from [height, width, color, depth] -> [height, width, depth, color]
                end
                imDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages');
                
                % saving images for prediction
                if obj.BatchOpt.CompressProcessedImages
                    save(fullfile(imDir, sprintf('%s.mat', fnOut)), 'outImg', '-v7.3');   % save image file
                else
                    save(fullfile(imDir, sprintf('%s.mat', fnOut)), 'outImg', '-nocompression', '-v7.3');   % save image file
                end
                
                % saving ground truth models for prediction images
                if ~isempty(groundFiles)
                    if obj.BatchOpt.CompressProcessedModels
                        save(fullfile(labelDir, sprintf('%s.mat', fnModOut)), 'outModel', '-v7.3');  % save model file
                    else
                        save(fullfile(labelDir, sprintf('%s.mat', fnModOut)), 'outModel', '-nocompression', '-v7.3');  % save model file
                    end
                end
                
                if obj.BatchOpt.showWaitbar; waitbar(imgId/NumFiles, obj.wb); end
                imgId = imgId + 1;
            end
            
            if obj.BatchOpt.showWaitbar; waitbar(1, obj.wb); delete(obj.wb); end
            result = 1;
        end
        
        function StartPreprocessing(obj)
            % function StartPreprocessing(obj)
            % Normalize datasets by subtracting the mean and dividing by
            % the standard deviation and stretching between 0 and 1
            
            obj.processImagesForTraining();     % process images for training
            obj.processImagesForPrediction();     % process images for training
        end
        
        function StartTraining(obj)
            % function StartTraining(obj)
            % perform training of the network
            global mibPath;
            
            answer = questdlg(sprintf('Have images for training were preprocessed?\n\nIf not, please switch to the Directories and Preprocessing tab and preprocess images for training'), ...
                'Preprocessing', 'Yes', 'No', 'Yes');
            if strcmp(answer, 'No'); return; end
            
            %% Create Random Patch Extraction Datastore for Training
            % create image data store
            obj.TrainingProgress = struct();
            obj.TrainingProgress.stopTraining = false;
            
            inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);
            if numel(inputPatchSize) ~= 4
                errordlg(sprintf('!!! Error !!!\n\nPlease provide the input patch size (BatchOpt.T_InputPatchSize) as 4 numbers that define\nheight, width, depth, colors\n\nFor example:\n"32, 32, 1, 3" for 2D U-net of 3 color channel images\n"64, 64, 64, 1" for 3D U-net of 1 color channel images'), ...
                    'Wrong patch size');
                return;
            end
            
            % make directories for export of the training scores
            if obj.BatchOpt.T_ExportTrainingPlots
                delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.csv'));     % delete all csv files
                delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.score'));     % delete all score matlab files
            end

            % check whether it is needed to continue the previous training
            % or start a new one
            checkPointRestoreFile = '';     % selected FULL filename for the network restore
            currentNetFile = {'not present'};   % place maker for the loaded network
            checkPointFiles = {'not present'};  % place maker for the checkpoint networks
            if exist(obj.BatchOpt.NetworkFilename, 'file') == 2
                [~, currentNetFile, netExt] = fileparts(obj.BatchOpt.NetworkFilename);
                currentNetFile = {[currentNetFile netExt]};     % already existing network
            end
            
            if obj.BatchOpt.T_SaveProgress  % checkpoint networks
                warning('off', 'MATLAB:MKDIR:DirectoryExists');
                mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork'));
                
                progressFiles = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.mat'));
                if ~isempty(progressFiles)
                    [~, idx]=sort([progressFiles.datenum], 'descend');      % sort in time order
                    checkPointFiles = {progressFiles(idx).name};
                end
            end
            
            if ~strcmp(currentNetFile{1}, 'not present') || ~strcmp(currentNetFile{1}, 'not present')
                prompts = {'Select the check point:'};
                defAns = {[{'Start new training'}, currentNetFile, checkPointFiles], 1};
                dlgTitle = 'Select checkpoint';
                options.PromptLines = 1;
                options.Title = sprintf('Files with training checkpoints were detected.\nPlease select the checkpoint to continue, if you choose "Start new training" the checkpoint directory will be cleared from the older checkpoints and the new training session initiated:');
                options.TitleLines = 5;
                options.WindowWidth = 1.4;
                [answer, selPosition] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer); return; end
                if strcmp(answer{1}, 'not present')
                    errordlg(sprintf('!!! Error !!!\n\nWrong selection, please select filename or Start new training!'));
                    return;
                end
                switch selPosition
                    case 1  % start new training
                        if obj.BatchOpt.T_SaveProgress
                            delete(fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', '*.mat'));     % delete all score matlab files
                        end
                    case 2  % continue from the loaded net
                        checkPointRestoreFile = obj.BatchOpt.NetworkFilename;
                    otherwise  % continue from the checkpoint
                        checkPointRestoreFile = fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork', answer{1});
                end
            end
            
            if obj.BatchOpt.showWaitbar 
                obj.wb = waitbar(0, sprintf('Creating datastores\nPlease wait...'), ...
                    'Name', 'Training network', ...
                    'CreateCancelBtn', @obj.stopTrainingCallback); 
            end
            
            % the other options are not available, require to process images
            try
                imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainImages'), ...
                    'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); end
                return;
            end
            
            % get class names
            files = dir([obj.BatchOpt.OriginalTrainingImagesDir, filesep '*.model']);
            modelFn = fullfile(files(1).folder, files(1).name);
            res = load(modelFn, '-mat', 'modelMaterialNames', 'modelMaterialColors');
            classColors = res.modelMaterialColors;  % get colors
            classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
            pixelLabelID = 0:numel(classNames) - 1;
            
            labelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'TrainLabels'), ...
                classNames, pixelLabelID, 'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
            %% Create Random Patch Extraction Datastore for Validation
            if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, 'Create a datastore for validation ...'); end
            
            fileList = dir(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages', '*.mat'));
            if ~isempty(fileList)
                valImgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationImages'), ...
                    'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
                valLabelsDS = pixelLabelDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'ValidationLabels'), ...
                    classNames, pixelLabelID, 'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
            else    % do not use validation
                valImgDS = [];
                valLabelsDS = [];
            end
            
            switch obj.BatchOpt.Architecture{1}(1:2)
                case '3D'
                    % Augmenter needs to be applied to the patches later
                    % after initialization using transform function for 3D
                    % unet
                    patchDS = randomPatchExtractionDatastore(imgDS, labelsDS, inputPatchSize(1:3), ...
                        'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1}); %#ok<ST2NM>
                    patchDS.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
                    
                    % create random patch extraction datastore for validation
                    if ~isempty(valImgDS)
                        valPatchDS = randomPatchExtractionDatastore(valImgDS, valLabelsDS, inputPatchSize(1:3), ...
                            'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1});
                    else
                        valPatchDS = [];
                    end
                case '2D'
                    % for 2D U-net augumentation is enabled already during
                    % randomPatchExtractionDatastore initiation

                    if obj.BatchOpt.T_augmentation  % define datastore with augmentation
                        try
                            imageAugmenter = imageDataAugmenter( ...
                                'FillValue', obj.AugOpt2D.FillValue, ...
                                'RandXReflection', obj.AugOpt2D.RandXReflection, ...
                                'RandYReflection', obj.AugOpt2D.RandYReflection, ...
                                'RandRotation', obj.AugOpt2D.RandRotation, ...
                                'RandScale', obj.AugOpt2D.RandScale, ...
                                'RandXScale',obj.AugOpt2D.RandXScale, ...
                                'RandYScale',obj.AugOpt2D.RandYScale, ...
                                'RandXShear',obj.AugOpt2D.RandXShear, ...
                                'RandYShear',obj.AugOpt2D.RandYShear);
                        catch err
                            errordlg(sprintf('!!! Error !!!\n\n%s\n\nPlease go back to 2D augmenter settings and fix this!', err.message), 'Augmenter error');
                        end

                        patchDS = randomPatchExtractionDatastore(imgDS, labelsDS, inputPatchSize(1:2), ...
                            'DataAugmentation',imageAugmenter, ...
                            'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1}); %#ok<ST2NM>
                    else    % % define datastore without augmentation
                        patchDS = randomPatchExtractionDatastore(imgDS, labelsDS, inputPatchSize(1:2), ...
                            'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1}); %#ok<ST2NM>
                    end
                    patchDS.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
                    
%                     % test
%                     imgTest = read(AugTrainDS);
%                     imtool(imgTest.InputImage{1});
%                     imtool(uint8(imgTest.ResponsePixelLabelImage{1}), []);
%                     reset(AugTrainDS);
                    
                    % create random patch extraction datastore for validation
                    if ~isempty(valImgDS)
                        valPatchDS = randomPatchExtractionDatastore(valImgDS, valLabelsDS, inputPatchSize(1:2), ...
                            'PatchesPerImage', obj.BatchOpt.T_PatchesPerImage{1});
                    else
                        valPatchDS = [];
                    end
            end
            %valDS = pixelLabelImageDatastore(valImgDS, valLabelsDS);
            if ~isempty(valPatchDS)
                valPatchDS.MiniBatchSize = obj.BatchOpt.T_MiniBatchSize{1};
            end
            
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
                        AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 0));
                        if ~isempty(valPatchDS)
                            valDS = transform(valPatchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 1));
                        else
                            valDS = [];
                        end
                    else
                        if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                            % crop responses to the output size of the network
                            AugTrainDS = transform(patchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 1));
                            if ~isempty(valPatchDS)
                                valDS = transform(valPatchDS, @(patchIn)obj.augmentAndCrop3dPatch(patchIn, inputPatchSize(1:3), outputPatchSize, 1));
                            else
                                valDS = [];
                            end
                                
                        else
                            AugTrainDS = patchDS;  % no cropping needed for the same padding  
                            valDS = valPatchDS;
                        end
                    end
                case '2D'
                    % for 2D U-net augumentation is enabled already during
                    % randomPatchExtractionDatastore initiation
                    if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')    % crop responses to the size of the network output
                        % datastore history
                        % imgDS + labelsDS => AugTrainDS; 
                        % valImgDS + valLabelsDS => valDS
                        AugTrainDS = transform(patchDS, @(patchIn)mibDeepController.crop2dPatchForValid(patchIn, inputPatchSize, outputPatchSize));
                        if ~isempty(valPatchDS)
                            valDS = transform(valPatchDS, @(patchIn)mibDeepController.crop2dPatchForValid(patchIn, inputPatchSize, outputPatchSize));
                        else
                            valDS = [];
                        end
                    else
                        AugTrainDS = patchDS;
                        valDS = valPatchDS;
                    end
                    % % preview augmented patch
                    % minibatch = preview(AugTrainDS);
                    % imtool(imtile(minibatch.InputImage));
                    % a = minibatch.InputImage{1};
                    % b = minibatch.ResponsePixelLabelImage{1};
                    % imshowpair(a,uint8(b))
            end
            
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
            
            obj.TrainingProgress.useCustomProgressPlot = false;
            % for debug purposes of the custom training plot for the
            % deployed version of MIB
            % set to true
            %obj.TrainingProgress.useCustomProgressPlot = true;
            
            verboseSwitch = false;
            if strcmp(obj.TrainingOpt.Plots, 'none') 
                verboseSwitch = true;   % drop message into the command window when the plots are disabled
            end
            
            % since training plot is not available for the deployed
            % version different initialization is required
            if isdeployed
                PlotsSwitch = 'none';
            else
                if obj.TrainingProgress.useCustomProgressPlot   % for debug
                    PlotsSwitch = 'none';
                else
                    PlotsSwitch = obj.TrainingOpt.Plots;
                end
            end
            
            CheckpointPath = '';
            if obj.BatchOpt.T_SaveProgress
                CheckpointPath = fullfile(obj.BatchOpt.ResultingImagesDir, 'ScoreNetwork');
            end
            
            % calculate max number of iterations
            obj.TrainingProgress.maxNoIter = ...        % as noImages*PatchesPerImage*MaxEpochs/Minibatch
                patchDS.NumObservations*obj.TrainingOpt.MaxEpochs/obj.BatchOpt.T_MiniBatchSize{1};
            obj.TrainingProgress.iterPerEpoch = ...
                patchDS.NumObservations/obj.BatchOpt.T_MiniBatchSize{1};
            
            try
                switch obj.TrainingOpt.solverName
                    case {'adam', 'rmsprop'}
                        if ~isempty(valDS)
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'ValidationData', valDS, ...
                                'ValidationFrequency', obj.TrainingOpt.ValidationFrequency, ...
                                'Plots', PlotsSwitch, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1},...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath);
                        else
                            TrainingOptions = trainingOptions(obj.TrainingOpt.solverName, ...
                                'MaxEpochs', obj.TrainingOpt.MaxEpochs, ...
                                'Shuffle', obj.TrainingOpt.Shuffle, ...
                                'InitialLearnRate', obj.TrainingOpt.InitialLearnRate, ...
                                'LearnRateSchedule', obj.TrainingOpt.LearnRateSchedule, ...
                                'LearnRateDropPeriod', obj.TrainingOpt.LearnRateDropPeriod, ...
                                'LearnRateDropFactor', obj.TrainingOpt.LearnRateDropFactor, ...
                                'L2Regularization', obj.TrainingOpt.L2Regularization, ...
                                'Plots', PlotsSwitch, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1},...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath);
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
                                'ValidationFrequency', obj.TrainingOpt.ValidationFrequency, ...
                                'Verbose', verboseSwitch, ...
                                'ResetInputNormalization', ResetInputNormalization, ...
                                'MiniBatchSize', obj.BatchOpt.T_MiniBatchSize{1}, ...
                                'OutputFcn', @obj.trainingProgressDisplay,...
                                'CheckpointPath', CheckpointPath);
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
                                'CheckpointPath', CheckpointPath);
                        end
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Wrong training options');
                if obj.BatchOpt.showWaitbar; delete(obj.wb); return; end
            end
            
            %% Train Network
            % After configuring the training options and the data source, train the 3-D U-Net network
            % by using the trainNetwork function.
            
            if obj.BatchOpt.showWaitbar
                if obj.TrainingProgress.stopTraining == true; if isvalid(obj.wb); delete(obj.wb); end; return; end
                if ~isvalid(obj.wb); return; end
                waitbar(0, obj.wb, sprintf('Training\nPlease wait...')); 
            end
            tic
            modelDateTime = datestr(now, 'dd-mmm-yyyy-HH-MM-SS');
            
            % load the checkpoint to resume training
            if ~isempty(checkPointRestoreFile)
                load(checkPointRestoreFile, 'net', '-mat');
                lgraph = layerGraph(net);
            end
            
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
            
            try
                [net, info] = trainNetwork(AugTrainDS, lgraph, TrainingOptions);
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s', err.message)); 
                if obj.BatchOpt.showWaitbar; if isvalid(obj.wb); delete(obj.wb); end; end
                return;
            end
            
            %save(fullfile(outputDir, ['Trained3DUNet-' modelDateTime '-Epoch-' num2str(options.MaxEpochs) '.net']), 'net');
            if obj.BatchOpt.showWaitbar;  if ~isvalid(obj.wb); return; end; waitbar(0.98, obj.wb, 'Saving network...'); end
            %[outputDir, netName, Ext] = fileparts(obj.BatchOpt.NetworkFilename);
            %save(fullfile(outputDir, ['Trained3DUNet_' ProjectName '.net']), 'net');
            
            save(obj.BatchOpt.NetworkFilename, 'net', 'TrainingOptStruct', 'AugOpt2DStruct', 'AugOpt3DStruct', 'InputLayerOpt', ...
                'classNames', 'classColors', 'inputPatchSize', 'outputPatchSize', 'BatchOpt', '-mat');
            
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
            toc
            
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
                [file, path] = uiputfile({'*.mibCfg;', 'mibDeep config files (*.mibCfg)';
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
            
            % try to export path as relatives
            BatchOpt.NetworkFilename = strrep(BatchOpt.NetworkFilename, path, '[RELATIVE]'); %#ok<*PROP>
            BatchOpt.OriginalTrainingImagesDir = strrep(BatchOpt.OriginalTrainingImagesDir, path, '[RELATIVE]');
            BatchOpt.OriginalPredictionImagesDir = strrep(BatchOpt.OriginalPredictionImagesDir, path, '[RELATIVE]');
            BatchOpt.ResultingImagesDir = strrep(BatchOpt.ResultingImagesDir, path, '[RELATIVE]');
                        
            % generate config file; the config file is the same as *.mibDeep but without 'net' field
            save(configName, ...
                'TrainingOptStruct', 'AugOpt2DStruct', 'AugOpt3DStruct', ...
                'InputLayerOpt', 'BatchOpt', '-mat');
        end
        
        function loadConfig(obj)
            % function loadConfig(obj)
            % load config file with Deep MIB settings
            
            [file, path] = uigetfile({'*.mibCfg;', 'Deep MIB config files (*.mibCfg)';
                '*.mat', 'Mat files (*.mat)'}, 'Open network file', ...
                obj.BatchOpt.NetworkFilename);
            if file == 0; return; end
            configName = fullfile(path, file);
            
            obj.wb = waitbar(0, sprintf('Loadning config file\nPlease wait...'));
            
            res = load(configName, '-mat');  
            
            % restore full paths from relative
            res.BatchOpt.NetworkFilename = strrep(res.BatchOpt.NetworkFilename, '[RELATIVE]', path); %#ok<*PROP>
            res.BatchOpt.OriginalTrainingImagesDir = strrep(res.BatchOpt.OriginalTrainingImagesDir, '[RELATIVE]', path);
            res.BatchOpt.OriginalPredictionImagesDir = strrep(res.BatchOpt.OriginalPredictionImagesDir, '[RELATIVE]', path);
            res.BatchOpt.ResultingImagesDir = strrep(res.BatchOpt.ResultingImagesDir, '[RELATIVE]', path);
            
            % add/update BatchOpt with the provided fields in BatchOptIn
            % combine fields from input and default structures
            obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, res.BatchOpt);
            
            try
                obj.AugOpt2D = res.AugOpt2DStruct;
                obj.TrainingOpt = res.TrainingOptStruct;
                obj.InputLayerOpt = res.InputLayerOpt;
                obj.AugOpt3D = res.AugOpt3DStruct;
            catch err
                % when the training was stopped before finish,
                % those structures are not stored
            end
            
            obj.updateWidgets();
            
            waitbar(1, obj.wb);
            delete(obj.wb);
        end
        
        function stopTrainingCallback(obj, varargin)
            obj.TrainingProgress.stopTraining = true;
            if strcmp(varargin{2}.Source.Tag, 'TMWWaitbar')     % waitbar
                delete(varargin{2}.Source);
                return;
            end
            if strcmp(varargin{2}.EventName, 'Close')   % close training progress window
                if isfield(obj.TrainingProgress, 'hFig')    % otherwise it will try to trigger this upon X-button press of the waitbar
                    delete(obj.TrainingProgress.hFig);  
                end
            end
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
            maxPoints = 1000;     % max number of points in the plots, should be an even number
            if ProgressStruct.Iteration == 0
                %obj.TrainingProgress.hFig = uifigure('Name', 'Training progress', ...
                %    'CloseRequestFcn', @obj.stopTrainingCallback);
                obj.TrainingProgress.hFig = uifigure('Name', 'Training progress');
                ScreenSize = get(0, 'ScreenSize');
                FigPos(1) = 1/2*(ScreenSize(3)-800);
                FigPos(2) = 2/3*(ScreenSize(4)-600);
                obj.TrainingProgress.hFig.Position = [FigPos(1), FigPos(2), 800, 600];
                
                obj.TrainingProgress.TrainXvec = zeros([maxPoints, 1]);  % vector of iteration numbers for training
                obj.TrainingProgress.TrainLoss = zeros([maxPoints, 1]);  % training loss vector
                obj.TrainingProgress.TrainAccuracy = zeros([maxPoints, 1]);  % training accuracy vector
                obj.TrainingProgress.ValidationXvec = zeros([maxPoints, 1]);     % vector of iteration numbers for validation
                obj.TrainingProgress.ValidationLoss = zeros([maxPoints, 1]); % validation loss vector
                obj.TrainingProgress.ValidationAccuracy = zeros([maxPoints, 1]); % validation accuracy vector
                obj.TrainingProgress.TrainXvecIndex = 1;    % index of the next point to be added to the training vectors
                obj.TrainingProgress.ValidationXvecIndex = 1; % index of the next point to be added to the validation vectors
                
                obj.TrainingProgress.ax1 = uiaxes('Parent',obj.TrainingProgress.hFig,...
                    'Units','pixels',...
                    'Position', [20, 300, 560, 240]); 
                obj.TrainingProgress.hP1 = plot(obj.TrainingProgress.ax1, 0, 0, '-', 0, 0, '-o');
                obj.TrainingProgress.hP1(2).MarkerSize = 4;
                obj.TrainingProgress.hP1(2).MarkerFaceColor = 'r';
                obj.TrainingProgress.ax1.YLabel.String = 'Accuracy, %%';
                obj.TrainingProgress.ax1.XLabel.String = 'Iteration';
                obj.TrainingProgress.ax1.YLim = [0 100];
                obj.TrainingProgress.ax1.XGrid = 'on';
                obj.TrainingProgress.ax1.YGrid = 'on';
                
                obj.TrainingProgress.ax2 = uiaxes('Parent',obj.TrainingProgress.hFig,...
                    'Units','pixels',...
                    'Position', [20, 30, 560, 240]);
                obj.TrainingProgress.hP2 = plot(obj.TrainingProgress.ax2, 0, 0, '-', 0, 0, '-o');
                obj.TrainingProgress.hP2(2).MarkerSize = 4;
                obj.TrainingProgress.hP2(2).MarkerFaceColor = 'r';
                obj.TrainingProgress.ax2.YLabel.String = 'Loss';
                obj.TrainingProgress.ax2.XLabel.String = 'Iteration';
                obj.TrainingProgress.ax2.YLim = [0 1];
                obj.TrainingProgress.ax2.XGrid = 'on';
                obj.TrainingProgress.ax2.YGrid = 'on';
                
                legend(obj.TrainingProgress.ax2, 'Training', 'Validation');
                obj.TrainingProgress.stopTraining = false;
                
                obj.TrainingProgress.t1 = uilabel('Parent', obj.TrainingProgress.hFig, ...
                    'Text', 'Training progress', 'FontSize', 14, 'FontWeight', 'bold',...
                    'Position', [250, 540, 300, 50]);
                
                obj.TrainingProgress.hPanel = uipanel(obj.TrainingProgress.hFig, ...
                    'Title','Info',...
                    'Position',[588 64 205 520]);
                
                obj.TrainingProgress.tp1 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', 'Training time', 'FontSize', 12, 'FontWeight', 'bold',...
                    'Position', [8, 475, 200, 15]);
                
                obj.TrainingProgress.tp2 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', sprintf('Start time: %s', datetime(now,'ConvertFrom','datenum')), ...
                    'FontSize', 12, ...
                    'Position', [8, 455, 200, 15]);
                
                obj.TrainingProgress.tp3 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', 'Elapsed time: -', 'FontSize', 12, ...
                    'Position', [8, 435, 200, 15]);
                
                obj.TrainingProgress.tp4 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', 'Time to go: -', 'FontSize', 12, ...
                    'Position', [8, 415, 200, 15]);
                
                obj.TrainingProgress.tp5 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', 'Training cycle', 'FontSize', 12, 'FontWeight', 'bold',...
                    'Position', [8, 385, 200, 15]);
                
                obj.TrainingProgress.tp6 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', 'Epoch: -', 'FontSize', 12, ...
                    'Position', [8, 365, 200, 15]);
                
                obj.TrainingProgress.tp7 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', sprintf('Iterations per epoch: %d', obj.TrainingProgress.iterPerEpoch),...
                    'FontSize', 12, 'Position', [8, 345, 200, 15]);
                
                obj.TrainingProgress.tp8 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', sprintf('Maximum iterations: %d', obj.TrainingProgress.iterPerEpoch*obj.TrainingOpt.MaxEpochs),...
                    'FontSize', 12, 'Position', [8, 325, 200, 15]);
                
                obj.TrainingProgress.tp9 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', sprintf('Validation frequency: %d iter', obj.TrainingOpt.ValidationFrequency),...
                    'FontSize', 12, 'Position', [8, 305, 200, 15]);
                
                obj.TrainingProgress.tp10 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', sprintf('Learning rate schedule: %s', obj.TrainingOpt.LearnRateSchedule),...
                    'FontSize', 12, 'Position', [8, 285, 200, 15]);
                
                obj.TrainingProgress.tp11 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', sprintf('Initial learning rate: %.4f', obj.TrainingOpt.InitialLearnRate),...
                    'FontSize', 12, 'Position', [8, 265, 200, 15]);
                
                obj.TrainingProgress.tp12 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', 'Validation accuracy: - %',...
                    'FontSize', 12, 'Position', [8, 230, 200, 15]);
                
                obj.TrainingProgress.tp13 = uilabel('Parent', obj.TrainingProgress.hPanel, ...
                    'Text', 'Validation loss: - ',...
                    'FontSize', 12, 'Position', [8, 210, 200, 15]);
                
                % Create a push button
                obj.TrainingProgress.hStop = uibutton(obj.TrainingProgress.hFig, 'push',...
                    'Position', [680, 30, 100, 22],...
                    'Text', 'Stop', ...
                    'ButtonPushedFcn', @obj.stopTrainingCallback);
                
            else
                if obj.TrainingProgress.stopTraining == true % stop training
                    result = true;
                    return;
                end
                
                % draw plot for eath 5th iteration or for validation loss
                % check
                if mod(ProgressStruct.Iteration, 5) ~= 1 && isempty(ProgressStruct.ValidationLoss); return; end
                
                obj.TrainingProgress.TrainXvec(obj.TrainingProgress.TrainXvecIndex) = ProgressStruct.Iteration;
                obj.TrainingProgress.TrainLoss(obj.TrainingProgress.TrainXvecIndex) = ProgressStruct.TrainingLoss;
                obj.TrainingProgress.TrainAccuracy(obj.TrainingProgress.TrainXvecIndex) = ProgressStruct.TrainingAccuracy;
                obj.TrainingProgress.TrainXvecIndex = obj.TrainingProgress.TrainXvecIndex + 1;
                
                obj.TrainingProgress.hP1(1).XData = obj.TrainingProgress.TrainXvec(1:obj.TrainingProgress.TrainXvecIndex-1);
                obj.TrainingProgress.hP1(1).YData = obj.TrainingProgress.TrainAccuracy(1:obj.TrainingProgress.TrainXvecIndex-1);
                obj.TrainingProgress.hP2(1).XData = obj.TrainingProgress.TrainXvec(1:obj.TrainingProgress.TrainXvecIndex-1);
                obj.TrainingProgress.hP2(1).YData = obj.TrainingProgress.TrainLoss(1:obj.TrainingProgress.TrainXvecIndex-1);
                
                obj.TrainingProgress.tp3.Text = sprintf('Elapsed time: %.0f h %.0f min %.2d sec', floor(ProgressStruct.TimeSinceStart/3600), floor(mod(round(ProgressStruct.TimeSinceStart),3600)/60), mod(round(ProgressStruct.TimeSinceStart),60));
                timerValue = ProgressStruct.TimeSinceStart/ProgressStruct.Iteration*(obj.TrainingProgress.maxNoIter-ProgressStruct.Iteration);
                obj.TrainingProgress.tp4.Text = sprintf('Time to go: ~%.0f h %.0f min %.2d sec', floor(timerValue/3600), floor(mod(round(timerValue),3600)/60), mod(round(timerValue),60));
                obj.TrainingProgress.tp6.Text = sprintf('Epoch: %d of %d', ProgressStruct.Epoch, obj.TrainingOpt.MaxEpochs);
                                        
                if ~isempty(ProgressStruct.ValidationLoss)
                    obj.TrainingProgress.ValidationXvec(obj.TrainingProgress.ValidationXvecIndex) = ProgressStruct.Iteration;
                    obj.TrainingProgress.ValidationLoss(obj.TrainingProgress.ValidationXvecIndex) = ProgressStruct.ValidationLoss;
                    obj.TrainingProgress.ValidationAccuracy(obj.TrainingProgress.ValidationXvecIndex) = ProgressStruct.ValidationAccuracy;
                    obj.TrainingProgress.ValidationXvecIndex = obj.TrainingProgress.ValidationXvecIndex + 1;
                    
                    obj.TrainingProgress.hP1(2).XData = obj.TrainingProgress.ValidationXvec(1:obj.TrainingProgress.ValidationXvecIndex-1);
                    obj.TrainingProgress.hP1(2).YData = obj.TrainingProgress.ValidationAccuracy(1:obj.TrainingProgress.ValidationXvecIndex-1);
                    obj.TrainingProgress.hP2(2).XData = obj.TrainingProgress.ValidationXvec(1:obj.TrainingProgress.ValidationXvecIndex-1);
                    obj.TrainingProgress.hP2(2).YData = obj.TrainingProgress.ValidationLoss(1:obj.TrainingProgress.ValidationXvecIndex-1);
                    
                    obj.TrainingProgress.tp12.Text = ...
                        sprintf('Validation accuracy: %.2f %%', ProgressStruct.ValidationAccuracy);
                
                    obj.TrainingProgress.tp13.Text = ...
                        sprintf('Validation loss: %.4f', ProgressStruct.ValidationLoss);
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
                    
                    %obj.TrainingProgress.TrainXvec(2:maxPoints/2) = ...
                    %    (obj.TrainingProgress.TrainXvec(2:2:maxPoints-1) + obj.TrainingProgress.TrainXvec(3:2:maxPoints)) / 2;
                    %obj.TrainingProgress.TrainLoss(2:maxPoints/2) = ...
                    %    (obj.TrainingProgress.TrainLoss(2:2:maxPoints-1) + obj.TrainingProgress.TrainLoss(3:2:maxPoints)) / 2;
                    %obj.TrainingProgress.TrainAccuracy(2:maxPoints/2) = ...
                    %    (obj.TrainingProgress.TrainAccuracy(2:2:maxPoints-1) + obj.TrainingProgress.TrainAccuracy(3:2:maxPoints)) / 2;        
                end
                
                if obj.TrainingProgress.ValidationXvecIndex > maxPoints
                    obj.TrainingProgress.ValidationXvecIndex = maxPoints/2+1;
                    linvec = linspace(1, obj.TrainingProgress.ValidationXvec(maxPoints), maxPoints/2);
                    obj.TrainingProgress.ValidationLoss(1:maxPoints/2) = ...
                        interp1(obj.TrainingProgress.ValidationXvec, obj.TrainingProgress.ValidationLoss, linvec);
                    obj.TrainingProgress.ValidationAccuracy(1:maxPoints/2) = ...
                        interp1(obj.TrainingProgress.ValidationXvec, obj.TrainingProgress.ValidationAccuracy, linvec);
                    obj.TrainingProgress.ValidationXvec(1:maxPoints/2) = linvec;
                    
                    %obj.TrainingProgress.ValidationXvec(2:maxPoints/2) = ...
                    %    (obj.TrainingProgress.ValidationXvec(2:2:maxPoints-1) + obj.TrainingProgress.ValidationXvec(3:2:maxPoints)) / 2;        
                    obj.TrainingProgress.ValidationLoss(2:maxPoints/2) = ...
                        (obj.TrainingProgress.ValidationLoss(2:2:maxPoints-1) + obj.TrainingProgress.ValidationLoss(3:2:maxPoints)) / 2;
                    obj.TrainingProgress.ValidationAccuracy(2:maxPoints/2) = ...
                        (obj.TrainingProgress.ValidationAccuracy(2:2:maxPoints-1) + obj.TrainingProgress.ValidationAccuracy(3:2:maxPoints)) / 2;        
                end
            end
        end
        
        function StartPrediction(obj)
            % function StartPrediction(obj)
            % predict datasets
            
            answer = questdlg(sprintf('Have images for prediction were preprocessed?\n\nIf not, please switch to the Directories and Preprocessing tab and preprocess images for prediction'), ...
                'Preprocessing', 'Yes', 'No', 'Yes');
            if strcmp(answer, 'No'); return; end
            
            if obj.BatchOpt.showWaitbar; pwb = PoolWaitbar(1, 'Creating image store for prediction...', [], 'Predicting dataset'); end
            
            % creating output directories
            warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsScores'));
            mkdir(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels'));

            %if strcmp(obj.BatchOpt.PreprocessingMode{1}, 'Already preprocessed')
            imgDS = imageDatastore(fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages'), ...
                    'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
            %else
            %    imgDS = imageDatastore(obj.BatchOpt.OriginalPredictionImagesDir, 'FileExtensions', lower(['.' obj.BatchOpt.ImageFilenameExtension{1}]), ...
            %        'ReadFcn', @mibDeepController.loadAndTransposeImages);    
            %end
            
            if obj.BatchOpt.showWaitbar;  pwb.updateText('Loading network...'); end
            % loading: 'net', 'TrainingOptStruct', 'classNames',
            % 'inputPatchSize', 'outputPatchSize', 'BatchOpt' variables
            load(obj.BatchOpt.NetworkFilename, '-mat');     
            
            numClasses = numel(classNames); %#ok<USENS>
            modelMaterialColors = classColors;  %#ok<PROP> % loaded from network file
            
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
            Unet2DSwitch = 0;   % switch that defines 2D/3D unet; used for the waitbar
            if obj.BatchOpt.showWaitbar
                pwb.updateText(sprintf('Starting prediction\nPlease wait...')); 
                if ~strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D')
                    pwb.increaseMaxNumberOfIterations(noFiles);
                    Unet2DSwitch = 1;
                end
            end
            id = 1;     % indices of files
            patchCount = 1; % counter of processed patches
            %% TO DO:
            % 1. check situation, when the dataset for prediction is
            % smaller that then dataset for training: 2D and 3D cases
            % 2. check different padvalue in the code below: volPadded = padarray (vol, padSize, 0, 'post');
            % 43. add elastic deformations to data augmentation as https://stackoverflow.com/questions/39308301/expand-mnist-elastic-deformations-matlab
            % For Masks try to use <undefined> option of categorial, i.e.
            % that is not defined as pixelLabelID see more in isundefined
            % function, it should be compatible with crossentropy loss at
            % least.
            % 
            
            nDims = 3;  % number of dimensions for data, 2 or 3
            if ~strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D'); Unet2DSwitch = 1;  nDims = 2; end
            
            while hasdata(imgDS)
                vol = read(imgDS);
                if Unet2DSwitch     % 2D U-net
                    vol = permute(vol, [1 2 4 3]);  % convert to [height, width, depth, color]
                end
                volSize = size(vol, (1:3));
                [height, width, depth, color] = size(vol);
                [~, fn] = fileparts(imgDS.Files{id});
                
                if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'same')     % same
                    if obj.BatchOpt.P_OverlappingTiles == false
                        % pad image to have dimensions as multiples of patchSize
                        % see more in
                        % \\ad.helsinki.fi\home\i\ibelev\Documents\MATLAB\Examples\R2019b\deeplearning_shared\SemanticSegOfMultispectralImagesUsingDeepLearningExample\segmentImage.m
                        padSize(1) = inputPatchSize(1) - mod(height, inputPatchSize(1));
                        padSize(2) = inputPatchSize(2) - mod(width, inputPatchSize(2));
                        padSize(3) = inputPatchSize(3) - mod(depth, inputPatchSize(3));
                        if Unet2DSwitch
                            padSize(3) = 0;
                        end
                        volPadded = padarray(vol, padSize, 0, 'post');

                        [heightPad, widthPad, depthPad, colorPad] = size(volPadded);

                        outputLabels = zeros([heightPad, widthPad, depthPad], 'uint8');
                        scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'uint8');
                    
                        if obj.BatchOpt.showWaitbar
                            if Unet2DSwitch == 0    % 3D Unet
                                iterNo = numel(1:inputPatchSize(3):depthPad) * ...
                                    numel(1:inputPatchSize(2):widthPad) * ...
                                    numel(1:inputPatchSize(1):heightPad);
                                pwb.increaseMaxNumberOfIterations(iterNo);
                            end
                        end
                        
                        for k = 1:inputPatchSize(3):depthPad
                            for j = 1:inputPatchSize(2):widthPad
                                for i = 1:inputPatchSize(1):heightPad
                                    patch = volPadded( i:i+inputPatchSize(1)-1,...
                                        j:j+inputPatchSize(2)-1,...
                                        k:k+inputPatchSize(3)-1,:);
                                    [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, 'OutputType', 'uint8');
                                    
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
                                    scoreImg(i:i+outputPatchSize(1)-1, ...
                                        j:j+outputPatchSize(2)-1, ...
                                        k:k+outputPatchSize(3)-1,:) = scoreBlock*255;
                                    if obj.BatchOpt.showWaitbar && Unet2DSwitch==0
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
                        scoreImg = scoreImg(1:height, 1:width, 1:depth, :);
                    else        % the section below is for obj.BatchOpt.P_OverlappingTiles == true
                        % pad the image to include extended areas due to
                        % the overlapping strategy
                        padShift = (obj.BatchOpt.T_FilterSize{1}-1)*obj.BatchOpt.T_EncoderDepth{1};
                        if Unet2DSwitch
                            padShiftZ = 1;
                        else
                            padShiftZ = padShift;
                        end
                        padSize  = repmat(padShift, [1 nDims]);
                        volPadded = padarray(vol, padSize, 0, 'both');
                        
                        % pad image to have dimensions as multiples of patchSize
                        [heightPad, widthPad, depthPad, colorPad] = size(volPadded);
                        outputPatchSize = max(inputPatchSize-padShift*2, 1);  % recompute output patch size, it is smaller than input patch size
                        
                        padSize(1) = ceil(heightPad/outputPatchSize(1))*outputPatchSize(1) + padShift*2 - heightPad;
                        padSize(2) = ceil(widthPad/outputPatchSize(2))*outputPatchSize(2) + padShift*2 - widthPad;
                        padSize(3) = ceil(depthPad/outputPatchSize(3))*outputPatchSize(3) + padShift*2 - depthPad;
                        if Unet2DSwitch; padSize(3) = 0; end
                        volPadded = padarray(volPadded, padSize, 0, 'post');

                        [heightPad, widthPad, depthPad, colorPad] = size(volPadded);
                        outputLabels = zeros([heightPad, widthPad, depthPad], 'uint8');
                        scoreImg = zeros([heightPad, widthPad, depthPad, numClasses], 'uint8');
                        
                        if obj.BatchOpt.showWaitbar
                            if Unet2DSwitch == 0    % 3D Unet
                                iterNo = numel(1:outputPatchSize(3):depthPad-outputPatchSize(3)+1) * ...
                                    numel(1:outputPatchSize(2):widthPad-outputPatchSize(2)+1) * ...
                                    numel(1:outputPatchSize(1):heightPad-outputPatchSize(1)+1);
                                pwb.increaseMaxNumberOfIterations(iterNo);
                            end
                        end
                        
                        for k = 1:outputPatchSize(3):depthPad-outputPatchSize(3)+1
                            for j = 1:outputPatchSize(2):widthPad-outputPatchSize(2)+1
                                for i = 1:outputPatchSize(1):heightPad-outputPatchSize(1)+1
                                    patch = volPadded( i:i+inputPatchSize(1)-1,...
                                        j:j+inputPatchSize(2)-1,...
                                        k:k+inputPatchSize(3)-1,:);
                                    [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, 'OutputType', 'uint8');
                                    x1 = i + padShift - 1;
                                    y1 = j + padShift - 1;
                                    z1 = min(k + padShift - 1, depthPad);
                                    
                                    outputLabels(x1:x1+outputPatchSize(1)-1, ...
                                            y1:y1+outputPatchSize(2)-1, ...
                                            z1:z1+outputPatchSize(3)-1) = patchSeg(padShift:padShift+outputPatchSize(1)-1, ...
                                            padShift:padShift+outputPatchSize(2)-1, ...
                                            padShiftZ:padShiftZ+outputPatchSize(3)-1);
                                    
                                    if Unet2DSwitch == 1    % 2D Unet
                                        scoreImg(x1:x1+outputPatchSize(1)-1, ...
                                            y1:y1+outputPatchSize(2)-1, ...
                                            z1:z1+outputPatchSize(3)-1,:) = permute(scoreBlock(padShift:padShift+outputPatchSize(1)-1, ...
                                            padShift:padShift+outputPatchSize(2)-1, ...
                                            :), [1 2 4 3])*255;
                                    else                    % 3D Unet
                                        scoreImg(x1:x1+outputPatchSize(1)-1, ...
                                            y1:y1+outputPatchSize(2)-1, ...
                                            z1:z1+outputPatchSize(3)-1,:) = scoreBlock(padShift:padShift+outputPatchSize(1)-1, ...
                                            padShift:padShift+outputPatchSize(2)-1, ...
                                            padShiftZ:padShiftZ+outputPatchSize(3)-1,:)*255;
                                    end
                                    if obj.BatchOpt.showWaitbar && Unet2DSwitch==0
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
                        if Unet2DSwitch
                            outputLabels = outputLabels(padShift+1:padShift+height, padShift+1:padShift+width, :);
                            scoreImg = scoreImg(padShift+1:padShift+height, padShift+1:padShift+width, :, :);
                        else
                            outputLabels = outputLabels(padShift+1:padShift+height, padShift+1:padShift+width, padShiftZ+1:padShiftZ+depth);
                            scoreImg = scoreImg(padShift+1:padShift+height, padShift+1:padShift+width, padShiftZ+1:padShiftZ+depth, :);
                        end
                    end
                else    % the section below is for obj.BatchOpt.T_ConvolutionPadding{1} == 'valid'
                    padSizePre  = (inputPatchSize(1:3)-outputPatchSize(1:3))/2;
                    padSizePost = (inputPatchSize(1:3)-outputPatchSize(1:3))/2 + (outputPatchSize(1:3)-mod(volSize,outputPatchSize(1:3)));
                    if Unet2DSwitch
                        padSizePre(3) = 0;
                        padSizePost(3) = 0;
                    end
                    volPadded = padarray(vol, padSizePre, 'symmetric', 'pre');
                    volPadded = padarray(volPadded, padSizePost, 'symmetric', 'post');
                    
                    [heightPad, widthPad, depthPad, colorPad] = size(volPadded);
                    
                    outputLabels = zeros([height, width, depth], 'uint8');
                    scoreImg = zeros([height, width, depth, numClasses], 'uint8');
                    
                    if obj.BatchOpt.showWaitbar
                        if Unet2DSwitch == 0    % 3D Unet
                            iterNo = numel(1:outputPatchSize(3):depthPad-inputPatchSize(3)+1) * ...
                                numel(1:outputPatchSize(2):widthPad-inputPatchSize(2)+1) * ...
                                numel(1:outputPatchSize(1):heightPad-inputPatchSize(1)+1);
                            pwb.increaseMaxNumberOfIterations(iterNo);
                        end
                    end
                    
                    % Overlap-tile strategy for segmentation of volumes.
                    for k = 1:outputPatchSize(3):depthPad-inputPatchSize(3)+1
                        for j = 1:outputPatchSize(2):widthPad-inputPatchSize(2)+1
                            for i = 1:outputPatchSize(1):heightPad-inputPatchSize(1)+1
                                patch = volPadded( i:i+inputPatchSize(1)-1,...
                                    j:j+inputPatchSize(2)-1,...
                                    k:k+inputPatchSize(3)-1,:);
                                [patchSeg, ~, scoreBlock] = semanticseg(squeeze(patch), net, 'OutputType', 'uint8');
                                
                                outputLabels(i:i+outputPatchSize(1)-1, ...
                                             j:j+outputPatchSize(2)-1, ...
                                             k:k+outputPatchSize(3)-1) = patchSeg;
                                scoreImg(i:i+outputPatchSize(1)-1, ...
                                         j:j+outputPatchSize(2)-1, ...
                                         k:k+outputPatchSize(3)-1,:) = scoreBlock*255;
                                if obj.BatchOpt.showWaitbar && Unet2DSwitch==0
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
                    scoreImg = scoreImg(1:height, 1:width, 1:depth, :);
                end
                if obj.BatchOpt.showWaitbar && Unet2DSwitch==0; pwb.updateText('Saving results...'); end
                
                % Save results
                outputLabels = outputLabels - 1;    % remove the first "exterior" class
                
                [outputDir, fn] = fileparts(imgDS.Files{id});
                filename = fullfile(fullfile(outputDir, 'ResultsModels'), ['Labels_' fn '.model']);
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
                filename = fullfile(outputDir, 'ResultsScores',['Score_' fn '.am']);
                scoreImg = permute(scoreImg, [1 2 4 3]);    % convert to [height, width, color, depth]
                
                amiraOpt.overwrite = 1;
                amiraOpt.showWaitbar = 0;
                bitmap2amiraMesh(filename, scoreImg, [], amiraOpt);
                
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
            
            imgDir = fullfile(obj.BatchOpt.OriginalPredictionImagesDir);
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
            BatchOptIn1.UseBioFormats = false;
            obj.mibModel.myPath = imgDir;
            obj.mibController.mibFilesListbox_cm_Callback([], BatchOptIn1);     % load images
            obj.mibModel.loadModel([], BatchOptIn2);  % load models
        end
        
        function EvaluateSegmentation(obj)
            % function EvaluateSegmentation(obj)
            % evaluate segmentation results by comparing predicted models
            % with the ground truth models
            global mibPath;
            
            if strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D')
                truthDir = fullfile(obj.BatchOpt.OriginalPredictionImagesDir);
                truthList = dir(fullfile(truthDir, '*.model'));
            else
                truthDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'GroundTruthLabels');
                truthList = dir(fullfile(truthDir, '*.mat'));
            end
            
            predictionDir = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels');
            predictionList = dir(fullfile(predictionDir, '*.model'));
            
            if isempty(truthList) || isempty(predictionList)
                errordlg(sprintf('!!! Error !!!\n\nModels were not found in\n%s\n\n%s\n\nPlease update the Directory prediction and resulting images fields of the Directories and Preprocessing tab!', truthDir, predictionDir), 'Missing files');
                return;
            end
        
%             obj.mibModel.preferences.deep.Metrics.Accuracy = true;  % parameters for metrics evaluation
%             obj.mibModel.preferences.deep.Metrics.BFscore = false;
%             obj.mibModel.preferences.deep.Metrics.GlobalAccuracy = true;
%             obj.mibModel.preferences.deep.Metrics.IOU = true;
%             obj.mibModel.preferences.deep.Metrics.WeightedIOU = true;
            
            prompts = { 'Accuracy: the percentage of correctly identified pixels for each class';...
                        'bfscore: the boundary F1 (BF) contour matching score indicates how well the predicted boundary of each class aligns with the true boundary';...
                        'Global Accuracy: the ratio of correctly classified pixels, regardless of class, to the total number of pixels'; ...
                        'IOU (Jaccard similarity coefficient): Intersection over union, a statistical accuracy measurement that penalizes false positives'; ...
                        'Weighted IOU: average IoU of each class, weighted by the number of pixels in that class'; ...
                        };
            defAns = {obj.mibModel.preferences.deep.Metrics.Accuracy; ...
                      obj.mibModel.preferences.deep.Metrics.BFscore; ...
                      obj.mibModel.preferences.deep.Metrics.GlobalAccuracy; ...
                      obj.mibModel.preferences.deep.Metrics.IOU; ...
                      obj.mibModel.preferences.deep.Metrics.WeightedIOU ...
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
            
            obj.mibModel.preferences.deep.Metrics.Accuracy = logical(answer{1});
            obj.mibModel.preferences.deep.Metrics.BFscore = logical(answer{2});
            obj.mibModel.preferences.deep.Metrics.GlobalAccuracy = logical(answer{3});
            obj.mibModel.preferences.deep.Metrics.IOU = logical(answer{4});
            obj.mibModel.preferences.deep.Metrics.WeightedIOU = logical(answer{5});
            
            metricsList = {};
            if obj.mibModel.preferences.deep.Metrics.Accuracy;          metricsList = [metricsList, {'accuracy'}]; end
            if obj.mibModel.preferences.deep.Metrics.BFscore;           metricsList = [metricsList, {'bfscore'}]; end
            if obj.mibModel.preferences.deep.Metrics.GlobalAccuracy;    metricsList = [metricsList, {'global-accuracy'}]; end
            if obj.mibModel.preferences.deep.Metrics.IOU;               metricsList = [metricsList, {'iou'}]; end
            if obj.mibModel.preferences.deep.Metrics.WeightedIOU;       metricsList = [metricsList, {'weighted-iou'}]; end
            if isempty(metricsList); return; end
           
            try
                if strcmp(obj.BatchOpt.Architecture{1}(1:2), '3D')  % take only the first file for 3D case
                    modelFn = fullfile(truthList(1).folder, truthList(1).name);
                    res = load(modelFn, '-mat', 'modelMaterialNames');
                    classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                    pixelLabelID = 0:numel(classNames)-1;
                    dsTruth = pixelLabelDatastore(truthDir, classNames, pixelLabelID, ...
                        'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                else
                    modelFn = fullfile(predictionList(1).folder, predictionList(1).name);
                    res = load(modelFn, '-mat', 'modelMaterialNames');
                    classNames = [{'Exterior'}; res.modelMaterialNames];    % add Exterior
                    pixelLabelID = 0:numel(classNames)-1;
                    dsTruth = pixelLabelDatastore(truthDir, classNames, pixelLabelID, ...
                        'FileExtensions', '.mat', 'ReadFcn', @mibDeepController.matlabFileRead);
                end
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s\n\nCheck model:\n%s', err.identifier, err.message, modelFn), 'Wrong class name');
                return;
            end
            dsResults = pixelLabelDatastore(predictionDir, classNames, pixelLabelID, ...
                    'FileExtensions', '.model', 'ReadFcn', @mibDeepController.readModel);
                
            wbar = waitbar(0, sprintf('Starting evaluation\nit may take a while...'), 'Name', 'Evaluate segmentation');
            tic
            ssm = evaluateSemanticSegmentation(dsResults, dsTruth, 'Metrics', metricsList);
            waitbar(1, wbar);
            delete(wbar);
            toc
            
            normConfMatData = ssm.NormalizedConfusionMatrix.Variables;
            figure
            h = heatmap(classNames,classNames,100*normConfMatData);
            h.XLabel = 'Predicted Class';
            h.YLabel = 'True Class';
            h.Title = 'Normalized Confusion Matrix (%)';
            
            % display results
            metricName = ssm.ImageMetrics.Properties.VariableNames;
            metricValue = table2array(ssm.ImageMetrics);
            s = sprintf('Evaluation results\nfor details press the Help button and follow to the Metrics section\n\n');
            s = sprintf('%sGlobalAccuracy: ratio of correctly classified pixels to total pixels, regardless of class\n', s);
            s = sprintf('%sMeanAccuracy: ratio of correctly classified pixels to total pixels, averaged over all classes in the image\n', s);
            s = sprintf('%sMeanIoU: (Jaccard similarity coefficient) average intersection over union (IoU) of all classes in the image\n', s);
            s = sprintf('%sWeightedIoU: average IoU of all classes in the image, weighted by the number of pixels in each class\n', s);
            s = sprintf('%sMeanBFScore: average boundary F1 (BF) score of each class in the image\n\n', s);

            for i=1:numel(metricName)
                s = sprintf('%s%s: %f            ', s, metricName{i}, metricValue(i));
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
            prompts = {'Export to Matlab'; 'Save as Matlab file'; 'Save as Excel file'};
            defAns = {false; false; false};
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Evaluation results', options);
            if isempty(answer); return; end
            
            if answer{1}    % export to Matlab
                assignin('base','ssm', ssm);
                fprintf('A variable "ssm" was created in Matlab\n');
            end
            if answer{2}    % save in Matlab format
                fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationResults.mat');
                save(fn, 'ssm');
                fprintf('Evaluation results were saved to:\n%s\n', fn);
            end
            if answer{3}    % save in Excel format
                wbar = waitbar(0, sprintf('Saving to Excel\nPlease wait...'), 'Name', 'Export');
                fn = fullfile(obj.BatchOpt.ResultingImagesDir, 'PredictionImages', 'ResultsModels', 'EvaluationResults.xls');
                writetable(ssm.ClassMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'ClassMetrics');
                waitbar(0.2, wbar);
                writetable(ssm.ImageMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'ImageMetrics');
                waitbar(0.4, wbar);
                writetable(ssm.DataSetMetrics, fn, 'FileType', 'spreadsheet', 'Sheet', 'DataSetMetrics');
                waitbar(0.6, wbar);
                writetable(ssm.ConfusionMatrix, fn, 'FileType', 'spreadsheet', 'Sheet', 'ConfusionMatrix');
                waitbar(0.8, wbar);
                writetable(ssm.NormalizedConfusionMatrix, fn, 'FileType', 'spreadsheet', 'Sheet', 'NormalizedConfusionMatrix');
                waitbar(1, wbar);
                fprintf('Evaluation results were saved to:\n%s\n', fn);
                delete(wbar);
            end
   
        end
        
        function ExploreActivations(obj)
            obj.startController('mibDeepActivationsController', obj);
        end
        
        
    end
end