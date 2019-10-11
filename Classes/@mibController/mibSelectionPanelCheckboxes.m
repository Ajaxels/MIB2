function mibSelectionPanelCheckboxes(obj, BatchOptIn)
% function mibSelectionPanelCheckboxes(obj, BatchOptIn)
% a function of the batch mode that allow to tweak the status of checkboxes
% of the Selection panel
%
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Checkbox3D - cell, modify the status of mibActions3dCheck
% @li .ColorChannel - string, empty - do not modify; otherwise index of the color channel to set 0 - All, 1 - first, 2 - second, etc
%
% Return values:
% 

%| 
% @b Examples:
% @code 
% BatchOptIn.Checkbox3D = {'Checked'};
% obj.mibSelectionPanelCheckboxes(BatchOptIn);     // check the 3D checkbox, call from mibController
% @endcode
 
% Copyright (C) 03.10.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
BatchOpt.Checkbox3D = {'Unchanged'};
BatchOpt.Checkbox3D{2} = availableOptions;   
BatchOpt.ColorChannel = '';

BatchOpt.mibBatchSectionName = 'Panel -> Selection';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Modify parameters';
BatchOpt.mibBatchTooltip.Checkbox3D = 'Tweak the status of the "3D" checkbox';
BatchOpt.mibBatchTooltip.ColorChannel = 'When empty - do not modify; otherwise index of the color channel to set 0 - All, 1 - first, 2 - second, etc';

if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
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

BatchOpt2 = rmfield(BatchOpt, {'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'});
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
            case 'Checkbox3D'
                obj.mibView.handles.mibActions3dCheck.Value = state;
                if state == 1
                    obj.mibView.handles.mibMaskRecalcStatsBtn.Enable = 'on';
                else
                    obj.mibView.handles.mibMaskRecalcStatsBtn.Enable = 'off';
                end
               
        end
    elseif ischar(BatchOpt2.(fieldNames{fieldId}))
        if isempty(BatchOpt2.(fieldNames{fieldId})); continue; end
        
        switch fieldNames{fieldId}
            case 'ColorChannel'
                val = str2double(BatchOpt2.(fieldNames{fieldId}));
                val = min([val+1; numel(obj.mibView.handles.mibColChannelCombo.String)]);
                val = max([1 val]);
                obj.mibView.handles.mibColChannelCombo.Value = val;
                obj.mibColChannelCombo_Callback();
        end
    else
        %
    end
end

