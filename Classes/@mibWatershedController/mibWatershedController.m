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
	% 06.11.2017, taken to a separate function    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        preprocImg
        % a variable with the preprocessed image
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
        function obj = mibWatershedController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibWatershedGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'watershed segmentation is';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end
            
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
            
%             if obj.mibModel.getImageProperty('blockModeSwitch')
%                 warndlg(sprintf('Please switch off the Block-mode!\n\nUse the corresponding button in the toolbar'), 'Block-mode is detected');
%                 obj.View.handles.watershedBtn.Enable = 'off';
%             else
%                 obj.View.handles.watershedBtn.Enable = 'on';
%             end
            
            % populate aspect ratio edit box
            pixSize = obj.mibModel.getImageProperty('pixSize');
            minVal = min([pixSize.x pixSize.y pixSize.z]);
            aspect(1) = pixSize.x/minVal;
            aspect(2) = pixSize.y/minVal;
            aspect(3) = pixSize.z/minVal;
            obj.View.handles.aspectRatio.String = sprintf('%.2f %.2f %.2f', aspect(1), aspect(2), aspect(3));
            
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
            end
            obj.View.handles.imageColChPopup.String = colCh;
            
            % populating lists of materials
            obj.updateMaterialsBtn_Callback();
            
            % populate subarea edit boxes
            getDataOptions.blockModeSwitch = 0;
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4, NaN, getDataOptions);
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
                obj.View.handles.backgroundMateriaPopup.Value = 1;
                obj.View.handles.backgroundMateriaPopup.String = 'Please create a model with 2 materials: background and object and restart the watershed tool';
                obj.View.handles.backgroundMateriaPopup.BackgroundColor = 'r';
                obj.View.handles.signalMateriaPopup.Value = 1;
                obj.View.handles.signalMateriaPopup.String = 'Please create a model with 2 materials: background and object and restart the watershed tool';
                obj.View.handles.signalMateriaPopup.BackgroundColor = 'r';
                
            else
                obj.View.handles.backgroundMateriaPopup.Value = 1;
                obj.View.handles.backgroundMateriaPopup.String = list;
                obj.View.handles.backgroundMateriaPopup.BackgroundColor = 'w';
                obj.View.handles.signalMateriaPopup.Value = numel(list);
                obj.View.handles.signalMateriaPopup.String = list;
                obj.View.handles.signalMateriaPopup.BackgroundColor = 'w';
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
        
        function status = clearPreprocessBtn_Callback(obj)
            % function clearPreprocessBtn_Callback(obj)
            % callback for press of clearPreprocessBtn; clear the preprocessed data
            status = 0;
            
            if ~isnan(obj.preprocImg(1))
                button =  questdlg(sprintf('!!! Attention !!!\n\nThe pre-processed data will be removed!'),...
                    'Warning!', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button,'Cancel'); return; end
            end
            
            obj.preprocImg = NaN;
            
            bgcol = obj.View.handles.clearPreprocessBtn.BackgroundColor;
            obj.View.handles.preprocessBtn.BackgroundColor = bgcol;
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
            
            if ~isnan(obj.preprocImg(1))
                button =  questdlg(sprintf('!!! Attention !!!\n\nThe pre-processed data will be removed!'),...
                    'Warning!', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button,'Cancel')
                    obj.View.handles.(obj.mode).Value = 1;
                    return;
                end
                obj.preprocImg = NaN;
                obj.clearPreprocessBtn_Callback();    % clear preprocessed data
            end
            obj.mode = hObject.Tag;
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
            
            getDataOptions.blockModeSwitch = 0;
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4, NaN, getDataOptions);
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
            
            getDataOptions.blockModeSwitch = 0;
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', 4, NaN, getDataOptions);
            
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
            getDataOptions.blockModeSwitch = 0;
            bgColor = obj.View.handles.subAreaFromSelectionBtn.BackgroundColor;
            obj.View.handles.subAreaFromSelectionBtn.BackgroundColor = 'r';
            drawnow;
            if strcmp(obj.mode, 'mode2dCurrentRadio')
                img = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, getDataOptions));
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
                img = cell2mat(obj.mibModel.getData3D('selection', NaN, 4, NaN, getDataOptions));
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
            binDepth = ceil((max(depth)-min(depth)+1)/binVal(2));
            
            wb = waitbar(0, 'Please wait...', 'Name', 'Pre-processing...');
            
            hy = fspecial('sobel'); % for gradient filter
            hx = hy';               % for gradient filter
            switch obj.mode
                case 'mode2dRadio'
                    img = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, NaN, col_channel, getDataOptions)));   % get dataset
                    if binVal(1) ~= 1   % bin data
                        resizeOptions.height = binHeight;
                        resizeOptions.width = binWidth;
                        resizeOptions.depth = max(depth)-min(depth)+1;
                        resizeOptions.method = 'bicubic';
                        img = mibResize3d(img, [], resizeOptions);
                        %img = resizeVolume(img, [binHeight, binWidth, max(depth)-min(depth)+1], 'bicubic');
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
                        resizeOptions.depth = binDepth;
                        resizeOptions.method = 'bicubic';
                        img = mibResize3d(img, [], resizeOptions);
                        %img = resizeVolume(img, [binHeight, binWidth, binDepth], 'bicubic');
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
                    sliceId = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber() - min(depth) + 1;
                    if sliceId < 1; sliceId = 1; end;
                    if sliceId > size(obj.preprocImg, 3); sliceId = size(obj.preprocImg, 3); end;
                    eventdata = ToggleEventData(obj.preprocImg(:, :, sliceId));   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
                end
            end
            
            if obj.View.handles.exportPreprocessCheck.Value
                assignin('base', 'preprocImg', obj.preprocImg);
                text1 = sprintf('MIB-Watershed: a variable "preprocImg" [%d x %d x %d] with the preprocessed data has been created!\n', ...
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
            % backup current data
            if ~strcmp(obj.mode, 'mode2dCurrentRadio')
                obj.mibModel.mibDoBackup('mask', 1);
            else
                obj.mibModel.mibDoBackup('mask', 0);
            end
            
            % select and start watershed
            obj.doImageSegmentation();
            obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
            notify(obj.mibModel, 'showMask');
            
            obj.timerElapsed = toc;
            fprintf('Elapsed time: %f seconds\n', obj.timerElapsed)
            notify(obj.mibModel, 'plotImage');
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
            depth = str2num(obj.View.handles.zSubareaEdit.String);  %#ok<ST2NM>
            % fill structure to use with getSlice and getDataset methods
            getDataOptions.x = [min(width) max(width)];
            getDataOptions.y = [min(height) max(height)];
            getDataOptions.z = [min(depth) max(depth)];
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binDepth = ceil((max(depth)-min(depth)+1)/binVal(2));
            
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
                    end   % convert to 8bit if neeeded
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
                            resizeOptions.depth = binDepth;
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
                        resizeOptions.depth = binDepth;
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
                        resizeOptions.depth = max(depth)-min(depth)+1;
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
        
        function importBtn_Callback(obj)
            % function importBtn_Callback(obj)
            % callback for press of importBtn - import the graphcut
            % structure
            
            global mibPath;
            
            %options.Resize='on';
            %answer = inputdlg({'Enter variable containing preprocessed image (h:w:color:index):'},'Import image',1,{'I'},options);
            answer = mibInputDlg({mibPath}, 'Enter variable containing preprocessed image (h:w:color:z):', 'Import image', 'I');
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
            depth = str2num(obj.View.handles.zSubareaEdit.String); %#ok<ST2NM>
            
            % calculate image size after binning
            binVal = str2num(obj.View.handles.binSubareaEdit.String);     %#ok<ST2NM> % vector to bin the data binVal(1) for XY and binVal(2) for Z
            binWidth = ceil((max(width)-min(width)+1)/binVal(1));
            binHeight = ceil((max(height)-min(height)+1)/binVal(1));
            binDepth = ceil((max(depth)-min(depth)+1)/binVal(2));
            
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
                binDepth = 1;
                depth = 1;
            end
            
            % check dimensions
            if size(img,1) ~= binHeight || size(img,2) ~= binWidth || size(img,3) ~= binDepth
                try
                    img = img(height(1):height(end), width(1):width(end), depth(1):depth(end));
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
                            resizeOptions.depth = max(depth)-min(depth)+1;
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
                            resizeOptions.depth = binDepth;
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
    end
end

