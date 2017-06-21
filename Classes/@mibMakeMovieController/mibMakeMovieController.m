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
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        movieFilename
        % a cell array {1:obj.mibModel.maxId} with filenames for saving the snapshots
        origHeight
        % a height of the image area to render
        origWidth
        % width of the image area to render
        resizedWidth
        % width of the image area to render with respect of the aspect ratio
        textCharactersBase
        % a matrix with bitmaps of characters for generation of the scale bar
        textCharactersTable
        % a matrix with list of characters for generation of the scale bar
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
        function obj = mibMakeMovieController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibMakeMovieGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view

            for i=1:obj.mibModel.maxId
                obj.movieFilename{i} = [];
            end
            
            obj.updateWidgets();
            
            % load bitmap data and character table for the scale bars
            obj.textCharactersBase = uint8(1 - logical(imread('chars.bmp')));
            obj.textCharactersTable = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890''?!"?$%&/()=?^?+???,.-<\|;:_>????*@#[]{} ';
            
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
            obj.View.handles.widthEdit.String = num2str(ceil(width));
            obj.View.handles.heightEdit.String = num2str(height);
            obj.origHeight = height;
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
                obj.mibModel.updateParameters();
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
                if strcmp(button, 'Cancel'); return; end;
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
            if isequal(FileName,0) || isequal(PathName,0); return; end;
            
            obj.movieFilename{obj.mibModel.Id} = fullfile(PathName, FileName);
            obj.View.handles.outputDir.String = obj.movieFilename{obj.mibModel.Id};
        end
        
        function widthEdit_Callback(obj)
            % function widthEdit_Callback(obj)
            % a callback on change of obj.View.handles.widthEdit
            
            newWidth = str2double(obj.View.handles.widthEdit.String);
            ratio = obj.origHeight/obj.resizedWidth;
            newHeight = round(newWidth*ratio);
            obj.View.handles.heightEdit.String = num2str(newHeight);
        end
   
        function heightEdit_Callback(obj)
            % function heightEdit_Callback(obj)
            % a callback on change of obj.View.handles.heightEdit
            
            newHeight = str2double(obj.View.handles.heightEdit.String);
            ratio = obj.origHeight/obj.resizedWidth;
            newWidth = round(newHeight/ratio);
            obj.View.handles.widthEdit.String = num2str(newWidth);
        end
        
        function firstFrameEdit_Callback(obj)
            % function firstFrameEdit_Callback(obj)
            % callback for change of obj.View.handles.firstFrameEdit
            
            val = str2double(obj.View.handles.firstFrameEdit.String);
            if isnan(val)
                obj.View.handles.firstFrameEdit.String = '1';
                return; 
            end;
            
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
            
            tic
            open(writerObj);
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
            
            index = 1;
            for frame = framePnts
                if zStackSwitch
                    options.sliceNo = frame;
                    options.t = [timePoint timePoint];
                else
                    options.sliceNo = sliceNo;
                    options.t = [frame frame];
                end
                img = obj.mibModel.getRGBimage(options);
                if obj.View.handles.roiRadio.Value
                    img = imcrop(img, STATS.BoundingBox);
                end
                
                scale = newWidth/size(img, 2);
                if newWidth ~= obj.origWidth || newHeight ~= obj.origHeight   % resize the image
                    img = imresize(img, [newHeight newWidth], methodList{methodVal});
                end
                
                % convert to uint8
                if isa(img, 'uint16')
                    img = uint8(img/255);
                end
                
                if index == 1
                    if scalebarSwitch  % add scale bar
                        img2 = mibAddScaleBar(img, obj.mibModel.I{obj.mibModel.Id}.pixSize, scale, obj.mibModel.I{obj.mibModel.Id}.orientation, obj.textCharactersBase, obj.textCharactersTable);
                        scaleBar = img2(size(img2,1)-(size(img2,1)-size(img,1)-1):size(img2,1),:,:);
                        img = img2;
                    end
                else
                    if scalebarSwitch  % add scale bar
                        img = cat(1, img, scaleBar);
                    end
                end
                writeVideo(writerObj, im2frame(img));
                if mod(frame,10)==0; waitbar(index/noFrames, wb); end;
                index = index + 1;
            end
            close(writerObj);
            toc
            
            disp(['MIB: save movie ' obj.movieFilename{obj.mibModel.Id}]);
            delete(wb);
            set(0, 'DefaulttextInterpreter', curInt);
            
            obj.View.handles.continueBtn.BackgroundColor = 'g';
            
            %[~, fn, ext] = fileparts(obj.movieFilename{obj.mibModel.Id});
            %obj.mibController.updateFilelist([fn ext]);
        end
    end
end