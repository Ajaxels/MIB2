classdef mibMembraneDetectionController < handle
    % @type mibMembraneDetectionController class is resposnible for showing the Membrane Detection window,
    % available from MIB->Menu->Tools->Classifiers->Membrane detections
    
	% Copyright (C) 14.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        classFilename
        % filename for classifier
        dirOut
        % output directory
        maxNumberOfSamplesPerClass
        % max Number Of Samples Per Class
        forest
        % structure with classifier info
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibMembraneDetectionController(mibModel, parameter)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibMembraneDetectionGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.text1.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            % set some default parameters
            obj.maxNumberOfSamplesPerClass = 500;
            obj.forest = [];
            
            obj.dirOut = fullfile(obj.mibModel.myPath, 'RF_Temp');
            [~, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.classFilename = fullfile(obj.dirOut, [fn '.forest']);
            
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibMembraneDetectionController window
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
            
            list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;   % list of materials
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 || numel(list) < 2
                errordlg(sprintf('!!! Error !!!\n\nA model with at least two materials is needed to proceed further!\n\nPlease create a new model with two materials - one for the objects and another one for the background. After that try again!\n\nPlease also refer to the Help section for details'),...
                    'Missing the model', 'modal');
                obj.View.handles.trainClassifierBtn.Enable = 'off';
                obj.View.handles.predictSlice.Enable = 'off';
                list = {'Add 2 Materials to the model!'};
            end
            
            % populating material lists
            val = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();   % -1 mask, 0-bg, 1,2,3 - materials
            obj.View.handles.objectPopup.Value = max([val 1]);
            obj.View.handles.objectPopup.String = list;
            val = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo');    % -1 mask, 0-bg, 1,2,3 - materials
            obj.View.handles.backgroundPopup.Value = max([val 1]);
            obj.View.handles.backgroundPopup.String = list;
            
            % populating directories
            obj.View.handles.tempDirEdit.String = obj.dirOut;
            obj.View.handles.classifierFilenameEdit.String = obj.classFilename;
        end
        
        function tempDirEdit_Callback(obj)
            % function tempDirEdit_Callback(obj)
            % callback for selection of the output directory
            path = obj.View.handles.tempDirEdit.String;
            if ~isdir(path)
                mkdir(path);
                %obj.View.handles.tempDirEdit.String = obj.dirOut;
                obj.dirOut = path;
            else
                obj.dirOut = path;
            end
        end
        
        function tempDirSelectBtn_Callback(obj)
            % function tempDirSelectBtn_Callback(obj)
            % callback for selection of the output directory
            
            currTempPath = obj.dirOut;
            currTempPath = uigetdir(currTempPath, 'Select temp directory');
            if currTempPath == 0; return; end;   % cancel
            obj.View.handles.tempDirEdit.String = currTempPath;
            obj.tempDirEdit_Callback();
        end
        
        function classifierFilenameEdit_Callback(obj)
            % function classifierFilenameEdit_Callback(obj)
            % callback for selection of the classifier filename
            obj.classFilename = obj.View.handles.classifierFilenameEdit.String;
        end
        
        function classifierFilenameBtn_Callback(obj)
            % function classifierFilenameEdit_Callback(obj)
            % callback for selection of the classifier filename
            [FileName, PathName] = uigetfile('*.forest', 'Select filename for classifier', obj.classFilename);
            if isequal(FileName, 0)
                return;
            end
            obj.View.handles.classifierFilenameEdit.String = fullfile(PathName, FileName);
            obj.classifierFilenameEdit_Callback();
        end
        
        function updateLoglist(obj, addText)
            % function updateLoglist(obj, addText)
            % update the log list with status events reported by the
            % function
            
            status = obj.View.handles.logList.String;
            c = clock;
            if isempty(status)
                status = {sprintf('%d:%02i:%02i  %s', c(4), c(5), round(c(6)), addText)};
            else
                status(end+1) = {sprintf('%d:%02i:%02i  %s', c(4), c(5), round(c(6)), addText)};
            end
            obj.View.handles.logList.String = status;
            obj.View.handles.logList.Value = numel(status);
            drawnow;
        end
        
        function wipeTempDirBtn_Callback(obj)
            % function wipeTempDirBtn_Callback(obj)
            % callback for press wipeTempDirBtn; wipe temp directory
            
            if exist(obj.dirOut, 'dir') ~= 0     % remove directory
                button =  questdlg(sprintf('!!! Warning !!!\n\nThe whole directory:\n\n%s\n\nwill be deleted!!!\n\nAre you sure?', obj.dirOut),....
                    'Delete directory?', 'Delete', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel')
                    obj.updateLoglist('Wipe Temp directory: Canceled!');
                    return;
                end
                rmdir(obj.dirOut, 's');
                obj.updateLoglist('Temp directory was deleted');
            end
        end
        
        function trainClassifierBtn_Callback(obj)
            % function trainClassifierBtn_Callback(obj)
            % callback for press of trainClassifierBtn
            
            obj.View.handles.trainClassifierBtn.BackgroundColor = [1 0 0];
            if obj.View.handles.trainClassifierToggle.Value
                obj.trainClassifier();
            elseif obj.View.handles.predictDatasetToggle.Value
                obj.predictDataset();
            end
            obj.View.handles.trainClassifierBtn.BackgroundColor = [0 1 0];
        end
        
        function predictSlice_Callback(obj)
            % function predictSlice_Callback(obj)
            % callback for predictSlice; predict the current slice
            
            obj.View.handles.predictSlice.BackgroundColor = [1 0 0];
            sliceNo = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
            obj.predictDataset(sliceNo);
            obj.View.handles.predictSlice.BackgroundColor = [0 1 0];
        end
        
        function saveClassifierBtn_Callback(obj)
            % function saveClassifierBtn_Callback(obj)
            % callback for press of saveClassifierBtn; save classifier to
            % disk
            
            obj.View.handles.logList.String = '';
            obj.updateLoglist('======= Saving classifier... =======');
            outFile = obj.classFilename;
            
            if exist(outFile,'file')== 2     % make directory
                obj.updateLoglist('The classifier already exist!');
                button =  questdlg(sprintf('!!! Warning !!!\n\nThe file already exist!\n\nOverwrite?'),....
                    'Overwrite existing forest?', 'Overwrite', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel')
                    obj.updateLoglist('Save classifier: Canceled!');
                    return;
                end
                obj.updateLoglist('Save classifier: Overwriting...');
            end
            if isempty(obj.forest)
                errordlg(sprintf('!!! Error !!!\n\nThe classifier is not created yet!\nTry to train the classifer first!'),'Missing the classifier');
                obj.updateLoglist('Save classifier: The classifier is not created yet!');
                return;
            end
            forest = obj.forest; %#ok<PROP,NASGU>
            
            save(outFile, 'forest', '-mat','-v7.3');
            obj.updateLoglist('The classifier was saved!');
            obj.updateLoglist(outFile);
        end
        
        function trainClassifier(obj)
            % function trainClassifier(obj)
            % train random forest
            % based on skript_trainClassifier_for_membraneDetection.m by Verena Kaynig
            
            obj.View.handles.logList.String = '';
            obj.updateLoglist('======= Starting training... =======');
            
            obj.mibModel.mibDoBackup('selection', 1);    % store selection layer
            
            cs = str2double(obj.View.handles.contextSizeEdit.String);     % context size
            ms = str2double(obj.View.handles.membraneThicknessEdit.String);     % membrane thickness
            csHist = cs;  % context Size Histogram
            posModel = obj.View.handles.objectPopup.Value;
            negModel = obj.View.handles.backgroundPopup.Value;
            
            % check whether the blockmode is enabled
            blockModeSwitch = 0;
            if obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch == 1
                blockModeSwitch = 1;
                [yMinShown, yMaxShown, xMinShown, xMaxShown] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage();
            end
            votesThreshold = str2double(obj.View.handles.votesThresholdEdit.String);
            tempDir = obj.dirOut;
            if exist(tempDir, 'dir') == 0     % make directory
                mkdir(tempDir);
            end
            
            t1 = tic;
            extraOptions.blockModeSwitch = 0;
            model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, NaN, extraOptions));
            fmPos = [];
            fmNeg = [];
            slicesForTraining = zeros([size(model,3),1]);   % vector to keep slices for the training.
            for sliceNo=1:size(model, 3)
                % find slices with model
                if isempty(find(model(:,:,sliceNo) == posModel,1)) && isempty(find(model(:,:,sliceNo) == negModel,1))
                    continue;
                end
                slicesForTraining(sliceNo) = 1;     % indicate that this slice was used for the training
                % check whether the membrane feature file exist
                featuresFilename = fullfile(tempDir, sprintf('slice_%06i.fm', sliceNo));     % filename for features
                if ~exist(featuresFilename, 'file')
                    obj.updateLoglist(sprintf('Extracting membrane features for slice: %d...', sliceNo));
                    im = cell2mat(obj.mibModel.getData2D('image', sliceNo, NaN, NaN, extraOptions)); % get image
                    
                    % generate membrane features:
                    % fm(:,:,1) -> orig image
                    % fm(:,:,2:5) -> 1-90 degrees
                    % fm(:,:,6) -> minimal values of all degrees
                    % fm(:,:,7) -> maximal values of all degrees
                    % fm(:,:,8) -> mean values of all degrees
                    % fm(:,:,9) -> variance values of all degrees
                    % fm(:,:,10) -> median values of all degrees
                    % fm(:,:,11:14) -> 90-180 degrees
                    % fm(:,:,17:26) -> 10-bin histogram of a context area at each point of the image
                    % fm(:,:,27) -> mean value of a context area at each point of the image
                    % fm(:,:,28) -> variance (?) value of a context area at each point of the image
                    % fm(:,:,29) -> maximal - minimal values for all degrees
                    % the following are repeats of
                    % fm(:,:,30) -> smoothed original image, sigma = 1
                    % fm(:,:,31) -> smoothed eig1/eig2, sigma = 1
                    % fm(:,:,32) -> smoothed magnitude, sigma = 1
                    % fm(:,:,33) -> magnitude, sigma = 1
                    % fm(:,:,34-37) -> repeat 30-33, with sigma=2
                    % fm(:,:,38-41) -> repeat 30-33, with sigma=3
                    % fm(:,:,42) -> 38 -minus- smoothed original image with sigma=1
                    % fm(:,:,43-46) -> repeat 30-33, with sigma=4
                    % fm(:,:,47) -> 43 -minus- smoothed original image with sigma=1
                    % ...
                    % fm(:,:,89) -> end of that cycle
                    % fm(:,:,90) -> variance of last 10 entries in the fm
                    % fm(:,:,91) -> normalized smoothed orig.image sigma=2 - smoothed orig.image sigma=50
                    % fm(:,:,92) -> original image
                    
                    fm  = membraneFeatures(im, cs, ms, csHist);
                    
                    %         % test fm
                    %         fm  = membraneFeatures(im, 15, 2, 15);
                    %         fmout = zeros(size(fm),'uint8');
                    %         for i=1:size(fm,3)
                    %             fmout(:,:,i) = uint8(fm(:,:,i)/max(max(fm(:,:,i)))*255);
                    %         end
                    
                    
                    
                    fm(isnan(fm)) = 0;
                    save(featuresFilename, 'fm', '-mat', '-v7.3');
                else
                    load(featuresFilename, 'fm', '-mat');    % load membrane features
                end
                
                obj.updateLoglist(sprintf('Adding features from slice: %d...', sliceNo));
                posPos = find(model(:,:,sliceNo) == posModel);
                posNeg = find(model(:,:,sliceNo) == negModel);
                
                fm = reshape(fm, size(fm, 1)*size(fm, 2),size(fm, 3));  % convert x,y -> to vector
                fmPos = [fmPos; fm(posPos,:)];  % get features for positive points, combine with another training slice
                fmNeg = [fmNeg; fm(posNeg,:)];  % get features for negative points
            end
            clear fm;
            clear posPos;
            clear posNeg;
            
            obj.updateLoglist('======= Training the classifier... =======');
            y = [zeros(size(fmNeg,1),1); ones(size(fmPos,1),1)];     % generate a vector that defines positive and negative values
            x = double([fmNeg; fmPos]);  % generate a matrix with combined membrane features
            
            extra_options.sampsize = [obj.maxNumberOfSamplesPerClass, obj.maxNumberOfSamplesPerClass];
            obj.forest = classRF_train(x, y, 300, 5, extra_options);    % train classifier
            
            for sliceNo = find(slicesForTraining==1)'
                featuresFilename = fullfile(tempDir, sprintf('slice_%06i.fm', sliceNo));     % filename for features
                obj.updateLoglist(sprintf('Predicting slice: %d...', sliceNo));
                load(featuresFilename, 'fm', '-mat');    % load membrane features
                
                if blockModeSwitch  % crop fm if the block mode is enabled
                    fm = fm(yMinShown:yMaxShown, xMinShown:xMaxShown, :);
                end
                imsize = [size(fm,1), size(fm,2)];
                fm = reshape(fm,size(fm,1)*size(fm,2),size(fm,3));
                
                %im = handles.h.Img{handles.h.Id}.I.getSlice('image',sliceNo); % get image
                %im = uint8Img(im); % convert to uint8 and scale from 0 to 255
                % imsize = size(im);
                % clear im
                
                clear y;
                
                votes = zeros(imsize(1)*imsize(2),1);
                [y_h, v] = classRF_predict(double(fm), obj.forest);
                votes = v(:,2);
                votes = reshape(votes,imsize);
                votes = double(votes)/max(votes(:));
                
                % store votes for the export
                if obj.View.handles.exportVotesCheck.Value
                    if exist('votesOut', 'var') == 0
                        votesOut = zeros([imsize(1), imsize(2), 1, numel(find(slicesForTraining==1))]);
                        voteIndex = 1;
                    end
                    votesOut(:,:,1, voteIndex) = votes;
                    voteIndex = voteIndex + 1;
                end
                
                if obj.View.handles.skelClosedCheck.Value
                    skelImg = uint8(bwmorph(skeletonize(votes >= votesThreshold), 'dilate', 1));
                else
                    skelImg = uint8(votes > votesThreshold);
                end
                obj.mibModel.setData2D('selection', skelImg, sliceNo);
            end;
            
            if obj.View.handles.exportVotesCheck.Value
                obj.updateLoglist('======= Exporting votes to matlab =======');
                assignin('base', 'mibVotes', votesOut);
                obj.updateLoglist('Done! variable -> mibVotes(1:height, 1:width, 1, 1:slices)');
            end
            obj.updateLoglist('======= Training finished! =======');
            resultTOC = toc(t1);
            obj.updateLoglist(sprintf('Elapsed time is %f seconds.',resultTOC));
            notify(obj.mibModel, 'plotImage');
        end
        
        function predictDataset(obj, sliceNumber)
            % function predictDataset(obj, sliceNumber)
            % predict dataset using the random forest classifier
            %
            % Parameters:
            % sliceNumber: [@em optional] number of slice for prediction
            
            if nargin < 2
                [height, width, color, thick] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4);
                startSlice = 1;
                finishSlice = thick;
            else
                startSlice = sliceNumber;
                finishSlice = sliceNumber;
                thick = 1;
            end
            
            obj.View.handles.logList.String = '';
            obj.updateLoglist('======= Starting prediction... =======');
            
            obj.mibModel.mibDoBackup('selection', 1);    % store selection layer
            
            cs = str2double(obj.View.handles.contextSizeEdit.String);     % context size
            ms = str2double(obj.View.handles.membraneThicknessEdit.String);     % membrane thickness
            csHist = cs;  % context Size Histogram
            
            % check whether the blockmode is enabled
            blockModeSwitch = 0;
            if obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch == 1
                blockModeSwitch = 1;
                [yMinShown, yMaxShown, xMinShown, xMaxShown] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage();
            end
            votesThreshold = str2double(obj.View.handles.votesThresholdEdit.String);
            tempDir = obj.dirOut;
            if exist(tempDir,'dir') == 0     % make directory
                mkdir(tempDir);
            end
            
            t1 = tic;
            extra_options.sampsize = [obj.maxNumberOfSamplesPerClass, obj.maxNumberOfSamplesPerClass];
            
            inFile = obj.classFilename;
            obj.updateLoglist('Loading classifier...');
            obj.updateLoglist(inFile);
            if exist(inFile, 'file') == 0
                errordlg(sprintf('!!! Error !!!\n\nThe classifier file was not found!\nTry to train the classifer and save it to a file'),...
                    'Missing the classifier');
                obj.updateLoglist('The classifier was not found!');
                return;
            end
            load(inFile, '-mat');
            obj.forest = forest;
            clear forest;
            obj.updateLoglist('Classifier loaded!');
            getDataOptions.blockModeSwitch = 0;
            for sliceNo = startSlice:finishSlice
                featuresFilename = fullfile(tempDir, sprintf('slice_%06i.fm', sliceNo));     % filename for features
                
                % check whether the feature file already exist
                if ~exist(featuresFilename, 'file')
                    obj.updateLoglist(sprintf('Extracting membrane features for slice: %d...', sliceNo));
                    im = cell2mat(obj.mibModel.getData2D('image', sliceNo, NaN, NaN, getDataOptions)); % get image
                    % generate membrane features:
                    % fm(:,:,1) -> orig image
                    % fm(:,:,2:5) -> 1-90 degrees
                    % fm(:,:,6) -> minimal values of all degrees
                    % fm(:,:,7) -> maximal values of all degrees
                    % fm(:,:,8) -> mean values of all degrees
                    % fm(:,:,9) -> variance values of all degrees
                    % fm(:,:,10) -> median values of all degrees
                    % fm(:,:,11:14) -> 90-180 degrees
                    % fm(:,:,17:26) -> 10-bin histogram of a context area at each point of the image
                    % fm(:,:,27) -> mean value of a context area at each point of the image
                    % fm(:,:,28) -> variance (?) value of a context area at each point of the image
                    % fm(:,:,29) -> maximal - minimal values for all degrees
                    % the following are repeats of
                    % fm(:,:,30) -> smoothed original image, sigma = 1
                    % fm(:,:,31) -> smoothed eig1/eig2, sigma = 1
                    % fm(:,:,32) -> smoothed magnitude, sigma = 1
                    % fm(:,:,33) -> magnitude, sigma = 1
                    % fm(:,:,34-37) -> repeat 30-33, with sigma=2
                    % fm(:,:,38-41) -> repeat 30-33, with sigma=3
                    % fm(:,:,42) -> 38 -minus- smoothed original image with sigma=1
                    % fm(:,:,43-46) -> repeat 30-33, with sigma=4
                    % fm(:,:,47) -> 43 -minus- smoothed original image with sigma=1
                    % ...
                    % fm(:,:,89) -> end of that cycle
                    % fm(:,:,90) -> variance of last 10 entries in the fm
                    % fm(:,:,91) -> normalized smoothed orig.image sigma=2 - smoothed orig.image sigma=50
                    % fm(:,:,92) -> original image
                    
                    fm  = membraneFeatures(im, cs, ms, csHist);
                    fm(isnan(fm)) = 0;
                    save(featuresFilename, 'fm', '-mat','-v7.3');
                else
                    load(featuresFilename, 'fm', '-mat');    % load membrane features
                end
                
                obj.updateLoglist(sprintf('Predicting slice: %d...', sliceNo));
                if blockModeSwitch  % crop fm if the block mode is enabled
                    fm = fm(yMinShown:yMaxShown, xMinShown:xMaxShown, :);
                end
                imsize = [size(fm,1), size(fm,2)];
                fm = reshape(fm,size(fm,1)*size(fm,2),size(fm,3));
                
                votes = zeros(imsize(1)*imsize(2),1);
                [y_h, v] = classRF_predict(double(fm), obj.forest);
                votes = v(:,2);
                votes = reshape(votes, imsize);
                votes = double(votes)/max(votes(:));
                
                % store votes for the export
                if obj.View.handles.exportVotesCheck.Value
                    if exist('votesOut', 'var') == 0
                        votesOut = zeros([imsize(1), imsize(2), 1, thick]);
                        voteIndex = 1;
                    end
                    votesOut(:,:,1, voteIndex) = votes;
                    voteIndex = voteIndex + 1;
                end
                
                if obj.View.handles.skelClosedCheck.Value
                    skelImg = uint8(bwmorph(skeletonize(votes >= votesThreshold), 'dilate', 1));
                else
                    skelImg = uint8(votes > votesThreshold);
                end
                obj.mibModel.setData2D('selection', skelImg, sliceNo);
            end
            
            if obj.View.handles.exportVotesCheck.Value
                obj.updateLoglist('======= Exporting votes to matlab =======');
                assignin('base', 'mibVotes', votesOut);
                obj.updateLoglist('Done! variable -> mibVotes(1:height, 1:width, 1, 1:slices)');
            end
            obj.updateLoglist('======= Prediction finished! =======');
            resultTOC = toc(t1);
            obj.updateLoglist(sprintf('Elapsed time is %f seconds.',resultTOC));
            notify(obj.mibModel, 'plotImage');
        end
    end
end