function menuMaskImport_Callback(obj, ImportFrom, BatchOptIn)
% function menuMaskImport_Callback(obj, ImportFrom, BatchOptIn)
% callback to Menu->Mask->Import, import the Mask layer from Matlab or
% another buffer of MIB
%
% ImportFroms:
% ImportFrom: a string that specify the origin, from where the mask layer
% should be imported
% @li 'Matlab' - from the main Matlab workspace
% @li 'MIB container' - from another buffer within MIB
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .ImportFrom - cell string, {'Matlab', 'MIB container'} - source of the mask layer to be imported
% @li .MaskVariable - string, [Matlab import only] name of a variable with mask in the Matlab workspace;
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
%

global mibPath;
if nargin < 2; ImportFrom = 'Matlab'; end

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'Import of masks is';
    warndlg(sprintf('!!! Warning !!!\n\n%s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1
    warndlg(sprintf('The mask layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The masks are disabled', 'modal');
    notify(obj.mibModel, 'stopProtocol');
    return; 
end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(ImportFrom)
    BatchOpt.ImportFrom = {ImportFrom};
else
    BatchOpt.ImportFrom = {'Matlab'};
end
BatchOpt.ImportFrom{2} = {'Matlab', 'MIB container'};
BatchOpt.MaskVariable = 'M';   % variable name to be imported from matlab workspace, for ImportFrom = 'Matlab'
BatchOpt.ContainerId = {'Container 1'};     % index of the container to import mask from
BatchOpt.ContainerId{2} = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
BatchOpt.ContainerId(1) = BatchOpt.ContainerId{2}(obj.mibModel.Id);     % index of the container to import mask from
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Import mask';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ImportFrom = sprintf('Source of the mask to be imported');
BatchOpt.mibBatchTooltip.MaskVariable = sprintf('[Matlab import only]\nSpecify name of a variable with mask in the Matlab workspace');
BatchOpt.mibBatchTooltip.ContainerId = sprintf('[MIB container only]\nSpecify index of MIB container');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin < 3
    switch BatchOpt.ImportFrom{1}
        case 'Matlab'
            availableVars = evalin('base', 'whos');
            idx = ismember({availableVars.class}, {'uint8', 'uint16', 'uint32', 'uint64','int8', 'int16', 'int32', 'int64', 'double', 'single'});
            if sum(idx) == 0
                errordlg(sprintf('!!! Error !!!\nNothing to import...'), 'Nothing to import');
                return;
            end
            ImageVars = {availableVars(idx).name}';
            ImageSize = {availableVars(idx).size}';
            ImageClass = {availableVars(idx).class}';
            ImageVarsDetails = ImageVars;
            % add deteiled description to the text
            for i=1:numel(ImageVarsDetails)
                ImageVarsDetails{i} = sprintf('%s: %s [%s]', ImageVars{i}, ImageClass{i}, num2str(ImageSize{i}));
            end
            
            % find index of the I variable if it is present
            idx2 = find(ismember(ImageVars, 'M')==1);
            if ~isempty(idx2)
                ImageVarsDetails{end+1} = idx2;
            else
                ImageVarsDetails{end+1} = 1;
            end
            
            prompts = {'Mask variable (1:h,1:w,1:z,1:t):'};
            defAns = {ImageVarsDetails};
            title = 'Import Mask from Matlab';
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, title);
            if isempty(answer); return; end
            BatchOpt.MaskVariable = ImageVars{selIndex(1)};
        case 'MIB container'
            % find buffers that have the mask layer
            sourceBuffer = arrayfun(@(i) obj.mibModel.I{i}.maskExist, 1:obj.mibModel.maxId);
            sourceBuffer = find(sourceBuffer==1);   % find buffer indices
            sourceBuffer = sourceBuffer(sourceBuffer~=obj.mibModel.Id);     % remove currently opened buffer from the list
            
            if isempty(sourceBuffer)
                errordlg(sprintf('!!! Error !!!\n\nThe Mask layer has not been found!'), 'Missing mask', 'modal');
                return;
            end
            
            sourceBuffer = arrayfun(@(x) {['Container ' num2str(x)]}, sourceBuffer);   % convert to string cell array
            prompts = {'Please select the buffer number:'};
            defAns = {sourceBuffer};
            title = 'Import Mask from another dataset';
            answer = mibInputMultiDlg({obj.mibPath}, prompts, defAns, title);
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
switch BatchOpt.ImportFrom{1}
    case 'Matlab'
        if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Importing mask\nPlease wait...'),'Name','Import Mask', 'WindowStyle', 'modal'); end
        if BatchOpt.MaskVariable
            try
                mask = evalin('base', BatchOpt.MaskVariable);
            catch exception
                errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message),...
                    'Misssing variable!', 'modal');
                if BatchOpt.showWaitbar; delete(wb); end
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            if size(mask, 1) ~= obj.mibModel.I{BatchOpt.id}.height || ...
                    size(mask,2) ~= obj.mibModel.I{BatchOpt.id}.width 
                msgbox(sprintf('Mask and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nMask (HxWxZ) = %d x %d x %d pixels',...
                    obj.mibModel.I{BatchOpt.id}.height, obj.mibModel.I{BatchOpt.id}.width, obj.mibModel.I{BatchOpt.id}.depth, ...
                    size(mask, 1), size(mask, 2), size(mask, 3)), 'Error!', 'error', 'modal');
                if BatchOpt.showWaitbar; delete(wb); end
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            
            setDataOptions.blockModeSwitch = 0;
            setDataOptions.id = BatchOpt.id;
            obj.mibModel.mibDoBackup('mask', 1, setDataOptions);
            if BatchOpt.showWaitbar; waitbar(0.4, wb); end
            
            if size(mask, 3) == 1
                if obj.mibModel.I{BatchOpt.id}.modelType ~= 63
                    if obj.mibModel.I{BatchOpt.id}.maskExist == 0
                        obj.mibModel.I{BatchOpt.id}.maskImg{1} = ...
                            zeros([obj.mibModel.I{BatchOpt.id}.height, obj.mibModel.I{BatchOpt.id}.width,...
                            obj.mibModel.I{BatchOpt.id}.depth, obj.mibModel.I{BatchOpt.id}.time], 'uint8');
                    end
                end
                obj.mibModel.setData2D('mask', mask, NaN, NaN, 0, setDataOptions);
            elseif size(mask, 3) == obj.mibModel.I{BatchOpt.id}.depth && size(mask, 4) == 1
                obj.mibModel.setData3D('mask', mask, NaN, 4, NaN, setDataOptions);
            elseif size(mask, 4) == obj.mibModel.I{BatchOpt.id}.time
                obj.mibModel.setData4D('mask', mask, 4, NaN, setDataOptions);
            end
            
            if BatchOpt.showWaitbar; waitbar(0.95, wb); end
            [pathstr, name] = fileparts(obj.mibModel.I{BatchOpt.id}.meta('Filename'));
            obj.mibModel.I{BatchOpt.id}.maskImgFilename = fullfile(pathstr, sprintf('Mask_%s.mask', name));
            if BatchOpt.showWaitbar; waitbar(1, wb); delete(wb); end
        end
    case 'MIB container'
        sourceContainerId = str2double(BatchOpt.ContainerId{1}(10:end));    % get index of the MIB buffer
        
        % check dimensions
        [height, width, ~, depth, time] = obj.mibModel.I{BatchOpt.id}.getDatasetDimensions('image');
        [height2, width2, ~, depth2, time2] = obj.mibModel.I{sourceContainerId}.getDatasetDimensions('image');
        if height ~= height2 || width~=width2 || depth~=depth2 || time~=time2
            errordlg(sprintf('!!! Error !!!\n\nDimensions mismatch [height x width x depth x time]\nCurrent dimensions: %d x %d x %d x %d\nImported dimensions: %d x %d x %d x %d', height, width, depth, time, height2, width2, depth2, time2), 'Wrong dimensions', 'modal');
            notify(obj.mibModel, 'stopProtocol');
            return;
        end
        
        if BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Copying the mask', 'WindowStyle', 'modal'); end
        options.blockModeSwitch = 0;
        options.id = sourceContainerId;
        obj.mibModel.mibDoBackup('mask', 1, options);
        mask = obj.mibModel.getData4D('mask', 4, NaN, options);
        if BatchOpt.showWaitbar; waitbar(0.5, wb); end
        options.id = BatchOpt.id;
        obj.mibModel.setData4D('mask', mask, 4, NaN, options);
        if BatchOpt.showWaitbar; waitbar(1, wb); end
        fprintf('MIB: the mask layer was imported from %d to %d\n', sourceContainerId, BatchOpt.id);
        if BatchOpt.showWaitbar; delete(wb); end
end
obj.mibView.handles.mibMaskShowCheck.Value = 1;
obj.mibMaskShowCheck_Callback();

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

end