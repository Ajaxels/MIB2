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
% Date: 25.04.2023

function fillSelectionOrMask(obj, sel_switch, type, BatchOptIn)
% function fillSelectionOrMask(obj, sel_switch, type, BatchOptIn)
% fill holes for selection or mask layers
%
% Parameters:
% sel_switch: a string that defines where filling of holes should be done:
% @li when @b '2D, Slice' fill holes for the currently shown slice
% @li when @b '3D, Stack' fill holes for the currently shown z-stack
% @li when @b '4D, Dataset' fill holes for the whole dataset
% type: string with type of material 'selection', 'mask'
% BatchOptIn: [@em optional], a structure with extra parameters or settings for the batch processing mode, when NaN return
%    a structure with default options via "syncBatch" event
% optional parameters
% @li .DatasetType -> cell with one of possible parameters - '2D, Slice', '3D, Stack', '4D, Dataset'
% @li .TargetLayer -> cell, layer to fill - 'selection', 'mask'
% @li .SelectedMaterial - string, index of the selected material, '-1' for mask, '0'-for exterior, '1','2'..-indices of materials
% @li .fixSelectionToMaterial - logical, when 1- limit selection only for the selected material
% @li .showWaitbar - logical, show or not the waitbar

% Updates
% 25.09.2019, ported from mibSelectionFillBtn_Callback and updated for the
% batch mode

% do nothing is selection is disabled
if obj.I{obj.Id}.enableSelection == 0; notify(obj, 'stopProtocol'); return; end

if nargin < 4; BatchOptIn = struct; end
if nargin < 3; type = []; end
if nargin < 2; sel_switch = struct; end

%% populate default values
BatchOpt = struct();
BatchOpt.id = obj.Id;   % optional, id
if isempty(type)
    BatchOpt.TargetLayer = {'selection'};     
else
    BatchOpt.TargetLayer = {type};     
end
BatchOpt.TargetLayer{2} = {'selection', 'mask'};     % 
if isempty(sel_switch)
    BatchOpt.DatasetType = {'2D, Slice'};     % '2D, Slice', '3D, Stack', '4D, Dataset'
else
    BatchOpt.DatasetType = {sel_switch};
end
BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
BatchOpt.SelectedMaterial = num2str(obj.I{BatchOpt.id}.getSelectedMaterialIndex());    % index of the selected material
BatchOpt.fixSelectionToMaterial = logical(obj.I{BatchOpt.id}.fixSelectionToMaterial);   % when 1- limit selection only for the selected material
BatchOpt.Use2DParallelComputing = false;
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar

if strcmp(BatchOpt.TargetLayer{1}, 'selection')
    BatchOpt.mibBatchSectionName = 'Panel -> Selection';
    BatchOpt.mibBatchActionName = 'Fill selection';
else
    BatchOpt.mibBatchSectionName = 'Menu -> Mask';
    BatchOpt.mibBatchActionName = 'Fill mask';
end

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.TargetLayer = sprintf('Layer to be eroded');
BatchOpt.mibBatchTooltip.DatasetType = sprintf('Specify whether to erode the current slice (2D, Slice), the stack (3D, Stack) or complete dataset (4D, Dataset)');
BatchOpt.mibBatchTooltip.SelectedMaterial = sprintf('index of the selected material; -1 for mask, 0-for exterior, 1,2,3 materials of the model');
BatchOpt.mibBatchTooltip.fixSelectionToMaterial = sprintf('when checked, limit selection only for the selected material');
BatchOpt.mibBatchTooltip.Use2DParallelComputing = sprintf('Use parallel processing to fill images in 2D');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%%
batchModeSwitch = 0;
if isstruct(BatchOptIn) == 0
    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
        % trigger syncBatch event to send BatchOptInOut to mibBatchController
        BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
        eventdata = ToggleEventData(BatchOpt);
        notify(obj, 'syncBatch', eventdata);
    else
        errordlg(sprintf('A structure as the 4th parameter is required!'));
    end
    return;
else
    % add/update BatchOpt with the provided fields in BatchOptIn
    % combine fields from input and default structures
    BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    if isfield(BatchOptIn, 'mibBatchTooltip'); batchModeSwitch = 1; end
end

%% start of the function
% do nothing is selection is disabled
if obj.I{BatchOpt.id}.enableSelection == 0; notify(obj, 'stopProtocol'); return; end
tic;

selcontour = str2double(BatchOpt.SelectedMaterial);
selectedOnly = BatchOpt.fixSelectionToMaterial;

getDataOptions.id = BatchOpt.id;
% do not make backup in the batch processing mode
if ~batchModeSwitch
    if strcmp(BatchOpt.DatasetType{1}, '3D, Stack')
        obj.mibDoBackup(BatchOpt.TargetLayer{1}, 1, getDataOptions);
    else
        obj.mibDoBackup(BatchOpt.TargetLayer{1}, 0, getDataOptions);
    end
end

% define the time points
if strcmp(BatchOpt.DatasetType{1}, '4D, Dataset')
    t1 = 1;
    t2 = obj.I{BatchOpt.id}.time;
else    % 2D, 3D
    t1 = obj.I{BatchOpt.id}.slices{5}(1);
    t2 = obj.I{BatchOpt.id}.slices{5}(2);
end

if strcmp(BatchOpt.DatasetType{1}, '2D, Slice')
    filled_img = imfill(cell2mat(obj.getData2D(BatchOpt.TargetLayer{1}, NaN, NaN, NaN, getDataOptions)),'holes');
    if selectedOnly
        filled_img = filled_img & cell2mat(obj.getData2D('model', NaN, NaN, selcontour, getDataOptions));
    end
    obj.setData2D(BatchOpt.TargetLayer{1}, {filled_img}, NaN, NaN, NaN, getDataOptions);
else 
    showWaitbar = BatchOpt.showWaitbar;
    % get max number of iterations
    max_size = obj.I{BatchOpt.id}.dim_yxczt(obj.I{BatchOpt.id}.orientation);
    max_size2 = max_size*(t2-t1+1);
    
    % define parallel processing settings
    % when not in the batch mode, when parpool is present use it
    if ~batchModeSwitch
        p = gcp('nocreate');
        if ~isempty(p); BatchOpt.Use2DParallelComputing = true; end
    end

    % check for parallel processing options
    if BatchOpt.Use2DParallelComputing
        parforArg = obj.cpuParallelLimit;    % Maximum number of workers running in parallel
        if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
    else
        parforArg = 0;
    end

    if showWaitbar
        pw = PoolWaitbar(max_size2, sprintf('Filling holes in 2D for %s\nPlease wait...', BatchOpt.TargetLayer{1}), [], 'Filling holes...');
        pw.setIncrement(10);
    end
    
    for t=t1:t2
        getDataOptions.t = [t, t];
        if ~BatchOpt.Use2DParallelComputing
            for layer_id=1:max_size
                if showWaitbar && mod(layer_id, 10) == 1; increment(pw); end

                slice = obj.getData2D(BatchOpt.TargetLayer{1}, layer_id, obj.I{BatchOpt.id}.orientation, 0, getDataOptions);
                if max(max(slice{1})) < 1; continue; end

                slice = imfill(slice{1}, 'holes');
                if selectedOnly
                    slice = slice & cell2mat(obj.getData2D('model', layer_id, obj.I{BatchOpt.id}.orientation, selcontour, getDataOptions));
                end
                obj.setData2D(BatchOpt.TargetLayer{1}, {slice}, layer_id, obj.I{BatchOpt.id}.orientation, 0, getDataOptions);
            end
        else    % process in parallel
            stack = cell2mat(obj.getData3D(BatchOpt.TargetLayer{1}, t, obj.I{BatchOpt.id}.orientation, 0, getDataOptions));
            model = cell2mat(obj.getData3D('model', t, obj.I{BatchOpt.id}.orientation, selcontour, getDataOptions));
            parfor (layer_id=1:max_size, parforArg)
                if showWaitbar && mod(layer_id, 10) == 1;  increment(pw); end
                
                slice = stack(:,:,layer_id);
                if max(max(slice)) < 1; continue; end

                slice = imfill(slice, 'holes');
                if selectedOnly
                    slice = slice & model(:,:,layer_id);
                end
                stack(:,:,layer_id) = slice;
            end
            obj.setData3D(BatchOpt.TargetLayer{1}, {stack}, t, obj.I{BatchOpt.id}.orientation, 0, getDataOptions);
        end
    end
    if showWaitbar; pw.deletePoolWaitbar(); end

    if ~strcmp(BatchOpt.DatasetType{1}, '2D, Slice')
        toc;
    end
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');
end