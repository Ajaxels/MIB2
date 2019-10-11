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
	% 29.05.2019 updated for the batch mode
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        BatchOpt
        % a structure compatible with batch operation, see details in the contsructor
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
        function obj = mibImageMorphOpsController(mibModel, parameter, varargin)
            obj.mibModel = mibModel;    % assign model
            if nargin < 2; parameter = []; end
            if isempty(parameter); parameter = 'Bottom-hat filtering'; end
            
            obj.BatchOpt.MorphOperation = {parameter};   % morphological operation to perform
            obj.BatchOpt.MorphOperation{2} = {'Bottom-hat filtering', 'Clear border', 'Morphological closing', 'Dilate image', ...
                        'Erode image', 'Fill regions', 'H-maxima transform', 'H-minima transform', 'Morphological opening', 'Top-hat filtering'};
            obj.BatchOpt.DatasetType = {'2D, Slice'};   % perform opertion on dataset
            obj.BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
            obj.BatchOpt.Mode = {'2D'};         % operation mode: in 2D or 3D
            obj.BatchOpt.Mode{2} = {'2D', '3D'};
            PossibleColChannels = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{obj.mibModel.Id}.colors, 'UniformOutput', false);
            obj.BatchOpt.ColorChannel = {'All'};         % specify the color channel
            obj.BatchOpt.ColorChannel{2} = [{'All'}, PossibleColChannels];
            obj.BatchOpt.ActionToResult = {'None'};         % radio buttons for additional actions applied to the result
            obj.BatchOpt.ActionToResult{2} = {'None', 'AddToImage','SubtractFromImage'};
            obj.BatchOpt.StrelShape = {'rectangle'};         % shape of the strel element
            obj.BatchOpt.StrelShape{2} = {'rectangle', 'disk'};
            obj.BatchOpt.StrelSize = '7';   % size of the strel element
            obj.BatchOpt.Connectivity = {'Connectivity6'};         % connectivity parameter
            obj.BatchOpt.Connectivity{2} = {'Connectivity6', 'Connectivity18', 'Connectivity26'};
            obj.BatchOpt.Multiply = '1';    % multiplication value for the result
            obj.BatchOpt.SmoothHSize = '0';  % width of optional smoothing 
            obj.BatchOpt.SmoothSigma = '0';  % sigme of optional smoothing
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            obj.BatchOpt.id = obj.mibModel.Id;
            
            % add section name and action name for the batch tool
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Image';
            obj.BatchOpt.mibBatchActionName = 'Morphological operations';
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.DatasetType = sprintf('Specify whether to apply MorphOps to a shown slice (2D, Slice), the whole stack (3D, Stack) or complete dataset (4D, Dataset)');
            obj.BatchOpt.mibBatchTooltip.Mode = sprintf('Some MorphOps operations ("Clear border", "H-maxima", "H-minima") can also be done in 3D');
            obj.BatchOpt.mibBatchTooltip.ColorChannel = sprintf('Specify color channel for MorphOps');
            obj.BatchOpt.mibBatchTooltip.ActionToResult = sprintf('Depending on the choice, results of the MorphOps can be shown as it is or Added/Subtracted from the dataset');
            obj.BatchOpt.mibBatchTooltip.StrelShape = sprintf('Shape of the strel element used for MorphOps');
            obj.BatchOpt.mibBatchTooltip.StrelSize = sprintf('Size of the strel element used for MorphOps');
            obj.BatchOpt.mibBatchTooltip.Connectivity = sprintf('Connectivity factors, shown for 3D mode;\nfor 2D 6-corresponds to 4 and 18-corresponds to 8');
            obj.BatchOpt.mibBatchTooltip.Multiply = sprintf('Multiply result of the operation by this factor');
            obj.BatchOpt.mibBatchTooltip.SmoothHSize = sprintf('Smooth result of the operation using this kernel size');
            obj.BatchOpt.mibBatchTooltip.SmoothSigma = sprintf('Smooth result of the operation using this sigma value');
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

            % add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{1};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    return;
                end
                
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptInput);
                
                obj.continueBtn_Callback();
                return;
            end
            
            guiName = 'mibImageMorphOpsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                toolname = 'morphological operations are';
                warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
                    toolname), 'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.infoText.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.infoText.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            % highlight desired operation in the list
            list = obj.View.handles.MorphOperation.String;
            for i=1:numel(list)
                if strcmp(list{i}, parameter)
                    obj.View.handles.MorphOperation.Value = i;
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
            BatchOptOut = rmfield(BatchOptOut, 'id');     % remove id field
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
            % function updateWidgets(obj)
            % update widgets of this window
            
            % update the Mode panel
            if obj.mibModel.getImageProperty('depth') < 2
                obj.View.handles.Connectivity26.Visible = 'off';
                obj.View.handles.DatasetType.Value = 1;
                obj.View.handles.Mode.Value = 1;
                %obj.View.handles.Mode.String = '2D';
            else
                obj.View.handles.Connectivity26.Enable = 'on';
            end
            
            % updating color channels
            colorsNo = obj.mibModel.getImageProperty('colors');
            colCh = cell([colorsNo+1, 1]);
            colCh{1} = 'All';
            for i=1:colorsNo
                colCh{i+1} = sprintf('ColCh %d', i);
            end
            if colorsNo < obj.View.handles.ColorChannel.Value
                obj.View.handles.ColorChannel.Value = 1;
            end
            obj.View.handles.ColorChannel.String = colCh;
            obj.MorphOperation_Callback();
        end
        
        function MorphOperation_Callback(obj)
            % function MorphOperation_Callback(obj)
            % callback for change of obj.View.handles.MorphOperation
            
            global mibPath;
            list = obj.View.handles.MorphOperation.String;
            currOperationName = list{obj.View.handles.MorphOperation.Value};
            obj.View.handles.StrelShape.Enable = 'on';
            obj.View.handles.StrelSize.Enable = 'on';
            obj.View.handles.Connectivity6.Enable = 'off';
            obj.View.handles.Connectivity18.Enable = 'off';
            obj.View.handles.Connectivity26.Enable = 'off';
            obj.View.handles.Mode.Enable = 'off';
            
            if obj.mibModel.getImageProperty('depth') < 2; obj.View.handles.Mode.Value = 1; end
            
            switch currOperationName
                case 'Bottom-hat filtering'
                    infoText = 'Computes the morphological closing of the image (using imclose`) and then subtracts the result from the original image';
                    operationName = 'imbothat';
                    obj.View.handles.StrelShape.Enable = 'on';
                    obj.View.handles.StrelSize.Enable = 'on';
                case 'Clear border'
                    infoText = 'Suppresses light structures connected to image border';
                    operationName = 'imclearborder';
                    obj.View.handles.Connectivity6.Enable = 'on';
                    obj.View.handles.Connectivity18.Enable = 'on';
                    obj.View.handles.Connectivity26.Enable = 'on';
                    obj.View.handles.StrelShape.Enable = 'off';
                    obj.View.handles.StrelSize.Enable = 'off';
                    obj.View.handles.Mode.Enable = 'on';
                case 'Morphological closing'
                    infoText = 'Morphologically close image: a dilation followed by an erosion';
                    operationName = 'imclose';
                case 'Dilate image'
                    infoText = 'Dilate image';
                    operationName = 'imdilate';
                case 'Erode image'
                    infoText = 'Erode image';
                    operationName = 'imerode';
                case 'Fill regions'
                    infoText = 'Fills holes in the image, where a hole is defined as an area of dark pixels surrounded by lighter pixels';
                    operationName = 'imfill';
                    obj.View.handles.Mode.Value = 1;
                    obj.View.handles.StrelShape.Enable = 'off';
                    obj.View.handles.StrelSize.Enable = 'off';
                case 'H-maxima transform'
                    infoText = 'Suppresses all maxima in the image whose height is less than H';
                    operationName = 'imhmax';
                    obj.View.handles.Connectivity6.Enable = 'on';
                    obj.View.handles.Connectivity18.Enable = 'on';
                    obj.View.handles.Connectivity26.Enable = 'on';
                    obj.View.handles.Mode.Enable = 'on';
                case 'H-minima transform'
                    infoText = 'Suppresses all minima in the image whose depth is less than H';
                    operationName = 'imhmin';
                    obj.View.handles.Connectivity6.Enable = 'on';
                    obj.View.handles.Connectivity18.Enable = 'on';
                    obj.View.handles.Connectivity26.Enable = 'on';
                    obj.View.handles.Mode.Enable = 'on';
                case 'Morphological opening'
                    infoText = 'Morphologically open image: an erosion followed by a dilation';
                    operationName = 'imopen';
                case 'Top-hat filtering'
                    infoText = 'Computes the morphological opening of the image (using imopen) and then subtracts the result from the original image';
                    operationName = 'imtophat';
            end
            obj.View.handles.infoText.String = infoText;
            
            % load preview image
            img = imread(fullfile(mibPath, 'Resources', [operationName '.jpg']));
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
            
            DatasetTypeString = obj.View.handles.DatasetType.String;
            DatasetType = DatasetTypeString{obj.View.handles.DatasetType.Value};
            obj.BatchOpt.DatasetType{1} = DatasetType;
            
            if strcmp(DatasetType, '2D, Slice'); obj.View.handles.Mode.Value = 1; end
            obj.BatchOpt.Mode{1} = obj.View.handles.Mode.String{obj.View.handles.Mode.Value};
            
            if strcmp(obj.BatchOpt.Mode{1}, '2D')
                obj.View.handles.Connectivity6.String = '4';
                obj.View.handles.Connectivity18.String = '8';
                obj.View.handles.Connectivity26.Visible = 'off';
                if obj.View.handles.Connectivity26.Value == 1
                    obj.View.handles.Connectivity6.Value = 1;
                    obj.BatchOpt.Connectivity{1} = 'Connectivity6';
                end
                obj.View.handles.previewBtn.Enable = 'on';
                obj.View.handles.SmoothHSize.Enable = 'on';
                obj.View.handles.SmoothSigma.Enable = 'on';
                obj.View.handles.autoPreviewCheck.Enable = 'on';
            else
                obj.View.handles.Connectivity6.String = '6';
                obj.View.handles.Connectivity18.String = '18';
                obj.View.handles.Connectivity26.Visible = 'on';
                obj.View.handles.previewBtn.Enable = 'off';
                obj.View.handles.SmoothHSize.Enable = 'off';
                obj.View.handles.SmoothSigma.Enable = 'off';
                obj.View.handles.autoPreviewCheck.Value = 0;
                obj.View.handles.autoPreviewCheck.Enable = 'off';
            end
            
            % use auto preview
            if obj.View.handles.autoPreviewCheck.Value == 1
                obj.previewBtn_Callback();
            end
        end
        
        function previewBtn_Callback(obj)
            % function previewBtn_Callback(obj)
            % callback for press of obj.View.handles.previewBtn

            colChannel = obj.View.handles.ColorChannel.Value - 1;
            se = obj.getStrelElement();
            hValue = str2num(obj.BatchOpt.StrelSize); %#ok<ST2NM>
            multiplyFactor = str2double(obj.BatchOpt.Multiply);
            SmoothHSize = str2double(obj.BatchOpt.SmoothHSize);
            SmoothSigma = str2double(obj.BatchOpt.SmoothSigma);
            
            if strcmp(obj.BatchOpt.Connectivity{1}, 'Connectivity6')
                conn = 4;
            else
                conn = 8;
            end
            
            getDataOptions.blockModeSwitch = 1;
            img = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, colChannel, getDataOptions));
            Iout = zeros(size(img), class(img));
            
            for colId = 1:size(img, 3)
                switch obj.BatchOpt.MorphOperation{1}
                    case 'Bottom-hat filtering'
                        Iout(:,:,colId) = imbothat(img(:,:,colId), se);
                    case 'Clear border'
                        Iout(:,:,colId) = imclearborder(img(:,:,colId), conn);
                    case 'Morphological closing'
                        Iout(:,:,colId) = imclose(img(:,:,colId), se);
                    case 'Dilate image'
                        Iout(:,:,colId) = imdilate(img(:,:,colId), se);
                    case 'Erode image'
                        Iout(:,:,colId) = imerode(img(:,:,colId), se);
                    case 'Fill regions'
                        Iout(:,:,colId) = imfill(img(:,:,colId));
                    case 'H-maxima transform'
                        Iout(:,:,colId) = imhmax(img(:,:,colId), hValue(1), conn);
                    case 'H-minima transform'
                        Iout(:,:,colId) = imhmin(img(:,:,colId), hValue(1), conn);
                    case 'Morphological opening'
                        Iout(:,:,colId) = imopen(img(:,:,colId), se);
                    case 'Top-hat filtering'
                        Iout(:,:,colId) = imtophat(img(:,:,colId), se);
                end

                if SmoothHSize > 0  % do gaussian filtering
                    filter2d = fspecial('gaussian', SmoothHSize, SmoothSigma);
                    Iout(:,:,colId) = imfilter(Iout(:,:,colId), filter2d, 'replicate');
                end
            end
            
            switch obj.BatchOpt.ActionToResult{1}
                case 'None'
                    img = Iout*multiplyFactor;
                case 'AddToImage'
                    img = img + Iout*multiplyFactor;
                case 'SubtractFromImage'
                    img = img - Iout*multiplyFactor;
            end
            
            eventdata = ToggleEventData(img);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
            notify(obj.mibModel, 'plotImage', eventdata);
        end
        
        function se = getStrelElement(obj)
            % function se = getStrelElement(obj)
            % get strel element for the morph ops functions
            
            se_size = str2num(obj.BatchOpt.StrelSize); %#ok<ST2NM>
            
            % when only 1 value - calculate the second from the pixSize
            if strcmp(obj.BatchOpt.Mode{1}, '3D')
                if numel(se_size) == 1
                    se_size(2) = max([round(se_size(1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.z) 1]); % for z
                end
            elseif numel(se_size) == 1
                se_size(2) = se_size(1);
            end
            
            if strcmp(obj.BatchOpt.StrelShape{1}, 'rectangle') == 1  
                if strcmp(obj.BatchOpt.Mode{1}, '3D')
                    se = ones([se_size(1), se_size(1), se_size(2)]);
                else
                    se = strel('rectangle', [se_size(1), se_size(2)]);
                end
            else                % disk
                if strcmp(obj.BatchOpt.Mode{1}, '3D')
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
            
            BatchOptLoc = obj.BatchOpt;     % make a local copy of the BatchOpt, because it may be extended with additional fields
            
            if BatchOptLoc.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', [BatchOptLoc.MorphOperation{1} ' filter']); end
            colChannel = find(ismember(BatchOptLoc.ColorChannel{2}, BatchOptLoc.ColorChannel(1))) - 1;
            se = obj.getStrelElement();
            
            hValue = str2num(BatchOptLoc.StrelSize); %#ok<ST2NM>
            multiplyFactor = str2double(BatchOptLoc.Multiply);
            SmoothHSize = str2double(BatchOptLoc.SmoothHSize);
            SmoothSigma = str2double(BatchOptLoc.SmoothSigma);
            
            % backup current data
            backupOpt.id = BatchOptLoc.id;
            if strcmp(BatchOptLoc.DatasetType{1}, '2D, Slice')
                obj.mibModel.mibDoBackup('image', 0, backupOpt);
            elseif strcmp(BatchOptLoc.DatasetType{1}, '3D, Stack')
                obj.mibModel.mibDoBackup('image', 1, backupOpt);
            elseif strcmp(BatchOptLoc.DatasetType{1}, '4D, Dataset') && obj.mibModel.getImageProperty('time') == 1
                obj.mibModel.mibDoBackup('image', 1, backupOpt);
            end
            
            if strcmp(BatchOptLoc.DatasetType{1}, '2D, Slice')
                BatchOptLoc.t = [obj.mibModel.I{BatchOptLoc.id}.slices{5}(1), obj.mibModel.I{BatchOptLoc.id}.slices{5}(1)];
                maxIndex = 1;
            elseif strcmp(BatchOptLoc.DatasetType{1}, '3D, Stack')
                BatchOptLoc.t = [obj.mibModel.I{BatchOptLoc.id}.slices{5}(1), obj.mibModel.I{BatchOptLoc.id}.slices{5}(1)];
                maxIndex = obj.mibModel.I{BatchOptLoc.id}.depth;
            elseif strcmp(BatchOptLoc.DatasetType{1}, '4D, Dataset')
                BatchOptLoc.t = [1, obj.mibModel.I{BatchOptLoc.id}.time];
                maxIndex = obj.mibModel.I{BatchOptLoc.id}.depth * obj.mibModel.I{BatchOptLoc.id}.time;
            end
            
            if isfield(BatchOptLoc, 'x'); getDataOptions.x = BatchOptLoc.x; end
            if isfield(BatchOptLoc, 'y'); getDataOptions.y = BatchOptLoc.y; end
            if isfield(BatchOptLoc, 'z'); getDataOptions.z = BatchOptLoc.z; end
            
            if strcmp(BatchOptLoc.Mode{1}, '3D')
                switch obj.BatchOpt.Connectivity{1}
                    case 'Connectivity6'; conn = 6;
                    case 'Connectivity18'; conn = 18;
                    case 'Connectivity26'; conn = 26;
                end
            else
                switch obj.BatchOpt.Connectivity{1}
                    case 'Connectivity6'; conn = 4;
                    case 'Connectivity18'; conn = 8;
                end
            end
            
            index = 0;
            getDataOptions.id = BatchOptLoc.id;
            for t=BatchOptLoc.t(1):BatchOptLoc.t(2)
                getDataOptions.t = [t t];
                if strcmp(BatchOptLoc.Mode{1}, '3D')
                    img = obj.mibModel.getData3D('image', t, 4, colChannel, getDataOptions);
                    Iout = cell([numel(img),1]);
                    
                    for roiId=1:numel(img)
                        Iout{roiId} = zeros(size(img{roiId}), class(img{roiId}));
                        for colCh = 1:size(img{roiId}, 3)
                            switch BatchOptLoc.MorphOperation{1}
                                case 'Bottom-hat filtering'
                                    Iout{roiId}(:,:,colCh,:) = permute(imbothat(squeeze(img{roiId}(:,:,colCh,:)), se), [1 2 4 3]);
                                case 'Clear border'
                                    Iout{roiId}(:,:,colCh,:) = permute(imclearborder(squeeze(img{roiId}(:,:,colCh,:)), conn), [1 2 4 3]);
                                case 'Morphological closing'
                                    Iout{roiId}(:,:,colCh,:) = permute(imclose(squeeze(img{roiId}(:,:,colCh,:)), se), [1 2 4 3]);
                                case 'Dilate image'
                                    Iout{roiId}(:,:,colCh,:) = permute(imdilate(squeeze(img{roiId}(:,:,colCh,:)), se), [1 2 4 3]);
                                case 'Erode image'
                                    Iout{roiId}(:,:,colCh,:) = permute(imerode(squeeze(img{roiId}(:,:,colCh,:)), se), [1 2 4 3]);
                                case 'Fill regions'
                                    Iout{roiId}(:,:,colCh,:) = permute(imfill(squeeze(img{roiId}(:,:,colCh,:))), [1 2 4 3]);
                                case 'H-maxima transform'
                                    Iout{roiId}(:,:,colCh,:) = permute(imhmax(squeeze(img{roiId}(:,:,colCh,:)), hValue(1), conn), [1 2 4 3]);
                                case 'H-minima transform'
                                    Iout{roiId}(:,:,colCh,:) = permute(imhmin(squeeze(img{roiId}(:,:,colCh,:)), hValue(1), conn), [1 2 4 3]);
                                case 'Morphological opening'
                                    Iout{roiId}(:,:,colCh,:) = permute(imopen(squeeze(img{roiId}(:,:,colCh,:)), se), [1 2 4 3]);
                                case 'Top-hat filtering'
                                    Iout{roiId}(:,:,colCh,:) = permute(imtophat(squeeze(img{roiId}(:,:,colCh,:)), se), [1 2 4 3]);
                            end
                        end
                        
                        switch BatchOptLoc.ActionToResult{1}
                            case 'None'
                                img{roiId} = Iout{roiId}*multiplyFactor;
                            case 'AddToImage'
                                img{roiId} = img{roiId} + Iout{roiId}*multiplyFactor;
                            case 'SubtractFromImage'
                                img{roiId} = img{roiId} - Iout{roiId}*multiplyFactor;
                        end
                    end
                    if BatchOptLoc.showWaitbar; waitbar(index/maxIndex,wb); end
                    index = index + obj.mibModel.I{BatchOptLoc.id}.depth;
                    obj.mibModel.setData3D('image', img, t, 4, colChannel, getDataOptions);
                else
                    if isfield(BatchOptLoc, 'z')
                        startSlice = BatchOptLoc.z(1);
                        endSlice = BatchOptLoc.z(2);
                    else
                        startSlice = 1;
                        endSlice = obj.mibModel.I{BatchOptLoc.id}.dim_yxczt(obj.mibModel.I{BatchOptLoc.id}.orientation);
                    
                        if strcmp(BatchOptLoc.Mode{1}, '2D') && strcmp(BatchOptLoc.DatasetType{1}, '2D, Slice')
                            startSlice = obj.mibModel.I{BatchOptLoc.id}.getCurrentSliceNumber();
                            endSlice = startSlice;
                        end
                    end
                    
                    if SmoothHSize > 0  % do gaussian filtering
                        filter2d = fspecial('gaussian', SmoothHSize, SmoothSigma);
                    end
                    noSlices = endSlice - startSlice + 1;
                    
                    for sliceId = startSlice:endSlice
                        img = obj.mibModel.getData2D('image', sliceId, NaN, colChannel, getDataOptions);
                        Iout = cell([numel(img),1]);
                        for roiId=1:numel(img)
                            Iout{roiId} = zeros(size(img{roiId}), class(img{roiId}));
                            for colCh = 1:size(img{roiId}, 3)
                                switch BatchOptLoc.MorphOperation{1}
                                    case 'Bottom-hat filtering'
                                        Iout{roiId}(:,:,colCh) = imbothat(img{roiId}(:,:,colCh), se);
                                    case 'Clear border'
                                        Iout{roiId}(:,:,colCh) = imclearborder(img{roiId}(:,:,colCh), conn);
                                    case 'Morphological closing'
                                        Iout{roiId}(:,:,colCh) = imclose(img{roiId}(:,:,colCh), se);
                                    case 'Dilate image'
                                        Iout{roiId}(:,:,colCh) = imdilate(img{roiId}(:,:,colCh), se);
                                    case 'Erode image'
                                        Iout{roiId}(:,:,colCh) = imerode(img{roiId}(:,:,colCh), se);
                                    case 'Fill regions'
                                        Iout{roiId}(:,:,colCh) = imfill(img{roiId}(:,:,colCh));
                                    case 'H-maxima transform'
                                        Iout{roiId}(:,:,colCh) = imhmax(img{roiId}(:,:,colCh), hValue(1), conn);
                                    case 'H-minima transform'
                                        Iout{roiId}(:,:,colCh) = imhmin(img{roiId}(:,:,colCh), hValue(1), conn);
                                    case 'Morphological opening'
                                        Iout{roiId}(:,:,colCh) = imopen(img{roiId}(:,:,colCh), se);
                                    case 'Top-hat filtering'
                                        Iout{roiId}(:,:,colCh) = imtophat(img{roiId}(:,:,colCh), se);
                                end
                            
                                if SmoothHSize > 0  % do gaussian filtering
                                    Iout{roiId}(:,:,colCh) = imfilter(Iout{roiId}(:,:,colCh), filter2d, 'replicate');
                                end
                            end
                            
                            switch BatchOptLoc.ActionToResult{1}
                                case 'None'
                                    img{roiId} = Iout{roiId}*multiplyFactor;
                                case 'AddToImage'
                                    img{roiId} = img{roiId} + Iout{roiId}*multiplyFactor;
                                case 'SubtractFromImage'
                                    img{roiId} = img{roiId} - Iout{roiId}*multiplyFactor;
                            end
                        end
                        obj.mibModel.setData2D('image', img, sliceId, NaN, colChannel, getDataOptions);
                        if BatchOptLoc.showWaitbar; waitbar(index/maxIndex,wb); end
                        index = index + 1;
                    end
                end
            end
            
            % update log
            if strcmp(BatchOptLoc.DatasetType{1}, '2D, Slice')
                modeTxt = sprintf('2D, Slice,Z=%d,T=%d', startSlice, BatchOptLoc.t(1));
            elseif strcmp(BatchOptLoc.DatasetType{1}, '3D, Stack')
                modeTxt = sprintf('%s/%s,T=%d', BatchOptLoc.DatasetType{1}, BatchOptLoc.Mode{1}, BatchOptLoc.t(1));
            else
                modeTxt = sprintf('4D, Dataset/%s', BatchOptLoc.Mode{1});
            end
            
            log_text = ['imageMorphOps: Operation=' BatchOptLoc.MorphOperation{1} ',Mode=' modeTxt ',ColCh=', BatchOptLoc.ColorChannel{1} ...
                ',Strel=' BatchOptLoc.StrelShape{1} '/' BatchOptLoc.StrelSize ',Conn=' BatchOptLoc.Connectivity{1} ',Multiply=' BatchOptLoc.Multiply ...
                ',Smoothing=' BatchOptLoc.SmoothHSize '/' BatchOptLoc.SmoothSigma ',action=' BatchOptLoc.ActionToResult{1} ...
                ',orient=' num2str(obj.mibModel.I{BatchOptLoc.id}.orientation)];
            obj.mibModel.I{BatchOptLoc.id}.updateImgInfo(log_text);
            if BatchOptLoc.showWaitbar
                waitbar(1,wb); 
                delete(wb);
            end
            
            notify(obj.mibModel, 'plotImage');
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(BatchOptLoc);
        end
    end
end