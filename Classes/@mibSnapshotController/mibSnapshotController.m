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
            
            guiName = 'mibSnapshotGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view

            for i=1:obj.mibModel.maxId
                obj.snapshotFilename{i} = [];
            end
            
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
        
        function updateWidgets(obj)
            % function updateWidgets(obj, colorChannelSelection)
            % update widgets of the window
            
            if ~isempty(obj.extraController)
                obj.View.handles.fullImageRadio.Enable = 'off';
                obj.View.handles.shownAreaRadio.Enable = 'off';
                obj.View.handles.roiRadio.Enable = 'off';
                obj.View.handles.splitChannelsCheck.Enable = 'off';
                obj.View.handles.measurementsCheck.Enable = 'off';
                obj.View.handles.whiteBgCheck.Enable = 'off';
            end
            
            if isempty(obj.snapshotFilename{obj.mibModel.Id})
                filename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
                [path, fname] = fileparts(filename);
                if isempty(path); path = obj.mibModel.myPath; end
                formatList = obj.View.handles.fileFormatPopup.String;
                ext = ['.' lower(formatList{obj.View.handles.fileFormatPopup.Value})];
                fname = [fname, '_snapshot'];
                obj.snapshotFilename{obj.mibModel.Id} = fullfile(path, [fname ext]);
            end
            filename = obj.snapshotFilename{obj.mibModel.Id};
            [~, ~, ext] = fileparts(filename);
            
            if strcmp(ext(2:end), 'tif')
                obj.View.handles.fileFormatPopup.Value = 3;
            elseif strcmp(ext(2:end), 'jpg')
                obj.View.handles.fileFormatPopup.Value = 2;
            elseif strcmp(ext(2:end), 'bmp')
                obj.View.handles.fileFormatPopup.Value = 1;
            end
            obj.fileFormatPopup_Callback();
            
            obj.updateWidthHeight();
            
            % update split color channels
            if obj.mibModel.getImageProperty('colors') > 1
                obj.View.handles.splitChannelsCheck.Enable = 'on';
            else
                obj.View.handles.splitChannelsCheck.Enable = 'off';
                obj.View.handles.splitChannelsCheck.Value = 0;
            end
            obj.splitChannelsCheck_Callback();
            
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
        
        function updateWidthHeight(obj)
            % function updateWidthHeight(obj)
            % update width/height for the snapshot
            
            if isempty(obj.extraController)
                options.blockModeSwitch = obj.View.handles.shownAreaRadio.Value;
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
            obj.View.handles.widthEdit.String = num2str(width);
            obj.View.handles.heightEdit.String = num2str(height);
            obj.origHeight = height;
            obj.resizedWidth = width;
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
        
        function fileFormatPopup_Callback(obj)
            % function fileFormatPopup_Callback(obj)
            % a callback for selection of the output format
            value = obj.View.handles.fileFormatPopup.Value;
            obj.View.handles.tifPanel.Visible = 'off';
            obj.View.handles.jpgPanel.Visible = 'off';
            obj.View.handles.bmpPanel.Visible = 'off';
            
            fn = obj.snapshotFilename{obj.mibModel.Id};
            [path, fn, ~] = fileparts(fn);
            if value == 1
                obj.View.handles.bmpPanel.Visible = 'on';
                fn = fullfile(path, [fn '.bmp']);
            elseif value == 2
                obj.View.handles.jpgPanel.Visible = 'on';
                fn = fullfile(path, [fn '.jpg']);
            elseif value == 3
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
        
        function scalebarCheck_Callback(obj)
            % function scalebarCheck_Callback(obj)
            % enable the scale bar and check of pixel size
            if obj.View.handles.scalebarCheck.Value == 1
                obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution();
            end
        end
        
        function crop_Callback(obj)
            % function crop_Callback(obj)
            % a callback for the Crop radio buttons
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
        
        function outputDir_Callback(obj)
            % function outputDir_Callback(obj)
            % a callback for selection of the output file
            
            fn = obj.View.handles.outputDir.String;
            [~, ~, ext] = fileparts(fn);
            if isempty(ext)
                formatsList= obj.View.handles.fileFormatPopup.String;
                formatOut= lower(formatsList{obj.View.handles.fileFormatPopup.Value});
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
            
            formatValue = obj.View.handles.fileFormatPopup.Value;
            if formatValue == 1
                formatText = {'*.bmp', 'Windows Bitmap (*.bmp)'};
            elseif formatValue == 2
                formatText = {'*.jpg', 'JPG format (*.jpg)'};
            elseif    formatValue == 3
                formatText = {'*.tif', 'TIF format (*.tif)'};
            end
            
            [FileName, PathName, FilterIndex] = ...
                uiputfile(formatText, 'Select filename', obj.snapshotFilename{obj.mibModel.Id});
            if isequal(FileName,0) || isequal(PathName,0); return; end
            
            obj.snapshotFilename{obj.mibModel.Id} = fullfile(PathName, FileName);
            obj.View.handles.outputDir.String = obj.snapshotFilename{obj.mibModel.Id};
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
        
        function snapshotBtn_Callback(obj)
            % function snapshotBtn_Callback(obj)
            % make snapshot
            
            obj.View.handles.snapshotBtn.BackgroundColor = 'r';
            drawnow;
            if obj.View.handles.whiteBgCheck.Value == 1
                bgColor = 1;
            else
                bgColor = 0;
            end
                
            options.resize = 'no';
            options.mode = 'full';
            options.markerType = 'both';
            if obj.View.handles.shownAreaRadio.Value   % saving only the shown area
                options.blockModeSwitch = 1;
                options.mode = 'shown';
            elseif obj.View.handles.roiRadio.Value 
                options.blockModeSwitch = obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch;
            end
            
            slices = obj.mibModel.getImageProperty('slices');
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
            
            newWidth = str2double(obj.View.handles.widthEdit.String);
            newHeight = str2double(obj.View.handles.heightEdit.String);
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
                        if obj.View.handles.grayscaleCheck.Value == 1
                            options.useLut = 0;
                        end
                        
                        obj.mibModel.I{obj.mibModel.Id}.slices{3} = colorChannels(imageId);
                        img = obj.mibModel.getRGBimage(options);
                    end
                    
                    obj.mibModel.I{obj.mibModel.Id}.slices{3} = colorChannels;
                    
                    if obj.View.handles.measurementsCheck.Value
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
                        %                     if obj.mibController.matlabVersion < 8.4
                        %                         img2 = img2(2:end-1, 2:end-1, :);
                        %                     end
                        % the resulting image is few pixels larger than the original one
                        img = imresize(img2, [size(img,1) size(img,2)], 'nearest');
                    end
                    
                    if obj.View.handles.roiRadio.Value
                        roiList = obj.View.handles.roiPopup.String;
                        roiImg = obj.mibModel.I{obj.mibModel.Id}.hROI.returnMask(roiList{obj.View.handles.roiPopup.Value});
                        STATS = regionprops(roiImg, 'BoundingBox');
                        img = imcrop(img, STATS.BoundingBox);
                    end
                    
                    scale = newWidth/size(img, 2);
                    if newWidth ~= obj.origWidth || newHeight ~= obj.origHeight   % resize the image
                        methodVal = obj.View.handles.resizeMethodPopup.Value;
                        methodList = obj.View.handles.resizeMethodPopup.String;
                        img = imresize(img, [newHeight newWidth], methodList{methodVal});
                    end
                    
                    if obj.View.handles.scalebarCheck.Value  % add scale bar
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
            
            if obj.View.handles.toFileRadio.Value     % saving to a file
                if exist(obj.snapshotFilename{obj.mibModel.Id}, 'file')
                    button = questdlg(sprintf('Warning!\nThe file already exist!\n\nOverwrite?'),...
                        'Overwrite?','Overwrite','Cancel','Cancel');
                    if strcmp(button, 'Cancel'); obj.View.handles.snapshotBtn.BackgroundColor = 'g'; return; end
                end
                
                formatId = obj.View.handles.fileFormatPopup.Value;
                if formatId == 1 % bmp
                    parameters = struct();
                    if isa(imgOut, 'uint8') == 0    % convert to 8bit
                        imgOut = im2uint8(imgOut);
                    end
                elseif formatId == 2 % jpg
                    if isa(imgOut, 'uint8') == 0    % convert to 8bit
                        imgOut = im2uint8(imgOut);
                    end
                    parameters.Quality = str2double(obj.View.handles.jpgQuality.String);
                    parameters.Bitdepth = str2double(obj.View.handles.jpgBitdepth.String);
                    val = obj.View.handles.jpgMode.Value;
                    list = obj.View.handles.jpgMode.String;
                    parameters.Mode = list{val};
                    parameters.Comment = obj.View.handles.jpgComment.String;
                elseif formatId == 3 % tif
                    val = obj.View.handles.tifCompression.Value;
                    list = obj.View.handles.tifCompression.String;
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
            elseif obj.View.handles.clipboardRadio.Value  % copy to Clipboard
                waitbar(imageId/maxImageIndex, wb, sprintf('Exporting to clipboard\nPlease wait...'));
                imclipboard('copy', imgOut);
            end
            delete(wb);
            
            obj.View.handles.snapshotBtn.BackgroundColor = 'g';
        end
        
    end
end