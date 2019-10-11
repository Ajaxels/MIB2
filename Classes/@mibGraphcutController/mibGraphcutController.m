classdef mibGraphcutController  < handle
    % @type mibGraphcutController class is resposnible for showing the graphcut segmentation window,
    % available from MIB->Menu->Tools->Graphcut segmentation
    
	% Copyright (C) 27.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	% 02.11.2017 taken from Graphcut/watershed into a separate tool
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        graphcut
        % a structure array with the graphcut data
        mode
        % a string with mode to use: 
        % - 'mode2dCurrentRadio'
        % - 'mode2dRadio'
        % - 'mode3dRadio'
        % - 'mode3dGridRadio'
        realtimeSwitch
        % enable real time segmentation
        slic_size
        % size of slic superpixels
        shownLabelObj
        % cell array with indices of currently displayed superpixels for the objects
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
        watershed_size
        % size of watershed superpixels
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
        
        Graphcut = mibGraphcut_CalcSupervoxels(Graphcut, img, parLoopOptions)
        % declaration of method for calculation of supervoxels
        
    end
    
    methods
        function obj = mibGraphcutController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibGraphcutGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'graphcut segmentation is';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements if needed
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.text1.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            obj.slic_size = 500;
            obj.watershed_size = 15;
            
            % variable for data preprocessing
            obj.graphcut(1).slic = [];     % SLIC labels for the graph cut workflow
            obj.graphcut(1).noPix = [];    % number of superpixels/supervoxels for the graph cut workflow
            obj.graphcut(1).Graph = cell(1);    % graph for the graph cut workflow
            obj.graphcut(1).grid = struct;     % variable for the grid details
            obj.graphcut(1).version = 2.2;     % version of the graphcut tool
            
            obj.shownLabelObj = cell(1);  % indices of currently displayed superpixels for the objects
            obj.seedObj = cell(1);
            obj.seedBg = cell(1);
            obj.realtimeSwitch = 0;
            obj.timerElapsedMax = .5;   % if segmentation is slower than this time, show the waitbar
            obj.timerElapsed = 9999999; % initialize the timer
            
            % selected default mode
            obj.mode = 'mode2dCurrentRadio';
            
            obj.updateWidgets(); % update widgets
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
            obj.listener{2} = addlistener(obj.mibModel, 'setData', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
        end
        
        function closeWindow(obj)
            % closing mibGraphcutController  window
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
            
            if obj.mibModel.getImageProperty('depth') < 2
                obj.View.handles.mode3dRadio.Enable = 'off';
                obj.View.handles.mode3dGridRadio.Enable = 'off';
                obj.View.handles.mode2dCurrentRadio.Value = 1;
            else
                obj.View.handles.mode3dRadio.Enable = 'on';
                obj.View.handles.mode3dGridRadio.Enable = 'on';
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
            end
            obj.View.handles.imageColChPopup.String = colCh;
            
            % populating lists of materials
            obj.updateMaterialsBtn_Callback();
            
            % populate subarea edit boxes
            if isempty(obj.graphcut(1).slic)
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
                obj.View.handles.backgroundMaterialPopup.Value = 1;
                obj.View.handles.backgroundMaterialPopup.String = 'Please create a model with 2 materials: background and object and restart the watershed tool';
                obj.View.handles.backgroundMaterialPopup.BackgroundColor = 'r';
                obj.View.handles.signalMaterialPopup.Value = 1;
                obj.View.handles.signalMaterialPopup.String = 'Please create a model with 2 materials: background and object and restart the watershed tool';
                obj.View.handles.signalMaterialPopup.BackgroundColor = 'r';
                
            else
                %selectedMaterial = obj.mibModel.getImageProperty('selectedMaterial') - 2;
                obj.View.handles.backgroundMaterialPopup.Value = 1;
                obj.View.handles.backgroundMaterialPopup.String = list;
                obj.View.handles.backgroundMaterialPopup.BackgroundColor = 'w';
                obj.View.handles.signalMaterialPopup.Value = numel(list);
                obj.View.handles.signalMaterialPopup.String = list;
                obj.View.handles.signalMaterialPopup.BackgroundColor = 'w';
            end
        end
        
        function status = clearPreprocessBtn_Callback(obj)
            % function clearPreprocessBtn_Callback(obj)
            % callback for press of clearPreprocessBtn; clear the preprocessed data
            status = 0;
            
            if ~isempty(obj.graphcut(1).noPix)
                button =  questdlg(sprintf('!!! Attention !!!\n\nThe pre-processed data will be removed!'),...
                    'Warning!', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button,'Cancel'); return; end
            end
            
            obj.graphcut = struct();
            obj.graphcut(1).slic = [];     % SLIC labels for the graph cut workflow
            obj.graphcut(1).noPix = [];    % number of superpixels/supervoxels for the graph cut workflow
            obj.graphcut(1).Graph = cell(1);    % graph for the graph cut workflow
            obj.graphcut(1).grid = struct;    % a structure for the grid mode of the graphcut tool
            obj.graphcut(1).version = 2.2;
            
            % store size of superpixels
            if strcmp(obj.View.handles.superpixTypePopup.String{obj.View.handles.superpixTypePopup.Value}, 'SLIC')
                obj.slic_size = str2double(obj.View.handles.superpixelEdit.String);
            else
                obj.watershed_size = str2double(obj.View.handles.superpixelEdit.String);
            end
            
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String);  %#ok<ST2NM>
            depth = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>
            obj.graphcut(1).bb = [min(width) max(width) min(height) max(height) min(depth) max(depth)]; % bounding box of the dataset to process [.x .y .z];
            if strcmp(obj.mode, 'mode3dGridRadio')
                % populate obj.graphcut(1).grid structure
                tilesX =  str2double(obj.View.handles.chopXedit.String);  % calculate supervoxels for the chopped datasets
                tilesY =  str2double(obj.View.handles.chopYedit.String);
                tilesZ =  str2double(obj.View.handles.chopZedit.String);
                bb = obj.graphcut(1).bb;
                obj.graphcut(1).grid.stepX = ceil((bb(2)-bb(1)+1)/tilesX);
                obj.graphcut(1).grid.stepY = ceil((bb(4)-bb(3)+1)/tilesY);
                obj.graphcut(1).grid.stepZ = ceil((bb(6)-bb(5)+1)/tilesZ);
                xBoundaries = [bb(1):obj.graphcut(1).grid.stepX:bb(2) bb(2)];
                yBoundaries = [bb(3):obj.graphcut(1).grid.stepY:bb(4) bb(4)];
                zBoundaries = [bb(5):obj.graphcut(1).grid.stepZ:bb(6) bb(6)];

                index = 1;
                for z = 1:tilesZ
                    for y = 1:tilesY
                        for x = 1:tilesX
                            obj.graphcut(1).grid.bb(x,y,z).x = [xBoundaries(x) xBoundaries(x+1)];
                            obj.graphcut(1).grid.bb(x,y,z).width = xBoundaries(x+1)-xBoundaries(x)+1;
                            obj.graphcut(1).grid.bb(x,y,z).y = [yBoundaries(y) yBoundaries(y+1)];
                            obj.graphcut(1).grid.bb(x,y,z).height = yBoundaries(y+1)-yBoundaries(y)+1;
                            obj.graphcut(1).grid.bb(x,y,z).z = [zBoundaries(z) zBoundaries(z+1)];
                            obj.graphcut(1).grid.bb(x,y,z).depth = zBoundaries(z+1)-zBoundaries(z)+1;
                            obj.graphcut(1).grid.bb(x,y,z).index = index;
                            index = index + 1;
                        end
                    end
                end
                obj.graphcut(1).tilesX = tilesX;
                obj.graphcut(1).tilesY = tilesY;
                obj.graphcut(1).tilesZ = tilesZ;
            else
                obj.graphcut(1).grid.bb(1).x = [min(width) max(width)];
                obj.graphcut(1).grid.bb(1).width = obj.graphcut(1).grid.bb(1).x(2)-obj.graphcut(1).grid.bb(1).x(1)+1;
                obj.graphcut(1).grid.bb(1).y = [min(height) max(height)];
                obj.graphcut(1).grid.bb(1).height = obj.graphcut(1).grid.bb(1).y(2)-obj.graphcut(1).grid.bb(1).y(1)+1;
                obj.graphcut(1).grid.bb(1).z = [min(depth) max(depth)];
                obj.graphcut(1).grid.bb(1).depth = obj.graphcut(1).grid.bb(1).z(2)-obj.graphcut(1).grid.bb(1).z(1)+1;
                obj.graphcut(1).grid.bb(1).index = 1;
                obj.graphcut(1).grid.stepX = obj.graphcut(1).grid.bb(1).width;
                obj.graphcut(1).grid.stepY = obj.graphcut(1).grid.bb(1).height;
                obj.graphcut(1).grid.stepZ = obj.graphcut(1).grid.bb(1).depth;
                obj.graphcut(1).tilesX = 1;
                obj.graphcut(1).tilesY = 1;
                obj.graphcut(1).tilesZ = 1;
            end
            
            %obj.graphcut(1).PixelIdxList = [];  % position of pixels in each supervoxels
            %obj.graphcut(1).PixelIdxList = cell(1);  % position of pixels in each supervoxels
            
            if obj.View.handles.mode2dRadio.Value == 1
                obj.seedObj = cell(1);
                obj.seedBg = cell(1);
                obj.shownLabelObj = cell([obj.graphcut(1).grid.bb(1).depth 1]);  % indices of currently displayed superpixels for the objects
            elseif obj.View.handles.mode3dGridRadio.Value == 1
                obj.shownLabelObj = cell([numel(obj.graphcut(1).grid.bb) 1]);  % indices of currently displayed superpixels for the objects
                obj.seedObj = cell([numel(obj.graphcut(1).grid.bb) 1]);
                obj.seedBg = cell([numel(obj.graphcut(1).grid.bb) 1]);
            else
                obj.shownLabelObj = cell(1);  % indices of currently displayed superpixels for the objects    
                obj.seedObj = cell(1);
                obj.seedBg = cell(1);
            end
            
            bgcol = obj.View.handles.resetDimsBtn.BackgroundColor;
            obj.View.handles.preprocessBtn.BackgroundColor = bgcol;
            obj.View.handles.superpixelsBtn.BackgroundColor = bgcol;
            obj.View.handles.superpixelsCountText.String = sprintf('Superpixels count: 0');
            
            val = str2num(obj.View.handles.binSubareaEdit.String); %#ok<ST2NM>
            % disable the realtime mode
            if sum(val) ~= 2
                obj.View.handles.realtimeCheck.Value = 0;   % the auto update mode is not compatible with the binned datasets
                obj.realtimeSwitch = 0;
                obj.View.handles.realtimeCheck.Enable = 'off';
                obj.View.handles.realtimeText.Enable = 'off';
            else
                obj.View.handles.realtimeCheck.Enable = 'on';
                obj.View.handles.realtimeText.Enable = 'on';
            end
            status = 1;
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
            % @li 'mode3dGridRadio'
            
            if ~isempty(obj.graphcut(1).noPix)
                button =  questdlg(sprintf('!!! Attention !!!\n\nThe pre-processed data will be removed!'),...
                    'Warning!', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button,'Cancel')
                    obj.View.handles.(obj.mode).Value = 1;
                    return;
                end
                obj.graphcut = struct();
                obj.graphcut(1).noPix = [];
                obj.clearPreprocessBtn_Callback();    % clear preprocessed data
            end
            obj.mode = hObject.Tag;
            
            obj.superpixTypePopup_Callback();
            hObject.Value = 1;
        end
        
        function checkDimensions(obj, hObject)
            % function checkDimensions(parameter)
            % check entered dimensions for the dataset to process
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
                errordlg('Please check the values!', 'Wrong parameters!');
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
        
        function doGraphcutSegmentation(obj)
            % function doGraphcutSegmentation(obj)
            % make graphcut segmentation
            
            bgMaterialId = obj.View.handles.backgroundMaterialPopup.Value;    % index of the background label
            seedMaterialId = obj.View.handles.signalMaterialPopup.Value;    % index of the signal label
            noMaterials = numel(obj.View.handles.signalMaterialPopup.String);    % number of materials in the model

            if bgMaterialId == seedMaterialId
                errordlg(sprintf('!!! Error !!!\nWrong selection of materials!\nPlease select two different materials in the Background and Object combo boxes of the Image segmentation settings panel'))
                return;
            end
            
            if isempty(obj.graphcut(1).noPix); obj.superpixelsBtn_Callback(); end
            if obj.timerElapsed > obj.timerElapsedMax
                wb = waitbar(0, sprintf('Graphcut segmentation...\nPlease wait...'), 'Name', 'Maxflow/Mincut');
            end
            
            if strcmp(obj.mode, 'mode3dGridRadio')
                [winWidth, winHeight] = obj.mibModel.getAxesLimits(); 
                centX = mean(winWidth);
                centY = mean(winHeight);
                centZ = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber;
                
                bbX = mean(vertcat(obj.graphcut(1).grid.bb.x),2);
                bbY = mean(vertcat(obj.graphcut(1).grid.bb.y),2);
                bbZ = mean(vertcat(obj.graphcut(1).grid.bb.z),2);
                bbCenters = [bbX, bbY, bbZ];
                distances = sqrt((bbCenters(:,1)-centX).^2 + (bbCenters(:,2)-centY).^2 + (bbCenters(:,3)-centZ).^2);
                [~, graphId] = min(distances);
                
                % get area for processing
                width = obj.graphcut(1).grid.bb(graphId).width; 
                height = obj.graphcut(1).grid.bb(graphId).height;
                depth = obj.graphcut(1).grid.bb(graphId).depth;
                % fill structure to use with getSlice and getDataset methods
                getDataOptions.x = obj.graphcut(1).grid.bb(graphId).x;
                getDataOptions.y = obj.graphcut(1).grid.bb(graphId).y;
                getDataOptions.z = obj.graphcut(1).grid.bb(graphId).z;
            else
                graphId = 1;
                % get area for processing
                width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
                height = str2num(obj.View.handles.ySubareaEdit.String);  %#ok<ST2NM>
                depth = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>

                % fill structure to use with getSlice and getDataset methods
                getDataOptions.x = [min(width) max(width)];
                getDataOptions.y = [min(height) max(height)];
                getDataOptions.z = [min(depth) max(depth)];
                getDataOptions.blockModeSwitch = 0;
            end
            
            % generate a structure for conversion of pixels in the 3D
            % cropped graphcut
            convertPixelOpt.x = getDataOptions.x;
            convertPixelOpt.y = getDataOptions.y;
            convertPixelOpt.z = getDataOptions.z;
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((getDataOptions.x(2)-getDataOptions.x(1)+1) / binVal(1));
            binHeight = ceil((getDataOptions.y(2)-getDataOptions.y(1)+1) / binVal(1));
            binDepth = ceil((getDataOptions.z(2)-getDataOptions.z(1)+1) / binVal(2));
            
            if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0   % initialize the mask layer if it is not present
                obj.mibModel.I{obj.mibModel.Id}.clearMask();   
            end
            
            if obj.View.handles.mode2dCurrentRadio.Value
                % initialize
                negIds = []; 
                posIds = [];
                
                seedImg = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, NaN, getDataOptions));   % get slice
                
                % tweak to work also with a current view mode
                if size(obj.graphcut(1).slic, 3) > 1
                    sliceNo = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                    currSlic = obj.graphcut(1).slic(:,:,sliceNo);
                else
                    currSlic = obj.graphcut(1).slic;
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
                
                if strcmp(obj.graphcut(1).superPixType, 'Watershed') && strcmp(obj.graphcut(1).dilateMode, 'post')  % watershed
                    % remove 0 indices
                    labelObj(labelObj==0) = [];
                    labelBg(labelBg==0) = [];
                end
                
                % generate data term
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.45, wb, sprintf('Generating data term\nPlease wait...'));
                end
                
                T = zeros([obj.graphcut(1).noPix(sliceNo), 2])+0.5;
                % remove from labelObj those that are also found in labelBg
                labelObj(ismember(labelObj, labelBg)) = [];
                
                T(labelObj, 1) = 0;        T(labelObj, 2) = 99999;
                T(labelBg,  1) = 99999;      T(labelBg,  2) = 0;
                
                T=sparse(T);
                
                %hView = view(biograph(handles.graphcut.Graph{sliceNo},[],'ShowArrows','off','ShowWeights','on'));
                %set(hView.Nodes(labelObj), 'color',[0 1 0]);
                %set(hView.Nodes(labelBg), 'color',[1 0 0]);
                
                [~, labels] = maxflow_v222(obj.graphcut(1).Graph{sliceNo}, T);
                
                % % test of the standard Matlab maxflow function
                %matlabGraph = graph(obj.graphcut(1).Graph{sliceNo});
                %[~,~, cs, ~] = maxflow(matlabGraph, labelObj, labelBg);
                %labels = zeros([obj.graphcut(1).noPix(sliceNo), 1]);
                %labels(cs) = 1;
                
                if isempty(obj.shownLabelObj{1})
                    obj.shownLabelObj{1} = labels;
                    Mask = zeros(size(seedImg),'uint8');
                else
                    Mask = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, NaN, getDataOptions));   % get slice
                    negIds = obj.shownLabelObj{1} - labels;
                    posIds = labels - obj.shownLabelObj{1};
                    obj.shownLabelObj{1} = labels;
                end
                
                % % using ismembc instead of ismember because it is a bit faster
                % % however, the vertcut with known indeces of pixels is faster!
                % indexLabel = find(labels>0);
                % Mask(ismember(double(currSlic), indexLabel)) = 1;
                if isfield(obj.graphcut(1), 'PixelIdxList')
                    if ~isempty(negIds)
                        Mask(vertcat(obj.graphcut(1).PixelIdxList{negIds>0})) = 0;  % remove background superpixels
                        Mask(vertcat(obj.graphcut(1).PixelIdxList{posIds>0})) = 1;  % add object superpixels
                    else
                        Mask(vertcat(obj.graphcut(1).PixelIdxList{labels>0})) = 1;    
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
                if strcmp(obj.graphcut(1).superPixType, 'Watershed') && strcmp(obj.graphcut(1).dilateMode, 'post')  % watershed
                    Mask = imdilate(Mask, ones(3));
                end
                
                if binVal(1) ~= 1   % bin data
                    Mask = imresize(Mask, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                end
                obj.mibModel.setData2D('mask', Mask, NaN, NaN, NaN, getDataOptions);   % set slice
            elseif obj.View.handles.mode2dRadio.Value
                if obj.realtimeSwitch == 0
                    startIndex = getDataOptions.z(1);
                    endIndex = getDataOptions.z(2);
                    index = 1;
                else
                    startIndex = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                    endIndex = startIndex;
                    index = startIndex - getDataOptions.z(1) + 1;
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
                    currSlic = obj.graphcut(1).slic(:,:,index);
                    labelObj = unique(currSlic(seedImg==seedMaterialId));
                    if isempty(labelObj); index = index + 1; continue; end
                    
                    labelBg = unique(currSlic(seedImg==bgMaterialId));
                    
                    if strcmp(obj.graphcut(1).superPixType, 'Watershed') && strcmp(obj.graphcut(1).dilateMode, 'post')  % watershed
                        % remove 0 indices
                        labelObj(labelObj==0) = [];
                        labelBg(labelBg==0) = [];
                    end
                    
                    % remove from labelObj those that are also found in labelBg
                    labelObj(ismember(labelObj, labelBg)) = [];
                    
                    % generate data term
                    T = zeros([obj.graphcut(1).noPix(index), 2])+0.5;
                    T(labelObj, 1) = 0;
                    T(labelObj, 2) = 99999;
                    T(labelBg, 1) = 99999;
                    T(labelBg, 2) = 0;
                    T=sparse(T);
                    
                    %[~, labels] = maxflow(obj.graphcut(1).Graph{index}, T);
                    [~, labels] = maxflow_v222(obj.graphcut(1).Graph{index}, T);
                    
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
                            Mask(vertcat(obj.graphcut(1).PixelIdxList{index}{negIds>0})) = 0;  % remove background superpixels
                            Mask(vertcat(obj.graphcut(1).PixelIdxList{index}{posIds>0})) = 1;  % add object superpixels
                        else
                            Mask(vertcat(obj.graphcut(1).PixelIdxList{index}{labels>0})) = 1;
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
                    if strcmp(obj.graphcut(1).superPixType, 'Watershed') && strcmp(obj.graphcut(1).dilateMode, 'post')  % watershed
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
                
                if numel(obj.shownLabelObj{graphId}) == 0
                    %depth = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
                    %obj.seedObj = cell([max(depth)-min(depth)+1 1]);
                    %obj.seedBg = cell([max(depth)-min(depth)+1 1]);
                    
                    obj.seedObj{graphId} = cell([getDataOptions.z(2)-getDataOptions.z(1)+1 1]);
                    obj.seedBg{graphId} = cell([getDataOptions.z(2)-getDataOptions.z(1)+1 1]);
                    
                    seedImg = cell2mat(obj.mibModel.getData3D('model', NaN, 4, NaN, getDataOptions));   % get dataset
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        if obj.timerElapsed > obj.timerElapsedMax
                            waitbar(.05, wb, sprintf('Binning the labels\nPlease wait...'));
                        end
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = binDepth;
                        resizeOptions.method = 'nearest';
                        seedImg = mibResize3d(seedImg, [], resizeOptions);
                    end
                else
                    sliceId = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber()-obj.graphcut(1).grid.bb(graphId).z(1)+1;
                    if size(obj.graphcut(graphId).slic, 3) < sliceId     % check for out of bounaries
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
                if numel(obj.shownLabelObj{graphId}) == 0   % generate for 3D
                    for sliceId = 1:size(obj.graphcut(graphId).slic, 3)
                        currSlicImg = obj.graphcut(graphId).slic(:, :, sliceId);
                        currSeedImg = seedImg(:, :, sliceId);
                        
                        obj.seedObj{graphId}{sliceId} = unique(currSlicImg(currSeedImg==seedMaterialId));
                        
                        if noMaterials == 2
                            obj.seedBg{graphId}{sliceId} = unique(currSlicImg(currSeedImg==bgMaterialId));
                            %if ~isempty(find(obj.seedBg{graphId}{sliceId}==0))
                                %warndlg(sprintf('!!! Warning !!!\nA watershed/slic cluster with index 0'))
                            %end
                        else
                            % combine bg and all other materials to background    
                            obj.seedBg{graphId}{sliceId} = unique(currSlicImg(~ismember(currSeedImg, [0 seedMaterialId])));
                            
                            %if ~isempty(find(obj.seedBg{graphId}{sliceId}==0))
                            %    0
                            %end
                        end
                        %labelBg(ismember(labelBg, labelObj)) = [];
                    end
                else    % work with the current slice in 2D
                    currSlicImg = obj.graphcut(graphId).slic(:, :, sliceId);
                    obj.seedObj{graphId}{sliceId} = unique(currSlicImg(seedImg==seedMaterialId));
                    if noMaterials == 2
                        obj.seedBg{graphId}{sliceId} = unique(currSlicImg(seedImg==bgMaterialId));
                    else
                        % combine bg and all other materials to background
                        obj.seedBg{graphId}{sliceId} = unique(currSlicImg(~ismember(seedImg, [0 seedMaterialId])));
                    end
                end
                
                % when two seeds overlap give preference to the background
                labelBg = vertcat(obj.seedBg{graphId}{:});
                    
                for sliceId = 1:size(obj.graphcut(graphId).slic, 3)
                    [commonVal, bgIdx] = intersect(obj.seedObj{graphId}{sliceId}, labelBg);
                    obj.seedObj{graphId}{sliceId}(bgIdx) = [];
                end
                labelObj = vertcat(obj.seedObj{graphId}{:});
                
%                 if strcmp(obj.graphcut(1).superPixType, 'Watershed') && strcmp(obj.graphcut(1).dilateMode, 'post')   % watershed
%                     % remove 0 indices
%                     labelObj(labelObj==0) = [];
%                     labelBg(labelBg==0) = [];
%                 end
                
                % generate data term
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.45, wb, sprintf('Generating data term\nPlease wait...'));
                end
                try
                    T = zeros([obj.graphcut(graphId).noPix, 2])+0.5;
                    T(labelObj, 1) = 0;
                    T(labelObj, 2) = 999999;
                    T(labelBg, 1) = 999999;
                    T(labelBg, 2) = 0;
                catch err
                    warndlg(sprintf('!!! Warning !!!\nA supervoxel with index 0 is most likely exists; try to recalculate the supervoxels\n\n%s\n%s', err.identifier, err.message), 'Error');
                end
                
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
                %[~, labels] = maxflow(obj.graphcut(1).Graph{1}, T);
                [~, labels] = maxflow_v222(obj.graphcut(graphId).Graph{1}, T);
                
                if obj.timerElapsed > obj.timerElapsedMax
                    waitbar(.75, wb, sprintf('Generating the mask\nPlease wait...'));
                end
                
                if isempty(obj.shownLabelObj{graphId})
                    obj.shownLabelObj{graphId} = labels;
                    Mask = zeros(size(seedImg),'uint8');
                else
                    %Mask = cell2mat(obj.mibModel.getData3D('mask', NaN, 4, NaN, getDataOptions));   % get mask
                    negIds = obj.shownLabelObj{graphId} - labels;
                    posIds = labels - obj.shownLabelObj{graphId};
                    obj.shownLabelObj{graphId} = labels;
                end
                
                % % alternative ~35% slower
                %indexLabel = find(labels>0);
                %Mask(ismember(double(graphcut.slic), find(labels>0))) = 1;
                
                % % using ismembc instead of ismember because it is a bit faster
                % % however, the vertcut with known indeces of pixels is faster!
                % unfortunately it takes a lot of space to keep the indices of
                % supervoxels
                if isfield(obj.graphcut(graphId), 'PixelIdxList')
                    if ~isempty(negIds)
                        setDataOpt.PixelIdxList = find(negIds>0);
                        if ~isempty(setDataOpt.PixelIdxList)
                            setDataOpt.PixelIdxList = vertcat(obj.graphcut(graphId).PixelIdxList{setDataOpt.PixelIdxList});
                            setDataOpt.PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(setDataOpt.PixelIdxList, convertPixelOpt);   % recalc indices
                            dataset = zeros([numel(setDataOpt.PixelIdxList), 1], 'uint8');
                            obj.mibModel.setData3D('mask', dataset, NaN, NaN, NaN, setDataOpt);
                        end
                        setDataOpt.PixelIdxList = find(posIds>0);
                        if ~isempty(setDataOpt.PixelIdxList)
                            setDataOpt.PixelIdxList = vertcat(obj.graphcut(graphId).PixelIdxList{setDataOpt.PixelIdxList});
                            setDataOpt.PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(setDataOpt.PixelIdxList, convertPixelOpt);   % recalc indices
                            dataset = zeros([numel(setDataOpt.PixelIdxList), 1], 'uint8')+1;
                            obj.mibModel.setData3D('mask', dataset, NaN, NaN, NaN, setDataOpt);
                        end
                        if obj.timerElapsed > obj.timerElapsedMax
                            delete(wb);
                        end
                        return;
                    else
                        Mask(vertcat(obj.graphcut(graphId).PixelIdxList{labels>0})) = 1;  
                    end
                else
                    if ~isempty(negIds)
                        negIds = find(negIds > 0);
                        posIds = find(posIds > 0);
                        if isa(obj.graphcut(graphId).slic, 'uint8')
                            negIds = uint8(negIds);
                            posIds = uint8(posIds);
                        elseif isa(obj.graphcut(graphId).slic, 'uint16')
                            negIds = uint16(negIds);
                            posIds = uint16(posIds);
                        else
                            negIds = uint32(negIds);
                            posIds = uint32(posIds);
                        end
                        if ~isempty(negIds)
                            setDataOpt.PixelIdxList = find(ismember(obj.graphcut(graphId).slic, negIds)>0);
                            setDataOpt.PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(setDataOpt.PixelIdxList, convertPixelOpt);   % recalc indices
                            dataset = zeros([numel(setDataOpt.PixelIdxList), 1], 'uint8');
                            obj.mibModel.setData3D('mask', dataset, NaN, NaN, NaN, setDataOpt);
                        end
                        
                        if ~isempty(posIds)
                            setDataOpt.PixelIdxList = find(ismember(obj.graphcut(graphId).slic, posIds)>0);
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
                        if isa(obj.graphcut(graphId).slic, 'uint8')
                            indexLabel = uint8(indexLabel);
                        elseif isa(obj.graphcut(graphId).slic, 'uint16')
                            indexLabel = uint16(indexLabel);
                        else
                            indexLabel = uint32(indexLabel);
                        end
                        %Mask(ismembc(obj.graphcut(graphId).slic, indexLabel)) = 1;
                        Mask(ismember(obj.graphcut(graphId).slic, indexLabel)) = 1;
                    end
                end
                
                % remove boundaries between superpixels
                if strcmp(obj.graphcut(1).superPixType, 'Watershed') && strcmp(obj.graphcut(1).dilateMode, 'post')  % watershed
                    Mask = imdilate(Mask, ones([3 3 3]));
                end
                
                %Mask(seedImg==bgMaterialId) = 0;    % remove background pixels
                %Mask(seedImg==seedMaterialId) = 1;    % add label pixels
                
                if binVal(1) ~= 1 || binVal(2) ~= 1
                    if obj.timerElapsed > obj.timerElapsedMax
                        waitbar(.95, wb, sprintf('Re-binning the mask\nPlease wait...'));
                    end
                    resizeOptions.width = getDataOptions.x(2)-getDataOptions.x(1)+1;
                    resizeOptions.height = getDataOptions.y(2)-getDataOptions.y(1)+1;
                    resizeOptions.depth = getDataOptions.z(2)-getDataOptions.z(1)+1;
                    resizeOptions.method = 'nearest';
                    Mask = mibResize3d(Mask, [], resizeOptions);
                end
                obj.mibModel.setData3D('mask', Mask, NaN, 4, NaN, getDataOptions);   % set dataset
            end
            if obj.timerElapsed > obj.timerElapsedMax
                delete(wb);
            end
        end
        
        function superpixelsBtn_Callback(obj)
            % function superpixelsBtn_Callback(obj)
            % callback for press of superpixelsBtn - calculate superpixels
            
            status = obj.clearPreprocessBtn_Callback();
            if status == 0; return; end
            
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
                if isequal(filename,0); return; end % check for cancel
                fn_out = fullfile(path, filename);
            end
            
            tic
            superPixType = obj.View.handles.superpixTypePopup.String{obj.View.handles.superpixTypePopup.Value};
            if strcmp(superPixType, 'SLIC')
                wb = waitbar(0, sprintf('Initiating...\nPlease wait...'), 'Name', 'SLIC superpixels/supervoxels');
            else
                wb = waitbar(0, sprintf('Initiating...\nPlease wait...'), 'Name', 'Watershed superpixels/supervoxels');
            end
            
            col_channel = obj.View.handles.imageColChPopup.Value;
            superpixelSize = str2double(obj.View.handles.superpixelEdit.String);
            superpixelCompact = str2double(obj.View.handles.superpixelsCompactEdit.String);
            blackOnWhite = obj.View.handles.signalPopup.Value;       % black ridges over white background
            
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = obj.graphcut(1).bb(1:2);    %[min(width) max(width)];
            getDataOptions.y = obj.graphcut(1).bb(3:4);    %[min(height) max(height)];
            getDataOptions.z = obj.graphcut(1).bb(5:6);    %[min(depth) max(depth)];
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((getDataOptions.x(2)-getDataOptions.x(1)+1) / binVal(1));
            binHeight = ceil((getDataOptions.y(2)-getDataOptions.y(1)+1) / binVal(1));
            binDepth = ceil((getDataOptions.z(2)-getDataOptions.z(1)+1) / binVal(2));
            
            obj.graphcut(1).dilateMode = 'post';
            
            tilesX =  str2double(obj.View.handles.chopXedit.String);  % calculate supervoxels for the chopped datasets
            tilesY =  str2double(obj.View.handles.chopYedit.String);
            tilesZ =  str2double(obj.View.handles.chopZedit.String);
            
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
                    if strcmp(superPixType, 'SLIC')     % generate SLIC superpixels
                        waitbar(.05, wb, sprintf('Calculating SLIC superpixels...\nPlease wait...'));
                        % calculate number of supervoxels
                        obj.graphcut(1).noPix = ceil(dims(1)*dims(2)/superpixelSize);
                        
                        [obj.graphcut(1).slic, obj.graphcut(1).noPix] = slicmex(img, obj.graphcut(1).noPix, superpixelCompact);
                        obj.graphcut(1).noPix = double(obj.graphcut(1).noPix);
                        % remove superpixel with 0-index
                        obj.graphcut(1).slic = obj.graphcut(1).slic + 1;
                        % a new procedure imRAG that is few times faster
                        %STATS = regionprops(obj.graphcut(1).slic, img, 'MeanIntensity','PixelIdxList');
                        STATS = regionprops(obj.graphcut(1).slic, img, 'MeanIntensity');
                        gap = 0;    % regions are connected, no gap in between
                        obj.graphcut(1).Edges{1} = imRAG(obj.graphcut(1).slic, gap);
                        obj.graphcut(1).Edges{1} = double(obj.graphcut(1).Edges{1});
                        
                        obj.graphcut(1).EdgesValues{1} = zeros([size(obj.graphcut(1).Edges{1},1), 1]);
                        meanVals = [STATS.MeanIntensity];
                        
                        for i=1:size(obj.graphcut(1).Edges{1}, 1)
                            %EdgesValues(i) = 255/(abs(meanVals(Edges(i,1))-meanVals(Edges(i,2)))+.00001);     % should be low (--> 0) at the edges of objects
                            obj.graphcut(1).EdgesValues{1}(i) = abs(meanVals(obj.graphcut(1).Edges{1}(i,1))-meanVals(obj.graphcut(1).Edges{1}(i,2)));     % should be low (--> 0) at the edges of objects
                        end
                        
                        waitbar(.9, wb, sprintf('Calculating weights for boundaries...\nPlease wait...'));
                        obj.recalcGraph_Callback();
                    else    % generate WATERSHED superpixels
                        waitbar(.05, wb, sprintf('Calculating Watershed superpixels...\nPlease wait...'));
                        if blackOnWhite == 1
                            img = imcomplement(img);    % convert image that the ridges are white
                        end
                        
                        mask = imextendedmin(img, superpixelSize);
                        mask = imimposemin(img, mask);
                        
                        obj.graphcut(1).slic = watershed(mask);       % generate superpixels
                        waitbar(.5, wb, sprintf('Calculating connectivity ...\nPlease wait...'));
                        [obj.graphcut(1).Edges{1}, edgeIndsList] = imRichRAG(obj.graphcut(1).slic);
                        % calculate mean of intensities at the borders between each superpixel
                        obj.graphcut(1).EdgesValues{1} = cell2mat(cellfun(@(idx) mean(img(idx)), edgeIndsList, 'UniformOutput', 0));
                        obj.recalcGraph_Callback();
                        
                        obj.graphcut(1).noPix = max(obj.graphcut(1).slic(:));
                        % two modes for dilation: 'pre' and 'post'
                        % in 'pre' the superpixels are dilated before the graphcut
                        % segmentation, i.e. in this function
                        % in 'post' the superpixels are dilated after the graphcut
                        % segmentation
                        obj.graphcut(1).dilateMode = 'pre';
                        if strcmp(obj.graphcut(1).dilateMode, 'pre')
                            obj.graphcut(1).slic = imdilate(obj.graphcut(1).slic, ones(3));
                        end
                        %STATS = regionprops(obj.graphcut(1).slic, 'PixelIdxList');
                    end
                    %obj.graphcut(1).PixelIdxList{1} = {STATS.PixelIdxList};
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
                    obj.graphcut(1).slic = zeros(size(img));
                    obj.graphcut(1).noPix = zeros([size(img,3), 1]);
                    if strcmp(superPixType, 'SLIC')     % generate SLIC superpixels
                        noPix = ceil(dims(1)*dims(2)/superpixelSize);
                        
                        for i=1:dims(3)
                            [obj.graphcut(1).slic(:,:,i), noPixCurrent] = slicmex(img(:,:,i), noPix, superpixelCompact);
                            obj.graphcut(1).noPix(i) = double(noPixCurrent);
                            % remove superpixel with 0-index
                            obj.graphcut(1).slic(:,:,i) = obj.graphcut(1).slic(:,:,i) + 1;
                            
                            % a new procedure imRAG that is few times faster
                            %STATS = regionprops(obj.graphcut(1).slic(:,:,i), img(:,:,i), 'MeanIntensity','PixelIdxList');
                            STATS = regionprops(obj.graphcut(1).slic(:,:,i), img(:,:,i), 'MeanIntensity');
                            gap = 0;    % regions are connected, no gap in between
                            Edges = imRAG(obj.graphcut(1).slic(:,:,i), gap);
                            Edges = double(Edges);
                            
                            EdgesValues = zeros([size(Edges,1), 1]);
                            meanVals = [STATS.MeanIntensity];
                            
                            for j=1:size(Edges,1)
                                %EdgesValues(i) = 255/(abs(meanVals(Edges(i,1))-meanVals(Edges(i,2)))+.00001);     % should be low (--> 0) at the edges of objects
                                EdgesValues(j) = abs(meanVals(Edges(j,1))-meanVals(Edges(j,2)));     % should be low (--> 0) at the edges of objects
                            end
                            
                            obj.graphcut(1).Edges{i} = Edges;
                            obj.graphcut(1).EdgesValues{i} = EdgesValues;
                            waitbar(i/dims(3), wb, sprintf('Calculating...\nPlease wait...'));
                        end
                        obj.recalcGraph_Callback();
                    else % generate WATERSHED superpixels
                        if blackOnWhite == 1
                            img = imcomplement(img);    % convert image that the ridges are white
                        end
                        for i=1:dims(3)
                            currImg = img(:,:,i);
                            mask = imextendedmin(currImg, superpixelSize);
                            mask = imimposemin(currImg, mask);
                            obj.graphcut(1).slic(:,:,i) = watershed(mask);       % generate superpixels
                            
                            % this call seems to be faster for 2D than using
                            % [Edges, EdgesValues] = imRichRAG(obj.graphcut(1).slic(:,:,i), 1, currImg);
                            [obj.graphcut(1).Edges{i}, edgeIndsList] = imRichRAG(obj.graphcut(1).slic(:,:,i));
                            % calculate mean of intensities at the borders between each superpixel
                            obj.graphcut(1).EdgesValues{i} = cell2mat(cellfun(@(idx) mean(currImg(idx)), edgeIndsList, 'UniformOutput', 0));
                            obj.graphcut(1).Edges{i} = double(obj.graphcut(1).Edges{i});
                            obj.graphcut(1).noPix(i) = double(max(max(obj.graphcut(1).slic(:,:,i))));
                            
                            % two modes for dilation: 'pre' and 'post'
                            % in 'pre' the superpixels are dilated before the graphcut
                            % segmentation, i.e. in this function
                            % in 'post' the superpixels are dilated after the graphcut
                            % segmentation
                            obj.graphcut(1).dilateMode = 'post';
                            obj.graphcut(1).dilateMode = 'pre';
                            if strcmp(obj.graphcut(1).dilateMode, 'pre')
                                obj.graphcut(1).slic(:,:,i) = imdilate(obj.graphcut(1).slic(:,:,i), ones(3));
                            end
                            waitbar(i/dims(3), wb, sprintf('Calculating...\nPlease wait...'));
                        end
                        obj.recalcGraph_Callback();
                    end
                case {'mode3dRadio', 'mode3dGridRadio'}
                    if strcmp(obj.mode, 'mode3dGridRadio')
                        % calculate subareas for 3D grid graphcut
                        if tilesX + tilesY + tilesZ == 3
                            warndlg(sprintf('!!! Attention !!!\n\nThe grid has not been defined, please use the Chop fields in the Details panel to specify number of the grid blocks'));
                            delete(wb);
                            return;
                        end
                    end
                    
                    % move settings to a structure for parfor loop
                    parLoopOptions.viewPort.min = obj.mibModel.I{obj.mibModel.Id}.viewPort.min(col_channel);
                    parLoopOptions.viewPort.max = obj.mibModel.I{obj.mibModel.Id}.viewPort.max(col_channel);
                    parLoopOptions.viewPort.gamma = obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(col_channel);
                    parLoopOptions.mibLiveStretchCheck = obj.mibModel.mibLiveStretchCheck;
                    parLoopOptions.binVal = binVal;
                    parLoopOptions.binHeight = binHeight;
                    parLoopOptions.binWidth = binWidth;
                    parLoopOptions.binDepth = binDepth;
                    parLoopOptions.superPixType = superPixType;
                    parLoopOptions.blackOnWhite = blackOnWhite;
                    parLoopOptions.superpixelSize = superpixelSize;
                    parLoopOptions.superpixelCompact = superpixelCompact;
                    parLoopOptions.waitbar = [];     % disable the waitbar
                    parLoopOptions.tilesX = tilesX;
                    parLoopOptions.tilesY = tilesY;
                    
                    % preparation step
                    Graphcut = obj.graphcut;
                    img = cell([numel(obj.graphcut(1).grid.bb), 1]);
                    for graphId = 1:numel(obj.graphcut(1).grid.bb)
                        getDataOptions = obj.graphcut(1).grid.bb(graphId);
                        img(graphId) = obj.mibModel.getData3D('image', NaN, 4, col_channel, getDataOptions);   % get dataset
                        Graphcut(graphId).slic = 0;
                        Graphcut(graphId).noPix = 0;
                        Graphcut(graphId).Edges = cell(1);
                        Graphcut(graphId).EdgesValues = cell(1);
                    end
                    
                    % get use parallel processing
                    if strcmp(obj.mode, 'mode3dGridRadio')
                        parallelSwitch = obj.View.handles.parforCheck.Value;
                    else
                        parallelSwitch = 0;
                    end
                    
                    if parallelSwitch == 1
                        waitbar(.5, wb, sprintf('Please note that the waitbar will not be updated\nwhile using the parallel computing...'), 'Name', 'Calculating graphcut...');
                        parfor graphId = 1:numel(obj.graphcut(1).grid.bb)
                            G = Graphcut(graphId);
                            G = mibGraphcutController.mibGraphcut_CalcSupervoxels(G, img{graphId}, parLoopOptions);
                            fNames = fieldnames(G);
                            for fieldId = 1:numel(fNames)
                                Graphcut(graphId).(fNames{fieldId}) = G.(fNames{fieldId});
                            end
                        end
                        obj.graphcut = Graphcut;
                        clear Graphcut;
                    else
                        if numel(obj.graphcut(1).grid.bb) == 1
                            parLoopOptions.waitbar = wb;     % enable the waitbar
                        end
                        for graphId = 1:numel(obj.graphcut(1).grid.bb)
                            waitbar(graphId/numel(obj.graphcut(1).grid.bb), wb, sprintf('Calculating graphcut\nThis will take a while...'));
                            G = Graphcut(graphId);
                            G = mibGraphcutController.mibGraphcut_CalcSupervoxels(G, img{graphId}, parLoopOptions);
                            fNames = fieldnames(G);
                            for fieldId = 1:numel(fNames)
                                Graphcut(graphId).(fNames{fieldId}) = G.(fNames{fieldId});
                            end
                        end
                        obj.graphcut = Graphcut;
                        clear Graphcut;
                    end
                    
                    for graphId = 1:numel(obj.graphcut(1).grid.bb)
                        % clear list of selected pixels
                        obj.seedObj{graphId} = cell([size(obj.graphcut(graphId).slic, 3), 1]);
                        obj.seedBg{graphId} = cell([size(obj.graphcut(graphId).slic, 3), 1]);
                    end
                    
                    obj.graphcut(1).mode = obj.mode;     % store the mode for the calculated superpixels
                    obj.graphcut(1).binVal = binVal;     % store the mode for the calculated superpixels
                    obj.graphcut(1).colCh = col_channel;     % store color channel
                    obj.graphcut(1).spSize = superpixelSize; % size of superpixels
                    obj.graphcut(1).spCompact = superpixelCompact; % compactness of superpixels
                    obj.graphcut(1).superPixType = superPixType;   % type of superpixels, 1-SLIC, 2-Watershed
                    obj.graphcut(1).blackOnWhite = blackOnWhite;   % 1-when black ridges over white background
                   
                    obj.recalcGraph_Callback();
            end
            

            if strcmp(obj.mode, 'mode2dCurrentRadio') || strcmp(obj.mode, 'mode2dRadio')
                % for 3d case the same procedure is done inside the switch
                % structure above
                
                for graphId = 1:numel(obj.graphcut)
                    % convert to a proper class, to uint8 if below 255
                    if max(obj.graphcut(graphId).noPix) < 256
                        obj.graphcut(graphId).slic = uint8(obj.graphcut(graphId).slic);
                    elseif max(obj.graphcut(1).noPix) < 65536
                        obj.graphcut(graphId).slic = uint16(obj.graphcut(graphId).slic);
                    elseif max(obj.graphcut(1).noPix) < 4294967295
                        obj.graphcut(graphId).slic = uint32(obj.graphcut(graphId).slic);
                    end
                end
                
                obj.graphcut(1).bb = [getDataOptions.x getDataOptions.y getDataOptions.z];   % store bounding box of the generated superpixels
                obj.graphcut(1).mode = obj.mode;     % store the mode for the calculated superpixels
                obj.graphcut(1).binVal = binVal;     % store the mode for the calculated superpixels
                obj.graphcut(1).colCh = col_channel;     % store color channel
                obj.graphcut(1).spSize = superpixelSize; % size of superpixels
                obj.graphcut(1).spCompact = superpixelCompact; % compactness of superpixels
                obj.graphcut(1).superPixType = superPixType;   % type of superpixels, 1-SLIC, 2-Watershed
                obj.graphcut(1).blackOnWhite = blackOnWhite;   % 1-when black ridges over white background
            end
            
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
            obj.View.handles.superpixelsCountText.String = sprintf('Superpixels count: %d', sum([obj.graphcut(:).noPix]));
            delete(wb);
            toc
        end
        
        function exportSuperpixelsBtn_Callback(obj)
            % function exportSuperpixelsBtn_Callback(obj)
            % callback for press of exportSuperpixelsBtn; export/save
            % supervoxels 
            global mibPath;
            Graphcut = obj.graphcut;
            if isempty(Graphcut(1).noPix); return; end
            
            prompts = {'Export to Matlab'; 'Save to a file'; 'Export to a model'; 'Export to 3DLines'};
            defAns = {false; false; false; false};
            dlgTitle = 'Export supervoxels';
            options.WindowStyle = 'normal';
            options.Title = 'Please select where to export the supervoxels';
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            if answer{1} == true
                title = 'Input variable to export';
                def = 'Graphcut';
                prompt = {'A variable for the export to Matlab'};
                answer2 = mibInputDlg({mibPath}, prompt, title, def);
                if size(answer2) == 0; return; end
                assignin('base', answer2{1}, Graphcut);
                fprintf('MIB: export superpixel data ("%s") to Matlab -> done!\n', answer2{1});
            end
            if answer{2} == true
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
            if answer{3} == true
                anwser2 = questdlg(sprintf('!!! Warning !!!\n\nIf you continue the existing model will be removed!'),'Export to model', 'Continue','Cancel', 'Cancel');
                if strcmp(anwser2, 'Cancel'); return; end
                
                wb = waitbar(0, sprintf('Exporting to a model\nPlease wait...'), 'Name', 'Export');
                
                graphId = 1;
                if strcmp(obj.mode, 'mode3dGridRadio')
                    [winWidth, winHeight] = obj.mibModel.getAxesLimits();
                    centX = mean(winWidth);
                    centY = mean(winHeight);
                    centZ = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber;
                    
                    bbX = mean(vertcat(obj.graphcut(1).grid.bb.x),2);
                    bbY = mean(vertcat(obj.graphcut(1).grid.bb.y),2);
                    bbZ = mean(vertcat(obj.graphcut(1).grid.bb.z),2);
                    bbCenters = [bbX, bbY, bbZ];
                    distances = sqrt((bbCenters(:,1)-centX).^2 + (bbCenters(:,2)-centY).^2 + (bbCenters(:,3)-centZ).^2);
                    [~, graphId] = min(distances);
                    
                    % get area for processing
                    width = obj.graphcut(1).grid.bb(graphId).width;
                    height = obj.graphcut(1).grid.bb(graphId).height;
                    depth = obj.graphcut(1).grid.bb(graphId).depth;
                    % fill structure to use with getSlice and getDataset methods
                    getDataOptions.x = obj.graphcut(1).grid.bb(graphId).x;
                    getDataOptions.y = obj.graphcut(1).grid.bb(graphId).y;
                    getDataOptions.z = obj.graphcut(1).grid.bb(graphId).z;
                end
                
                if Graphcut(graphId).noPix < 65536
                    modelType = 65535;
                else
                    modelType = 4294967295;    
                end
                
                if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
                    obj.mibModel.I{obj.mibModel.Id}.createModel(modelType);
                end
                waitbar(.1, wb);
                if modelType ~= obj.mibModel.I{obj.mibModel.Id}.modelType
                    obj.mibModel.I{obj.mibModel.Id}.convertModel(modelType);
                end
                if strcmp(Graphcut(1).mode, 'mode2dCurrentRadio')
                    obj.mibModel.setData2D('model', {Graphcut(graphId).slic}, NaN, 4);
                elseif strcmp(Graphcut(1).mode, 'mode3dGridRadio')
                	obj.mibModel.setData3D('model', {Graphcut(graphId).slic}, NaN, 4, NaN, getDataOptions);   % set dataset
                else
                    obj.mibModel.setData4D('model', {Graphcut(graphId).slic}, 4);
                end
                obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = {'1','2'}';
                waitbar(.9, wb);
                % adding extra colors if needed
                if size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, 1) < 65535
                    obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = [obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors; rand([65535-Graphcut(graphId).noPix, 3])];
                end
                [pathTemp, fnTemplate] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                model_fn = fullfile(pathTemp, ['Labels_' fnTemplate '.model']);
                obj.mibModel.I{obj.mibModel.Id}.modelFilename = model_fn;
                obj.mibModel.I{obj.mibModel.Id}.modelVariable = 'mibModel';
                waitbar(1, wb);
                eventdata = ToggleEventData(1); 
                notify(obj.mibModel, 'showModel', eventdata);
                notify(obj.mibModel, 'updateId');
                delete(wb);
                notify(obj.mibModel, 'plotImage');
            end
            if answer{4} == true
                answer2 = questdlg(sprintf('!!! Warning !!!\n\nExport to 3D lines is only recommended for relatively small number of supervoxels!'), ...
                    'Export to 3d lines', 'Continue', 'Cancel', 'Cancel');
                if strcmp(answer2, 'Cancel'); return; end
                
                wb = waitbar(0, 'Please wait...', 'Name', 'Exporting to 3D lines');
                switch obj.graphcut.mode
                    case 'mode3dRadio'
                        obj.mibModel.I{obj.mibModel.Id}.hLines3D.clearContents();  % clear Lines3D
                        %
                        STATS = regionprops(Graphcut.slic, 'Centroid');     % x,y,z
                        waitbar(0.2, wb);
                        % convert Centroids to a matrix
                        points = reshape([STATS.Centroid], [3, numel(STATS)])';
                        NodeTable = table(points, 'VariableNames',{'PointsXYZ'});
                        EdgeTable = table([Graphcut.Edges{1}(:,1), Graphcut.Edges{1}(:,2)], Graphcut.EdgesValues{1}, 'VariableNames', {'EndNodes', 'Weight'});
                        %
                        G = graph(EdgeTable, NodeTable);  % generate the graph
                        G.Nodes.Properties.VariableUnits = {'pixel'}; % it is important to indicate "pixel" unit for the PointsXYZ field, when using pixels

                        G.Nodes.Properties.UserData.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;   % required when points are pixels, add pixSize structure
                        G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                        waitbar(0.6, wb);
                        obj.mibModel.I{obj.mibModel.Id}.hLines3D.replaceGraph(G);
                    case 'mode2dRadio'
                        obj.mibModel.I{obj.mibModel.Id}.hLines3D.clearContents();  % clear Lines3D
                        %
                        treeNames = {};
                        t = [];     % target node
                        s = [];     % source node
                        w = [];     % edge weight
                        points = [];
                        maxNodeId = 0;
                        for z = 1:size(Graphcut.slic, 3)
                            STATS = regionprops(Graphcut.slic(:,:,z), 'Centroid');     % x,y
                            % convert Centroids to a matrix
                            cPoints = reshape([STATS.Centroid], [2, numel(STATS)])';
                            cPoints(:,3) = repmat(z, [size(cPoints,1) 1]);    % add z
                            points = cat(1, points, cPoints);
                            treeNames = [treeNames; repmat({sprintf('SliceNo_%.4d', z)}, [size(cPoints,1) 1])];
                            s = [s; Graphcut.Edges{z}(:,1) + maxNodeId];
                            t = [t; Graphcut.Edges{z}(:,2) + maxNodeId];
                            w = [w; Graphcut.EdgesValues{z}];
                            maxNodeId = maxNodeId + max(Graphcut.Edges{z}(:));
                            waitbar(z/size(Graphcut.slic, 3), wb);
                        end
                        waitbar(0.5, wb, 'Generating the 3D lines object');
                        NodeTable = table(points, treeNames, 'VariableNames',{'PointsXYZ', 'TreeName'});
                        EdgeTable = table([s, t], w, 'VariableNames', {'EndNodes', 'Weight'});
                        %
                        G = graph(EdgeTable, NodeTable);  % generate the graph
                        G.Nodes.Properties.VariableUnits = {'pixel', 'string'}; % it is important to indicate "pixel" unit for the PointsXYZ field, when using pixels
                        G.Nodes.Properties.UserData.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;   % required when points are pixels, add pixSize structure
                        G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                        waitbar(0.7, wb, 'Submitting the 3D lines object');
                        obj.mibModel.I{obj.mibModel.Id}.hLines3D.replaceGraph(G);
                    case 'mode2dCurrentRadio'
                        z = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                        STATS = regionprops(Graphcut.slic, 'Centroid');     % x,y
                        waitbar(0.2, wb);
                        % convert Centroids to a matrix
                        points = reshape([STATS.Centroid], [2, numel(STATS)])';
                        points(:,3) = repmat(z, [size(points,1) 1]);    % add z
                        treeNames = repmat({sprintf('SliceNo_%.4d', z)}, [size(points,1) 1]);
                        s = Graphcut.Edges{1}(:,1);
                        t = Graphcut.Edges{1}(:,2);
                        w = Graphcut.EdgesValues{1};
                        waitbar(0.4, wb);
                        
                        NodeTable = table(points, treeNames, 'VariableNames',{'PointsXYZ', 'TreeName'});
                        EdgeTable = table([s, t], w, 'VariableNames', {'EndNodes', 'Weight'});
                        %
                        G = graph(EdgeTable, NodeTable);  % generate the graph
                        G.Nodes.Properties.VariableUnits = {'pixel', 'string'}; % it is important to indicate "pixel" unit for the PointsXYZ field, when using pixels
                        G.Nodes.Properties.UserData.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;   % required when points are pixels, add pixSize structure
                        G.Nodes.Properties.UserData.BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                        waitbar(0.7, wb, 'Submitting the 3D lines object');
                        obj.mibModel.I{obj.mibModel.Id}.hLines3D.replaceGraph(G);
                    otherwise
                        errordlg('This mode is not yet implemented!');
                        delete(wb);
                        return;
                end
                waitbar(1, wb);
                delete(wb);
            end
            
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
                            Graphcut = evalin('base',answer{1});
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
                        Graphcut = res.Graphcut;
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
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', Graphcut(1).bb(1), Graphcut(1).bb(2));
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', Graphcut(1).bb(3), Graphcut(1).bb(4));
                obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', Graphcut(1).bb(5), Graphcut(1).bb(6));
                
                switch Graphcut(1).mode
                    case 'mode2dCurrentRadio'
                        obj.View.handles.mode2dCurrentRadio.Value = 1;
                        obj.mode = 'mode2dCurrentRadio';
                    case 'mode2dRadio'
                        obj.View.handles.mode2dRadio.Value = 1;
                        obj.mode = 'mode2dRadio';
                    case 'mode3dRadio'
                        obj.View.handles.mode3dRadio.Value = 1;
                        obj.mode = 'mode3dRadio';
                    case 'mode3dGridRadio'
                        obj.View.handles.mode3dGridRadio.Value = 1;
                        obj.mode = 'mode3dGridRadio';
                end
                obj.clearPreprocessBtn_Callback(); % do again to initialize obj.graphcut(1).grid
                % move finally Graphcut to obj.graphcut
                obj.graphcut = Graphcut;
                clear Graphcut;
            else
                obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', obj.graphcut(1).bb(1), obj.graphcut(1).bb(2));
                obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', obj.graphcut(1).bb(3), obj.graphcut(1).bb(4));
                obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', obj.graphcut(1).bb(5), obj.graphcut(1).bb(6));
                
                switch obj.graphcut(1).mode
                    case 'mode2dCurrentRadio'
                        obj.View.handles.mode2dCurrentRadio.Value = 1;
                        obj.mode = 'mode2dCurrentRadio';
                    case 'mode2dRadio'
                        obj.View.handles.mode2dRadio.Value = 1;
                        obj.mode = 'mode2dRadio';
                    case 'mode3dRadio'
                        obj.View.handles.mode3dRadio.Value = 1;
                        obj.mode = 'mode3dRadio';
                    case 'mode3dGridRadio'
                        obj.View.handles.mode3dGridRadio.Value = 1;
                        obj.mode = 'mode3dGridRadio';
                end
            end
            
            if ~isfield(obj.graphcut(1), 'version')
                errordlg(sprintf('!!! Error !!!\n\nIncompatible type of the graphcut structure!\nMost likely it is from an older version of the graphcut tool for MIB version 2.12 and older'),'Wrong Graphcut');
                return;
                %obj.graphcut(1).superPixType='SLIC'; 
            end
            if obj.graphcut(1).version < 2.2
                errordlg(sprintf('!!! Error !!!\n\nIncompatible type of the graphcut structure!\nMost likely it is from an older version of the graphcut tool for MIB version 2.12 and older'),'Wrong Graphcut');
                return;
            end
            
            obj.View.handles.binSubareaEdit.String = sprintf('%d;%d', obj.graphcut(1).binVal(1), obj.graphcut(1).binVal(2));
            obj.View.handles.imageColChPopup.Value = obj.graphcut(1).colCh;
                
            if isfield(obj.graphcut(1), 'scaleFactor')
                obj.View.handles.edgeFactorEdit.String = num2str(obj.graphcut(1).scaleFactor); 
            end
            
            if strcmp(obj.graphcut(1).superPixType, 'SLIC')
                obj.View.handles.superpixTypePopup.Value = 1;
                obj.slic_size = obj.graphcut(1).spSize;
            else
                obj.View.handles.superpixTypePopup.Value = 2;
                obj.watershed_size = obj.graphcut(1).spSize;
            end
            
            obj.View.handles.superpixelEdit.String = num2str(obj.graphcut(1).spSize);
            obj.View.handles.superpixelsCompactEdit.String = num2str(obj.graphcut(1).spCompact);
            
            if ~isfield(obj.graphcut(1), 'blackOnWhite'); obj.graphcut(1).blackOnWhite=1; end
            obj.View.handles.signalPopup.Value = obj.graphcut(1).blackOnWhite;
            
            % recalculate the Graph
            if ~isfield(obj.graphcut(1), 'Graph')
                obj.recalcGraph_Callback(1);
            end
            
            % calculate PixelIdxList if needed
            if obj.View.handles.pixelIdxListCheck.Value == 1 && ~isfield(obj.graphcut, 'PixelIdxList')
                obj.pixelIdxListCheck_Callback();
            end
            if isfield(obj.graphcut, 'PixelIdxList')
                obj.View.handles.pixelIdxListCheck.Value = 1;
            end
            if isfield(obj.graphcut, 'tilesX')
                obj.View.handles.chopXedit.String = num2str(obj.graphcut(1).tilesX); 
                obj.View.handles.chopYedit.String = num2str(obj.graphcut(1).tilesY);
                obj.View.handles.chopZedit.String = num2str(obj.graphcut(1).tilesZ);
            else
                obj.View.handles.chopXedit.String = '1'; 
                obj.View.handles.chopYedit.String = '1';
                obj.View.handles.chopZedit.String = '1';
            end
            
            obj.View.handles.superpixelsBtn.BackgroundColor = 'g';
            obj.View.handles.superpixelsCountText.String = sprintf('Superpixels count: %d', sum([obj.graphcut.noPix]));
            obj.superpixTypePopup_Callback('keep');
        end
        
        function superpixelsPreviewBtn_Callback(obj)
            % function superpixelsPreviewBtn_Callback(obj)
            % callback for press of superpixelsPreviewBtn; preview
            % superpixels in MIB
            
            if isempty(obj.graphcut(1).noPix); return; end
            
            wb = waitbar(0, 'Please wait...', 'Name', 'Generating superpixels');
            
            if strcmp(obj.mode, 'mode3dGridRadio')
                [winWidth, winHeight] = obj.mibModel.getAxesLimits(); 
                centX = mean(winWidth);
                centY = mean(winHeight);
                centZ = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber;
                
                bbX = mean(vertcat(obj.graphcut(1).grid.bb.x),2);
                bbY = mean(vertcat(obj.graphcut(1).grid.bb.y),2);
                bbZ = mean(vertcat(obj.graphcut(1).grid.bb.z),2);
                bbCenters = [bbX, bbY, bbZ];
                distances = sqrt((bbCenters(:,1)-centX).^2 + (bbCenters(:,2)-centY).^2 + (bbCenters(:,3)-centZ).^2);
                [~, graphId] = min(distances);

                % get area for processing
                width = obj.graphcut(1).grid.bb(graphId).width; 
                height = obj.graphcut(1).grid.bb(graphId).height;
                depth = obj.graphcut(1).grid.bb(graphId).depth;
                % fill structure to use with getSlice and getDataset methods
                getDataOptions.x = obj.graphcut(1).grid.bb(graphId).x;
                getDataOptions.y = obj.graphcut(1).grid.bb(graphId).y;
                getDataOptions.z = obj.graphcut(1).grid.bb(graphId).z;
            else
                % get area for processing
                width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
                height = str2num(obj.View.handles.ySubareaEdit.String); %#ok<ST2NM>
                depth = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
                % fill structure to use with getSlice and getDataset methods
                getDataOptions.x = [min(width) max(width)];
                getDataOptions.y = [min(height) max(height)];
                getDataOptions.z = [min(depth) max(depth)];
                graphId = 1;
            end
            waitbar(0.05, wb);
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            
            switch obj.mode
                case 'mode2dCurrentRadio'
                    if size(obj.graphcut(1).slic, 3) > 1
                        currSlic = obj.graphcut(graphId).slic(:,:,obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber());
                    else
                        currSlic = obj.graphcut(graphId).slic;
                    end
                    waitbar(0.5, wb);
                    if binVal(1) ~= 1   % re-bin mask
                        L2 = imresize(currSlic, [max(height)-min(height)+1, max(width)-min(width)+1], 'nearest');
                        L2 = imdilate(L2,ones([3,3])) > L2;
                    else
                        L2 = imdilate(currSlic,ones([3,3])) > currSlic;
                    end
                    waitbar(0.9, wb);
                    obj.mibModel.setData2D('selection', L2, NaN, NaN, NaN, getDataOptions);   % set slice
                case 'mode2dRadio'
                    if binVal(1) ~= 1   % re-bin mask
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(depth)-min(depth)+1;
                        resizeOptions.method = 'nearest';
                        L2 = mibResize3d(obj.graphcut(graphId).slic, [], resizeOptions);
                    else
                        L2 = obj.graphcut(graphId).slic;
                    end
                    waitbar(0.5, wb);
                    for i=1:size(L2,3)
                        L2(:,:,i) = imdilate(L2(:,:,i),ones([3,3],class(L2))) > L2(:,:,i);
                    end
                    waitbar(0.9, wb);
                    obj.mibModel.setData3D('selection', uint8(L2), NaN, 4, NaN, getDataOptions);   % set dataset
                case {'mode3dRadio', 'mode3dGridRadio'}
                    % [gx, gy, gz] = gradient(double(graphcut.slic));
                    % L2 = zeros(size(graphcut.slic))+1;
                    % L2((gx.^2+gy.^2+gz.^2)==0) = 0;
                    
                    %L2 = imdilate(graphcut.slic,ones([3,3,3])) > imerode(graphcut.slic,ones([1,1,1]));
                    
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(depth)-min(depth)+1;
                        resizeOptions.method = 'nearest';
                        L2 = mibResize3d(obj.graphcut(graphId).slic, [], resizeOptions);
                    else
                        L2 = obj.graphcut(graphId).slic;
                    end
                    waitbar(0.5, wb);
                    L2 = imdilate(L2,ones([3,3,3])) > L2;
                    waitbar(0.9, wb);
                    obj.mibModel.setData3D('selection', L2, NaN, 4, NaN, getDataOptions);   % set dataset
            end
            waitbar(1, wb);
            notify(obj.mibModel, 'plotImage');
            delete(wb);
        end
        
        function superpixTypePopup_Callback(obj, parameter)
            % function superpixTypePopup_Callback(obj, parameter)
            % callback for change of superpixTypePopup
            
            if nargin < 2; parameter = 'clear'; end     % clear preprocessed data
            
            popupVal = obj.View.handles.superpixTypePopup.Value;
            popupText = obj.View.handles.superpixTypePopup.String;
            obj.View.handles.chopXedit.Enable = 'off';
            obj.View.handles.chopYedit.Enable = 'off';
            obj.View.handles.chopZedit.Enable = 'off';
            obj.View.handles.parforCheck.Enable = 'off';
            obj.View.handles.segmentAllBtn.Enable = 'off';
            if strcmp(popupText{popupVal}, 'SLIC')      % SLIC superpixels
                obj.View.handles.superpixelEdit.String = num2str(obj.slic_size);
                obj.View.handles.compactnessText.Enable = 'on';
                obj.View.handles.superpixelsCompactEdit.Enable = 'on';
                if obj.View.handles.mode3dRadio.Value
                    obj.View.handles.chopXedit.Enable = 'on';
                    obj.View.handles.chopYedit.Enable = 'on';
                    obj.View.handles.chopZedit.Enable = 'off';
                end
                obj.View.handles.superpixelSize.String = sprintf('Size of\nsuperpixels:');
                obj.View.handles.superpixelSize.TooltipString = 'set approximate size of each superpixel (2D) or supervoxel (3D); the smaller size gives better segmentation, but slower';
                obj.View.handles.superpixelEdit.TooltipString = 'set approximate size of each superpixel (2D) or supervoxel (3D); the smaller size gives better segmentation, but slower';
            else                                        % Watershed superpixels
                obj.View.handles.superpixelEdit.String = num2str(obj.watershed_size);
                obj.View.handles.compactnessText.Enable = 'off';
                obj.View.handles.superpixelsCompactEdit.Enable = 'off';
                
                obj.View.handles.superpixelSize.String = sprintf('Reduce number\nof superpixels:');
                obj.View.handles.superpixelSize.TooltipString = 'reduce oversegmentation; the higher number gives bigger superpixels';
                obj.View.handles.superpixelEdit.TooltipString = 'reduce oversegmentation; the higher number gives bigger superpixels';
                
            end
            
            if obj.View.handles.mode3dGridRadio.Value
                obj.View.handles.chopXedit.Enable = 'on';
                obj.View.handles.chopYedit.Enable = 'on';
                obj.View.handles.chopZedit.Enable = 'on';
                obj.View.handles.parforCheck.Enable = 'on';
                obj.View.handles.segmentAllBtn.Enable = 'on';
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
            
            if ~isfield(obj.graphcut(1), 'EdgesValues')
                errordlg(sprintf('!!! Error !!!\n\nThe edges are missing!\nPlease press the Superpixels/Graph button to calculate them'));
                return;
            end
            
            if showWaitbar; wb = waitbar(0, sprintf('Calculating weights for boundaries...\nPlease wait...')); end
            
            for graphId = 1:numel(obj.graphcut)
                obj.graphcut(graphId).scaleFactor = str2double(obj.View.handles.edgeFactorEdit.String);
                if showWaitbar; waitbar((graphId-1)/numel(obj.graphcut)+.1, wb); end

                for i=1:numel(obj.graphcut(graphId).EdgesValues)
                    edgeMax = max(obj.graphcut(graphId).EdgesValues{i});
                    edgeMin = min(obj.graphcut(graphId).EdgesValues{i});
                    edgeVar = edgeMax - edgeMin;
                    normE = obj.graphcut(graphId).EdgesValues{i}/edgeVar;   % scale to 0-1 range
                    EdgesValues = exp(-normE*obj.graphcut(graphId).scaleFactor);  % should be low (--> 0) at the edges of objects

                    if showWaitbar; waitbar((graphId-1)/numel(obj.graphcut)+.5, wb); end

                    Edges2 = fliplr(obj.graphcut(graphId).Edges{i});    % complement for both ways
                    Edges = double([obj.graphcut(graphId).Edges{i}; Edges2]);
                    obj.graphcut(graphId).Graph{i} = sparse(Edges(:,1), Edges(:,2), [EdgesValues EdgesValues]);
                    %if showWaitbar; waitbar(i/numel(obj.graphcut(1).EdgesValues), wb); end
                end

                if showWaitbar; waitbar((graphId-1)/numel(obj.graphcut)+.9, wb); end
            end
            if showWaitbar;     waitbar(1, wb);     delete(wb);  end
        end
        
        function pixelIdxListCheck_Callback(obj)
            % function pixelIdxListCheck_Callback(obj)
            % calculate pixelIdxList for the superpixels
            % this may improve performance of the segmentation process, but
            % requires more memory
            
            if isempty(obj.graphcut(1).noPix); return; end
            
            % clear the structure
            if obj.View.handles.pixelIdxListCheck.Value == 0
                obj.graphcut = rmfield(obj.graphcut, 'PixelIdxList');
                return;
            end
            
            wb = waitbar(0, sprintf('Calculating PixelIdxList\nPlease wait...'));
            if obj.View.handles.mode2dCurrentRadio.Value    % 2d current slice
                STATS = regionprops(obj.graphcut(1).slic, 'PixelIdxList');
                obj.graphcut(1).PixelIdxList = struct2cell(STATS);
            elseif obj.View.handles.mode2dRadio.Value       % 2d slice by slice
                depth = size(obj.graphcut(1).slic,3);
                for sliceId = 1:depth
                    STATS = regionprops(obj.graphcut(1).slic(:,:,sliceId), 'PixelIdxList');
                    obj.graphcut(1).PixelIdxList{sliceId} = struct2cell(STATS);
                    waitbar(sliceId/depth, wb);
                end
            elseif obj.View.handles.mode3dRadio.Value   % 3d
                STATS = regionprops(obj.graphcut(1).slic, 'PixelIdxList');
                waitbar(0.8, wb);
                obj.graphcut(1).PixelIdxList = struct2cell(STATS);
                waitbar(1, wb);
            else    % 3d grid
                for graphId=1:numel(obj.graphcut)
                    STATS = regionprops(obj.graphcut(graphId).slic, 'PixelIdxList');
                    obj.graphcut(graphId).PixelIdxList = struct2cell(STATS);
                end
                waitbar(1, wb);
            end
            delete(wb);
        end
        
        function segmentBtn_Callback(obj)
            % function segmentBtn_Callback(obj)
            % callback for press segmentBtn; start segmentation
            
            tic
            % backup current data
            if ~strcmp(obj.mode, 'mode2dCurrentRadio')
                obj.mibModel.mibDoBackup('mask', 1);
            else
                obj.mibModel.mibDoBackup('mask', 0);
            end
            
            if strcmp(obj.mode, 'mode3dGridRadio')
                obj.shownLabelObj = cell([numel(obj.graphcut(1).grid.bb) 1]);  % indices of currently displayed superpixels for the objects
                obj.seedObj = cell([numel(obj.graphcut(1).grid.bb) 1]);
                obj.seedBg = cell([numel(obj.graphcut(1).grid.bb) 1]);
            elseif strcmp(obj.mode, 'mode2dRadio')
                obj.shownLabelObj = cell([obj.graphcut(1).grid.bb(1).depth 1]);
                obj.seedObj = cell(1);
                obj.seedBg = cell(1);
            else
                obj.shownLabelObj = cell(1);
                obj.seedObj = cell(1);
                obj.seedBg = cell(1);
            end
            
            realtimeSwitchLocal = obj.realtimeSwitch;
            obj.realtimeSwitch = 0;
            obj.doGraphcutSegmentation();
            obj.realtimeSwitch = realtimeSwitchLocal;
            obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
            notify(obj.mibModel, 'showMask');
            obj.timerElapsed = toc;
            fprintf('Elapsed time: %f seconds\n', obj.timerElapsed)
            notify(obj.mibModel, 'plotImage');
        end
        
        function segmentAllBtn_Callback(obj)
            % function segmentAllBtn_Callback(obj)
            % callback for press segmentAllBtn; start segmentation for the
            % complete dataset in the grid mode
            
            tic
            wb = waitbar(0, sprintf('Segmenting dataset\nPlease wait...'));
            % backup current data
            if ~strcmp(obj.mode, 'mode2dCurrentRadio')
                obj.mibModel.mibDoBackup('mask', 1);
            else
                obj.mibModel.mibDoBackup('mask', 0);
            end
            
            obj.shownLabelObj = cell([numel(obj.graphcut(1).grid.bb) 1]);  % indices of currently displayed superpixels for the objects
            obj.seedObj = cell([numel(obj.graphcut(1).grid.bb) 1]);
            obj.seedBg = cell([numel(obj.graphcut(1).grid.bb) 1]);
            
            realtimeSwitchLocal = obj.realtimeSwitch;
            obj.realtimeSwitch = 0;
            for areaId = 1:numel(obj.shownLabelObj)
                posX = round(mean(obj.graphcut(1).grid.bb(areaId).x));
                posY = round(mean(obj.graphcut(1).grid.bb(areaId).y));
                posZ = round(mean(obj.graphcut(1).grid.bb(areaId).z));
                obj.mibModel.I{obj.mibModel.Id}.moveView(posX, posY, 4);
                eventdata = ToggleEventData(posZ);
                notify(obj.mibModel, 'updateLayerSlider', eventdata);
                drawnow;
                obj.doGraphcutSegmentation();
                waitbar(areaId/numel(obj.shownLabelObj), wb);
            end
            obj.realtimeSwitch = realtimeSwitchLocal;
            obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
            notify(obj.mibModel, 'showMask');
            obj.timerElapsed = toc;
            fprintf('Elapsed time: %f seconds\n', obj.timerElapsed)
            notify(obj.mibModel, 'plotImage');
            waitbar(1, wb);
            delete(wb);
        end
        
        
    end
end

