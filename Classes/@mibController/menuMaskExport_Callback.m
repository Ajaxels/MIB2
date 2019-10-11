function menuMaskExport_Callback(obj, ExportTo, BatchOptIn)
% function menuMaskExport_Callback(obj, ExportTo, BatchOptIn)
% callback to Menu->Mask->Export, export the Mask layer to Matlab or
% another buffer
%
% ExportTos:
% ExportTo: a string that specify the destination, where the mask layer
% should be exported
% @li 'Matlab' - to the main Matlab workspace
% @li 'MIB container' - another buffer within MIB
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .ExportTo - cell string, {'Matlab', 'MIB container'} destination for mask export
% @li .MaskVariable - string, [Matlab export only] name of a variable to be created in the Matlab workspace;
% @li .ContainerId - cell array, {'Container %d'} - index of the container for 'MIB container' mode
% @li .showWaitbar - logical, show or not the waitbar

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 11.09.2019 updated for the batch mode

global mibPath;
if nargin < 2; ExportTo = 'Matlab'; end

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'Export of masks is';
    warndlg(sprintf('!!! Warning !!!\n\n%s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(ExportTo)
    BatchOpt.ExportTo = {ExportTo};
else
    BatchOpt.ExportTo = {'Matlab'};
end
BatchOpt.ExportTo{2} = {'Matlab', 'MIB container'};
BatchOpt.MaskVariable = 'M';   % variable name for export to matlab workspace, for ExportTo = 'Matlab'
BatchOpt.ContainerId = {'Container 1'};     % index of the container to import mask from
BatchOpt.ContainerId{2} = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
BatchOpt.ContainerId(1) = BatchOpt.ContainerId{2}(obj.mibModel.Id);     % index of the container to import mask from
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Export mask';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ExportTo = sprintf('Source of the mask to be imported');
BatchOpt.mibBatchTooltip.MaskVariable = sprintf('[Matlab import only]\nSpecify name of a variable to be created in the Matlab workspace');
BatchOpt.mibBatchTooltip.ContainerId = sprintf('[MIB container only]\nSpecify index of MIB container');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin < 3
    switch BatchOpt.ExportTo{1}
        case 'Matlab'
            prompt = {'Variable for the mask image:'};
            title = 'Input variables for export';
            answer = mibInputDlg({mibPath}, prompt, title, 'M');
            if size(answer) == 0; return; end
            BatchOpt.MaskVariable = answer{1};
        case 'MIB container'
            % find MIB containers that have the mask layer
            destinationBuffer = 1:obj.mibModel.maxId;
            destinationButton = 1;
            bufferListIds = obj.mibModel.Id:-1:1;   % get the previous container if possible
            bufferListIds = [bufferListIds, obj.mibModel.Id:obj.mibModel.maxId];
            bufferListIds(bufferListIds==obj.mibModel.Id) = [];
            for i = bufferListIds
                if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif') == 0
                    destinationButton = i;
                    break;
                end
            end
            
            destinationBuffer = arrayfun(@(x) {['Container ' num2str(x)]}, destinationBuffer);   % convert to string cell array
            prompts = {'Enter destination to export the Mask layer:'};
            defAns = {[destinationBuffer, destinationButton]};
            title = 'Export Mask to another dataset';
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
            if isempty(answer); return; end
            BatchOpt.ContainerId(1) = answer(1);
    end
end

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

%%
switch BatchOpt.ExportTo{1}
    case 'Matlab'
        if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Exporting the mask', 'WindowStyle', 'modal'); end
        options.blockModeSwitch = 0;
        options.id = BatchOpt.id;
        if BatchOpt.showWaitbar; waitbar(0.05, wb); end
        assignin('base', BatchOpt.MaskVariable, cell2mat(obj.mibModel.getData4D('mask', 4, NaN, options)));
        if BatchOpt.showWaitbar; waitbar(1, wb); end
        disp(['Mask export: created variable ' BatchOpt.MaskVariable ' in the Matlab workspace']);
        if BatchOpt.showWaitbar; delete(wb); end
    case 'MIB container'
        destinationButton = str2double(BatchOpt.ContainerId{1}(10:end));
        % check dimensions
        [height, width, ~, depth, time] = obj.mibModel.I{BatchOpt.id}.getDatasetDimensions('image');
        [height2, width2, ~, depth2, time2] = obj.mibModel.I{destinationButton}.getDatasetDimensions('image');
        if height ~= height2 || width~=width2 || depth~=depth2 || time~=time2
            errordlg(sprintf('!!! Error !!!\n\nDimensions mismatch [height x width x depth x time]\nCurrent dimensions: %d x %d x %d x %d\nImported dimensions: %d x %d x %d x %d', height, width, depth, time, height2, width2, depth2, time2), 'Wrong dimensions', 'modal');
            notify(obj.mibModel, 'stopProtocol');
            return;
        end
        
        if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Copying the mask', 'WindowStyle', 'modal'); end
        options.blockModeSwitch = 0;
        options.id = BatchOpt.id;
        mask = obj.mibModel.getData4D('mask', 4, NaN, options);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end
        options.id = destinationButton;
        obj.mibModel.setData4D('mask', mask, 4, NaN, options);
        if BatchOpt.showWaitbar; waitbar(1, wb); end
        fprintf('MIB: the mask layer was exported from %d to %d\n', BatchOpt.id, destinationButton);
        if BatchOpt.showWaitbar; delete(wb); end
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);



