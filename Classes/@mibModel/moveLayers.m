function moveLayers(obj, SourceLayer, DestinationLayer, DatasetType, ActionType, BatchOptIn)
% function moveLayers(obj, SourceLayer, DestinationLayer, DatasetType, ActionType, BatchOptIn)
% to move datasets between the layers (image, model, mask, selection)
%
% for example, to move selection to mask, or selection to a specified material of the model
%
% Parameters:
% SourceLayer: name of a layer to get data, ''selection'', ''mask'', or
% ''model'', can be empty []
% DestinationLayer: name of a layer to set data, ''selection'', ''mask'', or ''model'', can be empty []
% DatasetType: a string, can be empty []
% - ''2D, Slice'' - 2D mode, move only the shown slice [y,x]
% - ''3D, Stack'' - 3D mode, move 3D dataset [y,x,z]
% - ''4D, Dataset'' - 4D mode, move 4D dataset [y,x,z,t]
% ActionType: a type of the desired action, can be empty []
% - ''add'' - add mask to selection
% - ''remove'' - remove mask from selection
% - ''replace'' - replace selection with mask
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .id -> [@em optional], an index dataset from 1 to 9, default = currently shown dataset
% @li .blockModeSwitch -> logical, use or not the block mode (@b 0 - return full dataset, @b 1 - return only the shown part)
% @li .roiId -> string, use or not the get ROI mode (@b when @b missing or less than 0, return
% full dataset, without ROI; @b 0 - return all ROIs dataset, @b Index - return ROI with the index, @b [] - currently selected) (@b Attention: see also fillBg parameter!)
% @li .fillBg -> string, when @em NaN (@b default) -> crops the dataset as a rectangle; when @em a @em number fills the areas out of the ROI area with this intensity number
% @li .y -> [@em optional], [ymin, ymax] of the part of the dataset to take
% @li .x -> [@em optional], [xmin, xmax] of the part of the dataset to take
% @li .z -> [@em optional], [zmin, zmax] of the part of the dataset to take
% @li .t -> [@em optional], [tmin, tmax] of the part of the dataset to take
% @li .level -> [@em optional], index of image level from the image pyramid [not yet used]
% @li .id - number, id of the dataset
% @li .SelectedMaterial - string, index of the selected material, '-1' for mask, '0'-for exterior, '1','2'..-indices of materials
% @li .selectedAddToMaterial - string, index of the selected add to material, '-1' for mask, '0'-for exterior, '1','2'..-indices of materials
% @li .fixSelectionToMaterial - logical, when 1- limit selection only for the selected material
% @li .fixSelectionToMask - logical, when checked will do add, replace, remove actions only in the masked areas
% @li .showWaitbar - logical, show or not the waitbar
%
% Return values:

%| @b Examples:
% @code obj.mibModel.moveLayers('selection', 'mask', '3D, Stack', 'add');     // add selection to mask for  @endcode
% @code obj.mibModel.moveLayers('selection', 'mask', '3D, Stack', 'add');     // remove selection from mask  @endcode

% Copyright (C) 17.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 26.06.2019, function was moved from mibController to mibModel class

if nargin < 5; errordlg(sprintf('!!! Error !!!\n\nAt least 4 parameters are required for this function')); return; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
% which layer should be moved
if ~isempty(SourceLayer); BatchOpt.SourceLayer = {SourceLayer}; else; BatchOpt.SourceLayer = {'selection'}; end
BatchOpt.SourceLayer{2} = {'selection', 'mask', 'model'};
% to which layer should be moved
if ~isempty(DestinationLayer); BatchOpt.DestinationLayer = {DestinationLayer}; else; BatchOpt.DestinationLayer = {'selection'}; end
BatchOpt.DestinationLayer{2} = {'selection', 'mask', 'model'};  
% part of the dataset to be moved
if ~isempty(DatasetType); BatchOpt.DatasetType = {DatasetType}; else; BatchOpt.DatasetType = {'2D, Slice'}; end
BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
% type of the movement action
if ~isempty(ActionType); BatchOpt.ActionType = {ActionType}; else; BatchOpt.ActionType = {'add'}; end
BatchOpt.ActionType{2} = {'add', 'remove', 'replace'};
BatchOpt.SelectedMaterial = num2str(obj.I{obj.Id}.getSelectedMaterialIndex());    % index of the selected material
BatchOpt.SelectedAddToMaterial = num2str(obj.I{obj.Id}.getSelectedMaterialIndex('AddTo'));       % index of the target material
BatchOpt.fixSelectionToMaterial = logical(obj.I{obj.Id}.fixSelectionToMaterial);   % when 1- limit selection only for the selected material
BatchOpt.fixSelectionToMask = logical(obj.I{obj.Id}.fixSelectionToMask);    % when checked will do add, replace, remove actions only in the masked areas
BatchOpt.blockModeSwitch = logical(obj.I{obj.Id}.blockModeSwitch);  % use or not the block mode
BatchOpt.roiId = num2str(obj.I{obj.Id}.selectedROI);
BatchOpt.fillBg = num2str(NaN);
BatchOpt.id = obj.Id;   
% BatchOpt.level = num2str(1); 
BatchOpt.showWaitbar = true;   % show or not the waitbar

switch BatchOpt.SourceLayer{1}
    case 'model'
        BatchOpt.mibBatchSectionName = 'Menu -> Models';    % section name for the Batch
        switch BatchOpt.DestinationLayer{1}
            case 'mask'
                BatchOpt.mibBatchActionName = 'Model to Mask';
            case 'selection'
                BatchOpt.mibBatchActionName = 'Model to Selection';
        end
    case 'mask'
        BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
        switch BatchOpt.DestinationLayer{1}
            case 'model'
                BatchOpt.mibBatchActionName = 'Mask to Model';
            case 'selection'
                BatchOpt.mibBatchActionName = 'Mask to Selection';
        end
    case 'selection'
        BatchOpt.mibBatchSectionName = 'Menu -> Selection';    % section name for the Batch
        switch BatchOpt.DestinationLayer{1}
            case 'mask'
                BatchOpt.mibBatchActionName = 'Selection to Mask';
            case 'model'
                BatchOpt.mibBatchActionName = 'Selection to Model';
        end
end

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.SourceLayer = sprintf('specify the source layer that will be moved');
BatchOpt.mibBatchTooltip.DestinationLayer = sprintf('specify the destibation layer to where the source layer will be moved');
BatchOpt.mibBatchTooltip.DatasetType = sprintf('Type of the dataset to process, could be overridden with x,y,z,t fields');
BatchOpt.mibBatchTooltip.ActionType = sprintf('type of the layer movement');
BatchOpt.mibBatchTooltip.SelectedMaterial = sprintf('index of the selected material; -1 for mask, 0-for exterior, 1,2,3 materials of the model');
BatchOpt.mibBatchTooltip.SelectedAddToMaterial = sprintf('index of the material to be added to; -1 for mask, 0-for exterior, 1,2,3 materials of the model');
BatchOpt.mibBatchTooltip.fixSelectionToMaterial = sprintf('when checked, limit selection only for the selected material');
BatchOpt.mibBatchTooltip.fixSelectionToMask = sprintf('when checked, will do add, replace, remove actions only in the masked areas');
BatchOpt.mibBatchTooltip.blockModeSwitch = sprintf('force to use or not the block mode');
BatchOpt.mibBatchTooltip.roiId = sprintf('ROI mode: when less than 0, ROIs are not used; when 0 - move all ROIs; any number - move ROI with the index, [] - currently selected');
BatchOpt.mibBatchTooltip.fillBg = sprintf('ROI mode: when NaN - crop the dataset as a rectangle; when a number fills the areas out of the ROI area with this intensity');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution; always off for 2D datasets');

%% Batch mode check actions
if nargin == 6  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 6rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

%% start function
% check for the virtual stacking mode and return
if obj.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = [];
    warndlg(sprintf('!!! Warning !!!\n\nThis %saction is not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

% when the Selection layer is disabled and SourceLayer/to is selection ->
% return
if obj.I{BatchOpt.id}.disableSelection == 1
    warndlg(sprintf('The models, selection and mask layers are switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The models are disabled','modal');
    notify(obj, 'stopProtocol');
    return; 
end

if BatchOpt.blockModeSwitch == 0
    if ~isfield(BatchOpt, 'roiId')
        BatchOpt.roiId = num2str(obj.I{BatchOpt.id}.selectedROI);
    end
else
    BatchOpt.roiId = '-1';
end

BatchOptLocal = BatchOpt;   % make a copy of the BatchOpt
BatchOpt = rmfield(BatchOpt, 'id');

% convert to numbers to use in MoveXXXtoXXXDataset functions
BatchOptLocal.SelectedMaterial = str2double(BatchOptLocal.SelectedMaterial);
BatchOptLocal.SelectedAddToMaterial = str2double(BatchOptLocal.SelectedAddToMaterial);
BatchOptLocal.roiId = str2double(BatchOptLocal.roiId);
BatchOptLocal.fillBg = str2double(BatchOptLocal.fillBg);
BatchOptLocal.selected_sw = BatchOptLocal.fixSelectionToMaterial;
BatchOptLocal.maskedAreaSw = BatchOptLocal.fixSelectionToMask;

t1 = tic;

contSelIndex = BatchOptLocal.SelectedMaterial;
contAddIndex = BatchOptLocal.SelectedAddToMaterial;
if strcmp(BatchOptLocal.SourceLayer{1}, 'model') && contSelIndex < 0; BatchOptLocal.SourceLayer{1} = 'mask'; end     % when ones press Ctrl+A to highlight the Mask layer
if strcmp(BatchOptLocal.SourceLayer{1}, 'model') && contAddIndex < 0; BatchOptLocal.DestinationLayer{1} = 'mask'; end     % when ones press Ctrl+A to highlight the Mask layer

% fix situation when using Alt+A shortcut over the Mask entry when Fix
% selection to meterial is enabled
if BatchOptLocal.fixSelectionToMaterial == 1 && strcmp(BatchOptLocal.SourceLayer{1}, 'mask') && contAddIndex == -1
    BatchOptLocal.fixSelectionToMaterial = false;
end

% check for existance of the model layer
if obj.I{BatchOptLocal.id}.modelExist == 0 && strcmp(BatchOptLocal.DestinationLayer{1}, 'model')
    msgbox(sprintf('Please Create the Model first!\n\nPress the Create button in the Segmentation panel'), 'The model is missing!', 'warn');
    notify(obj, 'stopProtocol');
    return;
end

% tweak, when there is only a single slice in the dataset
if strcmp(BatchOptLocal.DatasetType{1}, '4D, Dataset') && obj.I{BatchOptLocal.id}.time == 1
    BatchOptLocal.DatasetType{1} = '3D, Stack';
end
% tweak, when there is only a single slice in the dataset
if strcmp(BatchOptLocal.DatasetType{1},'3D, Stack') && obj.I{BatchOptLocal.id}.depth == 1
    BatchOptLocal.DatasetType{1} = '2D, Slice';
end

if strcmp(BatchOptLocal.DatasetType{1}, '2D, Slice')
    switch3d = 0;
    showWaitbar = 0;
else
    switch3d = 1;
    showWaitbar = BatchOptLocal.showWaitbar;
end
if showWaitbar; wb = waitbar(0,[BatchOptLocal.ActionType{1} ' ' BatchOptLocal.SourceLayer{1} ' to/with ' BatchOptLocal.DestinationLayer{1} ' for ' BatchOptLocal.DatasetType{1} ' layer(s)...'],'Name','Moving layers...','WindowStyle','modal'); end

if strcmp(BatchOptLocal.DatasetType{1}, '4D, Dataset')
    BatchOptLocal.t = [1 obj.I{BatchOptLocal.id}.time];
else
    BatchOptLocal.t = [obj.I{BatchOptLocal.id}.slices{5}(1) obj.I{BatchOptLocal.id}.slices{5}(1)];
end

% do backup, not for 4D data
if ~strcmp(BatchOptLocal.DatasetType{1},'4D, Dataset')
    if obj.I{BatchOptLocal.id}.modelType == 63
        obj.mibDoBackup('everything', switch3d, BatchOptLocal);
    else
        obj.mibDoBackup(BatchOptLocal.DestinationLayer{1}, switch3d, BatchOptLocal);
    end
end

% The first part is to speed up movement of layers for whole dataset, i.e. without ROI mode and without blockmode switch
if strcmp(BatchOptLocal.DatasetType{1},'4D, Dataset') || (strcmp(BatchOptLocal.DatasetType{1},'3D, Stack') && obj.I{BatchOptLocal.id}.time==1) && BatchOptLocal.roiId(1) < 0 && BatchOptLocal.blockModeSwitch == 0  % to be used only with full datasets, for roi mode and single slices check the procedures below
    BatchOptLocal.contSelIndex = contSelIndex; % index of the selected material
    BatchOptLocal.contAddIndex = contAddIndex; % index of the target material
    
    switch BatchOptLocal.SourceLayer{1}
        case 'mask'
            switch BatchOptLocal.DestinationLayer{1}
                case 'selection'
                    obj.I{BatchOptLocal.id}.moveMaskToSelectionDataset(BatchOptLocal.ActionType{1}, BatchOptLocal); % checked
                case 'model'
                    obj.I{BatchOptLocal.id}.moveMaskToModelDataset(BatchOptLocal.ActionType{1}, BatchOptLocal);  
                case 'mask'
                    return;
            end
        case 'model'
            switch BatchOptLocal.DestinationLayer{1}
                case 'selection'
                    obj.I{BatchOptLocal.id}.moveModelToSelectionDataset(BatchOptLocal.ActionType{1}, BatchOptLocal);    % checked
                case 'mask'
                    obj.I{BatchOptLocal.id}.moveModelToMaskDataset(BatchOptLocal.ActionType{1}, BatchOptLocal);   % checked
                case 'model'
                    return;
            end
        case 'selection'
            switch BatchOptLocal.DestinationLayer{1}
                case 'mask'
                    obj.I{BatchOptLocal.id}.moveSelectionToMaskDataset(BatchOptLocal.ActionType{1}, BatchOptLocal);   % checked  
                case 'model'
                    obj.I{BatchOptLocal.id}.moveSelectionToModelDataset(BatchOptLocal.ActionType{1}, BatchOptLocal);  % checked
                case 'selection'
                    return;
            end
    end
else    % move layers for 2D/3D and ROI and block modes
    if BatchOptLocal.blockModeSwitch
        doNotTranspose = 0;
    else
        doNotTranspose = 4;
    end
    switch BatchOptLocal.SourceLayer{1}
        case 'mask'     % select mask layer
            if switch3d
                img = obj.getData4D('mask', doNotTranspose, NaN, BatchOptLocal);
            else
                img = obj.getData2D('mask', NaN, NaN, NaN, BatchOptLocal);
            end
        case 'model'      % select obj layer
            if obj.I{BatchOptLocal.id}.modelExist == 0 || obj.I{BatchOptLocal.id}.modelType == 128; if showWaitbar; delete(wb); end; notify(obj, 'stopProtocol'); return; end    % different model type
            if switch3d
                img = obj.getData4D('model', doNotTranspose, contSelIndex, BatchOptLocal);
            else
                img = obj.getData2D('model', NaN, NaN, contSelIndex, BatchOptLocal);
            end
        case 'selection'
            if switch3d
                img = obj.getData4D('selection', doNotTranspose, NaN, BatchOptLocal);
                obj.I{BatchOptLocal.id}.clearSelection('3D', NaN, obj.I{BatchOptLocal.id}.getCurrentSliceNumber, obj.I{BatchOptLocal.id}.getCurrentTimePoint, BatchOptLocal.blockModeSwitch)
            else
                img = obj.getData2D('selection', NaN, NaN, NaN, BatchOptLocal);
                obj.I{BatchOptLocal.id}.clearSelection('2D', NaN, obj.I{BatchOptLocal.id}.getCurrentSliceNumber, obj.I{BatchOptLocal.id}.getCurrentTimePoint, BatchOptLocal.blockModeSwitch)
            end
    end
    
    % filter results
    if BatchOptLocal.fixSelectionToMaterial && ~strcmp(BatchOptLocal.SourceLayer{1},'model') && obj.I{BatchOptLocal.id}.modelExist && ~strcmp(BatchOptLocal.DestinationLayer{1},'model')
        if switch3d
            sel_img = obj.getData4D('model', doNotTranspose, contSelIndex, BatchOptLocal);
        else
            sel_img = obj.getData2D('model', NaN, NaN, contSelIndex, BatchOptLocal);
        end
        for i=1:numel(img)
            img{i} = bitand(img{i}, sel_img{i});    % img{:}(sel_img{:}==0) = 0;
        end
        clear sel_img;
    end
    
    if BatchOptLocal.fixSelectionToMask
        if ~strcmp(BatchOptLocal.SourceLayer{1},'mask') && ~strcmp(BatchOptLocal.DestinationLayer{1},'mask')
            if switch3d
                mask = obj.getData4D('mask', doNotTranspose, NaN, BatchOptLocal);
            else
                mask = obj.getData2D('mask', NaN, NaN, NaN, BatchOptLocal);
            end
            
            for i=1:numel(mask)
                img{i} = bitand(img{i}, mask{i});
            end
            clear mask;
        end
    end
    
    if switch3d     %3d mode full dataset
        switch BatchOptLocal.DestinationLayer{1}
            case 'selection'
                switch BatchOptLocal.ActionType{1}
                    case 'add'
                        selection = obj.getData4D('selection', doNotTranspose, NaN, BatchOptLocal);
                        for i=1:numel(img)
                            selection{i} = bitor(selection{i}, img{i}); %selection{:}(img{:}==1) = 1;
                        end
                    case 'replace'
                        selection = img;
                    case 'remove'
                        selection = obj.getData4D('selection', doNotTranspose, NaN, BatchOptLocal);
                        for i=1:numel(img)
                            selection{i} = selection{i} - img{i};  %selection{:}(img{:}==1) = 0;
                        end
                end
                obj.setData4D('selection', selection, doNotTranspose, NaN, BatchOptLocal);
            case 'mask'
                obj.I{BatchOptLocal.id}.maskExist = 1;
                if obj.I{BatchOptLocal.id}.modelType ~= 63
                    if isnan(obj.I{BatchOptLocal.id}.maskImg{1}(1,1,1,1))
                        obj.I{BatchOptLocal.id}.maskImg = ...
                            zeros([obj.I{BatchOptLocal.id}.height,obj.I{BatchOptLocal.id}.width,obj.I{BatchOptLocal.id}.depth,obj.I{BatchOptLocal.id}.time], 'uint8');
                    end
                end
                switch BatchOptLocal.ActionType{1}
                    case 'add'
                        mask = obj.getData4D('mask', doNotTranspose, NaN, BatchOptLocal);
                        for i=1:numel(mask)
                            mask{i} = bitor(mask{i}, img{i});   % mask{:}(img{:}==1) = 1;
                        end
                    case 'replace'
                        mask = img;
                    case 'remove'
                        mask = obj.getData4D('mask', doNotTranspose, NaN, BatchOptLocal);
                        for i=1:numel(img)
                            mask{i} = mask{i} - img{i}; % mask{:}(img{:}==1) = 0;
                        end
                end
                obj.setData4D('mask', mask, doNotTranspose, NaN, BatchOptLocal);
            case 'model'
                if obj.I{BatchOptLocal.id}.modelExist == 0 || obj.I{BatchOptLocal.id}.modelType == 128; if showWaitbar; delete(wb); end; notify(obj, 'stopProtocol'); return; end
                model = obj.getData4D('model', doNotTranspose, NaN, BatchOptLocal);     % %model = getData4D('model', 4, contAddIndex); <- seems to be slower
                obj.I{BatchOptLocal.id}.modelExist = 1;
                switch BatchOptLocal.ActionType{1}
                    case 'add'
                        for i=1:numel(img)
                            model{i}(img{i}==1) = contAddIndex;
                        end
                    case 'replace'
                        for i=1:numel(img)
                            model{i}(model{i}==contAddIndex) = 0;
                            model{i}(img{i}==1) = contAddIndex;
                        end
                    case 'remove'
                        if BatchOptLocal.fixSelectionToMaterial
                            for i=1:numel(img)
                                model{i}(bitand(img{i}, model{i}/contSelIndex)==1) = 0; %model{:}(img{:}==1 & model{:} == contSelIndex) = 0;
                            end
                        else
                            for i=1:numel(img)
                                model{i}(img{i}==1) = 0;
                            end
                        end
                end
                obj.setData4D('model', model, doNotTranspose, NaN, BatchOptLocal);
        end
    else    % 2d mode, the current slice only
        switch BatchOptLocal.DestinationLayer{1}
            case 'selection'
                switch BatchOptLocal.ActionType{1}
                    case 'add'
                        selection = obj.getData2D('selection', NaN, NaN, NaN, BatchOptLocal);
                        for i=1:numel(img)
                            selection{i}(img{i}==1) = 1;
                        end
                    case 'replace'
                        selection = img;
                    case 'remove'
                        selection = obj.getData2D('selection', NaN, NaN, NaN, BatchOptLocal);
                        for i=1:numel(img)
                            selection{i}(img{i}==1) = 0;
                        end
                end
                obj.setData2D('selection', selection, NaN, NaN, NaN, BatchOptLocal);
            case 'mask'
                obj.I{BatchOptLocal.id}.maskExist = 1;
                if obj.I{BatchOptLocal.id}.modelType ~= 63
                    if isnan(obj.I{BatchOptLocal.id}.maskImg{1}(1,1,1,1))
                        obj.I{BatchOptLocal.id}.maskImg{1} = ...
                            zeros([obj.I{BatchOptLocal.id}.height,obj.I{BatchOptLocal.id}.width,obj.I{BatchOptLocal.id}.depth,obj.I{BatchOptLocal.id}.time],'uint8'); 
                    end
                end
                switch BatchOptLocal.ActionType{1}
                    case 'add'
                        mask = obj.getData2D('mask', NaN, NaN, NaN, BatchOptLocal);
                        for i=1:numel(mask)
                            mask{i} = bitor(mask{i}, img{i});       % mask{:}(img{:}==1) = 1;
                        end
                    case 'replace'
                        mask = img;
                    case 'remove'
                        mask = obj.getData2D('mask', NaN, NaN, NaN, BatchOptLocal);
                        for i=1:numel(img)
                            mask{i} = mask{i} - img{i}; % mask{:}(img{:}==1) = 0;
                        end
                end
                obj.setData2D('mask', mask, NaN, NaN, NaN, BatchOptLocal);
            case 'model'
                if obj.I{BatchOptLocal.id}.modelExist == 0 || obj.I{BatchOptLocal.id}.modelType == 128
                    msgbox(sprintf('No model, or the model of the wrong type.\n\nPress the Create button in the Segmentation panel to start a new model.'),'Problem with model','error');
                    notify(obj, 'stopProtocol');
                    return;
                end
                obj.I{BatchOptLocal.id}.modelExist = 1;
                model = obj.getData2D('model', NaN, NaN, NaN, BatchOptLocal); 
                switch BatchOptLocal.ActionType{1}
                    case 'add'
                        for i=1:numel(img)
                            model{i}(img{i}==1) = contAddIndex;
                        end
                    case 'replace'
                        for i=1:numel(img)
                            model{i}(model{i}==contAddIndex) = 0;
                            model{i}(img{i}==1) = contAddIndex;
                        end
                    case 'remove'
                        if BatchOptLocal.fixSelectionToMaterial
                            for i=1:numel(img)
                                model{i}(img{i}==1 & model{i} == contSelIndex) = 0;
                            end
                        else
                            for i=1:numel(img)
                                model{i}(img{i}==1) = 0;
                            end
                        end
                end
                obj.setData2D('model', model, NaN, NaN, NaN, BatchOptLocal);
        end
    end
end

% switch on Model layer
if strcmp(BatchOptLocal.DestinationLayer{1}, 'model') 
    obj.I{BatchOptLocal.id}.modelExist = 1;
    eventdata = ToggleEventData(1);   % show the model checkbox on
    notify(obj, 'showModel', eventdata);
end

% switch on Mask layer
if strcmp(BatchOptLocal.DestinationLayer{1}, 'mask') 
    obj.I{BatchOptLocal.id}.maskExist = 1;
    obj.mibMaskShowCheck = 1;
    eventdata = ToggleEventData(1);   % show the model checkbox on
    notify(obj, 'showMask', eventdata);
end
if switch3d; if showWaitbar; delete(wb); end; toc(t1); end
% notify the batch mode
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');   % plot image

end