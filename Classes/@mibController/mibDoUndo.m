function mibDoUndo(obj, newIndex)
% function mibDoUndo(obj, newIndex)
% Undo the recent changes with Ctrl+Z shortcut
%
% Parameters:
% newIndex: [@em optional] - index of the dataset to restore, when omitted restore the last stored dataset.
%
% Return values:
%

% Copyright (C) 23.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; newIndex = NaN; end
if isnan(newIndex)  % result of Ctrl+Z combination
    newIndex = obj.mibModel.U.prevUndoIndex;
    newDataIndex = obj.mibModel.U.undoIndex;
else                % when using arrow button in the toolbar
    if newIndex < obj.mibModel.U.undoIndex   % shift left in the undo sequence, i.e. do undo
        newDataIndex = newIndex + 1;
    else            % shift right in the undo sequence, i.e. do redo
        newDataIndex = newIndex - 1;
    end
end

% get the stored dataset
[type, data, meta, storeOptions] = obj.mibModel.U.undo(newIndex);
if ~isfield(storeOptions, 'id'); storeOptions.id = obj.mibModel.Id; end
obj.mibModel.U.prevUndoIndex = newDataIndex;

% get stored info about the new place
[type2, ~, ~, ~] = obj.mibModel.U.undo(newDataIndex);

% delete data in the stored entry
storeOptions.blockModeSwitch=0;
getDataOptions = storeOptions;
obj.mibModel.U.replaceItem(newIndex, NaN, {NaN}, NaN, storeOptions); %index, type, data, meta, options
if obj.mibModel.preferences.max3dUndoHistory <= 1 && storeOptions.switch3d  % tweak for storing a single 3D dataset
    % store the current situation
    dataStore = cell([size(storeOptions.x,1), 1]);
    for roiId = 1:size(storeOptions.x,1)
        getDataOptions.x = storeOptions.x(roiId, :);
        getDataOptions.y = storeOptions.y(roiId, :);
        if strcmp(type, 'image')
            dataStore(roiId) = obj.mibModel.getData3D(type, getDataOptions.t(1), getDataOptions.orient, 0, getDataOptions);
        else
            dataStore(roiId) = obj.mibModel.getData3D(type, getDataOptions.t(1), getDataOptions.orient, NaN, getDataOptions);
        end
    end
    if strcmp(type, 'image')
        storeOptions.viewPort = obj.mibModel.I{storeOptions.id}.viewPort;
        obj.mibModel.U.replaceItem(newDataIndex, type, dataStore, obj.getMeta(), storeOptions);
    else
        obj.mibModel.U.replaceItem(newDataIndex, type, dataStore, NaN, storeOptions);
    end
else
    % store the current situation
    if storeOptions.switch3d    % 3D case
        if strcmp(type, 'image')
            dataStore = cell([size(storeOptions.x,1), 1]);
            for roiId = 1:size(storeOptions.x,1)
                getDataOptions.x = storeOptions.x(roiId, :);
                getDataOptions.y = storeOptions.y(roiId, :);
                dataStore(roiId) = obj.mibModel.getData3D(type, getDataOptions.t(1), getDataOptions.orient, 0, getDataOptions);
            end
            storeOptions.viewPort = obj.mibModel.I{storeOptions.id}.viewPort;
            obj.mibModel.U.replaceItem(newDataIndex, type, dataStore, obj.getMeta(), storeOptions);
        elseif strcmp(type, 'labels')
            [labels.labelText, labels.labelValue, labels.labelPosition] = obj.mibModel.I{storeOptions.id}.hLabels.getLabels();
            obj.mibModel.U.replaceItem(newDataIndex, type, {labels}, NaN, storeOptions);
        elseif strcmp(type, 'measurements')
            obj.mibModel.U.replaceItem(newDataIndex, type, {obj.mibModel.I{storeOptions.id}.hMeasure.Data}, NaN, storeOptions);
        else
            dataStore = cell([size(storeOptions.x,1), 1]);
            for roiId = 1:size(storeOptions.x, 1)
                getDataOptions.x = storeOptions.x(roiId, :);
                getDataOptions.y = storeOptions.y(roiId, :);
                dataStore(roiId) = obj.mibModel.getData3D(type, storeOptions.t(1), getDataOptions.orient, NaN, getDataOptions);
            end
            obj.mibModel.U.replaceItem(newDataIndex, type, dataStore, NaN, storeOptions);
        end
    else        % 2D case
        if strcmp(type, 'image')
            dataStore = cell([size(storeOptions.x, 1), 1]);
            for roiId = 1:size(storeOptions.x, 1)
                getDataOptions.x = storeOptions.x(roiId, :);
                getDataOptions.y = storeOptions.y(roiId, :);
                dataStore(roiId) = obj.mibModel.getData2D(type, storeOptions.z(1), storeOptions.orient, 0, getDataOptions);
            end
            storeOptions.viewPort = obj.mibModel.I{storeOptions.id}.viewPort;
            obj.mibModel.U.replaceItem(newDataIndex, type, dataStore, obj.getMeta(), storeOptions);
        elseif strcmp(type, 'labels')
            [labels.labelText, labels.labelValue, labels.labelPosition] = obj.mibModel.I{storeOptions.id}.hLabels.getLabels();
            obj.mibModel.U.replaceItem(newDataIndex, type, {labels}, NaN, storeOptions);
        elseif strcmp(type, 'lines3d')          
            obj.mibModel.U.replaceItem(newDataIndex, type, {obj.mibModel.I{storeOptions.id}.hLines3D}, NaN, storeOptions);
        elseif strcmp(type, 'measurements')
            obj.mibModel.U.replaceItem(newDataIndex, type, {obj.mibModel.I{storeOptions.id}.hMeasure.Data}, NaN, storeOptions);
        else
            dataStore = cell([size(storeOptions.x, 1), 1]);
            for roiId = 1:size(storeOptions.x, 1)
                getDataOptions.x = storeOptions.x(roiId, :);
                getDataOptions.y = storeOptions.y(roiId, :);
                dataStore(roiId) = obj.mibModel.getData2D(type, storeOptions.z(1), storeOptions.orient, NaN, getDataOptions);
            end
            obj.mibModel.U.replaceItem(newDataIndex, type, dataStore, NaN, storeOptions);
        end
    end
end
obj.mibModel.U.undoIndex = newIndex;
eventdata = ToggleEventData('');    % make empty event data for the notify function at the end

setDataOptions = storeOptions;
if storeOptions.switch3d     % 3D case
    for cellId = 1:numel(data)
        setDataOptions.x = storeOptions.x(cellId, :);
        setDataOptions.y = storeOptions.y(cellId, :);
        switch type
            case 'image'
                obj.mibModel.setData3D('image', data{cellId}, storeOptions.t(1), storeOptions.orient, 0, setDataOptions);
                obj.setMeta(meta);
                obj.mibModel.I{storeOptions.id}.width = meta('Width');
                obj.mibModel.I{storeOptions.id}.height = meta('Height');
                if obj.mibModel.I{storeOptions.id}.colors ~= size(data{1}, 3)    % take care about change of the number of color channels
                    obj.mibModel.I{storeOptions.id}.colors = size(data{1}, 3);
                    obj.mibModel.I{storeOptions.id}.slices{3} = 1:min([size(data{1},3) 3]);
                end
                if isempty(setDataOptions.viewPort)
                    obj.mibModel.I{storeOptions.id}.updateDisplayParameters();
                else
                    obj.mibModel.I{storeOptions.id}.viewPort = getDataOptions.viewPort;
                end
                obj.mibModel.I{storeOptions.id}.depth = meta('Depth');
                obj.mibModel.I{storeOptions.id}.time = meta('Time');
                obj.updateGuiWidgets();
            case 'selection'
                obj.mibModel.setData3D(type, data{cellId}, storeOptions.t(1), storeOptions.orient, NaN, setDataOptions);
            case 'mask'
                obj.mibModel.setData3D(type, data{cellId}, storeOptions.t(1), storeOptions.orient, NaN, setDataOptions);
                obj.mibModel.I{storeOptions.id}.maskExist = 1;
            case 'model'
                obj.mibModel.setData3D(type, data{cellId}, storeOptions.t(1), storeOptions.orient, NaN, setDataOptions);
                obj.mibModel.I{storeOptions.id}.modelExist = 1;
            case 'everything'
                obj.mibModel.setData3D(type, data{cellId}, storeOptions.t(1), storeOptions.orient, NaN, setDataOptions);
            case 'labels'
                data = data{cellId};
                obj.mibModel.I{storeOptions.id}.hLabels.replaceLabels(data.labelText, data.labelPosition, data.labelValue);
                notify(obj.mibModel, 'updatedAnnotations');
            case 'measurements'
                data = data{cellId};
                obj.mibModel.I{storeOptions.id}.hMeasure.Data = data;
        end
    end
else        % 2D case
    for cellId = 1:numel(data)
        setDataOptions.x = storeOptions.x(cellId, :);
        setDataOptions.y = storeOptions.y(cellId, :);
        switch type
            case 'image'
                obj.mibModel.setData2D('image', data{cellId}, storeOptions.z(1), storeOptions.orient, 0, setDataOptions);
                obj.setMeta(meta);
                if isempty(setDataOptions.viewPort)
                    obj.mibModel.I{storeOptions.id}.updateDisplayParameters();
                else
                    obj.mibModel.I{storeOptions.id}.viewPort = getDataOptions.viewPort;
                end
            case 'selection'
                obj.mibModel.setData2D(type, data{cellId}, storeOptions.z(1), storeOptions.orient, NaN, setDataOptions);
            case 'mask'
                obj.mibModel.setData2D(type, data{cellId}, storeOptions.z(1), storeOptions.orient, NaN, setDataOptions);
                obj.mibModel.I{storeOptions.id}.maskExist = 1;
            case 'model'
                obj.mibModel.setData2D(type, data{cellId}, storeOptions.z(1), storeOptions.orient, NaN, setDataOptions);
                obj.mibModel.I{storeOptions.id}.modelExist = 1;
            case 'everything'
                obj.mibModel.setData2D(type, data{cellId}, storeOptions.z(1), storeOptions.orient, NaN, setDataOptions);
            case 'labels'
                data = data{cellId};
                obj.mibModel.I{storeOptions.id}.hLabels.replaceLabels(data.labelText, data.labelPosition, data.labelValue);
                notify(obj.mibModel, 'updatedAnnotations');
            case 'lines3d'
                obj.mibModel.I{storeOptions.id}.hLines3D = copy(data{cellId});
                eventdata = ToggleEventData('lines3d');
            case 'measurements'
                data = data{cellId};
                obj.mibModel.I{storeOptions.id}.hMeasure.Data = data;
        end
    end
end

if isfield(storeOptions, 'maskExist')
    obj.mibModel.I{storeOptions.id}.maskExist = storeOptions.maskExist;
end
if isfield(storeOptions, 'modelExist')
    obj.mibModel.I{storeOptions.id}.modelExist = storeOptions.modelExist;
end


% clear selection layer
if ~strcmp(type, 'selection') && strcmp(type2, 'selection') && newIndex > newDataIndex
    if ~isnan(storeOptions.orient)
        slices = obj.mibModel.I{storeOptions.id}.slices;
        obj.mibModel.I{storeOptions.id}.clearSelection([slices{1}(1), slices{1}(2)],...
                                                       [slices{2}(1), slices{2}(2)],...
                                                       [slices{4}(1), slices{4}(2)],...
                                                       [slices{5}(1), slices{5}(2)]);
    else
        obj.mibModel.I{storeOptions.id}.clearSelection();
    end
end

% tweak to allow better Membrane Click Tracker work after Undo
if size(obj.mibView.trackerYXZ, 2) == 2; obj.mibView.trackerYXZ = obj.mibView.trackerYXZ(:,1); end

% % update the annotation window
% windowId = findall(0,'tag','ib_labelsGui');
% if ~isempty(windowId)
%     hlabelsGui = guidata(windowId);
%     cb = get(hlabelsGui.refreshBtn,'callback');
%     feval(cb, hlabelsGui.refreshBtn, []);
% end
% 
% % update the measurement window
% windowId = findall(0,'tag','mib_measureTool');
% if ~isempty(windowId)
%     hlabelsGui = guidata(windowId);
%     cb = get(hlabelsGui.filterPopup,'callback');
%     feval(cb, hlabelsGui.filterPopup, []);
% end

%sprintf('Undo: Index=%d, numel=%d, max=%d', obj.mibModel.U.undoIndex, numel(obj.mibModel.U.undoList), obj.mibModel.U.max_steps)
obj.plotImage(0);
notify(obj.mibModel, 'undoneBackup', eventdata);

end