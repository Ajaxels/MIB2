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
% Date: 12.03.2025

function status = modelExport(obj, BatchOptIn)
% function status = modelExport(obj, BatchOptIn)
% export model or material of the model from MIB to exportTo
%
% Parameters:
% BatchOptIn: [optional] a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details; 
%   default values in BatchOpt below are overriden by settings from
%   BatchOptIn, when BatchOptIn.batchModeFlag==true, no question asked
% @li .ExportTo - cell string with these options
%       'matlab' - export to MATLAB
%       'imaris' - export to Imaris
% @li .MaterialOutputVariable - string with output variable for MATLAB export
% @li .MaterialIndex - string, index of materials to export
% @li .MaterialOutputIndex - string, index that material gets after export (typically, 1 or 255)
% @li .showWaitbar - logical, show or not the waitbar
% @li .batchModeFlag - logical, when 1 do not ask any questions
%
% Return values:
% status: logical status of the function

%| 
% @b Examples:
% @code
% BatchOptIn.ExportTo = 'matlab';
% BatchOptIn.MaterialIndex = '3';
% BatchOptIn.MaterialOutputIndex = '255'
% obj.mibModel.modelExport(BatchOptIn); // call from mibController class; export material 3 from the model and assign it to value 255, ask question to confirm values
% @endcode
% @code 
% BatchOptIn.ExportTo = 'matlab';
% BatchOptIn.batchModeFlag = true;
% obj.mibModel.materialsActions(BatchOptIn); // call from mibController class; export the whole model to MATLAB, no questions asked
% @endcode

% Updates

global mibPath;
status = false; % status of the function

% populate BatchOpt with default values
BatchOpt = struct();
BatchOpt.ExportTo = {'matlab'};
BatchOpt.ExportTo{2} = {'matlab', 'imaris'};  % cell array with the list of available actions
BatchOpt.id = obj.Id;   % optional, id
if obj.I{obj.Id}.selectedMaterial > 2
    if obj.I{obj.Id}.modelType > 256
        materialIndex = str2double(obj.I{obj.Id}.modelMaterialNames{obj.I{obj.Id}.selectedMaterial - 2}); % index of the selected material
    else
        materialIndex = obj.I{obj.Id}.selectedMaterial - 2; % index of the selected material
    end
    BatchOpt.MaterialOutputVariable = ['Export_' obj.I{BatchOpt.id}.modelMaterialNames{materialIndex}];
else
    BatchOpt.MaterialOutputVariable = 'O'; % variable that will be created in MATLAB main workspace
end
BatchOpt.MaterialIndex = ''; % no index, export the whole model
BatchOpt.MaterialOutputIndex = '1'; % by default use index 1 when a single material exported
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
% additional
BatchOpt.batchModeFlag =  false; % indicate that the function was not started from batch processing

BatchOpt.mibBatchSectionName = 'Menu -> Models';
BatchOpt.mibBatchActionName = 'Export model or material';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ExportTo = sprintf('Destination for export of the model or material of the model');
BatchOpt.mibBatchTooltip.MaterialIndex = sprintf('Index of material to export, keep empty to export the whole model');
BatchOpt.mibBatchTooltip.MaterialOutputIndex = sprintf('When a single material exported, this value will be assigned to it; [typical values 1 or 255]');
BatchOpt.mibBatchTooltip.MaterialOutputVariable = sprintf('[MATLAB export] Variable name in MATLAB main workspace');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 2 % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
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
    BatchOptIn = struct();
end

% --- checks
% do nothing is selection is disabled
if obj.I{BatchOpt.id}.enableSelection == 0
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Enable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "yes" and try again...'),'The models are disabled');
    notify(obj, 'stopProtocol');
    return;
end
% check for whether the model exists, if not create one
if ~obj.I{BatchOpt.id}.modelExist 
    warndlg(sprintf('The model is not yet started!\n\nCreate or load a model first!'), 'The models is missing');
    notify(obj, 'stopProtocol');
    return;
end

if ~BatchOpt.batchModeFlag
    prompts = {'Destination:'; 'Output variable [Exporting to MATLAB only]'; ...
        'Material index [keep empty to export the whole model]:'; 'Output material index [when a single material exported]'};
    defAns = {[BatchOpt.ExportTo{2}, 1]; BatchOpt.MaterialOutputVariable; BatchOpt.MaterialIndex; BatchOpt.MaterialOutputIndex};
    dlgOptions.PromptLines = [1 1 1 1];
    dlgOptions.WindowWidth = 1.2;
    answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Export model (material)', dlgOptions);
    if isempty(answer); return; end
    
    BatchOpt.ExportTo(1) = answer(1);
    BatchOpt.MaterialOutputVariable = answer{2};
    BatchOpt.MaterialIndex = answer{3};
    BatchOpt.MaterialOutputIndex = answer{4};
end

switch BatchOpt.ExportTo{1}
    case 'matlab'
        status = obj.I{BatchOpt.id}.modelExportToMatlab(BatchOpt.MaterialOutputVariable, str2double(BatchOpt.MaterialIndex), str2double(BatchOpt.MaterialOutputIndex), BatchOpt);
    case 'imaris'
        imarisOptions.type = 'model';
        imarisOptions.modelIndex = str2double(BatchOpt.MaterialIndex);
        imarisOptions.showWaitbar = BatchOpt.showWaitbar;
        obj.connImaris = mibSetImarisDataset(obj.I{BatchOpt.id}, obj.mibModel.connImaris, imarisOptions);
        status = true;
end

if ~status
    notify(obj, 'stopProtocol');
    return;
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);
end