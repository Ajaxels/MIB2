function mibAddMaterialBtn_Callback(obj, BatchOptIn)
% function mibAddMaterialBtn_Callback(obj, BatchOptIn)
% callback to the obj.mibView.handles.mibAddMaterialBtn, add material to the model
%
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .MaterialName - a string, name of a new material
% @li .showWaitbar - logical, show or not the waitbar
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibAddMaterialBtn_Callback();     // add material to the model @endcode
 
% Copyright (C) 29.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 12.09.2019 updated for the batch mode

global mibPath;
if nargin < 2; BatchOptIn = struct(); end
unFocus(obj.mibView.handles.mibAddMaterialBtn); % remove focus from hObject

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.MaterialName = 'NewMaterial';   % name of the new material
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Add material';
BatchOpt.mibBatchTooltip.MaterialName = sprintf('[Models with 63 or 255 materials] Name of a new material to add without spaces! For other models the index is calculated automatically');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

% do nothing is selection is disabled
if obj.mibModel.I{BatchOpt.id}.disableSelection == 1
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The models are disabled');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

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
    if obj.mibModel.I{BatchOpt.id}.modelType < 256
        list = obj.mibModel.I{BatchOpt.id}.modelMaterialNames;
        if isempty(list); list = cell(0); end    % remove empty entry from the list
        number = numel(list);
    
        answer = mibInputDlg({mibPath}, sprintf('Please add a new name for this material:'), 'Rename material', num2str(number+1));
        if ~isempty(answer)
            BatchOpt.MaterialName = answer{1};
        else
            return;
        end
    end
end

if obj.mibModel.I{BatchOpt.id}.modelType < 256
    list = obj.mibModel.I{BatchOpt.id}.modelMaterialNames;
    if isempty(list); list = cell(0); end    % remove empty entry from the list
    number = numel(list);

    if obj.mibModel.I{BatchOpt.id}.modelType < number + 1
        warndlg(sprintf('!!! Warning !!!\n\nThe current type of the model can only have %d materials!\n\nPlease convert it to another suitable type and try again:\nMenu->Models->Type', obj.mibModel.getImageProperty('modelType')), ...
            'Wrong model type', 'modal');
        notify(obj.mibModel, 'stopProtocol');
        return;
    end

    if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Adding material\nPlease wait...'), 'Name', 'Add material', 'WindowStyle', 'modal'); end
    list(end+1,1) = cellstr(BatchOpt.MaterialName);

    if ~obj.mibModel.I{BatchOpt.id}.modelExist
        obj.mibModel.createModel([], list); % make an empty model
    else
        % update material list for the model
        obj.mibModel.I{BatchOpt.id}.modelMaterialNames = list;
    end
    obj.mibModel.I{BatchOpt.id}.generateModelColors();
    if BatchOpt.showWaitbar; waitbar(0.5, wb); end
    obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial = numel(list)+2;
    obj.mibModel.I{BatchOpt.id}.selectedMaterial = numel(list)+2;
    obj.updateSegmentationTable('end'); % scroll the segmentation table to bottom
    obj.plotImage(0);
    if BatchOpt.showWaitbar; waitbar(1, wb); end
else         % for 65535 model look for the next empty material
    if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Adding material\nPlease wait...'), 'Name', 'Add material', 'WindowStyle', 'modal'); end
    if ~obj.mibModel.I{BatchOpt.id}.modelExist
        CreateModelOptions.id = BatchOpt.id;
        obj.mibModel.createModel([], [], CreateModelOptions); % make an empty model
    end
    
    maxVal = 0;
    options.blockModeSwitch = 0;
    options.id = BatchOpt.id;
    if BatchOpt.showWaitbar; waitbar(0.05, wb, sprintf('Looking for the next empty material\nPlease wait...')); end
    t2 = obj.mibModel.I{BatchOpt.id}.time;
    for t=1:t2
        M = cell2mat(obj.mibModel.getData3D('model', t, 4, NaN, options));
        maxVal = max([maxVal max(max(max(M)))]);
        if BatchOpt.showWaitbar; waitbar(t/t2, wb); end
    end
    if BatchOpt.showWaitbar; waitbar(.99, wb); end
    if maxVal == obj.mibModel.I{BatchOpt.id}.modelType
        warndlg(sprintf('!!! Warning !!!\n\nThe model is full, i.e. the maximal material index found in the model is equal to the maximal allowed number (%d)', maxVal), 'Model is full!');
        if BatchOpt.showWaitbar; delete(wb); end
        notify(obj.mibModel, 'stopProtocol');
        return;
    end
    
    if obj.mibModel.I{BatchOpt.id}.selectedMaterial > 2
        obj.mibModel.I{BatchOpt.id}.modelMaterialNames{obj.mibModel.I{BatchOpt.id}.selectedMaterial-2} = num2str(maxVal+1);
        eventdata2.Indices = [obj.mibModel.I{BatchOpt.id}.selectedMaterial, 2];
    else
        obj.mibModel.I{BatchOpt.id}.modelMaterialNames{1} = num2str(maxVal+1);
        eventdata2.Indices = [3, 2];
    end
    if size(obj.mibModel.I{BatchOpt.id}.modelMaterialColors, 1) < maxVal+1  % generate a random color
        obj.mibModel.I{BatchOpt.id}.modelMaterialColors(maxVal+1, :) = rand(1,3);
    end
    
    obj.mibSegmentationTable_CellSelectionCallback(eventdata2);     % update mibSegmentationTable
    if BatchOpt.showWaitbar; waitbar(1, wb); end
    
end
if BatchOpt.showWaitbar; delete(wb); end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

end