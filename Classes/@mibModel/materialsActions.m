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

function status = materialsActions(obj, action, BatchOptIn)
% function materialsActions(obj, action, BatchOptIn)
% collection of actions related to materials of the model
%
% Parameters:
% action: string with desired action to do, one of those listed below.
% Provide only this parameter for the interactive behavior
% BatchOptIn: [optional] a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details; 
%   default values in BatchOpt below are overriden by settings from BatchOptIn
% @li .Action - cell string with these options
%   'Rename material'
%   'Add material'
%   'Insert material'
%   'Swap materials'
%   'Reorder materials'
%   'Export material'
%   'Save material to file' 
%   'Remove material'
% @li .MaterialIndex1 - string, primary index(indices) of materials to perform required action
% @li .MaterialIndex2 - string, secondary index of materials for swapping of materials
% @li .MaterialName - string, new name for the material
% @li .showWaitbar - logical, show or not the waitbar
%
% Return values:
% status: logical status of the function

%| 
% @b Examples:
% @code
% BatchOptIn.Action = {'Rename material'};
% BatchOptIn.MaterialIndex1 = '3';
% BatchOptIn.MaterialName = 'material3';
% obj.mibModel.materialsActions(BatchOptIn); // call from mibController class; rename material 3 as "material3"
% @endcode
% @code 
% BatchOptIn.Action = {'Remove material'};    
% BatchOptIn.MaterialIndex1 = '2:4 10';     
% obj.mibModel.materialsActions(BatchOptIn); // call from mibController class; remove materials 2,3,4,10
% @endcode

% Updates

global mibPath;
status = false; % status of the function

% populate BatchOpt with default values
BatchOpt = struct();
if ~isempty(action)
    BatchOpt.Action = {action};
else
    BatchOpt.Action = {'Rename material'};
end
BatchOpt.Action{2} = {'Rename material', 'Add material', 'Insert material', 'Swap materials', 'Reorder materials', 'Remove material'};  % cell array with the list of available actions
BatchOpt.MaterialName = '';
if obj.I{obj.Id}.selectedMaterial > 2
    if obj.I{obj.Id}.modelType > 256
        BatchOpt.MaterialIndex1 = obj.I{obj.Id}.modelMaterialNames{obj.I{obj.Id}.selectedMaterial - 2}; % index of the selected material
    else
        BatchOpt.MaterialIndex1 = num2str(obj.I{obj.Id}.selectedMaterial - 2); % index of the selected material
    end
else
    BatchOpt.MaterialIndex1 = '1';  % index of the selected material
end

if obj.I{obj.Id}.selectedAddToMaterial > 2
    BatchOpt.MaterialIndex2 = num2str(obj.I{obj.Id}.selectedAddToMaterial - 2); % index of the selected addTo material
else
    BatchOpt.MaterialIndex2 = '2';  % index of the selected material
end
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Models';
BatchOpt.mibBatchActionName = 'Material actions';
BatchOpt.batchModeFlag =  false; % indicate that the function was not started from batch processing

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Action = sprintf('Specify action for materials');
BatchOpt.mibBatchTooltip.MaterialName = sprintf('New name for the material\nUse empty for automatic naming\nWhen renaming all materials provide the comma-separated list. Do not use spaces!');
BatchOpt.mibBatchTooltip.MaterialIndex1 = sprintf('[all actions] Index(indices) of materials or new order of materials\nWhen "NaN" use the currently selected material; use 0 to rename all materials');
BatchOpt.mibBatchTooltip.MaterialIndex2 = sprintf('[swap only] Secondary index(indices) of materials to perform required action');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%batchModeSwitch = false; % not batch mode, replaced with BatchOpt.batchModeFlag
if nargin == 3 % batch mode 
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
        if strcmp(BatchOpt.Action{1}, 'Add material')
            BatchOpt.MaterialIndex1 = []; % replace BatchOpt.MaterialIndex1 with empty value to generate automatic index
        end
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
    warndlg(sprintf('Create or load the model first!'), 'No model');
    return;
end

switch BatchOpt.Action{1}
    case 'Rename material'
        if ~isfield(BatchOptIn, 'MaterialName')
            if obj.I{BatchOpt.id}.modelType > 255
                prompts = {sprintf('New material name\n(only numbers!):')};
                defAns = {BatchOpt.MaterialIndex1};
                dlgOptions.PromptLines = 2;
            else
                materialIndex = str2double(BatchOpt.MaterialIndex1);
                prompts = {sprintf('New material name\n(no spaces/no letters as the 1st character)\nCurrent index: %d, name: %s', materialIndex, obj.I{BatchOpt.id}.modelMaterialNames{materialIndex})};
                defAns = {obj.I{BatchOpt.id}.modelMaterialNames{materialIndex}};
                dlgOptions.PromptLines = 3;
            end
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Insert material', dlgOptions);
            if isempty(answer); return; end
            BatchOpt.MaterialName = answer{1};
        end
        status = obj.I{BatchOpt.id}.materialsRename(BatchOpt.MaterialName, str2double(BatchOpt.MaterialIndex1));
    case 'Add material'
        if obj.I{BatchOpt.id}.modelType > 255
            % if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Looking for the next empty material\nPlease wait...')); end
            % maxVal = 0;
            % getDataOpt.blockModeSwitch = 0;
            % 
            % for t=1:obj.I{BatchOpt.id}.time
            %     M = cell2mat(obj.getData3D('model', t, 4, NaN, getDataOpt));
            %     maxVal = max([maxVal max(max(max(M)))]);
            %     if BatchOpt.showWaitbar; waitbar(t/obj.I{BatchOpt.id}.time, wb); end
            % end
            % if BatchOpt.showWaitbar; delete(wb); end
            % newValue = maxVal + 1;
            % if newValue > obj.I{BatchOpt.id}.modelType
            %     warndlg(sprintf('!!! Warning !!!\n\nThe model is full, i.e. the maximal material index found in the model is equal to the maximal allowed number (%d)', maxVal), 'Model is full!');
            %     if BatchOpt.showWaitbar; delete(wb); end
            %     notify(obj.mibModel, 'stopProtocol');
            %     return;
            % end
            % 
            % if obj.I{BatchOpt.id}.fixSelectionToMaterial
            %     obj.I{BatchOpt.id}.modelMaterialNames{obj.I{BatchOpt.id}.selectedAddToMaterial-2} = num2str(newValue);
            % else
            %     if obj.I{BatchOpt.id}.selectedMaterial > 2
            %         obj.I{BatchOpt.id}.modelMaterialNames{obj.I{BatchOpt.id}.selectedMaterial-2} = num2str(newValue);
            %         eventdata2.Indices = [obj.I{BatchOpt.id}.selectedMaterial, 2];
            %     else
            %         obj.I{BatchOpt.id}.modelMaterialNames{2} = num2str(newValue);
            %         eventdata2.Indices = [4, 2];
            %     end
            %     obj.mibSegmentationTable_CellSelectionCallback(eventdata2);     % update mibSegmentationTable
            % end

            % trigger press of the find next empty material button
            motifyEvent.Name = 'mibAddMaterialBtn_Callback';
            eventdata = ToggleEventData(motifyEvent);
            notify(obj, 'modelNotify', eventdata);
            return;
        else
            if ~isfield(BatchOptIn, 'MaterialName')
                prompts = {sprintf('Material name\n(no spaces/no letters as the 1st character):')};
                defAns = {sprintf('mat%.3d', numel(obj.I{BatchOpt.id}.modelMaterialNames)+1)};
                dlgOptions.PromptLines = 2;
                answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Insert material', dlgOptions);
                if isempty(answer); return; end
                BatchOpt.MaterialName = answer{1};
                BatchOpt.MaterialIndex1 = num2str(numel(obj.I{BatchOpt.id}.modelMaterialNames)+1);
            end
            status = obj.I{BatchOpt.id}.materialsInsert(str2double(BatchOpt.MaterialIndex1), BatchOpt.MaterialName, BatchOpt);
        end
    case 'Insert material'
        if ~isfield(BatchOptIn, 'MaterialName') || ~isfield(BatchOptIn, 'MaterialIndex1')
            prompts = {sprintf('Material name\n(no spaces/no letters as the 1st character):'); ...
                       sprintf('Index where material needs to be inserted\n[number between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames)+1) };
            defAns = {sprintf('mat%.3d', numel(obj.I{BatchOpt.id}.modelMaterialNames)+1); ...
                      BatchOpt.MaterialIndex1};
            dlgOptions.PromptLines = [2, 2];
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Insert material', dlgOptions);
            if isempty(answer); return; end 
            BatchOpt.MaterialName = answer{1};
            BatchOpt.MaterialIndex1 = answer{2};
        end
        status = obj.I{BatchOpt.id}.materialsInsert(str2double(BatchOpt.MaterialIndex1), BatchOpt.MaterialName, BatchOpt);
    case 'Swap materials'
        if ~isfield(BatchOptIn, 'MaterialIndex1') || ~isfield(BatchOptIn, 'MaterialIndex2')
            prompts = {sprintf('Index of the first material to swap\n[number between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames)); ...
                       sprintf('Index of the second material to swap\n[number between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames)) };
            defAns = {BatchOpt.MaterialIndex1; ...
                      BatchOpt.MaterialIndex2};
            dlgOptions.PromptLines = [2, 2];
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Swap materials', dlgOptions);
            if isempty(answer); return; end 
            BatchOpt.MaterialIndex1 = answer{1};
            BatchOpt.MaterialIndex2 = answer{2};
        end
        status = obj.I{BatchOpt.id}.materialsSwap(str2double(BatchOpt.MaterialIndex1), str2double(BatchOpt.MaterialIndex2), BatchOpt);
    case 'Reorder materials'
        if ~isfield(BatchOptIn, 'MaterialIndex1')
            prompts = {sprintf('Provide a new order for materials\nyou can use MATLAB notation: "1:5 9:-1:6 12 11 10"\n          => "1,2,3,4,5,9,8,7,6,12,11,10"\n[numbers between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames))};
            defAns = {num2str(1:numel(obj.I{BatchOpt.id}.modelMaterialNames))};
            dlgOptions.PromptLines = 4;
            dlgOptions.WindowWidth = 2;
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Reorder materials', dlgOptions);
            if isempty(answer); return; end 
            BatchOpt.MaterialIndex1 = answer{1};
        end
        status = obj.I{BatchOpt.id}.materialsReorder(BatchOpt.MaterialIndex1, BatchOpt);
    case 'Export material'
        BatchOptExport = struct();
        BatchOptExport.MaterialIndex = BatchOpt.MaterialIndex1;
        obj.modelExport(BatchOptExport);
        return;
    case 'Save material to file'
        prompts = {sprintf('Index of material to export\n[numbers between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames))};
        defAns = {BatchOpt.MaterialIndex1};
        dlgOptions.PromptLines = 2;
        dlgOptions.WindowWidth = 1;
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Save material', dlgOptions);
        if isempty(answer); return; end
        SaveMaterial.MaterialIndex = answer{1};
        obj.saveModel([], SaveMaterial);
        return;
    case 'Remove material'
        if ~isfield(BatchOptIn, 'MaterialIndex1')
            if obj.I{obj.Id}.modelType > 256
                prompts = {sprintf('Provide index(es) of the material(s) to be remove\nyou can use MATLAB notation: "3:5 7 8"\n    => to remove "3,4,5,7,8":')};
            else
                prompts = {sprintf('Provide index(es) of the material(s) to be remove\nyou can use MATLAB notation: "3:5 7 8"\n    => to remove "3,4,5,7,8"\n[numbers between 1-%d]:', numel(obj.I{BatchOpt.id}.modelMaterialNames))};
            end
            defAns = {BatchOpt.MaterialIndex1};
            dlgOptions.PromptLines = 4;
            dlgOptions.Icon = 'warning';
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Remove materials', dlgOptions);
            if isempty(answer); return; end 
            BatchOpt.MaterialIndex1 = answer{1};
        else
            if ~BatchOpt.batchModeFlag
                materialIndex = str2num(BatchOpt.MaterialIndex1); %#ok<ST2NM>
                options.Icon = 'warning';
                answer = mibQuestDlg({mibPath}, sprintf('You are going to delete material(s):\n"%s",\nwith indices: %d\n\nAre you sure?', ...
                    obj.I{BatchOpt.id}.modelMaterialNames{materialIndex}, materialIndex), ...
                    {'Cancel', 'Yes'}, 'Delete materials?', options);
                if strcmp(answer, 'Cancel'); return; end
            end
        end
        status = obj.I{BatchOpt.id}.materialsRemove(str2num(BatchOpt.MaterialIndex1), BatchOpt); %#ok<ST2NM>
        if status && obj.I{obj.Id}.modelType > 256
            if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Squeezing labels\nPlease wait...')); end
            maxIndex = 0;
            for t=1:obj.I{BatchOpt.id}.time
                SqueezeOpt.blockModeSwitch = 0;
                SqueezeOpt.id = BatchOpt.id;
                img = cell2mat(obj.getData3D('model', t, 4, NaN, SqueezeOpt));
                [a, ~, c] = unique(img);    % process further c
                if a(1) == 0; c = c - 1; end    % remove zeros
                img = reshape(c, size(img));
                maxIndex = max([maxIndex, max(img(:))]);
                obj.setData3D('model', img, t, 4, NaN, SqueezeOpt);
                if BatchOpt.showWaitbar; waitbar(t/obj.I{BatchOpt.id}.time, wb); end
            end
            % update material names
            obj.I{BatchOpt.id}.modelMaterialNames = {'1', '2'};

            if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end
        end
end
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

end