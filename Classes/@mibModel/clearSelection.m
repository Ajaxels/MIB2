function clearSelection(obj, sel_switch, BatchOptIn)
% function clearSelection(obj, sel_switch, BatchOptIn)
% clear the Selection layer
%
% Parameters:
% sel_switch: a string to define where selection should be cleared:
% @li when @b '2D, Slice' fill holes for the currently shown slice
% @li when @b '3D, Stack' fill holes for the currently shown z-stack
% @li when @b '4D, Dataset' fill holes for the whole dataset
% BatchOptIn: [@em optional], a structure with extra parameters or settings for the batch processing mode, when NaN return
%    a structure with default options via "syncBatch" event
% optional parameters
% @li .DatasetType -> cell with one of possible parameters: '2D, Slice', '3D, Stack', '4D, Dataset'
% @li .showWaitbar - logical, show or not the waitbar

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 25.09.2019 updated for batch mode

% do nothing is selection is disabled
if obj.I{obj.Id}.disableSelection == 1; return; end

if nargin < 3; BatchOptIn = struct(); end
if nargin < 2; sel_switch = []; end

BatchOpt = struct();
if ~isempty(sel_switch)
    BatchOpt.DatasetType = {sel_switch};
else
    BatchOpt.DatasetType = {'3D, Stack'};    
end
BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.Id;   % default BatchOpt.id
BatchOpt.mibBatchTooltip.DatasetType = 'Select to remove selection from the current slice, stack, or dataset';
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

BatchOpt.mibBatchSectionName = 'Panel -> Selection';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Clear selection';

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
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

getDataOptions.blockModeSwitch = obj.I{BatchOpt.id}.blockModeSwitch;
[h, w, ~, d, ~] = obj.I{BatchOpt.id}.getDatasetDimensions('image', NaN, 0, getDataOptions);

setDataOptions.id = BatchOpt.id;
if strcmp(BatchOpt.DatasetType{1} ,'2D, Slice')
    obj.mibDoBackup('selection', 0, setDataOptions);
    img = zeros([h, w], 'uint8');
    obj.setData2D('selection', {img}, NaN, NaN, NaN, setDataOptions);
else 
    if strcmp(BatchOpt.DatasetType{1} ,'3D, Stack') 
        obj.mibDoBackup('selection', 1, setDataOptions);
        t1 = obj.I{BatchOpt.id}.slices{5}(1);
        t2 = obj.I{BatchOpt.id}.slices{5}(2);
        if BatchOpt.showWaitbar; wb = waitbar(0,'Clearing the Selection layer for a whole Z-stack...','WindowStyle','modal'); end
    else
        t1 = 1;
        t2 = obj.I{BatchOpt.id}.time;
        if BatchOpt.showWaitbar; wb = waitbar(0,'Clearing the Selection layer for a whole dataset...','WindowStyle','modal'); end
    end
    
    img = zeros([h, w, d], 'uint8');
    for t=t1:t2
        obj.setData3D('selection', {img}, t, obj.I{BatchOpt.id}.orientation, NaN, setDataOptions);
    end
    if BatchOpt.showWaitbar; delete(wb); end
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');
end