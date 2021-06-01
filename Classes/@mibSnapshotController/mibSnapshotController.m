classdef mibSnapshotController < matlab.mixin.Copyable
    % classdef mibSnapshotController < matlab.mixin.Copyable
    % a controller class for the snapshots subwindow available via
    % MIB->Menu->File->Make snapshot
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    % Updates
    % 16.11.2018, IB updated for making snapshots from volume viewer
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        extraController
        % an optional extra controller, used for making snapshots from volume rendering window
        snapshotFilename
        % a cell array {1:obj.mibModel.maxId} with filenames for saving the snapshots
        origHeight
        % a height of the image area to render
        origWidth
        % width of the image area to render
        resizedWidth
        % width of the image area to render with respect of the aspect ratio
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
                case {'updateROI', 'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibSnapshotController(varargin)
            % function obj = mibSnapshotController(varargin)
            % constructor of the class
            % Parameters:
            % parameter 1: a handles to mibModel
            % parameter 2: [@em optional] a handle to extra controllers 

            obj.mibModel = varargin{1};    % assign model
            if nargin > 1
                obj.extraController = varargin{2};
            else
                obj.extraController = [];
            end
            
            for i=1:obj.mibModel.maxId
                obj.snapshotFilename{i} = [];
            end
            
            obj.BatchOpt.Target = {'File'};     
            obj.BatchOpt.Target{2} = {'File', 'Clipboard'};  
            obj.BatchOpt.Crop = {'FullImage'};     
            obj.BatchOpt.Crop{2} = {'FullImage', 'ShownArea', 'ROI'};
            obj.BatchOpt.ROIIndex = {'1'};
            obj.BatchOpt.ROIIndex{2} = {'1'};
            obj.BatchOpt.Width = '';
            obj.BatchOpt.Height = '';
            obj.BatchOpt.ResizeMethod = {'bicubic'};
            obj.BatchOpt.ResizeMethod{2} = {'bicubic', 'bilinear', 'nearest'};
            obj.BatchOpt.Scalebar = false;
            obj.BatchOpt.Measurements = false;
            obj.BatchOpt.WhiteBackground = true;
            obj.BatchOpt.SplitChannels = false;
            obj.BatchOpt.Grayscale = false;
            obj.BatchOpt.ColsNumber = '2';
            obj.BatchOpt.RowsNumber = '2';
            obj.BatchOpt.Margin = '10';
            obj.BatchOpt.FileFormat = {'TIF'};
            obj.BatchOpt.FileFormat{2} = {'TIF', 'BMP', 'JPG', 'PNG'};
            obj.BatchOpt.TIFcompression = {'lzw'};
            obj.BatchOpt.TIFcompression{2} = {'none', 'lzw', 'packbits', 'deflate', 'jpeg', 'ccitt', 'fax3', 'fax4'};
            obj.BatchOpt.JPGmode = {'lossy'};
            obj.BatchOpt.JPGmode{2} = {'lossy', 'lossless'};
            obj.BatchOpt.JPGquality = '85';    
            % add section name and action name for the batch tool
            obj.BatchOpt.mibBatchSectionName = 'Menu -> File';
            obj.BatchOpt.mibBatchActionName = 'Make snapshot';
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Target = 'Destination target for snapshots';
            obj.BatchOpt.mibBatchTooltip.Crop = 'Crop the snapshot to ROI or the shown area';
            obj.BatchOpt.mibBatchTooltip.ROIIndex = '[ROI Crop only] index of ROI to be used for cropping';
            obj.BatchOpt.mibBatchTooltip.Width = 'Width of the output image, keep empty to match the crop parameter';
            obj.BatchOpt.mibBatchTooltip.Height = 'Height of the output image, keep empty to match the crop parameter';
            obj.BatchOpt.mibBatchTooltip.ResizeMethod = 'Method for image resizing, normally - bicubic for downsampling and nearest for upsampling';
            obj.BatchOpt.mibBatchTooltip.Scalebar = 'When checked, add a scale bar to the output image';
            obj.BatchOpt.mibBatchTooltip.Measurements = 'When checked, add measurements to the output image';
            obj.BatchOpt.mibBatchTooltip.WhiteBackground = 'When checked, use the white color for background, recommended for EM images, otherwise black - recommended for LM images';
            obj.BatchOpt.mibBatchTooltip.SplitChannels = 'When checked, make a montage image where the shown channels are split into a single images';
            obj.BatchOpt.mibBatchTooltip.Grayscale = '[Split channels only] render each channel as grayscale image, otherwise the color is defined by LUT';
            obj.BatchOpt.mibBatchTooltip.ColsNumber = '[Split channels only] number of columns in the output montage image';
            obj.BatchOpt.mibBatchTooltip.RowsNumber = '[Split channels only] number of rows in the output montage image'; 
            obj.BatchOpt.mibBatchTooltip.Margin = '[Split channels only] margin between individual panels in pixels';
            obj.BatchOpt.mibBatchTooltip.FileFormat = '[File target only] output format for snapshots';
            obj.BatchOpt.mibBatchTooltip.TIFcompression = '[TIF only] type of compression algorithm to use';
            obj.BatchOpt.mibBatchTooltip.JPGmode = '[JPG only] type of compression algorithm to use';
            obj.BatchOpt.mibBatchTooltip.JPGquality = '[JPG only] compression quality from 0 to 100';
            
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
                %useBatchMode = 1;
                obj.snapshotBtn_Callback();
                return;
            end
            
            guiName = 'mibSnapshotGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.updateWidgets();
            
            % load bitmap data and character table for the scale bars
            %obj.textCharactersBase = uint8(1 - logical(imread('chars.bmp')));
            %obj.textCharactersTable = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890''?!"?$%&/()=?^?+???,.-<\|;:_>????*@#[]{} ';
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'updateROI', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
        end
        
        function closeWindow(obj)
            % closing mibSnapshotController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete mibSnapshotController window
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
            % function updateWidgets(obj, colorChannelSelection)
            % update widgets of the window
            
            if ~isempty(obj.extraController)
                obj.View.handles.FullImage.Enable = 'off';
                obj.View.handles.ShownArea.Enable = 'off';
                obj.View.handles.ROI.Enable = 'off';
                obj.View.handles.SplitChannels.Enable = 'off';
                obj.View.handles.Measurements.Enable = 'off';
                obj.View.handles.WhiteBackground.Enable = 'off';
            end
            
            if isempty(obj.snapshotFilename{obj.mibModel.Id})
                filename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
                [path, fname] = fileparts(filename);
                if isempty(path); path = obj.mibModel.myPath; end
                formatList = obj.View.handles.FileFormat.String;
                ext = ['.' lower(formatList{obj.View.handles.FileFormat.Value})];
                fname = [fname, '_snapshot'];
                obj.snapshotFilename{obj.mibModel.Id} = fullfile(path, [fname ext]);
            end
            filename = obj.snapshotFilename{obj.mibModel.Id};
            [~, ~, ext] = fileparts(filename);
            
            if strcmp(ext(2:end), 'tif')
                obj.View.handles.FileFormat.Value = 4;
            elseif strcmp(ext(2:end), 'png')
                obj.View.handles.FileFormat.Value = 3;
            elseif strcmp(ext(2:end), 'jpg')
                obj.View.handles.FileFormat.Value = 2;
            elseif strcmp(ext(2:end), 'bmp')
                obj.View.handles.FileFormat.Value = 1;
            end
            obj.FileFormat_Callback();
            
            obj.updateWidthHeight();
            
            % update split color channels
            if obj.mibModel.getImageProperty('colors') > 1
                obj.View.handles.SplitChannels.Enable = 'on';
            else
                obj.View.handles.SplitChannels.Enable = 'off';
                obj.View.handles.SplitChannels.Value = 0;
            end
            obj.SplitChannels_Callback();
            
            [number, indices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI();
            if number == 0
                obj.View.handles.ROI.Enable = 'off';
                obj.View.handles.ROIIndex.Enable = 'off';
                if obj.View.handles.ROI.Value
                    obj.View.handles.FullImage.Value = 1;
                end
            else
                obj.View.handles.ROI.Enable = 'on';
                obj.View.handles.ROIIndex.Enable = 'on';
                
                str2 = cell([number 1]);
                for i=1:number
                    str2(i) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(indices(i)).label;
                end
                if numel(str2) < numel(obj.View.handles.ROIIndex.String)
                    obj.View.handles.ROIIndex.Value = 1;
                end
                obj.View.handles.ROIIndex.String = str2;
            end
        end
        
        function updateWidthHeight(obj)
            % function updateWidthHeight(obj)
            % update width/height for the snapshot
            
            if isempty(obj.extraController)
                options.blockModeSwitch = obj.View.handles.ShownArea.Value;
                [height, width] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', NaN, NaN, options);
                obj.origWidth = width;
                orientation = obj.mibModel.getImageProperty('orientation');
                pixSize = obj.mibModel.getImageProperty('pixSize');
                if orientation == 1
                    width = width*pixSize.z/pixSize.x;
                elseif orientation == 2
                    width = width*pixSize.z/pixSize.y;
                elseif orientation == 4
                    width = width*pixSize.x/pixSize.y;
                end
                width = ceil(width);
            else
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    curUnits = obj.extraController.View.handles.volViewPanel.Units;
                    obj.extraController.View.handles.volViewPanel.Units = 'pixels';
                    height = ceil(obj.extraController.View.handles.volViewPanel.Position(4));
                    width = ceil(obj.extraController.View.handles.volViewPanel.Position(3));
                    obj.extraController.View.handles.volViewPanel.Units = curUnits;
                    obj.origWidth = width;
                end
            end
            obj.View.handles.Width.String = num2str(width);
            obj.View.handles.Height.String = num2str(height);
            obj.origHeight = height;
            obj.resizedWidth = width;
        end
        
        function ROIIndex_Callback(obj)
            % function ROIIndex_Callback(obj)
            % update shown roi
            val = obj.View.handles.ROIIndex.Value;
            obj.mibModel.I{obj.mibModel.Id}.selectedROI = val;
            notify(obj.mibModel, 'updateId');
            notify(obj.mibModel, 'plotImage');
            obj.crop_Callback();
        end
        
        function FileFormat_Callback(obj)
            % function FileFormat_Callback(obj)
            % a callback for selection of the output format
            value = obj.View.handles.FileFormat.Value;
            obj.View.handles.tifPanel.Visible = 'off';
            obj.View.handles.jpgPanel.Visible = 'off';
            obj.View.handles.bmpPanel.Visible = 'off';
            obj.View.handles.pngPanel.Visible = 'off';
            
            fn = obj.snapshotFilename{obj.mibModel.Id};
            [path, fn, ~] = fileparts(fn);
            if value == 1
                obj.View.handles.bmpPanel.Visible = 'on';
                fn = fullfile(path, [fn '.bmp']);
            elseif value == 2
                obj.View.handles.jpgPanel.Visible = 'on';
                fn = fullfile(path, [fn '.jpg']);
            elseif value == 3
                obj.View.handles.pngPanel.Visible = 'on';
                fn = fullfile(path, [fn '.png']);
            elseif value == 4
                obj.View.handles.tifPanel.Visible = 'on';
                fn = fullfile(path, [fn '.tif']);
            end
            obj.View.handles.outputDir.String = fn;
            obj.snapshotFilename{obj.mibModel.Id} = fn;
        end
        
        function measurementsOptions_Callback(obj)
            % function measurementsOptions_Callback(obj)
            % update visualization settings for the measurements
            obj.mibModel.I{obj.mibModel.Id}.hMeasure.setOptions();
            obj.plotImage();
        end
        
        function Scalebar_Callback(obj)
            % function Scalebar_Callback(obj)
            % enable the scale bar and check of pixel size
            if obj.View.handles.Scalebar.Value == 1
                obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution();
            end
        end
        
        function crop_Callback(obj)
            % function crop_Callback(obj)
            % a callback for the Crop radio buttons
            %
            
            switch obj.BatchOpt.Crop{1}
                case 'FullImage'
                    options.blockModeSwitch = 0;
                case 'ShownArea'
                    options.blockModeSwitch = 1;
                case 'ROI'
                    options.blockModeSwitch = 0;
            end
            
            if strcmp(obj.BatchOpt.Crop{1}, 'ROI')
                roiList = obj.View.handles.ROIIndex.String;
                %roiIndex = str2double(obj.BatchOpt.ROIIndex{1});
                roiImg = obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(roiList{obj.View.handles.ROIIndex.Value});
                STATS = regionprops(roiImg, 'BoundingBox');
                width =  ceil(STATS.BoundingBox(3));
                height =  ceil(STATS.BoundingBox(4));
            else
                [height, width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, options);
            end
            
            obj.origWidth = width;
            obj.View.handles.Height.String = num2str(height);
            orientation = obj.mibModel.getImageProperty('orientation');
            pixSize = obj.mibModel.getImageProperty('pixSize');
            if orientation == 1
                width = width*pixSize.z/pixSize.x;
            elseif orientation == 2
                width = width*pixSize.z/pixSize.y;
            elseif orientation == 4
                width = width*pixSize.x/pixSize.y;
            end
            obj.View.handles.Width.String = num2str(ceil(width));
            obj.origHeight = height;
            obj.resizedWidth = width;
        end
        
        function SplitChannels_Callback(obj)
            % --- Executes on button press in SplitChannels.
            if obj.View.handles.SplitChannels.Value == 1
                obj.View.handles.Grayscale.Enable = 'on';
                obj.View.handles.ColsNumber.Enable = 'on';
                obj.View.handles.RowsNumber.Enable = 'on';
                obj.View.handles.Margin.Enable = 'on';
            else
                obj.View.handles.Grayscale.Enable = 'off';
                obj.View.handles.ColsNumber.Enable = 'off';
                obj.View.handles.RowsNumber.Enable = 'off';
                obj.View.handles.Margin.Enable = 'off';
            end
        end
        
        function outputDir_Callback(obj)
            % function outputDir_Callback(obj)
            % a callback for selection of the output file
            
            fn = obj.View.handles.outputDir.String;
            [~, ~, ext] = fileparts(fn);
            if isempty(ext)
                formatsList= obj.View.handles.FileFormat.String;
                formatOut= lower(formatsList{obj.View.handles.FileFormat.Value});
                fn = strcat(fn, '.', formatOut);
                obj.View.handles.outputDir.String = fn;
            end
            if isequal(fn, 0)
                obj.View.handles.outputDir.String = obj.snapshotFilename{obj.mibModel.Id};
                return;
            end
            
            if exist(fn, 'file')
                button = questdlg(sprintf('Warning!\nThe file already exist!\n\nOverwrite?'),...
                    'Overwrite?','Cancel','Overwrite','Cancel');
                if strcmp(button, 'Cancel'); return; end
            end
            obj.snapshotFilename{obj.mibModel.Id} = fn;
        end
        
        function selectFileBtn_Callback(obj)
            % function selectFileBtn_Callback(obj)
            % a callback for the select file button
            
            formatValue = obj.View.handles.FileFormat.Value;
            if formatValue == 1
                formatText = {'*.bmp', 'Windows Bitmap (*.bmp)'};
            elseif formatValue == 2
                formatText = {'*.jpg', 'JPG format (*.jpg)'};
            elseif    formatValue == 3
                formatText = {'*.png', 'PNG format (*.png)'};
            elseif    formatValue == 4
                formatText = {'*.tif', 'TIF format (*.tif)'};    
            end
            
            [FileName, PathName, FilterIndex] = ...
                uiputfile(formatText, 'Select filename', obj.snapshotFilename{obj.mibModel.Id});
            if isequal(FileName,0) || isequal(PathName,0); return; end
            
            obj.snapshotFilename{obj.mibModel.Id} = fullfile(PathName, FileName);
            obj.View.handles.outputDir.String = obj.snapshotFilename{obj.mibModel.Id};
        end
        
        function Width_Callback(obj)
            % function Width_Callback(obj)
            % a callback on change of obj.View.handles.Width
            newWidth = str2double(obj.View.handles.Width.String);            
            if isempty(obj.extraController)
                ratio = obj.origHeight/obj.resizedWidth;
                newHeight = round(newWidth*ratio);    
                obj.View.handles.Height.String = num2str(newHeight);
            else
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    screensize = get(groot, 'Screensize');
                    if screensize(3) < newWidth
                        warndlg(sprintf('!!! Warning !!!\n\nThe output dimensions should be smaller than the screen size!'), 'Size is too large','modal');
                        obj.View.handles.Width.String = num2str(obj.resizedWidth);
                        return;
                    end
                end
            end
        end
   
        function Height_Callback(obj)
            % function Height_Callback(obj)
            % a callback on change of obj.View.handles.Height
            
            newHeight = str2double(obj.View.handles.Height.String);
            if isempty(obj.extraController)
                ratio = obj.origHeight/obj.resizedWidth;
                newWidth = round(newHeight/ratio);
                obj.View.handles.Width.String = num2str(newWidth);
            else
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    screensize = get(groot, 'Screensize');
                    if screensize(4) < newHeight
                        warndlg(sprintf('!!! Warning !!!\n\nThe output dimensions should be smaller than the screen size!'), 'Size is too large','modal');
                        obj.View.handles.Height.String = num2str(obj.origHeight);
                        return;
                    end
                end
            end
        end
        
        function snapshotBtn_Callback(obj, useBatchMode)
            % function snapshotBtn_Callback(obj, useBatchMode)
            % make snapshot
            % Parameters:
            % useBatchMode: a logical switch indicating that the snapshot started in the batch mode
            
            if nargin < 2;  useBatchMode = 0; end
            if useBatchMode == 0
                obj.View.handles.snapshotBtn.BackgroundColor = 'r';
                drawnow;
            end
            
            if obj.View.handles.WhiteBackground.Value == 1
                bgColor = 1;
            else
                bgColor = 0;
            end
                
            options.resize = 'no';
            options.mode = 'full';
            options.markerType = 'both';
            if obj.View.handles.ShownArea.Value   % saving only the shown area
                options.blockModeSwitch = 1;
                options.mode = 'shown';
            elseif obj.View.handles.ROI.Value 
                options.blockModeSwitch = obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch;
            end
            
            slices = obj.mibModel.getImageProperty('slices');
            if obj.View.handles.SplitChannels.Value    % split color channels of the output image
                rowNo = str2double(obj.View.handles.RowsNumber.String);
                colNo = str2double(obj.View.handles.ColsNumber.String);
                if numel(slices{3})+1 > rowNo*colNo
                    warndlg(sprintf('!!! Warning !!!\n\nNumber of selected color channels is larger than the number of panels in the resulting image!\nIncrease number of columns or rows and try again'),'Too many color channels');
                    return;
                end
                maxImageIndex = min([numel(slices{3})+1 rowNo*colNo]);
                imageShift = str2double(obj.View.handles.Margin.String);    % shift between panels
            else
                rowNo = 1;
                colNo = 1;
                maxImageIndex = 1;
            end
            
            newWidth = str2double(obj.View.handles.Width.String);
            newHeight = str2double(obj.View.handles.Height.String);
            colorChannels = slices{3};    % store selected color channels
            
            wb = waitbar(0, sprintf('Generating images\nPlease wait...'),'Name', 'Making snapshot');
            
            if isempty(obj.extraController)     % snapshot from MIB main window
                for imageId = 1:maxImageIndex
                    if imageId == maxImageIndex
                        %set(handles.h.lutCheckbox, 'value', lutCheckBox);
                        %handles.h.Img{handles.h.Id}.I.slices{3} = colorChannels;
                        if isfield(options, 'useLut'); options = rmfield(options, 'useLut'); end
                        
                        if obj.mibModel.I{obj.mibModel.Id}.volren.show == 0
                            img = obj.mibModel.getRGBimage(options);
                        else
                            volrenOpt.ImageSize = [newHeight, newWidth];
                            scaleRatio = 1/obj.mibModel.getImageProperty('magFactor');
                            S = makehgtform('scale', 1/scaleRatio);
                            volren = obj.mibModel.getImageProperty('volren');
                            volrenOpt.Mview = S * volren.viewer_matrix;
                            
                            %             target=bsxfun(@plus,volrenOpt.Mview(1:3,1:3), volrenOpt.Mview(1:3,end));
                            %             source=eye(3);
                            %             E=absor(source, target, 'doScale', 0);
                            %             R = E.R;
                            %             x = radtodeg(atan2(R(3,2), R(3,3)));
                            %             y = radtodeg(atan2(-R(3,1), sqrt(R(3,2)*R(3,2) + R(3,3)*R(3,3))));
                            %             z = radtodeg(atan2(R(2,1), R(1,1)));
                            %             z = mod(z, 90);
                            %             shiftX1 = newWidth*cosd(z);
                            %             shiftX2 = newHeight*sind(z);
                            %             shiftY1 = newHeight*sind(z);
                            %             shiftY2 = newWidth*cosd(z);
                            %             volrenOpt.ImageSize = [round(shiftY1+shiftY2)*1.2, round(shiftX1+shiftX2)*1.2];
                            %
                            timePoint = slices{5}(1);
                            img = obj.mibModel.getRGBvolume(cell2mat(obj.mibModel.getData3D('image', timePoint, 4, 0)), volrenOpt);
                        end
                    else
                        if obj.View.handles.Grayscale.Value == 1
                            options.useLut = 0;
                        end
                        
                        obj.mibModel.I{obj.mibModel.Id}.slices{3} = colorChannels(imageId);
                        img = obj.mibModel.getRGBimage(options);
                    end
                    
                    obj.mibModel.I{obj.mibModel.Id}.slices{3} = colorChannels;
                    
                    if obj.View.handles.Measurements.Value
                        hFig = figure(153);
                        hFig.Renderer = 'zbuffer';
                        clf;
                        warning('off','images:initSize:adjustingMag');
                        warning('off','MATLAB:print:DeprecateZbuffer');
                        
                        imshow(img);
                        hold on;
                        obj.mibModel.I{obj.mibModel.Id}.hMeasure.addMeasurementsToPlot(obj.mibModel, options.mode, gca);
                        set(gca, 'xtick', []);
                        set(gca, 'ytick', []);
                        % export to img
                        img2 = export_fig('-native','-zbuffer','-a1');
                        
                        delete(153);
                        warning('on','images:initSize:adjustingMag');
                        warning('on','MATLAB:print:DeprecateZbuffer');
                        % crop the frame
                        %                     if verLessThan('matlab', '8.4') % obj.mibController.matlabVersion < 8.4
                        %                         img2 = img2(2:end-1, 2:end-1, :);
                        %                     end
                        % the resulting image is few pixels larger than the original one
                        img = imresize(img2, [size(img,1) size(img,2)], 'nearest');
                    end
                    
                    if obj.View.handles.ROI.Value
                        roiList = obj.View.handles.ROIIndex.String;
                        roiImg = obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(roiList{obj.View.handles.ROIIndex.Value});
                        STATS = regionprops(roiImg, 'BoundingBox');
                        img = imcrop(img, STATS.BoundingBox);
                    end
                    
                    scale = newWidth/size(img, 2);
                    if newWidth ~= obj.origWidth || newHeight ~= obj.origHeight   % resize the image
                        methodVal = obj.View.handles.ResizeMethod.Value;
                        methodList = obj.View.handles.ResizeMethod.String;
                        img = imresize(img, [newHeight newWidth], methodList{methodVal});
                    end
                    
                    if obj.View.handles.Scalebar.Value  % add scale bar
                        scalebarOptions.orientation = obj.mibModel.I{obj.mibModel.Id}.orientation;
                        scalebarOptions.bgColor = bgColor;
                        img = mibAddScaleBar(img, obj.mibModel.I{obj.mibModel.Id}.pixSize, scale, scalebarOptions);
                    end
                    
                    if maxImageIndex == 1
                        imgOut = img;
                    else
                        if imageId == 1
                            outH = size(img, 1);
                            outW = size(img, 2);
                            colId = 1;
                            rowId = 1;
                            max_int = double(intmax(class(img)));
                            bgColor2 = bgColor*max_int;
                            imgOut = zeros([outH*rowNo + (rowNo-1)*imageShift, outW*colNo + (colNo-1)*imageShift, size(img, 3)], class(img)) + bgColor2; %#ok<ZEROLIKE>
                        end
                        
                        y1 = (rowId-1)*outH+1 + imageShift*(rowId-1);
                        y2 = y1 + outH - 1;
                        x1 = (colId-1)*outW+1 + imageShift*(colId-1);
                        x2 = x1 + outW - 1;
                        imgOut(y1:y2,x1:x2,:) = img;
                        colId = colId + 1;
                        if colId > colNo
                            colId = 1;
                            rowId = rowId + 1;
                        end
                    end
                    waitbar(imageId/maxImageIndex, wb);
                end
            else
                maxImageIndex = 1;
                imageId = 1;
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    imgOut = obj.extraController.grabFrame(newWidth, newHeight);
                end
            end
            
            if obj.View.handles.File.Value     % saving to a file
                if exist(obj.snapshotFilename{obj.mibModel.Id}, 'file')
                    button = questdlg(sprintf('Warning!\nThe file already exist!\n\nOverwrite?'),...
                        'Overwrite?','Overwrite','Cancel','Cancel');
                    if strcmp(button, 'Cancel'); obj.View.handles.snapshotBtn.BackgroundColor = 'g'; return; end
                end
                
                formatId = obj.View.handles.FileFormat.Value;
                if formatId == 1 % bmp
                    parameters = struct();
                    if isa(imgOut, 'uint8') == 0    % convert to 8bit
                        imgOut = im2uint8(imgOut);
                    end
                elseif formatId == 2 % jpg
                    if isa(imgOut, 'uint8') == 0    % convert to 8bit
                        imgOut = im2uint8(imgOut);
                    end
                    parameters.Quality = str2double(obj.View.handles.JPGquality.String);
                    parameters.Bitdepth = str2double(obj.View.handles.jpgBitdepth.String);
                    val = obj.View.handles.JPGmode.Value;
                    list = obj.View.handles.JPGmode.String;
                    parameters.Mode = list{val};
                    parameters.Comment = obj.View.handles.jpgComment.String;
                elseif formatId == 3 % png
                    parameters.BitDepth = 8;
                elseif formatId == 4 % tif
                    val = obj.View.handles.TIFcompression.Value;
                    list = obj.View.handles.TIFcompression.String;
                    parameters.Compression = list{val};
                    val = obj.View.handles.tifColor.Value;
                    list = obj.View.handles.tifColor.String;
                    parameters.ColorSpace = list{val};
                    parameters.Resolution = str2double(obj.View.handles.tifResolution.String);
                    parameters.RowsPerStrip = str2double(obj.View.handles.tifRowsPerStrip.String);
                    parameters.Description = obj.View.handles.tifDescription.String;
                    parameters.WriteMode = 'overwrite';
                end
                
                mibImWrite(imgOut, obj.snapshotFilename{obj.mibModel.Id}, parameters);
            elseif obj.View.handles.Clipboard.Value  % copy to Clipboard
                waitbar(imageId/maxImageIndex, wb, sprintf('Exporting to clipboard\nPlease wait...'));
                imclipboard('copy', imgOut);
            end
            delete(wb);
            
            obj.View.handles.snapshotBtn.BackgroundColor = 'g';
        end
        
    end
end