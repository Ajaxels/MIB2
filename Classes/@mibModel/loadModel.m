function loadModel(obj, model, BatchOptIn)
% function loadModel(obj, model, BatchOptIn)
% load model from a file or import when model variable is provided
%
%
% Parameters:
% model: [@em optional], a matrix contaning a model to load [1:obj.height, 1:obj.width, 1:obj.color, 1:obj.no_stacks, 1:obj.time]
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .DirectoryName - cell with directory name
% @li .FilenameFilter - filter for filenames or filename of the model file
% to load, also compatible with template Labels_[F].model, where [F] - is
% filename of the open dataset
% @li .modelMaterialNames - cell array with list of materials
% @li .modelMaterialColors - a matrix with colors for materials
% @li .labelText - a cell array with labels
% @li .labelPosition - a matrix [x, y, z, t] with coordinates of labels
% @li .labelValue - an array of numbers for values of labels
% @li .modelType - a double with type of the model: 63, 255
% @li .modelVariable - an optional string with the name of the model variable
% @li .showWaitbar - show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 
%

%| 
% @b Examples:
% @code obj.mibModel.loadModel();     // call from mibController; load a model @endcode
% @code obj.mibModel.loadModel(model, BatchOptIn);     // call from mibController; import a model @endcode
 
% Copyright (C) 02.09.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates

if nargin < 3; BatchOptIn = struct(); end
if nargin < 2; model = []; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.DirectoryName = {obj.myPath};   % specify the target directory
BatchOpt.DirectoryName{2} = {obj.myPath, 'Inherit from dataset filename'};  % this option forces the directories to be provided from the Dir/File loops
BatchOpt.FilenameFilter = 'Labels_[F].model';
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Models';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Load model';
BatchOpt.mibBatchTooltip.DirectoryName = sprintf('Directory name, where the model file is located, use the right mouse click over the Parameters table to modify the directory');
BatchOpt.mibBatchTooltip.FilenameFilter = sprintf('Filter for filenames: template with [F] - indicates filename of the open dataset; could also be a filename');

BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the waitbar');

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
        
        % additional tweaks, otherwise only the first element is taken
        if isfield(BatchOptIn, 'modelMaterialNames')
            BatchOpt.modelMaterialNames = BatchOptIn.modelMaterialNames;
        end
        if isfield(BatchOptIn, 'labelText')
            BatchOpt.labelText = BatchOptIn.labelText;
        end
    end
    if isempty(model)
        if strcmp(BatchOpt.DirectoryName{1}, 'Inherit from dataset filename')   % update model directory name
            path = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
            if isempty(path)
                BatchOpt.DirectoryName{1} = obj.myPath;
            else
                BatchOpt.DirectoryName{1} = path;
            end
        end
        subFolders = strfind(BatchOpt.FilenameFilter, filesep);     % check for presence of subfolders
        if ~isempty(subFolders)
            BatchOpt.DirectoryName{1} = fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter(1:subFolders(end)));
            BatchOpt.FilenameFilter = BatchOpt.FilenameFilter(subFolders(end)+1:end);
        end
    
        templateDetection = strfind(BatchOpt.FilenameFilter, '[');  % detect [F] template
        if ~isempty(templateDetection)
            [path, fn] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
            BatchOpt.FilenameFilter = sprintf('%s%s%s', ...
                BatchOpt.FilenameFilter(1:templateDetection(1)-1), fn, BatchOpt.FilenameFilter(templateDetection(1)+3:end));
        end
    
        filename = dir(fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter));   % get list of files
        filename2 = arrayfun(@(filename) fullfile(BatchOpt.DirectoryName{1}, filename.name), filename, 'UniformOutput', false);  % generate full paths
        notDirsIndices = arrayfun(@(filename2) ~isdir(cell2mat(filename2)), filename2);     % get indices of not directories
        fn = filename2(notDirsIndices);     % generate full path file names
        filename = {filename(notDirsIndices).name}';
        if isempty(filename)
            errordlg(sprintf('!!! Error !!!\n\nLoad model: wrong model name:\n%s', fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter)));
            notify(obj, 'stopProtocol');
            return;
        end
    end
    batchModeSwitch = 1;    % indicates that the function is running in the batch mode
else
    [filename, BatchOpt.DirectoryName{1}] = uigetfile(...
        {'*.model;',  'Matlab format (*.model)'; ...
        '*.mat;',  'Matlab format (*.mat)'; ...
        '*.am;',  'Amira mesh format (*.am)'; ...
        '*.h5',   'Hierarchical Data Format (*.h5)'; ...
        '*.mrc',   'Medical Research Council format (*.mrc)'; ...
        '*.nrrd;',  'NRRD format (*.nrrd)'; ...
        '*.tif;',  'TIF format (*.tif)'; ...
        '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open model data...', BatchOpt.DirectoryName{1}, 'MultiSelect', 'on');
    if isequal(filename, 0); return; end % check for cancel
    if ischar(filename); filename = cellstr(filename); end     % convert to cell type
    
    batchModeSwitch = 0;    % indicates that the function is running in the gui mode
end

% check for the virtual stacking mode and return
if obj.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'models are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

tic
obj.I{BatchOpt.id}.blockModeSwitch = 0;  % disable the blockMode
if ~isfield(BatchOpt, 'showWaitbar'); BatchOpt.showWaitbar = true; end

if isempty(model) % model and BatchOpt were not provided, load model from a file
    % create a new model if it is not yet created
    if obj.I{BatchOpt.id}.modelExist == 0
        CreateModelOpt.showWaitbar = BatchOpt.showWaitbar;
        obj.createModel(63, [], CreateModelOpt);
    elseif ~batchModeSwitch
        button = questdlg(sprintf('!!! Warning !!!\nYou are about to start a new model,\n the existing model will be deleted!\n\n'),'Start new model','Continue','Cancel','Cancel');
        if strcmp(button, 'Cancel'); return; end
    end
    
    BatchOpt.imgStretch = 0;     % turn off conversion of images from uint32 to uint16 class
    BatchOpt.BioFormatsMemoizerMemoDir = obj.preferences.dirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats
    
    if BatchOpt.showWaitbar
        warning('off', 'MATLAB:handle_graphics:exceptions:SceneNode');
        wb = waitbar(0,sprintf('%s\nPlease wait.',filename{1}), 'Name', 'Loading model', 'WindowStyle', 'modal');
        wb.Children.Title.Interpreter = 'none';
        drawnow;
    end
    
    for fnId = 1:numel(filename)
        if ismember(filename{fnId}(end-3:end), {'.mat', 'odel'}) % loading model in the matlab format
            res = load(fullfile(BatchOpt.DirectoryName{1}, filename{fnId}), '-mat');
            BatchOpt.model_fn = fullfile(BatchOpt.DirectoryName{1}, filename{1});
            Fields = fieldnames(res);
            % find a field name for the data
            if ismember('modelVariable', Fields)
                BatchOpt.modelVariable = res.(Fields{ismember(Fields, 'modelVariable')});
            elseif ismember('model_var', Fields)
                BatchOpt.modelVariable = res.(Fields{ismember(Fields, 'model_var')});    % mib version 1
            else
                for field = 1:numel(Fields)
                    if ismember(Fields{field}, {'material_list', 'labelText', 'labelPosition','color_list','bounding_box','modelMaterialNames','modelMaterialColors','BoundingBox'}) == 0
                        BatchOpt.modelVariable = Fields{field};
                    end
                end
            end
            model = res.(BatchOpt.modelVariable);
            if isfield(res, 'modelMaterialNames')
                BatchOpt.material_list = res.modelMaterialNames;
            elseif isfield(res, 'material_list')    % mib version 1
                BatchOpt.material_list = res.material_list;
            else    % was using permute earlier to to match height and width with the image
                model = permute(model,[2 1 3 4]); %#ok<NODEF>
            end
            if isfield(res, 'modelMaterialColors')
                BatchOpt.color_list = res.modelMaterialColors; %#ok<NASGU>
            elseif isfield(res, 'color_list')
                BatchOpt.color_list = res.color_list; %#ok<NASGU>
            end
            
            % get the type of the model
            if isfield(res, 'modelType')
                BatchOpt.modelType = res.modelType;
            end
            
            % add labels labels
            if isfield(res, 'labelText')
                BatchOpt.labelText = res.labelText;
                BatchOpt.labelPosition = res.labelPosition;
                if isfield(res, 'labelValues'); BatchOpt.labelValue = res.labelValues; end   % old naming of the field before 2.5
                if isfield(res, 'labelValue'); BatchOpt.labelValue = res.labelValue; end
            end
            clear res;
        elseif strcmp(filename{fnId}(end-1:end),'am') % loading amira mesh
            [~, img_info] = getAmiraMeshHeader(fullfile(BatchOpt.DirectoryName{1}, filename{fnId}));
            try
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
                            modelMaterialColors(materialIndex, :) = materialColor(1:3); %#ok<AGROW>
                            modelMaterialNames{materialIndex, :} = matName(1:end-6); %#ok<AGROW>
                            keyId = keyId + 1; %#ok<FXSET>
                        end
                    end
                end
                BatchOpt.color_list = modelMaterialColors;
                BatchOpt.material_list = modelMaterialNames;
            catch err
                err;
                notify(obj, 'stopProtocol'); 
            end
            model = amiraLabels2bitmap(fullfile(BatchOpt.DirectoryName{1}, filename{fnId}));
            BatchOpt.model_fn = fullfile(BatchOpt.DirectoryName{1}, [filename{1}(1:end-2) 'model']);
            BatchOpt.modelVariable = 'amira_mesh';
        elseif strcmp(filename{fnId}(end-1:end),'h5') || strcmp(filename{fnId}(end-2:end),'xml')  % loading model in hdf5 format
            BatchOpt.mibBioformatsCheck = 0;
            BatchOpt.waitbar = 0;
            [model, img_info, ~] = mibLoadImages({fullfile(BatchOpt.DirectoryName{1}, filename{fnId})}, BatchOpt);
            %model = squeeze(model);
            model = permute(model, [1 2 4 5 3]);    % remove 3rd dimension, i.e. color
            BatchOpt.model_fn = fullfile(BatchOpt.DirectoryName{1}, [filename{1}(1:end-2) 'model']);
            BatchOpt.modelVariable = 'hdf5';
            if isKey(img_info, 'material_list')     % add list of material names
                BatchOpt.material_list = img_info('material_list');
            end
            if isKey(img_info, 'color_list')     % add list of colors for materials
                BatchOpt.color_list = img_info('color_list');
            end
            delete(img_info);
        elseif strcmp(filename{fnId}(end-3:end),'nrrd') % loading model in nrrd format
            model = nrrdLoadWithMetadata(fullfile(BatchOpt.DirectoryName{1}, filename{fnId}));
            model =  uint8(permute(model.data, [2 1 3]));
            BatchOpt.model_fn = fullfile(BatchOpt.DirectoryName{1}, [filename{fnId}(1:end-2) 'model']);
            BatchOpt.modelVariable = 'nrrd_model';
        elseif strcmp(filename{fnId}(end-3:end),'mrc') % loading model in mrc format            
            BatchOpt.mibBioformatsCheck = 0;
            BatchOpt.waitbar = 0;
            for i=1:numel(filename)
                [model, ~, ~] = mibLoadImages({fullfile(BatchOpt.DirectoryName{1}, filename{fnId})}, BatchOpt);
            end
        else        % loading model in tif format and other standard formats
            BatchOpt.mibBioformatsCheck = 0;
            BatchOpt.waitbar = 0;
            [model, ~, ~] = mibLoadImages({fullfile(BatchOpt.DirectoryName{1}, filename{fnId})}, BatchOpt);
            model =  squeeze(model);
            BatchOpt.model_fn = fullfile(BatchOpt.DirectoryName{1}, [filename{1}(1:end-3) 'model']);
            BatchOpt.modelVariable = 'tif_model';
        end
        
        % check H/W/Z dimensions
        if size(model, 1) ~= obj.I{BatchOpt.id}.height || size(model,2) ~= obj.I{BatchOpt.id}.width
            if BatchOpt.showWaitbar; delete(wb); end
            notify(obj, 'stopProtocol');
            msgbox(sprintf('Model and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nModel (HxWxZ) = %d x %d x %d pixels',...
                obj.I{BatchOpt.id}.height, obj.I{BatchOpt.id}.width, obj.I{BatchOpt.id}.depth, size(model,1), size(model,2), size(model,3)),'Error!','error','modal');
            return;
        end
        
        if size(model,3) ~= obj.I{BatchOpt.id}.depth && size(model,3) > 1
            if BatchOpt.showWaitbar; delete(wb); end
            notify(obj, 'stopProtocol');
            msgbox(sprintf('Model and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nModel (HxWxZ) = %d x %d x %d pixels',...
                obj.I{BatchOpt.id}.height, obj.I{BatchOpt.id}.width, obj.I{BatchOpt.id}.depth, size(model,1), size(model,2), size(model,3)),'Error!','error','modal');
            return;
        end
        
        % get the type of the model
        if ~isfield(BatchOpt, 'modelType')
            switch class(model)
                case 'uint8'
                    maxModelValue = max(max(max(max(model))));
                    if maxModelValue < 64
                        BatchOpt.modelType = 63;
                    else
                        BatchOpt.modelType = 255;
                    end
                case 'uint16'
                    BatchOpt.modelType = 65535;
                case 'uint32'
                    BatchOpt.modelType = 4294967295;
                otherwise
                    errordlg('This model type is not yet implemented! Convert the model into one of the following classes: uint8, uint16, uint32', 'Too many materials');
                    notify(obj, 'stopProtocol'); 
                    if BatchOpt.showWaitbar; delete(wb); end
            end
        end
        
        if BatchOpt.modelType ~= obj.I{BatchOpt.id}.modelType
            obj.I{BatchOpt.id}.convertModel(BatchOpt.modelType);
        end
        
        if size(model, 4) > 1 && size(model, 4) == obj.I{BatchOpt.id}.time   % update complete 4D dataset
            obj.setData4D('model', {model}, 4, NaN, BatchOpt);
        elseif size(model, 4) == 1 && size(model,3) == obj.I{BatchOpt.id}.depth  % update complete 3D dataset
            if numel(filename) > 1
                if strcmp(filename{fnId}(end-2:end),'mrc') % loading model in the MRC format
                    if fnId == 1
                        % get current model
                        cModel = cell2mat(obj.getData3D('model', NaN, 4, NaN, BatchOpt));
                        BatchOpt.material_list = cell([numel(filename), 1]);
                    end
                    cModel(model ~= 0) = model(model ~= 0);
                    BatchOpt.material_list{fnId} = filename{fnId}(1:end-4);
                    if fnId == numel(filename)
                        % update the model
                        obj.setData3D('model', {cModel}, NaN, 4, NaN, BatchOpt);
                    end
                else
                    obj.setData3D('model', {model}, fnId, 4, NaN, BatchOpt);
                end
            else
                obj.setData3D('model', {model}, NaN, 4, NaN, BatchOpt);
            end
        elseif size(model, 3) == 1
            if numel(filename) > 1
                obj.setData2D('model', {model}, fnId, 4, NaN, BatchOpt);
            else
                obj.setData2D('model', {model}, NaN, 4, NaN, BatchOpt);
            end
        end
        if BatchOpt.showWaitbar; waitbar(fnId/numel(filename),wb); end
    end
else
    if BatchOpt.showWaitbar; wb = waitbar(0,sprintf('Importing a model\nPlease wait.'), 'Name', 'Loading model', 'WindowStyle', 'modal'); end
    
    [pathTemp, fnTemplate] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
    
    if ~isfield(BatchOpt, 'model_fn'); BatchOpt.model_fn = fullfile(pathTemp, ['Labels_' fnTemplate '.model']); end
    if ~isfield(BatchOpt, 'modelVariable'); BatchOpt.modelVariable = 'mibModel'; end
    if isfield(BatchOpt, 'labelValues'); BatchOpt.labelValue = BatchOpt.labelValues; BatchOpt = rmfield(BatchOpt, 'labelValues'); end    % old name of the field, before MIB 2.5
    
    % check H/W/Z dimensions
    if size(model, 1) ~= obj.I{BatchOpt.id}.height || size(model,2) ~= obj.I{BatchOpt.id}.width || size(model,3) ~= obj.I{BatchOpt.id}.depth
        if BatchOpt.showWaitbar; delete(wb); end
        notify(obj, 'stopProtocol');
        msgbox(sprintf('Model and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nModel (HxWxZ) = %d x %d x %d pixels',...
            obj.I{BatchOpt.id}.height, obj.I{BatchOpt.id}.width, obj.I{BatchOpt.id}.depth, size(model,1), size(model,2), size(model,3)),'Error!','error','modal');
        return;
    end
    
    % get the type of the model
    if ~isfield(BatchOpt, 'modelType')
        switch class(model)
            case 'uint8'
                maxModelValue = max(max(max(max(model))));
                if maxModelValue < 64
                    BatchOpt.modelType = 63;
                else
                    BatchOpt.modelType = 255;
                end
            case 'uint16'
                BatchOpt.modelType = 65535;
            case 'uint32'
                BatchOpt.modelType = 4294967295;
            otherwise
                errordlg('This model type is not yet implemented! Convert the model into one of the following classes: uint8, uint16, uint32', 'Too many materials');
                notify(obj, 'stopProtocol'); 
                if BatchOpt.showWaitbar; delete(wb); end
        end
    end
    
    if BatchOpt.modelType ~= obj.I{BatchOpt.id}.modelType 
        if obj.I{BatchOpt.id}.modelExist
            obj.I{BatchOpt.id}.convertModel(BatchOpt.modelType);
        else
            obj.I{BatchOpt.id}.createModel(BatchOpt.modelType);
        end
    end
    
    if size(model, 4) > 1 && size(model, 4) == obj.I{BatchOpt.id}.time   % update complete 4D dataset
        obj.setData4D('model', {model}, 4, NaN, BatchOpt);
    elseif size(model, 4) == 1 && size(model,3) == obj.I{BatchOpt.id}.depth  % update complete 3D dataset
        obj.setData3D('model', {model}, NaN, 4, NaN, BatchOpt);
    elseif size(model, 3) == 1
        obj.setData2D('model', {model}, NaN, 4, NaN, BatchOpt);
    else
        
    end
end

if isfield(BatchOpt, 'material_list')
    obj.I{BatchOpt.id}.modelMaterialNames = BatchOpt.material_list;
elseif isfield(BatchOpt, 'modelMaterialNames')
    obj.I{BatchOpt.id}.modelMaterialNames = BatchOpt.modelMaterialNames;
else
    switch class(model)
        case 'uint8'
            max_color = max(max(max(max(model))));
            if max_color > 0
                obj.I{BatchOpt.id}.modelMaterialNames = cell(max_color, 1);
                for i=1:max_color
                    obj.I{BatchOpt.id}.modelMaterialNames(i,1) = cellstr(num2str(i));
                end
            end
        case 'uint16'
            obj.I{BatchOpt.id}.modelMaterialNames = {'1','2'}';
        case 'uint32'
            obj.I{BatchOpt.id}.modelMaterialNames = {'1','2'}';
    end
end

if isfield(BatchOpt, 'color_list')
    obj.I{BatchOpt.id}.modelMaterialColors = BatchOpt.color_list;
elseif isfield(BatchOpt, 'modelMaterialColors')
    obj.I{BatchOpt.id}.modelMaterialColors = BatchOpt.modelMaterialColors;
else
    switch class(model)
        case 'uint8'
            max_color = numel(obj.I{BatchOpt.id}.modelMaterialNames);
            obj.I{BatchOpt.id}.modelMaterialColors = obj.preferences.modelMaterialColors(1:min([max_color, size(obj.preferences.modelMaterialColors,1)]), :);
        case 'uint16'
            obj.I{BatchOpt.id}.modelMaterialColors = rand([65535,3]);
        case 'uint32'
            obj.I{BatchOpt.id}.modelMaterialColors = rand([65535,3]);
    end
end

% adding extra colors if needed
if isa(model, 'uint8')
    max_color = numel(obj.I{BatchOpt.id}.modelMaterialNames);
    if max_color > size(obj.I{BatchOpt.id}.modelMaterialColors,1)
        minId = size(obj.I{BatchOpt.id}.modelMaterialColors,1)+1;
        maxId = max_color;
        obj.I{BatchOpt.id}.modelMaterialColors = [obj.I{BatchOpt.id}.modelMaterialColors; rand([maxId-minId+1,3])];
    end
else
    max_color = size(obj.I{BatchOpt.id}.modelMaterialColors, 1);
    if max_color < 65535
        obj.I{BatchOpt.id}.modelMaterialColors = [obj.I{BatchOpt.id}.modelMaterialColors; rand([65535-max_color, 3])];
    end
end

% add annotations
if isfield(BatchOpt, 'labelText')
    obj.I{BatchOpt.id}.hLabels.clearContents();    % clear current labels
    if isfield(BatchOpt, 'labelValue')
        obj.I{BatchOpt.id}.hLabels.addLabels(BatchOpt.labelText, BatchOpt.labelPosition, BatchOpt.labelValue);
    else
        obj.I{BatchOpt.id}.hLabels.addLabels(BatchOpt.labelText, BatchOpt.labelPosition);
    end
end

obj.I{BatchOpt.id}.modelFilename = BatchOpt.model_fn;
obj.I{BatchOpt.id}.modelVariable = BatchOpt.modelVariable;

notify(obj, 'updateId');    % ask to update widgets of mibGUI
obj.I{BatchOpt.id}.lastSegmSelection = [2 1];
if BatchOpt.showWaitbar; waitbar(1,wb); end

eventdata = ToggleEventData(1);   % show the model checkbox on
notify(obj, 'showModel', eventdata);

if BatchOpt.showWaitbar; delete(wb); end
toc
end