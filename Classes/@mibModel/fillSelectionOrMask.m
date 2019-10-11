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

% Copyright (C) 19.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 25.09.2019, ported from mibSelectionFillBtn_Callback and updated for the
% batch mode

% do nothing is selection is disabled
if obj.I{obj.Id}.disableSelection == 1; notify(obj, 'stopProtocol'); return; end

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
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%%
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
end

tic;
selcontour = str2double(BatchOpt.SelectedMaterial);
selectedOnly = BatchOpt.fixSelectionToMaterial;

storeOptions.id = BatchOpt.id;
if strcmp(BatchOpt.DatasetType{1}, '2D, Slice')
    obj.mibDoBackup(BatchOpt.TargetLayer{1}, 0, storeOptions);
    filled_img = imfill(cell2mat(obj.getData2D(BatchOpt.TargetLayer{1}, NaN, NaN, NaN, storeOptions)),'holes');
    if selectedOnly
        filled_img = filled_img & cell2mat(obj.getData2D('model', NaN, NaN, selcontour, storeOptions));
    end
    obj.setData2D(BatchOpt.TargetLayer{1}, {filled_img}, NaN, NaN, NaN, storeOptions);
else 
    if strcmp(BatchOpt.DatasetType{1},'3D, Stack') 
        obj.mibDoBackup(BatchOpt.TargetLayer{1}, 1, storeOptions);
        t1 = obj.I{BatchOpt.id}.slices{5}(1);
        t2 = obj.I{BatchOpt.id}.slices{5}(2);
        if BatchOpt.showWaitbar; wb = waitbar(0,'Filling holes in 2D for a whole Z-stack...','WindowStyle','modal'); end
    else
        t1 = 1;
        t2 = obj.I{BatchOpt.id}.time;
        if BatchOpt.showWaitbar; wb = waitbar(0,'Filling holes in 2D for a whole dataset...','WindowStyle','modal'); end
    end
    max_size = obj.I{BatchOpt.id}.dim_yxczt(obj.I{BatchOpt.id}.orientation);
    max_size2 = max_size*(t2-t1+1);
    index = 1;
    
    for t=t1:t2
        storeOptions.t = [t, t];
        for layer_id=1:max_size
            if BatchOpt.showWaitbar; if mod(index, 10)==0; waitbar(layer_id/max_size2, wb); end; end
            slice = cell2mat(obj.getData2D(BatchOpt.TargetLayer{1}, layer_id, obj.I{BatchOpt.id}.orientation, 0, storeOptions));
            if max(max(slice)) < 1; continue; end
            slice = imfill(slice,'holes');
            if selectedOnly
                slice = slice & cell2mat(obj.getData2D('model', layer_id, obj.I{BatchOpt.id}.orientation, selcontour, storeOptions));
            end
            obj.setData2D(BatchOpt.TargetLayer{1}, {slice}, layer_id, obj.I{BatchOpt.id}.orientation, 0, storeOptions);
            index = index + 1;
        end
    end
    if BatchOpt.showWaitbar; delete(wb); end
    toc
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');
end