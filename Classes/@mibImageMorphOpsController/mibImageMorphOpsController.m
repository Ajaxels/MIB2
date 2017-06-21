classdef mibImageMorphOpsController < handle
    % @type mibImageMorphOpsController class is resposnible for showing the Morphological operations for images 
    % window, available from MIB->Menu->Image->MorphOps 
    
	% Copyright (C) 06.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        % morphops mode: mode2d_Slice, mode2d_Stack, mode2d_Dataset, mode3d_Stack, mode3d_Dataset
        conn
        % connectivity value
        action
        % additional action for the result of the filter: 'noneRadio', 'addRadio', 'subtractRadio'
        operationName
        % name of the morphop to perform
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
                case 'changeSlice'
                    if obj.View.handles.autoPreviewCheck.Value == 1
                        obj.previewBtn_Callback();
                    end
            end
        end
    end
    
    methods
        function obj = mibImageMorphOpsController(mibModel, parameter)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibImageMorphOpsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            % define the current mode
            obj.mode = 'mode2d_Slice'; % other modes mode2d_Stack, mode2d_Dataset, mode3d_Stack, mode3d_Dataset
            obj.conn = 4;
            obj.action = 'noneRadio';
            
            % highlight desired operation in the list
            list = obj.View.handles.morphOpsPopup.String;
            for i=1:numel(list)
                if strcmp(list{i}, parameter)
                    obj.View.handles.morphOpsPopup.Value = i;
                    continue;
                end
            end
            
            obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'changeSlice', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibImageMorphOpsController window
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
            
            % update the Mode panel
            if obj.mibModel.getImageProperty('depth') < 2
                obj.View.handles.radio26.Visible = 'off';
                obj.View.handles.datasetPopup.Value = 1;
                obj.View.handles.modePopup.Value = 1;
                obj.View.handles.modePopup.String = '2D';
            else
                obj.View.handles.radio26.Enable = 'on';
            end
            
            % updating color channels
            colorsNo = obj.mibModel.getImageProperty('colors');
            colCh = cell([colorsNo, 1]);
            for i=1:colorsNo
                colCh{i} = sprintf('Ch %d', i);
            end
            if colorsNo < obj.View.handles.colorChannelPopoup.Value
                obj.View.handles.colorChannelPopoup.Value = 1;
            end;
            obj.View.handles.colorChannelPopoup.String = colCh;
            obj.morphOpsPopup_Callback();
        end
        
        function morphOpsPopup_Callback(obj)
            % function morphOpsPopup_Callback(obj)
            % callback for change of obj.View.handles.morphOpsPopup
            
            global mibPath;
            list = obj.View.handles.morphOpsPopup.String;
            currOperationName = list{obj.View.handles.morphOpsPopup.Value};
            obj.View.handles.strelShapePopup.Enable = 'on';
            obj.View.handles.strelSizeEdit.Enable = 'on';
            obj.View.handles.radio6.Enable = 'off';
            obj.View.handles.radio18.Enable = 'off';
            obj.View.handles.radio26.Enable = 'off';
            obj.View.handles.modePopup.Value = 1;
            obj.View.handles.modePopup.Enable = 'off';
            
            switch currOperationName
                case 'Bottom-hat filtering'
                    infoText = 'Computes the morphological closing of the image (using imclose`) and then subtracts the result from the original image';
                    obj.operationName = 'imbothat';
                    obj.View.handles.strelShapePopup.Enable = 'on';
                    obj.View.handles.strelSizeEdit.Enable = 'on';
                case 'Clear border'
                    infoText = 'Suppresses light structures connected to image border';
                    obj.operationName = 'imclearborder';
                    obj.View.handles.radio6.Enable = 'on';
                    obj.View.handles.radio18.Enable = 'on';
                    obj.View.handles.radio26.Enable = 'on';
                    obj.View.handles.strelShapePopup.Enable = 'off';
                    obj.View.handles.strelSizeEdit.Enable = 'off';
                    obj.View.handles.modePopup.Enable = 'on';
                case 'Morphological closing'
                    infoText = 'Morphologically close image: a dilation followed by an erosion';
                    handles.operationName = 'imclose';
                case 'Dilate image'
                    infoText = 'Dilate image';
                    obj.operationName = 'imdilate';
                case 'Erode image'
                    infoText = 'Erode image';
                    obj.operationName = 'imerode';
                case 'Fill regions'
                    infoText = 'Fills holes in the image, where a hole is defined as an area of dark pixels surrounded by lighter pixels';
                    obj.operationName = 'imfill';
                    obj.View.handles.modePopup.Value = 1;
                    obj.View.handles.strelShapePopup.Enable = 'off';
                    obj.View.handles.strelSizeEdit.Enable = 'off';
                case 'H-maxima transform'
                    infoText = 'Suppresses all maxima in the image whose height is less than H';
                    obj.operationName = 'imhmax';
                    obj.View.handles.radio6.Enable = 'on';
                    obj.View.handles.radio18.Enable = 'on';
                    obj.View.handles.radio26.Enable = 'on';
                    obj.View.handles.modePopup.Enable = 'on';
                case 'H-minima transform'
                    infoText = 'Suppresses all minima in the image whose depth is less than H';
                    obj.operationName = 'imhmin';
                    obj.View.handles.radio6.Enable = 'on';
                    obj.View.handles.radio18.Enable = 'on';
                    obj.View.handles.radio26.Enable = 'on';
                    obj.View.handles.modePopup.Enable = 'on';
                case 'Morphological opening'
                    infoText = 'Morphologically open image: an erosion followed by a dilation';
                    obj.operationName = 'imopen';
                case 'Top-hat filtering'
                    infoText = 'Computes the morphological opening of the image (using imopen) and then subtracts the result from the original image';
                    obj.operationName = 'imtophat';
            end
            obj.View.handles.infoText.String = infoText;
            
            % load preview image
            img = imread(fullfile(mibPath, 'Resources', [obj.operationName '.jpg']));
            image(img, 'parent', obj.View.handles.previewAxes);
            obj.View.handles.previewAxes.Box = 'off';
            obj.View.handles.previewAxes.XTick = [];
            obj.View.handles.previewAxes.YTick = [];
            
            % use auto preview
            if obj.View.handles.autoPreviewCheck.Value == 1
                obj.previewBtn_Callback();
            end
        end
        
        function modePanel_Callback(obj)
            % function modePanel_Callback(obj)
            % callback for change of obj.View.handles.modePanel
            
            datasetPopupString = obj.View.handles.datasetPopup.String;
            datasetPopup = datasetPopupString{obj.View.handles.datasetPopup.Value};
            
            switch datasetPopup
                case '2D, Slice'
                    obj.mode = '_Slice';
                    obj.View.handles.modePopup.Value = 1;
                case '3D, Stack'
                    obj.mode = '_Stack';
                case '4D, Dataset'
                    obj.mode = '_Dataset';
            end
            
            modePopupString = obj.View.handles.modePopup.String;
            if iscell(modePopupString)
                modePopup = modePopupString{obj.View.handles.modePopup.Value};
            else
                modePopup = modePopupString;
            end
            
            if strcmp(modePopup, '2D')
                obj.View.handles.radio6.String = '4';
                obj.View.handles.radio18.String = '8';
                obj.View.handles.radio26.Visible = 'off';
                obj.View.handles.previewBtn.Enable = 'on';
                obj.View.handles.smoothWidth.Enable = 'on';
                obj.View.handles.smoothSigma.Enable = 'on';
                obj.View.handles.autoPreviewCheck.Enable = 'on';
                obj.mode = ['mode2d' obj.mode];
            else
                obj.View.handles.radio6.String = '6';
                obj.View.handles.radio18.String = '18';
                obj.View.handles.radio26.Visible = 'on';
                obj.View.handles.previewBtn.Enable = 'off';
                obj.View.handles.smoothWidth.Enable = 'off';
                obj.View.handles.smoothSigma.Enable = 'off';
                obj.View.handles.autoPreviewCheck.Value = 0;
                obj.View.handles.autoPreviewCheck.Enable = 'off';
                obj.mode = ['mode3d' obj.mode];
            end
            
            % use auto preview
            if obj.View.handles.autoPreviewCheck.Value == 1
                obj.previewBtn_Callback();
            end
        end
        
        function connectivityPanel_Callback(obj, eventdata)
            % function connectivityPanel_Callback(obj, eventdata)
            % callback for change of obj.View.handles.connectivityPanel
            
            value = eventdata.NewValue.String;
            obj.conn = str2double(value);

            % use auto preview
            if obj.View.handles.autoPreviewCheck.Value == 1
                obj.previewBtn_Callback();
            end
        end
        
        function actionPanel_Callback(obj, eventdata)
            % function actionPanel_Callback(obj, eventdata)
            % callback for change of obj.View.handles.actionPanel
            
            obj.action = eventdata.NewValue.Tag;
            % use auto preview
            if obj.View.handles.autoPreviewCheck.Value == 1
                obj.previewBtn_Callback();
            end
        end
       
        function previewBtn_Callback(obj)
            % function previewBtn_Callback(obj)
            % callback for press of obj.View.handles.previewBtn

            colChannel = obj.View.handles.colorChannelPopoup.Value;
            se = obj.getStrelElement();
            hValue = str2num(obj.View.handles.strelSizeEdit.String); %#ok<ST2NM>
            multiplyFactor = str2double(obj.View.handles.multiplyEdit.String);
            smoothWidth = str2double(obj.View.handles.smoothWidth.String);
            smoothSigma = str2double(obj.View.handles.smoothSigma.String);
            
            getDataOptions.blockModeSwitch = 1;
            img = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, colChannel, getDataOptions));
            switch obj.operationName
                case 'imbothat'
                    Iout = imbothat(img, se);
                case 'imclearborder'
                    Iout = imclearborder(img, obj.conn);
                case 'imclose'
                    Iout = imclose(img, se);
                case 'imdilate'
                    Iout = imdilate(img, se);
                case 'imerode'
                    Iout = imerode(img, se);
                case 'imfill'
                    Iout = imfill(img);
                case 'imhmax'
                    Iout = imhmax(img, hValue(1), obj.conn);
                case 'imhmin'
                    Iout = imhmin(img, hValue(1), obj.conn);
                case 'imopen'
                    Iout = imopen(img, se);
                case 'imtophat'
                    Iout = imtophat(img, se);
            end
            
            if smoothWidth > 0  % do gaussian filtering
                filter2d = fspecial('gaussian', smoothWidth, smoothSigma);
                Iout = imfilter(Iout, filter2d, 'replicate');
            end
            
            switch obj.action
                case 'noneRadio'
                    img = Iout*multiplyFactor;
                case 'addRadio'
                    img = img + Iout*multiplyFactor;
                case 'subtractRadio'
                    img = img - Iout*multiplyFactor;
            end
            
            eventdata = ToggleEventData(img);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
            notify(obj.mibModel, 'plotImage', eventdata);
        end
        
        function se = getStrelElement(obj)
            % function se = getStrelElement(obj)
            % get strel element for the morph ops functions
            strelShape = obj.View.handles.strelShapePopup.Value;     % 1-rectangle; 2-disk
            se_size = str2num(obj.View.handles.strelSizeEdit.String); %#ok<ST2NM>
            
            % when only 1 value - calculate the second from the pixSize
            if ~isempty(strfind(obj.mode, 'mode3d_'))
                if numel(se_size) == 1
                    se_size(2) = max([round(se_size(1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.z) 1]); % for z
                end
            elseif numel(se_size) == 1
                se_size(2) = se_size(1);
            end
            
            if strelShape == 1  % rectangle
                if ~isempty(strfind(obj.mode, 'mode3d_'))
                    se = ones([se_size(1), se_size(1), se_size(2)]);
                else
                    se = strel('rectangle', [se_size(1), se_size(2)]);
                end
            else                % disk
                if ~isempty(strfind(obj.mode, 'mode3d_'))
                    se = zeros(se_size(1)*2+1,se_size(1)*2+1,se_size(2)*2+1);    % do strel ball type in volume
                    [x,y,z] = meshgrid(-se_size(1):se_size(1),-se_size(1):se_size(1),-se_size(2):se_size(2));
                    ball = sqrt((x/se_size(1)).^2+(y/se_size(1)).^2+(z/se_size(2)).^2);
                    se(ball<=1) = 1;
                else
                    se = strel('disk', se_size(1), 0);
                end
            end
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % callback for press of obj.View.handles.continueBtn
            % perform the selected morph ops
            
            wb = waitbar(0, 'Please wait...', 'Name', [obj.operationName ' filter']);
            colChannel = obj.View.handles.colorChannelPopoup.Value;
            se = obj.getStrelElement();
            hValue = str2num(obj.View.handles.strelSizeEdit.String); %#ok<ST2NM>
            multiplyFactor = str2double(obj.View.handles.multiplyEdit.String);
            smoothWidth = str2double(obj.View.handles.smoothWidth.String);
            smoothSigma = str2double(obj.View.handles.smoothSigma.String);
            
            % backup current data
            if strcmp(obj.mode, 'mode2d_Slice')
                obj.mibModel.mibDoBackup('image', 0);
            elseif isempty(strfind(obj.mode, '_Dataset')) || obj.mibModel.getImageProperty('time') == 1
                obj.mibModel.mibDoBackup('image', 1);
            end
            
            if ~isempty(strfind(obj.mode, '_Slice'))
                t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                t2 = t1;
                maxIndex = 1;
            elseif ~isempty(strfind(obj.mode, '_Stack'))
                t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                t2 = t1;
                maxIndex = obj.mibModel.I{obj.mibModel.Id}.depth;
            elseif ~isempty(strfind(obj.mode, '_Dataset'))
                t1 = 1;
                t2 = obj.mibModel.I{obj.mibModel.Id}.time;
                maxIndex = obj.mibModel.I{obj.mibModel.Id}.depth * obj.mibModel.I{obj.mibModel.Id}.time;
            end
            
            index = 0;
            for t=t1:t2
                getDataOptions.t = [t t];
                if ~isempty(strfind(obj.mode,'mode3d'))
                    img = obj.mibModel.getData3D('image', t, 4, colChannel, getDataOptions);
                    
                    Iout = cell([numel(img),1]);
                    for roiId=1:numel(img)
                        switch obj.operationName
                            case 'imbothat'
                                Iout{roiId} = imbothat(img{roiId}, se);
                            case 'imclearborder'
                                Iout{roiId} = imclearborder(img{roiId}, obj.conn);
                            case 'imclose'
                                Iout{roiId} = imclose(img{roiId}, se);
                            case 'imdilate'
                                Iout{roiId} = imdilate(img{roiId}, se);
                            case 'imerode'
                                Iout{roiId} = imerode(img{roiId}, se);
                            case 'imfill'
                                Iout{roiId} = imfill(img{roiId});
                            case 'imhmax'
                                Iout{roiId} = imhmax(img{roiId}, hValue(1), obj.conn);
                            case 'imhmin'
                                Iout{roiId} = imhmin(img{roiId}, hValue(1), obj.conn);
                            case 'imopen'
                                Iout{roiId} = imopen(img{roiId}, se);
                            case 'imtophat'
                                Iout{roiId} = imtophat(img{roiId}, se);
                        end
                        switch obj.action
                            case 'noneRadio'
                                img{roiId} = Iout{roiId}*multiplyFactor;
                            case 'addRadio'
                                img{roiId} = img{roiId} + Iout{roiId}*multiplyFactor;
                            case 'subtractRadio'
                                img{roiId} = img{roiId} - Iout{roiId}*multiplyFactor;
                        end
                    end
                    waitbar(index/maxIndex,wb);
                    index = index + obj.mibModel.I{obj.mibModel.Id}.depth;
                    obj.mibModel.setData3D('image', img, t, 4, colChannel, getDataOptions);
                else
                    startSlice = 1;
                    endSlice = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
                    if strcmp(obj.mode,'mode2d_Slice')
                        startSlice = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                        endSlice = startSlice;
                    end
                    
                    if smoothWidth > 0  % do gaussian filtering
                        filter2d = fspecial('gaussian', smoothWidth, smoothSigma);
                    end
                    noSlices = endSlice-startSlice+1;
                    for sliceId = startSlice:endSlice
                        img = obj.mibModel.getData2D('image', sliceId, NaN, colChannel, getDataOptions);
                        Iout = cell([numel(img),1]);
                        for roiId=1:numel(img)
                            switch obj.operationName
                                case 'imbothat'
                                    Iout{roiId} = imbothat(img{roiId}, se);
                                case 'imclearborder'
                                    Iout{roiId} = imclearborder(img{roiId}, obj.conn);
                                case 'imclose'
                                    Iout{roiId} = imclose(img{roiId}, se);
                                case 'imdilate'
                                    Iout{roiId} = imdilate(img{roiId}, se);
                                case 'imerode'
                                    Iout{roiId} = imerode(img{roiId}, se);
                                case 'imfill'
                                    Iout{roiId} = imfill(img{roiId});
                                case 'imhmax'
                                    Iout{roiId} = imhmax(img{roiId}, hValue(1), obj.conn);
                                case 'imhmin'
                                    Iout{roiId} = imhmin(img{roiId}, hValue(1), obj.conn);
                                case 'imopen'
                                    Iout{roiId} = imopen(img{roiId}, se);
                                case 'imtophat'
                                    Iout{roiId} = imtophat(img{roiId}, se);
                            end
                            
                            if smoothWidth > 0  % do gaussian filtering
                                Iout{roiId} = imfilter(Iout{roiId}, filter2d, 'replicate');
                            end
                            
                            switch obj.action
                                case 'noneRadio'
                                    img{roiId} = Iout{roiId}*multiplyFactor;
                                case 'addRadio'
                                    img{roiId} = img{roiId} + Iout{roiId}*multiplyFactor;
                                case 'subtractRadio'
                                    img{roiId} = img{roiId} - Iout{roiId}*multiplyFactor;
                            end
                        end
                        obj.mibModel.setData2D('image', img, sliceId, NaN, colChannel, getDataOptions);
                        waitbar(index/maxIndex,wb);
                        index = index + 1;
                    end
                end
            end
            
            strelShape = obj.View.handles.strelShapePopup.String;
            strelShape = strelShape{obj.View.handles.strelShapePopup.Value};
            se_size = obj.View.handles.strelSizeEdit.String; 
            
            % update log
            if ~isempty(strfind(obj.mode, 'mode2d_Slice'))
                modeTxt = sprintf('mode2d_Slice,Z=%d,T=%d', startSlice, t1);
            elseif ~isempty(strfind(obj.mode, '_Stack'))
                modeTxt = sprintf('%s,T=%d', obj.mode, t1);
            else
                modeTxt = obj.mode;
            end
            
            log_text = ['imageMorphOps: Operation=' obj.operationName ',Mode=' modeTxt ',ColCh=', num2str(colChannel) ...
                ',Strel=' strelShape '/' se_size ',Conn=' num2str(obj.conn) ',Multiply=' num2str(multiplyFactor) ...
                ',Smoothing=' num2str(smoothWidth) '/' num2str(smoothSigma) ',action=' obj.action ...
                ',orient=' num2str(obj.mibModel.I{obj.mibModel.Id}.orientation)];
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            waitbar(1,wb);
            notify(obj.mibModel, 'plotImage');
            delete(wb);
        end
    end
end