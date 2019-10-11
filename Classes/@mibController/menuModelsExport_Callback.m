function menuModelsExport_Callback(obj, ExportTo, BatchOptIn)
% function menuModelsExport_Callback(obj, ExportTo, BatchOptIn)
% callback to Menu->Models->Export
% export the Model layer to the main Matlab workspace
%
% Parameters:
% ExportTo: a string with destination for the export
% @li 'matlab' - to Matlab workspace
% @li 'imaris' - to Imaris
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .ExportTo - cell string, export model to, {'matlab'} or {'imaris'}
% @li .ModelVariable - string, name of variable when exporting to Matlab workspace
% @li .MaterialIndex - string, indices of materials to take, 'All' - to take all, '1 3 5' - take materials with indices 1,3,5 (only for Imaris)
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
%

global mibPath;
if nargin < 2; ExportTo = []; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(ExportTo)
    BatchOpt.ExportTo = {ExportTo};
else
    BatchOpt.ExportTo = {'matlab'};
end
BatchOpt.ExportTo{2} = {'matlab', 'imaris'};
BatchOpt.ModelVariable = 'O';   % variable name to be created in matlab workspace
BatchOpt.MaterialIndex = 'All'; % string with indices of materials to take, 'All' - to take all, '1 3 5' - take materials with indices 1,3,5
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Models';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Export model';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ModelVariable = sprintf('[Matlab export only]\nSpecify name of a variable to be created in the Matlab workspace');
BatchOpt.mibBatchTooltip.MaterialIndex = sprintf('[Imaris export only]\nSpecify indices of materials to be exported or use "All" to export them all');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
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
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'export of models is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

%% Start
switch BatchOpt.ExportTo{1}
    case 'matlab'
        if nargin < 3
            prompt = {'Variable for the structure to keep the model:'};
            title = 'Input a destination variable for export';
            answer = mibInputDlg({mibPath}, prompt, title, 'O');
            if size(answer) == 0; return; end
            BatchOpt.ModelVariable = answer{1};
        end
        if BatchOpt.showWaitbar;  wb = waitbar(0, 'Please wait...', 'Name', 'Exporting the model', 'WindowStyle', 'modal'); end
        
        options.blockModeSwitch = 0;
        options.id = BatchOpt.id;
        O.model = cell2mat(obj.mibModel.getData4D('model', 4, NaN, options));
        if BatchOpt.showWaitbar; waitbar(0.4, wb); end
        O.modelMaterialNames = obj.mibModel.I{BatchOpt.id}.modelMaterialNames;
        O.modelMaterialColors = obj.mibModel.I{BatchOpt.id}.modelMaterialColors;
        O.modelType = obj.mibModel.I{BatchOpt.id}.modelType;    % store the model type
        
        if obj.mibModel.I{BatchOpt.id}.hLabels.getLabelsNumber() > 1  % save annotations
            [O.labelText, O.labelValue, O.labelPosition] = obj.mibModel.I{BatchOpt.id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
        end
        if BatchOpt.showWaitbar; waitbar(0.6, wb); end
        assignin('base', BatchOpt.ModelVariable, O);
        disp(['Model export: created structure ' BatchOpt.ModelVariable ' in the Matlab workspace']);
        if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end
    case 'imaris'
        options.type = 'model';
        if nargin < 3
            % define index of material to model, NaN - model all
            if obj.mibModel.showAllMaterials == 1    % all materials
                options.modelIndex = NaN;
                BatchOpt.MaterialIndex = 'All';
            else
                options.modelIndex = obj.mibModel.I{BatchOpt.id}.getSelectedMaterialIndex();
                BatchOpt.MaterialIndex = num2str(options.modelIndex);
            end
        else
            options.modelIndex = str2num(BatchOpt.MaterialIndex); %#ok<ST2NM>
            if isempty(options.modelIndex); options.modelIndex = NaN; end
        end
        options.showWaitbar = BatchOpt.showWaitbar;
        obj.mibModel.connImaris = mibSetImarisDataset(obj.mibModel.I{BatchOpt.id}, obj.mibModel.connImaris, options);
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

end