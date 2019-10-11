function mibSegmentationPanelCheckboxes(obj, BatchOptIn)
% function mibSegmentationPanelCheckboxes(obj, BatchOptIn)
% a function of the batch mode that allow to tweak the status of checkboxes
% of the Segmentation panel
%
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .FixSelectionToMaterial - a cell, fix selection to material, modifies mibSegmSelectedOnlyCheck
% @li .MaskedArea - a cell, fix selection to the masked area, modifies mibMaskedAreaCheck
% @li .BrushWatershed - a cell, use brush with watershed clustering, modifies mibBrushSuperpixelsWatershedCheck
% @li .BrushSlic - a cell, use brush with slic clustering, modifies mibBrushSuperpixelsCheck
% @li .SelectedMaterial - string, index of the selected material, '-1' for mask, '0'-for exterior, '1','2'..-indices of materials
% @li .selectedAddToMaterial - string, index of the selected add to material, '-1' for mask, '0'-for exterior, '1','2'..-indices of materials
%
% Return values:
% 

%| 
% @b Examples:
% @code 
% BatchOptIn.FixSelectionToMaterial = {'Checked'};
% obj.segmentationPanelCheckboxes_Callback(BatchOptIn);     // check the Fix Selection To Material checkbox 
% @endcode
 
% Copyright (C) 13.09.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; BatchOptIn = struct(); end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
availableOptions = {'Unchanged', 'Checked', 'Unchecked'};
BatchOpt.FixSelectionToMaterial = {'Unchanged'};   % fix selection to material
BatchOpt.FixSelectionToMaterial{2} = availableOptions;  
BatchOpt.MaskedArea = {'Unchanged'};   % fix selection to the masked area
BatchOpt.MaskedArea{2} = availableOptions;  
BatchOpt.BrushWatershed = {'Unchanged'};   % use brush with watershed clustering
BatchOpt.BrushWatershed{2} = availableOptions; 
BatchOpt.BrushSlic = {'Unchanged'};   % use brush with slic clustering
BatchOpt.BrushSlic{2} = availableOptions;  
BatchOpt.SelectedMaterial = '';    % index of the selected material
BatchOpt.SelectedAddToMaterial = '';       % index of the target material
BatchOpt.UnlinkMaterialFromAddTo = logical(obj.mibView.handles.mibSegmentationTable.UserData.unlink);       % unlink material from Add To Checkbox
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Modify parameters';
BatchOpt.mibBatchTooltip.FixSelectionToMaterial = sprintf('Tweak the status of the "Fix selection to material" checkbox');
BatchOpt.mibBatchTooltip.MaskedArea = sprintf('Tweak the status of the "Masked area" checkbox');
BatchOpt.mibBatchTooltip.BrushWatershed = sprintf('Use brush with watershed clustering');
BatchOpt.mibBatchTooltip.BrushSlic = sprintf('Use brush with slic clustering');
BatchOpt.mibBatchTooltip.SelectedMaterial = sprintf('[Not compatible with 65535 models] index of the selected material; keep empty to do not change the state; -1 for mask, 0-for exterior, 1,2,3 materials of the model');
BatchOpt.mibBatchTooltip.SelectedAddToMaterial = sprintf('[Not compatible with 65535 models] index of the material to be added to; keep empty to do not change the state; -1 for mask, 0-for exterior, 1,2,3 materials of the model');
BatchOpt.mibBatchTooltip.UnlinkMaterialFromAddTo = 'Unlink selected material from the AddTo material';       

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
end

BatchOpt2 = rmfield(BatchOpt, {'id', 'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'});
fieldNames = fieldnames(BatchOpt2);
for fieldId = 1:numel(fieldNames)
    if iscell(BatchOpt2.(fieldNames{fieldId}))
        if strcmp(BatchOpt2.(fieldNames{fieldId}){1}, 'Unchanged'); continue; end

        if strcmp(BatchOpt2.(fieldNames{fieldId}){1}, 'Checked')
            state = 1;
        else
            state = 0;
        end

        switch fieldNames{fieldId}
            case 'FixSelectionToMaterial'
                obj.mibModel.I{BatchOpt.id}.fixSelectionToMaterial = state;
                obj.mibView.handles.mibSegmSelectedOnlyCheck.Value = state;
                if BatchOpt.id == obj.mibModel.Id; obj.mibSegmSelectedOnlyCheck_Callback(); end
            case 'MaskedArea'
                if obj.mibModel.I{BatchOpt.id}.maskExist == 1
                    obj.mibModel.I{BatchOpt.id}.fixSelectionToMask = state;
                    obj.mibView.handles.mibMaskedAreaCheck.Value = state;
                    if BatchOpt.id == obj.mibModel.Id; obj.mibMaskedAreaCheck_Callback(); end
                end
            case 'BrushWatershed'
                obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value = state;
                obj.mibBrushSuperpixelsWatershedCheck_Callback(obj.mibView.handles.mibBrushSuperpixelsWatershedCheck);
            case 'BrushSlic'
                obj.mibView.handles.mibBrushSuperpixelsCheck.Value = state;
                obj.mibBrushSuperpixelsWatershedCheck_Callback(obj.mibView.handles.mibBrushSuperpixelsCheck);
        end
    elseif ischar(BatchOpt2.(fieldNames{fieldId}))
        if isempty(BatchOpt2.(fieldNames{fieldId})); continue; end
        
        switch fieldNames{fieldId}
            case 'SelectedMaterial'
                materialId = str2double(BatchOpt2.(fieldNames{fieldId}));
                obj.mibModel.I{BatchOpt.id}.selectedMaterial = materialId+2;
            case 'SelectedAddToMaterial'
                materialId = str2double(BatchOpt2.(fieldNames{fieldId}));
                obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial = materialId+2;
        end
    else
        obj.mibView.handles.mibSegmentationTable.UserData.unlink = BatchOpt.UnlinkMaterialFromAddTo;    % invert the unlink toggle status
        if obj.mibView.handles.mibSegmentationTable.UserData.unlink == 0
            obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial = obj.mibModel.I{BatchOpt.id}.selectedMaterial;
        end
    end
end
obj.updateSegmentationTable();
