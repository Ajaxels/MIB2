function mibViewSettingsPanelCheckboxes(obj, BatchOptIn)
% function mibViewSettingsPanelCheckboxes(obj, BatchOptIn)
% a function of the batch mode that allow to tweak status of checkboxes
% of the View Settings panel
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
% BatchOptIn.LUT = {'Checked'};
% obj.mibViewSettingsPanelCheckboxes(BatchOptIn);     // check the Fix Selection To Material checkbox 
% @endcode
 
% Copyright (C) 04.10.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
BatchOpt.LUT = {'Unchanged'};  
BatchOpt.LUT{2} = availableOptions;  
BatchOpt.DisplayedColorChannels = '';
BatchOpt.OnFly = {'Unchanged'};  
BatchOpt.OnFly{2} = availableOptions;  
BatchOpt.ShowModel = {'Unchanged'};  
BatchOpt.ShowModel{2} = availableOptions;  
BatchOpt.ShowMask = {'Unchanged'}; 
BatchOpt.ShowMask{2} = availableOptions; 
BatchOpt.ShowAnnotations = {'Unchanged'};  
BatchOpt.ShowAnnotations{2} = availableOptions;
BatchOpt.HideImage = {'Unchanged'};  
BatchOpt.HideImage{2} = availableOptions;  
BatchOpt.TransparencyModel = '';   
BatchOpt.TransparencyMask = '';   
BatchOpt.TransparencySelection = '';   
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Panel -> View settings';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Modify parameters';
BatchOpt.mibBatchTooltip.LUT = 'Tweak the status of the "LUT" checkbox';
BatchOpt.mibBatchTooltip.DisplayedColorChannels = 'Provide indices of the color channels to be displayed, keep empty if  no change required';
BatchOpt.mibBatchTooltip.OnFly = 'Tweak the status of the "on fly" checkbox for automatic stretching of image intensities';
BatchOpt.mibBatchTooltip.ShowModel = 'Tweak the status of the "Show model" checkbox';
BatchOpt.mibBatchTooltip.ShowMask = 'Tweak the status of the "Show mask" checkbox';
BatchOpt.mibBatchTooltip.ShowAnnotations = 'Tweak the status of the "Ann/measure" checkbox';
BatchOpt.mibBatchTooltip.HideImage = 'Tweak the status of the "Hide image" checkbox';
BatchOpt.mibBatchTooltip.TransparencyModel = 'Modify transparency of the model layer, enter a number from 0 to 1, keep empty if no change required';
BatchOpt.mibBatchTooltip.TransparencyMask = 'Modify transparency of the mask layer, enter a number from 0 to 1, keep empty if no change required';
BatchOpt.mibBatchTooltip.TransparencySelection = 'Modify transparency of the selection layer, enter a number from 0 to 1, keep empty if no change required';

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
            case 'LUT'
                obj.mibView.handles.mibLutCheckbox.Value = state;
                obj.mibLutCheckbox_Callback();
            case 'OnFly'
                obj.mibView.handles.mibLiveStretchCheck.Value = state;
                obj.mibModel.mibLiveStretchCheck = state;
            case 'ShowModel'
                obj.mibView.handles.mibModelShowCheck.Value = state;
                obj.mibModelShowCheck_Callback();
            case 'ShowMask'
                obj.mibView.handles.mibMaskShowCheck.Value = state;
                obj.mibMaskShowCheck_Callback();
            case 'ShowAnnotations'
                obj.mibView.handles.mibShowAnnotationsCheck.Value = state;
                obj.mibModel.mibShowAnnotationsCheck = state;
            case 'HideImage'
                obj.mibView.handles.mibHideImageCheck.Value = state;
                obj.mibModel.mibHideImageCheck = state;
        end
    elseif ischar(BatchOpt2.(fieldNames{fieldId}))
        if isempty(BatchOpt2.(fieldNames{fieldId})); continue; end
        
        switch fieldNames{fieldId}
            case 'DisplayedColorChannels'
                values = str2num(BatchOpt2.(fieldNames{fieldId})); %#ok<ST2NM>
                for i=1:size(obj.mibView.handles.mibChannelMixerTable.Data,1)
                    if ismember(i, values)
                        obj.mibView.handles.mibChannelMixerTable.Data{i,2} = true;
                    else
                        obj.mibView.handles.mibChannelMixerTable.Data{i,2} = false;
                    end
                end
                obj.mibChannelMixerTable_CellEditCallback();
                return;
            case 'TransparencyModel'
                obj.mibModel.preferences.mibModelTransparencySlider = str2double(BatchOpt2.(fieldNames{fieldId}));
                obj.mibView.handles.mibModelTransparencySlider.Value = str2double(BatchOpt2.(fieldNames{fieldId}));
            case 'TransparencyMask'
                obj.mibModel.preferences.mibMaskTransparencySlider = str2double(BatchOpt2.(fieldNames{fieldId}));
                obj.mibView.handles.mibMaskTransparencySlider.Value = str2double(BatchOpt2.(fieldNames{fieldId}));
            case 'TransparencySelection'
                obj.mibModel.preferences.mibSelectionTransparencySlider = str2double(BatchOpt2.(fieldNames{fieldId}));
                obj.mibView.handles.mibSelectionTransparencySlider.Value = str2double(BatchOpt2.(fieldNames{fieldId}));
        end
    else
%         obj.mibView.handles.mibSegmentationTable.UserData.unlink = BatchOpt.UnlinkMaterialFromAddTo;    % invert the unlink toggle status
%         if obj.mibView.handles.mibSegmentationTable.UserData.unlink == 0
%             obj.mibModel.I{BatchOpt.id}.selectedAddToMaterial = obj.mibModel.I{BatchOpt.id}.selectedMaterial;
%         end
    end
end
obj.plotImage();
obj.updateSegmentationTable();
