function createModel(obj, ModelType, ModelMaterialNames, BatchOptIn)
% function createModel(obj, ModelType, ModelMaterialNames, BatchOptIn)
% Create a new model
%
% Parameters:
% ModelType: [@em optional], can be empty: []; a number with the model type:
% @li 63 - 63 material model
% @li 255 - 255 material model
% @li 65535 - 65535 material model
% @li 4294967295 - 4294967295 material model
% ModelMaterialNames: [@em optional] can be empty: []; a cell array with names of materials, this parameter is not used for ModelType > 255
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .ModelType - cell string, {'63', '255', '65535', '4294967295'} - type of the model to create
% @li .ModelMaterialNames - string, with comma-separated names of materials
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
% 
% Return values:
% 
%

%| 
% @b Examples:
% @code obj.mibModel.createModel();     // create a new model, when used from mibController @endcode
 
% Copyright (C) 28.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 02.09.2019, ported from mibCreateModelBtn_Callback

global mibPath;

if nargin < 3; ModelMaterialNames = []; end
if nargin < 2; ModelType = []; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(ModelType)
    BatchOpt.ModelType = {num2str(ModelType)};
else
    BatchOpt.ModelType = {'63'};
end
BatchOpt.ModelType{2} = {'63', '255', '65535', '4294967295'};
if ~isempty(ModelMaterialNames)
    BatchOpt.ModelMaterialNames = sprintf('%s;', ModelMaterialNames{:});
    BatchOpt.ModelMaterialNames(end) = [];
else
    BatchOpt.ModelMaterialNames = '';
end
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Models';    % section name for the Batch
BatchOpt.mibBatchActionName = 'New model';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ModelType = sprintf('Specify type of the new model; the model type indicates the maximum number of materials. More materials require more memory and slower to work with');
BatchOpt.mibBatchTooltip.ModelMaterialNames = sprintf('[For 63 and 255 only]\nOptionally, specify names for materials as a comma separated list: "mat1, mat2, mat3"');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%% Batch mode check actions
if nargin == 4  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 4rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

%% Initial checks
% check for the virtual stacking mode and return
if obj.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'models are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

% do nothing is selection is disabled
if obj.I{BatchOpt.id}.disableSelection == 1
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The models are disabled','modal');
    notify(obj, 'stopProtocol');
    return; 
end

if obj.I{BatchOpt.id}.modelExist == 1 && nargin < 4
    button = questdlg(sprintf('!!! Warning !!!\nYou are about to start a new model,\n the existing model will be deleted!\n\n'), 'Start new model', 'Continue', 'Cancel', 'Cancel');
    if strcmp(button, 'Cancel'); return; end
end

if isempty(ModelType) && nargin < 4
    BatchOpt.ModelType{1} = num2str(mibSelectModelTypeDlg({mibPath}));
    if isempty(BatchOpt.ModelType{1}); return; end
end
%%
if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Create model', 'WindowStyle', 'modal'); end

switch BatchOpt.ModelType{1}
    case {'63', '255'}
        ModelMaterialNames = BatchOpt.ModelMaterialNames;
        if ~isempty(ModelMaterialNames)     % reshape ModelMaterialNames from string to cell array
            splitCells = regexp(ModelMaterialNames,'([^ ;,]*)','tokens');
            ModelMaterialNames = cat(2, splitCells{:});
        end
        obj.I{BatchOpt.id}.createModel(str2double(BatchOpt.ModelType{1}), ModelMaterialNames);
        %obj.I{BatchOpt.id}.selectedMaterial = 2;
        %obj.I{BatchOpt.id}.selectedAddToMaterial = 2;
    case '65535'
        obj.I{BatchOpt.id}.createModel(65535);
        %obj.I{BatchOpt.id}.selectedMaterial = 3;
        %obj.I{BatchOpt.id}.selectedAddToMaterial = 3;
    case '4294967295'
        obj.I{BatchOpt.id}.createModel(4294967295);
end
if BatchOpt.showWaitbar; waitbar(0.9, wb); end

% last selected contour for use with the 'e' button
obj.I{BatchOpt.id}.lastSegmSelection = [2 1];

notify(obj, 'updateId');    % ask to update widgets of mibGUI
if BatchOpt.showWaitbar; waitbar(0.95, wb); end

eventdata = ToggleEventData(1);   % show the model checkbox on
notify(obj, 'showModel', eventdata);

%obj.updateGuiWidgets();
notify(obj, 'plotImage');

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end
end