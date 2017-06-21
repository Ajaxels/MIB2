classdef mibCropObjectsController < handle
    % classdef mibCropObjectsController < handle
    % a controller class for the crop objects to file options of the context menu of the Get Statistics window
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    
    properties
        mibModel
        % handles to the model
        mibStatisticsController
        % a handle to mibStatisticsController 
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        outputDir
        % output directory
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch src.Name
                case 'Id'
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibCropObjectsController(mibModel, mibStatisticsController)
            obj.mibModel = mibModel;    % assign model
            obj.mibStatisticsController = mibStatisticsController;
            guiName = 'mibCropObjectsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            obj.updateWidgets();
            obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibCropObjectsController window
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
            % update widgets of the window
            
            % set default directory for the export
            obj.View.handles.dirEdit.String = obj.mibModel.myPath;
            obj.outputDir = obj.mibModel.myPath;
            
            if obj.mibModel.getImageProperty('maskExist') == 0
                obj.View.handles.cropMaskCheck.Enable = 'off';
            end
            if obj.mibModel.getImageProperty('modelExist') == 0
                obj.View.handles.cropModelCheck.Enable = 'off';
            end
            
        end
        
        function selectDirBtn_Callback(obj)
            % function selectDirBtn_Callback(obj)
            % a callback for press of obj.View.handles.selectDirBtn to select
            % output directory
            
            folder_name = uigetdir(obj.View.handles.dirEdit.String, 'Select directory');
            if isequal(folder_name, 0); return; end;
            obj.View.handles.dirEdit.String = folder_name;
            obj.outputDir = folder_name;
        end
        
        function dirEdit_Callback(obj)
            % function dirEdit_Callback(obj)
            % a callback for obj.View.handles.dirEdit to select output directory
            
            folder_name = obj.View.handles.dirEdit.String;
            if exist(folder_name, 'dir') == 0
                choice = questdlg(sprintf('!!! Warnging !!!\nThe target directory:\n%s\nis missing!\n\nCreate?', folder_name), ...
                    'Create Directory', ...
                    'Create','Cancel','Cancel');
                if strcmp(choice, 'Cancel')
                    obj.View.handles.dirEdit.String = obj.outputDir;
                    return;
                end;
                mkdir(folder_name);
            end
            obj.outputDir = folder_name;
        end
        
        function cropBtn_Callback(obj)
            % function cropBtn_Callback(obj)
            % a callback for press of obj.View.handles.cropBtn to start cropping            
            
            global mibPath; % path to mib installation folder
            
            % generate extension
            switch obj.View.handles.formatPopup.Value
                case 1
                    ext = '.am'; %#ok<NASGU>
                case 2
                    ext = '.mrc'; %#ok<NASGU>
                case 3
                    ext = '.nrrd'; %#ok<NASGU>
                case 4
                    ext = '.tif'; %#ok<NASGU>
                case 5
                    ext = '.tif'; %#ok<NASGU>
            end
            [~, fnTemplate] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            
            data = obj.mibStatisticsController.View.handles.statTable.Data;
            
            dimOpt.blockModeSwitch = 0;
            [h, w, c, z] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, dimOpt);
            
            % set CC structure for identification of the Bounding Box
            if obj.mibStatisticsController.View.handles.object2dRadio.Value == 1  % 2D mode
                if obj.mibStatisticsController.View.handles.connectivityCombo.Value == 1
                    CC.Connectivity = 4;
                else
                    CC.Connectivity = 8;
                end
                CC.ImageSize = [h, w];
            else            % 3D mode
                if obj.mibStatisticsController.View.handles.connectivityCombo.Value == 1
                    CC.Connectivity = 6;
                else
                    CC.Connectivity = 26;
                end
                CC.ImageSize = [h, w, z];
            end
            CC.NumObjects = 1;
            
            marginXY = str2double(obj.View.handles.marginXYEdit.String);
            marginZ = str2double(obj.View.handles.marginZEdit.String);
            
            % find uniqueTime - unique time points and their indices uniqueIndex
            selectedIndices = obj.mibStatisticsController.indices(:,1);
            [uniqueTime, ~, uniqueIndex] = unique(data(selectedIndices,4));
            
            if obj.mibModel.getImageProperty('time') > 1
                timeDigits = numel(num2str(obj.mibModel.getImageProperty('time')));    % get number of digits for time
            end
            
            timeIter = 1;
            for t=uniqueTime'   % has to be a horizontal vector
                if obj.View.handles.cropModelCheck.Value == 1
                    modelImg =  cell2mat(obj.mibModel.getData3D('model', t, 4, NaN, dimOpt));
                end
                if obj.View.handles.cropMaskCheck.Value
                    maskImg =  cell2mat(obj.mibModel.getData3D('mask', t, 4, NaN, dimOpt));
                end
                
                curTimeObjIndices = selectedIndices(uniqueIndex==timeIter);     % find indices of objects for the current time point t
                for rowId = 1:numel(curTimeObjIndices)
                    objId = data(curTimeObjIndices(rowId), 1);
                    
                    objectDigits = numel(num2str(numel(curTimeObjIndices)));    % get number of digits for objects
                    if obj.mibStatisticsController.View.handles.object2dRadio.Value == 1  % 2D mode
                        sliceDigits = numel(num2str(z));    % get number of digits for slices
                        sliceNumber = data(curTimeObjIndices(rowId), 3); %#ok<NASGU>
                        if obj.mibModel.getImageProperty('time') == 1
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(sliceDigits) 'd_%0' num2str(objectDigits) 'd%s'',  fnTemplate, sliceNumber, objId, ext));'];
                        else
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(timeDigits) 'd_%0' num2str(sliceDigits) 'd_%0' num2str(objectDigits) 'd%s'',  fnTemplate, t, sliceNumber, objId, ext));'];
                        end
                        eval(cmdText);
                        
                        % recalculate pixelIds from 3D to 2D space
                        CC.PixelIdxList{1} = obj.mibStatisticsController.STATS(objId).PixelIdxList-h*w*(sliceNumber-1);
                    else
                        %filename = fullfile(handles.outputDir, sprintf('%s_%06d%s',  fnTemplate, objId, ext));
                        if obj.mibModel.getImageProperty('time') == 1
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(objectDigits) 'd%s'',  fnTemplate, objId, ext));'];
                        else
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(timeDigits) 'd_%0' num2str(objectDigits) 'd%s'',  fnTemplate, t, objId, ext));'];
                        end
                        eval(cmdText);
                        CC.PixelIdxList{1} = obj.mibStatisticsController.STATS(objId).PixelIdxList;
                    end
                    
                    % get bounding box
                    S = regionprops(CC,'BoundingBox');
                    
                    if obj.mibStatisticsController.View.handles.object2dRadio.Value == 1  % 2D mode
                        xMin = ceil(S.BoundingBox(1))-marginXY;
                        yMin = ceil(S.BoundingBox(2))-marginXY;
                        xMax = xMin+floor(S.BoundingBox(3))-1+marginXY*2;
                        yMax = yMin+floor(S.BoundingBox(4))-1+marginXY*2;
                        zMin = sliceNumber;
                        zMax = sliceNumber;
                    else
                        xMin = ceil(S.BoundingBox(1))-marginXY;
                        yMin = ceil(S.BoundingBox(2))-marginXY;
                        xMax = xMin+floor(S.BoundingBox(4))-1+marginXY*2;
                        yMax = yMin+floor(S.BoundingBox(5))-1+marginXY*2;
                        zMin = ceil(S.BoundingBox(3))-marginZ;
                        zMax = zMin+floor(S.BoundingBox(6))-1+marginZ*2;
                    end
                    
                    xMin = max([xMin 1]);
                    yMin = max([yMin 1]);
                    zMin = max([zMin 1]);
                    xMax = min([xMax w]);
                    yMax = min([yMax h]);
                    zMax = min([zMax z]);
                    
                    getDataOptions.y = [yMin, yMax];
                    getDataOptions.x = [xMin, xMax];
                    getDataOptions.z = [zMin, zMax];
                    getDataOptions.t = [t, t];
                    imOut = obj.mibModel.I{obj.mibModel.Id}.getData('image', 4, 0, getDataOptions);
                    
                    imgOut2 = mibImage(imOut, [], 63);
                    imgOut2.pixSize = obj.mibModel.getImageProperty('pixSize');
                    imgOut2.meta('ImageDescription') = obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription');
                    % update Bounding Box
                    xyzShift = [(xMin-1)*imgOut2.pixSize.x (yMin-1)*imgOut2.pixSize.y (zMin-1)*imgOut2.pixSize.z];
                    imgOut2.updateBoundingBox(NaN, xyzShift);

                    % add XResolution/YResolution fields
                    [imgOut2.meta, imgOut2.pixSize] = mibUpdatePixSizeAndResolution(imgOut2.meta, imgOut2.pixSize);
                    
                    log_text = sprintf('ObjectCrop: [y1:y2,x1:x2,:,z1:z2,t]: %d:%d,%d:%d,:,%d:%d,%d', yMin,yMax,xMin,xMax, zMin,zMax,t);
                    imgOut2.updateImgInfo(log_text);
                    
                    if obj.View.handles.matlabRadio.Value == 1   % export to Matlab
                        %matlabVarName = sprintf('%s_%06d%s',  fnTemplate, objId);
                        [~, matlabVarName] = fileparts(filename);
                        matlabVar.img = imgOut2.img{1};
                        matlabVar.meta = containers.Map(keys(imgOut2.meta), values(imgOut2.meta));
                    else
                        switch obj.View.handles.formatPopup.Value
                            case 1  % Amira Mesh
                                savingOptions = struct('overwrite', 1);
                                savingOptions.colors = obj.mibModel.getImageProperty('lutColors');   % store colors for color channels 0-1;
                                bitmap2amiraMesh(filename, imgOut2.img{1}, ...
                                    containers.Map(keys(imgOut2.meta),values(imgOut2.meta)), savingOptions);
                            case 2 % MRC
                                savingOptions.volumeFilename = filename;
                                savingOptions.pixSize = imgOut2.pixSize;
                                mibImage2mrc(imgOut2.img{1}, savingOptions);
                            case 3  % NRRD
                                savingOptions = struct('overwrite', 1);
                                bb = imgOut2.getBoundingBox();
                                bitmap2nrrd(filename, imgOut2.img{1}, bb, savingOptions);
                            case {4, 5}  % LZW TIF / uncompressed TIF
                                if obj.View.handles.formatPopup.Value == 4
                                    compression = 'lzw';
                                else
                                    compression = 'none';
                                end
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
                        end
                    end
                    
                    % crop and save model
                    if obj.View.handles.cropModelCheck.Value == 1
                        imgOut2.hLabels = copy(obj.mibModel.I{obj.mibModel.Id}.hLabels);
                        % crop labels
                        imgOut2.hLabels.crop([xMin, yMin, NaN, NaN, zMin, NaN]);
                        
                        imOut =  modelImg(yMin:yMax, xMin:xMax, zMin:zMax); %#ok<NASGU>
                        
                        material_list = obj.mibModel.getImageProperty('modelMaterialNames'); %#ok<NASGU>
                        color_list = obj.mibModel.getImageProperty('modelMaterialColors'); %#ok<NASGU>
                        if obj.View.handles.matlabRadio.Value == 1   % export to Matlab
                            matlabVar.Model.model = imOut;
                            matlabVar.Model.materials = material_list;
                            matlabVar.Model.colors = color_list;
                            if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
                                [labelText, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                                matlabVar.labelText = labelText;
                                matlabVar.labelPosition = labelPosition;
                            end
                        else
                            % generate filename
                            [~, fnModel] = fileparts(filename);
                            bounding_box = imgOut2.getBoundingBox(); %#ok<NASGU>
                            
                            switch obj.View.handles.modelFormatPopup.Value
                                case 1  % Matlab format
                                    fnModel = ['Labels_' fnModel '.model']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
                                        [labelText, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                                        save(fnModel, 'imOut', 'material_list', 'color_list', 'bounding_box', 'labelText', 'labelPosition', '-mat', '-v7.3');
                                    else    % save without annotations
                                        save(fnModel, 'imOut', 'material_list', 'color_list', 'bounding_box', '-mat', '-v7.3');
                                    end
                                case 2  % Amira Mesh
                                    fnModel = ['Labels_' fnModel '.am']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    pixStr = imgOut2.pixSize;
                                    pixStr.minx = bounding_box(1);
                                    pixStr.miny = bounding_box(3);
                                    pixStr.minz = bounding_box(5);
                                    showWaitbar = 0;  % show or not waitbar in bitmap2amiraMesh
                                    bitmap2amiraLabels(fnModel, imOut, 'binary', pixStr, color_list, material_list, 1, showWaitbar);
                                case 3 % MRC
                                    fnModel = ['Labels_' fnModel '.mrc']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.volumeFilename = fnModel;
                                    Options.pixSize = imgOut2.pixSize;
                                    savingOptions.showWaitbar = 0;  % show or not waitbar in exportModelToImodModel
                                    mibImage2mrc(imOut, Options);
                                case 4  % NRRD
                                    fnModel = ['Labels_' fnModel '.nrrd']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.overwrite = 1;
                                    Options.showWaitbar = 0;  % show or not waitbar in bitmap2nrrd
                                    bitmap2nrrd(fnModel, imOut, bounding_box, Options);
                                case {5, 6}  % LZW TIF / uncompressed TIF
                                    fnModel = ['Labels_' fnModel '.tif']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    if obj.View.handles.formatPopup.Value == 5
                                        compression = 'lzw';
                                    else
                                        compression = 'none';
                                    end
                                    ImageDescription = {imgOut2.meta('ImageDescription')};
                                    imOut = reshape(imOut,[size(imOut,1) size(imOut,2) 1 size(imOut,3)]);
                                    savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                        'overwrite', 1, 'Saving3d', 'multi', 'Compression', compression);
                                    mibImage2tiff(fnModel, imOut, savingOptions, ImageDescription);
                            end
                        end
                    end
                    
                    % crop and save mask
                    if obj.View.handles.cropMaskCheck.Value
                        imOut =  maskImg(yMin:yMax, xMin:xMax, zMin:zMax);
                        if obj.View.handles.matlabRadio.Value == 1   % export to Matlab
                            matlabVar.Mask = imOut;
                        else
                            % generate filename
                            [~, fnModel] = fileparts(filename);
                            bounding_box = imgOut2.getBoundingBox(); %#ok<NASGU>
                            
                            switch obj.View.handles.maskFormatPopup.Value
                                case 1  % Matlab format
                                    fnModel = ['Mask_' fnModel '.mask']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    save(fnModel, 'imOut','-mat', '-v7.3');
                                case 2  % Amira Mesh
                                    fnModel = ['Mask_' fnModel '.am']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    pixStr = imgOut2.pixSize;
                                    pixStr.minx = bounding_box(1);
                                    pixStr.miny = bounding_box(3);
                                    pixStr.minz = bounding_box(5);
                                    showWaitbar = 0;  % show or not waitbar in bitmap2amiraMesh
                                    bitmap2amiraLabels(fnModel, imOut, 'binary', pixStr, [.567, .213, .625], cellstr('Mask'), 1, showWaitbar);
                                case 3 % MRC
                                    fnModel = ['Mask_' fnModel '.mrc']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.volumeFilename = fnModel;
                                    Options.pixSize = imgOut2.pixSize;
                                    savingOptions.showWaitbar = 0;  % show or not waitbar in exportModelToImodModel
                                    mibImage2mrc(imOut, Options);
                                case 4  % NRRD
                                    fnModel = ['Mask_' fnModel '.nrrd']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.overwrite = 1;
                                    Options.showWaitbar = 0;  % show or not waitbar in bitmap2nrrd
                                    bitmap2nrrd(fnModel, imOut, bounding_box, Options);
                                case {5, 6}  % LZW TIF / uncompressed TIF
                                    fnModel = ['Mask_' fnModel '.tif']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    if obj.View.handles.formatPopup.Value == 5
                                        compression = 'lzw';
                                    else
                                        compression = 'none';
                                    end
                                    ImageDescription = {imgOut2.meta('ImageDescription')};
                                    imOut = reshape(imOut,[size(imOut,1) size(imOut,2) 1 size(imOut,3)]);
                                    savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                        'overwrite', 1, 'Saving3d', 'multi', 'Compression', compression);
                                    mibImage2tiff(fnModel, imOut, savingOptions, ImageDescription);
                            end
                        end
                    end
                    
                    % export to Matlab
                    if obj.View.handles.matlabRadio.Value
                        answer = mibInputDlg({mibPath}, sprintf('Enter name for the export:\n(it should start with a letter)'),'Variable name:', matlabVarName);
                        if isempty(answer); return; end
                        matlabVarName = answer{1};
                        
                        assignin('base', matlabVarName, matlabVar);
                        fprintf('MIB: %s was exported to Matlab\n', matlabVarName);
                    end
                end
                timeIter = timeIter + 1;
            end
            
            obj.closeWindow();
        end
    end
end