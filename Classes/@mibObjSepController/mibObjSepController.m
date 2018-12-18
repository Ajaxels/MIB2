classdef mibObjSepController  < handle
    % @type mibObjSepController class is resposnible for showing the object separation window,
    % available from MIB->Menu->Tools->Object separation
    
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
        mode
        % a mode to use: 'mode2dCurrentRadio'
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
            end
        end
    end
    
    methods
        function obj = mibObjSepController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibObjSepGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'object separation is';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.watSourceTxt2.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.watSourceTxt2.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
          
            obj.timerElapsedMax = .5;   % if segmentation is slower than this time, show the waitbar
            obj.timerElapsed = 9999999; % initialize the timer
            
            % selected default mode
            obj.mode = 'mode2dCurrentRadio';
            
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
            end
        
        function closeWindow(obj)
            % closing mibObjSepController  window
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
                obj.View.handles.separateBtn.Enable = 'off';
            else
                obj.View.handles.separateBtn.Enable = 'on';
            end
            
            % populate aspect ratio edit box
            pixSize = obj.mibModel.getImageProperty('pixSize');
            minVal = min([pixSize.x pixSize.y pixSize.z]);
            aspect(1) = pixSize.x/minVal;
            aspect(2) = pixSize.y/minVal;
            aspect(3) = pixSize.z/minVal;
            obj.View.handles.aspectRatio.String = sprintf('%.2f %.2f %.2f', aspect(1), aspect(2), aspect(3));
            obj.View.handles.(obj.mode).Value = 1;
            
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
            if colorsNo < obj.View.handles.imageIntensityColorCh.Value
                obj.View.handles.imageIntensityColorCh.Value = 1;
            end
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
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', 1, width);
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', 1, height);
            obj.View.handles.zSubareaEdit.String = sprintf('%d:%d', 1, depth);
            
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
                
            else
                selectedMaterial = obj.mibModel.getImageProperty('selectedMaterial') - 2;
                obj.View.handles.selectedMaterialPopup.String = list;
                obj.View.handles.selectedMaterialPopup.Value = max([selectedMaterial 1]);
                obj.View.handles.seedsSelectedMaterialPopup.String = list;
                obj.View.handles.seedsSelectedMaterialPopup.Value = max([selectedMaterial 1]);
                obj.View.handles.modelRadio.Enable = 'on';
                obj.View.handles.selectedMaterialPopup.Enable = 'on';
                obj.View.handles.seedsModelRadio.Enable = 'on';
                obj.View.handles.seedsSelectedMaterialPopup.Enable = 'on';
            end
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
            
            obj.mode = hObject.Tag;
            hObject.Value = 1;
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
        end
        
        function resetDimsBtn_Callback(obj)
            % function resetDimsBtn_Callback(obj)
            % callback for resetDimsBtn - reset edit boxes with dataset dimensions
            
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4);
            obj.View.handles.xSubareaEdit.String = sprintf('1:%d', width);
            obj.View.handles.ySubareaEdit.String = sprintf('1:%d', height);
            obj.View.handles.zSubareaEdit.String = sprintf('1:%d', depth);
            obj.View.handles.binSubareaEdit.String = '1; 1';
        end
        
        function currentViewBtn_Callback(obj)
            % function currentViewBtn_Callback(obj)
            % callback for press of currentViewBtn; defines dataset from
            % the current view
            [yMin, yMax, xMin, xMax] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage();
            obj.View.handles.xSubareaEdit.String = sprintf('%d:%d', xMin, xMax);
            obj.View.handles.ySubareaEdit.String = sprintf('%d:%d', yMin, yMax);
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
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = bgColor;
        end
        
        function doObjectSeparation(obj)
            % function doObjectSeparation(obj)
            % start object separation using watershed
            tic
            wb = waitbar(0, sprintf('Object separation\nPlease wait...'), 'Name', 'Object separation...');
            aspect = str2num(obj.View.handles.aspectRatio.String); %#ok<ST2NM>
            col_channel = obj.View.handles.imageIntensityColorCh.Value;
            invertImage = obj.View.handles.imageIntensityInvert.Value;    % if == 1 image should be inverted, black-on-white
            
            % backup current data
            if ~strcmp(obj.mode, 'mode2dCurrentRadio')
                obj.mibModel.mibDoBackup('selection', 1);
            else
                obj.mibModel.mibDoBackup('selection', 0);
            end
            
            % get area for processing
            width = str2num(obj.View.handles.xSubareaEdit.String); %#ok<ST2NM>
            height = str2num(obj.View.handles.ySubareaEdit.String);  %#ok<ST2NM>
            depth = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = [min(width) max(width)];
            getDataOptions.y = [min(height) max(height)];
            getDataOptions.z = [min(depth) max(depth)];
            if strcmp(obj.mode, 'mode2dCurrentRadio')   % limit z for the current slice only mode
                currentSliceIndex = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                getDataOptions.z = [currentSliceIndex currentSliceIndex];
            end
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binDepth = ceil((max(depth)-min(depth)+1)/binVal(2));
            
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
                        resizeOptions.depth = binDepth;
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
                        if aspect(1)/aspect(3) > 0.65 && aspect(1)/aspect(3) <= 1.5
                            W = bwdist(~img);
                        else
                            W = bwdistsc(~img, aspect);
                        end
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
                    objInd(objInd==0) = [];     % remove 0 index
                    W = uint8(ismember(W,objInd));
                   
                    % % this is alternative option, because the other one
                    % % did not work at some situations, need to reproduce it
                    % % again for a fix
                    % img(W==0) = 0;
                    % W = img;
                    %obj.mibModel.setData3D('selection', W, NaN, 4, NaN, getDataOptions);   % set dataset
                    
                    
                    if binVal(1) ~= 1 || binVal(2) ~= 1
                        %waitbar(.95, wb, sprintf('Re-binning the mask\nPlease wait...'));
                        resizeOptions.height = max(height)-min(height)+1;
                        resizeOptions.width = max(width)-min(width)+1;
                        resizeOptions.depth = max(depth)-min(depth)+1;
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
                        resizeOptions.depth = binDepth;
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
                        resizeOptions.depth = max(depth)-min(depth)+1;
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
            
            obj.timerElapsed = toc;
            fprintf('Elapsed time: %f seconds\n', obj.timerElapsed)
            notify(obj.mibModel, 'plotImage');
        end
        
    end
end

