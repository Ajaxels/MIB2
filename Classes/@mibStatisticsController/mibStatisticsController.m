classdef mibStatisticsController < handle
    % classdef mibStatisticsController < handle
    % a controller class for the get statistics window available via
    % MIB->Menu->Models->Model statistics
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.

    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        histLimits
        % limits for the histogram
        indices
        % indices of selected entries in the statTable
        listener
        % a cell array with handles to listeners
        intType
        % index of the selected mode for the intensity mode
        obj2DType
        % index of the selected mode for the object mode
        obj3DType     
        % index of the selected mode for the object mode
        runId
        % a vector [datasetId, materialId] for which dataset statistics was calculated
        sel_model    
        % selected material, stored in obj.mibModel.I{obj.mibModel.Id}.selectedMaterial-2;
        selectedProperties
        % list of selected properties to calculate, used to be handles.properties in MIB1
        sorting
        % a variable to keep sorting status for columns
        statProperties
        % list of properties to calculate
        STATS
        % a structure with quantification results
        childControllers
        % list of opened subcontrollers
        childControllersIds
        % a cell array with names of initialized child controllers
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
        %function ViewListner_Callback(obj, varargin)
            switch src.Name
                case 'Id'
                    obj.updateWidgets();
                case 'newDatasetSwitch'
                    % dataset was reloaded
                    if ~isempty(obj.runId)
                        if obj.runId(1) == obj.mibModel.Id
                            obj.STATS = struct;
                            data = cell([1,4]);
                            obj.View.handles.statTable.Data = data;     % clear table contents
                            obj.runId = []; % clear runId 
                            obj.updateWidgets();
                        end
                    end
                    
            end
        end 
        
        function purgeControllers(obj, src, evnt)
            % find index of the child controller
            id = obj.findChildId(class(src));
            
            % delete the child controller
            delete(obj.childControllers{id});
            
            % clear the handle
            obj.childControllers(id) = [];
            obj.childControllersIds(id) = [];
        end
        
    end
    
    methods
        function obj = mibStatisticsController(mibModel, contIndex)
            % obj = mibStatisticsController(mibModel, contIndex)
            % constructor for mibStatisticsController
            % 
            % Parameters:
            % mibModel:     a handle to mibModel
            % contIndex: index of the dataset for statistics (1-mask, 2-Exterior, 3, 4 materials of the model)
            
            if nargin < 2; contIndex = mibModel.I{mibModel.Id}.selectedMaterial-1; end
            
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibStatisticsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % set default parameters
            obj.intType = 1;                % index of the selected mode for the intensity mode
            obj.obj2DType = 1;              % index of the selected mode for the object mode
            obj.obj3DType = 1;              % index of the selected mode for the object mode
            obj.statProperties = {'Area'};  % list of properties to calculate
            obj.sorting = 1;                % a variable to keep sorting status for columns
            obj.indices = [];               % indices for selected rows
            obj.histLimits = [0 1];     % limits for the histogram
            obj.STATS = struct();
            obj.runId = [];
            obj.updateWidgets();
            
            obj.childControllers = {};    % initialize child controllers
            obj.childControllersIds = {};
            
            if contIndex > 1 
                contIndex = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial;
                obj.View.handles.targetPopup.Value = contIndex;
            else
                obj.View.handles.targetPopup.Value = 1;
            end
            
            obj.targetPopup_Callback();
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibStatisticsController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            %fprintf('childController:updateWidgets: %g\n', toc);
            % populate targetPopup
            targetPopupValue = obj.View.handles.targetPopup.Value;
            targetList = {'Mask';'Exterior'};
            if obj.mibModel.getImageProperty('modelExist')
                materials = obj.mibModel.getImageProperty('modelMaterialNames');
                targetList = [targetList; materials];
            end
            obj.View.handles.targetPopup.String = targetList;
            
            if targetPopupValue <= numel(targetList)
                obj.View.handles.targetPopup.Value = targetPopupValue;
            else
                obj.View.handles.targetPopup.Value = 1;
            end
            if ~isempty(obj.runId)
                if obj.runId(1) == obj.mibModel.Id
                    obj.View.handles.targetPopup.Value = obj.runId(2);
                end
            end
            obj.targetPopup_Callback();
            
            % setting color channels popups
            colorChannels = obj.mibModel.getImageProperty('colors');
            colorChannelsList = cell([colorChannels, 1]);
            for i=1:colorChannels
                colorChannelsList{i} = sprintf('Ch %d', i);
            end
            obj.View.handles.firstChannelCombo.String = colorChannelsList;
            obj.View.handles.secondChannelCombo.String = colorChannelsList;
            if numel(colorChannelsList) > 1
                obj.View.handles.secondChannelCombo.Value = 2;
            else
                obj.View.handles.secondChannelCombo.Value = 1;
            end
            % when only one color channel is shown select it
            slices = obj.mibModel.getImageProperty('slices');
            if numel(slices{3}) == 1
                colorChannelSelection = slices{3};
                obj.View.handles.firstChannelCombo.Value = colorChannelSelection;
            else
                obj.View.handles.firstChannelCombo.Value = slices{3}(1);
            end
            
            % update the table
            obj.enableStatTable();
        end
        
        function histScale_Callback(obj)
            % function histScale_Callback(obj)
            % a callback for press of the obj.View.handles.histScale checkbox
            
            if obj.View.handles.histScale.Value
                obj.View.handles.histogram.YScale = 'log';
            else
                obj.View.handles.histogram.YScale = 'linear';
            end
        end
        
        function tableContextMenu_cb(obj, parameter)
            % function tableContextMenu_cb(obj, parameter)
            % a callback to context menu for obj.View.handles.statTable
            %
            % Parameters:
            % parameter: a string that specify parameter for the callback
            % @ 'mean'
            global mibPath;
            
            data = obj.View.handles.statTable.Data;
            if isempty(data); return; end
            if iscell(data(1)); return; end
            if isempty(obj.indices); return; end
            
            switch parameter
                case 'mean'
                    val = mean(data(obj.indices(:,1),2));
                    clipboard('copy', val);
                    msgbox(sprintf('Mean value for the selected (N=%d) objects: %f\n\nThis value was copied to the clipboard.', numel(obj.indices(:,1)), val), 'Mean value', 'help');
                case 'sum'
                    val = sum(data(obj.indices(:,1),2));
                    clipboard('copy', val);
                    msgbox(sprintf('Sum value for the selected (N=%d) objects: %f\n\nThis value was copied to the clipboard.', numel(obj.indices(:,1)), val), 'Mean value', 'help');
                case 'min'
                    val = min(data(obj.indices(:,1),2));
                    clipboard('copy', val);
                    msgbox(sprintf('Minimal value for the selected (N=%d) objects: %f\n\nThis value was copied to the clipboard.', numel(obj.indices(:,1)), val), 'Min value', 'help');
                case 'max'
                    val = max(data(obj.indices(:,1),2));
                    clipboard('copy', val);
                    msgbox(sprintf('Maximal value for the selected (N=%d) objects: %f\n\nThis value was copied to the clipboard.', numel(obj.indices(:,1)), val), 'Max value', 'help');
                case 'crop'     % crop regions to files
                    obj.startController('mibCropObjectsController', obj);
                case 'hist'
                    val = data(obj.indices(:,1),2);
                    nbins = mibInputDlg({mibPath}, sprintf('Enter number of bins for sorting\n(there are %d entries selected):', numel(val)),'Historgam','10');
                    if isempty(nbins); return; end
                    nbins = str2double(nbins{1});
                    if isnan(nbins); errordlg(sprintf('Please enter a number to define number of bins to sort the data!'), 'Error', 'modal'); return; end
                    parList = obj.View.handles.propertyCombo.String;
                    parList = parList{obj.View.handles.propertyCombo.Value};
                    hf = figure(randi(1000));
                    hist(val,nbins);
                    hHist = findobj(gca, 'Type', 'patch');
                    hHist.FaceColor = [0 1 0];
                    hHist.EdgeColor = 'k';
                    lab(1) = xlabel(parList);
                    lab(2) = ylabel('Frequency');
                    [lab(:).FontSize] = deal(12);
                    [lab(:).FontWeight] = deal('bold');
                    
                    [~, figName] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                    hf.Name = figName;
                    grid;
                case {'newLabel', 'addLabel', 'removeLabel'}
                    if strcmp(parameter, 'newLabel')    % clear existing annotations
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();
                    end
                    
                    labelList = cell([numel(obj.indices(:,1)), 1]);
                    positionList = zeros([numel(obj.indices(:,1)), 4]);
                    for rowId = 1:numel(obj.indices(:,1))
                        val = data(obj.indices(rowId,1), 2);
                        objId = data(obj.indices(rowId,1), 1);
                        %labelList(rowId) = {sprintf('%d:%s',  objId, num2str(val))};
                        labelList(rowId) = {sprintf('%s',  num2str(val))};
                        positionList(rowId,:) = [data(obj.indices(rowId,1), 3),  obj.STATS(objId).Centroid(1),  obj.STATS(objId).Centroid(2), data(obj.indices(rowId,1), 4)];
                    end
                    
                    if strcmp(parameter, 'removeLabel')
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(positionList);   % remove labels by position
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelList, positionList);
                    end
                    obj.mibModel.mibShowAnnotationsCheck = 1;
                    
                    notify(obj.mibModel, 'plotImage');
                    
%                     % update the annotation window
%                     windowId = findall(0,'tag','ib_labelsGui');
%                     if ~isempty(windowId)
%                         hlabelsGui = guidata(windowId);
%                         cb = get(hlabelsGui.refreshBtn,'callback');
%                         feval(cb, hlabelsGui.refreshBtn, []);
%                     end
                otherwise
                    obj.statTable_CellSelectionCallback([], parameter);
            end
        end
        
        
        function sortButtonContext_cb(obj, parameter)
            % function sortButtonContext_cb(obj, parameter)
            % a callback for context menu for obj.View.handles.sortBtn
            %
            % Parameters:
            % parameter: a string with sorting choice
            % @li 'object' - sort by object id
            % @li 'value' - sort by object value
            % @li 'slice' - sort by slice number
            % @li 'time' - sort by time point
            
            if strcmp(parameter, 'object')
                colIndex = 1;
            elseif strcmp(parameter, 'value')
                colIndex = 2;
            elseif strcmp(parameter, 'slice')
                colIndex = 3;
            elseif strcmp(parameter, 'time')
                colIndex = 4;
            end
            obj.sortBtn_Callback(colIndex);
        end
        
        function sortBtn_Callback(obj, colIndex)
            % function sortBtn_Callback(obj, colIndex)
            % sort the obj.View.handles.statTable
            %
            % Paremters:
            % colIndex: a number with the index of the column to use for
            % sorting (i.e. 1, 2, 3, or 4)
            
            data = obj.View.handles.statTable.Data;
            if iscell(data); return; end;   % nothing to sort
            if obj.sorting == 1     % ascend sorting
                [data(:,colIndex), index] = sort(data(:,colIndex), 'ascend');
                obj.sorting = 0;
            else
                [data(:,colIndex), index] = sort(data(:,colIndex), 'descend');
                obj.sorting = 1;
            end
            
            if colIndex == 2
                data(:,1) = data(index, 1);
                data(:,3) = data(index, 3);
                data(:,4) = data(index, 4);
            elseif colIndex == 1
                data(:,2) = data(index, 2);
                data(:,3) = data(index, 3);
                data(:,4) = data(index, 4);
            elseif colIndex == 3
                data(:,1) = data(index, 1);
                data(:,2) = data(index, 2);
                data(:,4) = data(index, 4);
            elseif colIndex == 4
                data(:,1) = data(index, 1);
                data(:,2) = data(index, 2);
                data(:,3) = data(index, 3);
            end
            obj.View.handles.statTable.Data = data;
        end
        
        function targetPopup_Callback(obj)
        % function targetPopup_Callback(obj)
        % a callback for obj.View.handles.targetPopup
        
        val = obj.View.handles.targetPopup.Value;
        targetList = obj.View.handles.targetPopup.String;
        obj.View.gui.Name = sprintf('"%s" stats...', targetList{val});
        obj.sel_model = val-2;
        end
        
        function propertyCombo_Callback(obj)
            % function propertyCombo_Callback(obj)
            % a callback for obj.View.handles.propertyCombo
            
            list = obj.View.handles.propertyCombo.String;
            value = obj.View.handles.propertyCombo.Value;
            if strcmp(list{value},'Correlation')
                obj.View.handles.secondChannelCombo.Enable = 'on';
            else
                obj.View.handles.secondChannelCombo.Enable = 'off';
                if strcmp(list{value},'EndpointsLength') || strcmp(list{value},'CurveLengthInUnits') || strcmp(list{value},'CurveLengthInPixels')
                    if obj.View.handles.connectivityCombo.Value == 1
                        msgbox('The connectivity parameter was changed from 4 to 8!','Connectivity changed','warn','modal')
                        obj.View.handles.connectivityCombo.Value = 2;
                    end
                end
                
                if obj.View.handles.objectBasedRadio.Value == 1
                    if obj.View.handles.object2dRadio.Value == 1
                        obj.obj2DType = obj.View.handles.propertyCombo.Value;
                    else
                        obj.obj3DType = obj.View.handles.propertyCombo.Value;
                    end
                else
                    obj.intType = obj.View.handles.propertyCombo.Value;
                end
            end
            selectedProperty = list{value};
            
            if obj.View.handles.multipleCheck.Value
                % update table if possible
                if isfield(obj.STATS, selectedProperty)
                    data = zeros(numel(obj.STATS),4);
                    if numel(data) ~= 0
                        [data(:,2), data(:,1)] = sort(cat(1,obj.STATS.(selectedProperty)), 'descend');
                        for row = 1:size(data,1)
                            pixelId = max([1 floor(numel(obj.STATS(data(row,1)).PixelIdxList)/2)]);  % id of the voxel to get a slice number
                            [~, ~, data(row,3)] = ind2sub([obj.mibModel.getImageProperty('width') obj.mibModel.getImageProperty('height') obj.mibModel.getImageProperty('depth')], ...
                                obj.STATS(data(row,1)).PixelIdxList(pixelId));
                        end
                        data(:, 4) = [obj.STATS(data(:,1)).TimePnt];
                    end
                    obj.View.handles.statTable.Data = data;
                    data = data(:,2);
                    
                    [a,b] = hist(data, 256);
                    bar(obj.View.handles.histogram, b, a);
                    obj.histLimits = [min(b) max(b)];
                    obj.histScale_Callback();
                    grid(obj.View.handles.histogram);
                else
                    data = [];
                    obj.View.handles.statTable.Data = data;
                end
            end
            
            if obj.View.handles.multipleCheck.Value == 0
                obj.selectedProperties = cellstr(selectedProperty);
            end
        end
        
        function radioButton_Callback(obj, hObject)
            % function radioButton_Callback(obj, hObject)
            % a callback for obj.View.handles.radioButton
            %
            % Parameters:
            % hObject: a handle to the object
            
            intensityBasedStats_Sw = obj.View.handles.intensityBasedRadio.Value;
            object2d_Sw = obj.View.handles.object2dRadio.Value;
            if intensityBasedStats_Sw == 1  % intensity based statistics
                list ={'MinIntensity','MaxIntensity','MeanIntensity','StdIntensity','SumIntensity','Correlation'};
                obj.View.handles.firstChannelCombo.Enable = 'on';
                obj.View.handles.propertyCombo.Value = obj.intType;
            else                            % object based statistics
                obj.View.handles.firstChannelCombo.Enable = 'off';
                obj.View.handles.secondChannelCombo.Enable = 'off';
                if object2d_Sw == 1
                    list = {'Area','ConvexArea','CurveLengthInPixels','CurveLengthInUnits','Eccentricity','EndpointsLength','EquivDiameter','EulerNumber',...
                        'Extent','FilledArea','FirstAxisLength','HolesArea','MajorAxisLength','MinorAxisLength','Orientation',...
                        'Perimeter','SecondAxisLength','Solidity'};
                    obj.View.handles.propertyCombo.Value = obj.obj2DType;
                else
                    list ={'Volume','EndpointsLength','EquatorialEccentricity','FilledArea','HolesArea','MajorAxisLength','MeridionalEccentricity','SecondAxisLength','ThirdAxisLength'};
                    obj.View.handles.propertyCombo.Value = obj.obj3DType;
                end
            end
            obj.View.handles.propertyCombo.String = list;
            hObject.Value = 1;
            
            if strcmp(hObject.Tag, 'object2dRadio')
                obj.selectedProperties = {'Area'};  % update handles.properties
                obj.View.handles.multipleCheck.Value = 0;
                obj.View.handles.multipleBtn.Enable = 'off';
            elseif strcmp(hObject.Tag, 'object3dRadio')
                obj.selectedProperties = {'Volume'};  % update handles.properties
                obj.View.handles.multipleCheck.Value = 0;
                obj.View.handles.multipleBtn.Enable = 'off';
            end
            
            if obj.View.handles.multipleCheck.Value == 1
                obj.propertyCombo_Callback();
            end
        end
        
        function highlightSelection(obj, object_list, mode, sliceNumbers)
            % function highlightSelection(obj, object_list, mode)
            % highlight selected objects
            %
            % Parameters:
            % object_list: indices of object to highlight
            % mode: a string
            % 'Add' - add selected objects to the selection layer
            % 'Remove' - remove selected objects from the selection layer
            % 'Replace' - replace the selection layer with selected objects 
            % 'obj2model' - generate a new model, where each selected object will be assigned to own index
            % sliceNumbers: indices of slices for each selected object
            
            if nargin < 4; sliceNumbers = []; end;
            if nargin < 3
                mode = obj.View.handles.detailsPanel.SelectedObject.String;    % what to do with selected objects: Add, Remove, Replace
            end
            
            datasetTypeList = obj.View.handles.datasetPopup.String;
            frame = datasetTypeList{obj.View.handles.datasetPopup.Value};
            mode2 = obj.View.handles.shapePanel.SelectedObject.String;      % 2D/3D objects
            
            getDataOptions.blockModeSwitch = 0;
            [img_height, img_width, ~, img_depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);
            if strcmp(frame, '2D, Slice') && strcmp(mode2, '2D objects') || (strcmp(mode2, '2D objects') && numel(object_list)==1)
                currentSlice = obj.STATS(object_list(1)).Centroid(3);
                currentTime = obj.STATS(object_list(1)).TimePnt;
                getDataOptions.t = [currentTime, currentTime];
                
                selection_mask = zeros(img_height, img_width, 'uint8');
                coef = img_height*img_width*(currentSlice-1); % shift pixel indeces back into 2D space
                for i=1:numel(object_list)
                    selection_mask(obj.STATS(object_list(i)).PixelIdxList-coef) = 1;
                end
                if strcmp(mode,'Add')
                    selection = cell2mat(obj.mibModel.getData2D('selection', currentSlice, NaN, NaN, getDataOptions));
                    selection = bitor(selection_mask, selection);   % selection_mask | selection;
                    obj.mibModel.setData2D('selection', {selection}, currentSlice, NaN, NaN, getDataOptions);
                elseif strcmp(mode,'Remove')
                    curr_selection = cell2mat(obj.mibModel.getData2D('selection', currentSlice, NaN, NaN, getDataOptions));
                    curr_selection(selection_mask==1) = 0;
                    obj.mibModel.setData2D('selection', {curr_selection}, currentSlice, NaN, NaN, getDataOptions);
                elseif strcmp(mode,'Replace')
                    if (strcmp(mode2,'2D objects') && numel(object_list)==1)
                        obj.mibModel.I{obj.mibModel.Id}.clearSelection();
                    end
                    obj.mibModel.setData2D('selection', {selection_mask}, currentSlice, NaN, NaN, getDataOptions);
                end
            else
                wb = waitbar(0,'Highlighting selected objects...','Name','Highlighting');
                timePoints = [obj.STATS(object_list).TimePnt];
                [timePointsUnuque, ~, ic] = unique(timePoints);
                index = 1;
                if strcmp(mode,'Replace'); obj.mibModel.I{obj.mibModel.Id}.clearSelection(); end
                
                if strcmp(mode, 'obj2model')
                    if strcmp(mode2, '2D objects')
                        objDistribution = histcounts(sliceNumbers, max(sliceNumbers));  % number of objects per each slice
                        numberOfObjects = max(objDistribution);
                    else
                        numberOfObjects = numel(object_list);
                    end
                    if numberOfObjects < 64
                        modelType = 63;
                        maskClass = 'uint8';    % define image class for generation of the model
                    elseif numberOfObjects < 256
                        modelType = 255;
                        maskClass = 'uint8';
                    elseif numberOfObjects < 65536
                        modelType = 65535;
                        maskClass = 'uint16';
                    else
                        errordlg('Number of materials exceeds the maximal possible number!', 'Too many objects');
                        return;
                    end
                    obj.mibModel.I{obj.mibModel.Id}.createModel(modelType);
                else
                    maskClass = 'uint8';
                end
                
                for t=timePointsUnuque
                    selection_mask = zeros([img_height, img_width, img_depth], maskClass);
                    objects = object_list(ic==index);
                    if ~strcmp(mode, 'obj2model')
                        objIndex = 1;   % define index of the object to assign in the resulting model
                        shiftValue = 0; % define the shift
                    else
                        if strcmp(mode2, '2D objects')
                            objIndex = zeros([max(sliceNumbers), 1]);   
                            shiftValue = 1;
                        else
                            objIndex = 0;   
                            shiftValue = 1;
                        end
                    end    
                    if strcmp(mode, 'obj2model') && strcmp(mode2, '2D objects')
                        for i=1:numel(objects)
                            [~, ~, subIdZ] = ind2sub([img_height, img_width, img_depth], obj.STATS(objects(i)).PixelIdxList(1));
                            objIndex(subIdZ) = objIndex(subIdZ)+shiftValue; %#ok<AGROW>
                            selection_mask(obj.STATS(objects(i)).PixelIdxList) = objIndex(subIdZ);
                        end
                    else
                        for i=1:numel(objects)
                            objIndex = objIndex+shiftValue;
                            selection_mask(obj.STATS(objects(i)).PixelIdxList) = objIndex;
                        end
                    end
                    
                    if strcmp(mode,'Add')
                        selection = cell2mat(obj.mibModel.getData3D('selection', t, NaN, 0, getDataOptions));
                        obj.mibModel.setData3D('selection', {bitor(selection, selection_mask)}, t, NaN, 0, getDataOptions);    % selection | selection_mask
                    elseif strcmp(mode,'Remove')
                        selection = cell2mat(obj.mibModel.getData3D('selection', t, NaN, 0, getDataOptions));
                        selection(selection_mask==1) = 0;
                        obj.mibModel.setData3D('selection', {selection}, t, NaN, 0, getDataOptions);
                    elseif strcmp(mode,'Replace')
                        obj.mibModel.setData3D('selection', {selection_mask}, t, NaN, 0, getDataOptions);
                    elseif strcmp(mode, 'obj2model')
                        obj.mibModel.setData3D('model', {selection_mask}, t, NaN, NaN, getDataOptions);
                    end
                    index = index + 1;
                    waitbar(index/numel(timePointsUnuque),wb);
                end
                delete(wb);
            end
            
            disp(['MaskStatistics: selected ' num2str(numel(object_list)) ' objects']);
            if strcmp(mode, 'obj2model')
                obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames = strtrim(cellstr(num2str((1:numberOfObjects).')));
                noColors = size(obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors, 1);
                if noColors < numberOfObjects
                    obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors(noColors+1:numberOfObjects,:) = rand(numberOfObjects-noColors, 3);
                end
                notify(obj.mibModel, 'updateId');   % notify to update GUI Widgets
            end
            notify(obj.mibModel, 'plotImage');
        end
        
        function statTable_CellSelectionCallback(obj, indices, parameter)
            % function statTable_CellSelectionCallback(obj, Indices, parameter)
            % a callback for click on cell in obj.View.handles.statTable
            %
            % Parameters:
            % indices:  indices of selected cells
            % parameter: a string with additional parameter,
            % - 'obj2model', generate a new model, where each selected object will be assigned to own index
            % - 'skip' to do not highlight selected objects
            
            if strcmp(parameter, 'obj2model')       % convert selected objects to a new model, where each objects will be assigned to its own material
                answer = questdlg(sprintf('!!! Warning !!!\n\nYou are going to creare a new model, where each of the selected objects gets its own index, i.e. assigned to a new material.\n\nATTENTION!!! The current model will be deleted!'), ...
                    'Convert models', 'Continue','Cancel','Cancel');
                if strcmp(answer, 'Cancel'); return; end
            end
            
            data = obj.View.handles.statTable.Data;
            if isempty(data); return; end
            if iscell(data(1)); return; end
            if strcmp(parameter, 'skip')    % turn off real time update upon selection of cells
                if isempty(indices); return; end
                
                % index of the selected object
                newIndex = NaN;
                if ~isempty(obj.indices)
                    newIndex = find(ismember(indices(:,1), obj.indices(:,1))==0);
                    if size(indices, 1) == 1
                        newIndex = indices(1,:);
                    elseif size(indices, 1) > 1
                        newIndex = indices(newIndex,:);
                    end
                else
                    newIndex = indices(1,:);
                end
                
                obj.indices = indices;
                
                if size(newIndex, 1) == 1 & ~isnan(newIndex)
                    % move image-view to the object
                    objId = data(newIndex(1,1), 1);
                    pixelId = max([1 floor(numel(obj.STATS(objId).PixelIdxList)/2)]);
                    obj.mibModel.I{obj.mibModel.Id}.moveView(obj.STATS(objId).PixelIdxList(pixelId));
                    
                    eventdata = ToggleEventData(data(newIndex(1,1), 3));
                    notify(obj.mibModel, 'updateLayerSlider', eventdata);
                    
                    if obj.mibModel.getImageProperty('time') > 1
                        eventdata = ToggleEventData(data(newIndex(1,1), 4));
                        notify(obj.mibModel, 'updateTimeSlider', eventdata);
                    end
                end
                if obj.View.handles.autoHighlightCheck.Value == 0     % stop here and do not highlight the objects
                    return;
                end
                parameter = obj.View.handles.detailsPanel.SelectedObject.String;
            end
            indices = obj.indices;
            indices = unique(indices(:,1));
            object_list = data(indices,1);
            sliceNumbers = data(indices, 3);
            obj.highlightSelection(object_list, parameter, sliceNumbers);
        end
        
        function mibStatisticsGUI_WindowButtonDownFcn(obj)
            % function mibStatisticsGUI_WindowButtonDownFcn(obj)
            % a callback for a mouse button press over obj.View.gui
            
            xy = obj.View.handles.histogram.CurrentPoint;
            seltype = obj.View.gui.SelectionType;
            ylim = obj.View.handles.histogram.YLim;
            if xy(1,2) > ylim(2); return; end;   % mouse click was too far from the plot
            if xy(1,2) < ylim(1); return; end;   % mouse click was too far from the plot
            
            switch seltype
                case 'normal'       % set the min limit
                    obj.histLimits(1) = xy(1,1);
                case 'alt'          % set the max limit
                    obj.histLimits(2) = xy(1,1);
            end
            obj.histLimits = sort(obj.histLimits);
            
            obj.View.handles.highlight1.String = num2str(obj.histLimits(1));
            obj.View.handles.highlight2.String = num2str(obj.histLimits(2));
            
            data = obj.View.handles.statTable.Data;
            indeces = find(data(:,2) >= obj.histLimits(1) & data(:,2) <= obj.histLimits(2));
            object_list = data(indeces, 1);
            obj.highlightSelection(object_list);
        end
        
        function multipleBtn_Callback(obj)
            % a callback for obj.View.handles.multipleBtn, selecting multiple
            % properties for calculation
            obj3d = 1;
            if obj.View.handles.object2dRadio.Value == 1
                obj3d = 0;
            end
            res = mibMaskStatsProps(obj.selectedProperties, obj3d);
            if ~isempty(res)
                obj.selectedProperties = sort(res);
                customProps = {'CurveLengthInUnits','CurveLengthInPixels','EndpointsLength'};
                if sum(ismember(obj.selectedProperties, customProps)) > 1
                    if obj.View.handles.connectivityCombo.Value == 1
                        msgbox('The connectivity parameter was changed from 4 to 8!','Connectivity changed','warn','modal')
                        obj.View.handles.connectivityCombo.Value = 2;
                    end
                end
                
                list = obj.View.handles.propertyCombo.String;
                index = find(ismember(list, obj.selectedProperties(1))==1);
                if isempty(index)
                    if obj.View.handles.objectBasedRadio.Value == 1    % switch from the object to intensity mode
                        obj.View.handles.intensityBasedRadio.Value = 1;
                    else                                        % switch from the intensity to the object mode
                        obj.View.handles.objectBasedRadio.Value = 1;
                    end
                    obj.radioButton_Callback(obj.View.handles.objectBasedRadio);
                    list = obj.View.handles.propertyCombo.String;
                    index = find(ismember(list, obj.selectedProperties(1))==1);
                else
                    obj.View.handles.propertyCombo.Value = index;
                end
            end
        end
        
        function exportButton_Callback(obj)
            % function exportButton_Callback(obj)
            % a callback for obj.View.handles.exportButton
            
            % export Statistics to Matlab or Excel
            if ~isdeployed
                choice =  questdlg('Would you like to save results?', 'Export', 'Save as...', 'Export to Matlab', 'Cancel', 'Save as...');
                if strcmp(choice,'Cancel')    % cancel
                    return;
                end
            else
                choice = 'Save as...';
            end
            
            datasetTypeList = obj.View.handles.datasetPopup.String;
            OPTIONS.frame = datasetTypeList{obj.View.handles.datasetPopup.Value};
            OPTIONS.mode = obj.View.handles.shapePanel.SelectedObject.String;   % 2d/3d objects
            connectivityValue = obj.View.handles.connectivityCombo.Value;   % if 1: connectivity=4(2d) and 6(3d), if 2: 8(2d)/26(3d)
            connectivityList = obj.View.handles.connectivityCombo.String;   % if 1: connectivity=4(2d) and 6(3d), if 2: 8(2d)/26(3d)
            OPTIONS.connectivity = connectivityList{connectivityValue};   % if 1: connectivity=4(2d) and 6(3d), if 2: 8(2d)/26(3d)
            OPTIONS.colorChannel = obj.View.handles.firstChannelCombo.Value;
            if obj.sel_model == -1
                OPTIONS.type = 'Mask';
            elseif obj.sel_model == 0
                OPTIONS.type = 'Exterior';
            else
                OPTIONS.type = 'Model';
            end
            OPTIONS.filename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            if strcmp(OPTIONS.type, 'Mask')
                OPTIONS.mask_fn = obj.mibModel.getImageProperty('maskImgFilename');
            elseif strcmp(OPTIONS.type, 'Exterior')
                OPTIONS.model_fn = obj.mibModel.getImageProperty('modelFilename');
                OPTIONS.material_id = 'Exterior';
            else
                OPTIONS.model_fn = obj.mibModel.getImageProperty('modelFilename');
                OPTIONS.material_id = sprintf('%d (%s)', obj.sel_model, obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{obj.sel_model});
            end
            
            if strcmp(OPTIONS.frame, '2D, Slice')
                OPTIONS.slicenumber = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
            else
                OPTIONS.slicenumber = 0;
            end
            
            %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
            curInt = get(0, 'DefaulttextInterpreter');
            set(0, 'DefaulttextInterpreter', 'none');
            
            if strcmp(choice, 'Export to Matlab')
                disp('''MIB_stats'' and ''MIB_options'' structures with results have been created in the Matlab workspace');
                assignin('base', 'MIB_options', OPTIONS);
                assignin('base', 'MIB_stats', obj.STATS);
            elseif strcmp(choice, 'Save as...')
                fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
                if isempty(fn_out)
                    fn_out = obj.mibModel.myPath;
                else
                    [fn_out, name, ~] = fileparts(fn_out);
                    fn_out = fullfile(fn_out, [name '_analysis']);
                end
                [filename, path, filterIndex] = uiputfile(...
                    {'*.xls;',  'Excel format (*.xls)'; ...
                    '*.mat;',  'Matlab format (*.mat)'; ...
                    '*.*',  'All Files (*.*)'}, ...
                    'Save as...',fn_out);
                if isequal(filename,0); return; end;
                fn = [path filename];
                wb = waitbar(0,sprintf('%s\nPlease wait...',fn), 'Name', 'Saving the results', 'WindowStyle', 'modal');
                if exist(fn,'file') == 2
                    delete(fn);  % delete exising file
                end
                waitbar(0.2,wb);
                if filterIndex == 2     % save as mat file
                    STATS = obj.STATS; %#ok<NASGU>
                    save(fn, 'OPTIONS','STATS');
                elseif filterIndex == 1     % save as Excel file
                    STATS = obj.STATS;
                    warning off MATLAB:xlswrite:AddSheet
                    % Sheet 1
                    s = {'Quantification Results'};
                    s(2,1) = {['Image filename: ' obj.mibModel.I{obj.mibModel.Id}.meta('Filename')]};
                    if strcmp(OPTIONS.type, 'Model') || strcmp(OPTIONS.type, 'Exterior')
                        s(3,1) = {['Model filename: ' OPTIONS.model_fn]};
                        s(3,9) = {OPTIONS.material_id};
                    else
                        if ~isnan(OPTIONS.mask_fn)
                            s(3,1) = {['Mask filename: ' OPTIONS.mask_fn]};
                        end
                    end
                    pixSize = obj.mibModel.getImageProperty('pixSize');
                    fieldNames = fieldnames(pixSize);
                    s(4,1) = {'Pixel size and units:'};
                    for field=1:numel(fieldNames)
                        s(4,field*2-1+1) = fieldNames(field);
                        s(4,field*2+1) = {pixSize.(fieldNames{field})};
                    end
                    start=8;
                    s(6,1) = {'Results:'};
                    s(7,1) = {'ObjID'};
                    s(7,3) = {'Centroid'};
                    s(8,2) = {'X'};
                    s(8,3) = {'Y'};
                    s(8,4) = {'Z'};
                    s(7,5) = {'TimePnt'};
                    noObj = numel(STATS);
                    s(start+1:start+noObj,1) = num2cell(1:noObj);
                    s(start+1:start+noObj,2:4) = num2cell(cat(1,STATS.Centroid));
                    s(start+1:start+noObj,5) = num2cell(cat(1,STATS.TimePnt));
                    
                    STATS = rmfield(STATS, 'Centroid');
                    STATS = rmfield(STATS, 'PixelIdxList');
                    STATS = rmfield(STATS, 'TimePnt');
                    
                    fieldNames = fieldnames(STATS);
                    s(7,6:5+numel(fieldNames)) = fieldNames;
                    for id=1:numel(fieldNames)
                        s(start+1:start+noObj,5+id) = num2cell(cat(1, STATS.(fieldNames{id})));
                    end
                    
                    %         for field=1:numel(fieldNames)
                    %             if strcmp(fieldNames(field),'data'); continue; end;
                    %             s(6+field-1,3) = fieldNames(field);
                    %             s(6+field-1,4) = {STATS.(fieldNames{field})};
                    %         end
                    %
                    %         s(6+field, 1) = {'Object id'};
                    %         s(6+field, 2) = {[STATS.property ', px']};
                    %         s(6+field+1:6+field+1+size(STATS.data,1), 1:2) = {STATS.data'};
                    %
                    %         for ind = 1:size(STATS.data,1)
                    %             s(6+field+ind, 1) = {STATS.data(ind,1)};
                    %             s(6+field+ind, 2) = {STATS.data(ind,2)};
                    %         end
                    waitbar(0.7,wb);
                    xlswrite2(fn, s, 'Results', 'A1');
                end
                waitbar(1,wb);
                delete(wb);
                disp(['MIB: statistics saved to ' fn]);
            end
            set(0, 'DefaulttextInterpreter', curInt);
            
        end
        
        function runStatAnalysis_Callback(obj)
            % function runStatAnalysis_Callback(obj)
            % start quantification analysis
                        
            contents = obj.View.handles.propertyCombo.String;
            selectedProperty = contents{obj.View.handles.propertyCombo.Value};
            selectedProperty = strtrim(selectedProperty);
            
            if obj.View.handles.multipleCheck.Value == 1
                property = obj.selectedProperties;
                if isempty(property)
                    errordlg(sprintf('!!! Error !!!\n\nYou have selected calculation of multiple properties; but none of them is selected!\nPlease press the Define properties button to make selection'), 'Missing properties');
                    return;
                end
            else
                property = cellstr(selectedProperty);
            end
            datasetTypeList = obj.View.handles.datasetPopup.String;
            frame = datasetTypeList{obj.View.handles.datasetPopup.Value};
            
            mode = obj.View.handles.shapePanel.SelectedObject.String;   % 2d/3d objects
            mode2 = obj.View.handles.modePanel.SelectedObject.String;   % object/intensity stats
            connectivity = obj.View.handles.connectivityCombo.Value;    % if 1: connectivity=4(2d) and 6(3d), if 2: 8(2d)/26(3d)
            colorChannel = obj.View.handles.firstChannelCombo.Value;
            colorChannel2 = obj.View.handles.secondChannelCombo.Value;  % for correlation
            
            selectedMaterial = obj.View.handles.targetPopup.Value-2;  % selected material: -1=Mask; 0=Ext; 1-1st material  ...

            if selectedMaterial >= 0    % model
                if obj.mibModel.getImageProperty('modelExist') == 0
                    errordlg(sprintf('The model is not detected!\n\nPlease create a new model using:\nMenu->Models->New model'),'Missing model');
                    return;
                end
                obj.sel_model = selectedMaterial;    % selected material
                list = obj.mibModel.getImageProperty('modelMaterialNames');
                if selectedMaterial == 0
                    materialName = 'Exterior';
                else
                    materialName = list{obj.sel_model};
                end
                
                if numel(property) == 1
                    wb = waitbar(0,sprintf('Calculating "%s" of %s for %s\nMaterial: "%s"\nPlease wait...',property{1}, mode, frame, materialName),'Name', 'Shape statistics...','WindowStyle','modal');
                else
                    wb = waitbar(0,sprintf('Calculating multiple parameters of %s for %s\nMaterial: "%s"\nPlease wait...', mode, frame, materialName),'Name','Shape statistics...','WindowStyle','modal');
                end
            else    % mask
                if obj.mibModel.getImageProperty('maskExist') == 0
                    errordlg(sprintf('The Mask is not detected!\n\nPlease create a new Mask using:\n1.Draw the mask with Brush\n2. Select Segmentation panel->Add to->Mask\n3. Press the "A" shortcut to add the drawn area to the Mask layer'),'Missing model');
                    return;
                end
                if numel(property) == 1
                    wb = waitbar(0,sprintf('Calculating "%s" of %s for %s\n Material: Mask\nPlease wait...',property{1}, mode, frame),'Name','Shape statistics...','WindowStyle','modal');
                else
                    wb = waitbar(0,sprintf('Calculating multiple parameters of %s for %s\n Material: Mask\nPlease wait...',mode, frame),'Name','Shape statistics...','WindowStyle','modal');
                end
            end
            
            getDataOptions.blockModeSwitch = 0;
            [img_height, img_width, ~, img_depth, img_time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);
            
            t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
            t2 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
            if strcmp(frame, '4D, Dataset')
                t1 = 1;
                t2 = img_time;
            end
            
            property{end+1} = 'PixelIdxList';
            property{end+1} = 'Centroid';
            property{end+1} = 'TimePnt';
            
            obj.STATS = cell2struct(cell(size(property)), property, 2);
            obj.STATS = orderfields(obj.STATS);
            obj.STATS(1) = [];
            
            for t=t1:t2
                if strcmp(mode, '3D objects')
                    if strcmp(frame, '2D, Slice')    % take only objects that are shown in the current slice
                        delete(wb);
                        msgbox(sprintf('CANCELED!\nThe Shown slice with 3D Mode is not implemented!'),'Error!','error','modal');
                        return;
                        %         selection2 = zeros(size(img),'uint8');
                        %         objCounter = 1;
                        %         lay_id = handles.h.Img{handles.h.Id}.I.getCurrentSliceNumber();
                        %
                        %         CC2.Connectivity = CC.Connectivity;
                        %         CC2.ImageSize = CC.ImageSize;
                        %         index1 = img_height*img_width*(lay_id-1);
                        %         index2 = img_height*img_width*(lay_id);
                        %         for obj=1:CC.NumObjects
                        %             if CC.PixelIdxList{1,obj}(1) < index1; continue; end;
                        %             if CC.PixelIdxList{1,obj}(end) > index2; continue; end;
                        %             selection2(CC.PixelIdxList{1,obj}) = 1;
                        %             CC2.PixelIdxList(1,objCounter) = CC.PixelIdxList(1,obj);
                        %             objCounter = objCounter + 1;
                        %         end
                        %         CC2.NumObjects = objCounter - 1;
                        %         CC = CC2;
                    end
                    
                    if connectivity == 1
                        conn = 6;
                    else
                        conn = 26;
                    end
                    
                    getDataOptions.blockModeSwitch = 0;
                    if selectedMaterial == -1
                        img = cell2mat(obj.mibModel.getData3D('mask', t, 4, 0, getDataOptions));
                    else
                        img = cell2mat(obj.mibModel.getData3D('model', t, 4, obj.sel_model, getDataOptions));
                    end
                    
                    intProps = {'SumIntensity', 'StdIntensity', 'MeanIntensity', 'MaxIntensity', 'MinIntensity'};
                    
                    if sum(ismember(property, 'HolesArea')) > 0
                        img = imfill(img, conn, 'holes') - img;
                    end
                    CC = bwconncomp(img,conn);
                    if CC.NumObjects == 0
                        continue;
                    end
                    waitbar(0.05,wb);
                    
                    % calculate common properties
                    STATS = regionprops(CC, {'PixelIdxList', 'Centroid'}); %#ok<*PROP>
                    
                    % calculate matlab standard shape properties
                    prop1 = property(ismember(property, {'FilledArea'}));
                    if ismember('Volume', property)
                        prop1 = [prop1, {'Area'}];
                    end
                    if ~isempty(prop1)
                        STATS2 = regionprops(CC, prop1);
                        fieldNames = fieldnames(STATS2);
                        for i=1:numel(fieldNames)
                            if strcmp(fieldNames{i}, 'Area')
                                [STATS.Volume] = STATS2.(fieldNames{i});
                            else
                                [STATS.(fieldNames{i})] = STATS2.(fieldNames{i});
                            end
                        end
                    end
                    waitbar(0.1,wb);
                    % calculate matlab standard shape properties
                    prop1 = property(ismember(property, 'HolesArea'));
                    if ~isempty(prop1)
                        STATS2 = regionprops(CC, 'Area');
                        [STATS.HolesArea] = STATS2.Area;
                    end
                    waitbar(0.2,wb);
                    % calculate Eccentricity for 3D objects
                    prop1 = property(ismember(property, {'MeridionalEccentricity', 'EquatorialEccentricity'}));
                    if ~isempty(prop1)
                        STATS2 = regionprops3(CC, 'Eccentricity');
                        if sum(ismember(property, 'MeridionalEccentricity')) > 0
                            [STATS.MeridionalEccentricity] = deal(STATS2.MeridionalEccentricity);
                        end
                        if sum(ismember(property,'EquatorialEccentricity')) > 0
                            [STATS.EquatorialEccentricity] = deal(STATS2.EquatorialEccentricity);
                        end
                    end
                    waitbar(0.3,wb);
                    % calculate MajorAxisLength
                    prop1 = property(ismember(property, 'MajorAxisLength'));
                    if ~isempty(prop1)
                        STATS2 = regionprops3(CC, 'MajorAxisLength');
                        [STATS.MajorAxisLength] = deal(STATS2.MajorAxisLength);
                    end
                    waitbar(0.4,wb);
                    % calculate 'SecondAxisLength', 'ThirdAxisLength'
                    prop1 = property(ismember(property, {'SecondAxisLength', 'ThirdAxisLength'}));
                    if ~isempty(prop1)
                        STATS2 = regionprops3(CC, 'AllAxes');
                        if sum(ismember(property,'SecondAxisLength')) > 0
                            [STATS.SecondAxisLength] = deal(STATS2.SecondAxisLength);
                        end
                        if sum(ismember(property,'ThirdAxisLength')) > 0
                            [STATS.ThirdAxisLength] = deal(STATS2.ThirdAxisLength);
                        end
                    end
                    waitbar(0.5,wb);
                    % calculate EndpointsLength for lines
                    prop1 = property(ismember(property, 'EndpointsLength'));
                    if ~isempty(prop1)
                        STATS3 = regionprops(CC, 'PixelList');
                        for obj=1:numel(STATS3)
                            minZ = STATS3(obj).PixelList(1,3);
                            maxZ = STATS3(obj).PixelList(end,3);
                            minPoints = STATS3(obj).PixelList(STATS3(obj).PixelList(:,3)==minZ,:);   % find points on the starting slice
                            minPoints = [minPoints(1,1:2); minPoints(end,1:2)];  % take 1st and last point
                            maxPoints = STATS3(obj).PixelList(STATS3(obj).PixelList(:,3)==maxZ,:);   % find points on the ending slice
                            maxPoints = [maxPoints(1,1:2); maxPoints(end,1:2)];  % take 1st and last point
                            
                            DD = sqrt( bsxfun(@plus,sum(minPoints.^2,2),sum(maxPoints.^2,2)') - 2*(minPoints*maxPoints') );
                            maxVal = max(DD(:));
                            [row, col] = find(DD == maxVal,1);
                            pixSize = obj.mibModel.getImageProperty('pixSize');
                            STATS3(obj).EndpointsLength = sqrt(...
                                ((minPoints(row,1) - maxPoints(col,1))*pixSize.x)^2 + ...
                                ((minPoints(row,2) - maxPoints(col,2))*pixSize.y)^2 + ...
                                ((minZ - maxZ)*pixSize.z)^2 );
                        end
                        [STATS.EndpointsLength] = deal(STATS3.EndpointsLength);
                    end
                    waitbar(0.6,wb);
                    % calculate Intensities
                    prop1 = property(ismember(property, intProps));
                    if ~isempty(prop1)
                        img = squeeze(cell2mat(obj.mibModel.getData3D('image', t, 4, colorChannel, getDataOptions)));
                        STATS2 = regionprops(CC, img, 'PixelValues');
                        if sum(ismember(property, 'MinIntensity')) > 0
                            calcVal = cellfun(@min, struct2cell(STATS2),'UniformOutput', false);
                            [STATS.MinIntensity] = calcVal{:};
                        end
                        if sum(ismember(property, 'MaxIntensity')) > 0
                            calcVal = cellfun(@max, struct2cell(STATS2),'UniformOutput', false);
                            [STATS.MaxIntensity] = calcVal{:};
                        end
                        if sum(ismember(property, 'MeanIntensity')) > 0
                            calcVal = cellfun(@mean, struct2cell(STATS2),'UniformOutput', false);
                            [STATS.MeanIntensity] = calcVal{:};
                        end
                        if sum(ismember(property, 'SumIntensity')) > 0
                            calcVal = cellfun(@sum, struct2cell(STATS2),'UniformOutput', false);
                            [STATS.SumIntensity] = calcVal{:};
                        end
                        if sum(ismember(property, 'StdIntensity')) > 0
                            calcVal = cellfun(@std2, struct2cell(STATS2),'UniformOutput', false);
                            [STATS.StdIntensity] = calcVal{:};
                        end
                    end
                    waitbar(0.8,wb);
                    % calculate correlation between channels
                    prop1 = property(ismember(property, 'Correlation'));
                    if ~isempty(prop1)
                        img = cell2mat(obj.mibModel.getData3D('image', t, 4));
                        img1 = squeeze(img(:,:,colorChannel,:));
                        img2 = squeeze(img(:,:,colorChannel2,:));
                        clear img;
                        for object=1:numel(STATS)
                            STATS(object).Correlation = corr2(img1(STATS(object).PixelIdxList),img2(STATS(object).PixelIdxList));
                        end
                    end
                    [STATS.TimePnt] = deal(t);  % add time points
                    obj.STATS = [obj.STATS orderfields(STATS')];
                    waitbar(0.95,wb);
                else    % 2D objects
                    if connectivity == 1
                        conn = 4;
                    else
                        conn = 8;
                    end
                    
                    % calculate statistics in XY plane
                    orientation = obj.mibModel.getImageProperty('orientation');
                    
                    if strcmp(frame, '2D, Slice')
                        start_id = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                        end_id = start_id;
                    else
                        start_id = 1;
                        end_id = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, orientation);
                    end

                    getDataOptions.t = [t t];
                    getDataOptions.blockModeSwitch = 0;
                    for lay_id=start_id:end_id
                        waitbar((lay_id-start_id)/(end_id-start_id),wb);
                        if selectedMaterial == -1   % mask
                            slice = cell2mat(obj.mibModel.getData2D('mask', lay_id, orientation, NaN, getDataOptions));
                        else
                            slice = cell2mat(obj.mibModel.getData2D('model', lay_id, orientation, obj.sel_model, getDataOptions));
                        end
                        
                        customProps = {'EndpointsLength','CurveLengthInUnits','CurveLengthInPixels','HolesArea'};
                        shapeProps = {'Solidity', 'Perimeter', 'Orientation', 'MinorAxisLength', 'MajorAxisLength', 'FilledArea', 'Extent', 'EulerNumber',...
                            'EquivDiameter', 'Eccentricity', 'ConvexArea', 'Area'};
                        shapeProps3D = {'FirstAxisLength','SecondAxisLength'};     % these properties are calculated by regionprops3
                        intProps = {'SumIntensity','StdIntensity','MeanIntensity','MaxIntensity','MinIntensity'};
                        intCustomProps = 'Correlation';
                        commonProps = {'PixelIdxList', 'Centroid'};
                        
                        % get objects
                        if ~isempty(property(ismember(property,'HolesArea')))     % calculate curve length in units
                            slice = imfill(slice, conn, 'holes') - slice;
                        end
                        CC = bwconncomp(slice,conn);
                        
                        if CC.NumObjects == 0
                            continue;
                        end
                        % calculate common properties
                        STATS = regionprops(CC, commonProps);
                        
                        % calculate matlab standard shape properties
                        prop1 = property(ismember(property,shapeProps));
                        if ~isempty(prop1)
                            STATS2 = regionprops(CC, prop1);
                            fieldNames = fieldnames(STATS2);
                            for i=1:numel(fieldNames)
                                [STATS.(fieldNames{i})] = STATS2.(fieldNames{i});
                            end
                        end
                        
                        % calculate regionprop3 shape properties
                        prop1 = property(ismember(property, shapeProps3D));
                        if ~isempty(prop1)
                            try
                                STATS2 = regionprops3(CC, prop1{:});
                            catch err
                                0
                            end
                            fieldNames = fieldnames(STATS2);
                            for i=1:numel(fieldNames)
                                [STATS.(fieldNames{i})] = STATS2.(fieldNames{i});
                            end
                        end
                        
                        % detects length between the end points of each object, applicable only to lines
                        prop1 = property(ismember(property, 'EndpointsLength'));
                        pixSize = obj.mibModel.getImageProperty('pixSize');
                        if ~isempty(prop1)
                            STATS2 = regionprops(CC, 'PixelList');
                            for obj=1:numel(STATS2)
                                STATS(obj).EndpointsLength = sqrt(((STATS2(obj).PixelList(1,1) - STATS2(obj).PixelList(end,1))*pixSize.x)^2 + ...
                                    ((STATS2(obj).PixelList(1,2) - STATS2(obj).PixelList(end,2))*pixSize.y)^2);
                            end
                            clear STAT2;
                        end
                        % calculate curve length in pixels
                        prop1 = property(ismember(property,'CurveLengthInPixels'));
                        if ~isempty(prop1)
                            STATS2 = mibCalcCurveLength(slice, [], CC);
                            if isstruct(STATS2)
                                [STATS.CurveLengthInPixels] = deal(STATS2.CurveLengthInPixels);
                            end
                        end
                        % calculate curve length in units
                        prop1 = property(ismember(property, 'CurveLengthInUnits'));     % calculate curve length in units
                        if ~isempty(prop1)
                            STATS2 = mibCalcCurveLength(slice, pixSize, CC);
                            if isstruct(STATS2)
                                [STATS.CurveLengthInUnits] = deal(STATS2.CurveLengthInUnits);
                            end
                        end
                        
                        % calculate Holes Area
                        prop1 = property(ismember(property, 'HolesArea'));     % calculate curve length in units
                        if ~isempty(prop1)
                            STATS2 = regionprops(CC, 'Area');
                            [STATS.HolesArea] = deal(STATS2.Area);
                        end
                        
                        % calculate intensity properties
                        prop1 = property(ismember(property, intProps));
                        if ~isempty(prop1)
                            STATS2 = regionprops(CC, cell2mat(obj.mibModel.getData2D('image', lay_id, orientation, colorChannel, getDataOptions)), 'PixelValues');
                            if sum(ismember(property, 'MinIntensity')) > 0
                                calcVal = cellfun(@min, struct2cell(STATS2),'UniformOutput', false);
                                [STATS.MinIntensity] = calcVal{:};
                            end
                            if sum(ismember(property, 'MaxIntensity')) > 0
                                calcVal = cellfun(@max, struct2cell(STATS2),'UniformOutput', false);
                                [STATS.MaxIntensity] = calcVal{:};
                            end
                            if sum(ismember(property, 'MeanIntensity')) > 0
                                calcVal = cellfun(@mean, struct2cell(STATS2),'UniformOutput', false);
                                [STATS.MeanIntensity] = calcVal{:};
                            end
                            if sum(ismember(property, 'SumIntensity')) > 0
                                calcVal = cellfun(@sum, struct2cell(STATS2),'UniformOutput', false);
                                [STATS.SumIntensity] = calcVal{:};
                            end
                            if sum(ismember(property, 'StdIntensity')) > 0
                                calcVal = cellfun(@std2, struct2cell(STATS2),'UniformOutput', false);
                                [STATS.StdIntensity] = calcVal{:};
                            end
                        end
                        % calculate correlation between channels
                        prop1 = property(ismember(property, 'Correlation'));
                        if ~isempty(prop1)
                            img = cell2mat(obj.mibModel.getData2D('image', lay_id, orientation, 0, getDataOptions));
                            img1 = img(:, :, colorChannel);
                            img2 = img(:, :, colorChannel2);
                            for object=1:numel(STATS)
                                STATS(object).Correlation = corr2(img1(STATS(object).PixelIdxList),img2(STATS(object).PixelIdxList));
                            end
                        end
                        
%                         prop1 = property(ismember(property, regprops3Props));
%                         if ~isempty(prop1)
%                             
%                         end
                        
                        
                        if numel(STATS)>0
                            % recalculate pixels' indeces into 3D space
                            STATS = arrayfun(@(s) setfield(s, 'PixelIdxList', s.PixelIdxList+img_height*img_width*(lay_id-1)), STATS);
                            %for obj_id=1:numel(STATS)
                            %    STATS(obj_id).PixelIdxList = STATS(obj_id).PixelIdxList + img_height*img_width*(lay_id-1);
                            %end
                            
                            % add Z-value to the centroid
                            %             Centroids = reshape([STATS.Centroid],[2, numel(STATS)])';
                            %             Centroids(:,3) = lay_id;
                            STATS = arrayfun(@(s) setfield(s,'Centroid',[s.Centroid lay_id]), STATS);
                        end
                        [STATS.TimePnt] = deal(t);  % add time points
                        obj.STATS = [obj.STATS orderfields(STATS')];
                    end
                end
            end
            
            % store information about which dataset was quantified
            obj.runId = [obj.mibModel.Id, selectedMaterial + 2];
            obj.enableStatTable();
            
            tic
            waitbar(.9,wb, sprintf('Reformatting the indices\nPlease wait...'));
            data = zeros(numel(obj.STATS),4);
            if numel(data) ~= 0
                if isfield(obj.STATS, selectedProperty)
                    [data(:,2), data(:,1)] = sort(cat(1, obj.STATS.(selectedProperty)),'descend');
                else
                    [data(:,2), data(:,1)] = sort(cat(1, obj.STATS.(property{1})),'descend');
                end
                dataWidth = obj.mibModel.getImageProperty('width');
                dataHeight = obj.mibModel.getImageProperty('height');
                dataDepth = obj.mibModel.getImageProperty('depth');
                for row = 1:size(data,1)
                    pixelId = max([1 floor(numel(obj.STATS(data(row,1)).PixelIdxList)/2)]);  % id of the voxel to get a slice number
                    [~, ~, data(row,3)] = ind2sub([dataWidth dataHeight dataDepth],...
                        obj.STATS(data(row,1)).PixelIdxList(pixelId));
                end
                data(:,4) = [obj.STATS(data(:,1)).TimePnt]';
            end
            toc
            
            waitbar(1,wb);
            obj.View.handles.statTable.Data = data;
            data = data(:,2);
            
            [a,b] = hist(data, 256);
            bar(obj.View.handles.histogram, b, a);
            obj.histLimits = [min(b) max(b)];
            obj.histScale_Callback();
            grid(obj.View.handles.histogram);
            delete(wb);
        end
        
        function enableStatTable(obj)
            % function enableStatTable(obj)
            % enable/disable the contents of the statTable
            
            obj.View.handles.statTable.Enable = 'off';
            if ~isempty(obj.runId)
                if obj.runId(1) == obj.mibModel.Id
                    obj.View.handles.statTable.Enable = 'on';
                end
            end
        end
        
        function id = findChildId(obj, childName)
            % function id = findChildId(childName)
            % find id of a child controller, see more in mibController.findChildId
            %
            % Parameters:
            % childName: name of a child controller
            %
            % Return values:
            % id: index of the requested child controller or empty if it is not open
            %
            if ismember(childName, obj.childControllersIds) == 0    % not in the list of controllers
                id = [];
            else                % already in the list
                id = find(ismember(obj.childControllersIds, childName)==1);
            end
        end
        
        function startController(obj, controllerName, varargin)
            % function startController(obj, controllerName, varargin)
            % start a child controller using provided name, see more in see more in mibController.startController
            %
            % Parameters:
            % controllerName: a string with name of a child controller, for example, 'mibImageAdjController'
            % varargin: additional optional controllers or parameters
            %
            
            id = obj.findChildId(controllerName);        % define/find index for this child controller window
            if ~isempty(id); return; end;   % return if controller is already opened
            
            % assign id and populate obj.childControllersIds for a new controller
            id = numel(obj.childControllersIds) + 1;
            obj.childControllersIds{id} = controllerName;
            
            fh = str2func(controllerName);               %  Construct function handle from character vector
            if nargin > 2
                obj.childControllers{id} = fh(obj.mibModel, varargin{1:numel(varargin)});    % initialize child controller with additional parameters
            else
                obj.childControllers{id} = fh(obj.mibModel);    % initialize child controller
            end
            % add listener to the closeEvent of the child controller
            addlistener(obj.childControllers{id}, 'closeEvent', @(src,evnt) mibStatisticsController.purgeControllers(obj, src, evnt));   % static
        end
        
    end
end



