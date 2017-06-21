function mibLoadModelBtn_Callback(obj, model, options)
% function mibLoadModelBtn_Callback(obj, model, options)
% callback to the obj.mibView.handles.mibLoadModelBtn, loads model to MIB from a file
%
%
% Parameters:
% model: [@em optional], a matrix contaning a model to load [1:obj.height, 1:obj.width, 1:obj.color, 1:obj.no_stacks, 1:obj.time]
% options: [@em optional], a structure with additional parameters:
% @li .modelMaterialNames - cell array with list of materials
% @li .modelMaterialColors - a matrix with colors for materials
% @li .labelText - a cell array with labels
% @li .labelPosition - a matrix [x, y, z, t] with coordinates of labels
% @li .modelType - a double with type of the model: 63, 255
% @li .modelVariable - an optional string with the name of the model variable
%
% Return values:
% 
%

%| 
% @b Examples:
% @code obj.mibLoadModelBtn_Callback();     // call from mibController; load a model @endcode
% @code obj.mibLoadModelBtn_Callback(model, options);     // call from mibController; load a model @endcode
 
% Copyright (C) 28.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

tic
obj.mibModel.setImageProperty('blockModeSwitch', 0);  % disable the blockMode
if nargin < 2   % model and options were not provided
    % load Model from a file
    unFocus(obj.mibView.handles.mibLoadModelBtn);   % remove focus from hObject
    
    [filename, path] = uigetfile(...
        {'*.model;',  'Matlab format (*.model)'; ...
        '*.mat;',  'Matlab format (*.mat)'; ...
        '*.am;',  'Amira mesh format (*.am)'; ...
        '*.h5',   'Hierarchical Data Format (*.h5)'; ...
        '*.mrc',   'Medical Research Council format (*.mrc)'; ...
        '*.nrrd;',  'NRRD format (*.nrrd)'; ...
        '*.tif;',  'TIF format (*.tif)'; ...
        '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open model data...', obj.mibModel.myPath, 'MultiSelect','on');
    if isequal(filename, 0); return; end % check for cancel
    if ischar(filename); filename = cellstr(filename); end     % convert to cell type
    
    % create a new model if it is not yet created
    if obj.mibModel.getImageProperty('modelExist') == 0
        obj.mibCreateModelBtn_Callback(63);
    else
        button = questdlg(sprintf('!!! Warning !!!\nYou are about to start a new model,\n the existing model will be deleted!\n\n'),'Start new model','Continue','Cancel','Cancel');
        if strcmp(button, 'Cancel'); return; end
    end
    
    wb = waitbar(0,sprintf('%s\nPlease wait...',filename{1}),'Name','Loading model','WindowStyle','modal');
    set(findall(wb,'type','text'),'Interpreter','none');
    waitbar(0, wb);
    options = struct();
    
    for fnId = 1:numel(filename)
        if ismember(filename{fnId}(end-3:end), {'.mat', 'odel'}) % loading model in the matlab format
            res = load([path filename{fnId}], '-mat');
            options.model_fn = fullfile([path filename{1}]);
            Fields = fieldnames(res);
            % find a field name for the data
            if ismember('modelVariable', Fields)
                options.modelVariable = res.(Fields{ismember(Fields, 'modelVariable')});
            elseif ismember('model_var', Fields)
                options.modelVariable = res.(Fields{ismember(Fields, 'model_var')});    % mib version 1
            else
                for field = 1:numel(Fields)
                    if ismember(Fields{field}, {'material_list', 'labelText', 'labelPosition','color_list','bounding_box','modelMaterialNames','modelMaterialColors','BoundingBox'}) == 0
                        options.modelVariable = Fields{field};
                    end
                end
            end
            model = res.(options.modelVariable);
            if isfield(res, 'modelMaterialNames')
                options.material_list = res.modelMaterialNames;
            elseif isfield(res, 'material_list')    % mib version 1
                options.material_list = res.material_list;
            else    % was using permute earlier to to match height and width with the image
                model = permute(model,[2 1 3 4]); %#ok<NODEF>
            end
            if isfield(res, 'modelMaterialColors')
                options.color_list = res.modelMaterialColors; %#ok<NASGU>
            elseif isfield(res, 'color_list')
                options.color_list = res.color_list; %#ok<NASGU>
            end
            
            % get the type of the model
            if isfield(res, 'modelType')
                options.modelType = res.modelType;
            end
            
            % add labels labels
            if isfield(res, 'labelText')
                options.labelText = res.labelText;
                options.labelPosition = res.labelPosition;
            end
            clear res;
        elseif strcmp(filename{fnId}(end-1:end),'am') % loading amira mesh
            model = amiraLabels2bitmap(fullfile([path filename{fnId}]));
            options.model_fn = fullfile([path filename{1}(1:end-2) 'mat']);
            options.modelVariable = 'amira_mesh';
        elseif strcmp(filename{fnId}(end-1:end),'h5') || strcmp(filename{fnId}(end-2:end),'xml')  % loading model in hdf5 format
            options.mibBioformatsCheck = 0;
            options.waitbar = 0;
            [model, img_info, ~] = mibLoadImages({fullfile(path, filename{fnId})}, options);
            model = squeeze(model);
            options.model_fn = fullfile([path filename{1}(1:end-2) 'mat']);
            options.modelVariable = 'hdf5';
            if isKey(img_info, 'material_list')     % add list of material names
                options.material_list = img_info('material_list');
            end
            if isKey(img_info, 'color_list')     % add list of colors for materials
                options.color_list = img_info('color_list');
            end
            delete(img_info);
        elseif strcmp(filename{fnId}(end-3:end),'nrrd') % loading model in nrrd format
            model = nrrdLoadWithMetadata(fullfile([path filename{fnId}]));
            model =  uint8(permute(model.data, [2 1 3]));
            options.model_fn = fullfile([path filename{fnId}(1:end-2) 'mat']);
            options.modelVariable = 'nrrd_model';
        elseif strcmp(filename{fnId}(end-3:end),'mrc') % loading model in mrc format            
            options.mibBioformatsCheck = 0;
            options.waitbar = 0;
            for i=1:numel(filename)
                [model, ~, ~] = mibLoadImages({fullfile(path, filename{fnId})}, options);
            end
        else        % loading model in tif format and other standard formats
            options.mibBioformatsCheck = 0;
            options.waitbar = 0;
            [model, ~, ~] = mibLoadImages({fullfile(path, filename{fnId})}, options);
            model =  squeeze(model);
            options.model_fn = fullfile(path, [filename{1}(1:end-3) 'mat']);
            options.modelVariable = 'tif_model';
        end
        
        % check H/W/Z dimensions
        if size(model, 1) ~= obj.mibModel.I{obj.mibModel.Id}.height || size(model,2) ~= obj.mibModel.I{obj.mibModel.Id}.width %|| size(model,3) ~= obj.mibModel.I{obj.mibModel.Id}.depth
            if exist('wb','var'); delete(wb); end
            msgbox(sprintf('Model and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nModel (HxWxZ) = %d x %d x %d pixels',...
                obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width, obj.mibModel.I{obj.mibModel.Id}.depth, size(model,1), size(model,2), size(model,3)),'Error!','error','modal');
            return;
        end
        
        % get the type of the model
        if ~isfield(options, 'modelType')
            maxModelValue = max(max(max(max(model))));
            if maxModelValue < 64
                options.modelType = 63;
            else
                options.modelType = 255;
            end
        end
        
        if options.modelType ~= obj.mibModel.I{obj.mibModel.Id}.modelType
            obj.mibModel.I{obj.mibModel.Id}.convertModel(options.modelType);
        end
        
        if size(model, 4) > 1 && size(model, 4) == obj.mibModel.I{obj.mibModel.Id}.time   % update complete 4D dataset
            obj.mibModel.setData4D('model', {model}, 4);
        elseif size(model, 4) == 1 && size(model,3) == obj.mibModel.I{obj.mibModel.Id}.depth  % update complete 3D dataset
            if numel(filename) > 1
                if strcmp(filename{fnId}(end-2:end),'mrc') % loading model in the MRC format
                    if fnId == 1
                        % get current model
                        cModel = cell2mat(obj.mibModel.getData3D('model', NaN, 4));
                        options.material_list = cell([numel(filename), 1]);
                    end
                    cModel(model ~= 0) = model(model ~= 0);
                    options.material_list{fnId} = filename{fnId}(1:end-4);
                    if fnId == numel(filename)
                        % update the model
                        obj.mibModel.setData3D('model', {cModel}, NaN, 4);
                    end
                else
                    obj.mibModel.setData3D('model', {model}, fnId, 4);
                end
            else
                obj.mibModel.setData3D('model', {model}, NaN, 4);
            end
        elseif size(model, 3) == 1
            if numel(filename) > 1
                obj.mibModel.setData2D('model', {model}, fnId, 4);
            else
                obj.mibModel.setData2D('model', {model}, NaN, 4);
            end
        end
        waitbar(fnId/numel(filename),wb);
    end
else
    wb = waitbar(0,sprintf('Importing a model\nPlease wait...'), 'Name', 'Loading model', 'WindowStyle', 'modal');
    if nargin < 3
        options = struct();
    end
    [pathTemp, fnTemplate] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
    
    if ~isfield(options, 'model_fn')
        options.model_fn = fullfile(pathTemp, ['Labels_' fnTemplate '.model']);
    end
    
    
    if ~isfield(options, 'modelVariable')
        options.modelVariable = 'mibModel';
    end
    
    % check H/W/Z dimensions
    if size(model, 1) ~= obj.mibModel.I{obj.mibModel.Id}.height || size(model,2) ~= obj.mibModel.I{obj.mibModel.Id}.width || size(model,3) ~= obj.mibModel.I{obj.mibModel.Id}.depth
        if exist('wb','var'); delete(wb); end
        msgbox(sprintf('Model and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nModel (HxWxZ) = %d x %d x %d pixels',...
            obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width, obj.mibModel.I{obj.mibModel.Id}.depth, size(model,1), size(model,2), size(model,3)),'Error!','error','modal');
        return;
    end
    
    % get the type of the model
    if ~isfield(options, 'modelType')
        maxModelValue = max(max(max(max(model))));
        if maxModelValue < 64
            options.modelType = 63;
        else
            options.modelType = 255;
        end
    end
    
    if options.modelType ~= obj.mibModel.I{obj.mibModel.Id}.modelType
        obj.mibModel.I{obj.mibModel.Id}.convertModel(options.modelType);
    end
    
    if size(model, 4) > 1 && size(model, 4) == obj.mibModel.I{obj.mibModel.Id}.time   % update complete 4D dataset
        obj.mibModel.setData4D('model', {model}, 4);
    elseif size(model, 4) == 1 && size(model,3) == obj.mibModel.I{obj.mibModel.Id}.depth  % update complete 3D dataset
        obj.mibModel.setData3D('model', {model}, NaN, 4);
    elseif size(model, 3) == 1
        obj.mibModel.setData2D('model', {model}, NaN, 4);
    else
        
    end
end

if isfield(options, 'material_list')
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = options.material_list;
    max_color = numel(options.material_list);
elseif isfield(options, 'modelMaterialNames')
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = options.modelMaterialNames;
    max_color = numel(options.modelMaterialNames);
else
    max_color = max(max(max(max(model))));
    if max_color > 0
        obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = cell(max_color, 1);
        for i=1:max_color
            obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(i,1) = cellstr(num2str(i));
        end
    end
end
if isfield(options, 'color_list')
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = options.color_list;
elseif isfield(options, 'modelMaterialColors')
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = options.modelMaterialColors;
else
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = obj.mibModel.preferences.modelMaterialColors(1:min([max_color, size(obj.mibModel.preferences.modelMaterialColors,1)]), :);
end
% adding extra colors if needed
if max_color > size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors,1)
    minId = size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors,1)+1;
    maxId = max_color;
    obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = [obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors; rand([maxId-minId+1,3])];
end
% add annotations
if isfield(options, 'labelText')
    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(options.labelText, options.labelPosition);
end

obj.mibModel.I{obj.mibModel.Id}.modelFilename = options.model_fn;
obj.mibModel.I{obj.mibModel.Id}.modelVariable = options.modelVariable;

%obj.updateSegmentationTable();
obj.updateGuiWidgets();
obj.mibView.lastSegmSelection = 1;
waitbar(1,wb);
obj.mibView.handles.mibModelShowCheck.Value = 1;
obj.mibModelShowCheck_Callback();

delete(wb);
toc
end