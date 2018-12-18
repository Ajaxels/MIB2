classdef mibChopDatasetController < handle
    % classdef mibChopDatasetController < handle
    % a controller class for chopping the dataset into several smaller ones
    
    % Copyright (C) 16.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        outputDir
        % output directory for export
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibChopDatasetController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibChopDatasetGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
				
			obj.updateWidgets();
        end
        
        function closeWindow(obj)
            % closing mibChopDatasetController  window
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
            % get dataset dimensions
            options.blockModeSwitch = 0;    % disable the blockmode
            [h, w, c, z] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', 4, NaN, options);
            
            obj.View.handles.textInfo.String =...
                sprintf('xmin-xmax: 1 - %d\nymin-ymax: 1 - %d\nzmin-zmax: 1 - %d\n', w, h, z);
            
            % get voxel size
            pixSize = obj.mibModel.getImageProperty('pixSize');
            pixSizeX = pixSize.x;
            pixSizeY = pixSize.y;
            pixSizeZ = pixSize.z;
            obj.View.handles.pixSizeText.String =...
                sprintf('X: %g\nY: %g\nZ: %g\n',pixSizeX, pixSizeY,pixSizeZ);
            
            % disable checkboxes, if needed
            if obj.mibModel.getImageProperty('modelExist') == 0
                obj.View.handles.chopModelCheck.Enable = 'off';
            end
            if obj.mibModel.getImageProperty('maskExist') == 0
                obj.View.handles.chopMaskCheck.Enable = 'off';
            end
            
            % set default directory for the export
            obj.View.handles.dirEdit.String = obj.mibModel.myPath;
            obj.outputDir = obj.mibModel.myPath;
            
            % set template
            [path, filename, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.filenameTemplate.String = [filename '_chop'];
        end
        
        function selectDirBtn_Callback(obj)
            % function selectDirBtn_Callback(obj)
            % callback for obj.View.handles.selectDirBtn select directory
            % for the export
            folder_name = uigetdir(obj.View.handles.dirEdit.String, 'Select directory');
            if isequal(folder_name, 0); return; end
            
            obj.View.handles.dirEdit.String = folder_name;
            obj.outputDir = folder_name;
        end
        
        function dirEdit_Callback(obj)
            % function dirEdit_Callback(obj)
            % callback for obj.View.handles.dirEdit select directory
            % for the export
            
            folder_name = obj.View.handles.dirEdit.String;
            if exist(folder_name, 'dir') == 0
                choice = questdlg(sprintf('!!! Warnging !!!\nThe target directory:\n%s\nis missing!\n\nCreate?', folder_name), ...
                    'Create Directory', ...
                    'Create','Cancel','Cancel');
                if strcmp(choice, 'Cancel')
                    obj.View.handles.dirEdit.String = obj.outputDir;
                    return;
                end
                mkdir(folder_name);
            end
            obj.outputDir = folder_name;
        end
        
        function chopBtn_Callback(obj)
            % function chopBtn_Callback(obj)
            % chop the dataset
            tilesX = str2double(obj.View.handles.xTilesEdit.String);
            tilesY = str2double(obj.View.handles.yTilesEdit.String);
            tilesZ = str2double(obj.View.handles.zTilesEdit.String);
            
            outDir = obj.outputDir;
            fnTemplate = obj.View.handles.filenameTemplate.String;
            switch obj.View.handles.formatPopup.Value
                case 1  % amira mesh
                    ext = '.am';
                case 2  % nrrd
                    ext = '.nrrd';
                case 3  % tif
                    ext = '.tif';
                case 4  % xml
                    ext = '.xml';
            end
            
            switch obj.View.handles.formatModelsPopup.Value
                case 1
                    modelExt = '.model';      % Matlab default
                case 2
                    modelExt = '.am';       % amira mesh
                case 3
                    modelExt = '.nrrd';     % NRRD (Nearly Raster Raw Data)
                case 4  % tif
                    modelExt = '.tif';      % TIF (uncompressed)
                case 5  % xml
                    modelExt = '.xml';      % XML (HDF5 with XML header)
            end
            
            % get dataset dimensions
            options.blockModeSwitch = 0;    % disable the blockmode
            [height, width, color, stacks] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', 4, NaN, options);
            
            xStep = ceil(width/tilesX);
            yStep = ceil(height/tilesY);
            zStep = ceil(stacks/tilesZ);
            
            timePnt = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
            index = 1;
            for z=1:tilesZ
                for x=1:tilesX
                    for y=1:tilesY
                        yMin = (y-1)*yStep+1;
                        yMax = min([(y-1)*yStep+yStep, height]);
                        xMin = (x-1)*xStep+1;
                        xMax = min([(x-1)*xStep+xStep, width]);
                        zMin = (z-1)*zStep+1;
                        zMax = min([(z-1)*zStep+zStep, stacks]);
                        
                        %fprintf('Y: %d-%d\tX: %d-%d\tZ: %d-%d\n', yMin, yMax,xMin, xMax,zMin, zMax);
                        options.y = [yMin, yMax];
                        options.x = [xMin, xMax];
                        options.z = [zMin, zMax];
                        imOut = cell2mat(obj.mibModel.getData3D('image', timePnt, 4, 0, options));
                        
                        mibImageOptions = struct();
                        mibImageOptions.modelType = 63;
                        mibImageOptions.virtual = 0;
                        % get meta copy of the current meta-data
                        meta2 = containers.Map(keys(obj.mibModel.I{obj.mibModel.Id}.meta), values(obj.mibModel.I{obj.mibModel.Id}.meta));
                        meta2('Height') = yMax - yMin + 1;  % update Height, Width, Depth fields, 
                        meta2('Width') = xMax - xMin + 1;   % because they are used to initialize 
                        meta2('Depth') = zMax - zMin + 1;   % mibImage class variables
                        imgOut2 = mibImage(imOut, meta2, mibImageOptions);
                        imgOut2.pixSize = obj.mibModel.getImageProperty('pixSize');
                        
                        % update Bounding Box
                        xyzShift = [(xMin-1)*imgOut2.pixSize.x (yMin-1)*imgOut2.pixSize.y (zMin-1)*imgOut2.pixSize.z];
                        imgOut2.updateBoundingBox(NaN, xyzShift);
                        
                        log_text = sprintf('Chop: [y1:y2,x1:x2,:,z1:z2,t]: %d:%d,%d:%d,:,%d:%d,%d', yMin,yMax,xMin,xMax, zMin,zMax, timePnt);
                        imgOut2.updateImgInfo(log_text);
                        
                        % generate filename
                        fn = sprintf('%s_Z%.2d-X%.2d-Y%.2d%s', fnTemplate, z, x, y, ext);
                        filename = fullfile(outDir, fn);
                        imgOut2.meta('Filename') = filename;
                        
                        switch ext
                            case '.am'  % Amira Mesh
                                savingOptions = struct('overwrite', 1);
                                savingOptions.colors = obj.mibModel.getImageProperty('lutColors');   % store colors for color channels 0-1;
                                bitmap2amiraMesh(filename, imgOut2.img{1}, ...
                                    containers.Map(keys(imgOut2.meta), values(imgOut2.meta)), savingOptions);
                            case '.nrrd'  % NRRD
                                savingOptions = struct('overwrite', 1);
                                bb = imgOut2.getBoundingBox();
                                bitmap2nrrd(filename, imgOut2.img{1}, bb, savingOptions);
                            case '.tif' % uncompressed TIF
                                compression = 'none';
                                colortype = imgOut2.meta('ColorType');
                                if strcmp(colortype,'indexed')
                                    cmap = imgOut2.meta('Colormap');
                                else
                                    cmap = NaN;
                                end
                                
                                ImageDescription = {imgOut2.meta('ImageDescription')};
                                savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                    'overwrite', 1, 'Saving3d', 'multi', 'cmap', cmap, 'Compression', compression);
                                mibImage2tiff(filename, imgOut2.img{1}, savingOptions, ImageDescription);
                            case '.xml'
                                % getting parameters for saving dataset
                                if index == 1
                                    optionsHDF = mibSaveHDF5Dlg(imgOut2);
                                    if isempty(optionsHDF); return; end
                                end
                                optionsHDF.filename = filename;
                                ImageDescription = imgOut2.meta('ImageDescription');  % initialize ImageDescription
                                
                                % permute dataset if needed
                                if strcmp(optionsHDF.Format, 'bdv.hdf5')
                                    % permute image to swap the X and Y dimensions
                                    imgOut2.img{1} = permute(imgOut2.img{1}, [2 1 3 4 5]);
                                end
                                
                                optionsHDF.height = size(imgOut2.img{1}, 1);
                                optionsHDF.width = size(imgOut2.img{1}, 2);
                                optionsHDF.colors = size(imgOut2.img{1}, 3);
                                optionsHDF.depth = size(imgOut2.img{1}, 4);
                                optionsHDF.time = 1;
                                optionsHDF.pixSize = obj.mibModel.getImageProperty('pixSize');    % !!! check .units = 'um'
                                optionsHDF.showWaitbar = 1;        % show or not waitbar in data saving function
                                optionsHDF.lutColors = obj.mibModel.getImageProperty('lutColors');    % store LUT colors for channels
                                optionsHDF.ImageDescription = ImageDescription;
                                optionsHDF.DatasetName = 'MIB_Export';
                                optionsHDF.overwrite = 1;
                                %optionsHDF.DatasetType = 'image';
                                
                                % saving xml file if needed
                                if optionsHDF.xmlCreate
                                    saveXMLheader(optionsHDF.filename, optionsHDF);
                                end
                                
                                switch optionsHDF.Format
                                    case 'bdv.hdf5'
                                        optionsHDF.pixSize.units = sprintf('\xB5m');
                                        saveBigDataViewerFormat(optionsHDF.filename, imgOut2.img{1}, optionsHDF);
                                    case 'matlab.hdf5'
                                        [localDir, localFn] = fileparts(filename);
                                        image2hdf5(fullfile(localDir, [localFn '.h5']), imgOut2.img{1}, optionsHDF);
                                end
                        end
                        
                        % crop and save model
                        if obj.View.handles.chopModelCheck.Value
                            imgOut2.hLabels = copy(obj.mibModel.I{obj.mibModel.Id}.hLabels);
                            % crop labels
                            imgOut2.hLabels.crop([xMin, yMin, NaN, NaN, zMin, NaN]);
                            
                            imOut = cell2mat(obj.mibModel.getData3D('model', timePnt, 4, NaN, options)); %#ok<NASGU>
                            modelMaterialNames = obj.mibModel.getImageProperty('modelMaterialNames'); %#ok<NASGU>
                            modelMaterialColors = obj.mibModel.getImageProperty('modelMaterialColors');  %#ok<NASGU>
                            
                            BoundingBox = imgOut2.getBoundingBox(); %#ok<NASGU>
                            
                            % generate filename
                            fn = sprintf('Labels_%s_Z%.2d-X%.2d-Y%.2d%s', fnTemplate, z, x, y, modelExt);
                            fnModel = fullfile(outDir, fn);
                            
                            switch modelExt
                                case '.model'     % matlab
                                    modelVariable = 'imOut'; %#ok<NASGU>
                                    if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
                                        [labelText, labelValue, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                                        save(fnModel, 'imOut', 'modelMaterialNames', 'modelMaterialColors', 'BoundingBox', 'modelVariable', 'labelText', 'labelValue', 'labelPosition', '-mat', '-v7.3');
                                    else    % save without annotations
                                        save(fnModel, 'imOut', 'modelMaterialNames', 'modelMaterialColors', 'BoundingBox', 'modelVariable', '-mat', '-v7.3');
                                    end
                                case '.am'      % Amira Mesh
                                    pixStr = obj.mibModel.I{obj.mibModel.Id}.pixSize;
                                    pixStr.minx = BoundingBox(1);
                                    pixStr.miny = BoundingBox(3);
                                    pixStr.minz = BoundingBox(5);
                                    bitmap2amiraLabels(fnModel, imOut, 'binary', pixStr, modelMaterialColors, modelMaterialNames, 1, 1);
                                case '.nrrd'    % NRRD
                                    savingNRRDOptions.overwrite = 1;
                                    savingNRRDOptions.showWaitbar = 1;  % show or not waitbar in bitmap2nrrd
                                    bitmap2nrrd(fnModel, imOut, BoundingBox, savingNRRDOptions);
                                case '.tif'     % uncompressed TIF
                                    ImageDescription = imgOut2.meta('ImageDescription');  % initialize ImageDescription
                                    resolution(1) = imgOut2.meta('XResolution');
                                    resolution(2) = imgOut2.meta('YResolution');
                                    if exist('savingTIFOptions', 'var') == 0   % define parameters for the first time use
                                        savingTIFOptions = struct('Resolution', resolution, 'overwrite', 1, 'Saving3d', 'multi', 'cmap', NaN);
                                    end
                                    savingTIFOptions.showWaitbar = 1;  % show or not waitbar in ib_image2tiff
                                    imOut = reshape(imOut,[size(imOut,1) size(imOut,2) 1 size(imOut,3)]);
                                    
                                    [result, savingTIFOptions] = mibImage2tiff(fnModel, imOut, savingTIFOptions, ImageDescription);
                                case '.xml'     % hdf5
                                    % getting parameters for saving dataset
                                    if index == 1
                                        optionsModelHDF = mibSaveHDF5Dlg(imgOut2);
                                        if isempty(optionsModelHDF); return; end
                                    end
                                    optionsModelHDF.filename = fnModel;
                                    ImageDescription = imgOut2.meta('ImageDescription');  % initialize ImageDescription
                                    
                                    if strcmp(optionsModelHDF.Format, 'bdv.hdf5')
                                        button = questdlg(sprintf('Export of models in using the Big Data Viewer format is not implemented!\nSave as ordinary HDF5?'),...
                                            'Warning', 'Save as HDF5', 'Cancel', 'Save as HDF5');
                                        if strcmp(button, 'Cancel'); return; end
                                        optionsModelHDF.Format = 'matlab.hdf5';
                                    end
                                    
                                    % permute dataset if needed
                                    if strcmp(optionsModelHDF.Format, 'bdv.hdf5')
                                        % permute image to swap the X and Y dimensions
                                        %imOut = permute(imOut, [2 1 5 3 4]);
                                    else
                                        % permute image to add color dimension to position 3
                                        imOut = permute(imOut, [1 2 4 3]);
                                    end
                                    
                                    optionsModelHDF.height = size(imOut, 1);
                                    optionsModelHDF.width = size(imOut, 2);
                                    optionsModelHDF.colors = 1;
                                    if strcmp(optionsModelHDF.Format, 'bdv.hdf5')
                                        %optionsModelHDF.depth = size(imOut,4);
                                    else
                                        optionsModelHDF.depth = size(imOut,4);
                                    end
                                    optionsModelHDF.time = 1;
                                    optionsModelHDF.pixSize = obj.mibModel.getImageProperty('pixSize');    % !!! check .units = 'um'
                                    optionsModelHDF.showWaitbar = 1;        % show or not waitbar in data saving function
                                    optionsModelHDF.lutColors = modelMaterialColors;    % store LUT colors for materials
                                    optionsModelHDF.ImageDescription = ImageDescription;
                                    optionsModelHDF.DatasetName = 'Model';
                                    optionsModelHDF.overwrite = 1;
                                    optionsModelHDF.ModelMaterialNames = modelMaterialNames; % names for materials
                                    % saving xml file if needed
                                    if optionsModelHDF.xmlCreate
                                        saveXMLheader(optionsModelHDF.filename, optionsModelHDF);
                                    end
                                    
                                    switch optionsModelHDF.Format
                                        case 'bdv.hdf5'
                                            optionsModelHDF.pixSize.units = sprintf('\xB5m');
                                            saveBigDataViewerFormat(optionsModelHDF.filename, imOut, optionsModelHDF);
                                        case 'matlab.hdf5'
                                            [localDir, localFn] = fileparts(optionsModelHDF.filename);
                                            image2hdf5(fullfile(localDir, [localFn '.h5']), imOut, optionsModelHDF);
                                    end
                            end
                        end
                        
                        % crop and save mask
                        if obj.View.handles.chopMaskCheck.Value
                            fn = sprintf('Mask_%s_Z%.2d-X%.2d-Y%.2d.mask', fnTemplate, z, x, y);
                            fnModel = fullfile(outDir, fn);
                            imOut = cell2mat(obj.mibModel.getData3D('mask', timePnt, 4, 0, options)); %#ok<NASGU>
                            save(fnModel, 'imOut', '-mat', '-v7.3');
                        end
                        index = index + 1;
                    end
                end
            end
            
            disp('MIB: the dataset was chopped!')
            
            obj.closeWindow();
        end
    end
end