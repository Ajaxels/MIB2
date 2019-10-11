classdef mibAlignmentController < handle
    % classdef mibAlignmentController < handle
    % controller class for alignment of datasets
    
    % Copyright (C) 25.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    %
    % Updates
    % 10.06.2019 updated for the batch mode
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        files
        % files structure from the getImageMetadata
        meta
        % meta containers.Map from the getImageMetadata
        pathstr
        % current path
        pixSize
        % pixSize structure from the getImageMetadata
        shiftsX
        % vector with X-shifts or tformMatrix
        shiftsY
        % vector with Y-shifts or rbMatrix
        varname
        % variable for import
        automaticOptions
        % a structure with additional options used during automatic
        % alignment with feature detectors
        % .imgWidthForAnalysis = round(Width/4);  % size of the image used to detect features, decrease to make it faster, but compromising the precision
        % .rotationInvariance = true;  % Rotation invariance flag, specified a logical scalar; When you set this property to true, the orientation of the feature vectors are not estimated and the feature orientation is set to pi/2. 
        % .detectSURFFeatures.MetricThreshold = 1000; % non-negative scalar, strongest feature threshold; to return more blobs, decrease the value of this threshold
        % .detectSURFFeatures.NumOctaves = 3; % scalar, greater than or equal to 1, increase this value to detect larger blobs. Recommended values are between 1 and 4.
        % .detectSURFFeatures.NumScaleLevels = 4; % integer scalar, greater than or equal to 3; Number of scale levels per octave to compute, increase this number to detect more blobs at finer scale increments. Recommended values are between 3 and 6.
        % .detectMSERFeatures.ThresholdDelta = 2; % percent numeric value; step size between intensity threshold levels, decrease this value to return more regions. Typical values range from 0.8 to 4.
        % .detectMSERFeatures.RegionAreaRange = [30 14000]; % two-element vector, size of the region in pixels, allows the selection of regions containing pixels between the provided range
        % .detectMSERFeatures.MaxAreaVariation = 0.25; % positive scalar, maximum area variation between extremal regions at varying intensity thresholds; Increasing this value returns a greater number of regions, but they may be less stable. Stable regions are very similar in size over varying intensity thresholds. Typical values range from 0.1 to 1.0.
        % .detectHarrisFeatures.MinQuality = 0.01; % between [0 1], minimum accepted quality of corners, larger values can be used to remove erroneous corners
        % .detectHarrisFeatures.FilterSize = 5; % an odd integer value in the range [3, min(size(I))]; Gaussian filter dimension.
        % .detectBRISKFeatures.MinContrast = 0.2; % a scalar in the range (0 1); Minimum intensity difference between a corner and its surrounding region, Increase this value to reduce the number of detected corners.
        % .detectBRISKFeatures.MinQuality = 0.1; % a scalar value in the range [0,1], Minimum accepted quality of corners, Increase this value to remove erroneous corners.
        % .detectBRISKFeatures.NumOctaves = 4; % an integer scalar, greater than or equal to 0; Number of octaves to implement, Increase this value to detect larger blobs. Recommended values are between 1 and 4. When you set NumOctaves to 0, the function disables multiscale detection
        % .detectFASTFeatures.MinQuality = 0.1; % a scalar value in the range [0,1]; The minimum accepted quality of corners represents a fraction of the maximum corner metric value in the image. Larger values can be used to remove erroneous corners.
        % .detectFASTFeatures.MinContrast = 0.2; % a scalar value in the range (0,1), The minimum intensity represents a fraction of the maximum value of the image class. Increasing the value reduces the number of detected corners.
        % .detectMinEigenFeatures.MinQuality = 0.01; % a scalar value in the range [0,1], The minimum accepted quality of corners represents a fraction of the maximum corner metric value in the image. Larger values can be used to remove erroneous corners
        % .detectMinEigenFeatures.FilterSize = 5; % an odd integer value in the range [3, inf), The Gaussian filter smooths the gradient of the input image.
        % .detectORBFeatures.ScaleFactor = 1.2; % Scale factor for image decomposition, an integer greater than 1.
        % .detectORBFeatures.NumLevels = 8; % Number of decomposition levels, an integer greater than or equal to 1. Increase this value to extract keypoints from the image at more levels of decomposition.
        BatchOpt
        % a structure compatible with batch operation, see details in the contsructor
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function idx = findMatchingPairs(X1, X2)
            % find matching pairs for X1 from X2
            % X1[:, (x,y)]
            % X2[:, (x,y)]
            
            % % following code is equal to pdist2 function in the statistics toolbox
            % % such as: dist = pdist2(X1,X2);
            dist = zeros([size(X1,1) size(X2,1)]);
            for i=1:size(X1,1)
                for j=1:size(X2,1)
                    dist(i,j) = sqrt((X1(i,1)-X2(j,1))^2 + (X1(i,2)-X2(j,2))^2);
                end
            end
            
            % alternative fast method
            % DD = sqrt( bsxfun(@plus,sum(X1.^2,2),sum(X2.^2,2)') - 2*(X1*X2') );
            
            % following is an adaptation of a code by Gunther Struyf
            % http://stackoverflow.com/questions/12083467/find-the-nearest-point-pairs-between-two-sets-of-of-matrix
            N = size(X1,1);
            matchAtoB=NaN(N,1);
            X1b = X1;
            X2b = X2;
            for ii=1:N
                %dist(:,matchAtoB(1:ii-1))=Inf; % make sure that already picked points of B are not eligible to be new closest point
                %[~, matchAtoB(ii)]=min(dist(ii,:));
                dist(matchAtoB(1:ii-1),:)=Inf; % make sure that already picked points of B are not eligible to be new closest point
                %         for jj=1:N
                %             [~, minVec(jj)] = min(dist(:,jj));
                %         end
                [~, matchAtoB(ii)]=min(dist(:,ii));
                
                %         X2b(matchAtoB(1:ii-1),:)=Inf;
                %         goal = X1b(ii,:);
                %         r = bsxfun(@minus,X2b,goal);
                %         [~, matchAtoB(ii)] = min(hypot(r(:,1),r(:,2)));
            end
            matchBtoA = NaN(size(X2,1),1);
            matchBtoA(matchAtoB)=1:N;
            idx =  matchBtoA;   % indeces of the matching objects, i.e. STATS1(objId) =match= STATS2(idx(objId))
        end
        
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibAlignmentController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'alignment tool';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s is not yet available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            
            fn = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            [obj.pathstr, name, ext] = fileparts(fn);
            
            getDataOpt.blockModeSwitch = 0;
            [height, width, colors, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOpt);
            
            if isfield(obj.mibModel.sessionSettings, 'automaticAlignmentOptions') && isempty(obj.automaticOptions)
                obj.automaticOptions = obj.mibModel.sessionSettings.automaticAlignmentOptions;
            else
                obj.automaticOptions.imgWidthForAnalysis = round(width/4);    % size of the image used to detect features, decrease to make it faster, but compromising the precision
                obj.automaticOptions.rotationInvariance = true;  % Rotation invariance flag, specified a logical scalar; When you set this property to true, the orientation of the feature vectors are not estimated and the feature orientation is set to pi/2. 
                obj.automaticOptions.detectSURFFeatures.MetricThreshold = 1000; % non-negative scalar, strongest feature threshold; to return more blobs, decrease the value of this threshold
                obj.automaticOptions.detectSURFFeatures.NumOctaves = 3; % scalar, greater than or equal to 1, increase this value to detect larger blobs. Recommended values are between 1 and 4.
                obj.automaticOptions.detectSURFFeatures.NumScaleLevels = 4; % integer scalar, greater than or equal to 3; Number of scale levels per octave to compute, increase this number to detect more blobs at finer scale increments. Recommended values are between 3 and 6.
                obj.automaticOptions.detectMSERFeatures.ThresholdDelta = 2; % percent numeric value; step size between intensity threshold levels, decrease this value to return more regions. Typical values range from 0.8 to 4.
                obj.automaticOptions.detectMSERFeatures.RegionAreaRange = [30 14000]; % two-element vector, size of the region in pixels, allows the selection of regions containing pixels between the provided range
                obj.automaticOptions.detectMSERFeatures.MaxAreaVariation = 0.25; % positive scalar, maximum area variation between extremal regions at varying intensity thresholds; Increasing this value returns a greater number of regions, but they may be less stable. Stable regions are very similar in size over varying intensity thresholds. Typical values range from 0.1 to 1.0.
                obj.automaticOptions.detectHarrisFeatures.MinQuality = 0.01; % between [0 1], minimum accepted quality of corners, larger values can be used to remove erroneous corners
                obj.automaticOptions.detectHarrisFeatures.FilterSize = 5; % an odd integer value in the range [3, min(size(I))]; Gaussian filter dimension.
                obj.automaticOptions.detectBRISKFeatures.MinContrast = 0.2; % a scalar in the range (0 1); Minimum intensity difference between a corner and its surrounding region, Increase this value to reduce the number of detected corners.
                obj.automaticOptions.detectBRISKFeatures.MinQuality = 0.1; % a scalar value in the range [0,1], Minimum accepted quality of corners, Increase this value to remove erroneous corners.
                obj.automaticOptions.detectBRISKFeatures.NumOctaves = 4; % an integer scalar, greater than or equal to 0; Number of octaves to implement, Increase this value to detect larger blobs. Recommended values are between 1 and 4. When you set NumOctaves to 0, the function disables multiscale detection
                obj.automaticOptions.detectFASTFeatures.MinQuality = 0.1; % a scalar value in the range [0,1]; The minimum accepted quality of corners represents a fraction of the maximum corner metric value in the image. Larger values can be used to remove erroneous corners.
                obj.automaticOptions.detectFASTFeatures.MinContrast = 0.2; % a scalar value in the range (0,1), The minimum intensity represents a fraction of the maximum value of the image class. Increasing the value reduces the number of detected corners.
                obj.automaticOptions.detectMinEigenFeatures.MinQuality = 0.01; % a scalar value in the range [0,1], The minimum accepted quality of corners represents a fraction of the maximum corner metric value in the image. Larger values can be used to remove erroneous corners
                obj.automaticOptions.detectMinEigenFeatures.FilterSize = 5; % an odd integer value in the range [3, inf), The Gaussian filter smooths the gradient of the input image.
                obj.automaticOptions.detectORBFeatures.ScaleFactor = 1.2; % Scale factor for image decomposition, an integer greater than 1.
                obj.automaticOptions.detectORBFeatures.NumLevels = 8; % Number of decomposition levels, an integer greater than or equal to 1. Increase this value to extract keypoints from the image at more levels of decomposition.
            end
            
            obj.BatchOpt.Mode = {'CurrentDataset'};     % align the current dataset
            obj.BatchOpt.Mode{2} = {'CurrentDataset', 'TwoStacks'};  % only the single option is available for the batch mode so far
            obj.BatchOpt.SecondDatasetPath = fullfile(obj.mibModel.myPath, '*.tif');
            obj.BatchOpt.Algorithm = {'Drift correction'};   % algorithm for the alignment
            obj.BatchOpt.Algorithm{2} = {'Drift correction','Template matching','Automatic feature-based','Single landmark point',...
                                    'Landmarks, multi points', 'Three landmark points', 'Color channels, multi points'};
            obj.BatchOpt.CorrelateWith = {'Previous slice'};   % selection of slice for the correlation
            obj.BatchOpt.CorrelateWith{2} = {'Previous slice','First slice','Relative to'};                     
            obj.BatchOpt.CorrelateStep = '1';   % step for the "Relative to"
            obj.BatchOpt.ColorChannel = {'ColCh 1'};         % specify the color channel
            obj.BatchOpt.ColorChannel{2} = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{obj.mibModel.Id}.colors, 'UniformOutput', false);
            obj.BatchOpt.IntensityGradient = false;     % use intensity gradient instead of intensities for the correlation
            obj.BatchOpt.TransformationType = {'non reflective similarity'};   % transformation type for the automatic alignment
            obj.BatchOpt.TransformationType{2} = {'non reflective similarity','similarity','affine','projective'};                     
            obj.BatchOpt.TransformationMode = {'extended'};   % transformation mode, the cropped mode limits the area to the view of view of the first slice; extended includes complete images
            obj.BatchOpt.TransformationMode{2} = {'extended', 'cropped'};                     
            obj.BatchOpt.TransformationDegree = {'2 (min: 6 pnt)'};   % degree of the polynomial transformation degree
            obj.BatchOpt.TransformationDegree{2} = {'2 (min: 6 pnt)', '3 (min: 10 pnt)', '4 (min: 15 pnt)'};
            obj.BatchOpt.FeatureDetectorType = {'Blobs: Speeded-Up Robust Features (SURF) algorithm'};  % feature detector for automatic alignment
            obj.BatchOpt.FeatureDetectorType{2}  = {'Blobs: Speeded-Up Robust Features (SURF) algorithm', 'Regions: Maximally Stable Extremal Regions (MSER) algorithm', ...
                'Corners: Harris-Stephens algorithm', 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)', ...
                'Corners: Features from Accelerated Segment Test (FAST)', 'Corners: Minimum Eigenvalue algorithm', 'Oriented FAST and rotated BRIEF (ORB)'};
            obj.BatchOpt.BackgroundColor = {'White'};   % background color
            obj.BatchOpt.BackgroundColor{2} = {'White', 'Black', 'Mean', 'Custom'};                     
            obj.BatchOpt.CustomColorValue = '255';  % value for the custom color intensity
            obj.BatchOpt.Subarea = {'Full image'};
            obj.BatchOpt.Subarea{2} = {'Full image', 'Manually specified', 'Selection', 'Mask'};
            obj.BatchOpt.minX = num2str(floor(width/2)-floor(width/4));
            obj.BatchOpt.maxX = num2str(floor(width/2)+floor(width/4));
            obj.BatchOpt.minY = num2str(floor(height/2)-floor(height/4));
            obj.BatchOpt.maxY = num2str(floor(height/2)+floor(height/4));
            obj.BatchOpt.SubtractRunningAverage = false;    % for subtraction of the running average
            obj.BatchOpt.SubtractRunningAverageStep = '25';     % step for running average subtraction
            obj.BatchOpt.SubtractRunningAverageExcludePeaks = '0';  % exclude peaks higher than this value from running average calculation
            obj.BatchOpt.SubtractRunningAverageFixStretch = true;     % apply running average to fix stretching (automatic mode)
            obj.BatchOpt.SubtractRunningAverageFixShear = true;     % apply running average to fix shear (automatic mode)
            obj.BatchOpt.SaveShiftsToFile = false;
            obj.BatchOpt.TwoStacksAutomaticMode = true;     % automatic mode for TwoStacks mode
            obj.BatchOpt.TwoStacksShiftX = '0';     % shift X for the manual mode of the TwoStacks mode
            obj.BatchOpt.TwoStacksShiftY = '0';     % shift Y for the manual mode of the TwoStacks mode
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            
            % add section name and action name for the batch tool
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
            obj.BatchOpt.mibBatchActionName = 'Alignment tool';
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Mode = sprintf('So far it is only possible to align the current dataset using the batch mode');
            obj.BatchOpt.mibBatchTooltip.SecondDatasetPath = '[TwoStacks only] full path to a second dataset or directory with images including the file mask';
            obj.BatchOpt.mibBatchTooltip.Algorithm = sprintf('Algorithm used for the alignment');
            obj.BatchOpt.mibBatchTooltip.CorrelateWith = sprintf('Correlate slice with one of this options');
            obj.BatchOpt.mibBatchTooltip.CorrelateStep = sprintf('[CorrelateWith->Relative to]: correlate with slice N-slices away');
            obj.BatchOpt.mibBatchTooltip.ColorChannel = sprintf('Color channel used for the alignment');
            obj.BatchOpt.mibBatchTooltip.IntensityGradient = sprintf('Use intensity gradients instead of images, may help in some situations');
            obj.BatchOpt.mibBatchTooltip.TransformationType = sprintf('[Automatic feature based/Landmarks]:\ntransformation type for the images');
            obj.BatchOpt.mibBatchTooltip.TransformationMode = sprintf('[Automatic feature based/Landmarks]: "extended" ensures that all pixels will stay in the resulting image; "cropped" - crops results based on the first slice');
            obj.BatchOpt.mibBatchTooltip.TransformationDegree  = sprintf('[Automatic feature based/Polynomal]:\ndegree of the polynomial transformation');
            obj.BatchOpt.mibBatchTooltip.FeatureDetectorType = sprintf('[Automatic feature based]:\nmethod to detect local features for automatic alignment');
            obj.BatchOpt.mibBatchTooltip.BackgroundColor = sprintf('Background color for the alignment');
            obj.BatchOpt.mibBatchTooltip.CustomColorValue = sprintf('[BackgroundColor->Custom]:\ncustom color intensity for the background');
            obj.BatchOpt.mibBatchTooltip.Subarea = sprintf('Calculate shifts from the whole image, image subset or the masked area');
            obj.BatchOpt.mibBatchTooltip.minX = sprintf('[Subarea->Manually specified]:\nMin X point for the subset for calculation of shifts');
            obj.BatchOpt.mibBatchTooltip.maxX = sprintf('[Subarea->Manually specified]:\nMax X point for the subset for calculation of shifts');
            obj.BatchOpt.mibBatchTooltip.minY = sprintf('[Subarea->Manually specified]:\nMin Y point for the subset for calculation of shifts');
            obj.BatchOpt.mibBatchTooltip.maxY = sprintf('[Subarea->Manually specified]:\nMax Y point for the subset for calculation of shifts');
            obj.BatchOpt.mibBatchTooltip.SubtractRunningAverage = sprintf('[Drift correction/Automatic]:\nSubtract the running average from the shifts');
            obj.BatchOpt.mibBatchTooltip.SubtractRunningAverageStep = sprintf('[Drift correction/Automatic]:\nSize of the running average window');
            obj.BatchOpt.mibBatchTooltip.SubtractRunningAverageExcludePeaks = sprintf('Exclude peaks higher than this value from the running average calculation');
            obj.BatchOpt.mibBatchTooltip.SubtractRunningAverageFixStretch = sprintf('[Automatic]:\nFix stretch using the running average');
            obj.BatchOpt.mibBatchTooltip.SubtractRunningAverageFixShear = sprintf('[Automatic]:\nFix shear using the running average');
            obj.BatchOpt.mibBatchTooltip.SaveShiftsToFile = sprintf('Automatically save detected shifts to a file, the filename is generated automatically from the dataset name');
            obj.BatchOpt.mibBatchTooltip.TwoStacksAutomaticMode = '[TwoStacks only] automatic detection of shifts between the stacks for the TwoStacks mode';
            obj.BatchOpt.mibBatchTooltip.TwoStacksShiftX = '[TwoStacks only] manually provided X value for shifting the datasets';
            obj.BatchOpt.mibBatchTooltip.TwoStacksShiftY = '[TwoStacks only] manually provided X value for shifting the datasets';
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

            % add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{2};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 3rd parameter is required!')); 
                    end
                    return;
                end
                
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptInput);
                useBatchMode = 1;
                obj.continueBtn_Callback(useBatchMode);
                return;
            end
            
            guiName = 'mibAlignmentGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % update elements of GUI from the BatchMode
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            
            obj.varname = 'I';  % variable for import
            obj.updateWidgets();
            
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
        end
        
        function closeWindow(obj)
            obj.mibModel.sessionSettings.automaticAlignmentOptions = obj.automaticOptions;
            
            % closing mibAlignmentController  window
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
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % via the notify 'syncBatch' event
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
            % 
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        function updateBatchOptFromGUI(obj, hObject)
            % function updateBatchOptFromGUI(obj, hObject)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % hObject: a handle to a widget of GUI
            
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, hObject);
        end
        
        function updateWidgets(obj)
            if  obj.mibModel.I{obj.mibModel.Id}.time > 1
                msgbox(sprintf('Unfortunately the alignment tool is not compatible with 5D datasets!\nLet us know if you need it!\nhttp:\\mib.helsinki.fi'), 'Error!', 'error', 'modal');
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            
            [height, width, colors, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions();
            fn = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            [obj.pathstr, name, ext] = fileparts(fn);
            
            % define variables to store the shifts
            obj.shiftsX = [];
            obj.shiftsY = [];
            
            obj.meta = containers.Map;   % meta containers.Map from the getImageMetadata
            obj.files = struct();      % files structure from the getImageMetadata
            obj.pixSize = struct();    % pixSize structure from the getImageMetadata
            
            obj.View.handles.existingFnText1.String = obj.pathstr;
            obj.View.handles.existingFnText1.TooltipString = fn;
            obj.View.handles.existingFnText2.String = [name ext];
            obj.View.handles.existingFnText2.TooltipString = fn;
            str2 = sprintf('%d x %d x %d', width, height, depth);
            obj.View.handles.existingDimText.String = str2;
            obj.View.handles.existingPixText2.String = sprintf('Pixel size, %s:', obj.mibModel.I{obj.mibModel.Id}.pixSize.units);
            str2 = sprintf('%f x %f x %f', obj.mibModel.I{obj.mibModel.Id}.pixSize.x, obj.mibModel.I{obj.mibModel.Id}.pixSize.y, obj.mibModel.I{obj.mibModel.Id}.pixSize.z);
            obj.View.handles.existingPixText.String = str2;
            
            obj.View.handles.SecondDatasetPath.String = obj.pathstr;
            obj.View.handles.saveShiftsXYpath.String = fullfile(obj.pathstr, [name '_align.coefXY']);
            obj.View.handles.loadShiftsXYpath.String = fullfile(obj.pathstr, [name '_align.coefXY']);
            
            % fill default entries for subwindow
            obj.View.handles.minX.String = num2str(floor(width/2)-floor(width/4));
            obj.View.handles.minY.String = num2str(floor(height/2)-floor(height/4));
            obj.View.handles.maxX.String = num2str(floor(width/2)+floor(width/4));
            obj.View.handles.maxY.String = num2str(floor(height/2)+floor(height/4));
            
            % updating color channel popup
            obj.BatchOpt.ColorChannel{2} = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{obj.mibModel.Id}.colors, 'UniformOutput', false);
            obj.BatchOpt.ColorChannel{1} = obj.BatchOpt.ColorChannel{2}{max([1 obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel])};
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);    % update widgets from BatchOpt
            
            % update imgWidthForAnalysis
            %optionsGetData.blockModeSwitch = 0;
            %[~, Width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, optionsGetData);
            %obj.automaticOptions.imgWidthForAnalysis = round(Width/4);    % size of the image used to detect features, decrease to make it faster, but compromising the precision
        end
        
        
        function selectButton_Callback(obj)
            % function selectButton_Callback(obj)
            % --- Executes on button press in selectButton.
            
            startingPath = obj.View.handles.SecondDatasetPath.String;
            
            if obj.View.handles.dirRadio.Value
                newValue = uigetdir(startingPath, 'Select directory...');
                if newValue == 0; return; end
                newValue = [newValue filesep];  % add a slash to the end
                
                [obj.meta, obj.files, obj.pixSize, dimsXYZ] = obj.getMetaInfo(newValue);
                obj.View.handles.SecondDatasetPath.String = newValue;
                obj.View.handles.SecondDatasetPath.TooltipString = newValue;
                obj.BatchOpt.SecondDatasetPath = fullfile(newValue, '*.*');
            elseif obj.View.handles.fileRadio.Value
                [FileName, PathName] = uigetfile({'*.tif; *.am','(*.tif; *.am) TIF/AM Files';
                    '*.am','(*.am) Amira Mesh Files';
                    '*.tif','(*.tif) TIF Files';
                    '*.*','All Files'}, 'Select file...', startingPath);
                if FileName == 0; return; end
                
                newValue = fullfile(PathName, FileName);
                [obj.meta, obj.files, obj.pixSize, dimsXYZ] = obj.getMetaInfo(newValue);
                obj.View.handles.SecondDatasetPath.String = newValue;
                obj.View.handles.SecondDatasetPath.TooltipString = newValue;
                obj.BatchOpt.SecondDatasetPath = newValue;
            elseif obj.View.handles.importRadio.Value
                [obj.meta, obj.files, obj.pixSize, dimsXYZ] = obj.getMetaInfo('');
                if isnan(dimsXYZ); return; end
            end
            obj.View.handles.secondDimText.String = sprintf('%d x %d x %d', dimsXYZ(1), dimsXYZ(2), dimsXYZ(3));
            obj.View.handles.minX.String = num2str(round(dimsXYZ(1)/2)-round(dimsXYZ(1)/4));
            obj.View.handles.maxX.String = num2str(round(dimsXYZ(1)/2)+round(dimsXYZ(1)/4));
            obj.View.handles.minY.String = num2str(round(dimsXYZ(2)/2)-round(dimsXYZ(2)/4));
            obj.View.handles.maxY.String = num2str(round(dimsXYZ(2)/2)+round(dimsXYZ(2)/4));
        end
        
        function [meta, files, pixSize, dimsXYZ] = getMetaInfo(obj, dirName)
            parameters.waitbar = 1;     % show waitbar
            meta = [];
            files = [];
            pixSize = [];
            dimsXYZ = [];
            if ~isempty(obj.View)
                if obj.View.handles.dirRadio.Value
                    mode = 'dir';
                elseif obj.View.handles.fileRadio.Value
                    mode = 'file';
                elseif obj.View.handles.importRadio.Value
                    mode = 'matlab';
                end
            else
                [path, filemask, ext] = fileparts(dirName);
                if ~isempty(strfind(filemask, '*')) || ~isempty(strfind(ext, '*'))  %#ok<STREMP> % directory mode
                    if exist(path) ~= 7 %#ok<EXIST> % directory does not exists
                        errordlg(sprintf('!!! Error !!!\n\nThe specified directory:\n%s\ndoes not exist!', path), 'Wrong direcory name');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                    mode = 'dir';
                else    % file mode
                    if exist(dirName) == 2  %#ok<EXIST> % a file
                        mode = 'file';
                    else
                        errordlg(sprintf('!!! Error !!!\n\nThe specified image file:\n%s\ndoes not exist!', dirName), 'Wrong filename');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                end
            end
            switch mode
                case 'dir'
                    [dirName, filemask, ext] = fileparts(dirName);
                    files = dir(dirName);
                    clear filenames;
                    index=1;
                    for i=1:numel(files)
                        if ~files(i).isdir
                            filenames{index} = fullfile(dirName, files(i).name);
                            index = index + 1;
                        end
                    end
                    [meta, files, pixSize] = mibGetImageMetadata(filenames, parameters);
                    dimsXYZ(1) = files(1).width;
                    dimsXYZ(2) = files(1).height;
                    dimsXYZ(3) = 0;
                    for i=1:numel(files)
                        dimsXYZ(3) = dimsXYZ(3) + files(i).noLayers;
                    end
                case 'file'
                    [meta, files, pixSize] = mibGetImageMetadata(cellstr(dirName), parameters);
                    dimsXYZ(1) = files(1).width;
                    dimsXYZ(2) = files(1).height;
                    dimsXYZ(3) = 0;
                    for i=1:numel(files)
                        dimsXYZ(3) = dimsXYZ(3) + files(i).noLayers;
                    end
                case 'matlab'
                    imgInfoVar = obj.View.handles.imageInfoEdit.String;
                    pathIn = obj.View.handles.SecondDatasetPath.String;
                    try %#ok<TRYNC>
                        img = evalin('base', pathIn);
                        if numel(size(img)) == 3 && size(img, 3) > 3    % reshape original dataset to w:h:color:z
                            dimsXYZ(1) = size(img, 2);
                            dimsXYZ(2) = size(img, 1);
                            dimsXYZ(3) = size(img, 3);
                        else
                            dimsXYZ(1) = size(img, 2);
                            dimsXYZ(2) = size(img, 1);
                            dimsXYZ(3) = size(img, 4);
                        end
                        if ~isempty(imgInfoVar)
                            meta = evalin('base', imgInfoVar);
                        else
                            meta = containers.Map;
                        end
                    end
                    files = struct();
                    pixSize = struct();
                    meta = NaN;
                    dimsXYZ = NaN;
            end
        end
        
        function radioButton_Callback(obj)
            % function radioButton_Callback(obj)
            % callback for selection of radio buttons:
            % obj.View.handles.dirRadio; .fileRadio; .importRadio in the Second stack panel
            if obj.View.handles.dirRadio.Value
                obj.View.handles.SecondDatasetPath.String = obj.pathstr;
                obj.View.handles.imageInfoEdit.Enable = 'off';
                obj.View.handles.secondDatasetPath.String = 'Path:';
            elseif obj.View.handles.fileRadio.Value
                obj.View.handles.SecondDatasetPath.String = obj.pathstr;
                obj.View.handles.imageInfoEdit.Enable = 'off';
                obj.View.handles.secondDatasetPath.String = 'Filename:';
            elseif obj.View.handles.importRadio.Value
                obj.pathstr = obj.View.handles.SecondDatasetPath.String;
                obj.View.handles.SecondDatasetPath.String = obj.varname;
                obj.View.handles.secondDatasetPath.String = 'Variable in the main Matlab workspace:';
                obj.View.handles.imageInfoEdit.Enable = 'on';
            end
            obj.selectButton_Callback();
        end
        
        function getSearchWindow_Callback(obj)
            % function getSearchWindow_Callback(obj)
            % callback from getSearchWindow button to define area to be
            % used for alignment
            sel = cell2mat(obj.mibModel.getData2D('selection'));
            STATS = regionprops(sel, 'BoundingBox');
            if numel(STATS) == 0
                msgbox('No selection layer present in the current slice!','Error','err');
                return;
            end
            STATS = STATS(1);
            
            obj.View.handles.minX.String = num2str(ceil(STATS.BoundingBox(1)));
            obj.View.handles.minY.String = num2str(ceil(STATS.BoundingBox(2)));
            obj.View.handles.maxX.String = num2str(ceil(STATS.BoundingBox(1)) + STATS.BoundingBox(3) - 1);
            obj.View.handles.maxY.String = num2str(ceil(STATS.BoundingBox(2)) + STATS.BoundingBox(4) - 1);
            obj.subwindowEdit_Callback();
        end
        
        function loadShiftsCheck_Callback(obj)
            % function loadShiftsCheck_Callback(obj)
            % --- Executes on button press in loadShiftsCheck.
            if obj.View.handles.loadShiftsCheck.Value
                startingPath = obj.View.handles.loadShiftsXYpath.String;
                [FileName, PathName] = uigetfile({'*.coefXY','*.coefXY (Matlab format)'; '*.*','All Files'}, 'Select file...', startingPath);
                if FileName == 0; obj.View.handles.loadShiftsCheck.Value = 0; return; end
                obj.View.handles.loadShiftsXYpath.String = fullfile(PathName, FileName);
                obj.View.handles.loadShiftsXYpath.Enable = 'on';
                var = load(fullfile(PathName, FileName), '-mat');
                if isfield(var, 'shiftsX')
                    obj.shiftsX = var.shiftsX;
                    obj.shiftsY = var.shiftsY;
                else
                    obj.shiftsX = var.tformMatrix;
                    obj.shiftsY = var.rbMatrix;
                end
            else
                obj.View.handles.loadShiftsXYpath.Enable = 'off';
            end
        end
        
        function subwindowEdit_Callback(obj, hObject)
            % function subwindowEdit_Callback(obj, hObject)
            % callback for change of subwindow edit boxes
            if nargin < 2; hObject = []; end
            
            x1 = str2double(obj.View.handles.minX.String);
            y1 = str2double(obj.View.handles.minY.String);
            x2 = str2double(obj.View.handles.maxX.String);
            y2 = str2double(obj.View.handles.maxY.String);
            if x1 < 1 || x1 > obj.mibModel.I{obj.mibModel.Id}.width
                errordlg(sprintf('!!! Error !!!\n\nThe minY value should be between 1 and %d!', obj.mibModel.I{obj.mibModel.Id}.width), 'Wrong X min');
                obj.View.handles.minX.String = '1';
                obj.updateBatchOptFromGUI(hObject); % update BatchOpt parameters
                return;
            end
            if y1 < 1 || y1 > obj.mibModel.I{obj.mibModel.Id}.height
                errordlg(sprintf('!!! Error !!!\n\nThe minY value should be between 1 and %d!', obj.mibModel.I{obj.mibModel.Id}.height), 'Wrong Y min');
                obj.View.handles.minY.String = '1';
                obj.updateBatchOptFromGUI(hObject); % update BatchOpt parameters
                return;
            end
            if x2 < 1 || x2 > obj.mibModel.I{obj.mibModel.Id}.width
                errordlg(sprintf('!!! Error !!!\n\nThe maxX value should be smaller than %d!', obj.mibModel.I{obj.mibModel.Id}.width),'Wrong X max');
                obj.View.handles.maxX.String = num2str(obj.mibModel.I{obj.mibModel.Id}.width);
                obj.updateBatchOptFromGUI(hObject); % update BatchOpt parameters
                return;
            end
            if y2 < 1 || y2 > obj.mibModel.I{obj.mibModel.Id}.height
                errordlg(sprintf('!!! Error !!!\n\nThe maxY value should be between 1 and %d!', obj.mibModel.I{obj.mibModel.Id}.height),'Wrong Y max');
                obj.View.handles.maxY.String = num2str(obj.mibModel.I{obj.mibModel.Id}.height);
                obj.updateBatchOptFromGUI(hObject); % update BatchOpt parameters
                return;
            end
            obj.BatchOpt.minX = obj.View.handles.minX.String;
            obj.BatchOpt.maxX = obj.View.handles.maxX.String;
            obj.BatchOpt.minY = obj.View.handles.minY.String;
            obj.BatchOpt.maxY = obj.View.handles.maxY.String;
        end
        
        function continueBtn_Callback(obj, useBatchMode)
            % function continueBtn_Callback(obj)
            % --- Executes on button press in continueBtn and does alignment
            % Parameters:
            % useBatchMode: a logical switch indicating that the alignment started in the batch mode
          
            if nargin < 2;  useBatchMode = 0; end

            if useBatchMode == 0     % update shiftsX/shiftsY coefficients
                if obj.View.handles.loadShiftsCheck.Value == 1
                    FileName = obj.View.handles.loadShiftsXYpath.String;
                    var = load(FileName, '-mat');
                    if isfield(var, 'shiftsX')
                        obj.shiftsX = var.shiftsX;
                        obj.shiftsY = var.shiftsY;
                    else
                        obj.shiftsX = var.tformMatrix;
                        obj.shiftsY = var.rbMatrix;
                    end
                end
            else
                [obj.meta, obj.files, obj.pixSize, dimsXYZ] = obj.getMetaInfo(obj.BatchOpt.SecondDatasetPath);
                if isempty(obj.meta); return; end
            end
            
            parameters.useBatchMode = useBatchMode;
            if obj.BatchOpt.showWaitbar; parameters.waitbar = waitbar(0, 'Please wait...', 'Name', 'Alignment and drift correction'); end
            parameters.colorCh = find(ismember(obj.BatchOpt.ColorChannel{2}, obj.BatchOpt.ColorChannel{1}));    % get index of the color channel
            
            % get color to fill background
            if strcmp(obj.BatchOpt.BackgroundColor{1}, 'Custom')
                parameters.backgroundColor = str2double(obj.BatchOpt.CustomColorValue);
                obj.files(1).backgroundColor = parameters.backgroundColor;
            else
                parameters.backgroundColor = lower(obj.BatchOpt.BackgroundColor{1});
            end
            
            switch obj.BatchOpt.CorrelateWith{1}
                case 'Previous slice'; parameters.refFrame = 0; 
                case 'First slice'; parameters.refFrame = 1; 
                case 'Relative to'; parameters.refFrame = -str2double(obj.BatchOpt.CorrelateStep);
            end
            
            parameters.method = obj.BatchOpt.Algorithm{1};
            parameters.TransformationType = obj.BatchOpt.TransformationType{1};
            if strcmp(parameters.TransformationType, 'piecewise linear'); parameters.TransformationType = 'pwl'; end
            parameters.TransformationType(parameters.TransformationType == ' ') = '';   % remove spaces
            parameters.TransformationMode = obj.BatchOpt.TransformationMode{1};
            parameters.transformationDegree = find(ismember(obj.BatchOpt.TransformationDegree{2}, obj.BatchOpt.TransformationDegree{1}))+1;
            
            [Height, Width, Color, Depth, Time] = obj.mibModel.getImageMethod('getDatasetDimensions');
            optionsGetData.blockModeSwitch = 0;
            
            if strcmp(obj.BatchOpt.Mode{1}, 'CurrentDataset')   % align the currently opened dataset
                if strcmp(parameters.method, 'Single landmark point')
                    tic
                    obj.shiftsX = zeros(1, Depth);
                    obj.shiftsY = zeros(1, Depth);
                    
                    shiftX = 0;     % shift vs 1st slice in X
                    shiftY = 0;     % shift vs 1st slice in Y
                    STATS1 = struct([]);
                    for layer=2:Depth
                        if isempty(STATS1)
                            prevLayer = cell2mat(obj.mibModel.getData2D('selection', layer-1, NaN, NaN, optionsGetData));
                            STATS1 = regionprops(prevLayer, 'Centroid');
                        end
                        if ~isempty(STATS1)
                            currLayer = cell2mat(obj.mibModel.getData2D('selection', layer, NaN, NaN, optionsGetData));
                            STATS2 = regionprops(currLayer, 'Centroid');
                            if ~isempty(STATS2)  % no second landmark found
                                shiftX = shiftX + round(STATS1.Centroid(1) - STATS2.Centroid(1));
                                shiftY = shiftY + round(STATS1.Centroid(2) - STATS2.Centroid(2));
                                obj.shiftsX(layer:end) = shiftX;
                                obj.shiftsY(layer:end) = shiftY;
                                STATS1 = STATS2;
                            else
                                STATS1 = struct([]);
                            end
                        else
                            STATS1 = struct([]);
                        end
                    end
                    toc
                    if useBatchMode == 0
                        figure(155);
                        plot(1:length(obj.shiftsX), obj.shiftsX, 1:length(obj.shiftsY), obj.shiftsY);
                        legend('Shift X', 'Shift Y');
                        grid;
                        xlabel('Frame number');
                        ylabel('Displacement');
                        title('Detected drifts');
                    
                        if ~isdeployed
                            assignin('base', 'shiftX', obj.shiftsX);
                            assignin('base', 'shiftY', obj.shiftsY);
                            fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
                        end
                    
                        fixDrifts = questdlg('Align the stack using detected displacements?', 'Fix drifts', 'Yes', 'No', 'Yes');
                        if strcmp(fixDrifts, 'No')
                            if obj.BatchOpt.showWaitbar
                                delete(parameters.waitbar);
                                return;
                            end
                        end
                        delete(155);
                    end
                    
                    % do alignment
                    obj.mibModel.getImageMethod('clearSelection');
                    
                    img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('image', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                    obj.mibModel.setData4D('image', img, NaN, 0, optionsGetData);
                elseif strcmp(parameters.method, 'Three landmark points')
                    tic
                    obj.shiftsX = zeros(1, Depth);
                    obj.shiftsY = zeros(1, Depth);
                    
                    layer = 1;
                    while layer <= Depth-1
                        currImg = cell2mat(obj.mibModel.getData2D('selection', layer, NaN, NaN, optionsGetData));
                        if sum(sum(currImg)) > 0   % landmark is found
                            CC1 = bwconncomp(currImg);
                            
                            if CC1.NumObjects < 3; continue; end  % require 3 points
                            CC2 = bwconncomp(cell2mat(obj.mibModel.getData2D('selection', layer+1, NaN, NaN, optionsGetData)));
                            if CC2.NumObjects < 3; layer = layer + 1; continue; end  % require 3 points
                            
                            STATS1 = regionprops(CC1, 'Centroid');
                            STATS2 = regionprops(CC2, 'Centroid');
                            
                            % find distances between centroids of material 1 and material 2
                            X1 =  reshape([STATS1.Centroid], [2 numel(STATS1)])';     % centroids matrix, c1([x,y], pointNumber)
                            X2 =  reshape([STATS2.Centroid], [2 numel(STATS1)])';
                            idx = mibAlignmentController.findMatchingPairs(X2, X1);
                            
                            output = reshape([STATS1.Centroid], [2 numel(STATS1)])';     % main dataset points, centroids matrix, c1(pointNumber, [x,y])
                            for objId = 1:numel(STATS2)
                                input(objId, :) = STATS2(idx(objId)).Centroid; % the second dataset points, centroids matrix, c1(pointNumber, [x,y])
                            end
                            
                            % define background color
                            if isnumeric(parameters.backgroundColor)
                                backgroundColor = options.backgroundColor;
                            else
                                if strcmp(parameters.backgroundColor, 'black')
                                    backgroundColor = 0;
                                elseif strcmp(parameters.backgroundColor,'white')
                                    backgroundColor = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
                                else
                                    backgroundColor = mean(mean(cell2mat(obj.mibModel.getData2D('image', layer, NaN, parameters.colorCh, optionsGetData))));
                                end
                            end
                            
                            tform2 = maketform('affine', input, output);    % fitgeotrans: see below for the test
                            
                            % define boundaries for datasets to take, note that the .x, .y, .z are numbers after transpose of the dataset
                            optionsGetData.x = [1, Width];
                            optionsGetData.y = [1, Height];
                            optionsGetData.z = [layer+1, Depth];
                            optionsGetData2.blockModeSwitch = 0;
                            optionsGetData2.x = [1, Width];
                            optionsGetData2.y = [1, Height];
                            optionsGetData2.z = [1, layer];
                            
                            [T, xdata, ydata] = imtransform(cell2mat(obj.mibModel.getData4D('image', NaN, 0, optionsGetData)), ...
                                tform2, 'bicubic', 'FillValues', double(backgroundColor));  % imwarp: see below for the test
                            if xdata(1) < 1
                                obj.shiftsX = floor(xdata(1));
                            else
                                obj.shiftsX = ceil(xdata(1));
                            end
                            if ydata(1) < 1
                                obj.shiftsY = floor(ydata(1))-1;
                            else
                                obj.shiftsY = ceil(ydata(1))-1;
                            end
                            
                            
                            %                                             tform2 = fitgeotrans(output, input, 'affine');
                            %                                             %tform2 = fitgeotrans(output, input, 'NonreflectiveSimilarity');
                            %
                            %                                             [T, RB] = imwarp(handles.I.img(:,:,:,layer+1:end), tform2, 'bicubic', 'FillValues', backgroundColor);
                            %                                             if RB.XWorldLimits(1) <  1
                            %                                                 obj.shiftsX = floor(RB.XWorldLimits(1));
                            %                                             else
                            %                                                 obj.shiftsX = ceil(RB.XWorldLimits(1));
                            %                                             end
                            %                                             if RB.YWorldLimits(1) < 1
                            %                                                 obj.shiftsY = floor(RB.YWorldLimits(1))-1;
                            %                                             else
                            %                                                 obj.shiftsY = ceil(RB.YWorldLimits(1))-1;
                            %                                             end
                            %
                            
                            [img, bbShiftXY] = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('image', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            if isempty(img);   notify(obj.mibModel, 'stopProtocol'); return; end
                            optionsSetData.blockModeSwitch = 0;
                            obj.mibModel.setData4D('image', img, NaN, 0, optionsSetData);
                            
                            layerId = layer;
                            layer = Depth;
                        end
                        layer = layer + 1;
                    end
                elseif strcmp(parameters.method, 'Landmarks, multi points')
                    % function to improve alignment using 3+ points
                    % for multiple slices.
                    % Limited to the same image size as the first image and
                    % 63 materials only
                    obj.LandmarkMultiPointAlignment(parameters);
                    return;
                elseif strcmp(parameters.method, 'Color channels, multi points')
                    % align selected color channel over the rest of the
                    % dataset. 
                    obj.LandmarkMultiPointColorAlignment(parameters);
                    return;
                elseif strcmp(parameters.method, 'Automatic feature-based')
                    % Automatic alignment using detected features
                    
                    parameters.detectPointsType = obj.BatchOpt.FeatureDetectorType{1};
                    obj.AutomaticFeatureBasedAlignment(parameters);
                    return;
                else        % standard alignement
                    %parameters.step = str2double(obj.View.handles.CorrelateStep,'string'));
                    tic
                    % calculate shifts
                    if isempty(obj.shiftsX)
                        if strcmp(obj.BatchOpt.Subarea{1}, 'Manually specified')
                            optionsGetData.x(1) = str2double(obj.BatchOpt.minX);
                            optionsGetData.x(2) = str2double(obj.BatchOpt.maxX);
                            optionsGetData.y(1) = str2double(obj.BatchOpt.minY);
                            optionsGetData.y(2) = str2double(obj.BatchOpt.maxY);
                            optionsGetData.z(1) = 1;
                            optionsGetData.z(2) = Depth;
                            I = squeeze(cell2mat(obj.mibModel.getData4D('image', NaN, parameters.colorCh, optionsGetData)));
                            optionsGetData = rmfield(optionsGetData, 'x');
                            optionsGetData = rmfield(optionsGetData, 'y');
                            optionsGetData = rmfield(optionsGetData, 'z');
                            %I = squeeze(handles.I.img(y1:y2, x1:x2, parameters.colorCh, :, handles.I.slices{5}(1)));
                        else
                            %I = squeeze(handles.I.img(:, :, parameters.colorCh, :, handles.I.slices{5}(1)));
                            I = squeeze(cell2mat(obj.mibModel.getData4D('image', NaN, parameters.colorCh, optionsGetData)));
                        end
                        
                        if ismember(obj.BatchOpt.Subarea{1}, {'Mask', 'Selection'})
                            if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Extracting masked areas\nPlease wait...')); end
                            %intensityShift =  mean(I(:));   % needed for better correlation of images of different size
                            img = zeros(size(I), class(I));% + intensityShift;
                            bb = nan([size(I, 3), 4]);
                            
                            for slice = 1:size(I, 3)
                                mask = cell2mat(obj.mibModel.getData2D(lower(obj.BatchOpt.Subarea{1}), slice, NaN, NaN, optionsGetData));
                                stats = regionprops(mask, 'BoundingBox');
                                if numel(stats) == 0; continue; end
                                
                                currBB = ceil(stats.BoundingBox);
                                mask = mask(currBB(2):currBB(2)+currBB(4)-1, currBB(1):currBB(1)+currBB(3)-1);
                                currImg = I(currBB(2):currBB(2)+currBB(4)-1, currBB(1):currBB(1)+currBB(3)-1, slice);
                                intensityShift = mean(mean(currImg));  % needed for better correlation of images of different size
                                currImg(~mask) = intensityShift;
                                img(:, :, slice) = intensityShift;
                                img(1:currBB(4), 1:currBB(3), slice) = currImg;
                                
                                bb(slice, :) = currBB;
                                if obj.BatchOpt.showWaitbar; waitbar(slice/size(I, 3), parameters.waitbar); end
                            end
                            sliceIndices = find(~isnan(bb(:,1)));   % find indices of slices that have mask
                            if isempty(sliceIndices)
                                if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                                errordlg(sprintf('No %s areas were found!', obj.BatchOpt.Subarea{1}), sprintf('Missing %s layer', obj.BatchOpt.Subarea{1}));
                                notify(obj.mibModel, 'stopProtocol');
                                return;
                            end
                            I = img(1:max(bb(:, 4)), 1:max(bb(:, 3)), sliceIndices);
                            clear img;
                        end
                        
                        if obj.BatchOpt.IntensityGradient
                            if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Calculating intensity gradient for color channel %d ...', parameters.colorCh)); end
                            
                            img = zeros(size(I), class(I));
                            % generate gradient image
                            hy = fspecial('sobel');
                            hx = hy';
                            for slice = 1:size(I, 3)
                                Im = I(:,:,slice);   % get a slice
                                Iy = imfilter(double(Im), hy, 'replicate');
                                Ix = imfilter(double(Im), hx, 'replicate');
                                img(:,:,slice) = sqrt(Ix.^2 + Iy.^2);
                                if obj.BatchOpt.showWaitbar; waitbar(slice/size(I, 3), parameters.waitbar); end
                            end
                            I = img;
                            clear img;
                        end
                        
                        % calculate drifts
                        [shiftX, shiftY] = mibCalcShifts(I, parameters);
                        if isempty(shiftX); notify(obj.mibModel, 'stopProtocol'); return; end
                        
                        if ismember(obj.BatchOpt.Subarea{1}, {'Mask', 'Selection'})
                            % check for missing mask slices
                            if length(sliceIndices) ~= Depth
                                shX = zeros([Depth, 1]);
                                shY = zeros([Depth, 1]);
                                
                                index = 1;
                                breakBegin = 0;
                                for i=2:Depth
                                    if isnan(bb(i,1))
                                        if breakBegin == 0
                                            breakBegin = 1;
                                            shX(i) = shX(i-1);
                                            shY(i) = shY(i-1);
                                        else
                                            shX(i) = shX(i-1);
                                            shY(i) = shY(i-1);
                                        end
                                    else
                                        if breakBegin == 1
                                            shX(i) = shX(i-1);
                                            shY(i) = shY(i-1);
                                            breakBegin = 0;
                                        else
                                            if index > 1
                                                shX(i) = shX(i-1) + shiftX(index)-shiftX(index-1)-(bb(i,1)-bb(i-1,1));
                                                shY(i) = shY(i-1) + shiftY(index)-shiftY(index-1)-(bb(i,2)-bb(i-1,2));
                                            else
                                                shX(i) = shX(i-1) + shiftX(index)-(bb(i,1)-bb(i-1,1));
                                                shY(i) = shY(i-1) + shiftY(index)-(bb(i,2)-bb(i-1,2));
                                            end
                                        end
                                        index = index + 1;
                                    end
                                end
                                shiftX = shX;
                                shiftY = shY;
                            else
                                difX = [0; diff(bb(:,1))];
                                difX = cumsum(difX);
                                shiftX = shiftX - difX;
                                difY = [0; diff(bb(:,2))];
                                difY = cumsum(difY);
                                shiftY = shiftY - difY;
                            end
                        end
                        
                        %             % ---- start of drift problems correction
                        fixDrifts = '';
                        if useBatchMode == 0
                            figure(155);
                            %subplot(2,1,1);
                            plot(1:length(shiftX), shiftX, 1:length(shiftY), shiftY);
                            %plot(1:length(shiftX), shiftX, 1:length(shiftX), windv(shiftX, 25), 1:length(shiftX), shiftX2);
                            legend('Shift X', 'Shift Y');
                            %legend('Shift X', 'Smoothed 50 pnts window', 'Final shifts');
                            grid;
                            xlabel('Frame number');
                            ylabel('Displacement');
                            title('Before drift correction');
                        
                            fixDrifts = questdlg('Align the stack using detected displacements?','Fix drifts','Yes','Subtract running average','No','Yes');
                            if strcmp(fixDrifts, 'No')
                                if isdeployed == 0
                                    assignin('base', 'shiftX', shiftX);
                                    assignin('base', 'shiftY', shiftY);
                                    fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
                                end
                                if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                                return;
                            end
                        end
                        
                        % fix drifts
                        if strcmp(fixDrifts, 'Subtract running average') || obj.BatchOpt.SubtractRunningAverage == 1
                            halfwidth = str2double(obj.BatchOpt.SubtractRunningAverageStep);
                            excludePeaks = str2double(obj.BatchOpt.SubtractRunningAverageExcludePeaks);
                            [shiftX, shiftY, halfwidth, excludePeaks] = mibSubtractRunningAverage(shiftX, shiftY, halfwidth, excludePeaks, useBatchMode);
                            if isempty(shiftX)
                                if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                                notify(obj.mibModel, 'stopProtocol');
                                return;    
                            end
                            if halfwidth > 0
                                obj.BatchOpt.SubtractRunningAverage = true;
                                obj.BatchOpt.SubtractRunningAverageStep = num2str(halfwidth);    
                                obj.BatchOpt.SubtractRunningAverageExcludePeaks = num2str(excludePeaks);
                            end
                        end
                        
                        % exporting shifts to Matlab
                        if isdeployed == 0
                            assignin('base', 'shiftX', shiftX);
                            assignin('base', 'shiftY', shiftY);
                            fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
                        end
                        
                        obj.shiftsX = shiftX;
                        obj.shiftsY = shiftY;
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning the images\nPlease wait...')); end
                    
                    %img = mib_crossShiftStack(handles.I.img, obj.shiftsX, obj.shiftsY, parameters);
                    img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('image', NaN, 0)), obj.shiftsX, obj.shiftsY, parameters);
                    if isempty(img); notify(obj.mibModel, 'stopProtocol'); return; end
                    %obj.mibModel.setData4D('image', img, NaN, 0);
                    obj.mibModel.setData4D('image', img, NaN, 0, optionsGetData);
                end
                
                % aligning the service layers: mask, selection, model
                % force background color to be black for the service layers
                % if the background needs to be selected, the parameters.backgroundColor = 'white'; should be used for selection layer
                parameters.backgroundColor = 0;
                parameters.modelSwitch = 1;
                
                if obj.mibModel.getImageProperty('modelType') ~= 63
                    if obj.mibModel.getImageProperty('modelExist')
                        if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning model\nPlease wait...')); end
                        if ~strcmp(parameters.method, 'Three landmark points')
                            img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('model', NaN, NaN, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('model', img, NaN, NaN, optionsGetData);
                        else
                            T = imtransform(cell2mat(obj.mibModel.getData4D('model', NaN, NaN, optionsGetData)), tform2, 'nearest');
                            img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('model', NaN, NaN, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('model', img, NaN, NaN, optionsSetData);
                        end
                    end
                    if ~isnan(obj.mibModel.I{obj.mibModel.Id}.maskImg{1}(1))
                        if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning mask...\nPlease wait...')); end
                        if ~strcmp(parameters.method, 'Three landmark points')
                            img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('mask', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('mask', img, NaN, NaN, optionsGetData);
                        else
                            T = imtransform(cell2mat(obj.mibModel.getData4D('mask', NaN, 0, optionsGetData)), tform2, 'nearest');
                            img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('mask', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('mask', img, NaN, NaN, optionsSetData);
                        end
                    end
                    if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                        if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning selection...\nPlease wait...')); end
                        if ~strcmp(parameters.method, 'Three landmark points')
                            img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('selection', NaN, NaN, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('selection', img, NaN, NaN, optionsGetData);
                        else
                            T = imtransform(cell2mat(obj.mibModel.getData4D('selection', NaN, NaN, optionsGetData)), tform2, 'nearest');
                            img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('selection', NaN, NaN, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                            obj.mibModel.setData4D('selection', img, NaN, NaN, optionsSetData);
                        end
                    end
                else
                    if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning Selection, Mask, Model...\nPlease wait...')); end
                    if ~strcmp(parameters.method, 'Three landmark points')
                        img = mibCrossShiftStack(cell2mat(obj.mibModel.getData4D('everything', NaN, 0, optionsGetData)), obj.shiftsX, obj.shiftsY, parameters);
                        obj.mibModel.setData4D('everything', img, NaN, 0, optionsGetData);
                    else
                        %T = imwarp(handles.I.model(:,:,layerId+1:end), tform2, 'nearest', 'FillValues', parameters.backgroundColor);
                        %handles.I.model = mib_crossShiftStacks(handles.I.model(:,:,1:layerId), T, obj.shiftsX, obj.shiftsY, parameters);
                        
                        T = imtransform(cell2mat(obj.mibModel.getData4D('everything', NaN, 0, optionsGetData)), tform2, 'nearest');
                        img = mibCrossShiftStacks(cell2mat(obj.mibModel.getData4D('everything', NaN, 0, optionsGetData2)), T, obj.shiftsX, obj.shiftsY, parameters);
                        obj.mibModel.setData4D('everything', img, NaN, 0, optionsSetData);
                    end
                end
                
                obj.mibModel.I{obj.mibModel.Id}.height = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 1);
                obj.mibModel.I{obj.mibModel.Id}.width = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 2);
                oldSlices = obj.mibModel.I{obj.mibModel.Id}.slices;
                obj.mibModel.I{obj.mibModel.Id}.slices{1} = [1, obj.mibModel.I{obj.mibModel.Id}.height];
                obj.mibModel.I{obj.mibModel.Id}.slices{2} = [1, obj.mibModel.I{obj.mibModel.Id}.width];
                obj.mibModel.I{obj.mibModel.Id}.slices{3} = 1:size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 3);
                obj.mibModel.I{obj.mibModel.Id}.slices{4} = [1, 1];
                obj.mibModel.I{obj.mibModel.Id}.slices{5} = [1, 1];
                obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation} = ...
                    [oldSlices{obj.mibModel.I{obj.mibModel.Id}.orientation}, oldSlices{obj.mibModel.I{obj.mibModel.Id}.orientation}];
                
                % calculate shift of the bounding box
                maxXshift =  min(obj.shiftsX);   % maximal X shift in pixels vs the first slice
                maxYshift = min(obj.shiftsY);   % maximal Y shift in pixels vs the first slice
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

                if exist('halfwidth', 'var')    % add halfwidth text
                    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(sprintf('Aligned using %s; relative to %d; run-average correction: %d, excludePeaks: %s', obj.BatchOpt.Algorithm{1}, parameters.refFrame, halfwidth, obj.BatchOpt.SubtractRunningAverageExcludePeaks));
                else
                    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(sprintf('Aligned using %s; relative to %d', obj.BatchOpt.Algorithm{1}, parameters.refFrame));    
                end
                
                if obj.BatchOpt.SaveShiftsToFile     % use preexisting parameters
                    if useBatchMode == 1
                        fn = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
                        [obj.pathstr, name, ext] = fileparts(fn);
                        fn = fullfile(obj.pathstr, [name '_align.coefXY']);
                    else
                        fn = obj.View.handles.saveShiftsXYpath.String;
                    end
                    shiftsX = obj.shiftsX; %#ok<PROP,NASGU>
                    shiftsY = obj.shiftsY; %#ok<PROP,NASGU>
                    fprintf('Saving alignement shifts to file: %s ...', fn);
                    save(fn, 'shiftsX', 'shiftsY');
                    fprintf('done!\n');
                end
            else        % align two stacks
                if obj.mibModel.I{obj.mibModel.Id}.orientation ~= 4
                    errordlg(sprintf('!!! Error !!!\n\nThe alignement of two separate datasets is only possible in the XY mode\nPlease turn your dataset into the XY mode using a dedicated button in the toolbar.'),'Wrong orientation');
                    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                    return;
                end
                
                if useBatchMode == 0     % update shiftsX/shiftsY coefficients
                    if isempty(fields(obj.files)) && obj.View.handles.importRadio.Value == 0
                        obj.selectButton_Callback();
                    end
                    if obj.View.handles.dirRadio.Value
                        % loading the datasets
                        [img,  img_info] = mibGetImages(obj.files, obj.meta);
                        if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning stacks using color channel %d ...', parameters.colorCh)); end
                    elseif obj.View.handles.fileRadio.Value
                        [img,  img_info] = mibGetImages(obj.files, obj.meta);
                        if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning stacks using color channel %d ...', parameters.colorCh)); end
                    elseif obj.View.handles.importRadio.Value
                        if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning stacks using color channel %d ...', parameters.colorCh)); end
                        pathIn = obj.View.handles.SecondDatasetPath.String;
                        imgInfoVar = obj.View.handles.imageInfoEdit.String;
                        img = evalin('base', pathIn);
                        if numel(size(img)) == 3 && size(img,3) > 3    % reshape original dataset to w:h:color:z
                            img = reshape(img, size(img,1), size(img,2), 1, size(img,3));
                        end
                        if ~isempty(imgInfoVar)
                            img_info = evalin('base', imgInfoVar);
                        else
                            img_info = containers.Map;
                        end
                    end
                else
                    [img,  img_info] = mibGetImages(obj.files, obj.meta);
                    if obj.BatchOpt.showWaitbar; waitbar(0, parameters.waitbar, sprintf('Aligning stacks using color channel %d ...', parameters.colorCh)); end
                end
                
                tic
                if obj.BatchOpt.TwoStacksAutomaticMode     % automatic mode
                    w1 = max([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 2) size(img, 2)]);
                    h1 = max([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 1) size(img, 1)]);
                    
                    I = zeros([h1, w1, 2], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')) + ...
                        mean(mean(obj.mibModel.I{obj.mibModel.Id}.img{1}(:, :, parameters.colorCh, end, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1))));
                    I(1:obj.mibModel.I{obj.mibModel.Id}.height, 1:obj.mibModel.I{obj.mibModel.Id}.width, 1) = ...
                        obj.mibModel.I{obj.mibModel.Id}.img{1}(:, :, parameters.colorCh, end, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                    I(1:size(img, 1), 1:size(img, 2), 2) = ...
                        img(:, :, parameters.colorCh, 1, obj.mibModel.I{obj.mibModel.Id}.slices{5}(1));
                    
                    if obj.BatchOpt.IntensityGradient
                        % generate gradient image
                        I2 = zeros(size(I), class(I));
                        % generate gradient image
                        hy = fspecial('sobel');
                        hx = hy';
                        for slice = 1:size(I, 3)
                            Im = I(:,:,slice);   % get a slice
                            Iy = imfilter(double(Im), hy, 'replicate');
                            Ix = imfilter(double(Im), hx, 'replicate');
                            I2(:,:,slice) = sqrt(Ix.^2 + Iy.^2);
                        end
                        I = I2;
                        clear I2;
                    end
                    % calculate drifts
                    [shiftX, shiftY] = mibCalcShifts(I, parameters);
                    if isempty(shiftX); return; end
                    
                    if useBatchMode == 0
                        prompt = {'X shift:'; 'Y shift:'};
                        defAns = {num2str(shiftX(2)); num2str(shiftY(2))};
                        mibInputMultiDlgOpt.PromptLines = [1, 1];
                        mibInputMultiDlgOpt.Title = 'Would you like to use detected shifts?';
                        mibInputMultiDlgOpt.TitleLines = 2;
                        answer = mibInputMultiDlg([], prompt, defAns, 'Calculated shifts', mibInputMultiDlgOpt);
                        if isempty(answer); if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end; return; end
                        obj.shiftsX = str2double(answer{1});
                        obj.shiftsY = str2double(answer{2});
                    else
                        obj.shiftsX = shiftX(2);
                        obj.shiftsY = shiftY(2);
                    end
                else
                    obj.shiftsX = str2double(obj.BatchOpt.TwoStacksShiftX);
                    obj.shiftsY = str2double(obj.BatchOpt.TwoStacksShiftY);
                end
%                 % Alternative option to use addStack function
%                 % it is slightly slower and takes a bit more memory
%                 % requires to update padarray -> so that it takes 4
%                 % independent parameters, not as 'pre'/'post'
%                 bbShiftXY = obj.mibModel.I{obj.mibModel.Id}.addStack(img, obj.shiftsX, obj.shiftsY, parameters);
%                 toc;
%                 notify(obj.mibModel, 'newDataset');
%                 notify(obj.mibModel, 'plotImage');
%                 if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
%                 return;
                
                [height2, width2, color2, depth2, time2] = size(img);
                
                [img, bbShiftXY] = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.img{1}, img, obj.shiftsX, obj.shiftsY, parameters);
                if isempty(img);        if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end;       return; end
                obj.mibModel.I{obj.mibModel.Id}.img{1} = img;
                clear img;
                
                obj.mibModel.I{obj.mibModel.Id}.depth = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 4);
                obj.mibModel.I{obj.mibModel.Id}.meta('Depth') = obj.mibModel.I{obj.mibModel.Id}.depth;
                obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(4) = obj.mibModel.I{obj.mibModel.Id}.depth;
                
                % calculate shift of the bounding box
                maxXshift = bbShiftXY(1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;  % X shift in units vs the first slice
                maxYshift = bbShiftXY(2)*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;  % Y shift in units vs the first slice
                bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                bb(1:2) = bb(1:2)-maxXshift;
                bb(3:4) = bb(3:4)-maxYshift;
                bb(6) = bb(6)+depth2*obj.mibModel.I{obj.mibModel.Id}.pixSize.z;
                obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(bb);
                
                obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(sprintf('Aligned two stacks using %s', obj.BatchOpt.Algorithm{1}));
                
                % aligning the service layers: mask, selection, model
                % force background color to be black for the service layers
                % if the background needs to be selected, the parameters.backgroundColor = 'white'; should be used for selection layer
                parameters.backgroundColor = 0;
                parameters.modelSwitch = 1;
                
                if obj.mibModel.disableSegmentation ~= 1
                    dummySelection = zeros([height2, width2, depth2, time2], 'uint8');    % dummy variable for resizing mask, model and selection
                end
                
                if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
                    if obj.mibModel.getImageProperty('modelExist')
                        if obj.BatchOpt.showWaitbar; waitbar(.5, parameters.waitbar,sprintf('Aligning model\nPlease wait...')); end
                        obj.mibModel.I{obj.mibModel.Id}.model{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.model{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                    end
                    if obj.mibModel.getImageProperty('maskExist')
                        if obj.BatchOpt.showWaitbar; waitbar(.5, parameters.waitbar,sprintf('Aligning mask\nPlease wait...')); end
                        obj.mibModel.I{obj.mibModel.Id}.maskImg{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.maskImg{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                    end
                    if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                        if obj.BatchOpt.showWaitbar; waitbar(.5, parameters.waitbar,sprintf('Aligning selection\nPlease wait...')); end
                        obj.mibModel.I{obj.mibModel.Id}.selection{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.selection{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                    end
                else
                    if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.model{1}(1))
                        if obj.BatchOpt.showWaitbar; waitbar(.5, parameters.waitbar,sprintf('Aligning Selection, Mask, Model\nPlease wait...')); end
                        obj.mibModel.I{obj.mibModel.Id}.model{1} = mibCrossShiftStacks(obj.mibModel.I{obj.mibModel.Id}.model{1}, dummySelection, obj.shiftsX, obj.shiftsY, parameters);
                    end
                end
                
                % combine SliceNames
%                 if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
%                     SN = cell([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 4), 1]);
%                     SN(1:numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))) = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
%                     
%                     if isKey(img_info, 'SliceName')
%                         SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = img_info('SliceName');
%                     else
%                         if isKey(img_info, 'Filename')
%                             [~, fn, ext] = fileparts(img_info('Filename'));
%                             SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = [fn ext];
%                         else
%                             SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = cellstr('noname');
%                         end
%                     end
%                     obj.mibModel.I{obj.mibModel.Id}.meta('SliceName') = SN;
%                 end
                
                % combine SliceNames
                if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
                    if numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName')) > 1
                        SN = cell([size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 4), 1]);
                        SN(1:numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))) = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                        
                        if isfield(parameters, 'SliceName')
                            SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = options.SliceName;
                        else
                            SN(numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))+1:end) = {'added_stack'};
                        end
                        obj.mibModel.I{obj.mibModel.Id}.meta('SliceName') = SN;
                    end
                end
                
                
            end
            
            if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
            
            obj.mibModel.I{obj.mibModel.Id}.width = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 2);
            obj.mibModel.I{obj.mibModel.Id}.height = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 1);
            obj.mibModel.I{obj.mibModel.Id}.colors = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 3);
            obj.mibModel.I{obj.mibModel.Id}.meta('Height') = obj.mibModel.I{obj.mibModel.Id}.height;
            obj.mibModel.I{obj.mibModel.Id}.meta('Width') = obj.mibModel.I{obj.mibModel.Id}.width;
            toc;
            notify(obj.mibModel, 'newDataset');
            notify(obj.mibModel, 'plotImage');
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(obj.BatchOpt);
            if useBatchMode == 0; obj.closeWindow(); end
        end
        
        
        function LandmarkMultiPointAlignment(obj, parameters)
            % function LandmarkMultiPointAlignment(obj, parameters)
            % perform alignment using multiple landmark points
            
            [Height, Width, Color, Depth, Time] = obj.mibModel.getImageMethod('getDatasetDimensions');
            optionsGetData.blockModeSwitch = 0;
            
            if parameters.useBatchMode == 0
                parameters.useAnnotations = 0;
                if obj.View.handles.loadShiftsCheck.Value == 0
                    if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber > 5
                        button = questdlg(sprintf('Have the corresponding points were labeled using Annotations or using brush and the selection layer?'), ...
                            'Annotations or Selection?', 'Annotations', 'Selection', 'Cancel', 'Annotations');
                        switch button
                            case 'Annotations'
                                parameters.useAnnotations = 1;
                            case 'Selection'
                                parameters.useAnnotations = 0;
                            case 'Cancel'
                                if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                                return;
                        end
                    end
                end
            else    % the batch mode uses annotations only
                parameters.useAnnotations = 1;
            end
            tic
            
            % define minimal number of required landmarks
            switch parameters.TransformationType
                case 'nonreflectivesimilarity'
                    minLandmarks = 2;
                case {'similarity', 'affine'}
                    minLandmarks = 3;
                case {'projective', 'pwl'}
                    minLandmarks = 4;
                case {'polynomial', 'lwm'}
                    minLandmarks = 6;
            end
            
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
            if loadShifts == 0
                for layer = 2:Depth
                    outputPnts = [];
                    if parameters.useAnnotations
                        [labelsList, ~, X1] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer-1);
                        if ~isempty(labelsList)
                            if numel(labelsList) < minLandmarks; continue; end
                            [labelsList2, ~, X2] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer);
                            if numel(labelsList2) < minLandmarks; continue; end
                            outputPnts = X1(:,2:3);     % x,y
                            X2 = X2(:,2:3);     % x,y
                            inputPnts = zeros(size(outputPnts));
                            for labelId = 1:numel(labelsList)
                                idx = find(ismember(labelsList2, labelsList{labelId})==1);
                                inputPnts(labelId, :) = X2(idx, :); %#ok<FNDSB>
                            end
                        end
                    else
                        currImg = cell2mat(obj.mibModel.getData2D('selection', layer-1, NaN, NaN, optionsGetData));
                        if sum(sum(currImg)) > 0   % landmark is found
                            CC1 = bwconncomp(currImg);

                            if CC1.NumObjects < minLandmarks; continue; end  % require minLandmarks points
                            CC2 = bwconncomp(cell2mat(obj.mibModel.getData2D('selection', layer, NaN, NaN, optionsGetData)));
                            if CC2.NumObjects < minLandmarks; continue; end  % require minLandmarks points

                            STATS1 = regionprops(CC1, 'Centroid');
                            STATS2 = regionprops(CC2, 'Centroid');

                            % find distances between centroids of material 1 and material 2
                            X1 =  reshape([STATS1.Centroid], [2 numel(STATS1)])';     % centroids matrix, c1([x,y], pointNumber)
                            X2 =  reshape([STATS2.Centroid], [2 numel(STATS1)])';

                            if ~isempty(tformMatrix{layer-1})
                                [X1(:,1), X1(:,2)] = transformPointsForward(tformMatrix{layer-1}, X1(:,1), X1(:,2));
                                [X2(:,1), X2(:,2)] = transformPointsForward(tformMatrix{layer-1}, X2(:,1), X2(:,2));
                            end

                            idx = mibAlignmentController.findMatchingPairs(X2, X1);     % indices of X2 matching X1
                            outputPnts = reshape([STATS1.Centroid], [2 numel(STATS1)])';     % main dataset points, centroids matrix, c1(pointNumber, [x,y])
                            inputPnts = zeros(size(outputPnts));

                            for objId = 1:numel(STATS2)
                                inputPnts(objId, :) = STATS2(idx(objId)).Centroid; % the second dataset points, centroids matrix, c1(pointNumber, [x,y])
                            end
                        end
                    end

                    if isempty(outputPnts) && isempty(tformMatrix{layer}); continue; end    % skip begining of the dataset

                    % https://se.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html
                    if isempty(tformMatrix{layer})
                        if ~strcmp(parameters.TransformationType, 'polynomial')
                            tform2 = fitgeotrans(inputPnts, outputPnts, parameters.TransformationType);
                        else
                            tform2 = fitgeotrans(inputPnts, outputPnts, parameters.TransformationType, parameters.transformationDegree);
                        end

                        tformMatrix(layer:end) = {tform2};
                    elseif ~isempty(outputPnts)
                        if ~strcmp(parameters.TransformationType, 'polynomial')
                            tform2 = fitgeotrans(inputPnts, outputPnts, parameters.TransformationType);
                        else
                            tform2 = fitgeotrans(inputPnts, outputPnts, parameters.TransformationType, parameters.transformationDegree);
                        end
                        %tform3 = cp2tform(inputPnts, outputPnts, parameters.TransformationType);
                        tform2.T = tform2.T*tformMatrix{layer}.T;
                        tformMatrix(layer:end) = {tform2};
                        %[y, x] = outputLimits(tform2, [1 Height], [1 Width])
                    end

                    if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 1: Extracting landmarks\nPlease wait...')); end
                end
                
                if exist('inputPnts', 'var')==0
                    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                    warndlg(sprintf('!!! Warning !!!\n\nLandmark points are missing!'));
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
            end
            
            refImgSize = imref2d([Height, Width]);
            
            if strcmp(parameters.TransformationMode, 'cropped') == 1    % the cropped view, faster and take less memory
                for layer=2:Depth
                    if ~isempty(tformMatrix{layer})
                        I = cell2mat(obj.mibModel.getData2D('image', layer, NaN, parameters.colorCh, optionsGetData));
                        [iMatrix{layer}, rbMatrix{layer}] = imwarp(I, tformMatrix{layer}, 'cubic', 'OutputView', refImgSize, 'FillValues', double(backgroundColor));
                        
                        obj.mibModel.setData2D('image', iMatrix{layer}, layer, NaN, parameters.colorCh, optionsGetData);
                        %                             A = imread('pout.tif');
                        %                             Rin = imref2d(size(A))
                        %                             Rin.XWorldLimits = Rin.XWorldLimits-mean(Rin.XWorldLimits);
                        %                             Rin.YWorldLimits = Rin.YWorldLimits-mean(Rin.YWorldLimits);
                        %                             out = imwarp(A,Rin,tform);
                        
                        if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
                            I = cell2mat(obj.mibModel.getData2D('everything', layer, NaN, NaN, optionsGetData));
                            I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                            obj.mibModel.setData2D('everything', I, layer, NaN, NaN, optionsGetData);
                        else
                            if obj.mibModel.getImageProperty('modelExist')
                                I = cell2mat(obj.mibModel.getData2D('model', layer, NaN, NaN, optionsGetData));
                                I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                                obj.mibModel.setData2D('model', I, layer, NaN, NaN, optionsGetData);
                            end
                            if obj.mibModel.getImageProperty('maskExist')
                                I = cell2mat(obj.mibModel.getData2D('mask', layer, NaN, NaN, optionsGetData));
                                I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                                obj.mibModel.setData2D('mask', I, layer, NaN, NaN, optionsGetData);
                            end
                            if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                                I = cell2mat(obj.mibModel.getData2D('selection', layer, NaN, NaN, optionsGetData));
                                I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                                obj.mibModel.setData2D('selection', I, layer, NaN, NaN, optionsGetData);
                            end
                        end
                        
                        % transform annotations
                        [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer);
                        if ~isempty(labelsList)
                            [labelPositions(:,2), labelPositions(:,3)] = transformPointsForward(tformMatrix{layer}, labelPositions(:,2), labelPositions(:,3));
                            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(indices, labelsList, labelPositions, labelValues);
                        end
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 2: Align datasets\nPlease wait...')); end
                end
            else  % the extended view
                iMatrix = cell([numel(Depth), 1]);
                rbMatrix(1:Depth) = {refImgSize};
                
                for layer=1:Depth
                    if ~isempty(tformMatrix{layer})
                        I = cell2mat(obj.mibModel.getData2D('image', layer, NaN, parameters.colorCh, optionsGetData));
                        [iMatrix{layer}, rbMatrix{layer}] = imwarp(I, tformMatrix{layer}, 'cubic', 'FillValues', double(backgroundColor));
                        
                        %I = cell2mat(obj.mibModel.getData2D('everything', layer, NaN, NaN, optionsGetData));
                        %I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                        %obj.mibModel.setData2D('everything', I, layer, NaN, NaN, optionsGetData);
                    else
                        iMatrix{layer} = cell2mat(obj.mibModel.getData2D('image', layer, NaN, parameters.colorCh, optionsGetData));
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 2: Transforming images\nPlease wait...')); end
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
                Iout = zeros([nHeight, nWidth, 1, numel(rbMatrix)], class(I)) + backgroundColor;
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
                    if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 3: Assembling transformed images\nPlease wait...')); end
                end
                obj.mibModel.setData4D('image', Iout);
                
                % aligning the model
                if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
                    Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
                    Model = cell2mat(obj.mibModel.getData4D('everything', NaN, NaN, optionsGetData));
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
                        if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 4: Assembling transformed models\nPlease wait...')); end
                    end
                    obj.mibModel.setData4D('everything', Iout, NaN, NaN, optionsGetData);
                else
                    % aligning the model layer
                    if obj.mibModel.getImageProperty('modelExist')
                        Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
                        Model = cell2mat(obj.mibModel.getData4D('model', NaN, NaN, optionsGetData));
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
                            if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 4: Assembling transformed model\nPlease wait...')); end
                        end
                        obj.mibModel.setData4D('model', Iout, NaN, NaN, optionsGetData);
                    end
                    % aligning the mask layer
                    if obj.mibModel.getImageProperty('maskExist')
                        Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
                        Model = cell2mat(obj.mibModel.getData4D('mask', NaN, NaN, optionsGetData));
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
                            if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 4: Assembling transformed mask\nPlease wait...')); end
                        end
                        obj.mibModel.setData4D('mask', Iout, NaN, NaN, optionsGetData);
                    end
                    % aligning the selection layer
                    if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                        Iout = zeros([nHeight, nWidth, numel(rbMatrix)], class(I));
                        Model = cell2mat(obj.mibModel.getData4D('selection', NaN, NaN, optionsGetData));
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
                            if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 4: Assembling transformed selection\nPlease wait...')); end
                        end
                        obj.mibModel.setData4D('selection', Iout, NaN, NaN, optionsGetData);
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
            
            if obj.BatchOpt.SaveShiftsToFile    % use preexisting parameters
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
            
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(sprintf('Aligned using %s; type=%s, mode=%s', parameters.method, parameters.TransformationType, parameters.TransformationMode));
            
            if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
            notify(obj.mibModel, 'newDataset');
            notify(obj.mibModel, 'plotImage');
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(obj.BatchOpt);
            
            if parameters.useBatchMode == 0; obj.closeWindow(); end
        end
        
        function LandmarkMultiPointColorAlignment(obj, parameters)
            % function LandmarkMultiPointColorAlignment(obj, parameters)
            % perform alignment of the selected color channel over the other color channels using multiple landmark points
            
            [Height, Width, Color, Depth, Time] = obj.mibModel.getImageMethod('getDatasetDimensions');
            optionsGetData.blockModeSwitch = 0;
            
            if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber < 6 && obj.View.handles.loadShiftsCheck.Value == 0
                errordlg(sprintf('!!! Error !!!\n\nNot enough landmark points!\nSelect the annotations tool from the segmentation panel and place annotations to mark the corresponding spots on the two color channels\n\nUse annotation text to mark the corresponding spots and the annotation value to mark the corresponding color channels: 1 for the fixed and 2 for the one that needs to be transformed'));
                if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                notify(obj.mibModel, 'stopProtocol');
                return
            end

            tic
            % define minimal number of required landmarks
            switch parameters.TransformationType
                case 'nonreflectivesimilarity'
                    minLandmarks = 2;
                case {'similarity', 'affine'}
                    minLandmarks = 3;
                case {'projective', 'pwl'}
                    minLandmarks = 4;
                case {'polynomial', 'lwm'}
                    minLandmarks = 6;
            end
            
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
            
            if loadShifts == 0
                for layer = 1:Depth
                    outputPnts = [];

                    [labelsList, labelsValue, X] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer);
                    if ~isempty(labelsList)
                        labelsList1 = labelsList(labelsValue==1);
                        X1 = X(labelsValue==1,:);
                        labelsList2 = labelsList(labelsValue==2);
                        X2 = X(labelsValue==2,:);
                        clear labelsList;
                        if numel(labelsList1) < minLandmarks; continue; end
                        if numel(labelsList2) < minLandmarks; continue; end

                        outputPnts = X1(:,2:3);     % x,y
                        X2 = X2(:,2:3);     % x,y
                        inputPnts = zeros(size(outputPnts));
                        for labelId = 1:numel(labelsList1)
                            idx = find(ismember(labelsList2, labelsList1{labelId})==1);
                            inputPnts(labelId, :) = X2(idx, :); %#ok<FNDSB>
                        end
                    end
                    if isempty(outputPnts); continue; end

                    % https://se.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html
                    if ~strcmp(parameters.TransformationType, 'polynomial')
                        tform2 = fitgeotrans(inputPnts, outputPnts, parameters.TransformationType);
                    else
                        tform2 = fitgeotrans(inputPnts, outputPnts, parameters.TransformationType, parameters.transformationDegree);
                    end
                    tformMatrix(layer) = {tform2};
                    if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 1: Extracting landmarks\nPlease wait...')); end
                end

                if exist('inputPnts', 'var')==0
                    if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
                    warndlg(sprintf('!!! Warning !!!\n\nLandmark points are missing!')); 
                    notify(obj.mibModel, 'stopProtocol');
                    return; 
                end
            end
            refImgSize = imref2d([Height, Width]);
            
            if strcmp(parameters.TransformationMode, 'cropped') == 1    % the cropped view, faster and take less memory
                for layer=1:Depth
                    if ~isempty(tformMatrix{layer})
                        I = cell2mat(obj.mibModel.getData2D('image', layer, NaN, parameters.colorCh, optionsGetData));
                        [iMatrix{layer}, rbMatrix{layer}] = imwarp(I, tformMatrix{layer}, 'cubic', 'OutputView', refImgSize, 'FillValues', double(backgroundColor));
                        
                        obj.mibModel.setData2D('image', iMatrix{layer}, layer, NaN, parameters.colorCh, optionsGetData);
                        %                             A = imread('pout.tif');
                        %                             Rin = imref2d(size(A))
                        %                             Rin.XWorldLimits = Rin.XWorldLimits-mean(Rin.XWorldLimits);
                        %                             Rin.YWorldLimits = Rin.YWorldLimits-mean(Rin.YWorldLimits);
                        %                             out = imwarp(A,Rin,tform);
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(layer/Depth, parameters.waitbar, sprintf('Step 2: Align datasets\nPlease wait...')); end
                end
            else  % the extended view
                errordlg(sprintf('Ops, not yet implemented!\n\nPlease use TransformationMode:cropped'));
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            toc;
            
            if obj.BatchOpt.SaveShiftsToFile    % use preexisting parameters
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
            
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(sprintf('Aligned using %s; type=%s, mode=%s', parameters.method, parameters.TransformationType, parameters.TransformationMode));
            
            if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
            notify(obj.mibModel, 'newDataset');
            notify(obj.mibModel, 'plotImage');
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(obj.BatchOpt);
            
            if parameters.useBatchMode == 0; obj.closeWindow(); end
        end
        
        function status = updateAutomaticOptions(obj)
            % function status = updateAutomaticOptions(obj)
            % update options (obj.automaticOptions) for the automatic alignment using detected
            % features
            %
            % Return values:
            % status: a switch whether the function was finished to the end
            % or cancelled
            
            global mibPath;
            status = 0;
            
            dlgTitle = 'Feature detection options';
            featureDetectorType = obj.View.handles.FeatureDetectorType.String{obj.View.handles.FeatureDetectorType.Value};
            options.Title = featureDetectorType;
            prompts = {...
                        sprintf('Width of the image used to detect features\ndecrease to make it faster, but compromising the precision'),...
                        sprintf('Rotation invariance')};
            defAns = {num2str(obj.automaticOptions.imgWidthForAnalysis), obj.automaticOptions.rotationInvariance};
            
            switch featureDetectorType
                case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
                    prompts{3} = sprintf('Strongest feature threshold\nto return more blobs, decrease the value of this threshold\n(a non-negative scalar)');
                    prompts{4} = sprintf('Number of octaves to implement\nincrease this value to detect larger blobs. Recommended values are between 1 and 4.\n(an integer scalar greater than or equal to 1)');
                    prompts{5} = sprintf('Number of scale levels per octave to compute\nincrease this number to detect more blobs at finer increments. Recommended values are between 3 and 6.\n(an integer scalar, greater than or equal to 3)');
                    defAns{3} = num2str(obj.automaticOptions.detectSURFFeatures.MetricThreshold);
                    defAns{4} = num2str(obj.automaticOptions.detectSURFFeatures.NumOctaves);
                    defAns{5} = num2str(obj.automaticOptions.detectSURFFeatures.NumScaleLevels);
                    options.PromptLines = [2, 1, 3, 4, 4];   % [optional] number of lines for widget titles
                    
                    options.WindowWidth = 1.6;    % make window x1.2 times wider
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    obj.automaticOptions.detectSURFFeatures.MetricThreshold = str2double(answer{3});
                    obj.automaticOptions.detectSURFFeatures.NumOctaves = str2double(answer{4});
                    obj.automaticOptions.detectSURFFeatures.NumScaleLevels = str2double(answer{5});
                case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
                    prompts{3} = sprintf('Step size between intensity threshold levels\nused in selecting extremal regions while testing for their stability. Decrease this value to return more regions\n(percent numeric value; typical: 0.8 to 4)');
                    prompts{4} = sprintf('Size of the region in pixels\nallows the selection of regions containing pixels to be between minArea and maxArea, inclusive\n(a two-element vector: minArea, maxArea)');
                    prompts{5} = sprintf('Maximum area variation between extremal regions at varying intensity thresholds\nincreasing this value returns a greater number of regions, but they may be less stable\n(a positive scalar value; typical: 0.1 to 1.0)');
                    defAns{3} = num2str(obj.automaticOptions.detectMSERFeatures.ThresholdDelta);
                    defAns{4} = num2str(obj.automaticOptions.detectMSERFeatures.RegionAreaRange);
                    defAns{5} = num2str(obj.automaticOptions.detectMSERFeatures.MaxAreaVariation);
                    options.PromptLines = [2, 1, 4, 4, 3];   % [optional] number of lines for widget titles
                    
                    options.WindowWidth = 1.7;    % make window x1.2 times wider
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    obj.automaticOptions.detectMSERFeatures.ThresholdDelta = str2double(answer{3}); % percent numeric value; step size between intensity threshold levels, decrease this value to return more regions. Typical values range from 0.8 to 4.
                    obj.automaticOptions.detectMSERFeatures.RegionAreaRange = str2num(answer{4}); %#ok<ST2NM> % two-element vector, size of the region in pixels, allows the selection of regions containing pixels between the provided range
                    obj.automaticOptions.detectMSERFeatures.MaxAreaVariation = str2double(answer{5}); % positive scalar, maximum area variation between extremal regions at varying intensity thresholds; Increasing this value returns a greater number of regions, but they may be less stable. Stable regions are very similar in size over varying intensity thresholds. Typical values range from 0.1 to 1.0.
                    
                case 'Corners: Harris-Stephens algorithm'
                    prompts{3} = sprintf('Minimum accepted quality of corners.\nThe minimum accepted quality of corners represents\na fraction of the maximum corner metric value in the image.\nLarger values can be used to remove erroneous corners\n(a scalar value in the range [0,1])');
                    prompts{4} = sprintf('Gaussian filter dimension.\nThe Gaussian filter smooths the gradient of the input image\n(an odd integer value in the range [3, min(size(I))])');
                    defAns{3} = num2str(obj.automaticOptions.detectHarrisFeatures.MinQuality);
                    defAns{4} = num2str(obj.automaticOptions.detectHarrisFeatures.FilterSize);
                    
                    options.PromptLines = [2, 3, 5, 3];   % [optional] number of lines for widget titles
                    
                    options.WindowWidth = 1.6;    % make window x1.2 times wider
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    obj.automaticOptions.detectHarrisFeatures.MinQuality = str2double(answer{3}); 
                    obj.automaticOptions.detectHarrisFeatures.FilterSize = str2double(answer{4}); 
                case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
                    prompts{3} = sprintf('Minimum intensity difference between a corner and its surrounding region.\nThe minimum contrast value represents a fraction of the maximum value\nof the image class. Increase this value to reduce the number of detected corners\n(a scalar in the range [0 1])');
                    prompts{4} = sprintf('Minimum accepted quality of corners\nrepresents a fraction of the maximum corner metric value in the image.\nIncrease this value to remove erroneous corners\n(a scalar value in the range [0,1])');
                    prompts{5} = sprintf('Number of octaves to implement.\nIncrease this value to detect larger blobs.\nWhen you set NumOctaves to 0, the function disables multiscale detection\n(an integer scalar, greater than or equal to 0, typical: from 1 to 4)');
                    defAns{3} = num2str(obj.automaticOptions.detectBRISKFeatures.MinContrast);
                    defAns{4} = num2str(obj.automaticOptions.detectBRISKFeatures.MinQuality);
                    defAns{5} = num2str(obj.automaticOptions.detectBRISKFeatures.NumOctaves);
                    options.PromptLines = [2, 3, 4, 4, 4];   % [optional] number of lines for widget titles
                    
                    options.WindowWidth = 1.6;    % make window x1.2 times wider
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    obj.automaticOptions.detectBRISKFeatures.MinContrast = str2double(answer{3}); 
                    obj.automaticOptions.detectBRISKFeatures.MinQuality = str2double(answer{4}); 
                    obj.automaticOptions.detectBRISKFeatures.NumOctaves = str2double(answer{5}); 
                case 'Corners: Features from Accelerated Segment Test (FAST)'
                    prompts{3} = sprintf('Minimum accepted quality of corners\nrepresents a fraction of the maximum corner metric value in the image.\nLarger values can be used to remove erroneous corners.\n(a scalar value in the range [0,1])');
                    prompts{4} = sprintf('Minimum intensity difference between corner and surrounding region\nrepresents a fraction of the maximum value of the image class.\nIncreasing the value reduces the number of detected corners.\n(a scalar value in the range [0,1])');
                    defAns{3} = num2str(obj.automaticOptions.detectFASTFeatures.MinQuality);
                    defAns{4} = num2str(obj.automaticOptions.detectFASTFeatures.MinContrast);
                    options.PromptLines = [2, 3, 4, 4];   % [optional] number of lines for widget titles
                    
                    options.WindowWidth = 1.6;    % make window x1.2 times wider
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    obj.automaticOptions.detectFASTFeatures.MinQuality = str2double(answer{3}); 
                    obj.automaticOptions.detectFASTFeatures.MinContrast = str2double(answer{4}); 
                case 'Corners: Minimum Eigenvalue algorithm'
                    prompts{3} = sprintf('Minimum accepted quality of corners\nrepresents a fraction of the maximum corner metric value in the image.\nLarger values can be used to remove erroneous corners.\n(a scalar value in the range [0,1])');
                    prompts{4} = sprintf('Gaussian filter dimension.\nThe Gaussian filter smooths the gradient of the input image.\n(an odd integer value in the range [3, inf])');
                    defAns{3} = num2str(obj.automaticOptions.detectMinEigenFeatures.MinQuality);
                    defAns{4} = num2str(obj.automaticOptions.detectMinEigenFeatures.FilterSize);
                    options.PromptLines = [2, 3, 4, 3];   % [optional] number of lines for widget titles
                    
                    options.WindowWidth = 1.6;    % make window x1.2 times wider
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    obj.automaticOptions.detectMinEigenFeatures.MinQuality = str2double(answer{3}); 
                    obj.automaticOptions.detectMinEigenFeatures.FilterSize = str2double(answer{4}); 
                case 'Oriented FAST and rotated BRIEF (ORB)'
                    prompts{2} = sprintf('Scale factor for image decomposition\n(an integer greater than 1)');
                    prompts{3} = sprintf('Number of decomposition levels. Increase this value to extract keypoints from the image at more levels of decomposition (an integer greater than or equal to 1)');
                    defAns{2} = num2str(obj.automaticOptions.detectORBFeatures.ScaleFactor);
                    defAns{3} = num2str(obj.automaticOptions.detectORBFeatures.NumLevels);
                    options.PromptLines = [2, 2, 2];   % [optional] number of lines for widget titles
                    
                    options.WindowWidth = 1.6;    % make window x1.2 times wider
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    obj.automaticOptions.detectORBFeatures.ScaleFactor = str2double(answer{2}); 
                    obj.automaticOptions.detectORBFeatures.NumLevels = str2double(answer{3}); 
            end
            obj.automaticOptions.imgWidthForAnalysis = str2double(answer{1}); % Width of the image used to detect features
            if ~strcmp(featureDetectorType, 'Oriented FAST and rotated BRIEF (ORB)')
                obj.automaticOptions.rotationInvariance = logical(answer{2});  % Rotation invariance flag, specified a logical scalar; When you set this property to true, the orientation of the feature vectors are not estimated and the feature orientation is set to pi/2. 
            end
            status = 1;
        end
        
        function previewFeaturesBtn_Callback(obj)
            % function previewFeaturesBtn_Callback(obj)
            % preview detected features
            
            % update automatic detection options
            status = obj.updateAutomaticOptions();
            if status == 0; return; end
            tic
            wb = waitbar(0, 'Please wait...');
            optionsGetData.blockModeSwitch = 0;
            [~, Width, ~, Depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, optionsGetData);
            colorCh = obj.View.handles.ColorChannel.Value;
            
            ratio = obj.automaticOptions.imgWidthForAnalysis/Width;
            sliceNo = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
            if sliceNo == Depth; sliceNo = sliceNo - 1; end
            waitbar(0.05, wb);
            currImg = cell2mat(obj.mibModel.getData2D('image', sliceNo, 4, colorCh, optionsGetData));
            original = imresize(currImg, ratio, 'bicubic');
            distortedImg = cell2mat(obj.mibModel.getData2D('image', sliceNo+1, 4, colorCh, optionsGetData));
            distorted = imresize(distortedImg, ratio, 'bicubic');
            waitbar(0.2, wb);
            % Detect features
            featureDetectorType = obj.View.handles.FeatureDetectorType.String{obj.View.handles.FeatureDetectorType.Value};
            switch featureDetectorType
                case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
                    detectOpt = obj.automaticOptions.detectSURFFeatures;
                    ptsOriginal  = detectSURFFeatures(original,  'MetricThreshold', detectOpt.MetricThreshold, 'NumOctaves', detectOpt.NumOctaves, 'NumScaleLevels', detectOpt.NumScaleLevels);
                    ptsDistorted = detectSURFFeatures(distorted, 'MetricThreshold', detectOpt.MetricThreshold, 'NumOctaves', detectOpt.NumOctaves, 'NumScaleLevels', detectOpt.NumScaleLevels);
                case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
                    detectOpt = obj.automaticOptions.detectMSERFeatures;
                    ptsOriginal  = detectMSERFeatures(original, 'ThresholdDelta', detectOpt.ThresholdDelta, 'RegionAreaRange', detectOpt.RegionAreaRange, 'MaxAreaVariation', detectOpt.MaxAreaVariation);
                    ptsDistorted  = detectMSERFeatures(distorted, 'ThresholdDelta', detectOpt.ThresholdDelta, 'RegionAreaRange', detectOpt.RegionAreaRange, 'MaxAreaVariation', detectOpt.MaxAreaVariation);
                case 'Corners: Harris-Stephens algorithm'
                    detectOpt = obj.automaticOptions.detectHarrisFeatures;
                    ptsOriginal  = detectHarrisFeatures(original, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                    ptsDistorted  = detectHarrisFeatures(distorted, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
                    detectOpt = obj.automaticOptions.detectBRISKFeatures;
                    ptsOriginal  = detectBRISKFeatures(original, 'MinContrast', detectOpt.MinContrast, 'MinQuality', detectOpt.MinQuality, 'NumOctaves', detectOpt.NumOctaves);
                    ptsDistorted  = detectBRISKFeatures(distorted, 'MinContrast', detectOpt.MinContrast, 'MinQuality', detectOpt.MinQuality, 'NumOctaves', detectOpt.NumOctaves);
                case 'Corners: Features from Accelerated Segment Test (FAST)'
                    detectOpt = obj.automaticOptions.detectFASTFeatures;
                    ptsOriginal  = detectFASTFeatures(original, 'MinQuality', detectOpt.MinQuality, 'MinContrast', detectOpt.MinContrast);
                    ptsDistorted  = detectFASTFeatures(distorted, 'MinQuality', detectOpt.MinQuality, 'MinContrast', detectOpt.MinContrast);   
                case 'Corners: Minimum Eigenvalue algorithm'
                    detectOpt = obj.automaticOptions.detectMinEigenFeatures;
                    ptsOriginal  = detectMinEigenFeatures(original, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                    ptsDistorted  = detectMinEigenFeatures(distorted, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                case 'Oriented FAST and rotated BRIEF (ORB)'
                    detectOpt = obj.automaticOptions.detectORBFeatures;
                    ptsOriginal  = detectORBFeatures(original,  'ScaleFactor',  detectOpt.ScaleFactor, 'NumLevels', detectOpt.NumLevels);
                    ptsDistorted = detectORBFeatures(distorted, 'ScaleFactor',  detectOpt.ScaleFactor, 'NumLevels', detectOpt.NumLevels);
            end
            waitbar(0.5, wb);
            % extract feature descriptors.
            if ~strcmp(featureDetectorType, 'Oriented FAST and rotated BRIEF (ORB)')
                [featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal, 'Upright', obj.automaticOptions.rotationInvariance);
                waitbar(0.6, wb);
                [featuresDistorted, validPtsDistorted] = extractFeatures(distorted, ptsDistorted, 'Upright', obj.automaticOptions.rotationInvariance);
            else
                [featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal);
                waitbar(0.6, wb);
                [featuresDistorted, validPtsDistorted] = extractFeatures(distorted, ptsDistorted);
            end
            waitbar(0.7, wb);
            % Match features by using their descriptors.
            indexPairs = matchFeatures(featuresOriginal, featuresDistorted);
            waitbar(0.8, wb);
             % Retrieve locations of corresponding points for each image.
            matchedOriginal  = validPtsOriginal(indexPairs(:,1));
            matchedDistorted = validPtsDistorted(indexPairs(:,2));
            waitbar(0.9, wb);
            toc
            
            % Show putative point matches.
            figure;
            showMatchedFeatures(original, distorted, matchedOriginal, matchedDistorted);
            title('Putatively matched points (including outliers)');
            waitbar(1, wb);
            delete(wb);
        end
        
        function AutomaticFeatureBasedAlignment(obj, parameters)
            % function AutomaticFeatureBasedAlignment(obj, parameters)
            % perform automatic alignment based on detected features
            global mibPath;
            
            optionsGetData.blockModeSwitch = 0;
            [Height, Width, Color, Depth, Time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, optionsGetData);
            
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
                if strcmp(parameters.backgroundColor,'black')
                    backgroundColor = 0;
                elseif strcmp(parameters.backgroundColor,'white')
                    backgroundColor = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
                else
                    backgroundColor = mean(mean(cell2mat(obj.mibModel.getData2D('image', 1, NaN, parameters.colorCh, optionsGetData))));
                end
            end
            parameters.imgWidthForAnalysis = obj.automaticOptions.imgWidthForAnalysis;  % resize image to this size to speed-up the process
            
            if loadShifts == 0
                ratio = parameters.imgWidthForAnalysis/Width;
                optionsGetData.blockModeSwitch = 0;
                currImg = cell2mat(obj.mibModel.getData2D('image', 1, 4, parameters.colorCh, optionsGetData));
                original = imresize(currImg, ratio, 'bicubic');
            
                % Detect features
                switch parameters.detectPointsType
                    case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
                        detectOpt = obj.automaticOptions.detectSURFFeatures;
                        ptsOriginal  = detectSURFFeatures(original,  'MetricThreshold', detectOpt.MetricThreshold, 'NumOctaves', detectOpt.NumOctaves, 'NumScaleLevels', detectOpt.NumScaleLevels);
                    case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
                        detectOpt = obj.automaticOptions.detectMSERFeatures;
                        ptsOriginal  = detectMSERFeatures(original, 'ThresholdDelta', detectOpt.ThresholdDelta, 'RegionAreaRange', detectOpt.RegionAreaRange, 'MaxAreaVariation', detectOpt.MaxAreaVariation);
                    case 'Corners: Harris-Stephens algorithm'
                        detectOpt = obj.automaticOptions.detectHarrisFeatures;
                        ptsOriginal  = detectHarrisFeatures(original, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                    case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
                        detectOpt = obj.automaticOptions.detectBRISKFeatures;
                        ptsOriginal  = detectBRISKFeatures(original, 'MinContrast', detectOpt.MinContrast, 'MinQuality', detectOpt.MinQuality, 'NumOctaves', detectOpt.NumOctaves);
                    case 'Corners: Features from Accelerated Segment Test (FAST)'
                        detectOpt = obj.automaticOptions.detectFASTFeatures;
                        ptsOriginal  = detectFASTFeatures(original, 'MinQuality', detectOpt.MinQuality, 'MinContrast', detectOpt.MinContrast);
                    case 'Corners: Minimum Eigenvalue algorithm'
                        detectOpt = obj.automaticOptions.detectMinEigenFeatures;
                        ptsOriginal  = detectMinEigenFeatures(original, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                    case 'Oriented FAST and rotated BRIEF (ORB)'
                        detectOpt = obj.automaticOptions.detectORBFeatures;
                        ptsOriginal  = detectORBFeatures(original, 'ScaleFactor', detectOpt.ScaleFactor, 'NumLevels', detectOpt.NumLevels);
                end
            
                % extract feature descriptors.
                if ~strcmp(parameters.detectPointsType, 'Oriented FAST and rotated BRIEF (ORB)')
                    [featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal, 'Upright', obj.automaticOptions.rotationInvariance); 
                else
                    [featuresOriginal,  validPtsOriginal]  = extractFeatures(original,  ptsOriginal);                 
                end
                % recalculate points to full resolution
                validPtsOriginal.Location = validPtsOriginal.Location / ratio;

                for layer = 2:Depth
                    distortedImg = cell2mat(obj.mibModel.getData2D('image', layer, 4, parameters.colorCh, optionsGetData));
                    distorted = imresize(distortedImg, ratio, 'bicubic');

                    % Detect features
                    switch parameters.detectPointsType
                        case 'Blobs: Speeded-Up Robust Features (SURF) algorithm'
                            ptsDistorted  = detectSURFFeatures(distorted,  'MetricThreshold', detectOpt.MetricThreshold, 'NumOctaves', detectOpt.NumOctaves, 'NumScaleLevels', detectOpt.NumScaleLevels);
                        case 'Regions: Maximally Stable Extremal Regions (MSER) algorithm'
                            ptsDistorted  = detectMSERFeatures(distorted, 'ThresholdDelta', detectOpt.ThresholdDelta, 'RegionAreaRange', detectOpt.RegionAreaRange, 'MaxAreaVariation', detectOpt.MaxAreaVariation);
                        case 'Corners: Harris-Stephens algorithm'
                            ptsDistorted  = detectHarrisFeatures(distorted, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                        case 'Corners: Binary Robust Invariant Scalable Keypoints (BRISK)'
                            ptsDistorted  = detectBRISKFeatures(distorted, 'MinContrast', detectOpt.MinContrast, 'MinQuality', detectOpt.MinQuality, 'NumOctaves', detectOpt.NumOctaves);
                        case 'Corners: Features from Accelerated Segment Test (FAST)'
                            ptsDistorted  = detectFASTFeatures(distorted, 'MinQuality', detectOpt.MinQuality, 'MinContrast', detectOpt.MinContrast);
                        case 'Corners: Minimum Eigenvalue algorithm'
                            ptsDistorted  = detectMinEigenFeatures(distorted, 'MinQuality', detectOpt.MinQuality, 'FilterSize', detectOpt.FilterSize);
                        case 'Oriented FAST and rotated BRIEF (ORB)'
                            ptsDistorted  = detectORBFeatures(distorted, 'ScaleFactor', detectOpt.ScaleFactor, 'NumLevels', detectOpt.NumLevels);                        
                    end

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

                    % Retrieve locations of corresponding points for each image.
                    matchedOriginal  = validPtsOriginal(indexPairs(:,1));
                    matchedDistorted = validPtsDistorted(indexPairs(:,2));

                    if size(matchedOriginal, 1) < 3
                        warndlg(sprintf('!!! Warning !!!\n\nThe number of detected points is not enough (slice number: %d) for the alignement\ntry to change the point detection settings to produce more points', layer-1));
                        if obj.BatchOpt.showWaitbar; delete(parameters.waitbar); end
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
                    [tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
                        matchedDistorted, matchedOriginal, parameters.TransformationType);

                    % recalculate transformations
                    % https://se.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html
                    if isempty(tformMatrix{layer})
                        tformMatrix(layer:end) = {tform};
                    else
                        tform.T = tform.T*tformMatrix{layer}.T;
                        tformMatrix(layer:end) = {tform};
                    end
                    % rearrange Distorted to Original
                    featuresOriginal = featuresDistorted;
                    validPtsOriginal = validPtsDistorted;

                    if obj.BatchOpt.showWaitbar; waitbar(layer/(Depth*2), parameters.waitbar, sprintf('Step 1: matching the points\nPlease wait...')); end
                end
            
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
            
%             % fix stretching with running average
%             halfwidth = 25;
%             % testing running average
%             x_stretch2 = x_stretch-windv(x_stretch, halfwidth)+1;   % stretch should be 1 when no changes
%             y_stretch2 = y_stretch-windv(y_stretch, halfwidth)+1;
%             x_shear2 = x_shear-windv(x_shear, halfwidth);        % shear should be 0 when no changes
%             y_shear2 = y_shear-windv(y_shear, halfwidth);
%             for i=2:vec_length
%                 tformMatrix{i}.T(1,1) = x_stretch2(i-1);
%                 tformMatrix{i}.T(2,2) = y_stretch2(i-1);
%                 tformMatrix{i}.T(2,1) = x_shear2(i-1);
%                 tformMatrix{i}.T(1,2) = y_shear2(i-1);
%             end
            
            % ----------------------------------------------
            % start the transformation procedure
            % ----------------------------------------------
            end
            
            refImgSize = imref2d([Height, Width]);  % reference image size
            
            if strcmp(parameters.TransformationMode, 'cropped') == 1    % the cropped view, faster and take less memory
                for layer=2:Depth
                    if ~isempty(tformMatrix{layer})
                        I = cell2mat(obj.mibModel.getData2D('image', layer, 4, NaN, optionsGetData));
                        [iMatrix{layer}, rbMatrix{layer}] = imwarp(I, tformMatrix{layer}, 'cubic', 'OutputView', refImgSize, 'FillValues', double(backgroundColor));
                        obj.mibModel.setData2D('image', iMatrix{layer}, layer, 4, NaN, optionsGetData);
                        %                             A = imread('pout.tif');
                        %                             Rin = imref2d(size(A))
                        %                             Rin.XWorldLimits = Rin.XWorldLimits-mean(Rin.XWorldLimits);
                        %                             Rin.YWorldLimits = Rin.YWorldLimits-mean(Rin.YWorldLimits);
                        %                             out = imwarp(A,Rin,tform);
                        
                        if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
                            I = cell2mat(obj.mibModel.getData2D('everything', layer, 4, NaN, optionsGetData));
                            I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                            obj.mibModel.setData2D('everything', I, layer, 4, NaN, optionsGetData);
                        else
                            if obj.mibModel.getImageProperty('modelExist')
                                I = cell2mat(obj.mibModel.getData2D('model', layer, 4, NaN, optionsGetData));
                                I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                                obj.mibModel.setData2D('model', I, layer, 4, NaN, optionsGetData);
                            end
                            if obj.mibModel.getImageProperty('maskExist')
                                I = cell2mat(obj.mibModel.getData2D('mask', layer, 4, NaN, optionsGetData));
                                I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                                obj.mibModel.setData2D('mask', I, layer, 4, NaN, optionsGetData);
                            end
                            if  ~isnan(obj.mibModel.I{obj.mibModel.Id}.selection{1}(1))
                                I = cell2mat(obj.mibModel.getData2D('selection', layer, 4, NaN, optionsGetData));
                                I = imwarp(I, tformMatrix{layer}, 'nearest', 'OutputView', refImgSize, 'FillValues', 0);
                                obj.mibModel.setData2D('selection', I, layer, 4, NaN, optionsGetData);
                            end
                        end
                        
                        % transform annotations
                        [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(layer);
                        if ~isempty(labelsList)
                            [labelPositions(:,2), labelPositions(:,3)] = transformPointsForward(tformMatrix{layer}, labelPositions(:,2), labelPositions(:,3));
                            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(indices, labelsList, labelPositions, labelValues);
                        end
                    end
                    if obj.BatchOpt.showWaitbar; waitbar((layer+Depth)/(Depth*2), parameters.waitbar, sprintf('Step 2: Align datasets\nPlease wait...')); end
                end
            else  % the extended view
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
                logText = sprintf('Aligned using %s; relative to %d, type=%s, mode=%s, points=%s, imgWidth=%d, rotation=%d', parameters.method, parameters.refFrame, parameters.TransformationType, parameters.TransformationMode, parameters.detectPointsType, parameters.imgWidthForAnalysis, 1-obj.automaticOptions.rotationInvariance);
                if strcmp(fixDrifts2, 'Subtract running average')
                    logText = sprintf('%s, runaverage:%d, fixstretch:%d fix-shear:%d', logText, halfwidth, answer{1}, answer{2});
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
            
            if parameters.useBatchMode == 0; obj.closeWindow(); end
        end
        
    end
end

