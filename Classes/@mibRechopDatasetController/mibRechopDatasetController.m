classdef mibRechopDatasetController < handle
    % classdef mibRechopDatasetController < handle
    % a controller class for re-chopping several small datasets into a
    % single one
    
    % Copyright (C) 16.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    % Updates:
    % 10.12.2018, added fusing of annotations together with models
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        filenames
        % list of files to rechop
        outputDir
        % output directory for export
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibRechopDatasetController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibRechopDatasetGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.updateWidgets();
        end
        
        function closeWindow(obj)
            % closing mibRechopDatasetController  window
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
            % set default directory for the import
            obj.outputDir = obj.mibModel.myPath;
            obj.filenames = [];     % list of selected files
        end
        
        function selectFilesBtn_Callback(obj)
            % function selectDirBtn_Callback(obj)
            % callback for obj.View.handles.selectFilesBtn select files
            % for the import
            
            imgSw = obj.View.handles.imagesCheck.Value;
            modelSw = obj.View.handles.modelsCheck.Value;
            maskSw = obj.View.handles.masksCheck.Value;
            
            if imgSw == 0 && modelSw == 0 && maskSw == 0
                errordlg('Please select type of the layer to combine and try again!', 'Missing the layers');
                return;
            end
            
            if imgSw == 1 && (modelSw == 1 || maskSw == 1)
                button = questdlg(sprintf('!!! Attention !!!\n\nPlease select only image files\nDo not select model nor mask files!'),...
                    'Attention!', 'Continue', 'Cancel', 'Continue');
                if strcmp(button, 'Cancel'); return; end
            end
            
            if imgSw == 1
                fileFormats = {'*.am;',  'Amira mesh binary (*.am)'; ...
                    '*.nrrd;',  'NRRD for 3D Slicer (*.nrrd)'; ...
                    '*.tif;',  'TIF format (*.tif)'; ...
                    '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
                    '*.*',  'All Files (*.*)'};
            else
                if maskSw == 1
                    fileFormats = {'*.mask',  'Masks (*.mask)'; ...
                        '*.*',  'All Files (*.*)'};
                elseif modelSw == 1
                    val = obj.View.handles.modelsFormatPopup.Value;
                    switch val
                        case 1
                            fileFormats = {'*.model',  'Matlab format (*.model)'};
                        case 2
                            fileFormats = {'*.mat',  'Matlab format (*.mat)'};
                        case 3
                            fileFormats = {'*.am;',  'Amira mesh binary (*.am)'};
                        case 4
                            fileFormats = {'*.nrrd;',  'NRRD for 3D Slicer (*.nrrd)'};
                        case 5
                            fileFormats = {'*.tif;',  'TIF format (*.tif)'};
                        case 6
                            fileFormats = {'*.xml',   'Hierarchical Data Format with XML header (*.xml)'};
                    end
                end
            end
            
            [FileName, PathName, FilterIndex] = uigetfile(fileFormats,'Select chopped files', obj.outputDir, 'MultiSelect', 'on');
            if isequal(FileName,0);    return;  end
            obj.View.handles.selectedFilesList.String = FileName;
            obj.filenames = fullfile(PathName, FileName);
            
            if ischar(obj.filenames)
                obj.filenames = cellstr(obj.filenames);
            end
        end
        
        function combineBtn_Callback(obj)
            % function combineBtn_Callback(obj)
            % rechop the dataset
            
            imgSw = obj.View.handles.imagesCheck.Value;
            modelSw = obj.View.handles.modelsCheck.Value;
            maskSw = obj.View.handles.masksCheck.Value;
            
            if imgSw == 0 && modelSw == 0 && maskSw == 0
                errordlg('Please select type of the layer to combine and try again!','Missing the layers');
                return;
            end
            
            no_files = numel(obj.filenames);
            if no_files < 1
                errordlg('Please select the files and try again!', 'Missing the files');
                return;
            end
            
            % get extension for the models
            %if imgSw==0
            val = obj.View.handles.modelsFormatPopup.Value;
            switch val
                case 1
                    modelExt = '.model';
                case 2
                    modelExt = '.mat';
                case 3
                    modelExt = '.am';
                case 4
                    modelExt = '.nrrd';
                case 5
                    modelExt = '.tif';
                case 6
                    modelExt = '.xml';
            end
            
            if obj.View.handles.newRadio.Value   % generate new stack mode
                % detect grid
                Zno = zeros([no_files 1]);
                Xno = zeros([no_files 1]);
                Yno = zeros([no_files 1]);
                options.waitbar = 1;
                for fnId=1:no_files
                    [path, fn, ext] = fileparts(obj.filenames{fnId});
                    Zind = strfind(fn, 'Z');
                    Yind = strfind(fn, 'Y');
                    Xind = strfind(fn, 'X');
                    Zno(fnId) = str2double(fn(Zind(end)+1:Zind(end)+2));
                    Yno(fnId) = str2double(fn(Yind(end)+1:Yind(end)+2));
                    Xno(fnId) = str2double(fn(Xind(end)+1:Xind(end)+2));
                    if imgSw
                        [img_info{fnId}, files{fnId}, pixSize{fnId}] = mibGetImageMetadata(obj.filenames(fnId), options);
                    end
                end
                tilesZ = max(Zno);
                tilesY = max(Yno);
                tilesX = max(Xno);
                
                if imgSw    % combine images
                    % get dimensions of the output dataset
                    stacks = 0;
                    for i=1:tilesZ
                        id = find(Zno==i, 1);
                        stacks = stacks + files{id}.noLayers;
                    end
                    height = 0;
                    for i=1:tilesY
                        id = find(Yno==i, 1);
                        height = height + files{id}.height;
                    end
                    width = 0;
                    for i=1:tilesX
                        id = find(Xno==i, 1);
                        width = width + files{id}.width;
                    end
                    
                    % get the step size
                    yStep = files{find(Yno==1, 1)}.height;
                    xStep = files{find(Xno==1, 1)}.width;
                    zStep = files{find(Zno==1, 1)}.noLayers;
                    
                    imgOut = zeros([height, width, files{1}.color, stacks], files{1}.imgClass);
                    
                    for fnId=1:no_files
                        [img, img_info{fnId}] = mibGetImages(files{fnId}, img_info{fnId});
                        
                        yMin = (Yno(fnId)-1)*yStep+1;
                        yMax = min([(Yno(fnId)-1)*yStep+yStep, height]);
                        xMin = (Xno(fnId)-1)*xStep+1;
                        xMax = min([(Xno(fnId)-1)*xStep+xStep, width]);
                        zMin = (Zno(fnId)-1)*zStep+1;
                        zMax = min([(Zno(fnId)-1)*zStep+zStep, stacks]);
                        
                        imgOut(yMin:yMax, xMin:xMax, :, zMin:zMax) = img;
                    end
                    
                    % update img_info
                    img_info{1}('Height') = height;
                    img_info{1}('Width') = width;
                    img_info{1}('Depth') = stacks;
                    
                    mibImageOptions = struct();
                    mibImageOptions.modelType = obj.mibModel.I{obj.mibModel.Id}.modelType;
                    obj.mibModel.I{obj.mibModel.Id} = mibImage(imgOut, img_info{1}, mibImageOptions);
                    
                    % update the bounding box
                    bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                    bb(2) = bb(1) + (width-1)*pixSize{1}.x;
                    bb(4) = bb(3) + (height-1)*pixSize{1}.y;
                    bb(6) = bb(5) + (stacks-1)*pixSize{1}.z;
                    
                    obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(bb);
                end
                
                height = obj.mibModel.I{obj.mibModel.Id}.height;
                width = obj.mibModel.I{obj.mibModel.Id}.width;
                stacks = obj.mibModel.I{obj.mibModel.Id}.depth;
                
                if modelSw    % combine models
                    wb = waitbar(0, 'Combining the models');
                    obj.mibModel.I{obj.mibModel.Id}.createModel();
                    imgOut = zeros([height, width, stacks], 'uint8');
                    modelMaterialNames = cellstr('');
                    for fnId=1:no_files
                        [path, fn, ext] = fileparts(obj.filenames{fnId});
                        if isempty(strfind(fn, 'Labels'))
                            fn = fullfile(path, ['Labels_' fn modelExt]);     % Add Labels_ to the filename and change extension
                        else
                            fn = fullfile(path, [fn modelExt]);     % change extension
                        end
                        
                        % load models
                        if exist(fn, 'file') == 0
                            errordlg(sprintf('!!! Error !!!\n\nThe file for the Model:\n%s\nwas not found!\nPlease check the filenames or unselect the Models checkbox!', fn),'Missing the model files');
                            delete(wb);
                            return;
                        end
                        R = obj.loadModels(fn);
                        obj.mibModel.I{obj.mibModel.Id}.modelFilename = fn;
                        obj.mibModel.I{obj.mibModel.Id}.modelVariable = 'mibModel';
                        
                        if isfield(R, 'modelMaterialNames')
                            if numel(R.modelMaterialNames) > numel(modelMaterialNames)
                                modelMaterialNames = R.modelMaterialNames;
                            end
                        elseif isfield(R, 'material_list')
                            if numel(R.material_list) > numel(modelMaterialNames)
                                modelMaterialNames = R.material_list;
                            end
                        end
                        
                        if isfield(R, 'modelMaterialColors')
                            if fnId == 1
                                modelMaterialColors = R.modelMaterialColors;
                                imgDim = size(R.imOut);
                            elseif size(R.modelMaterialColors,1) > size(modelMaterialColors, 1)
                                modelMaterialColors = R.modelMaterialColors;
                            end
                        elseif isfield(R, 'color_list')
                            if fnId == 1
                                modelMaterialColors = R.color_list;
                                imgDim = size(R.imOut);
                            elseif size(R.color_list,1) > size(modelMaterialColors, 1)
                                modelMaterialColors = R.color_list;
                            end
                        end
                        
                        yMin = (Yno(fnId)-1)*imgDim(1)+1;
                        yMax = min([(Yno(fnId)-1)*imgDim(1)+imgDim(1), height]);
                        xMin = (Xno(fnId)-1)*imgDim(2)+1;
                        xMax = min([(Xno(fnId)-1)*imgDim(2)+imgDim(2), width]);
                        zMin = (Zno(fnId)-1)*imgDim(3)+1;
                        zMax = min([(Zno(fnId)-1)*imgDim(3)+imgDim(3), stacks]);
                        
                        imgOut(yMin:yMax, xMin:xMax, zMin:zMax) = R.imOut;
                        waitbar(fnId/no_files, wb);
                    end
                    opt.blockModeSwitch = 0;
                    obj.mibModel.setData3D('model', {imgOut}, NaN, 4, NaN, opt);
                    delete(wb);
                end
                
                if maskSw    % combine masks
                    wb = waitbar(0, 'Combining the masks');
                    obj.mibModel.I{obj.mibModel.Id}.clearMask();
                    obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
                    imgOut = zeros([height, width, stacks], 'uint8');
                    
                    for fnId=1:no_files
                        [path, fn, ext] = fileparts(obj.filenames{fnId});
                        fn = fullfile(path, ['Mask_' fn '.mask']);     % Change extension
                        if exist(fn, 'file') == 0
                            errordlg(sprintf('!!! Error !!!\n\nThe file for the Mask:\n%s\nwas not found!\nPlease check the filenames or unselect the Masks checkbox!', fn),'Missing the mask files');
                            delete(wb);
                            return;
                        end
                        
                        R = load(fn, '-mat');
                        field_name = fieldnames(R);
                        R = R.(field_name{1});
                        
                        if fnId == 1
                            imgDim = size(R);
                        end
                        
                        yMin = (Yno(fnId)-1)*imgDim(1)+1;
                        yMax = min([(Yno(fnId)-1)*imgDim(1)+imgDim(1), height]);
                        xMin = (Xno(fnId)-1)*imgDim(2)+1;
                        xMax = min([(Xno(fnId)-1)*imgDim(2)+imgDim(2), width]);
                        zMin = (Zno(fnId)-1)*imgDim(3)+1;
                        zMax = min([(Zno(fnId)-1)*imgDim(3)+imgDim(3), stacks]);
                        
                        imgOut(yMin:yMax, xMin:xMax, zMin:zMax) = R;
                        waitbar(fnId/no_files, wb);
                    end
                    opt.blockModeSwitch = 0;
                    obj.mibModel.setData3D('mask', {imgOut}, NaN, 4, NaN, opt);
                    delete(wb);
                end
            else                                % fuse to existing
                if maskSw == 1 && modelSw == 0 && imgSw == 0
                    errordlg('The fusing mode is implemented only for the images and models that have the Bounding Box information!','Missing the images');
                    return;
                end
                
                xOffset = ceil(str2double(obj.View.handles.xOffsetEdit.String));
                yOffset = ceil(str2double(obj.View.handles.yOffsetEdit.String));
                zOffset = ceil(str2double(obj.View.handles.zOffsetEdit.String));
                
                if imgSw == 0 && modelSw == 1
                    wb = waitbar(0, 'Backing up the model');
                    obj.mibModel.mibDoBackup('model', 1);
                    waitbar(1, wb);
                    delete(wb);
                else
                    wb = waitbar(0, 'Backing up the image');
                    obj.mibModel.mibDoBackup('image', 1);
                    waitbar(1, wb);
                    delete(wb);
                end
                
                opt.blockModeSwitch = 0;
                options.waitbar = 0;
                
                if modelSw    % fuse into the model
                    if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
                        obj.mibModel.I{obj.mibModel.Id}.createModel();
                    end
                    modelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
                    modelMaterialColors = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors;
                end
                wb = waitbar(0, 'Please wait...', 'Name', 'Fusing the datasets');
                for fnId=1:no_files
                    if imgSw == 1
                        [img_info{fnId}, files{fnId}, pixSize{fnId}] = mibGetImageMetadata(obj.filenames(fnId), options);
                        if isKey(img_info{fnId}, 'ImageDescription') == 0
                            errordlg('In order to fuse the images the Bounding Box information should be present in the ImageDescription field!','Missing the ImageDescription');
                            return;
                        end
                        curr_text = img_info{fnId}('ImageDescription');             % get current bounding box x1,y1,z1
                        bb_info_exist = strfind(curr_text, 'BoundingBox');
                        if bb_info_exist == 0   % use information from the BoundingBox
                            errordlg('In order to fuse the images the Bounding Box information should be present in the ImageDescription field!','Missing the ImageDescription');
                            delete(wb);
                            return;
                        end
                        spaces = strfind(curr_text,' ');
                        if numel(spaces) < 7; spaces(7) = numel(curr_text); end
                        tab_pos = strfind(curr_text,sprintf('|'));
                        pos = min([spaces(7) tab_pos]);
                        bb = str2num(curr_text(spaces(1):pos-1)); %#ok<ST2NM>
                        
                        if strcmp(sprintf('%.6f',pixSize{fnId}.x), sprintf('%.6f', obj.mibModel.I{obj.mibModel.Id}.pixSize.x)) == 0 || ...
                                strcmp(sprintf('%.6f',pixSize{fnId}.y), sprintf('%.6f', obj.mibModel.I{obj.mibModel.Id}.pixSize.y)) == 0
                            errordlg(sprintf('!!! Error !!!\nPixel sizes mismatch!\n\nFilename: %s', obj.filenames{fnId}), 'Pixel sizes mismatch!');
                            delete(wb);
                            return;
                        end
                        % find shifts
                        currBB = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();    % get current Bounding Box
                        
                        x1 = max([1 ceil((bb(1)-currBB(1))/obj.mibModel.I{obj.mibModel.Id}.pixSize.x + 0.000000001)+xOffset]);    % need to add a small number due to floats
                        y1 = max([1 ceil((bb(3)-currBB(3))/obj.mibModel.I{obj.mibModel.Id}.pixSize.y + 0.000000001)+yOffset]);
                        z1 = max([1 ceil((bb(5)-currBB(5))/obj.mibModel.I{obj.mibModel.Id}.pixSize.z + 0.000000001)+zOffset]);
                        
                        if x1 < 1 || y1 < 1 || z1 < 1
                            errordlg(sprintf('!!! Error !!!\nWrong minimal coordinate of the bounding box!\n\nFilename: %s', obj.filenames{fnId}), 'Wrong bounding box!');
                            delete(wb);
                            return;
                        end
                        
                        x2 = min([x1+files{fnId}.width-1 obj.mibModel.I{obj.mibModel.Id}.width]);
                        y2 = min([y1+files{fnId}.height-1 obj.mibModel.I{obj.mibModel.Id}.height]);
                        z2 = min([z1+files{fnId}.noLayers-1 obj.mibModel.I{obj.mibModel.Id}.depth]);
                        
                        if x2 > obj.mibModel.I{obj.mibModel.Id}.width || y2 > obj.mibModel.I{obj.mibModel.Id}.height || ...
                                z2 > obj.mibModel.I{obj.mibModel.Id}.depth
                            errordlg(sprintf('!!! Error !!!\nWrong maximal coordinate of the  bounding box!\n\nFilename: %s', obj.filenames{fnId}), 'Wrong bounding box!');
                            delete(wb);
                            return;
                        end
                        
                        [img, img_info{fnId}] = mibGetImages(files{fnId}, img_info{fnId});
                        %handles.h.Img{handles.h.Id}.I.img(y1:y2, x1:x2,1:files{fnId}.color, z1:z2) = img;
                        
                        opt.x = [x1 x2];
                        opt.y = [y1 y2];
                        opt.z = [z1 z2];
                        obj.mibModel.setData3D('image', {img}, NaN, 4, NaN, opt);
                        
                        if modelSw    % fuse into the model
                            [path, fn, ext] = fileparts(obj.filenames{fnId});
                            if isempty(strfind(fn, 'Labels'))
                                fn = fullfile(path, ['Labels_' fn modelExt]);     % Add Labels_ to the filename and change extension
                            else
                                fn = fullfile(path, [fn modelExt]);     % change extension
                            end
                            
                            % load models
                            if exist(fn, 'file') == 0
                                errordlg(sprintf('!!! Error !!!\n\nThe file for the Model:\n%s\nwas not found!\nPlease check the filenames or unselect the Models checkbox!', fn),'Missing the model files');
                                delete(wb);
                                return;
                            end
                            R = obj.loadModels(fn);
                            
                            if isfield(R, 'modelMaterialNames')
                                if numel(R.modelMaterialNames) > numel(modelMaterialNames)
                                    modelMaterialNames = R.modelMaterialNames;
                                end
                            elseif isfield(R, 'material_list')
                                if numel(R.material_list) > numel(modelMaterialNames)
                                    modelMaterialNames = R.material_list;
                                end
                            end
                            
                            if isfield(R, 'modelMaterialColors')
                                if fnId == 1
                                    modelMaterialColors = R.modelMaterialColors;
                                elseif size(R.modelMaterialColors,1) > size(modelMaterialColors, 1)
                                    modelMaterialColors = R.modelMaterialColors;
                                end
                            elseif isfield(R, 'color_list')
                                if fnId == 1
                                    modelMaterialColors = R.color_list;
                                elseif size(R.color_list,1) > size(modelMaterialColors, 1)
                                    modelMaterialColors = R.color_list;
                                end
                            end
                            
                            opt.x = [x1 x2];
                            opt.y = [y1 y2];
                            opt.z = [z1 z2];
                            obj.mibModel.setData3D('model', {R.imOut}, NaN, 4, NaN, opt);
                        end
                        
                        if maskSw    % fuse into the mask
                            [path, fn, ext] = fileparts(obj.filenames{fnId});
                            fn = fullfile(path, ['Mask_' fn '.mask']);     % Change extension
                            
                            if exist(fn, 'file') == 0
                                errordlg(sprintf('!!! Error !!!\n\nThe file for the Mask:\n%s\nwas not found!\nPlease check the filenames or unselect the Masks checkbox!', fn),'Missing the mask files');
                                delete(wb);
                                return;
                            end
                            
                            R = load(fn, '-mat');
                            fieldsId = fieldnames(R);
                            opt.x = [x1 x2];
                            opt.y = [y1 y2];
                            opt.z = [z1 z2];
                            obj.mibModel.setData3D('mask', {R.(fieldsId{1})}, NaN, 4, NaN, opt);
                        end
                    elseif modelSw == 1     % get only the model, without image
                        fn = obj.filenames{fnId};
                        
                        % load models
                        R = obj.loadModels(fn);
                        
                        if isfield(R, 'modelMaterialNames')
                            if numel(R.modelMaterialNames) > numel(modelMaterialNames)
                                modelMaterialNames = R.modelMaterialNames;
                            end
                        elseif isfield(R, 'material_list')
                            if numel(R.material_list) > numel(modelMaterialNames)
                                modelMaterialNames = R.material_list;
                            end
                        end
                        
                        if isfield(R, 'modelMaterialColors')
                            if fnId == 1
                                modelMaterialColors = R.modelMaterialColors;
                                imgDim = size(R.imOut);
                            elseif size(R.modelMaterialColors,1) > size(modelMaterialColors, 1)
                                modelMaterialColors = R.modelMaterialColors;
                            end
                        elseif isfield(R, 'color_list')
                            if fnId == 1
                                modelMaterialColors = R.color_list;
                                imgDim = size(R.imOut);
                            elseif size(R.color_list,1) > size(modelMaterialColors, 1)
                                modelMaterialColors = R.color_list;
                            end
                        end
                        
                        if isfield(R, 'BoundingBox')
                            bb = R.BoundingBox;
                        elseif isfield(R, 'bounding_box')
                            bb = R.bounding_box;
                        else
                            errordlg(sprintf('!!! Error !!!\n\nThe bounding box is missing!'),'Error');
                            delete(wb);
                            return;
                        end
                        
                        % find shifts
                        currBB = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();    % get current Bounding Box
                        x1 = max([1 ceil((bb(1)-currBB(1))/obj.mibModel.I{obj.mibModel.Id}.pixSize.x + 0.000000001)+xOffset]);    % need to add a small number due to floats
                        y1 = max([1 ceil((bb(3)-currBB(3))/obj.mibModel.I{obj.mibModel.Id}.pixSize.y + 0.000000001)+yOffset]);
                        z1 = max([1 ceil((bb(5)-currBB(5))/obj.mibModel.I{obj.mibModel.Id}.pixSize.z + 0.000000001)+zOffset]);
                        
                        %x1 = max([1 ceil((bb(1)-currBB(1))/obj.mibModel.I{obj.mibModel.Id}.pixSize.x)+1]);    
                        %y1 = max([1 ceil((bb(3)-currBB(3))/obj.mibModel.I{obj.mibModel.Id}.pixSize.y)+1]);
                        %z1 = max([1 ceil((bb(5)-currBB(5))/obj.mibModel.I{obj.mibModel.Id}.pixSize.z)+1]);
                        
                        if x1 < 1 || y1 < 1 || z1 < 1
                            errordlg(sprintf('!!! Error !!!\nWrong minimal coordinate of the bounding box!\n\nFilename: %s', obj.filenames{fnId}), 'Wrong bounding box!');
                            delete(wb);
                            return;
                        end
                        
                        if isfield(R, 'modelVariable')
                            R.modelVariable = R.modelVariable;
                        elseif isfield(R, 'model_var')
                            R.modelVariable = R.model_var;
                        else
                            R.modelVariable = 'imOut';
                        end
                        
                        x2 = x1+size(R.(R.modelVariable),2)-1;
                        y2 = y1+size(R.(R.modelVariable),1)-1;
                        z2 = z1+size(R.(R.modelVariable),3)-1;
                        
                        if x2 > obj.mibModel.I{obj.mibModel.Id}.width || y2 > obj.mibModel.I{obj.mibModel.Id}.height || z2 > obj.mibModel.I{obj.mibModel.Id}.depth
                            errordlg(sprintf('!!! Error !!!\nWrong maximal coordinate of the  bounding box!\n\nFilename: %s', obj.filenames{fnId}), 'Wrong bounding box!');
                            delete(wb);
                            return;
                        end
                        
                        opt.x = [x1 x2];
                        opt.y = [y1 y2];
                        opt.z = [z1 z2];
                        obj.mibModel.setData3D('model', {R.(R.modelVariable)}, NaN, 4, NaN, opt);
                        
                        % adding annotations
                        if isfield(R, 'labelText')
                            R.labelPosition(:,1) = R.labelPosition(:,1) + z1;
                            R.labelPosition(:,2) = R.labelPosition(:,2) + x1;
                            R.labelPosition(:,3) = R.labelPosition(:,3) + y1;
                            if isfield(R, 'labelValues')    % old field name, before MIB 2.5
                                R.labelValue = R.labelValues;
                                R = rmfield(R, 'labelValues');
                            end
                            if isfield(R, 'labelValue') 
                                obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(R.labelText, R.labelPosition, R.labelValue);
                            else
                                obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(R.labelText, R.labelPosition);
                            end
                        end
                        
                        
                    end
                    
                    waitbar(fnId/no_files, wb);
                end
                delete(wb);
            end
            
            if modelSw == 1
                obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = modelMaterialNames;
                obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = modelMaterialColors;
                eventdata = ToggleEventData(1);   % show the mask
                notify(obj.mibModel, 'showModel', eventdata);
            end
            
            if maskSw == 1
                eventdata = ToggleEventData(1);   % show the mask
                notify(obj.mibModel, 'showMask', eventdata);
                obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
            end
            
            notify(obj.mibModel, 'newDataset');
            % redraw the image
            eventdata = ToggleEventData(1);
            notify(obj.mibModel, 'plotImage', eventdata);
            obj.closeWindow();
        end
        
        function R = loadModels(obj, fn)
            R = struct();
            if exist(fn, 'file') == 0
                errordlg(sprintf('!!! Error !!!\n\nThe file for the Model:\n%s\nwas not found!\nPlease check the filenames or unselect the Models checkbox!', fn),'Missing the model files');
                return;
            end
            [~, ~, modelExt] = fileparts(fn);
            
            switch modelExt
                case {'.mat', '.model'}
                    R = load(fn, '-mat');
                    if isfield(R, 'modelVariable') && ~isfield(R, 'imOut')
                        R.imOut = R.(R.modelVariable);
                        R = rmfield(R, R.modelVariable);
                        R.modelVariable = 'imOut';
                    elseif isfield(R, 'model_var') && ~isfield(R, 'imOut')
                        R.imOut = R.(R.model_var);
                        R = rmfield(R, R.model_var);
                        R.modelVariable = 'imOut';
                    end
                case '.am'
                    getMetaOpt.waitbar = 0;
                    img_info = mibGetImageMetadata({fn}, getMetaOpt);
                    keysList = keys(img_info);
                    for keyId=1:numel(keysList)
                        strfindResult = strfind(keysList{keyId}, 'Materials_');
                        if ~isempty(strfindResult)
                            % keysList{keyId} for materials returned as
                            % Materials_NAME-OF-MATERIAL_Color  - color 
                            % Materials_NAME-OF-MATERIAL_Id     - index of material
                            matName = keysList{keyId}(11:end);      % 11 due to removal of 'Materials_' text 
                            materialInfo = img_info(keysList{keyId});
                            if ~isempty(strfind(matName, 'Color')) %#ok<STREMP>
                                materialColor = str2num(materialInfo); %#ok<ST2NM>   Materials_NAME-OF-MATERIAL_Color
                                materialIndex = img_info(keysList{keyId+1});  %      Materials_NAME-OF-MATERIAL_Id
                                R.modelMaterialColors(materialIndex, :) = materialColor(1:3);
                                R.modelMaterialNames{materialIndex, :} = matName(1:end-6);
                                keyId = keyId + 1; %#ok<FXSET>
                            end
                        end
                    end
                    R.imOut = amiraLabels2bitmap(fn);
                case '.nrrd'
                    getMetaOpt.waitbar = 0;
                    img_info = mibGetImageMetadata({fn}, getMetaOpt);
                    R.imOut = nrrdLoadWithMetadata(fn);
                    R.imOut =  uint8(permute(R.imOut.data, [2 1 3]));
                case '.tif'
                    getDataOpt.bioformatsCheck = 0;
                    getDataOpt.waitbar = 1;
                    getDataOpt.id = obj.mibModel.Id;   % id of the current dataset
                    getDataOpt.BioFormatsMemoizerMemoDir = obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats
                    [R.imOut, img_info, ~] = mibLoadImages({fn}, getDataOpt);
                    R.imOut =  squeeze(R.imOut);
                case '.xml'
                    getDataOpt.bioformatsCheck = 0;
                    getDataOpt.waitbar = 0;
                    getDataOpt.id = obj.mibModel.Id;   % id of the current dataset
                    getDataOpt.BioFormatsMemoizerMemoDir = obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats
                    [R.imOut, img_info] = mibLoadImages({fn}, getDataOpt);
                    R.imOut = squeeze(R.imOut);
                    if isKey(img_info, 'modelMaterialNames')     % add list of material names
                        R.modelMaterialNames = img_info('modelMaterialNames');
                    elseif isKey(img_info, 'material_list')     % add list of material names
                        R.modelMaterialNames = img_info('material_list');
                    end
                    if isKey(img_info, 'modelMaterialColors')     % add list of colors for materials
                        R.modelMaterialColors = img_info('modelMaterialColors');
                    elseif isKey(img_info, 'color_list')     % add list of colors for materials
                        R.modelMaterialColors = img_info('color_list');
                    end
            end
            
            % get bounding box
            if exist('img_info', 'var')
                if isKey(img_info, 'ImageDescription')
                    curr_text = img_info('ImageDescription');             % get current bounding box x1,y1,z1
                    bb_info_exist = strfind(curr_text, 'BoundingBox');
                    if bb_info_exist == 1   % use information from the BoundingBox parameter for pixel sizes if it is exist
                        spaces = strfind(curr_text,' ');
                        if numel(spaces) < 7; spaces(7) = numel(curr_text); end
                        tab_pos = strfind(curr_text,sprintf('|'));
                        pos = min([spaces(7) tab_pos]);
                        R.BoundingBox = str2num(curr_text(spaces(1):pos-1)); %#ok<ST2NM>
                    end
                end
            end
            
            % generate material names and colors
            if ~isfield(R, 'modelMaterialNames')
                nMaterials = max(R.imOut(:));
                for matId = 1:nMaterials
                    R.modelMaterialNames(matId, :) = {num2str(matId)};
                    if matId <= size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors,1)
                        R.modelMaterialColors(matId, :) = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(matId,:);
                    else
                        R.modelMaterialColors(matId, :) = [rand(1) rand(1) rand(1)];
                    end
                end
            end
        end
        
    end
end