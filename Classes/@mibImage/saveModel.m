% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function fnOut = saveModel(obj, filename, saveModelOptions)
% function fnOut = saveModel(obj, filename, saveModelOptions)
% save model to a file
%
% Parameters:
% filename: [@em optional] a string with filename, when empty a dialog for
% filename selection is shown; when the filename is provided its extension defines the output format, unless the
% format is provided in the saveModelOptions structure
% saveModelOptions: an optional structure with additional parameters
% @li .Format - string with the output format, as in the Formats variable below, for example 'Matlab format (*.model)'
% @li .FilenameGenerator - string, when ''Use original
% filename'' -> use original filenames of the loaded datasets; ''Use
% sequential filename'' -> the filenames are generated in sequence using
% the first filename of the loaded dataset as template
% @li .DestinationDirectory - string, with destination directory, if filename has no full path
% @li .MaterialIndex - numeric, index of the material to save, when [] save all materials; NaN - save currently selected material
% @li .Saving3DPolicy - string, [TIF, mibCat only] save images as 3D file or as a sequence of 2D files ('3D stack', '2D sequence')
% @li .FilenamePolicy - string, [mibCat, TIF, PNG only] policy for generation of filenames ('Use existing name', 'Use new provided name')
% @li .showWaitbar - logical, show or not the waitbar
% @li .silent  - logical, do not ask any questions and use default parameters
%
% Return values:
% fnOut -> output model filename

% Updates
%

global mibPath;

fnOut = [];
if nargin < 3; saveModelOptions = struct(); end
if nargin < 2; filename = []; end

Formats = {'*.model',  'Matlab format (*.model)'; ...
    '*.am',  'Amira mesh binary RLE compression SLOW (*.am)'; ...
    '*.am',  'Amira mesh binary (*.am)'; ...
    '*.am',  'Amira mesh ascii (*.am)'; ...
    '*.h5',   'Hierarchical Data Format (*.h5)'; ...
    '*.model',  'Matlab format 2D sequence (*.model)'; ...
    '*.mat',   'Matlab format for MIB ver. 1 (*.mat)'; ...
    '*.mibCat', 'Matlab categorical format (*.mibCat)'; ...
    '*.mod',  'Contours for IMOD (*.mod)'; ...
    '*.mrc',  'Volume for IMOD (*.mrc)'; ...
    '*.nrrd',  'NRRD for 3D Slicer (*.nrrd)'; ...
    '*.png', 'PNG format (*.png)'; ...
    '*.stl',  'Isosurface as binary STL (*.stl)'; ...
    '*.tif',  'TIF format (*.tif)'; ...
    '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
    '*.*',  'All Files (*.*)'
    };
if ~isfield(saveModelOptions, 'showWaitbar'); saveModelOptions.showWaitbar = true; end
if ~isfield(saveModelOptions, 'silent'); saveModelOptions.silent = false; end

if  obj.modelExist == 0 || obj.modelType == 128
    disp('Cancel: No segmentation model detected');
    return;
end

% check for destination directory
if ~isempty(filename)
    [pathStr, fnameStr, ext] = fileparts(filename);
    if isempty(pathStr)
        if isfield(saveModelOptions, 'DestinationDirectory')
            filename = fullfile(saveModelOptions.DestinationDirectory, filename);
        else
            msgbox('Destination directory for saving models was not provided!', 'Error!', 'error', 'modal');
            return;
        end
    end
end

% define output filename
if isempty(filename)
    fnOut = obj.modelFilename;
    if isempty(fnOut)
        fnOut = obj.meta('Filename');
        if isempty(strfind(fnOut, '/')) && isempty(strfind(fnOut, '\')) && isfield(saveModelOptions, 'DestinationDirectory') %#ok<STREMP>
            fnOut = fullfile(saveModelOptions.DestinationDirectory, fnOut);
        end
        [path, fnOut] = fileparts(fnOut);
        fnOut = ['Labels_' fnOut '.model'];
        fnOut = fullfile(path, fnOut);
    end
    
    if isempty(fnOut) && isfield(saveModelOptions, 'DestinationDirectory')
        fnOut = fullfile(saveModelOptions.DestinationDirectory, 'model.model');
    elseif isempty(fnOut)
        fnOut = [];
    end
    
    if ~isempty(fnOut)
        extFilter = '*.model';
        
        formatListPosition = find(ismember(Formats(:,1), extFilter));
        if isempty(formatListPosition)
            Formats = Formats([end 1:end-1],:);
        else
            formatListPosition = formatListPosition(1);
            selectedFilter = Formats(formatListPosition, :);
            Formats(formatListPosition, :) = [];
            Formats = [selectedFilter; Formats];
        end
        dotPosition = strfind(fnOut, '.');
        if ~isempty(dotPosition)
            fnOut = [fnOut(1:dotPosition(end)) 'model'];
        else
            fnOut = [fnOut '.model'];
        end
    end
    
    [fn, pathStr, FilterIndex] = uiputfile(Formats, 'Save model...', fnOut); %...
    if isequal(fn, 0); return; end % check for cancel
    
    if strcmp(Formats{FilterIndex,2}, 'All Files (*.*)')
        warndlg(sprintf('!!! Warning !!!\n\nThe output format was not selected!'), 'Missing output format', 'modal');
        return;
    end
    saveModelOptions.Format = Formats{FilterIndex, 2};
    fnOut = fullfile(pathStr, fn);
else
    [pathStr, fnameStr, ext] = fileparts(filename);
    extFilter = ['*' ext];
    
    if ~isfield(saveModelOptions, 'Format')  % detect output format
        formatListPosition = find(ismember(Formats(1:end-1,1), extFilter));
        if isempty(formatListPosition); msgbox('The output format can''t be identified!', 'Error!', 'error', 'modal'); return; end
        formatListPosition = formatListPosition(1);
        saveModelOptions.Format = Formats{formatListPosition, 2};
    else
        if ismember(saveModelOptions.Format, Formats(:,2)) == 0
            errMsg = sprintf('The provided output format "%s" is not valid\n\nUse one of these saveModelOptions:\n%s', saveModelOptions.Format);
            for i=1:size(Formats, 1)-1
                errMsg = sprintf('%s%s\n', errMsg, Formats{i,2});
            end
            
            msgbox(errMsg, 'Error!', 'error', 'modal');
            return;
        end
    end
    fnOut = filename;
end

if isfield(saveModelOptions, 'MaterialIndex')
    if isempty(saveModelOptions.MaterialIndex)
        selMaterial = NaN;    % save all materials
    else
        if isnan(saveModelOptions.MaterialIndex)
            selMaterial = obj.selectedMaterial - 2;
        else
            selMaterial = saveModelOptions.MaterialIndex;
        end
    end
else
    selMaterial = NaN;    % save all materials
end

tic
obj.modelVariable = strrep(obj.modelVariable, '-', '_');
warning('off', 'MATLAB:handle_graphics:exceptions:SceneNode');

if strcmp(saveModelOptions.Format, 'Matlab format (*.model)') ...
    || strcmp(saveModelOptions.Format, 'Matlab format for MIB ver. 1 (*.mat)') ...
    || strcmp(saveModelOptions.Format, 'Matlab categorical format (*.mibCat)') 

    if strcmp(saveModelOptions.Format, 'Matlab categorical format (*.mibCat)') && ~isfield(saveModelOptions, 'Saving3DPolicy')
        prompts = {'Model saving policy:'; 'Filename policy (only for 2D):'};
        defAns = {{'3D stack', '2D sequence', 1}; {'Use existing name', 'Use new provided name', 2}}; 
        [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, 'Options');
        if isempty(answer); return; end     
        saveModelOptions.Saving3DPolicy = answer{1};
        saveModelOptions.FilenamePolicy = answer{2};
    end

    if saveModelOptions.showWaitbar
        wb = waitbar(0, '', 'Name', 'Saving the model', 'WindowStyle', 'modal');
        wb.Children.Title.Interpreter = 'none';
        [pathnameStr, filenameStr, extStr] = fileparts(fnOut);
        waitbar(0, wb, sprintf('%s\n%s', pathnameStr, [filenameStr extStr]));
        drawnow;
    end

    % update modelMaterialNames / modelMaterialColors
    modelMaterialNames = obj.modelMaterialNames;
    modelMaterialColors = obj.modelMaterialColors;
    if ~isnan(selMaterial)
        if selMaterial < 1
            modelMaterialNames = {'Exterior'}; 
            modelMaterialColors = obj.modelMaterialColors(1, :);
        else
            modelMaterialNames = obj.modelMaterialNames(selMaterial); 
            modelMaterialColors = obj.modelMaterialColors(selMaterial, :); 
        end
    end

    switch saveModelOptions.Format
        case 'Matlab format (*.model)'     % models for MIB2
            str1 = sprintf('%s = obj.getData(''model'', 4, %d);', obj.modelVariable, selMaterial);
            eval(str1);
           
            BoundingBox = obj.getBoundingBox(); %#ok<NASGU>
            modelVariable = obj.modelVariable; %#ok<NASGU>    % name of a variable that has the dataset
            modelType = obj.modelType;  %#ok<NASGU> % type of the model
            
            if obj.hLabels.getLabelsNumber() > 1  % save annotations
                [labelText, labelValue, labelPosition] = obj.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                str1 = ['save ''' fnOut ''' ' obj.modelVariable ...
                    ' modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType labelText labelValue labelPosition -mat -v7.3'];
            else    % save without annotations
                str1 = ['save ''' fnOut ''' ' obj.modelVariable ...
                    ' modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType -mat -v7.3'];
            end
            eval(str1);
            obj.modelFilename = fnOut;
        case 'Matlab format for MIB ver. 1 (*.mat)'
            str1 = sprintf('%s = obj.getData(''model'', 4, %d);', obj.modelVariable, selMaterial);
            eval(str1);
            material_list = modelMaterialNames; %#ok<NASGU>
            color_list = modelMaterialColors; %#ok<NASGU>
            bounding_box = obj.getBoundingBox(); %#ok<NASGU>
            model_var = obj.modelVariable;  %#ok<NASGU>    % name of a variable that has the dataset
            if obj.hLabels.getLabelsNumber() > 1  % save annotations
                [labelText, labelValue, labelPosition] = obj.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                str1 = ['save ''' fnOut ''' ' obj.modelVariable ' material_list color_list bounding_box model_var labelText labelPosition -mat -v7.3'];
            else    % save without annotations
                str1 = ['save ''' fnOut ''' ' obj.modelVariable ' material_list color_list bounding_box model_var -mat -v7.3'];
            end
            eval(str1);
        case 'Matlab categorical format (*.mibCat)'
            classNames = obj.modelMaterialNames;
            classNames = [{'Exterior'}; classNames];    % add Exterior as material 0
            imgVariable = 'imgOut';
            options.dimOrder = 'yxczt';
            options.modelType = obj.modelType;
            options.modelMaterialColors = obj.modelMaterialColors;
            if strcmp(obj.modelMaterialNames{1}, 'Exterior')    % correct material names for Exterior, Exterior case
                options.modelMaterialNames = obj.modelMaterialNames;    
            else
                options.modelMaterialNames = classNames;
            end
            if ~strcmp(obj.modelMaterialNames{1}, 'Exterior')   % add a random color for the Exterior
                options.modelMaterialColors = [rand(1,3); options.modelMaterialColors];     
            end
            
            if strcmp(saveModelOptions.Saving3DPolicy, '3D stack')
                str1 = strcat(obj.modelVariable, ' = obj.getData(''model'', 4, NaN);');
                eval(str1);
            
                cmdString = sprintf('imgOut = categorical(%s, 0:numel(classNames)-1, classNames);', obj.modelVariable);    %#ok<NODEF> % convert to categorial
                eval(cmdString);
                save(fnOut, 'imgOut', 'imgVariable', 'options', '-mat', '-v7.3');
            else
                imgOutFull = obj.getData('model', 4, NaN); %#ok<NASGU>
                [pathOut, fnOut] = fileparts(fnOut);
                sliceNames = obj.meta('SliceName');
                for z=1:obj.depth
                    if strcmp(saveModelOptions.FilenamePolicy, 'Use existing name') && numel(sliceNames) > 1
                        [~, fnOutLocal] = fileparts(sliceNames{z});
                        fnOutLocal = ['Labels_' fnOutLocal '.mibCat'];
                    else
                        fnOutLocal = generateSequentialFilename(fnOut, z, obj.depth, '.mibCat');
                    end
                    fnOutLocal = fullfile(pathOut, fnOutLocal);
                
                    cmdString = sprintf('imgOut = categorical(imgOutFull(:,:,%d), 0:numel(classNames)-1, classNames);', z);    %#ok<NODEF> % convert to categorial
                    eval(cmdString);
                    save(fnOutLocal, 'imgOut', 'imgVariable', 'options', '-mat', '-v7.3');
                    if saveModelOptions.showWaitbar; waitbar(z/obj.depth, wb); end
                end
            end
    end
    if saveModelOptions.showWaitbar; delete(wb); end
else
    [path, filename, ext] = fileparts(fnOut);
    ext = lower(ext);
    t1 = obj.slices{5}(1);
    t2 = t1;
    
    if obj.time > 1
        button = 'Save as series of 3D datasets';
        if ~ismember(ext, {'.xml', '.h5'})
            if saveModelOptions.silent == 0
                button = questdlg(sprintf('!!! Warning !!!\nIt is not possible to save 4D dataset into a single file!\n\nHowever it is possible to save the currently shown Z-stack, or to make a series of files'), ...
                    'Save model', 'Save as series of 3D datasets', 'Save the currently shown Z-stack', 'Cancel', 'Save as series of 3D datasets');
                if strcmp(button, 'Cancel'); return; end
            end
        end
        if strcmp(button, 'Save as series of 3D datasets')
            t1 = 1;
            t2 = obj.time;
        else
            t1 = obj.getCurrentTimePoint();
            t2 = t1;
        end
    end
    
    showLocalWaitbar = 0;
    if saveModelOptions.showWaitbar
        if t1 ~= t2
            showLocalWaitbar = 1;
            wb = waitbar(0, '', 'Name', 'Saving images...', 'WindowStyle', 'modal');
            wb.Children.Title.Interpreter = 'none';
            waitbar(0, wb, sprintf('Saving %s\nPlease wait...', saveModelOptions.Format));
            drawnow;
            dT = t2-t1+1;
        end
    end
    
    multCoefficient = 1;    % multiply material by this number
    color_list = obj.modelMaterialColors;
    color_list = color_list(1:numel(obj.modelMaterialNames),:);
    modelMaterialNames = obj.modelMaterialNames;
    
    if selMaterial >= 0
        button = 'Proceed, set as 1';
        if saveModelOptions.silent == 0
            button = questdlg(sprintf('You are going to export only material No:%d (%s) !\nProceed?', ...
                selMaterial, obj.modelMaterialNames{selMaterial}), ...
                'Single material export', 'Proceed, set as 1', 'Proceed, set as 255', 'Cancel', 'Proceed, set as 1');
            if strcmp(button, 'Cancel'); return; end
        end
        
        if strcmp(button, 'Proceed, set as 255')
            if ~strcmp(saveModelOptions.Format, 'Isosurface as binary STL (*.stl)'); multCoefficient = 255; end    % do not do that for the STL model type
        end
        color_list = obj.modelMaterialColors(selMaterial,:);
        modelMaterialNames = obj.modelMaterialNames(selMaterial);
    else
        selMaterial = NaN;  % reassign materials to take them all
    end
    
    for t=t1:t2
        if t1~=t2   % generate filename
            fnOutLocal = generateSequentialFilename(filename, t, t2-t1+1, ext);
        else
            fnOutLocal = [filename ext];
        end
        
        getDataOptions.t = [t t];
        model = obj.getData('model', 4, selMaterial, getDataOptions);
        if multCoefficient > 1      % make intensity of the output model as 255
            model = model*multCoefficient;
        end
        
        % add TransformationMatrix for saving with AmiraMesh
        if isKey(obj.meta, 'TransformationMatrix')
            extraOptions.TransformationMatrix = obj.meta('TransformationMatrix');
        else
            extraOptions = struct();
        end
        
        if saveModelOptions.showWaitbar
            showWaitbar = ~showLocalWaitbar;
        else
            showWaitbar = 0;
        end % show or not waitbar in bitmap2amiraMesh
        
        switch saveModelOptions.Format
            case 'Amira mesh binary RLE compression SLOW (*.am)'     % Amira mesh binary RLE compression
                bb = obj.getBoundingBox();
                pixStr = obj.pixSize;
                pixStr.minx = bb(1);
                pixStr.miny = bb(3);
                pixStr.minz = bb(5);
                bitmap2amiraLabels(fullfile(path, fnOutLocal), model, 'binaryRLE', pixStr, color_list, modelMaterialNames, 1, showWaitbar, extraOptions);
            case 'Amira mesh binary (*.am)'     % Amira mesh binary
                bb = obj.getBoundingBox();
                pixStr = obj.pixSize;
                pixStr.minx = bb(1);
                pixStr.miny = bb(3);
                pixStr.minz = bb(5);
                bitmap2amiraLabels(fullfile(path, fnOutLocal), model, 'binary', pixStr, color_list, modelMaterialNames, 1, showWaitbar, extraOptions);
            case 'Amira mesh ascii (*.am)'   % Amira mesh ascii
                bb = obj.getBoundingBox();
                pixStr = obj.pixSize;
                pixStr.minx = bb(1);
                pixStr.miny = bb(3);
                pixStr.minz = bb(5);
                bitmap2amiraLabels(fullfile(path, fnOutLocal), model, 'ascii', pixStr, color_list, modelMaterialNames, 1, showWaitbar, extraOptions);
            case {'Hierarchical Data Format (*.h5)', 'Hierarchical Data Format with XML header (*.xml)'} % hdf5 format
                if t==t1    % getting parameters for saving dataset
                    if saveModelOptions.silent == 0
                        HDFoptions = mibSaveHDF5Dlg(obj);
                    else
                         HDFoptions.Format = 'matlab.hdf5';
                         HDFoptions.SubSampling = [1;1;1];
                         HDFoptions.ChunkSize = [min([64 obj.height]); min([64 obj.width]); min([64 obj.depth])];
                         HDFoptions.Deflate = 0;
                         HDFoptions.xmlCreate = 1;
                    end
                    if isempty(HDFoptions)
                        if showLocalWaitbar; delete(wb); end
                        return;
                    end
                    
                    if strcmp(HDFoptions.Format, 'bdv.hdf5')
                        warndlg('Export of models in using the Big Data Viewer format is not implemented!');
                        if showLocalWaitbar; delete(wb); end
                        return;
                    end
                    HDFoptions.filename = fnOut;
                    ImageDescription = obj.meta('ImageDescription');  % initialize ImageDescription
                end
                
                % permute dataset if needed
                if strcmp(HDFoptions.Format, 'bdv.hdf5')
                    % permute image to swap the X and Y dimensions
                    %model = permute(model, [2 1 5 3 4]);
                else
                    % permute image to add color dimension to position 3
                    model = permute(model, [1 2 4 3]);
                end
                
                if t==t1    % updating parameters for saving dataset
                    HDFoptions.height = size(model, 1);
                    HDFoptions.width = size(model, 2);
                    HDFoptions.colors = 1;
                    if strcmp(HDFoptions.Format, 'bdv.hdf5')
                        %options.depth = size(model,4);
                    else
                        HDFoptions.depth = size(model, 4);
                    end
                    HDFoptions.time = obj.time;
                    HDFoptions.pixSize = obj.pixSize;    % !!! check .units = 'um'
                    HDFoptions.showWaitbar = ~showLocalWaitbar;        % show or not waitbar in data saving function
                    HDFoptions.lutColors = obj.modelMaterialColors;    % store LUT colors for materials
                    HDFoptions.ImageDescription = ImageDescription;
                    HDFoptions.DatasetName = filename;
                    HDFoptions.overwrite = 1;
                    HDFoptions.ModelMaterialNames = obj.modelMaterialNames; % names for materials
                    % saving xml file if needed
                    if HDFoptions.xmlCreate
                        saveXMLheader(HDFoptions.filename, HDFoptions);
                    end
                end
                HDFoptions.t = t;
                switch HDFoptions.Format
                    case 'bdv.hdf5'
                        HDFoptions.pixSize.units = sprintf('\xB5m'); % '?m';
                        saveBigDataViewerFormat(HDFoptions.filename, model, HDFoptions);
                    case 'matlab.hdf5'
                        HDFoptions.order = 'yxczt';
                        image2hdf5(fullfile(path, [filename '.h5']), model, HDFoptions);
                end
            case 'Contours for IMOD (*.mod)'    % Contours for IMOD (*.mod)
                if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                    if saveModelOptions.silent == 0
                        prompt = {'Take each Nth point in contours ( > 0):', 'show detected points in the selection layer'};
                        defAns = {'5', false};
                        answer = mibInputMultiDlg([], prompt, defAns, 'Export to IMOD');
                        if isempty(answer); return; end
                        savingOptions.xyScaleFactor = str2double(answer{1});
                        savingOptions.generateSelectionSw = answer{2};
                    else
                        savingOptions.xyScaleFactor = 5;
                        savingOptions.generateSelectionSw = false;
                    end
                    savingOptions.pixSize = obj.pixSize;
                    savingOptions.zScaleFactor = 1;
                    
                    if isnan(selMaterial)
                        savingOptions.colorList = color_list;
                        savingOptions.ModelMaterialNames = obj.modelMaterialNames; % names for materials;
                    else
                        savingOptions.colorList = color_list(1,:);
                        savingOptions.ModelMaterialNames = obj.modelMaterialNames(selMaterial); % names for materials;
                    end
                    savingOptions.showWaitbar = showWaitbar; % show or not waitbar in exportModelToImodModel
                end
                savingOptions.modelFilename = fullfile(path, fnOutLocal);
                if savingOptions.generateSelectionSw
                    [~, selection] = mibExportModelToImodModel(model, savingOptions);
                    obj.setData('selection', selection, 4, 0, getDataOptions);
                else
                    mibExportModelToImodModel(model, savingOptions);
                end
            case 'Matlab format 2D sequence (*.model)'  % MIB Matlab format 2D sequence
                useOriginalFilenames = false;
                if saveModelOptions.showWaitbar && t1==t2
                    if isKey(obj.meta, 'SliceName') && numel(obj.meta('SliceName'))==size(model,3)
                        answer = questdlg('Would you like to use original filenames or sequential?', ...
                            'Save model as...', ...
                            'Original', 'Sequential', 'Cancel', 'Original');
                        if strcmp(answer, 'Cancel'); return; end
                        if strcmp(answer, 'Original'); useOriginalFilenames = true; end
                        originalFilenames = obj.meta('SliceName');
                        [~, originalFilenames] = arrayfun(@(fn) fileparts(cell2mat(fn)), originalFilenames, 'UniformOutput', false);  % remove extensions
                        %if t1 == t2
                        %    savingOptions.SliceName = arrayfun(@(fn) sprintf('Labels_%s', cell2mat(fn)), obj.meta('SliceName'), 'UniformOutput', false);
                        %else
                        %    savingOptions.SliceName = arrayfun(@(t, fn) sprintf('Labels_t%.3d_%s', t, cell2mat(fn)), repmat(t, [size(model,3), 1]), obj.meta('SliceName'), 'UniformOutput', false);
                        %end
                    end
                    
                    wb2 = waitbar(0, 'Please wait...', 'Name', 'Saving the model', 'WindowStyle', 'modal');
                    wb2.Children.Title.Interpreter = 'none';
                    drawnow;
                end

                % update modelMaterialNames / modelMaterialColors
                modelMaterialNames = obj.modelMaterialNames;
                modelMaterialColors = obj.modelMaterialColors; %#ok<NASGU>
                if ~isnan(selMaterial)
                    if selMaterial < 1
                        modelMaterialNames = {'Exterior'};
                        modelMaterialColors = obj.modelMaterialColors(1, :); %#ok<NASGU>
                    else
                        modelMaterialNames = obj.modelMaterialNames(selMaterial);
                        modelMaterialColors = obj.modelMaterialColors(selMaterial, :); %#ok<NASGU>
                    end
                end

                %modelMaterialNames = obj.modelMaterialNames; %#ok<NASGU>
                %modelMaterialColors = obj.modelMaterialColors; %#ok<NASGU>
                BoundingBox = obj.getBoundingBox(); %#ok<NASGU>
                modelVariable = 'mibModel'; %#ok<NASGU> % name of a variable that has the dataset
                modelType = obj.modelType;  %#ok<NASGU> % type of the model
                
                zMax = size(model, 3);
                [~, fnLocal, extLocal] = fileparts(fnOutLocal);
                
                if obj.hLabels.getLabelsNumber() > 1  % save annotations
                    includeAnnotations = true;
                    [labelText, labelValue, labelPosition] = obj.hLabels.getLabels();
                else
                    includeAnnotations = false;
                end
                                
                for z=1:zMax
                    mibModel = model(:,:,z); %#ok<NASGU>
                    if useOriginalFilenames     % use original filenames
                        if t1==t2
                            fnOut = fullfile(path, sprintf('Labels_%s.model', originalFilenames{z}));
                        else
                            fnOut = fullfile(path, sprintf('Labels_%.3d_%s.model', t, originalFilenames{z}));
                        end
                    else    % use sequential filenames
                        fnOut = generateSequentialFilename(fullfile(path, fnLocal), z, zMax, extLocal);
                    end
                    
                    if saveModelOptions.showWaitbar && t1==t2; waitbar(z/zMax, wb2, sprintf('%s\nPlease wait...', fnOut)); end
                    if includeAnnotations  % save with annotations
                        %[labelText, labelValue, labelPosition] = obj.hLabels.getLabels(z); %#ok<ASGLU>
                        str1 = ['save ''' fnOut '''' ...
                            ' mibModel modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType labelText labelValue labelPosition -mat -v7.3'];
                    else    % save without annotations
                        str1 = ['save ''' fnOut '''' ...
                            ' mibModel modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType -mat -v7.3'];
                    end
                    eval(str1);
                    obj.modelFilename = fnOut;
                end
                if saveModelOptions.showWaitbar && t1==t2; delete(wb2); end
            case 'Volume for IMOD (*.mrc)'     % Volume for IMOD (*.mrc)
                Options.volumeFilename = fullfile(path, fnOutLocal);
                Options.pixSize = obj.pixSize;
                savingOptions.showWaitbar = showWaitbar;  % show or not waitbar in exportModelToImodModel
                mibImage2mrc(model, Options);
            case 'NRRD for 3D Slicer (*.nrrd)'    % NRRD for 3D Slicer (*.nrrd)
                bb = obj.getBoundingBox();
                Options.overwrite = 1;
                Options.showWaitbar = showWaitbar;  % show or not waitbar in bitmap2nrrd
                bitmap2nrrd(fullfile(path, fnOutLocal), model, bb, Options);
            case 'Isosurface as binary STL (*.stl)'  % STL isosurface for Blinder (*.stl)
                bounding_box = obj.getBoundingBox();  % get bounding box
                if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                    if saveModelOptions.silent == 0
                        prompt = {'Reduce the volume down to, width pixels (no volume reduction when 0)?',...
                            'Smoothing 3d kernel, width (no smoothing when 0):',...
                            'Maximal number of faces (no limit when 0):'};
                        if obj.width > 500
                            defAns = {'500', '5', '300000'};
                        else
                            defAns = {'0', '5', '300000'};
                        end
                        mibInputMultiDlgOpt.PromptLines = [2, 1, 1];
                        answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Isosurface parameters', mibInputMultiDlgOpt);
                        if isempty(answer); return; end
                        savingOptions.reduce = str2double(answer{1});
                        savingOptions.smooth = str2double(answer{2});
                        savingOptions.maxFaces = str2double(answer{3});
                    else
                        savingOptions.reduce = 500;
                        savingOptions.smooth = 5;
                        savingOptions.maxFaces = 300000;
                    end
                    savingOptions.slice = 0;
                end

                if isnan(selMaterial)
                    p = mibRenderModel(model, selMaterial, obj.pixSize, bounding_box, obj.modelMaterialColors, NaN, savingOptions);
                    for i=1:numel(p)
                        % check whether the material exists
                        if isa(p(i), 'matlab.graphics.GraphicsPlaceholder')
                            continue; 
                        end
                        fv = struct('faces', p(i).Faces, 'vertices', p(i).Vertices);
                        stlwrite(sprintf('%s_%s.stl', fnOut(1:end-4), obj.modelMaterialNames{i}), fv, 'FaceColor', p(i).FaceColor*255);
                    end
                else
                    p = mibRenderModel(model, 1, obj.pixSize, bounding_box, color_list, NaN, savingOptions);
                    fv.faces = p.Faces;
                    fv.vertices = p.Vertices;
                    stlwrite(sprintf('%s_%s.stl', fnOut(1:end-4), obj.modelMaterialNames{selMaterial}), fv, 'FaceColor', p.FaceColor*255);
                end
            case 'PNG format (*.png)'    % PNG format
                ImageDescription = {obj.meta('ImageDescription')};
                resolution(1) = obj.meta('XResolution');
                resolution(2) = obj.meta('YResolution');
                if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                    savingOptions = struct('overwrite', 1, 'Comment', ImageDescription,...
                        'XResolution', resolution(1), 'YResolution', resolution(2), ...
                        'ResolutionUnit', 'Unknown', 'Reshape', 0);
                    savingOptions.cmap = NaN;
                end
                savingOptions.showWaitbar = showWaitbar;
                if isKey(obj.meta, 'SliceName') && numel(obj.meta('SliceName'))==size(model,3)
                    if t1 == t2
                        savingOptions.SliceName = arrayfun(@(fn) sprintf('Labels_%s', cell2mat(fn)), obj.meta('SliceName'), 'UniformOutput', false);
                    else
                        savingOptions.SliceName = arrayfun(@(t, fn) sprintf('Labels_t%.3d_%s', t, cell2mat(fn)), repmat(t, [size(model,3), 1]), obj.meta('SliceName'), 'UniformOutput', false);
                    end
                    if isfield(saveModelOptions, 'FilenamePolicy') && strcmp(saveModelOptions.FilenamePolicy, 'Use existing name')
                        savingOptions.useOriginals = true;
                    end
                end
                if isfield(saveModelOptions, 'FilenamePolicy') && strcmp(saveModelOptions.FilenamePolicy, 'Use new provided name')
                    savingOptions.useOriginals = false;
                end
                model = reshape(model, [size(model,1) size(model,2) 1 size(model,3)]);

                result = mibImage2png(fullfile(path, fnOutLocal), model, savingOptions);
            case 'TIF format (*.tif)'
                ImageDescription = {obj.meta('ImageDescription')};
                resolution(1) = obj.meta('XResolution');
                resolution(2) = obj.meta('YResolution');
                if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                    savingOptions = struct('Resolution', resolution, 'overwrite', 1, 'Saving3d', NaN, 'cmap', NaN);
                    if isfield(saveModelOptions, 'Saving3DPolicy')
                        if strcmp(saveModelOptions.Saving3DPolicy, '3D stack')
                            savingOptions.Saving3d = 'multi';
                        else
                            savingOptions.Saving3d = 'sequence';
                        end
                    end
                end
                if isKey(obj.meta, 'SliceName') && numel(obj.meta('SliceName'))==size(model,3)
                    if t1 == t2
                        savingOptions.SliceName = arrayfun(@(fn) sprintf('Labels_%s', cell2mat(fn)), obj.meta('SliceName'), 'UniformOutput', false);
                    else
                        savingOptions.SliceName = arrayfun(@(t, fn) sprintf('Labels_t%.3d_%s', t, cell2mat(fn)), repmat(t, [size(model,3), 1]), obj.meta('SliceName'), 'UniformOutput', false);
                    end
                    if isfield(saveModelOptions, 'FilenamePolicy') && strcmp(saveModelOptions.FilenamePolicy, 'Use existing name')
                        savingOptions.useOriginals = true;
                    end
                end
                if isfield(saveModelOptions, 'FilenamePolicy') && strcmp(saveModelOptions.FilenamePolicy, 'Use new provided name')
                    savingOptions.useOriginals = false;
                end

                savingOptions.showWaitbar = showWaitbar;  % show or not waitbar in ib_image2tiff
                model = reshape(model,[size(model,1) size(model,2) 1 size(model,3)]);
                [result, savingOptions] = mibImage2tiff(fullfile(path, fnOutLocal), model, savingOptions, ImageDescription);
                if isfield(savingOptions, 'SliceName'); savingOptions = rmfield(savingOptions, 'SliceName'); end % remove SliceName field when saving series of 2D files
        end
        if showLocalWaitbar;    waitbar(t/dT, wb);    end
    end
    if showLocalWaitbar; delete(wb); end
end

disp(['Model: ' fnOut ' has been saved']);
toc;