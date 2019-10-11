function menuMaskInvert_Callback(obj, type, BatchOptIn)
% function menuMaskInvert_Callback(obj, type, BatchOptIn)
% callback to Menu->Mask->Invert; invert the Mask/Selection layer
%
% Parameters:
% type: a string with the layer to invert
% @li 'mask' - invert the Mask layer
% @li 'selection' - invert the Selection layer
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Target - cell string, {'mask', 'selection'} - layer to invert
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(type)
    BatchOpt.Target = {type};
else
    BatchOpt.Target = {'mask'};
end
BatchOpt.Target{2} = {'mask', 'selection'};
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

switch BatchOpt.Target{1}
    case 'mask'
        BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Invert mask';
    case 'selection'
        BatchOpt.mibBatchSectionName = 'Menu -> Selection';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Invert selection';
end
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Target = sprintf('Layer to be inverted');
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

%% do nothing is selection is disabled
if obj.mibModel.preferences.disableSelection == 1
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The selection layer is disabled','modal');
    notify(obj.mibModel, 'stopProtocol');
    return; 
end

% check for the virtual stacking mode and return
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'invert action is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

%%
if strcmp(BatchOpt.Target{1}, 'mask')
    if obj.mibModel.I{BatchOpt.id}.maskExist == 0; return; end
end

if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', sprintf('Inverting the %s', BatchOpt.Target{1}), 'WindowStyle', 'modal'); end
mibDoBackupOpt.id = BatchOpt.id;
obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 1, mibDoBackupOpt);
if BatchOpt.showWaitbar; waitbar(0.2, wb); end

options.roiId = [];     % enable use of ROIs
options.id = BatchOpt.id;
if obj.mibModel.I{BatchOpt.id}.modelType ~= 63
    mask = obj.mibModel.getData4D(BatchOpt.Target{1}, NaN, 0, options);
    if BatchOpt.showWaitbar; waitbar(0.3, wb); end
    for roi=1:numel(mask)
        mask{roi} = 1 - mask{roi};
    end
    if BatchOpt.showWaitbar; waitbar(0.8, wb); end
    obj.mibModel.setData4D(BatchOpt.Target{1}, mask, NaN, 0, options);
else
    mask = obj.mibModel.getData4D('everything', NaN, NaN, options);
    if BatchOpt.showWaitbar; waitbar(0.3, wb); end
    if strcmp(BatchOpt.Target{1}, 'mask')
        bitxorValue = 64;
    else
        bitxorValue = 128;
    end
        
    for roi=1:numel(mask)
        mask{roi} = bitxor(mask{roi}, bitxorValue);
    end
    if BatchOpt.showWaitbar; waitbar(0.8, wb); end
    obj.mibModel.setData4D('everything', mask, NaN, NaN, options);
end
if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end
obj.plotImage();

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

end