classdef mibSupervoxelClassifierController < handle
    % @type mibSupervoxelClassifierController class is resposnible for showing the supervoxel classifier,
    % available from MIB->Menu->Tools->Classifiers->Supervoxel
    % classification
    
	% Copyright (C) 28.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        maxNumberOfSamplesPerClass
        % max number of samples per class
        slic
        % a structure with processed slic images
        % .slic = [];     % a field for superpixels, [height, width, depth]
        % .noPix = [];    % a field for number of pixels, [depth] for 2d, or a single number for 3d
        % .properties = [];   % a substructure with properties, only for obj.slic.properties(1)
        %   .properties.bb [xMin xMax yMin yMax zMin zMax]
        %   .properties.mode '2d' or '3d'
        %   .properties.binVal, binning values: (xy z)
        %   .properties.colCh, a color channel used for SLIC
        %   .properties.spSize, size of superpixels
        %   .properties.spCompact, compactness of superpixels
        FEATURES
        % a structure for features
        Forest
        % classifier
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
        function obj = mibSupervoxelClassifierController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibSupervoxelClassifierGUI';
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
            
            obj.slic.slic = [];     % a field for superpixels, [height, width, depth]
            obj.slic.noPix = [];    % a field for number of pixels, [depth] for 2d, or a single number for 3d
            obj.slic.properties = [];   % a substructure with properties, only for handles.slic.properties(1)
                                %   .bb [xMin xMax yMin yMax zMin zMax]
                                %   .mode '2d' or '3d'
                                %   .binVal, binning values: (xy z)
                                %   .colCh, a color channel used for SLIC
                                %   .spSize, size of superpixels
                                %   .spCompact, compactness of superpixels
                                
            obj.FEATURES = [];      % a structure for features
            obj.Forest = [];        % classifier
                 
            % populating directories
            dirOut = fullfile(obj.mibModel.myPath, 'RF_Temp');
            obj.View.handles.tempDirEdit.String = dirOut;
            if exist(dirOut, 'dir') == 0
                res = questdlg('Use the following dialog to select a directory to store temporary data',...
                    'Select directory', 'Continue', 'Cancel', 'Continue');
                if strcmp(res,'Cancel')
                    obj.closeWindow();
                    return;
                end
                obj.tempDirSelectBtn_Callback();
                dirOut = obj.View.handles.tempDirEdit.String;
            end
            [~, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.classifierFilenameEdit.String = fn;
            obj.classifierFilenameEdit_Callback();
            
            list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;   % list of materials
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 || numel(list) < 2
                warndlg(sprintf('!!! Warning !!!\n\nFor a new training a model with at least two materials is needed to proceed further!\n\nPlease create a new model with two materials - one for the objects and another one for the background. After that try again!\n\nIf the classifier was trained earlier, it can be loaded in the Train & Predict section\n\nPlease also refer to the Help section for details'),...
                    'Missing the model', 'modal');
                obj.View.handles.trainClassifierBtn.Enable = 'off';
                obj.View.handles.predictSlice.Enable = 'off';
            end
            
            obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibSupervoxelClassifierController window
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
            
            % switch off the block mode
            if obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch
                warndlg(sprintf('!!! Warning !!!\n\nThe block mode will be disabled!'), 'Switch off the block mode');
                obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch = 0;
                notify(obj.mibModel, 'updateGuiWidgets');
            end
            
            list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;   % list of materials
            
            if isempty(list)
                obj.View.handles.objectPopup.Value = 1;
                obj.View.handles.objectPopup.String = 'require 2 materials';
                obj.View.handles.objectPopup.BackgroundColor = 'r';
                obj.View.handles.backgroundPopup.Value = 1;
                obj.View.handles.backgroundPopup.String = 'require 2 materials';
                obj.View.handles.backgroundPopup.BackgroundColor = 'r';
                obj.View.handles.trainClassifierBtn.Enable = 'off';
                obj.View.handles.predictSlice.Enable = 'off';
            else
                % populating material lists
                obj.View.handles.backgroundPopup.String = list;
                obj.View.handles.backgroundPopup.Value = 1;
                
                val = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo');    % -1 mask; 0 bg; 1,2,3-materials
                obj.View.handles.objectPopup.String = list;
                obj.View.handles.objectPopup.Value = max([val 1]);
                obj.View.handles.backgroundPopup.BackgroundColor = 'w';
                obj.View.handles.objectPopup.BackgroundColor = 'w';
                
                if numel(list) < 2
                    obj.View.handles.trainClassifierBtn.Enable = 'off';
                    obj.View.handles.predictSlice.Enable = 'off';
                else
                    obj.View.handles.trainClassifierBtn.Enable = 'on';
                    obj.View.handles.predictSlice.Enable = 'on';
                end
            end
            
            if obj.mibModel.I{obj.mibModel.Id}.depth < 2
                obj.View.handles.mode3dRadio.Enable = 'off';
                obj.View.handles.mode2dRadio.Value = 1;
            else
                obj.View.handles.mode3dRadio.Enable = 'on';
            end
            
            % updating color channels
            colorsNo = obj.mibModel.getImageProperty('colors');
            colCh = cell([colorsNo, 1]);
            for i=1:colorsNo
                colCh{i} = sprintf('Ch %d', i);
            end
            if colorsNo < obj.View.handles.imageColChPopup.Value
                obj.View.handles.imageColChPopup.Value = 1;
            end;
            obj.View.handles.imageColChPopup.String = colCh;
            
            % populate subarea edit boxes
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', 1, width);
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', 1, height);
            obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', 1, depth);
        end
        
        function tempDirSelectBtn_Callback(obj)
            % function tempDirSelectBtn_Callback(obj)
            % select directory for temp data
            
            currTempPath = obj.View.handles.tempDirEdit.String;
            if exist(currTempPath, 'dir') == 0     % make directory
                mkdir(currTempPath);
            end
            currTempPath = uigetdir(currTempPath, 'Select temp directory');
            if currTempPath == 0; return; end;   % cancel
            obj.View.handles.tempDirEdit.String = currTempPath;
        end
        
        function classifierFilenameEdit_Callback(obj)
            % function classifierFilenameEdit_Callback(obj)
            % callback for modification of filename for classifier
            
            obj.slic.slic = [];     % a field for superpixels, [height, width, depth]
            obj.slic.noPix = [];    % a field for number of pixels, [depth] for 2d, or a single number for 3d
            obj.slic.properties = [];   % a substructure with properties, only for handles.slic.properties(1)
            %   .bb [xMin xMax yMin yMax zMin zMax]
            %   .mode '2d' or '3d'
            %   .slicSuperpixelsRadio 1-SLIC,0-Watershed
            %   .binVal, binning values: (xy z)
            %   .colCh, a color channel used for SLIC
            obj.FEATURES = [];      % a structure for features
            obj.Forest = [];        % classifier
            
            dirOut = obj.View.handles.tempDirEdit.String;
            fn = obj.View.handles.classifierFilenameEdit.String;
            fn = fullfile(dirOut, [fn '.slic']);     % filename with superpixels
            if exist(fn, 'file') ~= 0
                res = questdlg(sprintf('!!! Warning !!!\n\nAn old project was found!\nProject name:\n%s\n\nLoad its settings and superpixels?', fn),...
                    'Load settings', 'Load', 'Cancel', 'Load');
                if strcmp(res,'Load')
                    load(fn, '-mat');
                    obj.slic = localSlic; %#ok<CPROP>
                    
                    clear slic;
                    
                    % update Subarea editboxes
                    obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(1), obj.slic.properties(1).bb(2));
                    obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(3), obj.slic.properties(1).bb(4));
                    obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(5), obj.slic.properties(1).bb(6));
                    obj.View.handles.binSubareaEdit.String = sprintf('%d;%d', obj.slic.properties(1).binVal(1), obj.slic.properties(1).binVal(2));
                    obj.View.handles.imageColChPopup.Value = obj.slic.properties(1).colCh;
                    if strcmp(obj.slic.properties(1).mode, '3d')
                        obj.View.handles.mode3dRadio.Value = 1;
                    end
                    if obj.slic.properties(1).slicSuperpixelsRadio == 1
                        obj.View.handles.slicSuperpixelsRadio.Value = 1;
                        obj.View.handles.watershedSuperpixelsRadio.Value = 0;
                    else
                        obj.View.handles.slicSuperpixelsRadio.Value = 0;
                        obj.View.handles.watershedSuperpixelsRadio.Value = 1;
                    end
                    obj.superpixelTypeRadio_Callback();
                    obj.View.handles.superpixelEdit.String = num2str(obj.slic.properties(1).spSize);
                    obj.View.handles.superpixelsCompactEdit.String = num2str(obj.slic.properties(1).spCompact);
                end
            end
        end
        
        function updateLoglist(obj, addText)
            % function updateLoglist(obj, addText)
            % update log list with information about the progress
            %
            % Parameters:
            % addText: a string with the text to show in the log list
            
            status = obj.View.handles.logList.String;
            c = clock;
            if isempty(status)
                status = {sprintf('%d:%02i:%02i  %s', c(4), c(5), round(c(6)), addText)};
            else
                status(end+1) = {sprintf('%d:%02i:%02i  %s', c(4),c(5), round(c(6)), addText)};
            end
            obj.View.handles.logList.String = status;
            obj.View.handles.logList.Value = numel(status);
            drawnow;
        end
        
        function resetDimsBtn_Callback(obj)
            % function resetDimsBtn_Callback(obj)
            % reset area for segmentation
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            obj.View.handles.xSubareaEdit.String = sprintf('1:%d', width);
            obj.View.handles.ySubareaEdit.String = sprintf('1:%d', height);
            obj.View.handles.zSubareaEdit.String = sprintf('1:%d', depth);
            obj.View.handles.binSubareaEdit.String = '1; 1';
        end
        
        function checkDimensions(obj, hObject, parameter)
            % function checkDimensions(obj, parameter)
            % check dimensions for the area to be segmented
            % Parameters:
            % hObject: handle of the calling object
            % parameter: dimension to check
            
            text = hObject.String;
            typedValue = str2num(text); %#ok<ST2NM>
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            switch parameter
                case 'x'
                    maxVal = width;
                case 'y'
                    maxVal = height;
                case 'z'
                    maxVal = depth;
            end
            if min(typedValue) < 1 || max(typedValue) > maxVal
                errordlg('Please check the values!','Wrong parameters!');
                hObject.String = sprintf('1:%d', maxVal);
                return;
            end
        end
        
        function subAreaFromSelectionBtn_Callback(obj)
            % function subAreaFromSelectionBtn_Callback(obj)
            % get area for segmentation from the selection layer
            
            bgColor = obj.View.handles.subAreaFromSelectionBtn.BackgroundColor;
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = 'r';
            drawnow;
            img = cell2mat(obj.mibModel.getData3D('selection', NaN, 4));
            STATS = regionprops(img, 'BoundingBox');
            if numel(STATS) == 0
                errordlg(sprintf('!!! Error !!!\n\nSelection layer was not found!\nPlease make sure that the Selection layer\n is shown in the Image View panel'),...
                    'Missing Selection');
                obj.resetDimsBtn_Callback();
                obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
                return;
            end
            if obj.mibModel.I{obj.mibModel.Id}.depth == 1
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(3)-1);
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(4)-1);
            else
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(4)-1);
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(5)-1);
                obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(3)), ceil(STATS(1).BoundingBox(3))+STATS(1).BoundingBox(6)-1);
            end
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
        end
        
        function currentViewBtn_Callback(obj)
            % function currentViewBtn_Callback(obj)
            % update area for segmentation from the current view
            [yMin, yMax, xMin, xMax] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage();
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', xMin, xMax);
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', yMin, yMax);
        end
        
        function superpixelsBtn_Callback(obj)
            % function superpixelsBtn_Callback(obj)
            % calculate superpixels
            
            dirOut = obj.View.handles.tempDirEdit.String;
            if exist(dirOut,'dir') == 0     % make directory
                mkdir(dirOut);
            end
            fnOut = obj.View.handles.classifierFilenameEdit.String;
            fn = fullfile(dirOut, [fnOut '.slic']);     % filename to keep superpixels
            if exist(fn, 'file') || ~isempty(obj.slic.slic)
                button = questdlg(sprintf('!!! Warning !!!\n\nFile containing superpixels/supervoxels:\n%s\nalready exist!\nOverwrite?', fn),...
                    'Overwrite?', 'Overwrite', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel'); return; end;
            end
            
            obj.slic.slic = [];
            obj.slic.noPix = [];
            
            wb = waitbar(0, sprintf('Calculating superpixels/voxels...\nPlease wait...'), 'Name', 'Classifier segmentation');
            col_channel = obj.View.handles.imageColChPopup.Value;
            slicSuperpixelsRadio = obj.View.handles.slicSuperpixelsRadio.Value;    % 1 - use SLIC, 0-use watershed
            superpixelSize = str2double(obj.View.handles.superpixelEdit.String);
            superpixelCompact = str2double(obj.View.handles.superpixelsCompactEdit.String);
            
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String);  %#ok<ST2NM>
            thick = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = [min(width) max(width)];
            getDataOptions.y = [min(height) max(height)];
            getDataOptions.z = [min(thick) max(thick)];
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binThick = ceil((max(thick)-min(thick)+1)/binVal(2));
            
            getSliceOptions.x = getDataOptions.x;
            getSliceOptions.y = getDataOptions.y;
            if obj.View.handles.mode2dRadio.Value % calculate superpixels
                obj.updateLoglist('========= Calculating superpixels... =========');
                mode = '2d';
                depth = getDataOptions.z(2)-getDataOptions.z(1)+1;
                for sliceNo=1:depth
                    img = cell2mat(obj.mibModel.getData2D('image', getDataOptions.z(1)+sliceNo-1, NaN, col_channel, getSliceOptions));
                    
                    if binVal(1) ~= 1   % bin data
                        img = imresize(img, [binHeight binWidth], 'bicubic');
                    end
                    
                    if sliceNo == 1
                        % calculate number of supervoxels
                        dims = size(img);
                        noPix = ceil(dims(1)*dims(2)/superpixelSize);
                        localSlic.slic = zeros([size(img, 1),size(img, 2), depth]);
                        localSlic.noPix = zeros([depth, 1]);
                    end
                    
                    % stretch image for preview
                    if obj.mibModel.mibLiveStretchCheck
                        img = imadjust(img ,stretchlim(img, [0 1]), []);
                    end
                    if isa(img, 'uint16') % convert to 8bit
                        currViewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;
                        img = imadjust(img, [currViewPort.min(col_channel)/65535 currViewPort.max(col_channel)/65535], [0 1], currViewPort.gamma(col_channel));
                        img = uint8(img/255);
                    end
                    
                    if slicSuperpixelsRadio
                        [localSlic.slic(:,:,sliceNo), noPixCurrent] = slicmex(img, noPix, superpixelCompact);
                        localSlic.noPix(sliceNo) = double(noPixCurrent);
                        % remove superpixel with 0-index
                        localSlic.slic(:,:,sliceNo) = localSlic.slic(:,:,sliceNo) + 1;
                        
                        % calculate adjacent matrix for labels
                        %localSlic.STATS{i} = regionprops(localSlic.slic(:,:,i), img(:,:,i), 'MeanIntensity','BoundingBox');
                        %meanVals = [STATS.MeanIntensity];   % get mean intensity
                    else
                        if superpixelCompact > 0
                            img = imcomplement(img);    % convert image that the ridges are white
                        end
                        
                        mask = imextendedmin(img, superpixelSize);
                        mask = imimposemin(img, mask);
                        
                        mask = watershed(mask);       % generate superpixels
                        localSlic.slic(:,:,sliceNo) = imdilate(mask, ones([3 3]));
                        localSlic.noPix(sliceNo) = max(max(mask));
                    end
                    waitbar(sliceNo/depth, wb, sprintf('Calculating...\nPlease wait...'));
                end
            else        % calculate supervoxels
                obj.updateLoglist('========= Calculating supervoxels... =========');
                img = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, 4, col_channel, getDataOptions)));   % get dataset
                mode = '3d';
                % bin dataset
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    waitbar(.05, wb, sprintf('Binning the dataset\nPlease wait...'));
                    resizeOpt.height = binHeight;
                    resizeOpt.width = binWidth;
                    resizeOpt.depth = binThick;
                    resizeOpt.method = 'bicubic';
                    resizeOpt.algorithm = 'imresize';
                    img = mibResize3d(img, [], resizeOpt);
                end
                
                if slicSuperpixelsRadio
                    % calculate number of supervoxels
                    dims = size(img);
                    localSlic.noPix = ceil(dims(1)*dims(2)*dims(3)/superpixelSize);
                    
                    % calculate supervoxels
                    waitbar(.05, wb, sprintf('Calculating  %d SLIC supervoxels\nPlease wait...', localSlic.noPix));
                    [localSlic.slic, localSlic.noPix] = slicsupervoxelmex_byte(img, localSlic.noPix, superpixelCompact);
                    localSlic.noPix = double(localSlic.noPix);
                    
                    % remove superpixel with 0-index
                    localSlic.slic = localSlic.slic + 1;
                else
                    if superpixelCompact > 0
                        waitbar(.05, wb, sprintf('Inverting the image\nPlease wait...'));
                        img = imcomplement(img);    % convert image that the ridges are white
                    end
                    waitbar(.25, wb, sprintf('imextendedmin transformation\nPlease wait...'));
                    mask = imextendedmin(img, superpixelSize);
                    waitbar(.45, wb, sprintf('Imposing minima\nPlease wait...'));
                    mask = imimposemin(img, mask);
                    waitbar(.55, wb, sprintf('Doing watershed\nPlease wait...'));
                    mask = watershed(mask);       % generate superpixels
                    waitbar(.9, wb, sprintf('Removing edges\nPlease wait...'));
                    localSlic.slic = imdilate(mask, ones([3 3 3]));
                    localSlic.noPix = max(max(max(mask)));
                end
            end
            localSlic.properties(1).bb = [getDataOptions.x getDataOptions.y getDataOptions.z];   % store bounding box of the generated superpixels
            localSlic.properties(1).mode = mode;     % store the mode for the calculated superpixels, 2D or 3D
            localSlic.properties(1).slicSuperpixelsRadio = slicSuperpixelsRadio;     % type of superpixels: 1-SLIC, 0-Watershed
            localSlic.properties(1).binVal = binVal;     % store binning value
            localSlic.properties(1).colCh = col_channel; % store color channel
            localSlic.properties(1).spSize = superpixelSize; % size of superpixels
            localSlic.properties(1).spCompact = superpixelCompact; % compactness of superpixels
            
            waitbar(.95, wb, sprintf('Saving to a file\nPlease wait...'));
            obj.updateLoglist(sprintf('Save to: %s', fn));
            save(fn, 'localSlic', '-mat', '-v7.3');
            
            obj.slic = localSlic;
            delete(wb);
            if obj.View.handles.mode2dRadio.Value
                obj.updateLoglist(sprintf('Calculating and saving (average=%d) superpixels: Done!!!', mean(localSlic.noPix)));
            else
                obj.updateLoglist(sprintf('Calculating and saving %d supervoxels: Done!!!', localSlic.noPix));
            end
        end
        
        function previewSuperpixelsBtn_Callback(obj)
            % function previewSuperpixelsBtn_Callback(obj)
            % preview supepixels/voxels
            if isempty(obj.slic.noPix)
                dirOut = obj.View.handles.tempDirEdit.String;
                fnOut = obj.View.handles.classifierFilenameEdit.String;
                fn = fullfile(dirOut, [fnOut '.slic']);     % filename with superpixels
                if exist(fn, 'file') == 0
                    errordlg(sprintf('!!! Error !!!\n\nThe superpixels/supervoxels were not found!\nPlease generate them first using the Claculate superpixels button!'),...
                        'Superpixels are missing!')
                    return;
                end
                load(fn, '-mat');
                obj.slic = localSlic; 
                clear slic;
            end
            
            % fill structure to use with setSlice and setDataset methods
            getDataOptions.x = obj.slic.properties(1).bb(1:2);
            getDataOptions.y = obj.slic.properties(1).bb(3:4);
            getDataOptions.z = obj.slic.properties(1).bb(5:6);
            
            % calculate image size after binning
            binVal = obj.slic.properties(1).binVal;     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            
            if obj.View.handles.mode2dRadio.Value % show superpixels
                if binVal(1) ~= 1   % re-bin mask
                    resizeOpt.height = diff(getDataOptions.y)+1;
                    resizeOpt.width = diff(getDataOptions.x)+1;
                    resizeOpt.depth = diff(getDataOptions.z)+1;
                    resizeOpt.method = 'nearest';
                    resizeOpt.algorithm = 'imresize';
                    L2 = mibResize3d(obj.slic.slic, [], resizeOpt);
                else
                    L2 = obj.slic.slic;
                end
                for i=1:size(L2,3)
                    L2(:,:,i) = imdilate(L2(:,:,i), ones([3,3], class(L2))) > L2(:,:,i);
                end
                obj.mibModel.setData3D('selection', uint8(L2), NaN, 4, NaN, getDataOptions);   % set dataset
            else    % show supervoxels
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    resizeOpt.height = diff(getDataOptions.y)+1;
                    resizeOpt.width = diff(getDataOptions.x)+1;
                    resizeOpt.depth = diff(getDataOptions.z)+1;
                    resizeOpt.method = 'nearest';
                    resizeOpt.algorithm = 'imresize';
                    L2 = mibResize3d(obj.slic.slic, [], resizeOpt);
                else
                    L2 = obj.slic.slic;
                end
                L2 = imdilate(L2, ones([3,3,3])) > L2;
                obj.mibModel.setData3D('selection', L2, NaN, 4, NaN, getDataOptions);   % set dataset
            end
            notify(obj.mibModel, 'plotImage');
        end
        
        function calcFeaturesBtn_Callback(obj)
            % function calcFeaturesBtn_Callback(obj)
            % calculate features of superpixels/supervoxels
            if isempty(obj.slic.noPix)
                dirOut = obj.View.handles.tempDirEdit.String;
                fnOut = obj.View.handles.classifierFilenameEdit.String;
                fn = fullfile(dirOut, [fnOut '.slic']);     % filename with superpixels
                if exist(fn, 'file') == 0
                    obj.superpixelsBtn_Callback();
                else
                    load(fn, '-mat');
                    obj.slic = localSlic;
                    clear slic;
                end
            end
            col_channel = obj.View.handles.imageColChPopup.Value;
            
            wb = waitbar(0, sprintf('Calculating features for superpixels/voxels...\nPlease wait...'), 'Name', 'Getting features');
            tic
            % update Subarea editboxes
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(1), obj.slic.properties(1).bb(2));
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(3), obj.slic.properties(1).bb(4));
            obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(5), obj.slic.properties(1).bb(6));
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = obj.slic.properties(1).bb(1:2);
            getDataOptions.y = obj.slic.properties(1).bb(3:4);
            getDataOptions.z = obj.slic.properties(1).bb(5:6);
            
            % calculate image size after binning
            obj.View.handles.binSubareaEdit.String = sprintf('%d;%d', obj.slic.properties(1).binVal(1), obj.slic.properties(1).binVal(2));
            binVal = obj.slic.properties(1).binVal;
            binWidth = ceil((getDataOptions.x(2)-getDataOptions.x(1)+1)/binVal(1));
            binHeight = ceil((getDataOptions.y(2)-getDataOptions.y(1)+1)/binVal(1));
            binThick = ceil((getDataOptions.z(2)-getDataOptions.z(1)+1)/binVal(2));
            
            getSliceOptions.x = getDataOptions.x;
            getSliceOptions.y = getDataOptions.y;
            
            indexOut = [];  % list of features to exclude, those that are NaN
            
            if obj.View.handles.mode2dRadio.Value % calculate features for superpixels
                obj.updateLoglist('======= Calculating features for superpixels... =======');
                waitbar(0, wb, sprintf('Calculating features for superpixels\nPlease wait...'));
                
                depth = getDataOptions.z(2)-getDataOptions.z(1)+1;
                for sliceNo=1:depth
                    img = cell2mat(obj.mibModel.getData2D('image', getDataOptions.z(1)+sliceNo-1, NaN, col_channel, getSliceOptions));
                    if binVal(1) ~= 1   % bin data
                        img = imresize(img, [binHeight binWidth], 'bicubic');
                    end
                    
                    if sliceNo == 1
                        % preallocating space
                        localFEATURES = struct;
                        localFEATURES(depth).fm = [];
                        localFEATURES(depth).BoundingBox = [];
                    end
                    
                    % stretch the image
                    minVal = min(min(min(img)));
                    img = img - minVal;
                    img = img*(255/double(max(max(max(img)))));
                    
                    STATS = regionprops(obj.slic.slic(:,:,sliceNo), img, ...
                        'BoundingBox', 'MeanIntensity', 'MaxIntensity', 'MinIntensity', 'PixelValues', 'Centroid', 'PixelIdxList');
                    % store bounding box
                    bb = arrayfun(@(ind) STATS(ind).BoundingBox, 1:numel(STATS), 'UniformOutput', 0);
                    bb = reshape(cell2mat(bb), [4, numel(bb)])';
                    localFEATURES(sliceNo).BoundingBox = bb;
                    
                    % get features
                    localFEATURES(sliceNo).fm(:,1) = [STATS.MeanIntensity];
                    localFEATURES(sliceNo).fm(:,2) = [STATS.MaxIntensity];
                    localFEATURES(sliceNo).fm(:,3) = [STATS.MinIntensity];
                    
                    localFEATURES(sliceNo).fm(:,4)=arrayfun(@(ind) var(double(STATS(ind).PixelValues)), 1:numel(STATS),'UniformOutput',1);
                    localFEATURES(sliceNo).fm(:,5)=arrayfun(@(ind) std(double(STATS(ind).PixelValues)), 1:numel(STATS),'UniformOutput',1);
                    localFEATURES(sliceNo).fm(:,6)=arrayfun(@(ind) median(double(STATS(ind).PixelValues)), 1:numel(STATS),'UniformOutput',1);
                    
                    % calculate histogram arranged to 10 bins
                    histVal = arrayfun(@(ind) hist(double(STATS(ind).PixelValues),[0:26:255]), 1:numel(STATS),'UniformOutput',0);
                    histVal = reshape(cell2mat(histVal), [10, numel(histVal)])';
                    [localFEATURES(sliceNo).fm(:,7:16)] = histVal;
                    
                    %         entropyImg = entropyfilt(img);
                    %         STATS2 = regionprops(obj.slic.slic(:,:,sliceNo), entropyImg, 'MeanIntensity');
                    %         localFEATURES(sliceNo).fm(:,17) = [STATS2.MeanIntensity];
                    %
                    %         L2 = imdilate(obj.slic.slic(:,:,sliceNo), ones([3,3], class(obj.slic.slic(:,:,sliceNo)))) > obj.slic.slic(:,:,sliceNo);
                    %         currSlic = obj.slic.slic(:,:,sliceNo);
                    %         for j=1:obj.slic.noPix(sliceNo)
                    %             val = mean(img(currSlic==j & L2==1));
                    %             if ~isnan(val)
                    %                 localFEATURES(sliceNo).fm(j,17) = val;
                    %             else
                    %                 localFEATURES(sliceNo).fm(j,17) = 1;
                    %             end
                    %         end
                    
                    if 0
                        shift = 18;
                        gap = 0;    % regions are connected, no gap in between
                        Edges = imRAG(obj.slic.slic(:,:,sliceNo), gap);
                        Edges2 = fliplr(Edges);    % complement for both ways
                        Edges = [Edges; Edges2];
                        for idx = 1:numel(STATS)
                            uInd = Edges(Edges(:,1)==idx,2);
                            localFEATURES(sliceNo).fm(idx,shift:shift+15) = mean(localFEATURES(sliceNo).fm(uInd,1:16));
                            localFEATURES(sliceNo).fm(idx,shift+16) = std(localFEATURES(sliceNo).fm(uInd,1));
                        end
                    end
                    
                    % test of downsampling where each pixel is a superpixel
                    if 0
                        shift2 = size(localFEATURES(sliceNo).fm, 2);
                        centVec = cat(1, STATS.Centroid);   % vector of centroids
                        
                        samplingRate = sqrt(obj.slic.properties.spSize/pi);     % get sampling rate for convertion to uniform points
                        [xq,yq] = meshgrid(1:samplingRate:size(img,2), 1:samplingRate:size(img,1));
                        slicImg = griddata(centVec(:,1),centVec(:,2), localFEATURES(sliceNo).fm(:,1), xq, yq, 'nearest');    % FEATURES(sliceNo).fm(:,1) - mean intensity
                        slicImg = uint8(slicImg);
                        
                        % alternatively just resize image to size of the superpixels...
                        %slicImg = imresize(img, 1/samplingRate, 'bicubic');
                        
                        % % checks
                        % figure(15)
                        % mesh(xq,yq,slicImg);
                        % hold on
                        % plot3(centVec(:,1),centVec(:,2),meanInt,'o');
                        % imtool(slicImg);
                        
                        % calculate features
                        cs = 5; % context size
                        ms = 1; % membrane thickness
                        csHist = cs;
                        fmTemp  = membraneFeatures(slicImg, cs, ms, csHist);
                        % fmTemp - feature matrix [h, w, feature_id]
                        noExtraFeatures = size(fmTemp,3);
                        
                        for idx=1:size(centVec,1)
                            indX = ceil(centVec(idx,1)/samplingRate);
                            indY = ceil(centVec(idx,2)/samplingRate);
                            localFEATURES(sliceNo).fm(idx,shift2+1:shift2+noExtraFeatures) = squeeze(fmTemp(indY, indX, :));
                        end
                        % find and remove NaNs
                        for idx=shift2+1:shift2+noExtraFeatures
                            if ~isempty(find(isnan(localFEATURES(sliceNo).fm(:,idx))==1,1))
                                indexOut = [indexOut idx];
                            end
                        end
                    end
                    
                    if 0
                        shift2 = size(localFEATURES(sliceNo).fm, 2);
                        d_image = double(img);
                        f00=[1, 1, 1; 1, -8, 1; 1, 1, 1];
                        BETA=5; % to avoid that center pixture is equal to zero
                        ALPHA=3; % like a lens to magnify or shrink the difference between neighbors
                        
                        LOG=conv2(d_image, f00, 'same'); %convolve with f00
                        LOG_scaled=atan(ALPHA*LOG./(d_image+BETA)); %perform the tangent scaling
                        LOG_norm=255*(LOG_scaled-min(min(LOG_scaled)))/(max(max(LOG_scaled))-min(min(LOG_scaled)));
                        
                        for idx=1:numel(STATS)
                            localFEATURES(sliceNo).fm(idx,shift2+1) = mean(LOG_norm(STATS(idx).PixelIdxList));
                        end
                    end
                    
                    % test of gabor filters
                    if 0
                        shift2 = size(localFEATURES(sliceNo).fm, 2);
                        
                        wavelength = 4;
                        %orientation = [0 15 30 45 60 75 90];
                        orientation = 0:15:180;
                        gaborBank = gabor(wavelength,orientation);
                        noExtraFeatures = numel(orientation)*numel(wavelength);
                        %           % opt 1
                        %             for idx = 1:numel(STATS)
                        %                 bb = ceil(FEATURES(sliceNo).BoundingBox(1,:));
                        %                 imgTemp = img(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1);
                        %                 imgTemp = imgaborfilt(imgTemp, gaborBank);
                        %                 for idx2 = 1:noExtraFeatures
                        %                     absGabor = abs(imgTemp(:,:,idx2));
                        %                     FEATURES(sliceNo).fm(idx, shift2+idx2) = mean(mean((absGabor-mean(absGabor(:)))/std(absGabor(:))));
                        %                 end
                        %             end
                        
                        % opt 2
                        imgTemp = imgaborfilt(img, gaborBank);
                        imgTemp = mean(imgTemp, 3);  % sum all directions
                        for idx=1:numel(STATS)
                            localFEATURES(sliceNo).fm(idx,shift2+1) = mean(imgTemp(STATS(idx).PixelIdxList));
                        end
                        
                    end
                    %
                    
                    %         if 0    % test to use information from bigger superpixels
                    %             [slic2, noPixCurrent] = slicmex(img, ceil(obj.slic.noPix/10), obj.slic.properties.spCompact);
                    %             % % remove superpixel with 0-index
                    %             slic2 = slic2 + 1;
                    %             slic2 = double(slic2);
                    %
                    %             slic1 = obj.slic.slic(:,:,sliceNo);
                    %             occuranceMatrix = zeros([obj.slic.noPix(sliceNo), noPixCurrent]);    % matrix of occurance of small superpixels in bigger superpixels
                    %             for sPixId=1:noPixCurrent
                    %                 sPixIndices = unique(slic1(slic2==sPixId));
                    %                 occuranceMatrix(sPixIndices, sPixId) = histc(slic1(slic2==sPixId),sPixIndices);
                    %             end
                    %             %[~, localFEATURES(1).fm(:,17)] = max(occuranceMatrix,[],2);
                    %             [~, occuranceIndex] = max(occuranceMatrix,[],2); % correlates number of each small supervoxel with number of a bigger one
                    %
                    %             shift = 16;
                    %             STATS = regionprops(slic2, img, 'MeanIntensity','PixelValues');
                    %             % convert PixelValues to doubles
                    %             STATS = arrayfun(@(s) setfield(s,'PixelValues',double(s.PixelValues)),STATS);
                    %
                    %             localFEATURES(sliceNo).fm(:,shift+1) = arrayfun(@(ind) STATS(occuranceIndex(ind)).MeanIntensity, 1:numel(occuranceIndex),'UniformOutput',1);
                    %             tempVal = arrayfun(@(ind) var(STATS(ind).PixelValues), 1:numel(STATS),'UniformOutput',1);
                    %             localFEATURES(sliceNo).fm(:,shift+2)=arrayfun(@(ind) tempVal(occuranceIndex(ind)), 1:numel(occuranceIndex),'UniformOutput',1);
                    %
                    %             histVal =  arrayfun(@(ind) hist(STATS(ind).PixelValues, [0:26:255]), 1:numel(STATS),'UniformOutput',0);
                    %             histVal = reshape(cell2mat(histVal), [10, numel(histVal)])';
                    %             histVal = arrayfun(@(ind) histVal(occuranceIndex(ind),:), 1:numel(occuranceIndex),'UniformOutput',0);
                    %             histVal = reshape(cell2mat(histVal), [10, numel(histVal)])';
                    %             localFEATURES(sliceNo).fm(:,shift+3:shift+12)= histVal;
                    %         end
                    
                    
                    waitbar(sliceNo/depth, wb, sprintf('Calculating...\nPlease wait...'));
                end
                % remove possible NaNs
                for sliceNo=1:depth
                    localFEATURES(sliceNo).fm(:,indexOut) = [];
                end
            else                                 % calculate features for supervoxels
                obj.updateLoglist('======= Calculating features for supervoxels... =======');
                img = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, 4, col_channel, getDataOptions)));   % get dataset
                % bin dataset
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    waitbar(.05, wb, sprintf('Binning the dataset\nPlease wait...'));
                    resizeOpt.height = binHeight;
                    resizeOpt.width = binWidth;
                    resizeOpt.depth = binThick;
                    resizeOpt.method = 'bicubic';
                    resizeOpt.algorithm = 'imresize';
                    img = mibResize3d(img, [], resizeOpt);
                end
                
                % calculate supervoxels
                waitbar(.05, wb, sprintf('Calculating features for %d supervoxels\nPlease wait...', obj.slic.noPix));
                
                % stretch the image
                minVal = min(min(min(img)));
                img = img - minVal;
                img = img*(255/double(max(max(max(img)))));
                
                % preallocating space
                localFEATURES = struct;
                
                STATS = regionprops(obj.slic.slic, img, ...
                    'BoundingBox', 'MeanIntensity', 'MaxIntensity', 'MinIntensity', 'PixelValues', 'Centroid');
                % store bounding box
                bb = arrayfun(@(ind) STATS(ind).BoundingBox, 1:numel(STATS),'UniformOutput', 0);
                bb = reshape(cell2mat(bb), [6, numel(bb)])';
                localFEATURES(1).BoundingBox = bb;
                
                % get features
                waitbar(.4, wb, sprintf('Calculating MeanIntensity for %d supervoxels\nPlease wait...', obj.slic.noPix));
                localFEATURES(1).fm(:,1) = [STATS.MeanIntensity];
                waitbar(.45, wb, sprintf('Calculating MaxIntensity for %d supervoxels\nPlease wait...', obj.slic.noPix));
                localFEATURES(1).fm(:,2) = [STATS.MaxIntensity];
                waitbar(.5, wb, sprintf('Calculating MinIntensity for %d supervoxels\nPlease wait...', obj.slic.noPix));
                localFEATURES(1).fm(:,3) = [STATS.MinIntensity];
                
                waitbar(.55, wb, sprintf('Calculating Variance for %d supervoxels\nPlease wait...', obj.slic.noPix));
                localFEATURES(1).fm(:,4)=arrayfun(@(ind) var(double(STATS(ind).PixelValues)), 1:numel(STATS),'UniformOutput',1);
                waitbar(.6, wb, sprintf('Calculating Std for %d supervoxels\nPlease wait...', obj.slic.noPix));
                localFEATURES(1).fm(:,5)=arrayfun(@(ind) std(double(STATS(ind).PixelValues)), 1:numel(STATS),'UniformOutput',1);
                waitbar(.65, wb, sprintf('Calculating Median for %d supervoxels\nPlease wait...', obj.slic.noPix));
                localFEATURES(1).fm(:,6)=arrayfun(@(ind) median(double(STATS(ind).PixelValues)), 1:numel(STATS),'UniformOutput',1);
                
                % calculate histogram arranged to 10 bins
                waitbar(.7, wb, sprintf('Calculating Histogram for %d supervoxels\nPlease wait...', obj.slic.noPix));
                histVal = arrayfun(@(ind) hist(double(STATS(ind).PixelValues),[0:26:255]), 1:numel(STATS),'UniformOutput',0);
                histVal = reshape(cell2mat(histVal), [10, numel(histVal)])';
                [localFEATURES(1).fm(:,7:16)] = histVal;
                
                % calculate adjacent matrix for labels
                waitbar(.8, wb, sprintf('Calculating adjacent matrix for %d supervoxels\nPlease wait...', numel(STATS)));
                gap = 0;    % regions are connected, no gap in between
                Edges = imRAG(obj.slic.slic, gap);
                Edges2 = fliplr(Edges);    % complement for both ways
                Edges = [Edges; Edges2];
                
                for idx = 1:numel(STATS)
                    uInd = Edges(Edges(:,1)==idx,2);
                    localFEATURES(1).fm(idx,17:32) = mean(localFEATURES(1).fm(uInd,1:16));
                    localFEATURES(1).fm(idx,33) = std(localFEATURES(1).fm(uInd,1));
                end
                
                if 0
                    shift2 = size(localFEATURES(1).fm, 2);
                    centVec = cat(1, STATS.Centroid);   % vector of centroids
                    
                    samplingRate = sqrt(obj.slic.properties.spSize/pi);     % get sampling rate for convertion to uniform points
                    [xq,yq,zq] = meshgrid(1:samplingRate:size(img,2), 1:samplingRate:size(img,1),1:samplingRate:size(img,3));
                    slicImg = griddata(centVec(:,1),centVec(:,2),centVec(:,3), localFEATURES(1).fm(:,1), xq, yq, zq, 'nearest');    % FEATURES(sliceNo).fm(:,1) - mean intensity
                    slicImg = uint8(slicImg);
                    
                    % alternatively just resize image to size of the superpixels...
                    %slicImg = imresize(img, 1/samplingRate, 'bicubic');
                    
                    % % checks
                    % figure(15)
                    % mesh(xq,yq,slicImg);
                    % hold on
                    % plot3(centVec(:,1),centVec(:,2),meanInt,'o');
                    % imtool(slicImg);
                    
                    % calculate features
                    cs = 5; % context size
                    ms = 1; % membrane thickness
                    csHist = cs;
                    fmTemp  = membraneFeatures(slicImg, cs, ms, csHist);
                    % fmTemp - feature matrix [h, w, feature_id]
                    noExtraFeatures = size(fmTemp,3);
                    
                    for idx=1:size(centVec,1)
                        indX = ceil(centVec(idx,1)/samplingRate);
                        indY = ceil(centVec(idx,2)/samplingRate);
                        indZ = ceil(centVec(idx,3)/samplingRate);
                        localFEATURES(1).fm(idx,shift2+1:shift2+noExtraFeatures) = squeeze(fmTemp(indY, indX, indZ, :));
                    end
                    % find and remove NaNs
                    for idx=shift2+1:shift2+noExtraFeatures
                        if ~isempty(find(isnan(localFEATURES(1).fm(:,idx))==1,1))
                            indexOut = [indexOut idx];
                        end
                    end
                end
                
                
                %     if 0    % test to use information from bigger supervoxels
                %         [slic2, noPixCurrent] = slicsupervoxelmex_byte(img, ceil(obj.slic.noPix/216), obj.slic.properties.spCompact);
                %         % % remove superpixel with 0-index
                %         slic2 = slic2 + 1;
                %         slic2 = double(slic2);
                %         occuranceMatrix = zeros([obj.slic.noPix, noPixCurrent]);    % matrix of occurance of small superpixels in bigger superpixels
                %         for sPixId=1:noPixCurrent
                %             sPixIndices = unique(obj.slic.slic(slic2==sPixId));
                %             occuranceMatrix(sPixIndices, sPixId) = histc(obj.slic.slic(slic2==sPixId),sPixIndices);
                %         end
                %         %[~, localFEATURES(1).fm(:,17)] = max(occuranceMatrix,[],2);
                %         [~, occuranceIndex] = max(occuranceMatrix,[],2); % correlates number of each small supervoxel with number of a bigger one
                %
                %         shift = 16;
                %         STATS = regionprops(slic2, img, 'MeanIntensity','PixelValues');
                %         % convert PixelValues to doubles
                %         STATS = arrayfun(@(s) setfield(s,'PixelValues',double(s.PixelValues)),STATS);
                %
                %         waitbar(.4, wb, sprintf('Calculating MeanIntensity for %d large supervoxels\nPlease wait...', noPixCurrent));
                %         localFEATURES(1).fm(:,shift+1) = arrayfun(@(ind) STATS(occuranceIndex(ind)).MeanIntensity, 1:numel(occuranceIndex),'UniformOutput',1);
                %         waitbar(.55, wb, sprintf('Calculating Variance for %d large supervoxels\nPlease wait...', obj.slic.noPix));
                %         tempVal = arrayfun(@(ind) var(STATS(ind).PixelValues), 1:numel(STATS),'UniformOutput',1);
                %         localFEATURES(1).fm(:,shift+2)=arrayfun(@(ind) tempVal(occuranceIndex(ind)), 1:numel(occuranceIndex),'UniformOutput',1);
                %
                %         histVal =  arrayfun(@(ind) hist(STATS(ind).PixelValues), 1:numel(STATS),'UniformOutput',0);
                %         histVal = reshape(cell2mat(histVal), [10, numel(histVal)])';
                %         histVal = arrayfun(@(ind) histVal(occuranceIndex(ind),:), 1:numel(occuranceIndex),'UniformOutput',0);
                %         histVal = reshape(cell2mat(histVal), [10, numel(histVal)])';
                %         localFEATURES(1).fm(:,shift+3:shift+12)= histVal;
                %     end
                
                waitbar(1, wb, sprintf('Finishing\nPlease wait...'));
            end
            
            dirOut = obj.View.handles.tempDirEdit.String;
            fnOut = obj.View.handles.classifierFilenameEdit.String;
            fn = fullfile(dirOut, [fnOut '.features']);     % filename with features
            save(fn, 'localFEATURES','-mat');
            
            obj.FEATURES = localFEATURES;
            delete(wb);
            obj.updateLoglist('Calculating and saving features: Done!!!');
            toc
        end
        
        function trainClassifierBtn_Callback(obj)
            % function trainClassifierBtn_Callback(obj)
            % train random forest
            bgCol = obj.View.handles.trainClassifierBtn.BackgroundColor;
            obj.View.handles.trainClassifierBtn.BackgroundColor = [1 0 0];
            
            % load check required preprocessed data
            if isempty(obj.FEATURES)
                dirOut = obj.View.handles.tempDirEdit.String;
                fnOut = obj.View.handles.classifierFilenameEdit.String;
                fn = fullfile(dirOut, [fnOut '.features']);     % filename to keep features
                if exist(fn,'file') == 0
                    obj.calcFeaturesBtn_Callback();
                else
                    load(fn, '-mat');
                    obj.FEATURES = localFEATURES;
                    clear localFEATURES;
                end
            end
            
            if isempty(obj.slic.noPix)
                dirOut = obj.View.handles.tempDirEdit.String;
                fnOut = obj.View.handles.classifierFilenameEdit.String;
                fn = fullfile(dirOut, [fnOut '.slic']);     % filename with superpixels
                if exist(fn,'file') == 0
                    obj.superpixelsBtn_Callback();
                else
                    load(fn,'-mat');
                    obj.slic = localSlic;
                    clear localSlic;
                end
            end
            
            obj.updateLoglist('======= Starting training... =======');
            
            obj.mibModel.mibDoBackup('selection', 1);    % store selection layer
            posModel = obj.View.handles.objectPopup.Value;
            negModel = obj.View.handles.backgroundPopup.Value;
            
            % update Subarea editboxes
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(1), obj.slic.properties(1).bb(2));
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(3), obj.slic.properties(1).bb(4));
            obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(5), obj.slic.properties(1).bb(6));
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = obj.slic.properties(1).bb(1:2);
            getDataOptions.y = obj.slic.properties(1).bb(3:4);
            getDataOptions.z = obj.slic.properties(1).bb(5:6);
            
            % calculate image size after binning
            obj.View.handles.binSubareaEdit.String = sprintf('%d;%d', obj.slic.properties(1).binVal(1), obj.slic.properties(1).binVal(2));
            binVal = obj.slic.properties(1).binVal;
            binWidth = ceil((diff(getDataOptions.x)+1)/binVal(1));
            binHeight = ceil((diff(getDataOptions.y)+1)/binVal(1));
            binThick = ceil((diff(getDataOptions.z)+1)/binVal(2));
            
            model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, NaN, getDataOptions));   % get dataset
            fmPos = [];
            fmNeg = [];
            
            NLearn = str2double(obj.View.handles.classCyclesEdit.String);
            classId = obj.View.handles.classifierPopup.Value;
            classType = obj.View.handles.classifierPopup.String;
            classType = classType{classId};
            
            if obj.View.handles.mode2dRadio.Value % train for superpixels
                if binVal(1) ~= 1   % bin data
                    model2 = zeros([binHeight, binWidth, size(model,3)], class(model));
                    for sliceId=1:size(model, 3)
                        model2(:,:,sliceId) = imresize(model(:,:,sliceId), [binHeight binWidth], 'nearest');
                    end
                    model = model2;
                    clear model2;
                end
                depth = size(model,3);
                obj.updateLoglist('Extracting features for object and background...');
                for sliceNo=1:depth
                    % find slices with model
                    if isempty(find(model(:,:,sliceNo) == posModel, 1)) && isempty(find(model(:,:,sliceNo) == negModel,1))
                        continue;
                    end
                    
                    currSlic = obj.slic.slic(:,:,sliceNo);
                    posPos = unique(currSlic(model(:,:,sliceNo)==posModel));   % indices of superpixels that belong to the objects
                    posNeg = unique(currSlic(model(:,:,sliceNo)==negModel));   % indices of superpixels that belong to the background
                    
                    % remove from labelBg those that are also found in labelObj
                    posNeg(ismember(posNeg, posPos)) = [];
                    
                    fmPos = [fmPos; obj.FEATURES(sliceNo).fm(posPos,:)];  % get features for positive points, combine with another training slice
                    fmNeg = [fmNeg; obj.FEATURES(sliceNo).fm(posNeg,:)];  % get features for negative points
                end
                clear posPos;
                clear posNeg;
            else    % train for supervoxels
                % bin dataset
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    resizeOpt.height = binHeight;
                    resizeOpt.width = binWidth;
                    resizeOpt.depth = binThick;
                    resizeOpt.method = 'nearest';
                    resizeOpt.algorithm = 'imresize';
                    model = mibResize3d(model, [], resizeOpt);
                end
                
                obj.updateLoglist('Extracting features for object and background...');
                
                [posPos, ~, countL] = unique(obj.slic.slic(model==posModel));     % countL can be used to count number of occurances as
                [posNeg, ~, countBg] = unique(obj.slic.slic(model==negModel));       % numel(find(countL==IndexOfSuperpixel)))
                
                % when two labels intersect in one supervoxel, prefer the one that
                % has larger number of occurances
                [commonVal, bgIdx] = intersect(posNeg, posPos);  % find indices of the intersection supervoxels
                labelIdx = find(ismember(posPos, commonVal));
                for comId = 1:numel(commonVal)
                    if numel(find(countL==labelIdx(comId))) > numel(find(countBg==bgIdx(comId)))
                        posNeg(posNeg==commonVal(comId)) = [];
                    else
                        posPos(posPos==commonVal(comId)) = [];
                    end
                end
                
                % OLD CODE that gives preference to label
                % % remove from labelBg those that are also found in labelObj
                %posNeg(ismember(posNeg, posPos)) = [];
                
                fmPos = [fmPos; obj.FEATURES(1).fm(posPos,:)];  % get features for positive points, combine with another training slice
                fmNeg = [fmNeg; obj.FEATURES(1).fm(posNeg,:)];  % get features for negative points
            end
            obj.updateLoglist('Training the classifier...');
            y = [zeros(size(fmNeg,1),1); ones(size(fmPos,1),1)];     % generate a vector that defines positive and negative values
            x = double([fmNeg; fmPos]);  % generate a matrix with combined features
            
            extra_options.sampsize = [obj.maxNumberOfSamplesPerClass, obj.maxNumberOfSamplesPerClass];
            if isempty(x) || isempty(y)
                errordlg(sprintf('!!! Error !!!\n\nThe labels are probably missing!\nMake sure that labels for the object and background are within the selected area!'));
                obj.updateLoglist('Cancelled: missing labels!');
                obj.View.handles.trainClassifierBtn.BackgroundColor = bgCol;
                return;
            end
            
            if classId == 1   % use random forest
                obj.updateLoglist('Type: Random Forest');
                localForest = classRF_train(x, y, 300, 5, extra_options);    % train classifier
            else
                obj.updateLoglist(sprintf('Type: %s', classType));
                if strcmp(classType,'Support Vector Machine')
                    %localForest = fitcsvm(x,y);
                    localForest = fitctree(x,y);
                else
                    localForest = fitensemble(x,y, classType, NLearn, 'Tree', 'Type','classification');
                end
            end
            
            dirOut = obj.View.handles.tempDirEdit.String;
            fnOut = obj.View.handles.classifierFilenameEdit.String;
            fn = fullfile(dirOut, [fnOut '.forest']);     % filename to keep trained classifier
            
            save(fn, 'localForest', '-mat');
            obj.Forest = localForest;
            obj.updateLoglist('Training the classifier: Done!');
            obj.View.handles.trainClassifierBtn.BackgroundColor = bgCol;
        end
        
        function wipeTempDirBtn_Callback(obj)
            % function wipeTempDirBtn_Callback(obj)
            % wipe temp directory
            tempDir = obj.View.handles.tempDirEdit.String;
            if exist(tempDir,'dir') ~= 0     % remove directory
                button =  questdlg(sprintf('!!! Warning !!!\n\nThe whole directory:\n\n%s\n\nwill be deleted!!!\n\nAre you sure?', tempDir),....
                    'Delete directory?', 'Delete', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel')
                    obj.updateLoglist('Wipe temp directory: canceled!');
                    return;
                end
                
                rmdir(tempDir, 's');
                obj.updateLoglist('The temp directory has been deleted');
            end
            
            obj.slic.slic = [];     % a field for superpixels, [height, width, depth]
            obj.slic.noPix = [];    % a field for number of pixels, [depth] for 2d, or a single number for 3d
            obj.slic.properties = [];   % a substructure with properties, only for handles.slic.properties(1)
            %   .bb [xMin xMax yMin yMax zMin zMax]
            %   .mode '2d' or '3d'
            %   .binVal, binning values: (xy z)
            obj.FEATURES = [];      % a structure for features
            obj.Forest = [];        % classifier
        end
        
        function predictDatasetBtn_Callback(obj)
            % function predictDatasetBtn_Callback(obj)
            % predict dataset using the random forest classifier
            
            % load check required preprocessed data
            % check classifier
            if isempty(obj.Forest)
                dirOut = obj.View.handles.tempDirEdit.String;
                fnOut = obj.View.handles.classifierFilenameEdit.String;
                fn = fullfile(dirOut, [fnOut '.forest']);     % filename to keep trained classifier
                
                if exist(fn, 'file') == 0
                    obj.trainClassifierBtn_Callback();
                else
                    load(fn, '-mat');
                    obj.Forest = localForest;
                    clear localForest;
                end
            end
            
            % check features
            if isempty(obj.FEATURES)
                dirOut = obj.View.handles.tempDirEdit.String;
                fnOut = obj.View.handles.classifierFilenameEdit.String;
                fn = fullfile(dirOut, [fnOut '.features']);     % filename with features
                
                if exist(fn, 'file') == 0
                    obj.calcFeaturesBtn_Callback();
                else
                    load(fn,'-mat');
                    obj.FEATURES = localFEATURES;
                    clear localFEATURES;
                end
            end
            % check superpixels/voxels
            if isempty(obj.slic.noPix)
                dirOut = obj.View.handles.tempDirEdit.String;
                fnOut = obj.View.handles.classifierFilenameEdit.String;
                fn = fullfile(dirOut, [fnOut '.slic']);     % filename to keep superpixels
                if exist(fn, 'file') == 0
                    obj.superpixelsBtn_Callback();
                else
                    load(fn, '-mat');
                    obj.slic = localSlic;
                    clear localSlic;
                end
            end
            
            % update Subarea editboxes
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(1), obj.slic.properties(1).bb(2));
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(3), obj.slic.properties(1).bb(4));
            obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', obj.slic.properties(1).bb(5), obj.slic.properties(1).bb(6));
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = obj.slic.properties(1).bb(1:2);
            getDataOptions.y = obj.slic.properties(1).bb(3:4);
            getDataOptions.z = obj.slic.properties(1).bb(5:6);
            
            % calculate image size after binning
            obj.View.handles.binSubareaEdit.String = sprintf('%d;%d', obj.slic.properties(1).binVal(1), obj.slic.properties(1).binVal(2));
            binVal = obj.slic.properties(1).binVal;
            binWidth = ceil((diff(getDataOptions.x)+1)/binVal(1));
            binHeight = ceil((diff(getDataOptions.y)+1)/binVal(1));
            binThick = ceil((diff(getDataOptions.z)+1)/binVal(2));
            
            if nargin == 2
                getDataOptions.z = [getDataOptions.z-sliceNumber+1 getDataOptions.z-sliceNumber+1];
            end
            obj.updateLoglist('======= Starting prediction... =======');
            
            obj.mibModel.mibDoBackup('mask', 1);    % store the mask layer
            
            t1 = tic;
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                obj.mibModel.I{obj.mibModel.Id}.clearMask();   % clear or delete mask for uint8 model type
            end
            
            negModel = obj.View.handles.backgroundPopup.Value;
            
            if obj.View.handles.mode2dRadio.Value % predict in 2D
                getSliceOptions.x = getDataOptions.x;
                getSliceOptions.y = getDataOptions.y;
                for sliceNo = 1:getDataOptions.z(2)-getDataOptions.z(1)+1
                    Mask = zeros([size(obj.slic.slic,1), size(obj.slic.slic,2)], 'uint8');
                    currSlic = obj.slic.slic(:,:,sliceNo);
                    
                    obj.updateLoglist(sprintf('Predicting slice: %d...', sliceNo));
                    
                    if isstruct(obj.Forest)
                        [y_h, v] = classRF_predict(obj.FEATURES(sliceNo).fm, obj.Forest);
                    else
                        y_h = predict(obj.Forest, obj.FEATURES(sliceNo).fm);
                    end
                    
                    %votes = v(:,2);
                    %votes = reshape(votes,imsize);
                    %votes = double(votes)/max(votes(:));
                    indexLabel = find(y_h>0);
                    Mask(ismember(double(currSlic), indexLabel)) = 1;
                    
                    model = cell2mat(obj.mibModel.getData2D('model', getDataOptions.z(1)+sliceNo-1, NaN, NaN, getSliceOptions));
                    if binVal(1) ~= 1   % bin data
                        model = imresize(model, [binHeight binWidth], 'nearest');
                    end
                    Mask(model==negModel) = 0;    % remove background pixels
                    
                    if binVal(1) ~= 1   % bin data
                        Mask = imresize(Mask, [diff(getDataOptions.y)+1, diff(getDataOptions.x)+1], 'nearest');
                    end
                    obj.mibModel.setData2D('mask', Mask, getDataOptions.z(1)+sliceNo-1, NaN, NaN, getSliceOptions);
                end
            else                                 % predict in 3D
                Mask = zeros(size(obj.slic.slic), 'uint8');
                obj.updateLoglist('Predicting dataset...');
                
                if isstruct(obj.Forest)
                    [y_h, v] = classRF_predict(obj.FEATURES.fm, obj.Forest);
                else
                    y_h = predict(obj.Forest, obj.FEATURES.fm);
                end
                
                indexLabel = find(y_h>0);
                Mask(ismember(double(obj.slic.slic), indexLabel)) = 1;
                
                obj.updateLoglist('Removing background pixels...');
                model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, NaN, getDataOptions));   % get dataset
                % bin dataset
                resizeOpt.height = binHeight;
                resizeOpt.width = binWidth;
                resizeOpt.depth = binThick;
                resizeOpt.method = 'nearest';
                resizeOpt.algorithm = 'imresize';
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    model = mibResize3d(model, [], resizeOpt);
                end
                Mask(model==negModel) = 0;    % remove background pixels
                
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    obj.updateLoglist('Re-binning the mask...');
                    resizeOpt.height = diff(getDataOptions.y)+1;
                    resizeOpt.width = diff(getDataOptions.x)+1;
                    resizeOpt.depth = diff(getDataOptions.z)+1;
                    Mask = mibResize3d(Mask, [], resizeOpt);
                end
                obj.mibModel.setData3D('mask', Mask, NaN, 4, NaN, getDataOptions);   % set dataset
            end
            
            obj.updateLoglist('======= Prediction finished! =======');
            resultTOC = toc(t1);
            obj.updateLoglist(sprintf('Elapsed time is %f seconds.', resultTOC));
            notify(obj.mibModel, 'showMask');   % turn on the show mask checkbox
        end
        
        function loadClassifierBtn_Callback(obj)
            % function loadClassifierBtn_Callback(obj)
            % load classifier from the disk
            
            tempDir = obj.View.handles.tempDirEdit.String;
            [FileName,PathName,FilterIndex] = uigetfile('*.forest', 'Select trained classifier', tempDir, 'MultiSelect', 'off');
            if FileName==0; return; end;
            
            fn = fullfile(PathName, FileName);
            res = load(fn, '-mat');
            localForest = res.localForest;
            obj.Forest = localForest;
            
            % saving the classifier using the current project name
            fnOut = obj.View.handles.classifierFilenameEdit.String;
            fn = fullfile(tempDir, [fnOut '.forest']);     % filename to keep trained classifier
            
            save(fn, 'localForest', '-mat');
            obj.updateLoglist('Loading the classifier: Done!');
        end
        
        
    end
end