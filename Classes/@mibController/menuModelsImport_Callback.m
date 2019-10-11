function menuModelsImport_Callback(obj, BatchOptIn)
% function menuModelsImport_Callback(obj, BatchOptIn)
% callback to Menu->Models->Import;
% import the Model layer from the main Matlab workspace
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details
% @li .ModelVariable - string, name of variable when exporting to Matlab workspace
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Copyright (C) 06.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 11.06.2019 updated for the batch mode

global mibPath;

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.ModelVariable = 'O';
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Models';    % define secion name for the Batch mode
BatchOpt.mibBatchActionName = 'Import model from Matlab';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ModelVariable = sprintf('Specify name of the existing variable in the Matlab workspace to be imported as a new model');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 2nd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
else
    % get list of available variables
    availableVars = evalin('base', 'whos');
    idx = ismember({availableVars.class}, {'uint8', 'uint16', 'uint32', 'struct'});
    if sum(idx) == 0
        errordlg(sprintf('!!! Error !!!\nNothing to import...'), 'Nothing to import');
        return;
    end
    ModelVars = {availableVars(idx).name}';
    ModelClass = {availableVars(idx).class}';
    ModelVarsDetails = ModelClass;
    % add deteiled description to the text
    for i=1:numel(ModelVarsDetails)
        ModelVarsDetails{i} = sprintf('%s: %s', ModelVars{i}, ModelClass{i});
    end
    % find index of the I variable if it is present
    idx2 = find(ismember(ModelVars, 'O')==1);
    if ~isempty(idx2)
        ModelVarsDetails{end+1} = idx2;
    else
        ModelVarsDetails{end+1} = 1;
    end
    prompts = {sprintf('Enter the name of the model variable.\nIt may be a matrix (1:height,1:width,1:z,1:t)\nor a structure with "model" and some extra fields:')};
    defAns = {ModelVarsDetails};
    title = 'Import model from Matlab';
    mibInputMultiDlgOptions.PromptLines = 4;
    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, title, mibInputMultiDlgOptions);
    if isempty(answer); return; end
    %answer(1) = ModelVars(contains(ModelVarsDetails(1:end-1), answer{1})==1);
    BatchOpt.ModelVariable = ModelVars{selIndex(1)};
end

%% initial checks
% check for the virtual stacking mode and return
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'models are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

% do nothing is selection is disabled
if obj.mibModel.I{BatchOpt.id}.disableSelection == 1
    warndlg(sprintf('The model layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The models are disabled', 'modal');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

%%
if ~isempty(BatchOpt.ModelVariable)
    try
        varIn = evalin('base', BatchOpt.ModelVariable);
    catch exception
        errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message), 'Misssing variable!', 'modal');
        notify(obj.mibModel, 'stopProtocol');
        return;
    end
    
    options = struct();
    if isstruct(varIn)
        if isfield(varIn, 'modelVariable')
            options.modelVariable = varIn.modelVariable; 
        else
            options.modelVariable = 'model';
        end
        model = varIn.(options.modelVariable);
        if isfield(varIn, 'modelMaterialNames')
            options.modelMaterialNames = varIn.modelMaterialNames; 
        end
        if isfield(varIn, 'modelMaterialColors')
            %material_colors = varIn.colors;
            options.modelMaterialColors = varIn.modelMaterialColors;
        end
        if isfield(varIn, 'labelText')
            options.labelText = varIn.labelText;
            options.labelPosition = varIn.labelPosition;
            options.labelValue = varIn.labelValue;
        end
        
        if isfield(varIn, 'modelType')
            options.modelType = varIn.modelType;
        else
            maxModelValue = max(max(max(max(model))));
            if maxModelValue < 64
                options.modelType = 63;
            else
                options.modelType = 255;
            end
        end
    else
        model = varIn;
    end
    options.showWaitbar = BatchOpt.showWaitbar;
    options.id = BatchOpt.id;
    obj.mibModel.loadModel(model, options);
    
    % notify the batch mode
    BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
    eventdata = ToggleEventData(BatchOpt);
    notify(obj.mibModel, 'syncBatch', eventdata);
end
