classdef mibWatershedController  < handle
    % @type mibWatershedController class is resposnible for showing the watershed/graphcut segmentation window,
    % available from MIB->Menu->Tools->Watershed/Graphcut segmentation
    
	% Copyright (C) 27.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        preprocImg
        % a variable with the preprocessed image
        graphcut
        % a structire with the graphcut data
        mode
        % a mode to use: 'mode2dCurrentRadio'
        realtimeSwitch
        % enable real time segmentation (for the graphcut only)
        shownLabelObj
        % indices of currently displayed superpixels for the objects
        seedObj
        % a cell array with the object seeds for each slice for 3D graphcut
        seedBg
        % a cell array with the background seeds for each slice for 3D graphcut
        timerElapsed
        % a variable to keep the elapsed time, when the elapsed time
        % shorter than the timerElapsedMax the waitbar is not shown
        timerElapsedMax
        % when the segmentation is longer that this number, the waitbar is
        % displayed
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
                case {'setData'}
                    if strcmp(evnt.Parameter.type, 'model') && obj.realtimeSwitch == 1
                        tic
                        obj.doGraphcutSegmentation();
                        obj.timerElapsed = toc;
                        fprintf('Elapsed time is %f seconds.\n', obj.timerElapsed);
                        notify(obj.mibModel, 'showMask');
                    end
            end
        end
    end
    
    methods
        function obj = mibWatershedController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibWatershedGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.text1.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            % variable for data preprocessing
            obj.preprocImg = NaN;
            obj.graphcut.slic = [];     % SLIC labels for the graph cut workflow
            obj.graphcut.noPix = [];    % number of superpixels/supervoxels for the graph cut workflow
            obj.graphcut.Graph{1} = [];    % graph for the graph cut workflow
            %obj.graphcut.PixelIdxList{1} = [];  % position of pixels in each supervoxels
            
            obj.shownLabelObj = [];  % indices of currently displayed superpixels for the objects
            obj.seedObj = [];
            obj.seedBg = [];
            obj.realtimeSwitch = 0;
            obj.timerElapsedMax = .5;   % if segmentation is slower than this time, show the waitbar
            obj.timerElapsed = 9999999; % initialize the timer
            
            % selected default mode
            obj.mode = 'mode2dCurrentRadio';
            
            % obj.updateWidgets(); % done in graphCutToggle_Callback
            
            % select graphcut segmentation
            obj.View.handles.graphCutToggle.Value = 1;
            obj.graphCutToggle_Callback();
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
            obj.listener{2} = addlistener(obj.mibModel, 'setData', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
        end
        
        function closeWindow(obj)
            % closing mibWatershedController  window
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
            % update all widgets of the current window
            
            if obj.mibModel.getImageProperty('blockModeSwitch')
                warndlg(sprintf('Please switch off the Block-mode!\n\nUse the corresponding button in the toolbar'), 'Block-mode is detected');
                obj.View.handles.watershedBtn.Enable = 'off';
            else
                obj.View.handles.watershedBtn.Enable = 'on';
            end
            
            % populate aspect ratio edit box
            pixSize = obj.mibModel.getImageProperty('pixSize');
            minVal = min([pixSize.x pixSize.y pixSize.z]);
            aspect(1) = pixSize.x/minVal;
            aspect(2) = pixSize.y/minVal;
            aspect(3) = pixSize.z/minVal;
            obj.View.handles.aspectRatio.String = sprintf('%.3f %.3f %.3f', aspect(1), aspect(2), aspect(3));
            
            if obj.mibModel.getImageProperty('depth') < 2
                obj.View.handles.mode3dRadio.Enable = 'off';
                obj.View.handles.aspectRatio.Enable = 'off';
                obj.View.handles.mode2dCurrentRadio.Value = 1;
            else
                obj.View.handles.mode3dRadio.Enable = 'on';
                obj.View.handles.aspectRatio.Enable = 'on';
            end
            
            % updating color channels
            % updating color channels
            colorsNo = obj.mibModel.getImageProperty('colors');
            colCh = cell([colorsNo, 1]);
            for i=1:colorsNo
                colCh{i} = sprintf('Ch %d', i);
            end
            if colorsNo < obj.View.handles.imageColChPopup.Value
                obj.View.handles.imageColChPopup.Value = 1;
                obj.View.handles.imageIntensityColorCh.Value = 1;
            end
            obj.View.handles.imageColChPopup.String = colCh;
            obj.View.handles.imageIntensityColorCh.String = colCh;
            
            % populating lists of materials
            obj.updateMaterialsBtn_Callback();
            
            if obj.mibModel.getImageProperty('maskExist') == 0
                obj.View.handles.maskRadio.Enable = 'off';
                obj.View.handles.maskRadio.Value = 0;
                obj.View.handles.selectionRadio.Value = 1;
                obj.View.handles.seedsMaskRadio.Enable = 'off';
                obj.View.handles.seedsMaskRadio.Value = 0;
                obj.View.handles.seedsSelectionRadio.Value = 1;
            else
                obj.View.handles.maskRadio.Enable = 'on';
                obj.View.handles.seedsMaskRadio.Enable = 'on';
            end
            
            % populate subarea edit boxes
            if isempty(obj.graphcut.slic)
                [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', 1, width);
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', 1, height);
                obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', 1, depth);
            else
                obj.importSuperpixelsBtn_Callback(1);
            end
        end
        
        function updateMaterialsBtn_Callback(obj)
            % function updateMaterialsBtn_Callback(obj)
            % callback for the update Materials button
            
            % populating lists of materials
            list = obj.mibModel.getImageProperty('modelMaterialNames');
            if obj.mibModel.getImageProperty('modelExist') == 0 || isempty(list)
                obj.View.handles.modelRadio.Enable = 'off';
                obj.View.handles.selectedMaterialPopup.Enable = 'off';
                obj.View.handles.seedsModelRadio.Enable = 'off';
                obj.View.handles.seedsSelectedMaterialPopup.Enable = 'off';
                obj.View.handles.backgroundMateriaPopup.Value = 1;
                obj.View.handles.backgroundMateriaPopup.String = 'Please create a model with 2 materials: background and object and restart the watershed tool';
                obj.View.handles.backgroundMateriaPopup.BackgroundColor = 'r';
                obj.View.handles.signalMateriaPopup.Value = 1;
                obj.View.handles.signalMateriaPopup.String = 'Please create a model with 2 materials: background and object and restart the watershed tool';
                obj.View.handles.signalMateriaPopup.BackgroundColor = 'r';
                
            else
                selectedMaterial = obj.mibModel.getImageProperty('selectedMaterial') - 2;
                obj.View.handles.backgroundMateriaPopup.Value = 1;
                obj.View.handles.backgroundMateriaPopup.String = list;
                obj.View.handles.backgroundMateriaPopup.BackgroundColor = 'w';
                obj.View.handles.signalMateriaPopup.Value = numel(list);
                obj.View.handles.signalMateriaPopup.String = list;
                obj.View.handles.signalMateriaPopup.BackgroundColor = 'w';
                
                obj.View.handles.selectedMaterialPopup.String = list;
                obj.View.handles.selectedMaterialPopup.Value = max([selectedMaterial 1]);
                obj.View.handles.seedsSelectedMaterialPopup.String = list;
                obj.View.handles.seedsSelectedMaterialPopup.Value = max([selectedMaterial 1]);
            end
        end
        
        function graphCutToggle_Callback(obj)
            % function graphCutToggle_Callback(obj)
            % callback for selection of the graphcut segmentation
            
            bgColor = obj.View.handles.resetDimsBtn.BackgroundColor;
            obj.View.handles.graphCutToggle.Value = 1;
            obj.View.handles.imageSegmentationToggle.Value = 0;
            obj.View.handles.objectSeparationToggle.Value = 0;
            obj.View.handles.graphCutToggle.Value = 1;
            obj.View.handles.imageSegmentationPanel.Visible = 'on';
            obj.View.handles.objectSeparationPanel.Visible = 'off';
            obj.View.handles.imageSegmentationToggle.BackgroundColor = bgColor;
            obj.View.handles.objectSeparationToggle.BackgroundColor = bgColor;
            obj.View.handles.graphCutToggle.BackgroundColor = 'g';
            obj.View.handles.superpixelsStepsPanel.Visible = 'on';
            obj.View.handles.preprocPanel.Visible = 'off';
            obj.updateWidgets();     % update widgets of the watershed window
        end
        
        function imageSegmentationToggle_Callback(obj)
            % function imageSegmentationToggle_Callback(obj)
            % callback for selection of imageSegmentationToggle - classical
            % watershed
            
            bgColor = obj.View.handles.resetDimsBtn.BackgroundColor;
            obj.View.handles.imageSegmentationToggle.Value = 1;
            obj.View.handles.imageSegmentationToggle.Value = 1;
            obj.View.handles.objectSeparationToggle.Value = 0;
            obj.View.handles.graphCutToggle.Value = 0;
            obj.View.handles.imageSegmentationPanel.Visible = 'on';
            obj.View.handles.objectSeparationPanel.Visible = 'off';
            obj.View.handles.imageSegmentationToggle.BackgroundColor = 'g';
            obj.View.handles.objectSeparationToggle.BackgroundColor = bgColor;
            obj.View.handles.graphCutToggle.BackgroundColor = bgColor;
            obj.View.handles.superpixelsStepsPanel.Visible = 'off';
            obj.View.handles.preprocPanel.Visible = 'on';
            obj.updateWidgets();     % update widgets of the watershed window
        end
        
        function objectSeparationToggle_Callback(obj)
            % function objectSeparationToggle_Callback(obj)
            % callback for objectSeparationToggle -> enable the object
            % separation mode
            bgColor = obj.View.handles.resetDimsBtn.BackgroundColor;
            obj.View.handles.objectSeparationToggle.Value = 1;
            obj.View.handles.imageSegmentationToggle.Value = 0;
            obj.View.handles.objectSeparationToggle.Value = 1;
            obj.View.handles.graphCutToggle.Value = 0;
            obj.View.handles.imageSegmentationPanel.Visible = 'off';
            obj.View.handles.objectSeparationPanel.Visible = 'on';
            obj.View.handles.imageSegmentationToggle.BackgroundColor = bgColor;
            obj.View.handles.objectSeparationToggle.BackgroundColor = 'g';
            obj.View.handles.graphCutToggle.BackgroundColor = bgColor;
            obj.updateWidgets();     % update widgets of the watershed window
        end
        
        function aspectRatio_Callback(obj)
            % function aspectRatio_Callback(obj)
            % callback for edit of aspect ratio edit boxes
            
            val = obj.View.handles.aspectRatio.String;
            val = str2num(val); %#ok<ST2NM>
            if isempty(val) || numel(val) ~= 3 || min(val) <= 0
                errordlg(sprintf('Wrong aspect ratio!\nPlease enter 3 numbers above 0 and try again!'), 'Error!');
                pixSize = obj.mibModel.getImageProperty('pixSize');
                minVal = min([pixSize.x pixSize.y pixSize.z]);
                aspect(1) = pixSize.x/minVal;
                aspect(2) = pixSize.y/minVal;
                aspect(3) = pixSize.z/minVal;
                obj.View.handles.aspectRatio.String = sprintf('%.3f %.3f %.3f', aspect(1), aspect(2), aspect(3));
                return;
            end
        end
        
        function clearPreprocessBtn_Callback(obj)
            % function clearPreprocessBtn_Callback(obj)
            % callback for press of clearPreprocessBtn; clear the preprocessed data
            
            obj.preprocImg = NaN;
            obj.graphcut = struct();
            obj.graphcut.slic = [];     % SLIC labels for the graph cut workflow
            obj.graphcut.noPix = [];    % number of superpixels/supervoxels for the graph cut workflow
            obj.graphcut.Graph = [];    % graph for the graph cut workflow
            obj.graphcut.Graph{1} = [];    % graph for the graph cut workflow
            %obj.graphcut.PixelIdxList = [];  % position of pixels in each supervoxels
            %obj.graphcut.PixelIdxList{1} = [];  % position of pixels in each supervoxels
            
            if obj.View.handles.mode2dRadio.Value == 1
                depth = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
                obj.shownLabelObj = cell([max(depth)-min(depth)+1 1]);  % indices of currently displayed superpixels for the objects
            else
                obj.shownLabelObj = [];  % indices of currently displayed superpixels for the objects    
            end
            
            obj.seedObj = [];
            obj.seedBg = [];
            
            bgcol = obj.View.handles.clearPreprocessBtn.BackgroundColor;
            obj.View.handles.preprocessBtn.BackgroundColor = bgcol;
            obj.View.handles.superpixelsBtn.BackgroundColor = bgcol;
            obj.View.handles.superpixelsCountText.String = sprintf('Superpixels count: 0');
            
            val = str2num(obj.View.handles.binSubareaEdit.String); %#ok<ST2NM>
            % disable the realtime mode
            if sum(val) ~= 2
                obj.View.handles.realtimeCheck.Value = 0;
                obj.realtimeSwitch = 0;
                obj.View.handles.realtimeCheck.Enable = 'off';
                obj.View.handles.realtimeText.Enable = 'off';
            else
                obj.View.handles.realtimeCheck.Enable = 'on';
                obj.View.handles.realtimeText.Enable = 'on';
            end
            
        end
        
        function mode2dRadio_Callback(obj, hObject)
            % function mode2dRadio_Callback(obj, hObject)
            % callback for selection of the segmentation mode
            %
            % Parameters:
            % hObject: a handle to the selected radio button
            % @li 'mode2dCurrentRadio'
            % @li 'mode2dRadio'
            % @li 'mode3dRadio'
            
            if ~isnan(obj.preprocImg(1)) || ~isempty(obj.graphcut.noPix)
                button =  questdlg(sprintf('!!! Attention !!!\n\nThe pre-processed data will be removed!'),...
                    'Warning!', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button,'Cancel')
                    obj.View.handles.(obj.mode).Value = 1;
                    return;
                end
                obj.clearPreprocessBtn_Callback();    % clear preprocessed data
            end
            obj.mode = hObject.Tag;
            switch obj.mode
                case 'mode3dRadio'
                    obj.View.handles.chopXedit.Enable = 'on';
                    obj.View.handles.chopYedit.Enable = 'on';
                otherwise
                    obj.View.handles.chopXedit.Enable = 'off';
                    obj.View.handles.chopYedit.Enable = 'off';
            end
            hObject.Value = 1;
        end
        
        function eigenSigmaEdit_Callback(obj)
            % function eigenSigmaEdit_Callback(obj)
            % callback for change of eigenSigmaEdit
            
            eigenSigma = str2double(obj.View.handles.eigenSigmaEdit.String);
            if eigenSigma < 1 && ~strcmp(obj.mode, 'mode3dRadio')
                warndlg('Sigma should be larger than 1!', 'Wrong Sigma');
                obj.View.handles.eigenSigmaEdit.String = '1.6';
            end
        end
        
        
        function checkDimensions(obj, hObject)
            % function checkDimensions(parameter)
            % check entered dimensions for the dataset to precess
            %
            % Parameters:
            % hObject: handle on the selected object
            
            text = hObject.String;
            typedValue = str2num(text); %#ok<ST2NM>
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            switch hObject.Tag
                case 'xSubareaEdit'
                    maxVal = width;
                case 'ySubareaEdit'
                    maxVal = height;
                case 'zSubareaEdit'
                    maxVal = depth;
            end
            if min(typedValue) < 1 || max(typedValue) > maxVal
                hObject.String = sprintf('1:%d', maxVal); %#ok<MCNPR>
                errordlg('Please check the values!','Wrong parameters!');
                return;
            end
            obj.clearPreprocessBtn_Callback();    % clear preprocessed data
        end
        
        function resetDimsBtn_Callback(obj)
            % function resetDimsBtn_Callback(obj)
            % callback for resetDimsBtn - reset edit boxes with dataset dimensions
            
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            obj.View.handles.xSubareaEdit.String = sprintf('1:%d', width);
            obj.View.handles.ySubareaEdit.String = sprintf('1:%d', height);
            obj.View.handles.zSubareaEdit.String = sprintf('1:%d', depth);
            obj.View.handles.binSubareaEdit.String = '1; 1';
            obj.clearPreprocessBtn_Callback();    % clear preprocessed data
        end
        
        function currentViewBtn_Callback(obj)
            % function currentViewBtn_Callback(obj)
            % callback for press of currentViewBtn; defines dataset from
            % the current view
            [yMin, yMax, xMin, xMax] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage();
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', xMin, xMax);
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', yMin, yMax);
            obj.clearPreprocessBtn_Callback();    % clear preprocessed data
        end
        
        function subAreaFromSelectionBtn_Callback(obj)
            % function subAreaFromSelectionBtn_Callback(obj)
            % callback for press of subAreaFromSelectionBtn; select subArea
            % from the current selection layer
            
            bgColor = obj.View.handles.subAreaFromSelectionBtn.BackgroundColor;
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = 'r';
            drawnow;
            if strcmp(obj.mode, 'mode2dCurrentRadio')
                img = cell2mat(obj.mibModel.getData2D('selection'));
                STATS = regionprops(img, 'BoundingBox');
                if numel(STATS) == 0
                    errordlg(sprintf('!!! Error !!!\n\nSelection layer was not found!\nPlease make sure that the Selection layer\nis shown in the Image View panel'), ...
                        'Missing Selection');
                    obj.resetDimsBtn_Callback();
                    obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
                    return;
                end
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(3)-1);
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(4)-1);
            else
                img = cell2mat(obj.mibModel.getData3D('selection', NaN, 4));
                STATS = regionprops(img, 'BoundingBox');
                if numel(STATS) == 0
                    errordlg(sprintf('!!! Error !!!\n\nSelection layer was not found!\nPlease make sure that the Selection layer\n is shown in the Image View panel'),...
                        'Missing Selection');
                    obj.resetDimsBtn_Callback();
                    obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
                    return;
                end
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(1)), ceil(STATS(1).BoundingBox(1))+STATS(1).BoundingBox(4)-1);
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(2)), ceil(STATS(1).BoundingBox(2))+STATS(1).BoundingBox(5)-1);
                obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', ceil(STATS(1).BoundingBox(3)), ceil(STATS(1).BoundingBox(3))+STATS(1).BoundingBox(6)-1);
            end
            obj.clearPreprocessBtn_Callback();    % clear preprocessed data
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
        end
        
        function binSubareaEdit_Callback(obj, hObject)
            % function binSubareaEdit_Callback(obj, hObject)
            % callback for selection of subarea for segmentation
            %
            % Parameters:
            % hObject: handle to the object
            
            val = str2num(hObject.String); %#ok<ST2NM>
            if isempty(val)
                val = [1; 1];
            elseif isnan(val(1)) || min(val) <= .5
                val = [1;1];
            else
                val = round(val);
            end
            
            hObject.String = sprintf('%d; %d',val(1), val(2));
            obj.clearPreprocessBtn_Callback();    % clear preprocessed data
        end
        
        function preprocessBtn_Callback(obj)
            % function preprocessBtn_Callback(obj)
            % callback for press of preprocessBtn; preprocess images for
            % segmentation
            
            col_channel = obj.View.handles.imageColChPopup.Value;
            gradientSw = obj.View.handles.gradientCheck.Value;
            eigenSw = obj.View.handles.eigenvalueCheck.Value;
            
            % no options are selected for preprocessing
            if gradientSw == 0 && eigenSw == 0
                return;
            end
            
            obj.timerElapsed = 9999999;     % reinitialize the timer
            
            eigenSigma = str2double(obj.View.handles.eigenSigmaEdit.String);
            invertImage = obj.View.handles.signalPopup.Value;    % if == 1 image should be inverted, black-on-white
            
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String); %#ok<ST2NM>
            depth = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = [min(width) max(width)];
            getDataOptions.y = [min(height) max(height)];
            getDataOptions.z = [min(depth) max(depth)];
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binThick = ceil((max(depth)-min(depth)+1)/binVal(2));
            
            wb = waitbar(0, 'Please wait...', 'Name', 'Pre-processing...');
            
            hy = fspecial('sobel'); % for gradient filter
            hx = hy';               % for gradient filter
            switch obj.mode
                case 'mode2dRadio'
                    img = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, NaN, col_channel, getDataOptions)));   % get dataset
                    if binVal(1) ~= 1   % bin data
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = max(thick)-min(thick)+1;
                        resizeOptions.method = 'bicubic';
                        img = mibResize3d(img, [], resizeOptions);
                        %img = resizeVolume(img, [binHeight, binWidth, max(thick)-min(thick)+1], 'bicubic');
                    end
                    if invertImage == 1
                        img = imcomplement(img);
                    end
                    obj.preprocImg = zeros([size(img,1), size(img,2),size(img,3)], 'uint8');
                    no_stacks = size(img, 3);
                    
                    for sliceId=1:no_stacks
                        if gradientSw == 1 && eigenSw == 1
                            Iy = imfilter(double(img(:,:,sliceId)), hy, 'replicate');
                            Ix = imfilter(double(img(:,:,sliceId)), hx, 'replicate');
                            gradImg = sqrt(Ix.^2 + Iy.^2);
                            img(:,:,sliceId) = uint8(gradImg/max(max(max(gradImg)))*255);   % convert to 8bit
                            
                            [Dxx, Dxy, Dyy] = Hessian2D(double(img(:,:,sliceId)), eigenSigma);
                            [~, Lambda1, ~, ~] = eig2image(Dxx, Dxy, Dyy);
                            minVal = min(min(Lambda1));
                            maxVal = max(max(Lambda1));
                            img(:,:,sliceId) = uint8((Lambda1-minVal)/(maxVal-minVal)*255);
                            invertImage = 1;
                        elseif gradientSw == 1 && eigenSw == 0
                            Iy = imfilter(double(img(:,:,sliceId)), hy, 'replicate');
                            Ix = imfilter(double(img(:,:,sliceId)), hx, 'replicate');
                            gradImg = sqrt(Ix.^2 + Iy.^2);
                            img(:,:,sliceId) = uint8(gradImg/max(max(max(gradImg)))*255);   % convert to 8bit
                            invertImage = 0;
                        elseif gradientSw == 0 && eigenSw == 1
                            [Dxx, Dxy, Dyy] = Hessian2D(double(img(:,:,sliceId)), eigenSigma);
                            [~,Lambda1,~,~] = eig2image(Dxx, Dxy, Dyy);
                            minVal = min(min(Lambda1));
                            maxVal = max(max(Lambda1));
                            img(:,:,sliceId) = uint8((Lambda1-minVal)/(maxVal-minVal)*255);
                            invertImage = abs(invertImage - 1);
                        end
                        if invertImage == 1
                            img = imcomplement(img);
                        end
                        
                        waitbar(sliceId/no_stacks, wb);
                    end
                case 'mode2dCurrentRadio'
                    img = squeeze(cell2mat(obj.mibModel.getData2D('image', NaN, NaN, col_channel, getDataOptions)));   % get slice
                    if binVal(1) ~= 1   % bin data
                        img = imresize(img, [binHeight binWidth], 'bicubic');
                    end
                    
                    obj.preprocImg = zeros(size(img), 'uint8');
                    
                    if gradientSw == 1 && eigenSw == 1
                        Iy = imfilter(double(img), hy, 'replicate');
                        Ix = imfilter(double(img), hx, 'replicate');
                        gradImg = sqrt(Ix.^2 + Iy.^2);
                        img = uint8(gradImg/max(max(max(gradImg)))*255);   % convert to 8bit
                        
                        [Dxx, Dxy, Dyy] = Hessian2D(double(img), eigenSigma);
                        [~,Lambda1,~,~] = eig2image(Dxx, Dxy, Dyy);
                        minVal = min(min(Lambda1));
                        maxVal = max(max(Lambda1));
                        img = uint8((Lambda1-minVal)/(maxVal-minVal)*255);
                        invertImage = 1;
                    elseif gradientSw == 1 && eigenSw == 0
                        Iy = imfilter(double(img), hy, 'replicate');
                        Ix = imfilter(double(img), hx, 'replicate');
                        gradImg = sqrt(Ix.^2 + Iy.^2);
                        img = uint8(gradImg/max(max(max(gradImg)))*255);   % convert to 8bit
                        invertImage = 0;
                    elseif gradientSw == 0 && eigenSw == 1
                        [Dxx, Dxy, Dyy] = Hessian2D(double(img), eigenSigma);
                        [~,Lambda1,~,~] = eig2image(Dxx, Dxy, Dyy);
                        minVal = min(min(Lambda1));
                        maxVal = max(max(Lambda1));
                        img = uint8((Lambda1-minVal)/(maxVal-minVal)*255);
                        invertImage = abs(invertImage - 1);
                    end
                    
                    if invertImage == 1
                        img = imcomplement(img);
                    end
                    waitbar(.8, wb);
                case 'mode3dRadio'
                    img = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, 4, col_channel, getDataOptions)));   % get dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = binThick;
                        resizeOptions.method = 'bicubic';
                        img = mibResize3d(img, [], resizeOptions);
                        %img = resizeVolume(img, [binHeight, binWidth, binThick], 'bicubic');
                    end
                    
                    obj.preprocImg = zeros(size(img), 'uint8');
                    waitbar(0.05, wb);
                    if gradientSw == 1 && eigenSw == 1
                        waitbar(0.05, wb, sprintf('Calculating gradient image...\nPlease wait...'));
                        [Ix,Iy,Iz] = gradient(double(img));
                        img = sqrt(Ix.^2 + Iy.^2 + Iz.^2);
                        %img = uint8(img/max(max(max(img)))*255);   % convert to 8bit
                        waitbar(0.45, wb, sprintf('Calculating Hessian 3D...\nPlease wait...'));
                        
                        [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz] = Hessian3D(img, eigenSigma);
                        waitbar(0.75, wb, sprintf('Calculation of eigen values...\nPlease wait...'));
                        [~, ~, Lambda3] = eig3volume(Dxx,Dxy,Dxz,Dyy,Dyz,Dzz);
                        minVal = min(min(min(Lambda3)));
                        maxVal = max(max(max(Lambda3)));
                        img = uint8((Lambda3-minVal)/(maxVal-minVal)*255);
                        invertImage = 1;
                    elseif gradientSw == 1 && eigenSw == 0
                        waitbar(0.05, wb, sprintf('Calculating gradient image...\nPlease wait...'));
                        [Ix,Iy,Iz] = gradient(double(img));
                        img = sqrt(Ix.^2 + Iy.^2 + Iz.^2);
                        img = uint8(img/max(max(max(img)))*255);   % convert to 8bit
                        invertImage = 0;
                    elseif gradientSw == 0 && eigenSw == 1
                        waitbar(0.45, wb, sprintf('Calculating Hessian 3D...\nPlease wait...'));
                        [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz] = Hessian3D(double(img), eigenSigma);
                        waitbar(0.75, wb, sprintf('Calculation of eigen values...\nPlease wait...'));
                        [~, ~, Lambda3] = eig3volume(Dxx,Dxy,Dxz,Dyy,Dyz,Dzz);
                        minVal = min(min(min(Lambda3)));
                        maxVal = max(max(max(Lambda3)));
                        img = uint8((Lambda3-minVal)/(maxVal-minVal)*255);
                        invertImage = abs(invertImage - 1);
                    end
                    
                    waitbar(0.8, wb);
                    if invertImage == 1
                        img = imcomplement(img);
                    end
                    waitbar(0.9, wb);
            end
            obj.preprocImg = img;
            
            if obj.View.handles.previewCheck.Value
                if size(obj.preprocImg, 3) == 1
                    eventdata = ToggleEventData(obj.preprocImg);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
                else
                    eventdata = ToggleEventData(obj.preprocImg(:, :, obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber()));   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
                end
            end
            
            if obj.View.handles.exportPreprocessCheck.Value
                assignin('base', 'preprocImg', obj.preprocImg);
                text1 = sprintf('MIB-Watershed: a variable "preprocImg" [%d x %d x %d] with the preprocessed data has been created!', ...
                    size(obj.preprocImg,1), size(obj.preprocImg,2), size(obj.preprocImg,3));
                fprintf(text1);
            end
            
            obj.View.handles.preprocessBtn.BackgroundColor = 'g';
            waitbar(1, wb);
            delete(wb);
        end
        
        function watershedBtn_Callback(obj)
            % function watershedBtn_Callback(obj)
            % callback for press watershedBtn; start segmentation
            
            tic
            % define type of the objects to backup
            if obj.View.handles.imageSegmentationToggle.Value || obj.View.handles.graphCutToggle.Value
                type = 'mask';
            else
                type = 'selection';
            end
            
            % backup current data
            if ~strcmp(obj.mode, 'mode2dCurrentRadio')
                obj.mibModel.mibDoBackup(type, 1);
            else
                obj.mibModel.mibDoBackup(type, 0);
            end
            
            % select and start watershed
            if obj.View.handles.imageSegmentationToggle.Value
                obj.doImageSegmentation();
                obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
                notify(obj.mibModel, 'showMask');
            elseif obj.View.handles.graphCutToggle.Value
                % clear list of selected pixels
                obj.seedObj = cell([size(obj.graphcut.slic, 3), 1]);
                obj.seedBg = cell([size(obj.graphcut.slic, 3), 1]);
                
                if obj.View.handles.mode2dRadio.Value == 1
                    thick = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>
                    startIndex = min(thick);
                    endIndex = max(thick);
                    obj.shownLabelObj = cell([endIndex-startIndex+1, 1]);
                else
                    obj.shownLabelObj = [];    
                end
                
                realtimeSwitchLocal = obj.realtimeSwitch;
                obj.realtimeSwitch = 0;
                obj.doGraphcutSegmentation();
                obj.realtimeSwitch = realtimeSwitchLocal;
                obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
                notify(obj.mibModel, 'showMask');
            else
                obj.doObjectSeparation();
            end
            obj.timerElapsed = toc;
            fprintf('Elapsed time: %f seconds\n', obj.timerElapsed)
            notify(obj.mibModel, 'plotImage');
        end
        
        function doGraphcutSegmentation(obj)
            % function doGraphcutSegmentation(obj)
            % make graphcut segmentation
            
            bgMaterialId = obj.View.handles.backgroundMateriaPopup.Value;    % index of the background label
            seedMaterialId = obj.View.handles.signalMateriaPopup.Value;    % index of the signal label
            noMaterials = numel(obj.View.handles.signalMateriaPopup.String);    % number of materials in the model

            if bgMaterialId == seedMaterialId
                errordlg(sprintf('!!! Error !!!\nWrong selection of materials!\nPlease select two different materials in the Background and Object combo boxes of the Image segmentation settings panel'))
                return;
            end
            
            if isempty(obj.graphcut.noPix)
                obj.superpixelsBtn_Callback();
            end
            if obj.timerElapsed > obj.timerElapsedMax
                wb = waitbar(0, sprintf('Graphcut segmentation...\nPlease wait...'), 'Name', 'Maxflow/Mincut');
            end
            
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String);  %#ok<ST2NM>
            thick = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>
            
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = [min(width) max(width)];
            getDataOptions.y = [min(height) max(height)];
            getDataOptions.z = [min(thick) max(thick)];
            getDataOptions.blockModeSwitch = 0;

            % generate a structure for conversion of pixels in the 3D
            % cropped graphcut
            convertPixelOpt.x = getDataOptions.x;
            convertPixelOpt.y = getDataOptions.y;
            convertPixelOpt.z = getDataOptions.z;
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binThick = ceil((max(thick)-min(thick)+1)/binVal(2));
            
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                obj.mibModel.I{obj.mibModel.Id}.clearMask();   % clear or delete mask for uint8 model type
            end
            
            if obj.View.handles.mode2dCurrentRadio.Value
                % initialize
                negIds = []; 
                posIds = [];
                
                seedImg = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, NaN, getDataOptions));   % get slice
                
                % tweak to work also with a current view mode
                if size(obj.graphcut.slic, 3) > 1
                    sliceNo = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                    currSlic = obj.graphcut.slic(:,:,sliceNo);
                else
                    currSlic = obj.graphcut.slic;
                    sliceNo = 1;
                end
                
                if binVal(1) ~= 1   % bin data
                    seedImg = imresize(seedImg, [binHeight binWidth], 'nearest');
                end
                
                %     if noMaterials > 2  % when more than 2 materials present keep only background and color
                %         seedImg(seedImg~=seedMaterialId & seedImg~=0) = bgMaterialId;
                %     end
                
                labelObj = unique(currSlic(seedImg==seedMaterialId));
                if isempty(labelObj)
                    if obj.timerElapsed > obj.timerElapsedMax
                        delete(wb); 
                    end
                    return; 
                end
                labelBg = unique(currSlic(seedImg==bgMaterialId));
                
                if obj.graphcut.superPixType == 2 && strcmp(obj.graphcut.dilateMode, 'post')  % watershed
                    % remove 0 indices
                    labelObj(labelObj==0) = [];
                    labelBg(labelBg==0) = [];
                end
                
                % generate data term
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.45, wb, sprintf('Generating data term\nPlease wait...'));
                end
                
                T = zeros([obj.graphcut.noPix(sliceNo), 2])+0.5;
                % remove from labelObj those that are also found in labelBg
                labelObj(ismember(labelObj, labelBg)) = [];
                
                T(labelObj, 1) = 0;        T(labelObj, 2) = 99999;
                T(labelBg,  1) = 99999;      T(labelBg,  2) = 0;
                
                T=sparse(T);
                
                %hView = view(biograph(handles.graphcut.Graph{sliceNo},[],'ShowArrows','off','ShowWeights','on'));
                %set(hView.Nodes(labelObj), 'color',[0 1 0]);
                %set(hView.Nodes(labelBg), 'color',[1 0 0]);
                
                [~, labels] = maxflow_v222(obj.graphcut.Graph{sliceNo}, T);
                
                if isempty(obj.shownLabelObj)
                    obj.shownLabelObj = labels;
                    Mask = zeros(size(seedImg),'uint8');
                else
                    Mask = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, NaN, getDataOptions));   % get slice
                    negIds = obj.shownLabelObj - labels;
                    posIds = labels - obj.shownLabelObj;
                    obj.shownLabelObj = labels;
                end
                
                % % using ismembc instead of ismember because it is a bit faster
                % % however, the vertcut with known indeces of pixels is faster!
                % indexLabel = find(labels>0);
                % Mask(ismember(double(currSlic), indexLabel)) = 1;
                if isfield(obj.graphcut, 'PixelIdxList')
                    if ~isempty(negIds)
                        Mask(vertcat(obj.graphcut.PixelIdxList{negIds>0})) = 0;  % remove background superpixels
                        Mask(vertcat(obj.graphcut.PixelIdxList{posIds>0})) = 1;  % add object superpixels
                    else
                        Mask(vertcat(obj.graphcut.PixelIdxList{labels>0})) = 1;    
                    end
                else
                    if ~isempty(negIds)
                        negIds = find(negIds > 0);
                        posIds = find(posIds > 0);
                        if isa(currSlic, 'uint8')
                            negIds = uint8(negIds);
                            posIds = uint8(posIds);
                        elseif isa(currSlic, 'uint16')
                            negIds = uint16(negIds);
                            posIds = uint16(posIds);
                        else
                            negIds = uint32(negIds);
                            posIds = uint32(posIds);
                        end
                        if ~isempty(negIds); Mask(ismember(currSlic, negIds)) = 0; end
                        if ~isempty(posIds); Mask(ismember(currSlic, posIds)) = 1; end
                    else
                        indexLabel = find(labels>0);
                        if isa(currSlic, 'uint8')
                            indexLabel = uint8(indexLabel);
                        elseif isa(currSlic, 'uint16')
                            indexLabel = uint16(indexLabel);
                        else
                            indexLabel = uint32(indexLabel);
                        end
                        %Mask(ismembc(currSlic, indexLabel)) = 1;
                        Mask(ismember(currSlic, indexLabel)) = 1;
                    end
                end
                Mask(seedImg==bgMaterialId) = 0;    % remove background pixels
                
                % remove boundaries between superpixels
                if obj.graphcut.superPixType == 2 && strcmp(obj.graphcut.dilateMode, 'post')  % watershed
                    Mask = imdilate(Mask, ones(3));
                end
                
                if binVal(1) ~= 1   % bin data
                    Mask = imresize(Mask, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                end
                obj.mibModel.setData2D('mask', Mask, NaN, NaN, NaN, getDataOptions);   % set slice
            elseif obj.View.handles.mode2dRadio.Value
                if obj.realtimeSwitch == 0
                    startIndex = min(thick);
                    endIndex = max(thick);
                    index = 1;
                else
                    startIndex = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                    endIndex = startIndex;
                    index = startIndex - min(thick) + 1;
                end
                
                total = endIndex-startIndex+1;
                for sliceNo = startIndex:endIndex
                    negIds = []; 
                    seedImg = cell2mat(obj.mibModel.getData2D('model', sliceNo, NaN, NaN, getDataOptions));   % get slice
                    
                    if binVal(1) ~= 1   % bin data
                        seedImg = imresize(seedImg, [binHeight binWidth], 'nearest');
                    end
                    %if noMaterials > 2  % when more than 2 materials present keep only background and color
                    %    seedImg(seedImg~=seedMaterialId & seedImg~=bgMaterialId) = 0;
                    %end
                    currSlic = obj.graphcut.slic(:,:,index);
                    labelObj = unique(currSlic(seedImg==seedMaterialId));
                    if isempty(labelObj); index = index + 1; continue; end
                    
                    labelBg = unique(currSlic(seedImg==bgMaterialId));
                    
                    if obj.graphcut.superPixType == 2 && strcmp(obj.graphcut.dilateMode, 'post')  % watershed
                        % remove 0 indices
                        labelObj(labelObj==0) = [];
                        labelBg(labelBg==0) = [];
                    end
                    
                    % remove from labelObj those that are also found in labelBg
                    labelObj(ismember(labelObj, labelBg)) = [];
                    
                    % generate data term
                    T = zeros([obj.graphcut.noPix(index), 2])+0.5;
                    T(labelObj, 1) = 0;
                    T(labelObj, 2) = 99999;
                    T(labelBg, 1) = 99999;
                    T(labelBg, 2) = 0;
                    T=sparse(T);
                    
                    %[~, labels] = maxflow(obj.graphcut.Graph{index}, T);
                    [~, labels] = maxflow_v222(obj.graphcut.Graph{index}, T);
                    
                    if isempty(obj.shownLabelObj{index})
                        obj.shownLabelObj{index} = labels;
                        Mask = zeros(size(seedImg),'uint8');
                    else
                        Mask = cell2mat(obj.mibModel.getData2D('mask', sliceNo, NaN, NaN, getDataOptions));   % get slice
                        negIds = obj.shownLabelObj{index} - labels;
                        posIds = labels - obj.shownLabelObj{index};
                        obj.shownLabelObj{index} = labels;
                    end
                    
                    % % using ismembc instead of ismember because it is a bit faster
                    % % however, the vertcut with known indeces of pixels is ~x10 times
                    % faster!
                    % indexLabel = find(labels>0);
                    % Mask(ismember(double(currSlic), indexLabel)) = 1;
                    if isfield(obj.graphcut, 'PixelIdxList')
                        if ~isempty(negIds)
                            Mask(vertcat(obj.graphcut.PixelIdxList{index}{negIds>0})) = 0;  % remove background superpixels
                            Mask(vertcat(obj.graphcut.PixelIdxList{index}{posIds>0})) = 1;  % add object superpixels
                        else
                            Mask(vertcat(obj.graphcut.PixelIdxList{index}{labels>0})) = 1;
                        end
                    else
                        if ~isempty(negIds)
                            negIds = find(negIds > 0);
                            posIds = find(posIds > 0);
                            if isa(currSlic, 'uint8')
                                negIds = uint8(negIds);
                                posIds = uint8(posIds);
                            elseif isa(currSlic, 'uint16')
                                negIds = uint16(negIds);
                                posIds = uint16(posIds);
                            else
                                negIds = uint32(negIds);
                                posIds = uint32(posIds);
                            end
                            if ~isempty(negIds); Mask(ismember(currSlic, negIds)) = 0; end
                            if ~isempty(posIds); Mask(ismember(currSlic, posIds)) = 1; end
                        else
                            indexLabel = find(labels>0);
                            if isa(currSlic, 'uint8')
                                indexLabel = uint8(indexLabel);
                            elseif isa(currSlic, 'uint16')
                                indexLabel = uint16(indexLabel);
                            else
                                indexLabel = uint32(indexLabel);
                            end
                            %Mask(ismembc(currSlic, indexLabel)) = 1;
                            Mask(ismember(currSlic, indexLabel)) = 1;
                        end
                    end
                    
                    Mask(seedImg==bgMaterialId) = 0;    % remove background pixels
                    
                    % remove boundaries between superpixels
                    if obj.graphcut.superPixType == 2 && strcmp(obj.graphcut.dilateMode, 'post')  % watershed
                        Mask = imdilate(Mask, ones(3));
                    end
                    
                    if binVal(1) ~= 1   % bin data
                        Mask = imresize(Mask, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                    end
                    obj.mibModel.setData2D('mask', Mask, sliceNo, NaN, NaN, getDataOptions);   % set slice
                    if obj.timerElapsed > obj.timerElapsedMax
                        waitbar(index/total, wb, sprintf('Calculating...\nPlease wait...'));
                    end
                    index = index + 1;
                end
            else        % do it for 3D
                % initialize
                negIds = []; 
                posIds = [];
                
                if isempty(obj.shownLabelObj)
                    depth = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
                    obj.seedObj = cell([max(depth)-min(depth)+1 1]);
                    obj.seedBg = cell([max(depth)-min(depth)+1 1]);
                    
                    seedImg = cell2mat(obj.mibModel.getData3D('model', NaN, 4, NaN, getDataOptions));   % get dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        if obj.timerElapsed > obj.timerElapsedMax
                            waitbar(.05, wb, sprintf('Binning the labels\nPlease wait...'));
                        end
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = binThick;
                        resizeOptions.method = 'nearest';
                        seedImg = mibResize3d(seedImg, [], resizeOptions);
                    end
                else
                    sliceId = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber()-min(thick)+1;
                    if size(obj.graphcut.slic, 3) < sliceId     % check for out of bounaries
                        if obj.timerElapsed > obj.timerElapsedMax
                            delete(wb);
                        end
                        return;
                    end
                    getDataOptions.z = [sliceId, sliceId];
                    seedImg = cell2mat(obj.mibModel.getData2D('model', NaN, 4, NaN, getDataOptions));   % get dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = 1;
                        resizeOptions.method = 'nearest';
                        seedImg = mibResize3d(seedImg, [], resizeOptions);
                    end
                end
                
                
                %     if noMaterials > 2  % when more than 2 materials present keep only background and color
                %         seedImg(seedImg~=seedMaterialId & seedImg~=0) = bgMaterialId;
                %     end
                
                % define labeled object
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.35, wb, sprintf('Definfing the labels\nPlease wait...'));
                end
                if isempty(obj.shownLabelObj)   % generate for 3D
                    for sliceId = 1:size(obj.graphcut.slic, 3)
                        currSlicImg = obj.graphcut.slic(:, :, sliceId);
                        currSeedImg = seedImg(:, :, sliceId);
                        obj.seedObj{sliceId} = unique(currSlicImg(currSeedImg==seedMaterialId));
                        if noMaterials == 2
                            obj.seedBg{sliceId} = unique(currSlicImg(currSeedImg==bgMaterialId));
                        else
                            % combine bg and all other materials to background    
                            obj.seedBg{sliceId} = unique(currSlicImg(~ismember(currSeedImg, [0 seedMaterialId])));
                        end
                        %labelBg(ismember(labelBg, labelObj)) = [];
                    end
                else    % work with the current slice in 2D
                    currSlicImg = obj.graphcut.slic(:, :, sliceId);
                    obj.seedObj{sliceId} = unique(currSlicImg(seedImg==seedMaterialId));
                    if noMaterials == 2
                        obj.seedBg{sliceId} = unique(currSlicImg(seedImg==bgMaterialId));
                    else
                        % combine bg and all other materials to background
                        obj.seedBg{sliceId} = unique(currSlicImg(~ismember(seedImg, [0 seedMaterialId])));
                    end
                end
                
                % when two seeds overlap give preference to the background
                labelBg = vertcat(obj.seedBg{:});
                for sliceId = 1:size(obj.graphcut.slic, 3)
                    [commonVal, bgIdx] = intersect(obj.seedObj{sliceId}, labelBg);
                    obj.seedObj{sliceId}(bgIdx) = [];
                end
                labelObj = vertcat(obj.seedObj{:});
                
%                 if obj.graphcut.superPixType == 2 && strcmp(obj.graphcut.dilateMode, 'post')   % watershed
%                     % remove 0 indices
%                     labelObj(labelObj==0) = [];
%                     labelBg(labelBg==0) = [];
%                 end
                
                % generate data term
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.45, wb, sprintf('Generating data term\nPlease wait...'));
                end
                T = zeros([obj.graphcut.noPix, 2])+0.5;
                T(labelObj, 1) = 0;
                T(labelObj, 2) = 999999;
                T(labelBg, 1) = 999999;
                T(labelBg, 2) = 0;
                
                %T(labelObj, 2) = 0;
                %T(labelObj, 1) = 999999;
                %T(labelBg, 2) = 999999;
                %T(labelBg, 1) = 0;
                
                T=sparse(T);
                %     % testing BK_matlab
                %     T = T';
                %     h = BK_Create();
                %     BK_AddVars(h, graphcut.noPix);
                %     BK_SetNeighbors(h, graphcut.Graph{1});
                %     BK_SetUnary(h, T);
                %     e = BK_Minimize(h);
                %     labels = BK_GetLabeling(h);
                %     BK_Delete(h);
                
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.55, wb, sprintf('Doing maxflow/mincut\nPlease wait...'));
                end
                %[~, labels] = maxflow(obj.graphcut.Graph{1}, T);
                [~, labels] = maxflow_v222(obj.graphcut.Graph{1}, T);
                
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.75, wb, sprintf('Generating the mask\nPlease wait...'));
                end
                
                if isempty(obj.shownLabelObj)
                    obj.shownLabelObj = labels;
                    Mask = zeros(size(seedImg),'uint8');
                else
                    %Mask = cell2mat(obj.mibModel.getData3D('mask', NaN, 4, NaN, getDataOptions));   % get mask
                    negIds = obj.shownLabelObj - labels;
                    posIds = labels - obj.shownLabelObj;
                    obj.shownLabelObj = labels;
                end
                
                % % alternative ~35% slower
                %indexLabel = find(labels>0);
                %Mask(ismember(double(graphcut.slic), find(labels>0))) = 1;
                
                % % using ismembc instead of ismember because it is a bit faster
                % % however, the vertcut with known indeces of pixels is faster!
                % unfortunately it takes a lot of space to keep the indices of
                % supervoxels
                if isfield(obj.graphcut, 'PixelIdxList')
                    if ~isempty(negIds)
                        setDataOpt.PixelIdxList = find(negIds>0);
                        if ~isempty(setDataOpt.PixelIdxList)
                            setDataOpt.PixelIdxList = vertcat(obj.graphcut.PixelIdxList{setDataOpt.PixelIdxList});
                            setDataOpt.PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(setDataOpt.PixelIdxList, convertPixelOpt);   % recalc indices
                            dataset = zeros([numel(setDataOpt.PixelIdxList), 1], 'uint8');
                            obj.mibModel.setData3D('mask', dataset, NaN, NaN, NaN, setDataOpt);
                        end
                        setDataOpt.PixelIdxList = find(posIds>0);
                        if ~isempty(setDataOpt.PixelIdxList)
                            setDataOpt.PixelIdxList = vertcat(obj.graphcut.PixelIdxList{setDataOpt.PixelIdxList});
                            setDataOpt.PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(setDataOpt.PixelIdxList, convertPixelOpt);   % recalc indices
                            dataset = zeros([numel(setDataOpt.PixelIdxList), 1], 'uint8')+1;
                            obj.mibModel.setData3D('mask', dataset, NaN, NaN, NaN, setDataOpt);
                        end
                        if obj.timerElapsed > obj.timerElapsedMax
                            delete(wb);
                        end
                        return;
                    else
                        Mask(vertcat(obj.graphcut.PixelIdxList{labels>0})) = 1;  
                    end
                else
                    if ~isempty(negIds)
                        negIds = find(negIds > 0);
                        posIds = find(posIds > 0);
                        if isa(obj.graphcut.slic, 'uint8')
                            negIds = uint8(negIds);
                            posIds = uint8(posIds);
                        elseif isa(obj.graphcut.slic, 'uint16')
                            negIds = uint16(negIds);
                            posIds = uint16(posIds);
                        else
                            negIds = uint32(negIds);
                            posIds = uint32(posIds);
                        end
                        if ~isempty(negIds)
                            setDataOpt.PixelIdxList = find(ismember(obj.graphcut.slic, negIds)>0);
                            setDataOpt.PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(setDataOpt.PixelIdxList, convertPixelOpt);   % recalc indices
                            dataset = zeros([numel(setDataOpt.PixelIdxList), 1], 'uint8');
                            obj.mibModel.setData3D('mask', dataset, NaN, NaN, NaN, setDataOpt);
                        end
                        
                        if ~isempty(posIds)
                            setDataOpt.PixelIdxList = find(ismember(obj.graphcut.slic, posIds)>0);
                            setDataOpt.PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(setDataOpt.PixelIdxList, convertPixelOpt);   % recalc indices
                            dataset = zeros([numel(setDataOpt.PixelIdxList), 1], 'uint8')+1;
                            obj.mibModel.setData3D('mask', dataset, NaN, NaN, NaN, setDataOpt);
                        end
                        if obj.timerElapsed > obj.timerElapsedMax
                            delete(wb);
                        end
                        return;
                    else
                        indexLabel = find(labels>0);
                        %indexLabel = find(labels==1); % test of BK_matlab
                        if isa(obj.graphcut.slic, 'uint8')
                            indexLabel = uint8(indexLabel);
                        elseif isa(obj.graphcut.slic, 'uint16')
                            indexLabel = uint16(indexLabel);
                        else
                            indexLabel = uint32(indexLabel);
                        end
                        %Mask(ismembc(obj.graphcut.slic, indexLabel)) = 1;
                        Mask(ismember(obj.graphcut.slic, indexLabel)) = 1;
                    end
                end
                
                % remove boundaries between superpixels
                if obj.graphcut.superPixType == 2 && strcmp(obj.graphcut.dilateMode, 'post')  % watershed
                    Mask = imdilate(Mask, ones([3 3 3]));
                end
                
                %Mask(seedImg==bgMaterialId) = 0;    % remove background pixels
                %Mask(seedImg==seedMaterialId) = 1;    % add label pixels
                
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    if obj.timerElapsed > obj.timerElapsedMax
                        waitbar(.95, wb, sprintf('Re-binning the mask\nPlease wait...'));
                    end
                    resizeOptions.height = max(height)-min(height)+1;
                    resizeOptions.width = max(width)-min(width)+1;
                    resizeOptions.depth = max(thick)-min(thick)+1;
                    resizeOptions.method = 'nearest';
                    Mask = mibResize3d(Mask, [], resizeOptions);
                end
                obj.mibModel.setData3D('mask', Mask, NaN, 4, NaN, getDataOptions);   % set dataset
            end
            if obj.timerElapsed > obj.timerElapsedMax
                delete(wb);
            end
        end
        
        function doImageSegmentation(obj)
            % function doImageSegmentation(obj)
            % make image segmentation using standard watershed
            
            wb = waitbar(0, sprintf('Image segmentation...\nPlease wait...'), 'Name', 'Image segmentation');
            col_channel = obj.View.handles.imageColChPopup.Value;
            bgMaterialId = obj.View.handles.backgroundMateriaPopup.Value;    % index of the background label
            seedMaterialId = obj.View.handles.signalMateriaPopup.Value;    % index of the signal label
            noMaterials = numel(obj.View.handles.signalMateriaPopup.String);    % number of materials in the model
            preprocImgNaN = 0;  % switch to remove temporary preprocImg later
            invertImage = obj.View.handles.signalPopup.Value;    % if == 1 image should be inverted, black-on-white
            
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
            
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                obj.mibModel.I{obj.mibModel.Id}.clearMask();   % clear or delete mask for uint8 model type
            end
            
            switch obj.mode
                case 'mode2dCurrentRadio'
                    if isnan(obj.preprocImg(1)) % get image is it was not pre-processed
                        img = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, col_channel, getDataOptions));   % get slice
                        if binVal(1) ~= 1   % bin data
                            img = imresize(img, [binHeight binWidth], 'bicubic');
                        end
                        waitbar(.1, wb);
                        if invertImage == 1
                            img = imcomplement(img);
                        end
                        preprocImgNaN = 1;  % switch to remove temporary preprocImg later
                        obj.preprocImg = squeeze(img);
                        clear img;
                    end
                    seedImg = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, NaN, getDataOptions));   % get slice
                    
                    if binVal(1) ~= 1   % bin data
                        seedImg = imresize(seedImg, [binHeight binWidth], 'nearest');
                    end
                    
                    if noMaterials > 2  % when more than 2 materials present keep only background and color
                        seedImg(seedImg~=seedMaterialId & seedImg~=bgMaterialId) = 0;
                    end
                    waitbar(.2, wb);
                    % modify the image so that the background pixels and the extended
                    % maxima pixels are forced to be the only local minima in the image.
                    W = imimposemin(obj.preprocImg, seedImg);
                    
                    waitbar(.4, wb);
                    W = watershed(W);
                    if isa(W,'dip_image')
                        warndlg(sprintf('!!! Warning !!!\n\nThis tool requires watershed function of Matlab. It seems that the currenly used function is coming from the dip-lib library!\n\nTo fix, place the dip-lib directory to the bottom of the Matlab path:\nMatlab->Home->Set path->Highlight directories containing DIPimage->Move to Bottom->Save'), 'Wrong watershed');
                        delete(wb);
                        return;
                    end
                    waitbar(.5, wb);
                    
                    bgIndex = unique(W(seedImg==bgMaterialId));   % indeces of the background in the watershed regions
                    W(ismember(W, bgIndex)) = 0; % make background 0
                    W(W>1) = 1; % make objects
                    if isa(W, 'uint8') == 0
                        W = uint8(W);
                    end;   % convert to 8bit if neeeded
                    waitbar(.7, wb);
                    % fill the gaps between the objects
                    se = strel('rectangle', [3 3]);
                    W = imdilate(W, se);
                    W = imerode(W, se);
                    waitbar(.9, wb);
                    if binVal(1) ~= 1   % bin data
                        W = imresize(W, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                    end
                    obj.mibModel.setData2D('mask', W, NaN, NaN, NaN, getDataOptions);   % set slice
                case 'mode2dRadio'
                    if isnan(obj.preprocImg(1)) % get image is it was not pre-processed
                        img = cell2mat(obj.mibModel.getData3D('image', NaN, NaN, col_channel, getDataOptions));   % get dataset
                        if binVal(1) ~= 1   % bin data
                            img2 = zeros([binHeight, binWidth, 1, size(img,4)],class(img));
                            for sliceId=1:size(img, 4)
                                img2(:,:,:,sliceId) = imresize(img(:,:,:,sliceId), [binHeight binWidth], 'bicubic');
                            end
                            img = img2;
                            clear img2;
                        end
                        if invertImage == 1
                            img = imcomplement(img);
                        end
                        preprocImgNaN = 1;  % switch to remove temporary preprocImg later
                        obj.preprocImg = squeeze(img);
                        clear img;
                    end
                    seedImg = cell2mat(obj.mibModel.getData3D('model', NaN, NaN, NaN, getDataOptions));   % get dataset
                    if binVal(1) ~= 1   % bin model
                        img2 = zeros([binHeight, binWidth, size(seedImg,3)],class(seedImg));
                        for sliceId=1:size(seedImg, 3)
                            img2(:,:,sliceId) = imresize(seedImg(:,:,sliceId), [binHeight binWidth], 'nearest');
                        end
                        seedImg = img2;
                        clear img2;
                    end
                    
                    if noMaterials > 2  % when more than 2 materials present keep only background and color
                        seedImg(seedImg~=seedMaterialId & seedImg~=bgMaterialId) = 0;
                    end
                    
                    no_stacks = size(obj.preprocImg, 3);
                    realSliceIndex = getDataOptions.z(1):getDataOptions.z(2);   % generate list of slice indeces
                    for sliceId=1:no_stacks
                        % skip if seeds are not present
                        if max(max(seedImg(:,:,sliceId))) == 0;  continue; end;
                        
                        % modify the image so that the background pixels and the extended
                        % maxima pixels are forced to be the only local minima in the image.
                        W = imimposemin(obj.preprocImg(:,:,sliceId), seedImg(:,:,sliceId));
                        W = watershed(W);
                        
                        bgIndex = unique(W(seedImg(:,:,sliceId)==bgMaterialId));   % indeces of the background in the watershed regions
                        W(ismember(W, bgIndex)) = 0; % make background 0
                        W(W>1) = 1; % make objects
                        if isa(W,'uint8') == 0; W = uint8(W); end;   % convert to 8bit if neeeded
                        
                        % fill the gaps between the objects
                        se = strel('rectangle', [3 3]);
                        W = imdilate(W, se);
                        W = imerode(W, se);
                        if binVal(1) ~= 1   % re-bin mask
                            W = imresize(W, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                        end
                        obj.mibModel.setData2D('mask', W, realSliceIndex(sliceId), NaN, NaN, getDataOptions);   % set slice
                        waitbar(sliceId/no_stacks, wb);
                    end
                case 'mode3dRadio'
                    if isnan(obj.preprocImg(1)) % get image is it was not pre-processed
                        img = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, 4, col_channel, getDataOptions)));   % get dataset
                        % bin dataset
                        if binVal(1) ~= 1 || binVal(2) ~= 1
                            waitbar(.05, wb, sprintf('Binning the image\nPlease wait...'));
                            resizeOptions.height = binHeight;
                            resizeOptions.width = binWidth;
                            resizeOptions.depth = binThick;
                            resizeOptions.method = 'bicubic';
                            img = mibResize3d(img, [], resizeOptions);
                        end
                        
                        if invertImage == 1
                            waitbar(.1, wb, sprintf('Inverting the image\nPlease wait...'));
                            img = imcomplement(img);
                        end
                        preprocImgNaN = 1;  % switch to remove temporary preprocImg later
                        obj.preprocImg = img;
                        clear img;
                    end
                    seedImg = cell2mat(obj.mibModel.getData3D('model', NaN, 4, NaN, getDataOptions));   % get dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        waitbar(.15, wb, sprintf('Binning the labels\nPlease wait...'));
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = binThick;
                        resizeOptions.method = 'nearest';
                        seedImg = mibResize3d(seedImg, [], resizeOptions);
                    end
                    
                    if noMaterials > 2  % when more than 2 materials present keep only background and color
                        seedImg(seedImg~=seedMaterialId & seedImg~=bgMaterialId) = 0;
                    end
                    
                    % modify the image so that the background pixels and the extended
                    % maxima pixels are forced to be the only local minima in the image.
                    waitbar(.2, wb, sprintf('Imposing minima\nPlease wait...'));
                    W = imimposemin(obj.preprocImg, seedImg);
                    waitbar(.3, wb, sprintf('Computing the watershed regions\nPlease wait...'));
                    W = watershed(W);
                    waitbar(.7, wb, sprintf('Removing background\nPlease wait...'));
                    bgIndex = unique(W(seedImg==bgMaterialId));   % indeces of the background in the watershed regions
                    W(ismember(W, bgIndex)) = 0; % make background 0
                    W(W>1) = 1; % make objects
                    if isa(W,'uint8')==0; W = uint8(W); end;   % convert to 8bit if neeeded
                    
                    waitbar(.9, wb, sprintf('Filling gaps between objects\nPlease wait...'));
                    % fill the gaps between the objects
                    se = ones([3 3 3]);
                    W = imdilate(W, se);
                    W = imerode(W, se);
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        waitbar(.95, wb, sprintf('Re-binning the mask\nPlease wait...'));
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(thick)-min(thick)+1;
                        resizeOptions.method = 'nearest';
                        W = mibResize3d(W, [], resizeOptions);
                    end
                    obj.mibModel.setData3D('mask', W, NaN, 4, NaN, getDataOptions);   % set dataset
            end
            waitbar(1, wb);
            % restore handles.preprocImg state
            if preprocImgNaN
                obj.preprocImg = NaN;
            end
            delete(wb);
        end
        
        function doObjectSeparation(obj)
            % function doObjectSeparation(obj)
            % start object separation using watershed
            
            wb = waitbar(0, sprintf('Object separation\nPlease wait...'), 'Name', 'Object separation...');
            aspect = str2num(obj.View.handles.aspectRatio.String); %#ok<ST2NM>
            col_channel = obj.View.handles.imageIntensityColorCh.Value;
            invertImage = obj.View.handles.imageIntensityInvert.Value;    % if == 1 image should be inverted, black-on-white
            
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String);  %#ok<ST2NM>
            thick = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = [min(width) max(width)];
            getDataOptions.y = [min(height) max(height)];
            getDataOptions.z = [min(thick) max(thick)];
            if strcmp(obj.mode, 'mode2dCurrentRadio')   % limit z for the current slice only mode
                currentSliceIndex = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                getDataOptions.z = [currentSliceIndex currentSliceIndex];
            end
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binThick = ceil((max(thick)-min(thick)+1)/binVal(2));
            
            % define source of the objects and seeds
            modelId = NaN;
            seedModelId = NaN;
            if obj.View.handles.selectionRadio.Value == 1
                inputType = 'selection';
            elseif obj.View.handles.maskRadio.Value == 1
                inputType = 'mask';
            elseif obj.View.handles.modelRadio.Value == 1
                inputType = 'model';
                modelId = obj.View.handles.selectedMaterialPopup.Value;
            end
            
            if obj.View.handles.seedsSelectionRadio.Value == 1
                seedType = 'selection';
            elseif obj.View.handles.seedsMaskRadio.Value == 1
                seedType = 'mask';
            elseif obj.View.handles.seedsModelRadio.Value == 1
                seedType = 'model';
                seedModelId = obj.View.handles.seedsSelectedMaterialPopup.Value;
            end
            
            if obj.View.handles.useSeedsCheck.Value  % use seeded watershed, modified from http://blogs.mathworks.com/steve/2006/06/02/cell-segmentation/
                if strcmp(obj.mode, 'mode3dRadio')  % do watershed for 3D objects
                    img = cell2mat(obj.mibModel.getData3D(inputType, NaN, 4, modelId, getDataOptions));   % get image with objects to watershed
                    seedImg = squeeze(cell2mat(obj.mibModel.getData3D(seedType, NaN, 4, seedModelId, getDataOptions)));   % get image with seeds
                    if obj.View.handles.intensityRadio.Value
                        intImg = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, 4, col_channel, getDataOptions)));   % get image of the specified color channel to use instead of distance map
                    end
                    % bin dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        waitbar(.05, wb, sprintf('Binning the data\nPlease wait...'));
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = binThick;
                        resizeOptions.method = 'nearest';
                        img = mibResize3d(img, [], resizeOptions);
                        seedImg = mibResize3d(seedImg, [], resizeOptions);
                        
                        if exist('intImg', 'var')
                            resizeOptions.method = 'bicubic';
                            intImg = mibResize3d(intImg, [], resizeOptions);
                        end
                        aspect(1) = aspect(1)*binVal(1);
                        aspect(2) = aspect(2)*binVal(1);
                        aspect(3) = aspect(3)*binVal(2);
                    end
                    % invert image with intensities
                    if invertImage == 1 && obj.View.handles.intensityRadio.Value
                        waitbar(.07, wb, sprintf('Complementing the image\nPlease wait...'));
                        intImg = imcomplement(intImg); % complement the image so that the peaks become valleys.
                    end
                    
                    if obj.View.handles.intensityRadio.Value
                        waitbar(.1, wb, sprintf('Updating local minima\nPlease wait...'));
                        W = imimposemin(intImg, ~img | seedImg);
                        clear intImg;
                    else
                        waitbar(.1, wb, sprintf('Computing the distance transform\nPlease wait...'));
                        W = bwdistsc(~img, aspect);
                        waitbar(.3, wb, sprintf('Complementing the image\nPlease wait'));
                        W = -W;
                        
                        waitbar(.35, wb, sprintf('Generating the local minima\nPlease wait...'));
                        % replace the following to eliminate 1 pixel shrinkage of
                        % the objects. Use: W = imimposemin(W, seedImg);
                        % W = imimposemin(W, ~img | seedImg);
                        W = imimposemin(W, seedImg);
                    end
                    waitbar(.5, wb, sprintf('Computing the watershed regions\nPlease wait...'));
                    W = watershed(W);
                    
                    waitbar(.7, wb, sprintf('Removing background\nPlease wait...'));
                    W(~img) = 0;
                    
                    % have to calculate the connected components because some objects without
                    % the seeds have indeces equal to those that have seeds
                    waitbar(.75, wb, sprintf('Relabeling the objects\nPlease wait...'));
                    W = bwlabeln(W);
                    
                    waitbar(.85, wb, sprintf('Generating resulting image\nPlease wait...'));
                    objInd = unique(W(seedImg~=0));
                    W = uint8(ismember(W,objInd));
                    
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        %waitbar(.95, wb, sprintf('Re-binning the mask\nPlease wait...'));
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(thick)-min(thick)+1;
                        resizeOptions.method = 'nearest';
                        W = mibResize3d(W, [], resizeOptions);
                    end
                    obj.mibModel.setData3D('selection', W, NaN, 4, NaN, getDataOptions);   % set dataset
                    waitbar(1, wb, sprintf('Done!'));
                else
                    noSlices = getDataOptions.z(2)-getDataOptions.z(1)+1;
                    for sliceId=getDataOptions.z(1):getDataOptions.z(2)
                        img = cell2mat(obj.mibModel.getData2D(inputType, sliceId, NaN, modelId, getDataOptions));   % get slice with objects to watershed
                        seedImg = cell2mat(obj.mibModel.getData2D(seedType, sliceId, NaN, seedModelId, getDataOptions));   % get slice with objects to watershed
                        if max(max(seedImg)) == 0; continue; end    % skip when no seeds
                        if obj.View.handles.intensityRadio.Value
                            intImg = cell2mat(obj.mibModel.getData2D('image', sliceId, NaN, col_channel, getDataOptions));   % get slice with objects to watershed
                        end
                        
                        % bin dataset if needed
                        if binVal(1) ~= 1 || binVal(2) ~= 1
                            %waitbar(.15, wb, sprintf('Binning the labels\nPlease wait...'));
                            img = imresize(img, [binHeight binWidth], 'nearest');
                            seedImg = imresize(seedImg, [binHeight binWidth], 'nearest');
                            if exist('intImg', 'var')
                                intImg = imresize(intImg, [binHeight binWidth], 'bicubic');
                            end
                        end
                        
                        % invert image with intensities
                        if invertImage == 1 && obj.View.handles.intensityRadio.Value
                            % waitbar(.05, wb, sprintf('Complementing image\nPlease wait'));
                            intImg = imcomplement(intImg); % complement the image so that the peaks become valleys.
                        end
                        if obj.View.handles.intensityRadio.Value
                            W = imimposemin(intImg, ~img | seedImg);
                            %W = imimposemin(intImg, seedImg);
                        else
                            W = bwdistsc(~img, [aspect(1) aspect(2)]);
                            W = -W;
                            
                            % replace the following to eliminate 1 pixel shrinkage of
                            % the objects. Use: W = imimposemin(W, seedImg);
                            %W = imimposemin(W, ~img | seedImg);
                            W = imimposemin(W, seedImg);
                        end
                        W = watershed(W);
                        W(~img) = 0;
                        
                        % have to calculate the connected components because some objects without
                        % the seeds have indeces equal to those that have seeds
                        W = bwlabeln(W);
                        
                        objInd = unique(W(seedImg~=0));
                        W = uint8(ismember(W,objInd));
                        
                        if binVal(1) ~= 1   % re-bin mask
                            W = imresize(W, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                        end
                        obj.mibModel.setData2D('selection', W, sliceId, NaN, NaN, getDataOptions);   % set slice
                        waitbar((sliceId-getDataOptions.z(1))/noSlices, wb, sprintf('Please wait...'));
                    end
                    
                end
            else    % standard shape watershed
                reduiceOversegmCheck = obj.View.handles.reduiceOversegmCheck.Value;
                if strcmp(obj.mode, 'mode3dRadio')  % do watershed for 3D objects
                    img = squeeze(cell2mat(obj.mibModel.getData3D(inputType, NaN, 4, modelId, getDataOptions)));   % get image with objects to watershed
                    % bin dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        waitbar(.05, wb, sprintf('Binning the dataset\nPlease wait...'));
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = binThick;
                        resizeOptions.method = 'nearest';
                        img = mibResize3d(img, [], resizeOptions);
                        
                        aspect(1) = aspect(1)*binVal(1);
                        aspect(2) = aspect(2)*binVal(1);
                        aspect(3) = aspect(3)*binVal(2);
                    end
                    waitbar(.2, wb, sprintf('Computing the distance transform\nPlease wait...'));
                    D = bwdistsc(~img, aspect);   % compute the distance transform of the complement of the binary image.
                    D = -D;     % complement the distance transform
                    
                    if reduiceOversegmCheck
                        waitbar(.4, wb, sprintf('Reducing oversegmentation\nPlease wait...'));
                        % few extra steps to reduce oversegmentation, suggested at
                        % http://blogs.mathworks.com/steve/2013/11/19/watershed-transform-question-from-tech-support/
                        mask = imextendedmin(D, 2);
                        D = imimposemin(D, mask);
                    end
                    
                    waitbar(.6, wb, sprintf('Computing the watershed regions\nPlease wait...'));
                    D = uint8(watershed(D)); % do watershed
                    
                    waitbar(.85, wb, sprintf('Generating resulting image\nPlease wait...'));
                    D(~img) = 0;
                    D(D>1) = 1;     % flatten the result
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        %waitbar(.95, wb, sprintf('Re-binning the mask\nPlease wait...'));
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(thick)-min(thick)+1;
                        resizeOptions.method = 'nearest';
                        D = mibResize3d(D, [], resizeOptions);
                    end
                    obj.mibModel.setData3D('selection', D, NaN, 4, NaN, getDataOptions);   % set dataset
                    waitbar(1, wb, sprintf('Done!'));
                else
                    noSlices = getDataOptions.z(2)-getDataOptions.z(1)+1;
                    for sliceId=getDataOptions.z(1):getDataOptions.z(2)
                        img = cell2mat(obj.mibModel.getData2D(inputType, sliceId, NaN, modelId, getDataOptions));   % get slice with objects to watershed
                        if binVal(1) ~= 1 || binVal(2) ~= 1
                            %waitbar(.15, wb, sprintf('Binning the labels\nPlease wait...'));
                            img = imresize(img, [binHeight binWidth], 'nearest');
                        end
                        
                        % calculate distance transform
                        W = bwdistsc(~img, [aspect(1) aspect(2)]);
                        W = -W;     % complement the distance transform
                        
                        if reduiceOversegmCheck
                            % few extra steps to reduce oversegmentation, suggested at
                            % http://blogs.mathworks.com/steve/2013/11/19/watershed-transform-question-from-tech-support/
                            mask = imextendedmin(W,2);
                            W = imimposemin(W,mask);
                        end
                        
                        W = uint8(watershed(W)); % do watershed
                        W(~img) = 0;
                        W(W>1) = 1;     % flatten the result
                        
                        if binVal(1) ~= 1   % re-bin mask
                            W = imresize(W, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                        end
                        obj.mibModel.setData2D('selection', W, sliceId, NaN, NaN, getDataOptions);   % set slice
                        waitbar((sliceId-getDataOptions.z(1))/noSlices, wb, sprintf('Please wait...'));
                    end
                end
            end
            delete(wb);
        end
        
        function importBtn_Callback(obj)
            % function importBtn_Callback(obj)
            % callback for press of importBtn - import the graphcut
            % structure
            
            global mibPath;
            
            %options.Resize='on';
            %answer = inputdlg({'Enter variable containing preprocessed image (h:w:color:index):'},'Import image',1,{'I'},options);
            answer = mibInputDlg({mibPath}, 'Enter variable containing preprocessed image (h:w:color:index):', 'Import image', 'I');
            if size(answer) == 0; return; end
            
            try
                img = evalin('base', answer{1});
            catch exception
                errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message),...
                    'Misssing variable!', 'modal');
                return;
            end
            if isstruct(img); img = img.data; end  % check for Amira structures
            
            % check dimensions
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String); %#ok<ST2NM>
            thick = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binThick = ceil((max(thick)-min(thick)+1)/binVal(2));
            
            [~, ~, ~, t] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4);
            % convert to 3D
            % get desired color channel
            col_channel = obj.View.handles.imageColChPopup.Value;
            if ndims(img) == 4 && size(img, 3) > 1
                img = squeeze(img(:,:,col_channel,:));
            elseif ndims(img) == 4 && size(img, 3) == 1
                img = squeeze(img);
            elseif size(img, 3) > 1 && t==1
                img = img(:, :, col_channel);
            end
            
            % take a single slice from 3D stack
            if size(img, 3) ~= 1 && strcmp(obj.mode,'mode2dCurrentRadio')
                currentSliceNumber = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                img = img(:, :, currentSliceNumber);
                binThick = 1;
                thick = 1;
            end
            
            % check dimensions
            if size(img,1) ~= binHeight || size(img,2) ~= binWidth || size(img,3) ~= binThick
                try
                    img = img(height(1):height(end), width(1):width(end),thick(1):thick(end));
                catch err
                    errordlg('Wrong dimensions!', 'Error');
                    return;
                end
                % resize the volume
                switch obj.mode
                    case 'mode2dRadio'
                        if binVal(1) ~= 1   % bin data
                            resizeOptions.height = binHeight;
                            resizeOptions.width = binWidth;
                            resizeOptions.depth = max(thick)-min(thick)+1;
                            resizeOptions.method = 'bicubic';
                            img = mibResize3d(img, [], resizeOptions);
                        end
                    case 'mode2dCurrentRadio'
                        if binVal(1) ~= 1   % bin data
                            img = imresize(img, [binHeight binWidth], 'bicubic');
                        end
                    case 'mode3dRadio'
                        if binVal(1) ~= 1 || binVal(2) ~= 1
                            resizeOptions.height = binHeight;
                            resizeOptions.width = binWidth;
                            resizeOptions.depth = binThick;
                            resizeOptions.method = 'bicubic';
                            img = mibResize3d(img, [], resizeOptions);
                        end
                end
            end
            
            % invert image
            invertImage = obj.View.handles.signalPopup.Value;    % if == 1 image should be inverted, black-on-white
            if invertImage == 1
                img = imcomplement(img);
            end
            
            obj.preprocImg = img;
            obj.View.handles.preprocessBtn.BackgroundColor = 'g';
        end
        
        function superpixelsBtn_Callback(obj)
            % function superpixelsBtn_Callback(obj)
            % callback for press of superpixelsBtn - calculate superpixels
            
            if ~isnan(obj.preprocImg(1)) || ~isempty(obj.graphcut.noPix)
                button =  questdlg(sprintf('!!! Attention !!!\n\nYou are going to recalculate superpixels structure, which may take significant time!'),...
                    'Warning!', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button,'Cancel')
                    return;
                end
            end
            
            tic
            superPixType = obj.View.handles.superpixTypePopup.Value;  % 1-SLIC, 2-Watershed
            if superPixType == 1
                wb = waitbar(0, sprintf('Initiating...\nPlease wait...'), 'Name', 'SLIC superpixels/supervoxels');
            else
                wb = waitbar(0, sprintf('Initiating...\nPlease wait...'), 'Name', 'Watershed superpixels/supervoxels');
            end
            obj.clearPreprocessBtn_Callback();
            
            col_channel = obj.View.handles.imageColChPopup.Value;
            superpixelSize = str2double(obj.View.handles.superpixelEdit.String);
            superpixelCompact = str2double(obj.View.handles.superpixelsCompactEdit.String);
            blackOnWhite = obj.View.handles.signalPopup.Value;       % black ridges over white background
            watershedReduce = str2double(obj.View.handles.superpixelsReduceEdit.String);  % factor to reduce oversegmentation by watershed
            
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
            
            obj.graphcut.dilateMode = 'post';
            
            tilesX =  str2double(obj.View.handles.chopXedit.String);  % calculate supervoxels for the chopped datasets
            tilesY =  str2double(obj.View.handles.chopYedit.String);
            
            % check for autosave
            if obj.View.handles.supervoxelsAutosaveCheck.Value
                fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
                dotIndex = strfind(fn_out, '.');
                if ~isempty(dotIndex)
                    fn_out = fn_out(1:dotIndex(end)-1);
                end
                if isempty(strfind(fn_out,'/')) && isempty(strfind(fn_out,'\'))
                    fn_out = fullfile(obj.mibModel.myPath, fn_out);
                end
                if isempty(fn_out)
                    fn_out = obj.mibModel.myPath;
                end
                Filters = {'*.graph;',  'Matlab format (*.graph)'};
                
                [filename, path, FilterIndex] = uiputfile(Filters, 'Save Graph...', fn_out); %...
                if isequal(filename,0); delete(wb); return; end % check for cancel
                fn_out = fullfile(path, filename);
            end
            
            switch obj.mode
                case 'mode2dCurrentRadio'
                    img = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, col_channel, getDataOptions));   % get slice
                    if binVal(1) ~= 1   % bin data
                        img = imresize(img, [binHeight binWidth], 'bicubic');
                    end
                    
                    % convert to 8bit
                    currViewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;
                    if isa(img, 'uint16')
                        if obj.mibModel.mibLiveStretchCheck   % on fly mode
                            img = imadjust(img ,stretchlim(img,[0 1]),[]);
                        else
                            img = imadjust(img, [currViewPort.min(col_channel)/65535 currViewPort.max(col_channel)/65535],[0 1],currViewPort.gamma(col_channel));
                        end
                        img = uint8(img/255);
                    else
                        if currViewPort.min(col_channel) > 1 || currViewPort.max(col_channel) < 255
                            img = imadjust(img, [currViewPort.min(col_channel)/255 currViewPort.max(col_channel)/255],[0 1],currViewPort.gamma(col_channel));
                        end
                    end
                    
                    dims = size(img);
                    if superPixType == 1     % generate SLIC superpixels
                        waitbar(.05, wb, sprintf('Calculating SLIC superpixels...\nPlease wait...'));
                        % calculate number of supervoxels
                        obj.graphcut.noPix = ceil(dims(1)*dims(2)/superpixelSize);
                        
                        [obj.graphcut.slic, obj.graphcut.noPix] = slicmex(img, obj.graphcut.noPix, superpixelCompact);
                        obj.graphcut.noPix = double(obj.graphcut.noPix);
                        % remove superpixel with 0-index
                        obj.graphcut.slic = obj.graphcut.slic + 1;
                        % a new procedure imRAG that is few times faster
                        %STATS = regionprops(obj.graphcut.slic, img, 'MeanIntensity','PixelIdxList');
                        STATS = regionprops(obj.graphcut.slic, img, 'MeanIntensity');
                        gap = 0;    % regions are connected, no gap in between
                        obj.graphcut.Edges{1} = imRAG(obj.graphcut.slic, gap);
                        obj.graphcut.Edges{1} = double(obj.graphcut.Edges{1});
                        
                        obj.graphcut.EdgesValues{1} = zeros([size(obj.graphcut.Edges{1},1), 1]);
                        meanVals = [STATS.MeanIntensity];
                        
                        for i=1:size(obj.graphcut.Edges{1}, 1)
                            %EdgesValues(i) = 255/(abs(meanVals(Edges(i,1))-meanVals(Edges(i,2)))+.00001);     % should be low (--> 0) at the edges of objects
                            obj.graphcut.EdgesValues{1}(i) = abs(meanVals(obj.graphcut.Edges{1}(i,1))-meanVals(obj.graphcut.Edges{1}(i,2)));     % should be low (--> 0) at the edges of objects
                        end
                        
                        waitbar(.9, wb, sprintf('Calculating weights for boundaries...\nPlease wait...'));
                        obj.recalcGraph_Callback();
                    else    % generate WATERSHED superpixels
                        waitbar(.05, wb, sprintf('Calculating Watershed superpixels...\nPlease wait...'));
                        if blackOnWhite == 1
                            img = imcomplement(img);    % convert image that the ridges are white
                        end
                        
                        mask = imextendedmin(img, watershedReduce);
                        mask = imimposemin(img, mask);
                        
                        obj.graphcut.slic = watershed(mask);       % generate superpixels
                        waitbar(.5, wb, sprintf('Calculating connectivity ...\nPlease wait...'));
                        [obj.graphcut.Edges{1}, edgeIndsList] = imRichRAG(obj.graphcut.slic);
                        % calculate mean of intensities at the borders between each superpixel
                        obj.graphcut.EdgesValues{1} = cell2mat(cellfun(@(idx) mean(img(idx)), edgeIndsList, 'UniformOutput', 0));
                        obj.recalcGraph_Callback();
                        
                        obj.graphcut.noPix = max(obj.graphcut.slic(:));
                        % two modes for dilation: 'pre' and 'post'
                        % in 'pre' the superpixels are dilated before the graphcut
                        % segmentation, i.e. in this function
                        % in 'post' the superpixels are dilated after the graphcut
                        % segmentation
                        obj.graphcut.dilateMode = 'pre';
                        if strcmp(obj.graphcut.dilateMode, 'pre')
                            obj.graphcut.slic = imdilate(obj.graphcut.slic, ones(3));
                        end
                        %STATS = regionprops(obj.graphcut.slic, 'PixelIdxList');
                    end
                    %obj.graphcut.PixelIdxList{1} = {STATS.PixelIdxList};
                case 'mode2dRadio'
                    img = cell2mat(obj.mibModel.getData3D('image', NaN, NaN, col_channel, getDataOptions));   % get dataset
                    if binVal(1) ~= 1   % bin data
                        waitbar(.05, wb, sprintf('Binning the images\nPlease wait...'));
                        img2 = zeros([binHeight, binWidth, 1, size(img,4)],class(img));
                        for sliceId=1:size(img, 4)
                            img2(:,:,:,sliceId) = imresize(img(:,:,:,sliceId), [binHeight binWidth], 'bicubic');
                        end
                        img = img2;
                        clear img2;
                    end
                    img = squeeze(img);
                    
                    % convert to 8bit and adjust contrast
                    currViewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;
                    if isa(img, 'uint16')
                        if obj.mibModel.mibLiveStretchCheck   % on fly mode
                            for sliceId=1:size(img, 3)
                                img(:,:,sliceId) = imadjust(img(:,:,sliceId) ,stretchlim(img(:,:,sliceId),[0 1]),[]);
                            end
                        else
                            for sliceId=1:size(img, 3)
                                img(:,:,sliceId) = imadjust(img(:,:,sliceId), [currViewPort.min(col_channel)/65535 currViewPort.max(col_channel)/65535],[0 1],currViewPort.gamma(col_channel));
                            end
                        end
                        img = uint8(img/255);
                    else
                        if currViewPort.min(col_channel) > 1 || currViewPort.max(col_channel) < 255
                            for sliceId=1:size(img, 3)
                                img(:,:,sliceId) = imadjust(img(:,:,sliceId), [currViewPort.min(col_channel)/255 currViewPort.max(col_channel)/255],[0 1],currViewPort.gamma(col_channel));
                            end
                        end
                    end
                    
                    % calculate number of superpixels
                    dims = size(img);
                    if numel(dims) == 2; dims(3) = 1; end
                    obj.graphcut.slic = zeros(size(img));
                    obj.graphcut.noPix = zeros([size(img,3), 1]);
                    if superPixType == 1     % generate SLIC superpixels
                        noPix = ceil(dims(1)*dims(2)/superpixelSize);
                        
                        for i=1:dims(3)
                            [obj.graphcut.slic(:,:,i), noPixCurrent] = slicmex(img(:,:,i), noPix, superpixelCompact);
                            obj.graphcut.noPix(i) = double(noPixCurrent);
                            % remove superpixel with 0-index
                            obj.graphcut.slic(:,:,i) = obj.graphcut.slic(:,:,i) + 1;
                            
                            % a new procedure imRAG that is few times faster
                            %STATS = regionprops(obj.graphcut.slic(:,:,i), img(:,:,i), 'MeanIntensity','PixelIdxList');
                            STATS = regionprops(obj.graphcut.slic(:,:,i), img(:,:,i), 'MeanIntensity');
                            gap = 0;    % regions are connected, no gap in between
                            Edges = imRAG(obj.graphcut.slic(:,:,i), gap);
                            Edges = double(Edges);
                            
                            EdgesValues = zeros([size(Edges,1), 1]);
                            meanVals = [STATS.MeanIntensity];
                            
                            for j=1:size(Edges,1)
                                %EdgesValues(i) = 255/(abs(meanVals(Edges(i,1))-meanVals(Edges(i,2)))+.00001);     % should be low (--> 0) at the edges of objects
                                EdgesValues(j) = abs(meanVals(Edges(j,1))-meanVals(Edges(j,2)));     % should be low (--> 0) at the edges of objects
                            end
                            
                            obj.graphcut.Edges{i} = Edges;
                            obj.graphcut.EdgesValues{i} = EdgesValues;
                            waitbar(i/dims(3), wb, sprintf('Calculating...\nPlease wait...'));
                        end
                        obj.recalcGraph_Callback();
                    else % generate WATERSHED superpixels
                        if blackOnWhite == 1
                            img = imcomplement(img);    % convert image that the ridges are white
                        end
                        for i=1:dims(3)
                            currImg = img(:,:,i);
                            mask = imextendedmin(currImg, watershedReduce);
                            mask = imimposemin(currImg, mask);
                            obj.graphcut.slic(:,:,i) = watershed(mask);       % generate superpixels
                            
                            % this call seems to be faster for 2D than using
                            % [Edges, EdgesValues] = imRichRAG(obj.graphcut.slic(:,:,i), 1, currImg);
                            [obj.graphcut.Edges{i}, edgeIndsList] = imRichRAG(obj.graphcut.slic(:,:,i));
                            % calculate mean of intensities at the borders between each superpixel
                            obj.graphcut.EdgesValues{i} = cell2mat(cellfun(@(idx) mean(currImg(idx)), edgeIndsList, 'UniformOutput', 0));
                            obj.graphcut.Edges{i} = double(obj.graphcut.Edges{i});
                            obj.graphcut.noPix(i) = double(max(max(obj.graphcut.slic(:,:,i))));
                            
                            % two modes for dilation: 'pre' and 'post'
                            % in 'pre' the superpixels are dilated before the graphcut
                            % segmentation, i.e. in this function
                            % in 'post' the superpixels are dilated after the graphcut
                            % segmentation
                            obj.graphcut.dilateMode = 'post';
                            obj.graphcut.dilateMode = 'pre';
                            if strcmp(obj.graphcut.dilateMode, 'pre')
                                obj.graphcut.slic(:,:,i) = imdilate(obj.graphcut.slic(:,:,i), ones(3));
                            end
                            waitbar(i/dims(3), wb, sprintf('Calculating...\nPlease wait...'));
                        end
                        obj.recalcGraph_Callback();
                    end
                case 'mode3dRadio'
                    img = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, 4, col_channel, getDataOptions)));   % get dataset
                    % bin dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        waitbar(.05, wb, sprintf('Binning the dataset\nPlease wait...'));
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = binThick;
                        resizeOptions.method = 'bicubic';
                        img = mibResize3d(img, [], resizeOptions);
                    end
                    
                    % convert to 8bit
                    currViewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;
                    if isa(img, 'uint16')
                        if obj.mibModel.mibLiveStretchCheck  % on fly mode
                            for sliceId=1:size(img, 3)
                                img(:,:,sliceId) = imadjust(img(:,:,sliceId) ,stretchlim(img(:,:,sliceId),[0 1]),[]);
                            end
                        else
                            for sliceId=1:size(img, 3)
                                img(:,:,sliceId) = imadjust(img(:,:,sliceId), [currViewPort.min(col_channel)/65535 currViewPort.max(col_channel)/65535],[0 1],currViewPort.gamma(col_channel));
                            end
                        end
                        img = uint8(img/255);
                    else
                        if currViewPort.min(col_channel) > 1 || currViewPort.max(col_channel) < 255
                            for sliceId=1:size(img, 3)
                                img(:,:,sliceId) = imadjust(img(:,:,sliceId), [currViewPort.min(col_channel)/255 currViewPort.max(col_channel)/255],[0 1],currViewPort.gamma(col_channel));
                            end
                        end
                    end
                    
                    % calculate number of supervoxels
                    dims = size(img);
                    if superPixType == 1     % generate SLIC superpixels
                        obj.graphcut.noPix = ceil(dims(1)*dims(2)*dims(3)/superpixelSize);
                        
                        % calculate supervoxels
                        waitbar(.05, wb, sprintf('Calculating  %d SLIC supervoxels\nPlease wait...', obj.graphcut.noPix));
                        
                        if tilesX > 1 || tilesY > 1
                            [height, width, depth] = size(img);
                            obj.graphcut.slic = zeros([height width depth], 'int32');
                            noPix = 0;
                            
                            xStep = ceil(width/tilesX);
                            yStep = ceil(height/tilesY);
                            for x=1:tilesX
                                for y=1:tilesY
                                    yMin = (y-1)*yStep+1;
                                    yMax = min([(y-1)*yStep+yStep, height]);
                                    xMin = (x-1)*xStep+1;
                                    xMax = min([(x-1)*xStep+xStep, width]);
                                    
                                    [slicChop, noPixChop] = slicsupervoxelmex_byte(img(yMin:yMax, xMin:xMax, :), round(obj.graphcut.noPix/(tilesX*tilesY)), superpixelCompact);
                                    obj.graphcut.slic(yMin:yMax, xMin:xMax, :) = slicChop + noPix + 1;   % +1 to remove zero supervoxels
                                    noPix = noPixChop + noPix;
                                end
                            end
                            obj.graphcut.noPix = double(noPix);
                        else
                            [obj.graphcut.slic, obj.graphcut.noPix] = slicsupervoxelmex_byte(img, obj.graphcut.noPix, superpixelCompact);
                            obj.graphcut.noPix = double(obj.graphcut.noPix);
                            % remove superpixel with 0-index
                            obj.graphcut.slic = obj.graphcut.slic + 1;
                        end
                        
                        % calculate adjacent matrix for labels
                        waitbar(.25, wb, sprintf('Calculating MeanIntensity for labels\nPlease wait...'));
                        %STATS = regionprops(obj.graphcut.slic, img, 'MeanIntensity','BoundingBox','PixelIdxList');
                        STATS = regionprops(obj.graphcut.slic, img, 'MeanIntensity');
                        
                        waitbar(.3, wb, sprintf('Calculating adjacent matrix for labels\nPlease wait...'));
                        
                        % a new procedure imRAG that is up to 10 times faster
                        gap = 0;    % regions are connected, no gap in between
                        obj.graphcut.Edges{1} = imRAG(obj.graphcut.slic, gap);
                        obj.graphcut.Edges{1} = double(obj.graphcut.Edges{1});
                        
                        obj.graphcut.EdgesValues{1} = zeros([size(obj.graphcut.Edges{1},1), 1]);
                        meanVals = [STATS.MeanIntensity];
                        
                        for i=1:size(obj.graphcut.Edges{1},1)
                            %                 knownId = 2088;
                            %                 if i==knownId
                            %                     0;
                            %                     vInd = find(Edges(:,1)==knownId);   % indices of edges
                            %                     vInd2 = find(Edges(:,2)==knownId);   % indices of edges
                            %                     vInd = sort([vInd; vInd2]);
                            %                     [vInd, Edges(vInd,1), Edges(vInd,2)];  % connected superpixels
                            %                 end
                            obj.graphcut.EdgesValues{1}(i) = abs(meanVals(obj.graphcut.Edges{1}(i,1))-meanVals(obj.graphcut.Edges{1}(i,2)));     % should be low (--> 0) at the edges of objects
                        end
                        obj.recalcGraph_Callback();
                    else    % generate WATERSHED supervoxels
                        if blackOnWhite == 1
                            waitbar(.05, wb, sprintf('Complementing the image\nPlease wait...'));
                            img = imcomplement(img);    % convert image that the ridges are white
                        end
                        waitbar(.1, wb, sprintf('Extended-minima transform\nPlease wait...'));
                        if watershedReduce > 0
                            mask = imextendedmin(img, watershedReduce);
                            waitbar(.15, wb, sprintf('Impose minima\nPlease wait...'));
                            mask = imimposemin(img, mask);
                            waitbar(.2, wb, sprintf('Calculating watershed\nPlease wait...'));
                            obj.graphcut.slic = watershed(mask);       % generate supervoxels

                        else
                            waitbar(.2, wb, sprintf('Calculating watershed\nPlease wait...'));
                            obj.graphcut.slic = watershed(img);       % generate supervoxels
                        end
                        waitbar(.7, wb, sprintf('Calculating adjacency graph\nPlease wait...'));
                        
                        % calculate adjacency matrix and mean intensity between each
                        % two adjacent supervoxels
                        [obj.graphcut.Edges{1}, obj.graphcut.EdgesValues{1}] = imRichRAG(obj.graphcut.slic, 1, img);
                        obj.graphcut.noPix = double(max(max(max(obj.graphcut.slic))));
                        
                        waitbar(.9, wb, sprintf('Generating the final graph\nPlease wait...'));
                        % two modes for dilation: 'pre' and 'post'
                        % in 'pre' the superpixels are dilated before the graphcut
                        % segmentation, i.e. in this function
                        % in 'post' the superpixels are dilated after the graphcut
                        % segmentation
                        obj.graphcut.dilateMode = 'pre';
                        if strcmp(obj.graphcut.dilateMode, 'pre')
                            obj.graphcut.slic = imdilate(obj.graphcut.slic, ones([3 3 3]));
                        end
                        obj.recalcGraph_Callback();
                    end
                    % clear list of selected pixels
                    obj.seedObj = cell([size(obj.graphcut.slic, 3), 1]);
                    obj.seedBg = cell([size(obj.graphcut.slic, 3), 1]);
            end
            
            % convert to a proper class, to uint8 if below 255
            if max(obj.graphcut.noPix) < 256
                obj.graphcut.slic = uint8(obj.graphcut.slic);
            elseif max(obj.graphcut.noPix) < 65536
                obj.graphcut.slic = uint16(obj.graphcut.slic);
            elseif max(obj.graphcut.noPix) < 4294967295
                obj.graphcut.slic = uint32(obj.graphcut.slic);
            end
            
            obj.graphcut.bb = [getDataOptions.x getDataOptions.y getDataOptions.z];   % store bounding box of the generated superpixels
            obj.graphcut.mode = obj.mode;     % store the mode for the calculated superpixels
            obj.graphcut.binVal = binVal;     % store the mode for the calculated superpixels
            obj.graphcut.colCh = col_channel;     % store color channel
            obj.graphcut.spSize = superpixelSize; % size of superpixels
            obj.graphcut.spCompact = superpixelCompact; % compactness of superpixels
            obj.graphcut.superPixType = superPixType;   % type of superpixels, 1-SLIC, 2-Watershed
            obj.graphcut.blackOnWhite = blackOnWhite;   % 1-when black ridges over white background
            obj.graphcut.watershedReduce = watershedReduce; % factor to reduce oversegmentation by watershed
            
            if exist('fn_out', 'var')
                % autosaving results
                waitbar(.95, wb, sprintf('Saving Graphcut to a file\nPlease wait...'), 'Name', 'Saving to a file');
                %Graphcut = rmfield(obj.graphcut, 'PixelIdxList');   %#ok<NASGU> % remove the PixelIdxList to make save fast
                %Graphcut = obj.graphcut; %#ok<NASGU>
                
                % remove of the Graph field for 2542540 supervoxels
                % makes saving faster by 5% and files smaller by 20%
                Graphcut = rmfield(obj.graphcut, 'Graph');   %#ok<NASGU> % remove the PixelIdxList to make save fast
                save(fn_out, 'Graphcut', '-mat', '-v7.3');
                fprintf('MIB: saving graphcut structure to %s -> done!\n', fn_out);
            end
            
            % calculate PixelIdxList
            if obj.View.handles.pixelIdxListCheck.Value == 1
                waitbar(.98, wb, sprintf('Calculate PixelIdxList\nPlease wait...'), 'Name', 'PixelIdxList');
                obj.pixelIdxListCheck_Callback();
            end
            
            waitbar(1, wb, sprintf('Done!'));
            obj.View.handles.superpixelsBtn.BackgroundColor = 'g';
            obj.View.handles.superpixelsCountText.String = sprintf('Superpixels count: %d', max(obj.graphcut.noPix));
            delete(wb);
            toc
        end
        
        function exportSuperpixelsBtn_Callback(obj)
            % function exportSuperpixelsBtn_Callback(obj)
            % callback for press of exportSuperpixelsBtn; export/save
            % supervoxels 
            global mibPath;
            Graphcut = obj.graphcut;
            if isempty(Graphcut.noPix); return; end
            
            button =  questdlg(sprintf('Would you like to export preprocessed data to a file or the main Matlab workspace?'), ...
                'Export/Save SLIC', 'Save to a file', 'Export to Matlab', 'Cancel', 'Save to a file');
            if strcmp(button, 'Cancel'); return; end
            if strcmp(button, 'Export to Matlab')
                title = 'Input variable to export';
                def = 'Graphcut';
                prompt = {'A variable for the measurements structure:'};
                answer = mibInputDlg({mibPath}, prompt, title, def);
                if size(answer) == 0; return; end
                assignin('base', answer{1}, Graphcut);
                fprintf('MIB: export superpixel data ("%s") to Matlab -> done!\n', answer{1});
                return;
            end
            fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            dotIndex = strfind(fn_out, '.');
            if ~isempty(dotIndex)
                fn_out = fn_out(1:dotIndex(end)-1);
            end
            if isempty(strfind(fn_out,'/')) && isempty(strfind(fn_out,'\'))
                fn_out = fullfile(obj.mibModel.myPath, fn_out);
            end
            if isempty(fn_out)
                fn_out = obj.mibModel.myPath;
            end
            Filters = {'*.graph;',  'Matlab format (*.graph)'};
            
            [filename, path, FilterIndex] = uiputfile(Filters, 'Save Graph...', fn_out); %...
            if isequal(filename,0); return; end % check for cancel
            fn_out = fullfile(path, filename);
            wb = waitbar(0, sprintf('Saving Graphcut to a file\nPlease wait...'), 'Name', 'Saving to a file');
            tic
            
            if isfield(Graphcut, 'PixelIdxList')
                Graphcut = rmfield(Graphcut, 'PixelIdxList');   %#ok<NASGU> % remove the PixelIdxList to make save fast
            end
            Graphcut = rmfield(Graphcut, 'Graph');   %#ok<NASGU> % remove the PixelIdxList to make save fast
            save(fn_out, 'Graphcut', '-mat', '-v7.3');
            
            fprintf('MIB: saving graphcut structure to %s -> done!\n', fn_out);
            toc
            delete(wb);
        end
        
        function importSuperpixelsBtn_Callback(obj, noImportSwitch)
            % function importSuperpixelsBtn_Callback(obj, noImportSwitch)
            % callback for press of importSuperpixelsBtn; import superpixel
            % structure
            %
            % Parameters:
            % noImportSwitch: [@em optional] if 1, do not import the
            % graphcut, but just update widgets (used in the updateWidgets function)
            
            if nargin < 2; noImportSwitch = 0; end
           
            global mibPath;
            
            if noImportSwitch == 0
                button =  questdlg(sprintf('Would you like to import Graphcut data from a file or from the main Matlab workspace?'),...
                    'Import/Load measurements', 'Load from a file', 'Import from Matlab', 'Cancel', 'Load from a file');
                switch button
                    case 'Cancel'
                        return;
                    case 'Import from Matlab'
                        availableVars = evalin('base', 'whos');
                        idx = ismember({availableVars.class}, {'struct'});
                        if sum(idx) == 0
                            errordlg(sprintf('!!! Error !!!\nNothing to import...'), 'Nothing to import');
                            return;
                        end
                        Vars = {availableVars(idx).name}';
                        
                        % find index of the I variable if it is present
                        idx2 = find(ismember(Vars, 'Graphcut')==1);
                        if ~isempty(idx2)
                            Vars{end+1} = idx2;
                        end
                        prompts = {'A variable that contains compatible structure:'};
                        defAns = {Vars};
                        title = 'Input variable for import';
                        answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
                        if isempty(answer); return; end

                        tic;
                        obj.clearPreprocessBtn_Callback();

                        try
                            obj.graphcut = evalin('base',answer{1});
                        catch exception
                            errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message), 'Missing variable!', 'modal');
                            return;
                        end
                        toc;
                    case 'Load from a file'
                        [filename, path] = uigetfile(...
                            {'*.graph;',  'Matlab format (*.graph)'}, ...
                            'Load Graphcut data...', obj.mibModel.myPath);
                        if isequal(filename, 0); return; end % check for cancel
                        wb = waitbar(0.05,sprintf('Loading preprocessed Graphcut\nPlease wait...'));
                        tic;
                        obj.clearPreprocessBtn_Callback();

                        res = load(fullfile(path, filename),'-mat');
                        obj.graphcut = res.Graphcut;
                        %           % comment this for a while due to bad memory performance with
                        %           large datasets
                        %         if ~isfield(graphcut, 'PixelIdxList')
                        %             % calculate PixelIdxList, to be fast during segmentation
                        %             waitbar(0.5, wb, sprintf('Calculating positions of superpixels\nPlease wait...'));
                        %             switch graphcut.mode
                        %                 case {'mode3dRadio', 'mode2dCurrentRadio'}
                        %                     STATS = regionprops(graphcut.slic, 'PixelIdxList');
                        %                     graphcut.PixelIdxList{1} = {STATS.PixelIdxList};
                        %                 case 'mode2dRadio'
                        %                     for i=1:size(graphcut.slic,3)
                        %                         STATS = regionprops(graphcut.slic(:,:,i), 'PixelIdxList');
                        %                         graphcut.PixelIdxList{i} = {STATS.PixelIdxList};
                        %                     end
                        %             end
                        %         end
                        waitbar(.99, wb, sprintf('Finishing...\nPlease wait...'));
                        delete(wb);
                        toc;
                end
            end
            
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', obj.graphcut.bb(1), obj.graphcut.bb(2));
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', obj.graphcut.bb(3), obj.graphcut.bb(4));
            obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', obj.graphcut.bb(5), obj.graphcut.bb(6));
            obj.View.handles.binSubareaEdit.String = sprintf('%d;%d', obj.graphcut.binVal(1), obj.graphcut.binVal(2));
            obj.View.handles.imageColChPopup.Value = obj.graphcut.colCh;
            if strcmp(obj.graphcut.mode, 'mode3dRadio')
                obj.View.handles.mode3dRadio.Value = 1;
                obj.mode = 'mode3dRadio';
            elseif strcmp(obj.graphcut.mode, 'mode2dRadio')
                obj.View.handles.mode2dRadio.Value = 1;
                obj.mode = 'mode2dRadio';
            else
                obj.View.handles.mode2dCurrentRadio.Value = 1;
                obj.mode = 'mode2dCurrentRadio';
            end
            if isfield(obj.graphcut, 'scaleFactor')
                obj.View.handles.edgeFactorEdit.String = num2str(obj.graphcut.scaleFactor); 
            end
            
            obj.View.handles.superpixelEdit.String = num2str(obj.graphcut.spSize);
            obj.View.handles.superpixelsCompactEdit.String = num2str(obj.graphcut.spCompact);
            if ~isfield(obj.graphcut, 'superPixType'); obj.graphcut.superPixType=1; end
            obj.View.handles.superpixTypePopup.Value = obj.graphcut.superPixType;
            if ~isfield(obj.graphcut, 'blackOnWhite'); obj.graphcut.blackOnWhite=1; end
            obj.View.handles.signalPopup.Value = obj.graphcut.blackOnWhite;
            if ~isfield(obj.graphcut, 'watershedReduce'); obj.graphcut.watershedReduce=15; end
            obj.View.handles.superpixelsReduceEdit.String = num2str(obj.graphcut.watershedReduce);
            
            % recalculate the Graph
            if ~isfield(obj.graphcut, 'Graph')
                obj.recalcGraph_Callback(1);
            end
            
            % calculate PixelIdxList if needed
            if obj.View.handles.pixelIdxListCheck.Value == 1 && ~isfield(obj.graphcut, 'PixelIdxList')
                obj.pixelIdxListCheck_Callback();
            end
            if isfield(obj.graphcut, 'PixelIdxList')
                obj.View.handles.pixelIdxListCheck.Value = 1;
            end
            
            obj.View.handles.superpixelsBtn.BackgroundColor = 'g';
            obj.View.handles.superpixelsCountText.String = sprintf('Superpixels count: %d', max(obj.graphcut.noPix));
            obj.superpixTypePopup_Callback('keep');
        end
        
        function superpixelsPreviewBtn_Callback(obj)
            % function superpixelsPreviewBtn_Callback(obj)
            % callback for press of superpixelsPreviewBtn; preview
            % superpixels in MIB
            
            if isempty(obj.graphcut.noPix)
                return;
            end
            
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String); %#ok<ST2NM>
            thick = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = [min(width) max(width)];
            getDataOptions.y = [min(height) max(height)];
            getDataOptions.z = [min(thick) max(thick)];
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binThick = ceil((max(thick)-min(thick)+1)/binVal(2));
            
            switch obj.mode
                case 'mode2dCurrentRadio'
                    if size(obj.graphcut.slic, 3) > 1
                        currSlic = obj.graphcut.slic(:,:,obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber());
                    else
                        currSlic = obj.graphcut.slic;
                    end
                    if binVal(1) ~= 1   % re-bin mask
                        L2 = imresize(currSlic, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                        L2 = imdilate(L2,ones([3,3])) > L2;
                    else
                        L2 = imdilate(currSlic,ones([3,3])) > currSlic;
                    end
                    obj.mibModel.setData2D('selection', L2, NaN, NaN, NaN, getDataOptions);   % set slice
                case 'mode2dRadio'
                    if binVal(1) ~= 1   % re-bin mask
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(thick)-min(thick)+1;
                        resizeOptions.method = 'nearest';
                        L2 = mibResize3d(obj.graphcut.slic, [], resizeOptions);
                    else
                        L2 = obj.graphcut.slic;
                    end
                    for i=1:size(L2,3)
                        L2(:,:,i) = imdilate(L2(:,:,i),ones([3,3],class(L2))) > L2(:,:,i);
                    end
                    obj.mibModel.setData3D('selection', uint8(L2), NaN, 4, NaN, getDataOptions);   % set dataset
                case 'mode3dRadio'
                    % [gx, gy, gz] = gradient(double(graphcut.slic));
                    % L2 = zeros(size(graphcut.slic))+1;
                    % L2((gx.^2+gy.^2+gz.^2)==0) = 0;
                    
                    %L2 = imdilate(graphcut.slic,ones([3,3,3])) > imerode(graphcut.slic,ones([1,1,1]));
                    
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(thick)-min(thick)+1;
                        resizeOptions.method = 'nearest';
                        L2 = mibResize3d(obj.graphcut.slic, [], resizeOptions);
                    else
                        L2 = obj.graphcut.slic;
                    end
                    
                    L2 = imdilate(L2,ones([3,3,3])) > L2;
                    obj.mibModel.setData3D('selection', L2, NaN, 4, NaN, getDataOptions);   % set dataset
            end
            notify(obj.mibModel, 'plotImage');
        end
        
        function superpixTypePopup_Callback(obj, parameter)
            % function superpixTypePopup_Callback(obj, parameter)
            % callback for change of superpixTypePopup
            
            if nargin < 2; parameter = 'clear'; end     % clear preprocessed data
            
            popupVal = obj.View.handles.superpixTypePopup.Value;
            popupText = obj.View.handles.superpixTypePopup.String;
            obj.View.handles.chopXedit.Enable = 'off';
            obj.View.handles.chopYedit.Enable = 'off';
            if strcmp(popupText{popupVal}, 'SLIC')      % SLIC superpixels
                obj.View.handles.compactnessText.Enable = 'on';
                obj.View.handles.superpixelsCompactEdit.Enable = 'on';
                obj.View.handles.superpixelSize.Enable = 'on';
                obj.View.handles.superpixelEdit.Enable = 'on';
                obj.View.handles.superpixelsReduceText.Enable = 'off';
                obj.View.handles.superpixelsReduceEdit.Enable = 'off';
                if obj.View.handles.mode3dRadio.Value
                    obj.View.handles.chopXedit.Enable = 'on';
                    obj.View.handles.chopYedit.Enable = 'on';
                end
            else                                        % Watershed superpixels
                obj.View.handles.compactnessText.Enable = 'off';
                obj.View.handles.superpixelsCompactEdit.Enable = 'off';
                obj.View.handles.superpixelSize.Enable = 'off';
                obj.View.handles.superpixelEdit.Enable = 'off';
                obj.View.handles.superpixelsReduceText.Enable = 'on';
                obj.View.handles.superpixelsReduceEdit.Enable = 'on';
            end
            if ~strcmp(parameter, 'keep')
                obj.clearPreprocessBtn_Callback();    % clear preprocessed data
            end
        end
        
        
        function recalcGraph_Callback(obj, showWaitbar)
            % function recalcGraph_Callback(obj, showWaitbar)
            % callback for press of recalcGraph; recalculate energy
            % barriers for the graphcut structure
           
            if nargin < 2;    showWaitbar = 0; end
            
            if ~isfield(obj.graphcut, 'EdgesValues')
                errordlg(sprintf('!!! Error !!!\n\nThe edges are missing!\nPlease press the Superpixels/Graph button to calculate them'));
                return;
            end
            
            if showWaitbar; wb = waitbar(0, sprintf('Calculating weights for boundaries...\nPlease wait...')); end;
            
            obj.graphcut.scaleFactor = str2double(obj.View.handles.edgeFactorEdit.String);
            if showWaitbar; waitbar(.1, wb); end
            
            for i=1:numel(obj.graphcut.EdgesValues)
                edgeMax = max(obj.graphcut.EdgesValues{i});
                edgeMin = min(obj.graphcut.EdgesValues{i});
                edgeVar = edgeMax-edgeMin;
                normE = obj.graphcut.EdgesValues{i}/edgeVar;   % scale to 0-1 range
                EdgesValues = exp(-normE*obj.graphcut.scaleFactor);  % should be low (--> 0) at the edges of objects
                
                if showWaitbar; waitbar(.5, wb); end
                
                Edges2 = fliplr(obj.graphcut.Edges{i});    % complement for both ways
                Edges = double([obj.graphcut.Edges{i}; Edges2]);
                obj.graphcut.Graph{i} = sparse(Edges(:,1), Edges(:,2), [EdgesValues EdgesValues]);
                if showWaitbar; waitbar(i/numel(obj.graphcut.EdgesValues), wb); end
            end
            
            if showWaitbar; waitbar(.9, wb); end
            if showWaitbar;     waitbar(1, wb);     delete(wb);  end
        end
        
        function pixelIdxListCheck_Callback(obj)
            % function pixelIdxListCheck_Callback(obj)
            % calculate pixelIdxList for the superpixels
            % this may improve performance of the segmentation process, but
            % requires more memory
            
            if isempty(obj.graphcut.noPix); return; end
            
            % clear the structure
            if obj.View.handles.pixelIdxListCheck.Value == 0
                obj.graphcut = rmfield(obj.graphcut, 'PixelIdxList');
                return;
            end
            
            wb = waitbar(0, sprintf('Calculating PixelIdxList\nPlease wait...'));
            if obj.View.handles.mode2dCurrentRadio.Value    % 2d current slice
                STATS = regionprops(obj.graphcut.slic, 'PixelIdxList');
                obj.graphcut.PixelIdxList = struct2cell(STATS);
            elseif obj.View.handles.mode2dRadio.Value       % 2d slice by slice
                depth = size(obj.graphcut.slic,3);
                for sliceId = 1:depth
                    STATS = regionprops(obj.graphcut.slic(:,:,sliceId), 'PixelIdxList');
                    obj.graphcut.PixelIdxList{sliceId} = struct2cell(STATS);
                    waitbar(sliceId/depth, wb);
                end
            else    % 3d
                STATS = regionprops(obj.graphcut.slic, 'PixelIdxList');
                waitbar(0.8, wb);
                obj.graphcut.PixelIdxList = struct2cell(STATS);
                waitbar(1, wb);
            end
            delete(wb);
        end
        
    end
end

