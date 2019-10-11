classdef mibResampleController  < handle
    % @type mibResampleController class is resposnible for showing the dataset
    % resample window, available from MIB->Menu->Dataset->Resample 
    
	% Copyright (C) 01.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	% 30.08.2017 IB added shift of annotations during resampling
    % 12.03.2019 IB updated for the batch mode
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        height
        % a value with the current height of the dataset
        width
        % a value with the current width of the dataset
        color
        % a value with number of color channels
        depth
        % a value with the current depth of the dataset
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
                case 'updateGuiWidgets'
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibResampleController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            getDataOpt.blockModeSwitch = 0;
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, getDataOpt);
            
            % fill BatchOpt structure with default values
            obj.BatchOpt.ResamplingFunction = {'imresize'};     % function used for resampling
            obj.BatchOpt.ResamplingFunction{2} = [{'interpn'},{'imresize'},{'tformarray'}];
            obj.BatchOpt.ResamplingMethod = {'cubic'};            % method used for resampling of images
            obj.BatchOpt.ResamplingMethod{2} = [{'nearest'},{'linear'},{'spline'},{'cubic'},{'box'},{'triangle'},{'lanczos2'},{'lanczos2'}];
            obj.BatchOpt.ResamplingMethodModels = {'nearest'};    % method used for resampling of models
            obj.BatchOpt.ResamplingMethodModels{2} = [{'nearest'},{'linear'},{'spline'},{'cubic'}];
            obj.BatchOpt.Dimensions = true;                    % type of values for resampling, dims in pixels
            obj.BatchOpt.Voxels = false;                        % type of values for resampling, voxels
            obj.BatchOpt.PercentageXYZ = false;                 % type of values for resampling, percentage
            obj.BatchOpt.PercentageXY = false;                  % type of values for resampling, percentage
            obj.BatchOpt.DimensionX = num2str(width);        % new width in pix                
            obj.BatchOpt.DimensionY = num2str(height);        % new height in pix
            obj.BatchOpt.DimensionZ = num2str(depth);          % new depth in pix
            obj.BatchOpt.Percentage = '100';        % new relative percentage
            obj.BatchOpt.VoxelX = num2str(obj.mibModel.I{obj.mibModel.Id}.pixSize.x);      % new voxel size for X
            obj.BatchOpt.VoxelY = num2str(obj.mibModel.I{obj.mibModel.Id}.pixSize.y);      % new voxel size for Y
            obj.BatchOpt.VoxelZ = num2str(obj.mibModel.I{obj.mibModel.Id}.pixSize.z);      % new voxel size for Z
            obj.BatchOpt.FixAspectRatio = true;
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            % add section name and action name for the batch tool
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
            obj.BatchOpt.mibBatchActionName = 'Resample...';
            
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.ResamplingFunction = sprintf('Resampling function used to resize the dataset');
            obj.BatchOpt.mibBatchTooltip.ResamplingMethod = sprintf('Resampling method for images\nit is recommended to use "cubic" for downsampling and "nearest" for upsampling');
            obj.BatchOpt.mibBatchTooltip.ResamplingMethodModels = sprintf('Resampling method for models\nit is recommended to use "nearest"');
            obj.BatchOpt.mibBatchTooltip.Dimensions = sprintf('Resample the dataset based on provided dimensions in pixels');
            obj.BatchOpt.mibBatchTooltip.Voxels = sprintf('Resample the dataset based on provided voxel size');
            obj.BatchOpt.mibBatchTooltip.PercentageXYZ = sprintf('Resample the dataset based on provided scaling in %% for XYZ dimensions');
            obj.BatchOpt.mibBatchTooltip.PercentageXY = sprintf('Resample the dataset based on provided scaling in %% for XY dimensions');
            obj.BatchOpt.mibBatchTooltip.DimensionX = sprintf('[Dimensions only]\nNew width of the dataset');
            obj.BatchOpt.mibBatchTooltip.DimensionY = sprintf('[Dimensions only]\nNew height of the dataset');
            obj.BatchOpt.mibBatchTooltip.DimensionZ = sprintf('[Dimensions only]\nNew depth of the dataset');
            obj.BatchOpt.mibBatchTooltip.Percentage = sprintf('[Percentage only]\nScaling factor in %%');
            obj.BatchOpt.mibBatchTooltip.VoxelX = sprintf('[Voxels only]\nNew voxel size in X');
            obj.BatchOpt.mibBatchTooltip.VoxelY = sprintf('[Voxels only]\nNew voxel size in Y');
            obj.BatchOpt.mibBatchTooltip.VoxelZ = sprintf('[Voxels only]\nNew voxel size in Z');
            obj.BatchOpt.mibBatchTooltip.FixAspectRatio = sprintf('Fix the aspect ratio during resizing');
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');
           
            options.blockModeSwitch = 0;
            [obj.height, obj.width, obj.color, obj.depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, options);
            obj.color = numel(obj.color);
            
            % ---- Batch mode processing code
            % if the BatchOpt stucture is provided the controller is initialized using those parameters
            % and performs the function in the headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{2};
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
                
                % check the radio button names
                if obj.BatchOpt.Dimensions + obj.BatchOpt.Voxels + obj.BatchOpt.PercentageXYZ + obj.BatchOpt.PercentageXY > 1
                    errordlg(sprintf('The wrong initialization of radio buttons!\n\nOnly one of the following options should be used:\n.Dimensions=true (.DimensionX, .DimensionY, .DimensionZ)\n.Voxels=true (.VoxelX, .VoxelY, .VoxelZ)\n.PercentageXYZ=true (.Percentage)\n.PercentageXY=true (.Percentage)'), 'Resamping: initialization error');
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
                
                if isfield(obj.BatchOpt, 'id')
                    errordlg(sprintf('!!! Error !!!\n\nCrop tool is not compatible with the "id" field yet'), 'Crop: initialization error');
                    notify(obj.mibModel, 'stopProtocol');
                end
                
                obj.resampleBtn_Callback();
                return;
            end
            
            guiName = 'mibResampleGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
				
			obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
             % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
             obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
        end
        
        function closeWindow(obj)
            % closing mibResampleController  window
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
            
            options.blockModeSwitch = 0;
            [obj.height, obj.width, obj.color, obj.depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, options);
            obj.color = numel(obj.color);
            
            obj.View.handles.ResamplingMethodModels.String = 'nearest';
            
            obj.View.handles.widthTxt.String = num2str(obj.width);
            obj.View.handles.heightTxt.String = num2str(obj.height);
            obj.View.handles.colorsTxt.String = num2str(obj.color);
            obj.View.handles.depthTxt.String = num2str(obj.depth);
            
            pixSize = obj.mibModel.getImageProperty('pixSize');
            obj.View.handles.pixsizeX.String = sprintf('%f %s', pixSize.x, pixSize.units);
            obj.View.handles.pixsizeY.String = sprintf('%f %s', pixSize.y, pixSize.units);
            obj.View.handles.pixsizeZ.String = sprintf('%f %s', pixSize.z, pixSize.units);
            
            obj.View.handles.DimensionX.String = num2str(obj.width);
            obj.View.handles.DimensionY.String = num2str(obj.height);
            obj.View.handles.DimensionZ.String = num2str(obj.depth);
            obj.View.handles.VoxelX.String = sprintf('%f', pixSize.x);
            obj.View.handles.VoxelY.String = sprintf('%f', pixSize.y);
            obj.View.handles.VoxelZ.String = sprintf('%f', pixSize.z);
            obj.View.handles.Percentage.String = '100';
        end
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
             
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
        
        function editbox_Callback(obj, hObject)
            % function editbox_Callback(obj)
            % callbacks for modification of edit boxes
            %
            % Parameters:
            % hObject: handle to the editbox
            pixSize = obj.mibModel.getImageProperty('pixSize');
            
            if obj.BatchOpt.Dimensions
                switch hObject.Tag
                    case 'DimensionX'
                        val = str2double(hObject.String);
                        ratio = obj.width / val;
                        obj.View.handles.VoxelX.String = num2str(pixSize.x*ratio);
                        if obj.View.handles.FixAspectRatio.Value
                            obj.View.handles.DimensionY.String = num2str(floor(obj.height/ratio));
                            obj.View.handles.VoxelY.String = num2str(pixSize.y*ratio);
                        end
                    case 'DimensionY'
                        val = str2double(hObject.String);
                        ratio = obj.height / val;
                        obj.View.handles.VoxelY.String = num2str(pixSize.y*ratio);
                        if obj.View.handles.FixAspectRatio.Value
                            obj.View.handles.DimensionX.String = num2str(floor(obj.width/ratio));
                            obj.View.handles.VoxelX.String = num2str(pixSize.x*ratio);
                        end
                    case 'DimensionZ'
                        val = str2double(hObject.String);
                        ratio = obj.depth / val;
                        obj.View.handles.VoxelZ.String = num2str(pixSize.z*ratio);
                end
            elseif obj.BatchOpt.Voxels
                switch hObject.Tag
                    case 'VoxelX'
                        val = str2double(hObject.String);
                        ratio = val / pixSize.x;
                        obj.View.handles.DimensionX.String = num2str(floor(obj.width/ratio));
                        if obj.View.handles.FixAspectRatio.Value
                            obj.View.handles.DimensionY.String = num2str(floor(obj.height/ratio));
                            obj.View.handles.VoxelY.String = num2str(pixSize.y*ratio);
                        end
                    case 'VoxelY'
                        val = str2double(hObject.String);
                        ratio = val / pixSize.y;
                        obj.View.handles.DimensionY.String = num2str(floor(obj.height/ratio));
                        if obj.View.handles.FixAspectRatio.Value
                            obj.View.handles.DimensionX.String = num2str(floor(obj.width/ratio));
                            obj.View.handles.VoxelX.String = num2str(pixSize.x*ratio);
                        end
                    case 'VoxelZ'
                        val = str2double(hObject.String);
                        ratio = val / pixSize.z;
                        obj.View.handles.DimensionZ.String = num2str(floor(obj.depth/ratio));
                end
            elseif obj.BatchOpt.PercentageXYZ
                val = str2double(obj.View.handles.Percentage.String);
                obj.View.handles.DimensionX.String = num2str(floor(obj.width/100*val));
                obj.View.handles.DimensionY.String = num2str(floor(obj.height/100*val));
                obj.View.handles.DimensionZ.String = num2str(floor(obj.depth/100*val));
                obj.View.handles.VoxelX.String = num2str(pixSize.x*obj.width/floor(obj.width/100*val));
                obj.View.handles.VoxelY.String = num2str(pixSize.y*obj.height/floor(obj.height/100*val));
                obj.View.handles.VoxelZ.String = num2str(pixSize.z*obj.depth/floor(obj.depth/100*val));
            elseif obj.BatchOpt.PercentageXY
                val = str2double(obj.View.handles.Percentage.String);
                obj.View.handles.DimensionX.String = num2str(floor(obj.width/100*val));
                obj.View.handles.DimensionY.String = num2str(floor(obj.height/100*val));
                obj.View.handles.VoxelX.String = num2str(pixSize.x*obj.width/floor(obj.width/100*val));
                obj.View.handles.VoxelY.String = num2str(pixSize.y*obj.height/floor(obj.height/100*val));
            end
            
            % update obj.BatchOpt
            obj.BatchOpt.DimensionX = obj.View.handles.DimensionX.String;        % new width in pix                
            obj.BatchOpt.DimensionY = obj.View.handles.DimensionY.String;        % new height in pix
            obj.BatchOpt.DimensionZ = obj.View.handles.DimensionZ.String;          % new depth in pix
            obj.BatchOpt.Percentage = obj.View.handles.Percentage.String;        % new relative percentage
            obj.BatchOpt.VoxelX = obj.View.handles.VoxelX.String;      % new voxel size for X
            obj.BatchOpt.VoxelY = obj.View.handles.VoxelY.String;      % new voxel size for Y
            obj.BatchOpt.VoxelZ = obj.View.handles.VoxelZ.String;      % new voxel size for Z
        end
        
        function resampleBtn_Callback(obj)
            % function resampleBtn_Callback(obj)
            % resample the current dataset
            tic
            pixSize = obj.mibModel.getImageProperty('pixSize');
            
            BatchOptLoc = obj.BatchOpt;
            % recompute provided values to width/height/depth
            if BatchOptLoc.Voxels 
                voxX = str2double(BatchOptLoc.VoxelX);
                ratio = voxX / pixSize.x;
                BatchOptLoc.DimensionX = num2str(floor(obj.width/ratio));
                if BatchOptLoc.FixAspectRatio
                    BatchOptLoc.DimensionY = num2str(floor(obj.height/ratio));
                else
                    voxY = str2double(BatchOptLoc.VoxelY);
                    ratio = voxY / pixSize.y;
                    BatchOptLoc.DimensionY = num2str(floor(obj.height/ratio));
                end
                valZ = str2double(BatchOptLoc.VoxelZ);
                ratio = valZ / pixSize.z;
                BatchOptLoc.DimensionZ = num2str(floor(obj.depth/ratio));
            elseif BatchOptLoc.PercentageXYZ
                val = str2double(BatchOptLoc.Percentage);
                BatchOptLoc.DimensionX = num2str(floor(obj.width/100*val));
                BatchOptLoc.DimensionY = num2str(floor(obj.height/100*val));
                BatchOptLoc.DimensionZ = num2str(floor(obj.depth/100*val));
            elseif BatchOptLoc.PercentageXY
                val = str2double(BatchOptLoc.Percentage);
                BatchOptLoc.DimensionX = num2str(floor(obj.width/100*val));
                BatchOptLoc.DimensionY = num2str(floor(obj.height/100*val));
            end
            
            newW = str2double(BatchOptLoc.DimensionX);
            newH = str2double(BatchOptLoc.DimensionY);
            newZ = str2double(BatchOptLoc.DimensionZ);
            maxT = obj.mibModel.getImageProperty('time');
            if newW == obj.width && newH == obj.height && newZ == obj.depth
                warndlg('The dimensions were not changed!', 'Wrong dimensions', 'modal');
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            
            % define resampled ratio for resampling ROIs
            resampledRatio = [newW/obj.width, newH/obj.height, newZ/obj.depth];
            
            ResamplingFunction = BatchOptLoc.ResamplingFunction{1};
            methodImage = BatchOptLoc.ResamplingMethod{1};
            ResamplingMethodModels = BatchOptLoc.ResamplingMethodModels{1};
            
            if BatchOptLoc.showWaitbar
                wb = waitbar(0,sprintf('Resampling image...\n[%d %d %d %d]->[%d %d %d %d]', ...
                    obj.height, obj.width, obj.color, obj.depth, newH, newW, obj.color, newZ), 'Name', 'Resampling ...', 'WindowStyle', 'modal');
            end
            
            options.blockModeSwitch=0;
            imgOut = zeros([newH, newW, obj.color, newZ, maxT], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'));   %#ok<ZEROLIKE> % allocate space
            options.height = newH;
            options.width = newW;
            options.depth = newZ;
            options.method = methodImage;
            options.imgType = '4D';
            for t=1:maxT
                img = cell2mat(obj.mibModel.getData3D('image', t, 4, 0, options));
                if BatchOptLoc.showWaitbar; waitbar(0.05,wb); end
                % resample image
                if strcmp(ResamplingFunction, 'interpn')
                    options.showWaitbar = 0;
                    options.algorithm = 'interpn';
                    imgOut(:,:,:,:,t) = mibResize3d(img(:,:,:,:), [], options);
                elseif strcmp(ResamplingFunction, 'imresize')
                    options.showWaitbar = 0;
                    options.algorithm = 'imresize';
                    imgOut(:,:,:,:,t) = mibResize3d(img(:,:,:,:), [], options);
                else
                    options.showWaitbar = 0;
                    options.algorithm = 'tformarray';
                    imgOut(:,:,:,:,t) = mibResize3d(img(:,:,:,:), [], options);
                end
            end
            clear img;
            clear imgOut2;
            if BatchOptLoc.showWaitbar; waitbar(0.5,wb); end
            
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0
                obj.mibModel.setData4D('image', imgOut, 4, 0, options);
            else
                %obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual = 0;
                %obj.mibModel.I{obj.mibModel.Id}.disableSelection = obj.mibModel.preferences.disableSelection;  % should be before cropDataset
                newMode = obj.mibModel.I{obj.mibModel.Id}.switchVirtualStackingMode(0);   % switch to the memory resident mode
                if isempty(newMode); delete(wb); notify(obj.mibModel, 'stopProtocol'); return; end
                obj.mibModel.setData4D('image', imgOut, 4, 0, options);
            end
            if BatchOptLoc.showWaitbar; waitbar(0.55,wb); end
            
            % update pixel dimensions
            obj.mibModel.I{obj.mibModel.Id}.pixSize.x = obj.mibModel.I{obj.mibModel.Id}.pixSize.x/size(imgOut, 2)*obj.width;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.y = obj.mibModel.I{obj.mibModel.Id}.pixSize.y/size(imgOut, 1)*obj.height;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.z = obj.mibModel.I{obj.mibModel.Id}.pixSize.z/size(imgOut, 4)*obj.depth;
            
            % update img_info
            resolution = mibCalculateResolution(obj.mibModel.I{obj.mibModel.Id}.pixSize);
            obj.mibModel.I{obj.mibModel.Id}.meta('XResolution') = resolution(1);
            obj.mibModel.I{obj.mibModel.Id}.meta('YResolution') = resolution(2);
            obj.mibModel.I{obj.mibModel.Id}.meta('ResolutionUnit') = 'Inch';
            
            options.method = ResamplingMethodModels;
            options.imgType = '3D';
            % resample model and mask
            modelDataType = 'model'; 
            if obj.mibModel.I{obj.mibModel.Id}.modelExist
                if BatchOptLoc.showWaitbar
                    waitbar(0.75,wb,sprintf('Resampling model...\n[%d %d %d %d]->[%d %d %d %d]', ...
                        obj.height, obj.width, obj.color, obj.depth, newH, newW, obj.color, newZ));
                end
                imgOut = zeros([newH, newW, newZ, maxT], 'uint8');
                
                if obj.mibModel.I{obj.mibModel.Id}.modelType == 63 && strcmp(ResamplingMethodModels,'nearest')
                    modelDataType = 'everything';   % resample all layers
                end
                
                model = cell2mat(obj.mibModel.getData4D(modelDataType, 4, NaN, options));  % have to use getData4D, because getData3D returns the cropped model because of already resized image
                matetialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
                for t=1:maxT
                    if strcmp(ResamplingFunction, 'interpn')
                        if strcmp(ResamplingMethodModels,'nearest')
                            options.showWaitbar = 0;
                            options.algorithm = 'interpn';
                            imgOut(:,:,:,t) = mibResize3d(model(:,:,:,t), [], options);
                        else
                            modelTemp = zeros([newH, newW, newZ], 'uint8');
                            for materialId = 1:matetialsNumber
                                modelTemp2 = zeros(size(model(:,:,:,t)), 'uint8');
                                modelTemp2(model(:,:,:,t) == materialId) = 1;
                                modelTemp2 = mibResize3d(modelTemp2, [], options);
                                modelTemp(modelTemp2 > 0.33) = materialId;
                            end
                            imgOut(:,:,:,t) = modelTemp;
                        end
                    elseif strcmp(ResamplingFunction, 'imresize')
                        options.showWaitbar = 0;
                        options.algorithm = 'imresize';
                        imgOut(:,:,:,t) = mibResize3d(model(:,:,:,t), [], options);
                    else
                        options.showWaitbar = 0;
                        options.algorithm = 'tformarray';
                        imgOut(:,:,:,t) = mibResize3d(model(:,:,:,t), [], options);
                    end
                end
                if BatchOptLoc.showWaitbar; waitbar(0.95,wb); end
                obj.mibModel.I{obj.mibModel.Id}.model{1} = zeros(size(imgOut), 'uint8');  % reinitialize .model
                obj.mibModel.setData4D(modelDataType, imgOut, 4, NaN, options);
            elseif obj.mibModel.I{obj.mibModel.Id}.modelType == 63     % when no model, reset handles.Img{andles.Id}.I.model variable
                obj.mibModel.I{obj.mibModel.Id}.model{1} = zeros([size(imgOut,1), size(imgOut,2), size(imgOut,4) size(imgOut,5)], 'uint8');    % clear the old model
            end
            
            % shift annotations
            labelsNumber = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber();
            if labelsNumber > 0
                [labelsList, labelValues, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
                if numel(labelsList) == 0; notify(obj.mibModel, 'stopProtocol'); return; end
                labelPositions(:,1) =  labelPositions(:,1) * options.depth/obj.depth;
                labelPositions(:,2) =  labelPositions(:,2) * options.width/obj.width;
                labelPositions(:,3) =  labelPositions(:,3) * options.height/obj.height;
                obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(labelsList, labelPositions, labelValues);
            end
            
            % resampling ROIS
            obj.mibModel.I{obj.mibModel.Id}.hROI.resample(resampledRatio);
            
            % update the log
            log_text = sprintf('Resample [%d %d %d %d %d]->[%d %d %d %d %d], method: %s', ...
                obj.height, obj.width, obj.color, obj.depth, maxT, ...
                newH, newW, obj.color, newZ, maxT, methodImage);
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            % remove slice name if number of z-sections has changed
            if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName') && newZ ~= obj.depth
                remove(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName');
            end
            
            if ~strcmp(modelDataType, 'everything')
                obj.mibModel.I{obj.mibModel.Id}.clearSelection();     % will not resample selection
                obj.mibModel.I{obj.mibModel.Id}.clearMask();          % will not resample mask
            end
            if BatchOptLoc.showWaitbar
                waitbar(1,wb);
                delete(wb);
            end
            toc;
            
            notify(obj.mibModel, 'newDataset');
            eventdata = ToggleEventData(1);
            notify(obj.mibModel, 'plotImage', eventdata);
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(BatchOptLoc);
            
            %obj.closeWindow();
        end
        
    end
end