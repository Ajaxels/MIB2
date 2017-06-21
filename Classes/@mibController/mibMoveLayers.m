function mibMoveLayers(obj, obj_type_from, obj_type_to, layers_id, action_type, options)
% function mibMoveLayers(obj, obj_type_from, obj_type_to, layers_id, action_type, options)
% to move datasets between the layers (image, model, mask, selection)
%
% for example, to move selection to mask, or selection to a specified material of the model
%
% Parameters:
% obj_type_from: name of a layer to get data, ''selection'', ''mask'', or ''model''
% obj_type_to: name of a layer to set data, ''selection'', ''mask'', or ''model''
% layers_id: a string
% - ''2D'' - 2D mode, move only the shown slice [y,x]
% - ''3D'' - 3D mode, move 3D dataset [y,x,z]
% - ''4D'' - 4D mode, move 4D dataset [y,x,z,t]
% action_type: a type of the desired action
% - ''add'' - add mask to selection
% - ''remove'' - remove mask from selection
% - ''replace'' - replace selection with mask
% options: [@em optional], a structure with extra parameters
% @li .blockModeSwitch -> use or not the block mode (@b 0 - return full dataset, @b 1 - return only the shown part)
% @li .roiId -> use or not the get ROI mode (@b when @b missing or less than 0, return
% full dataset, without ROI; @b 0 - return all ROIs dataset, @b Index - return ROI with the index, @b [] - currently selected) (@b Attention: see also fillBg parameter!)
% @li .fillBg -> when @em NaN (@b default) -> crops the dataset as a rectangle; when @em a @em number fills the areas out of the ROI area with this intensity number
% @li .y -> [@em optional], [ymin, ymax] of the part of the dataset to take
% @li .x -> [@em optional], [xmin, xmax] of the part of the dataset to take
% @li .z -> [@em optional], [zmin, zmax] of the part of the dataset to take
% @li .t -> [@em optional], [tmin, tmax] of the part of the dataset to take
% @li .level -> [@em optional], index of image level from the image pyramid
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:

%| @b Examples:
% @code obj.mibMoveLayers('selection', 'mask', '3D', 'add');     // add selection to mask for  @endcode
% @code obj.mibMoveLayers('selection', 'mask', '3D', 'add');     // remove selection from mask  @endcode

% Copyright (C) 17.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

t1 = tic;
% when the Selection layer is disabled and obj_type_from/to is selection ->
% return
if obj.mibModel.preferences.disableSelection == 1
    warndlg(sprintf('The models, selection and mask layers are switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The models are disabled','modal');
    return; 
end

if nargin < 6; options = struct(); end
if ~isfield(options, 'id')
    options.id = obj.mibModel.Id;
end
if ~isfield(options, 'blockModeSwitch'); options.blockModeSwitch = obj.mibModel.getImageProperty('blockModeSwitch'); end
if options.blockModeSwitch == 0
    if ~isfield(options, 'roiId')
        %options.roiId = obj.mibView.getRoiSwitch() - 1; 
        if obj.mibView.getRoiSwitch() == 0
            options.roiId = -1;
        else
            options.roiId = obj.mibModel.I{options.id}.selectedROI;
        end
    end
else
    options.roiId = -1;
end

if obj.mibModel.I{obj.mibModel.Id}.modelType < 256
    contSelIndex = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;    % index of the selected material
    if strcmp(obj_type_from, 'model') && contSelIndex == - 1
        obj_type_from = 'mask'; 
    end
    contAddIndex = obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial - 2;       % index of the target material
else
    if obj.mibModel.I{obj.mibModel.Id}.selectedMaterial > 2
        contSelIndex = str2double(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{obj.mibModel.I{obj.mibModel.Id}.selectedMaterial-2});
    elseif obj.mibModel.I{obj.mibModel.Id}.selectedMaterial == 2
        contSelIndex = 0;
    else
        
    end
    if obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial > 2
        contAddIndex = str2double(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2});
    elseif obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial == 2
        contAddIndex = 0;
    else
        
    end
end

selected_sw = obj.mibView.handles.mibSegmSelectedOnlyCheck.Value;   % when 1- limit selection only for the selected material
maskedAreaSw = obj.mibView.handles.mibMaskedAreaCheck.Value;    % when checked will do add, replace, remove actions only in the masked areas

% fix situation when using Alt+A shortcut over the Mask entry when Fix
% selection to meterial is enabled
if selected_sw == 1 && strcmp(obj_type_from, 'mask') && contAddIndex == -1
    selected_sw = 0;
end

% check for existance of the model layer
if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 && strcmp(obj_type_to, 'model')
    msgbox(sprintf('Please Create the Model first!\n\nPress the Create button in the Segmentation panel'),'The model is missing!','warn')
    return;
end

% tweak, when there is only a single slice in the dataset
if strcmp(layers_id,'4D') && obj.mibModel.I{obj.mibModel.Id}.time == 1
    layers_id = '3D';
end
% tweak, when there is only a single slice in the dataset
if strcmp(layers_id,'3D') && obj.mibModel.I{obj.mibModel.Id}.depth == 1
    layers_id = '2D';
end

if strcmp(layers_id, '2D')
    switch3d = 0;
else
    switch3d = 1;
    wb = waitbar(0,[action_type ' ' obj_type_from ' to/with ' obj_type_to ' for ' layers_id ' layer(s)...'],'Name','Moving layers...','WindowStyle','modal');
end

if strcmp(layers_id, '4D')
    options.t = [1 obj.mibModel.I{obj.mibModel.Id}.time];
elseif strcmp(layers_id, '3D')
    options.t = [obj.mibModel.I{obj.mibModel.Id}.slices{5}(1) obj.mibModel.I{obj.mibModel.Id}.slices{5}(1)];
end

% do backup, not for 4D data
if ~strcmp(layers_id,'4D')
    if obj.mibModel.I{obj.mibModel.Id}.modelType == 63
%         if obj.mibModel.preferences.max3dUndoHistory > 2 || switch3d == 0
%             obj.mibModel.mibDoBackup('everything', switch3d, options);
%         end;
        obj.mibModel.mibDoBackup('everything', switch3d, options);
    else
        obj.mibModel.mibDoBackup(obj_type_to, switch3d, options);
    end
    
end

% The first part is to speed up movement of layers for whole dataset, i.e. without ROI mode and without blockmode switch
if strcmp(layers_id,'4D') || (strcmp(layers_id,'3D') && obj.mibModel.I{obj.mibModel.Id}.time==1) && options.roiId(1) < 0 && options.blockModeSwitch == 0  % to be used only with full datasets, for roi mode and single slices check the procedures below
    options.contSelIndex = contSelIndex; % index of the selected material
    options.contAddIndex = contAddIndex; % index of the target material
    options.selected_sw = selected_sw;   % when 1- limit selection only for the selected material
    options.maskedAreaSw = maskedAreaSw;    % when checked will do add, replace, remove actions only in the masked areas
    
    switch obj_type_from
        case 'mask'
            switch obj_type_to
                case 'selection'
                    obj.mibModel.I{obj.mibModel.Id}.moveMaskToSelectionDataset(action_type, options);     
                case 'model'
                    error('ib_moveLayers: mask->model is not implemented');
                case 'mask'
                    return;
            end
        case 'model'
            switch obj_type_to
                case 'selection'
                    obj.mibModel.I{obj.mibModel.Id}.moveModelToSelectionDataset(action_type, options);    
                case 'mask'
                    obj.mibModel.I{obj.mibModel.Id}.moveModelToMaskDataset(action_type, options);   
                case 'model'
                    return;
            end
        case 'selection'
            switch obj_type_to
                case 'mask'
                    obj.mibModel.I{obj.mibModel.Id}.moveSelectionToMaskDataset(action_type, options);     
                case 'model'
                    obj.mibModel.I{obj.mibModel.Id}.moveSelectionToModelDataset(action_type, options);
                case 'selection'
                    return;
            end
    end
else    % move layers for 2D/3D and ROI and block modes
    if options.blockModeSwitch
        doNotTranspose = 0;
    else
        doNotTranspose = 4;
    end
    switch obj_type_from
        case 'mask'     % select mask layer
            if switch3d
                img = obj.mibModel.getData4D('mask', doNotTranspose, NaN, options);
            else
                img = obj.mibModel.getData2D('mask', NaN, NaN, NaN, options);
            end
        case 'model'      % select obj layer
            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 || obj.mibModel.I{obj.mibModel.Id}.modelType == 128; delete(wb); return; end;     % different model type
            if switch3d
                img = obj.mibModel.getData4D('model', doNotTranspose, contSelIndex, options);
            else
                img = obj.mibModel.getData2D('model', NaN, NaN, contSelIndex, options);
            end
        case 'selection'
            if switch3d
                img = obj.mibModel.getData4D('selection', doNotTranspose, NaN, options);
                obj.mibSelectionClearBtn_Callback('3D');
            else
                img = obj.mibModel.getData2D('selection', NaN, NaN, NaN, options);
                obj.mibSelectionClearBtn_Callback('2D');
            end
    end
    
    % filter results
    if selected_sw && ~strcmp(obj_type_from,'model') && obj.mibModel.I{obj.mibModel.Id}.modelExist && ~strcmp(obj_type_to,'model')
        if switch3d
            sel_img = obj.mibModel.getData4D('model', doNotTranspose, contSelIndex, options);
        else
            sel_img = obj.mibModel.getData2D('model', NaN, NaN, contSelIndex, options);
        end
        for i=1:numel(img)
            img{i} = bitand(img{i}, sel_img{i});    % img{:}(sel_img{:}==0) = 0;
        end
        clear sel_img;
    end
    
    if maskedAreaSw
        if ~strcmp(obj_type_from,'mask') && ~strcmp(obj_type_to,'mask')
            if switch3d
                mask = obj.mibModel.getData4D('mask', doNotTranspose, NaN, options);
            else
                mask = obj.mibModel.getData2D('mask', NaN, NaN, NaN, options);
            end
            
            for i=1:numel(mask)
                img{i} = bitand(img{i}, mask{i});
            end
            clear mask;
        end
    end
    
    if switch3d     %3d mode full dataset
        switch obj_type_to
            case 'selection'
                switch action_type
                    case 'add'
                        selection = obj.mibModel.getData4D('selection', doNotTranspose, NaN, options);
                        for i=1:numel(img)
                            selection{i} = bitor(selection{i}, img{i}); %selection{:}(img{:}==1) = 1;
                        end
                    case 'replace'
                        selection = img;
                    case 'remove'
                        selection = obj.mibModel.getData4D('selection', doNotTranspose, NaN, options);
                        for i=1:numel(img)
                            selection{i} = selection{i} - img{i};  %selection{:}(img{:}==1) = 0;
                        end
                end
                obj.mibModel.setData4D('selection', selection, doNotTranspose, NaN, options);
            case 'mask'
                obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
                if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
                    if isnan(obj.mibModel.I{obj.mibModel.Id}.maskImg{1}(1,1,1,1))
                        obj.mibModel.I{obj.mibModel.Id}.maskImg = zeros([obj.mibModel.I{obj.mibModel.Id}.height,obj.mibModel.I{obj.mibModel.Id}.width,obj.mibModel.I{obj.mibModel.Id}.depth,obj.mibModel.I{obj.mibModel.Id}.time], 'uint8');
                    end;
                end
                switch action_type
                    case 'add'
                        mask = obj.mibModel.getData4D('mask', doNotTranspose, NaN, options);
                        for i=1:numel(mask)
                            mask{i} = bitor(mask{i}, img{i});   % mask{:}(img{:}==1) = 1;
                        end
                    case 'replace'
                        mask = img;
                    case 'remove'
                        mask = obj.mibModel.getData4D('mask', doNotTranspose, NaN, options);
                        for i=1:numel(img)
                            mask{i} = mask{i} - img{i}; % mask{:}(img{:}==1) = 0;
                        end
                end
                obj.mibModel.setData4D('mask', mask, doNotTranspose, NaN, options);
            case 'model'
                if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 || obj.mibModel.I{obj.mibModel.Id}.modelType == 128; delete(wb); return; end;
                model = obj.mibModel.getData4D('model', doNotTranspose, NaN, options);     % %model = getData4D('model', 4, contAddIndex); <- seems to be slower
                obj.mibModel.I{obj.mibModel.Id}.modelExist = 1;
                switch action_type
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
                        if selected_sw
                            for i=1:numel(img)
                                model{i}(bitand(img{i}, model{i}/contSelIndex)==1) = 0; %model{:}(img{:}==1 & model{:} == contSelIndex) = 0;
                            end
                        else
                            for i=1:numel(img)
                                model{i}(img{i}==1) = 0;
                            end
                        end
                end
                obj.mibModel.setData4D('model', model, doNotTranspose, NaN, options);
        end
    else    % 2d mode, the current slice only
        switch obj_type_to
            case 'selection'
                switch action_type
                    case 'add'
                        selection = obj.mibModel.getData2D('selection', NaN, NaN, NaN, options);
                        for i=1:numel(img)
                            selection{i}(img{i}==1) = 1;
                        end
                    case 'replace'
                        selection = img;
                    case 'remove'
                        selection = obj.mibModel.getData2D('selection', NaN, NaN, NaN, options);
                        for i=1:numel(img)
                            selection{i}(img{i}==1) = 0;
                        end
                end
                obj.mibModel.setData2D('selection', selection, NaN, NaN, NaN, options);
            case 'mask'
                obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
                if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
                    if isnan(obj.mibModel.I{obj.mibModel.Id}.maskImg{1}(1,1,1,1))
                        obj.mibModel.I{obj.mibModel.Id}.maskImg{1} = zeros([obj.mibModel.I{obj.mibModel.Id}.height,obj.mibModel.I{obj.mibModel.Id}.width,obj.mibModel.I{obj.mibModel.Id}.depth,obj.mibModel.I{obj.mibModel.Id}.time],'uint8'); 
                    end;
                end
                switch action_type
                    case 'add'
                        mask = obj.mibModel.getData2D('mask', NaN, NaN, NaN, options);
                        for i=1:numel(mask)
                            mask{i} = bitor(mask{i}, img{i});       % mask{:}(img{:}==1) = 1;
                        end
                    case 'replace'
                        mask = img;
                    case 'remove'
                        mask = obj.mibModel.getData2D('mask', NaN, NaN, NaN, options);
                        for i=1:numel(img)
                            mask{i} = mask{i} - img{i}; % mask{:}(img{:}==1) = 0;
                        end
                end
                obj.mibModel.setData2D('mask', mask, NaN, NaN, NaN, options);
            case 'model'
                if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0 || obj.mibModel.I{obj.mibModel.Id}.modelType == 128
                    msgbox(sprintf('No model, or the model of the wrong type.\n\nPress the Create button in the Segmentation panel to start a new model.'),'Problem with model','error');
                    return;
                end
                obj.mibModel.I{obj.mibModel.Id}.modelExist = 1;
                model = obj.mibModel.getData2D('model', NaN, NaN, NaN, options); % model = ib_getSlice('model', handles, NaN, NaN, contAddIndex); <-this option seems to be slower
                switch action_type
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
                        if selected_sw
                            for i=1:numel(img)
                                model{i}(img{i}==1 & model{i} == contSelIndex) = 0;
                            end
                        else
                            for i=1:numel(img)
                                model{i}(img{i}==1) = 0;
                            end
                        end
                end
                obj.mibModel.setData2D('model', model, NaN, NaN, NaN, options);
        end
    end
end
% switch on Model layer
if strcmp(obj_type_to, 'model') 
    obj.mibView.handles.mibModelShowCheck.Value = 1; 
    obj.mibModel.I{obj.mibModel.Id}.modelExist = 1;
    obj.mibModel.mibModelShowCheck = 1;
end
% switch on Mask layer
if strcmp(obj_type_to, 'mask') 
    obj.mibView.handles.mibMaskShowCheck.Value = 1; 
    obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
    obj.mibModel.mibMaskShowCheck = 1;
end
if switch3d; delete(wb); toc(t1); end
obj.plotImage(0);
end