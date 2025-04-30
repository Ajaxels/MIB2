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
% Date: 24.03.2025

function status = materialsSwapColors(obj, BatchOptIn)
% function materialsSwapColors(obj, BatchOptIn)
% % swap two colors of two materials in the model
%
% Parameters:
% BatchOptIn: [optional] a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details; 
%   default values in BatchOpt below are overriden by settings from BatchOptIn
% @li .MaterialIndex1 - string, index of the first material 
% @li .MaterialIndex2 - string, index of the second material 
%
% Return values:
% status: logical status of the function

%| 
% @b Examples:
% @code
% BatchOptIn.MaterialIndex1 = '3';
% BatchOptIn.MaterialIndex2 = '5';
% obj.mibModel.materialsColorSwap(BatchOptIn); // call from mibController class; swap colors between material with index 3 and material with index  5
% @endcode
% @code 
% obj.mibModel.materialsActions(); // call from mibController class; interactive mode, a dialog will be shown
% @endcode

% Updates

global mibPath;
status = false; % status of the function

% populate BatchOpt with default values
BatchOpt = struct();
% index of the selected material 1
if obj.I{obj.Id}.selectedMaterial > 2
    if obj.I{obj.Id}.modelType > 256
        BatchOpt.MaterialIndex1 = obj.I{obj.Id}.modelMaterialNames{obj.I{obj.Id}.selectedMaterial - 2}; % index of the selected material
    else
        BatchOpt.MaterialIndex1 = num2str(obj.I{obj.Id}.selectedMaterial - 2); % index of the selected material
    end
else
    BatchOpt.MaterialIndex1 = '1';  % index of the selected material
end
% index of the selected material 2
if obj.I{obj.Id}.selectedAddToMaterial > 2
    BatchOpt.MaterialIndex2 = num2str(obj.I{obj.Id}.selectedAddToMaterial - 2); % index of the selected addTo material
else
    BatchOpt.MaterialIndex2 = '2';  % index of the selected material
end
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Models';
BatchOpt.mibBatchActionName = 'Materials color swap';
BatchOpt.batchModeFlag =  false; % indicate that the function was not started from batch processing

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.MaterialIndex1 = sprintf('index of the first material');
BatchOpt.mibBatchTooltip.MaterialIndex2 = sprintf('index of the second material ');

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
    %batchModeSwitch = true; % replaced with BatchOpt.batchModeFlag
else
    BatchOptIn = struct();
end

% do nothing is selection is disabled
if obj.I{BatchOpt.id}.enableSelection == 0 
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Enable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "yes" and try again...'),'The models are disabled');
    notify(obj, 'stopProtocol');
    return;
end

% check for whether the model exists, if not create one
if ~obj.I{BatchOpt.id}.modelExist 
    errordlg(sprintf('The model is missing!\nStart new model by pressing the Create button in the Segmentation panel'), 'The model is missing');
    notify(obj, 'stopProtocol');
    return;
end

% check for whether the model exists, if not create one
if ~obj.I{BatchOpt.id}.modelExist 
    errordlg(sprintf('The model is missing!\nStart new model by pressing the Create button in the Segmentation panel'), 'The model is missing');
    notify(obj, 'stopProtocol');
    return;
end

if obj.I{obj.Id}.modelType > 256
    errordlg(sprintf('Swapping of material colors in the model is only available for models with up to 255 materials!'), 'Wrong model type');
    notify(obj, 'stopProtocol');
    return;
end

if ~isfield(BatchOptIn, 'MaterialIndex1') || ~isfield(BatchOptIn, 'MaterialIndex2') || ~BatchOpt.batchModeFlag
    prompts = {sprintf('Index of the first material to swap colors\n[number between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames)); ...
        sprintf('Index of the second material to swap colors\n[number between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames)) };
    defAns = {BatchOpt.MaterialIndex1; BatchOpt.MaterialIndex2};
    dlgOptions.PromptLines = [2, 2];
    answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Swap materials', dlgOptions);
    if isempty(answer); return; end
    BatchOpt.MaterialIndex1 = answer{1};
    BatchOpt.MaterialIndex2 = answer{2};
end
status = obj.I{BatchOpt.id}.materialsSwapColors(str2double(BatchOpt.MaterialIndex1), str2double(BatchOpt.MaterialIndex2));

if ~status
    notify(obj, 'stopProtocol');
    return;
end

% update segmentation table
notifyEvent.Name = 'updateSegmentationTable';
eventdata = ToggleEventData(notifyEvent);
notify(obj, 'modelNotify', eventdata);

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');  % notify plotImage