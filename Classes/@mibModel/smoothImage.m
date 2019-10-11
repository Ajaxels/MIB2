function smoothImage(obj, type, BatchOptIn)
% function smoothImage(obj, type, BatchOptIn)
% smooth 'Mask', 'Selection' or 'Model' layer
%
% Parameters:
% type: a string with type of the layer for the smoothing
% @li ''selection'' - smooth the 'Selection' layer
% @li ''model'' - smooth the 'Model' layer
% @li ''mask'' - smooth the 'Mask' layer
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Target - cell string, {'mask', 'selection', 'model'} - layer to smooth
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], index of the dataset for the smoothing
% 
% Return values:
% 

% Copyright (C) 10.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
    BatchOpt.Target = {'selection'};
end
BatchOpt.Target{2} = {'mask', 'selection', 'model'};
BatchOpt.SmoothingMode = {'2D'};
BatchOpt.SmoothingMode{2} = {'2D','3D'};
BatchOpt.KernelSizeX = '5';
BatchOpt.KernelSizeY = '5';
BatchOpt.KernelSizeZ = '5';
BatchOpt.Sigma = '3';
BatchOpt.MaterialIndex = '1';
BatchOpt.showWaitbar = true;   % show or not the waitbar

switch BatchOpt.Target{1}
    case 'mask'
        BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Smooth mask';
    case 'selection'
        BatchOpt.mibBatchSectionName = 'Menu -> Selection';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Smooth selection';
    case 'model'
        BatchOpt.mibBatchSectionName = 'Menu -> Models';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Smooth model';

end
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Target = sprintf('Layer to be smoothed');
BatchOpt.mibBatchTooltip.SmoothingMode = sprintf('Use 2D or 3D smoothing for the dataset');
BatchOpt.mibBatchTooltip.KernelSizeX = sprintf('X-size of the smoothing kernel in pixels');
BatchOpt.mibBatchTooltip.KernelSizeY = sprintf('Y-size of the smoothing kernel in pixels, leave empty for automatic calculation');
BatchOpt.mibBatchTooltip.KernelSizeZ = sprintf('[3D mode only]\nZ-size of the smoothing kernel in pixels');
BatchOpt.mibBatchTooltip.Sigma = sprintf('Smoothing sigma');
BatchOpt.mibBatchTooltip.MaterialIndex = sprintf('Index of material in the model to be smoothed');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt.id = obj.Id;   % default BatchOpt.id
        BatchOptLocal = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
        BatchOpt = rmfield(BatchOpt, 'id');     % remove id from the BatchOpt structure
    end
else
    BatchOptLocal = BatchOpt;   % make BatchOptLocal for standard call of the function
    BatchOptLocal.id = obj.Id;   % default BatchOpt.id
end

%% do nothing is selection is disabled
if obj.I{BatchOptLocal.id}.disableSelection == 1
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The selection layer is disabled', 'modal');
    notify(obj, 'stopProtocol');
    return; 
end

% check for the virtual stacking mode and return
if obj.I{BatchOptLocal.id}.Virtual.virtual == 1
    toolname = 'smoothing is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

if nargin < 3
    matIndex = obj.I{BatchOptLocal.id}.getSelectedMaterialIndex();
    defAns = {{'2D', '3D'}, '5', '5', '5', '3', num2str(matIndex)};
    prompt = {'Mode:',...
        'X Kernel size:', ...
        sprintf('Y Kernel size\nleave empty for automatic calculation based on voxel size:'), ...
        sprintf('Z Kernel size for 3D:'),...
        'Sigma', '[models only], index of the material:'};
    
    mibInputMultiDlgOpt.PromptLines = [1, 1, 3, 1, 1, 1];
    answer = mibInputMultiDlg([], prompt, defAns, sprintf('Smooth %s', BatchOpt.Target{1}), mibInputMultiDlgOpt);
    if isempty(answer); return; end
    
    BatchOptLocal.SmoothingMode{1} = answer{1};
    BatchOptLocal.KernelSizeX = answer{2};
    BatchOptLocal.KernelSizeY = answer{3};
    BatchOptLocal.KernelSizeZ = answer{4};
    BatchOptLocal.Sigma = answer{5};
    BatchOptLocal.MaterialIndex = answer{6};
end

options.pixSize = obj.I{BatchOptLocal.id}.pixSize;
options.orientation = obj.I{BatchOptLocal.id}.orientation;

if strcmp(BatchOptLocal.SmoothingMode{1}, '3D')
    options.filters3DCheck = 1;
    kernel = [str2double(BatchOptLocal.KernelSizeX) str2double(BatchOptLocal.KernelSizeZ)];
else
    options.filters3DCheck = 0;
    if isnan(str2double(BatchOptLocal.KernelSizeY))
        kernel = str2double(BatchOptLocal.KernelSizeX);
    else
        kernel = [str2double(BatchOptLocal.KernelSizeX) str2double(BatchOptLocal.KernelSizeY)];
    end
end

options.fitType = 'Gaussian';
options.hSize = kernel;
if isempty(BatchOptLocal.Sigma)
    options.sigma = 1;
else
    options.sigma = str2double(BatchOptLocal.Sigma);
end

options.showWaitbar = 0;    % do not show the waitbar in the ib_doImageFiltering function, the local waitbar is shown instead
t1 = 1;
t2 = obj.I{BatchOptLocal.id}.time;

if BatchOptLocal.showWaitbar; wb = waitbar(0, sprintf('Smoothing the %s layer\nPlease wait...', BatchOptLocal.Target{1}), ...
    'Name', 'Smoothing', 'WindowStyle', 'modal'); end

backupOpt.id = BatchOptLocal.id;
switch BatchOptLocal.Target{1}
    case {'mask', 'selection'}
        if t1==t2
            obj.mibDoBackup(BatchOptLocal.Target{1}, 1, backupOpt);
        end
        options.dataType = '3D';
        for t=t1:t2
            mask = cell2mat(obj.getData3D(BatchOptLocal.Target{1}, t, 4, NaN, backupOpt));
            mask = mibDoImageFiltering(mask, options);
            obj.setData3D(BatchOptLocal.Target{1}, mask, t, 4, NaN, backupOpt);
            if BatchOptLocal.showWaitbar; waitbar(t/t2, wb); end
        end
    case 'model'
        options.dataType = '3D';
        sel_model = str2double(BatchOptLocal.MaterialIndex);
        if sel_model < 1
            if BatchOptLocal.showWaitbar; delete(wb); end
            return; 
        end
        if t1==t2
            obj.mibDoBackup('model', 1, backupOpt);
        end
        start_no=sel_model;
        end_no=sel_model;
        
        for t=t1:t2
            for object = start_no:end_no
                model = cell2mat(obj.getData3D('model', t, 4, object, backupOpt));
                model = mibDoImageFiltering(model, options);
                obj.setData3D('model', model, t, 4, object, backupOpt);
            end
            if BatchOptLocal.showWaitbar; waitbar(t/t2,wb); end
        end
end

% notify the batch mode
BatchOptLocal = rmfield(BatchOptLocal, 'id');     % remove id from the BatchOptLocal structure
eventdata = ToggleEventData(BatchOptLocal);
notify(obj, 'syncBatch', eventdata);
if BatchOptLocal.showWaitbar; delete(wb); end

notify(obj, 'plotImage');  % notify to plot the image
end