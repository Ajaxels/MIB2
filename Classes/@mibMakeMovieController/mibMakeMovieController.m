classdef mibMakeMovieController < handle
    % classdef mibMakeMovieController < handle
    % controller class for the render movie window available via
    % MIB->Menu->File->Make movie
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    % Updates
    % 17.01.2018, IB imporoved performance with the ROI mode
    % 16.11.2018, IB updated for making snapshots from volume viewer
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        extraController
        % an optional extra controller, used for making animations from volume rendering window
        extraOptions
        % a structure with extra options for making movies
        % .mode - a string with desired mode, 'spin' - make a spin around selected axis
        movieFilename
        % a cell array {1:obj.mibModel.maxId} with filenames for saving the snapshots
        origHeight
        % a height of the image area to render
        origWidth
        % width of the image area to render
        resizedWidth
        % width of the image area to render with respect of the aspect ratio
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
        function obj = mibMakeMovieController(varargin)
            % function obj = mibMakeMovieController(varargin)
            % constructor of the class
            % Parameters:
            % parameter 1: a handles to mibModel
            % parameter 2: [@em optional] a handle to extra controllers
            % parameter 3: [@em optional] a structure with additional parameters
            
            obj.mibModel = varargin{1};    % assign model
            if nargin < 3
                obj.extraOptions = struct();
            else
                obj.extraOptions = varargin{3};
            end
            if nargin < 2
                obj.extraController = [];
            else
                obj.extraController = varargin{2};
            end
            
            guiName = 'mibMakeMovieGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view

            for i=1:obj.mibModel.maxId
                obj.movieFilename{i} = [];
            end
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'updateROI', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
        end
        
        function closeWindow(obj)
            % closing mibMakeMovieController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete mibMakeMovieController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj, colorChannelSelection)
            % update widgets of the window
            
            % update split color channels
            if obj.mibModel.getImageProperty('colors') > 1
                obj.View.handles.splitChannelsCheck.Enable = 'on';
            else
                obj.View.handles.splitChannelsCheck.Enable = 'off';
                obj.View.handles.splitChannelsCheck.Value = 0;
            end
            
            if ~isempty(obj.extraController) % modify elements of GUI
                obj.View.handles.cropPanel.Title = 'Mode';
                %obj.View.handles.fullImageRadio.Callback = [];  % remove callback from the radio button
                if strcmp(obj.extraOptions.mode, 'animation')
                    obj.View.handles.shownAreaRadio.Value = 1;
                else
                    obj.View.handles.fullImageRadio.Value = 1;
                end
                obj.View.handles.fullImageRadio.String = 'Spin';
                obj.View.handles.shownAreaRadio.String = 'Animation';
                obj.View.handles.splitChannelsCheck.Enable = 'off';
                obj.View.handles.roiRadio.Visible = 'off';
                obj.View.handles.roiPopup.Visible = 'off';
                obj.View.handles.scalebarCheck.Enable = 'off';
                obj.View.handles.lastFrameEdit.Visible = 'off';
                obj.View.handles.firstFrameEdit.String = '360';
                obj.View.handles.framerateEdit.String = '24';
                obj.View.handles.lastFrameText.Visible = 'off';
                obj.View.handles.firstFrameText.String = 'Number of frames:';
            end
            
            if isempty(obj.movieFilename{obj.mibModel.Id})
                filename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
                [path, fname] = fileparts(filename);
                if isempty(path); path = obj.mibModel.myPath; end
                switch obj.View.handles.codecPopup.Value 
                    case 1  % Archival
                        ext = '.mj2';
                    case 2  % Motion JPEG AVI
                        ext = '.avi';
                    case 3  % Motion JPEG 2000
                        ext = '.mj2';
                    case 4  % MPEG-4
                        ext = '.mp4';
                    case 5  % Uncompressed AVI
                        ext = '.avi';
                end
                fname = [fname, '_movie'];
                obj.movieFilename{obj.mibModel.Id} = fullfile(path, [fname ext]);
            end
            
            [~, ~, ext] = fileparts(obj.movieFilename{obj.mibModel.Id});
            if strcmp(ext(2:end), 'avi')
                obj.View.handles.codecPopup.Value = 2;
            elseif strcmp(ext(2:end), 'mj2')
                obj.View.handles.codecPopup.Value = 3;
            elseif strcmp(ext(2:end), 'mp4')
                obj.View.handles.codecPopup.Value = 4;
            end
            obj.View.handles.outputDir.String = obj.movieFilename{obj.mibModel.Id};
            
            if isempty(obj.extraController)
                options.blockModeSwitch = 1;
                [height, width, ~, z] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', NaN, NaN, options);
                
                obj.View.handles.heightEdit.String = num2str(height);
                obj.View.handles.lastFrameEdit.String = num2str(z);
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
                obj.resizedWidth = width;
                
                if obj.mibModel.getImageProperty('time') > 1
                    obj.View.handles.directionPopup.Enable = 'on';
                end
                
                [number, indices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI();
                if number == 0
                    obj.View.handles.roiRadio.Enable = 'off';
                    obj.View.handles.roiPopup.Enable = 'off';
                    if obj.View.handles.roiRadio.Value
                        obj.View.handles.fullImageRadio.Value = 1;
                    end
                else
                    obj.View.handles.roiRadio.Enable = 'on';
                    obj.View.handles.roiPopup.Enable = 'on';
                    
                    str2 = cell([number 1]);
                    for i=1:number
                        str2(i) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(indices(i)).label;
                    end
                    if numel(str2) < numel(obj.View.handles.roiPopup.String)
                        obj.View.handles.roiPopup.Value = 1;
                    end
                    obj.View.handles.roiPopup.String = str2;
                end
            else
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    curUnits = obj.extraController.View.handles.volViewPanel.Units;
                    obj.extraController.View.handles.volViewPanel.Units = 'pixels';
                    height = ceil(obj.extraController.View.handles.volViewPanel.Position(4));
                    width = ceil(obj.extraController.View.handles.volViewPanel.Position(3));
                    obj.extraController.View.handles.volViewPanel.Units = curUnits;
                    obj.origWidth = width;
                    obj.resizedWidth = width;
                end
            end
            
            obj.splitChannelsCheck_Callback();
            
            obj.origHeight = height;
            obj.View.handles.widthEdit.String = num2str(ceil(width));
            obj.View.handles.heightEdit.String = num2str(height);
        end
        
        function splitChannelsCheck_Callback(obj)
            % --- Executes on button press in splitChannelsCheck.
            if obj.View.handles.splitChannelsCheck.Value == 1
                obj.View.handles.grayscaleCheck.Enable = 'on';
                obj.View.handles.colsNoEdit.Enable = 'on';
                obj.View.handles.rowNoEdit.Enable = 'on';
                obj.View.handles.marginEdit.Enable = 'on';
            else
                obj.View.handles.grayscaleCheck.Enable = 'off';
                obj.View.handles.colsNoEdit.Enable = 'off';
                obj.View.handles.rowNoEdit.Enable = 'off';
                obj.View.handles.marginEdit.Enable = 'off';
            end
        end
        
        function roiPopup_Callback(obj)
            % function roiPopup_Callback(obj)
            % update shown roi
            val = obj.View.handles.roiPopup.Value;
            obj.mibModel.I{obj.mibModel.Id}.selectedROI = val;
            notify(obj.mibModel, 'updateId');
            notify(obj.mibModel, 'plotImage');
            obj.crop_Callback();
        end
        
        function crop_Callback(obj)
            % function crop_Callback(obj)
            % callback for the Crop radio buttons
            
            if ~isempty(obj.extraController)     % making movie from the MIB image view panel
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    if obj.View.handles.fullImageRadio.Value
                        obj.extraOptions.mode = 'spin';
                    elseif obj.View.handles.shownAreaRadio.Value
                        obj.extraOptions.mode = 'animation';                        
                    end
                end
                return;
            end
            
            if obj.View.handles.fullImageRadio.Value
                options.blockModeSwitch = 0; % full image
            elseif obj.View.handles.shownAreaRadio.Value
                options.blockModeSwitch = 1; % the shown image
            elseif obj.View.handles.roiRadio.Value
                options.blockModeSwitch = 0; % full image
            else
                %hObject.Value = 1;
                %return;
            end
            
            if obj.View.handles.roiRadio.Value
                roiList = obj.View.handles.roiPopup.String;
                roiImg = obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(roiList{obj.View.handles.roiPopup.Value});
                STATS = regionprops(roiImg, 'BoundingBox');
                width =  ceil(STATS.BoundingBox(3));
                height =  ceil(STATS.BoundingBox(4));
            else
                [height, width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, options);
            end
            obj.origWidth = width;
            obj.View.handles.heightEdit.String = num2str(height);
            
            orientation = obj.mibModel.getImageProperty('orientation');
            pixSize = obj.mibModel.getImageProperty('pixSize');
            
            if orientation == 1
                width = width*pixSize.z/pixSize.x;
            elseif orientation == 2
                width = width*pixSize.z/pixSize.y;
            elseif orientation == 4
                width = width*pixSize.x/pixSize.y;
            end
            
            obj.View.handles.widthEdit.String = num2str(ceil(width));
            obj.origHeight = height;
            obj.resizedWidth = width;
        end
        
        
        function codecPopup_Callback(obj)
            % function codecPopup_Callback(obj)
            % a callback for selection of the output format
            value = obj.View.handles.codecPopup.Value;
            fn = obj.View.handles.outputDir.String;
            
            [path, fn, ~] = fileparts(fn);
            obj.View.handles.qualityEdit.Enable = 'on';
            if value == 1 || value == 3
                fn = fullfile(path, [fn '.mj2']);
                obj.View.handles.qualityEdit.Enable = 'off';
            elseif value == 4
                fn = fullfile(path, [fn '.mp4']);
            elseif value == 5   % uncomressed AVI
                fn = fullfile(path, [fn '.avi']);
                obj.View.handles.qualityEdit.Enable = 'off';
            elseif value == 2   % Motion JPEG AVI
                fn = fullfile(path, [fn '.avi']);
            end
            obj.View.handles.outputDir.String = fn;
            obj.movieFilename{obj.mibModel.Id}  = fn;
        end
        
        function scalebarCheck_Callback(obj)
            % function scalebarCheck_Callback(obj)
            % enable the scale bar and check of pixel size
            if obj.View.handles.scalebarCheck.Value == 1
                obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution();
            end
        end
        
        function outputDir_Callback(obj)
            % function outputDir_Callback(obj)
            % a callback for selection of the output file
            
            fn = obj.View.handles.outputDir.String;
            if isequal(fn, 0)
                obj.View.handles.outputDir.String = obj.movieFilename{obj.mibModel.Id};
                return;
            end
            
            if exist(fn, 'file')
                button = questdlg(sprintf('Warning!\nThe file already exist!\n\nOverwrite?'),...
                    'Overwrite?', 'Cancel', 'Overwrite', 'Cancel');
                if strcmp(button, 'Cancel'); return; end
            end
            obj.movieFilename{obj.mibModel.Id} = fn;
        end
        
        function selectFileBtn_Callback(obj)
            % function selectFileBtn_Callback(obj)
            % a callback for the select file button
            
            formatValue = obj.View.handles.codecPopup.Value;
            if formatValue == 1
                formatText = {'*.mj2', 'Motion JPEG 2000 file with lossless compression (*.mj2)'};
            elseif formatValue == 2
                formatText = {'*.avi', 'Compressed AVI file using Motion JPEG codec (*.avi)'};
            elseif    formatValue == 3
                formatText = {'*.mj2', 'Compressed Motion JPEG 2000 file (*.mj2)'};
            elseif    formatValue == 4
                formatText = {'*.mp4', 'Compressed MPEG-4 file with H.264 encoding (Windows 7 systems only) (*.mp4)'};
            elseif    formatValue == 5
                formatText = {'*.avi', 'Uncompressed AVI file with RGB24 video (*.avi)'};
            end
            
            [FileName, PathName, FilterIndex] = ...
                uiputfile(formatText, 'Select filename', obj.movieFilename{obj.mibModel.Id});
            if isequal(FileName,0) || isequal(PathName,0); return; end
            
            obj.movieFilename{obj.mibModel.Id} = fullfile(PathName, FileName);
            obj.View.handles.outputDir.String = obj.movieFilename{obj.mibModel.Id};
        end
        
        function widthEdit_Callback(obj)
            % function widthEdit_Callback(obj)
            % a callback on change of obj.View.handles.widthEdit
            
            newWidth = str2double(obj.View.handles.widthEdit.String);
            if isempty(obj.extraController)
                ratio = obj.origHeight/obj.resizedWidth;
                newHeight = round(newWidth*ratio);
                obj.View.handles.heightEdit.String = num2str(newHeight);
            else
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    screensize = get(groot, 'Screensize');
                    if screensize(3) < newWidth
                        warndlg(sprintf('!!! Warning !!!\n\nThe output dimensions should be smaller than the screen size!'), 'Size is too large','modal');
                        obj.View.handles.widthEdit.String = num2str(obj.resizedWidth);
                        return;
                    end
                end
            end
        end
   
        function heightEdit_Callback(obj)
            % function heightEdit_Callback(obj)
            % a callback on change of obj.View.handles.heightEdit
            
            newHeight = str2double(obj.View.handles.heightEdit.String);
            if isempty(obj.extraController)
                ratio = obj.origHeight/obj.resizedWidth;
                newWidth = round(newHeight/ratio);
                obj.View.handles.widthEdit.String = num2str(newWidth);
            else
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')
                    screensize = get(groot, 'Screensize');
                    if screensize(4) < newHeight
                        warndlg(sprintf('!!! Warning !!!\n\nThe output dimensions should be smaller than the screen size!'), 'Size is too large','modal');
                        obj.View.handles.heightEdit.String = num2str(obj.origHeight);
                        return;
                    end
                end
            end
        end
        
        function firstFrameEdit_Callback(obj)
            % function firstFrameEdit_Callback(obj)
            % callback for change of obj.View.handles.firstFrameEdit
            
            if ~isempty(obj.extraController); return; end
            
            val = str2double(obj.View.handles.firstFrameEdit.String);
            if isnan(val)
                obj.View.handles.firstFrameEdit.String = '1';
                return; 
            end
            
            options.blockModeSwitch = 1;
            [~, ~, ~, z] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', NaN, NaN, options);
            if val < 1 || val > z
                msgbox(sprintf('Wrong number of the starting frame\nit should be in range: %d - %d', 1, z-1), 'Error', 'error');
                obj.View.handles.firstFrameEdit.String = '1';
                return;
            end
        end
        
        function lastFrameEdit_Callback(obj)
            % function lastFrameEdit_Callback(obj)
            % callback for change of obj.View.handles.lastFrameEdit
            
            val = str2double(obj.View.handles.lastFrameEdit.String);
            options.blockModeSwitch = 1;
            [~, ~, ~, z] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', NaN, NaN, options);
            if isnan(val); obj.View.handles.lastFrameEdit.String = num2str(z); return; end;
            if val < 1 || val > z
                msgbox(sprintf('Wrong number of the last frame\nit should be in range: %d - %d', 2, z), 'Error', 'error');
                obj.View.handles.lastFrameEdit.String = num2str(z);
                return;
            end
        end
        
        function directionPopup_Callback(obj)
            % function directionPopup_Callback(obj)
            % callback for press obj.View.handles.directionPopup
            
            val = obj.View.handles.directionPopup.Value;
            if val == 1     % make video of a z-stack
                obj.View.handles.lastFrameEdit.String = num2str(handles.mibModel.getImageProperty('depth'));
            else            % make video of a time series
                obj.View.handles.lastFrameEdit.String = num2str(handles.mibModel.getImageProperty('time'));
            end
        end
        
        function continueBtn_Callback(obj)
            obj.View.handles.continueBtn.BackgroundColor = 'r';
            drawnow;
            
            codecList = obj.View.handles.codecPopup.String;
            codec = codecList{obj.View.handles.codecPopup.Value};
            quality = str2double(obj.View.handles.qualityEdit.String);
            frame_rate = str2double(obj.View.handles.framerateEdit.String);
            
            options.resize = 'no';
            options.mode = 'full';
            if obj.View.handles.shownAreaRadio.Value   % saving only the shown area
                options.blockModeSwitch = 1;
            end
            
            if obj.View.handles.whiteBgCheck.Value == 1
                bgColor = 1;
            else
                bgColor = 0;
            end
            
            if exist(obj.movieFilename{obj.mibModel.Id}, 'file')
                button = questdlg(sprintf('Warning!\nThe file already exist!\n\nOverwrite?'),...
                    'Overwrite?', 'Overwrite', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel')
                    obj.View.handles.continueBtn.BackgroundColor = 'g';
                    return;
                end
            end
            
            try
                writerObj = VideoWriter(obj.movieFilename{obj.mibModel.Id}, codec);
            catch err
                msgbox(sprintf('Can''t create the video file, it might be opened elsewhere...\n\n%s', err.identifier), 'Error!', 'error', 'modal');
                obj.View.handles.continueBtn.BackgroundColor = 'g';
                return;
            end
            
            slices = obj.mibModel.getImageProperty('slices');
            colorChannels = slices{3};    % store selected color channels
            if obj.View.handles.splitChannelsCheck.Value    % split color channels of the output image
                rowNo = str2double(obj.View.handles.rowNoEdit.String);
                colNo = str2double(obj.View.handles.colsNoEdit.String);
                if numel(slices{3})+1 > rowNo*colNo
                    warndlg(sprintf('!!! Warning !!!\n\nNumber of selected color channels is larger than the number of panels in the resulting image!\nIncrease number of columns or rows and try again'),'Too many color channels');
                    return;
                end
                maxImageIndex = min([numel(slices{3})+1 rowNo*colNo]);
                imageShift = str2double(obj.View.handles.marginEdit.String);    % shift between panels
            else
                rowNo = 1;
                colNo = 1;
                maxImageIndex = 1;
            end
            
            %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
            curInt = get(0, 'DefaulttextInterpreter');
            set(0, 'DefaulttextInterpreter', 'none');
            
            wb = waitbar(0,sprintf('%s\nPlease wait...', obj.movieFilename{obj.mibModel.Id}), ...
                'Name', 'Rendering the movie...', 'WindowStyle', 'modal');
            waitbar(0, wb);
            
            writerObj.FrameRate = frame_rate;
            if ~strcmp(codec, 'Archival') && ~strcmp(codec, 'Uncompressed AVI') && ~strcmp(codec, 'Motion JPEG 2000')
                writerObj.Quality = quality;
            end
            
            newWidth = str2double(obj.View.handles.widthEdit.String);
            newHeight = str2double(obj.View.handles.heightEdit.String);
            
            methodVal = obj.View.handles.resizeMethodPopup.Value;
            methodList = obj.View.handles.resizeMethodPopup.String;
            scalebarSwitch = obj.View.handles.scalebarCheck.Value;
            
            startPoint = str2double(obj.View.handles.firstFrameEdit.String);
            lastPoint = str2double(obj.View.handles.lastFrameEdit.String);
            
            tic
            if isempty(obj.extraController)     % making movie from the MIB image view panel
                if obj.View.handles.directionPopup.Value == 1    % z-stack
                    orientation = obj.mibModel.getImageProperty('orientation');
                    if orientation == 4
                        maxZ = obj.mibModel.getImageProperty('depth');
                    elseif orientation == 1
                        maxZ = obj.mibModel.getImageProperty('height');
                    elseif orientation == 2
                        maxZ = obj.mibModel.getImageProperty('width');
                    end
                    zStackSwitch = 1;
                    timePoint = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                else
                    maxZ =obj.mibModel.getImageProperty('time');
                    zStackSwitch = 0;
                    sliceNo = obj.mibModel.getImageMethod('getCurrentSliceNumber');
                end
                if maxZ < lastPoint
                    msgbox(sprintf('Please check the last frame number!\nIt should be not larger than %d', maxZ), 'Error!', 'error', 'modal');
                    obj.View.handles.continueBtn.BackgroundColor = 'g';
                    delete(wb);
                    return;
                end
                
                if obj.View.handles.roiRadio.Value
                    roiList = obj.View.handles.roiPopup.String;
                    roiImg = obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(roiList{obj.View.handles.roiPopup.Value});
                    STATS = regionprops(roiImg, 'BoundingBox');
                end
                options.markerType = 'both';
                
                % generate the frame indices
                framePnts = startPoint:lastPoint;
                if obj.View.handles.backandforthCheck.Value  % add reverse direction
                    framePnts = [framePnts lastPoint-1:-1:startPoint];
                end
                noFrames = numel(framePnts);
                
                if obj.View.handles.roiRadio.Value
                    %STATS.BoundingBox
                    options.x = [floor(STATS.BoundingBox(1)), floor(STATS.BoundingBox(1))+STATS.BoundingBox(3)-1];
                    options.y = [floor(STATS.BoundingBox(2)), floor(STATS.BoundingBox(2))+STATS.BoundingBox(4)-1];
                end
                
                % open the movie writer
                open(writerObj);
                
                % generating the movie
                index = 1;
                for frame = framePnts
                    if zStackSwitch
                        options.sliceNo = frame;
                        options.t = [timePoint timePoint];
                    else
                        options.sliceNo = sliceNo;
                        options.t = [frame frame];
                    end
                    
                    for imageId = 1:maxImageIndex
                        if imageId == maxImageIndex
                            if isfield(options, 'useLut'); options = rmfield(options, 'useLut'); end
                            obj.mibModel.I{obj.mibModel.Id}.slices{3} = colorChannels;
                            img = obj.mibModel.getRGBimage(options);
                        else
                            if obj.View.handles.grayscaleCheck.Value == 1
                                options.useLut = 0;
                            end
                            obj.mibModel.I{obj.mibModel.Id}.slices{3} = colorChannels(imageId);
                            img = obj.mibModel.getRGBimage(options);
                        end
                        scale = newWidth/size(img, 2);
                        if newWidth ~= obj.origWidth || newHeight ~= obj.origHeight   % resize the image
                            img = imresize(img, [newHeight newWidth], methodList{methodVal});
                        end
                        
                        % convert to uint8
                        if isa(img, 'uint16')
                            img = uint8(img/255);
                        end
                        
                        if index == 1 && imageId == 1
                            if scalebarSwitch  % add scale bar
                                scalebarOptions.bgColor = bgColor;
                                scalebarOptions.orientation = obj.mibModel.I{obj.mibModel.Id}.orientation;
                                img2 = mibAddScaleBar(img, obj.mibModel.I{obj.mibModel.Id}.pixSize, scale, scalebarOptions);
                                scaleBar = img2(size(img2,1)-(size(img2,1)-size(img,1)-1):size(img2,1),:,:);
                                img = img2;
                            end
                        else
                            if scalebarSwitch  % add scale bar
                                img = cat(1, img, scaleBar);
                            end
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
                    end
                    
                    writeVideo(writerObj, im2frame(imgOut));
                    if mod(frame,10)==0; waitbar(index/noFrames, wb); end
                    index = index + 1;
                end
                obj.mibModel.I{obj.mibModel.Id}.slices{3} = colorChannels;
            else
                if strcmp(obj.extraController.View.gui.Name, '3D rendering')    % making a movie from the volume viewer
                    % open the movie writer
                    open(writerObj);
                    
                    % generating the movie
                    index = 1;
                    noFrames = startPoint;
                    options.back_and_forth = obj.View.handles.backandforthCheck.Value;
                    switch obj.extraOptions.mode
                        case 'animation'
                            % get camera positions for the spin
                            positions = obj.extraController.generatePositionsForKeyFramesAnimation(noFrames, options);
                            % update noFrames, due to possible increase
                            % from back_and_forth option
                            noFrames = size(positions.CameraPosition,1);
                            
                            % prepare rendering window 
                            obj.extraController.prepareWindowForGrabFrame(newWidth, newHeight);
                            
                            % start the camera spin
                            grabFrameOptions.showWaitbar = 0;
                            grabFrameOptions.resizeWindow = 0;
                            for frameId = 1:noFrames
                                obj.extraController.volume.CameraPosition = positions.CameraPosition(frameId, :);
                                obj.extraController.volume.CameraUpVector = positions.CameraUpVector(frameId, :);
                                if ~isempty(positions.CameraTarget)
                                    obj.extraController.volume.CameraTarget = positions.CameraTarget(frameId, :);
                                end
                                img = obj.extraController.grabFrame(newWidth, newHeight, grabFrameOptions);
                                
                                writeVideo(writerObj, im2frame(img));
                                if mod(frameId, 10) == 0; waitbar(index/noFrames, wb); end
                                index = index + 1;
                            end
                            obj.extraController.restoreWindowAfterGrabFrame();    % restore widget size
                            
                        case 'spin'
                            % get camera positions for the spin
                            positions = obj.extraController.generatePositionsForSpinAnimation(noFrames, options);
                            
                            % update noFrames, due to possible increase
                            % from back_and_forth option
                            noFrames = size(positions.CameraPosition,1);
                            
                            % prepare rendering window 
                            obj.extraController.prepareWindowForGrabFrame(newWidth, newHeight);
                            
                            % update camera positions
                            obj.extraController.volume.CameraUpVector = positions.CameraUpVector;
                            obj.extraController.volume.CameraTarget = positions.CameraTarget;
                            
                            % start the camera spin
                            grabFrameOptions.showWaitbar = 0;
                            grabFrameOptions.resizeWindow = 0;
                            for frameId = 1:noFrames
                                obj.extraController.volume.CameraPosition = positions.CameraPosition(frameId, :);
                                img = obj.extraController.grabFrame(newWidth, newHeight, grabFrameOptions);
                                
                                writeVideo(writerObj, im2frame(img));
                                if mod(frameId, 10) == 0; waitbar(index/noFrames, wb); end
                                index = index + 1;
                            end
                            obj.extraController.restoreWindowAfterGrabFrame();    % restore widget size
                    end
                end
            end
            
            close(writerObj);
            toc
            
            disp(['MIB: movie saved, ' obj.movieFilename{obj.mibModel.Id}]);
            delete(wb);
            set(0, 'DefaulttextInterpreter', curInt);
            
            obj.View.handles.continueBtn.BackgroundColor = 'g';
            
            %[~, fn, ext] = fileparts(obj.movieFilename{obj.mibModel.Id});
            %obj.mibController.updateFilelist([fn ext]);
        end
    end
end