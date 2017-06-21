function menuModelsSaveAs_Callback(obj, parameter)
% function menuModelsSaveAs_Callback(obj, parameter)
% callback to Menu->Models->Save as
% save model to a file
%
% Parameters:
% parameter: a string, 'saveas' to define that the save as mode should be
% used, when omitted the model is saved in matlab format

% Copyright (C) 06.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; parameter = 'save'; end

if  obj.mibModel.getImageProperty('modelExist') == 0 || obj.mibModel.getImageProperty('modelType') == 128
    disp('Cancel: No segmentation model detected'); 
    return; 
end
fn_out = obj.mibModel.getImageProperty('modelFilename');
if isempty(fn_out)
    [pathstr, name] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
    fn_out = fullfile(pathstr, ['Labels_' name '.model']);
    parameter = 'saveas';
end

obj.mibModel.getImageProperty('modelFilename');
selMaterial = obj.mibModel.getImageProperty('selectedMaterial') - 2;
if obj.mibModel.showAllMaterials == 1;     selMaterial = 0;  end  % save all materials

if isempty(fn_out)
    fn_out = obj.mibModel.myPath;
end

if strcmp(parameter, 'saveas')
    Filters = {'*.model;',  'Matlab format (*.model)'; ...
        '*.am;',  'Amira mesh binary RLE compression SLOW (*.am)'; ...
        '*.am;',  'Amira mesh binary (*.am)'; ...
        '*.am;',  'Amira mesh ascii (*.am)'; ...
        '*.h5',   'Hierarchical Data Format (*.h5)'; ...
        '*.mat',   'Matlab format for MIB ver. 1 (*.mat)'; ...
        '*.mod;',  'Contours for IMOD (*.mod)'; ...
        '*.mrc;',  'Volume for IMOD (*.mrc)'; ...
        '*.nrrd;',  'NRRD for 3D Slicer (*.nrrd)'; ...
        '*.stl',  'Isosurface as binary STL (*.stl)'; ...
        '*.tif;',  'TIF format (*.tif)'; ...
        '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
        '*.*',  'All Files (*.*)'
        };

    [filename, path, FilterIndex] = uiputfile(Filters, 'Save model data...', fn_out);
    if isequal(filename,0); return; end % check for cancel
else
    FilterIndex = 1;    % Matlab format (*.model)
    [path, filename] = fileparts(fn_out);
    filename = [filename '.model'];
end
tic

getDataOptions.blockModeSwitch = 0;     % get the full dataset

obj.mibModel.I{obj.mibModel.Id}.modelVariable = strrep(obj.mibModel.I{obj.mibModel.Id}.modelVariable, '-', '_');

if FilterIndex == 1 || FilterIndex == 6    % matlab file
    warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
    curInt = get(0, 'DefaulttextInterpreter');
    set(0, 'DefaulttextInterpreter', 'none');
    wb = waitbar(0,sprintf('%s\nPlease wait...', fullfile(path, filename)), 'Name', 'Saving the model', 'WindowStyle', 'modal');
    set(findall(wb,'type','text'),'Interpreter','none');
    waitbar(0, wb);
    str1 = strcat(obj.mibModel.I{obj.mibModel.Id}.modelVariable, ' = cell2mat(obj.mibModel.getData4D(''model'', 4, NaN, getDataOptions));');
    eval(str1);    
    
    if FilterIndex == 1     % models for MIB2
        modelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames; %#ok<NASGU>
        modelMaterialColors = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors; %#ok<NASGU>
        BoundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(); %#ok<NASGU>
        modelVariable = obj.mibModel.I{obj.mibModel.Id}.modelVariable; %#ok<NASGU>    % name of a variable that has the dataset
        modelType = obj.mibModel.I{obj.mibModel.Id}.modelType;  %#ok<NASGU> % type of the model
        
        if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
            [labelText, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
            str1 = ['save ''' fullfile(path, filename) ''' ' obj.mibModel.I{obj.mibModel.Id}.modelVariable ...
                ' modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType labelText labelPosition -mat -v7.3'];
        else    % save without annotations
            str1 = ['save ''' fullfile(path, filename) ''' ' obj.mibModel.I{obj.mibModel.Id}.modelVariable ...
                ' modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType -mat -v7.3'];
        end
        eval(str1);
        obj.mibModel.I{obj.mibModel.Id}.modelFilename = fullfile(path, filename);
    else                    % models for MIB1
        material_list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames; %#ok<NASGU>
        color_list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors; %#ok<NASGU>
        bounding_box = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox(); %#ok<NASGU>
        model_var = obj.mibModel.I{obj.mibModel.Id}.modelVariable;  %#ok<NASGU>    % name of a variable that has the dataset
        if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
            [labelText, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
            str1 = ['save ''' fullfile(path, filename) ''' ' obj.mibModel.I{obj.mibModel.Id}.modelVariable ' material_list color_list bounding_box model_var labelText labelPosition -mat -v7.3'];
        else    % save without annotations
            str1 = ['save ''' fullfile(path, filename) ''' ' obj.mibModel.I{obj.mibModel.Id}.modelVariable ' material_list color_list bounding_box model_var -mat -v7.3'];
        end
        eval(str1);
    end
    delete(wb);
    set(0, 'DefaulttextInterpreter', curInt);
else
    [~, filename, ext] = fileparts(filename);
    ext = lower(ext);
    t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
    t2 = t1;
    
    if obj.mibModel.I{obj.mibModel.Id}.time > 1
        if ~ismember(ext, {'.xml', '.h5'})
            button = questdlg(sprintf('!!! Warning !!!\nIt is not possible to save 4D dataset into a single file!\n\nHowever it is possible to save the currently shown Z-stack, or to make a series of files'), ...
                'Save model', 'Save as series of 3D datasets', 'Save the currently shown Z-stack', 'Cancel', 'Save as series of 3D datasets');
            if strcmp(button, 'Cancel'); return; end
        end
        t1 = 1;
        t2 = obj.mibModel.I{obj.mibModel.Id}.time;
    end
    
    showLocalWaitbar = 0;   % switch to show or not wait bar in this function
    if t1 ~= t2
        showLocalWaitbar = 1;
        wb = waitbar(0, sprintf('Saving %s\nPlease wait...', Filters{FilterIndex,2}), 'Name', 'Saving images...', 'WindowStyle', 'modal');
        dT = t2-t1+1;
    end
    
    multCoefficient = 1;    % multiply material by this number
    color_list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors;
    color_list = color_list(1:numel(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames),:);
    modelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
    
    if selMaterial > 0
        button = questdlg(sprintf('You are going to export only material No:%d (%s) !\nProceed?', ...
            selMaterial, obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{selMaterial}), ...
            'Single material export', 'Proceed, set as 1', 'Proceed, set as 255', 'Cancel', 'Proceed, set as 1');
        if strcmp(button, 'Cancel'); return; end
        if strcmp(button, 'Proceed, set as 255')
            if FilterIndex ~= 9; multCoefficient = 255; end    % do not do that for the STL model type
        end
        color_list = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(selMaterial,:);
        modelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(selMaterial);
    else
        selMaterial = NaN;  % reassign materials to take them all
    end
    
    for t=t1:t2
        if t1~=t2   % generate filename
            fnOut = generateSequentialFilename(filename, t, t2-t1+1, ext);
        else
            fnOut = [filename ext];
        end
        
        model = cell2mat(obj.mibModel.getData3D('model', t, 4, selMaterial, getDataOptions));
        if multCoefficient > 1      % make intensity of the output model as 255
            model = model*multCoefficient;
        end
        
        if FilterIndex == 2     % Amira mesh binary RLE compression
            bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            pixStr = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            pixStr.minx = bb(1);
            pixStr.miny = bb(3);
            pixStr.minz = bb(5);
            showWaitbar = ~showLocalWaitbar;  % show or not waitbar in bitmap2amiraMesh
            bitmap2amiraLabels(fullfile(path, fnOut), model, 'binaryRLE', pixStr, color_list, modelMaterialNames, 1, showWaitbar);
        elseif FilterIndex == 3     % Amira mesh binary
            bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            pixStr = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            pixStr.minx = bb(1);
            pixStr.miny = bb(3);
            pixStr.minz = bb(5);
            showWaitbar = ~showLocalWaitbar;  % show or not waitbar in bitmap2amiraMesh
            bitmap2amiraLabels(fullfile(path, fnOut), model, 'binary', pixStr, color_list, modelMaterialNames, 1, showWaitbar);
        elseif FilterIndex == 4     % Amira mesh ascii
            bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            pixStr = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            pixStr.minx = bb(1);
            pixStr.miny = bb(3);
            pixStr.minz = bb(5);
            showWaitbar = ~showLocalWaitbar;  % show or not waitbar in bitmap2amiraMesh
            bitmap2amiraLabels(fullfile(path, fnOut), model, 'ascii', pixStr, color_list, modelMaterialNames, 1, showWaitbar);
        elseif FilterIndex == 5 || FilterIndex == 12          % hdf5 format
            if t==t1    % getting parameters for saving dataset
                options = mibSaveHDF5Dlg(obj.mibModel.I{obj.mibModel.Id});
                if isempty(options)
                    if showLocalWaitbar; delete(wb); end
                    return;
                end
                
                if strcmp(options.Format, 'bdv.hdf5')
                    warndlg('Export of models in using the Big Data Viewer format is not implemented!');
                    if showLocalWaitbar; delete(wb); end
                    return;
                end
                    
                options.filename = fullfile(path, [filename ext]);
                ImageDescription = obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription');  % initialize ImageDescription
            end
            % permute dataset if needed
            if strcmp(options.Format, 'bdv.hdf5')
                % permute image to swap the X and Y dimensions
                %model = permute(model, [2 1 5 3 4]);
            else
                % permute image to add color dimension to position 3
                model = permute(model, [1 2 4 3]);
            end
            
            if t==t1    % updating parameters for saving dataset
                options.height = size(model, 1);
                options.width = size(model, 2);
                options.colors = 1;
                if strcmp(options.Format, 'bdv.hdf5')
                    %options.depth = size(model,4);
                else
                    options.depth = size(model, 4);
                end
                options.time = obj.mibModel.I{obj.mibModel.Id}.time;
                options.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;    % !!! check .units = 'um'
                options.showWaitbar = ~showLocalWaitbar;        % show or not waitbar in data saving function
                options.lutColors = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors;    % store LUT colors for materials
                options.ImageDescription = ImageDescription; 
                options.DatasetName = filename; 
                options.overwrite = 1;
                options.ModelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames; % names for materials
                % saving xml file if needed
                if options.xmlCreate
                    saveXMLheader(options.filename, options);
                end
            end
            options.t = t;
            switch options.Format
                case 'bdv.hdf5'
                    options.pixSize.units = sprintf('\xB5m'); % 'µm';
                    saveBigDataViewerFormat(options.filename, model, options);
                case 'matlab.hdf5'
                    options.order = 'yxczt';
                    image2hdf5(fullfile(path, [filename '.h5']), model, options);
            end
            
        elseif FilterIndex == 7     % Contours for IMOD (*.mod)
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                prompt = {'Take each Nth point in contours ( > 0):','Show detected points in the selection layer [0-no, 1-yes]:'};
                dlg_title = 'Parameters';
                answer = inputdlg(prompt, dlg_title, 1, {'5','0'});
                if size(answer) == 0; return; end
                savingOptions.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
                savingOptions.xyScaleFactor = str2double(answer{1});
                savingOptions.zScaleFactor = 1;
                savingOptions.generateSelectionSw = str2double(answer{2});
                if selMaterial == 0 || isnan(selMaterial)
                    savingOptions.colorList = color_list;
                    savingOptions.ModelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames; % names for materials;
                else
                    savingOptions.colorList = color_list(1,:);
                    savingOptions.ModelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(selMaterial); % names for materials;
                end
                savingOptions.showWaitbar = ~showLocalWaitbar;  % show or not waitbar in exportModelToImodModel
            end
            savingOptions.modelFilename = [path fnOut];
            if savingOptions.generateSelectionSw
                [~, selection] = mibExportModelToImodModel(model, savingOptions);
                obj.mibModel.setData3D('selection', selection, t, 4, 0, getDataOptions);
            else
                mibExportModelToImodModel(model, savingOptions);
            end
        elseif FilterIndex == 8     % Volume for IMOD (*.mrc)
            Options.volumeFilename = fullfile(path, fnOut);
            Options.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            savingOptions.showWaitbar = ~showLocalWaitbar;  % show or not waitbar in exportModelToImodModel
            mibImage2mrc(model, Options);
        elseif FilterIndex == 9     % NRRD for 3D Slicer (*.nrrd)
            bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            Options.overwrite = 1;
            Options.showWaitbar = ~showLocalWaitbar;  % show or not waitbar in bitmap2nrrd
            bitmap2nrrd(fullfile(path, fnOut), model, bb, Options);
        elseif FilterIndex == 10     % STL isosurface for Blinder (*.stl)
            bounding_box = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();  % get bounding box
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                prompt = {'Reduce the volume down to, width pixels [no volume reduction when 0]?',...
                    'Smoothing 3d kernel, width (no smoothing when 0):',...
                    'Maximal number of faces (no limit when 0):'};
                dlg_title = 'Isosurface parameters';
                if obj.mibModel.I{obj.mibModel.Id}.width > 500
                    def = {'500', '5', '300000'};
                else
                    def = {'0', '5', '300000'};
                end
                answer = inputdlg(prompt, dlg_title, 1, def);
                if isempty(answer); return;  end
                
                savingOptions.reduce = str2double(answer{1});
                savingOptions.smooth = str2double(answer{2});
                savingOptions.maxFaces = str2double(answer{3});
                savingOptions.slice = 0;
            end
            
            if isnan(selMaterial)
                p = mibRenderModel(model, selMaterial, obj.mibModel.I{obj.mibModel.Id}.pixSize, bounding_box, obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, NaN, savingOptions);
                for i=1:numel(p)
                    fv = struct('faces', p(i).Faces, 'vertices', p(i).Vertices);
                    stlwrite(fullfile(path, [sprintf('%s_%d', fnOut(1:end-4), i) '.stl']), fv, 'FaceColor', p(i).FaceColor*255);
                end
            else
                p = mibRenderModel(model, 1, obj.mibModel.I{obj.mibModel.Id}.pixSize, bounding_box, color_list, NaN, savingOptions);
                fv.faces = p.Faces;
                fv.vertices = p.Vertices;
                stlwrite(fullfile(path, fnOut), fv, 'FaceColor', p.FaceColor*255);
            end
        elseif FilterIndex == 11     % as tif
            ImageDescription = {obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription')};
            resolution(1) = obj.mibModel.I{obj.mibModel.Id}.meta('XResolution');
            resolution(2) = obj.mibModel.I{obj.mibModel.Id}.meta('YResolution');
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                savingOptions = struct('Resolution', resolution, 'overwrite', 1, 'Saving3d', NaN, 'cmap', NaN);
            end
            savingOptions.showWaitbar = ~showLocalWaitbar;  % show or not waitbar in ib_image2tiff
            model = reshape(model,[size(model,1) size(model,2) 1 size(model,3)]);
            [result, savingOptions] = mibImage2tiff(fullfile(path, fnOut), model, savingOptions, ImageDescription);
            if isfield(savingOptions, 'SliceName'); savingOptions = rmfield(savingOptions, 'SliceName'); end % remove SliceName field when saving series of 2D files
        end
        if showLocalWaitbar;    waitbar(t/dT, wb);    end
    end
    if showLocalWaitbar; delete(wb); end
end
disp(['Model: ' fullfile(path, filename) ' has been saved']);
obj.updateFilelist(filename);
obj.plotImage();
toc;
end
