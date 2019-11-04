classdef mibAnnotationsController < handle
    % classdef mibAnnotationsController < handle
    % a controller class for the list of annotations available via
    % MIB->Menu->Models->Annotations->List of annotations
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    % Updates
    % 28.02.2018, IB, updated to be compatible with values
    % 22.05.2019, IB added batch modification of values via right mouse button menu
    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        imarisOptions
        % a structure with export options for imaris
        % .radii - number with default radius
        % .color - default color [Red Green Blue Alpha] in range from 0 to 1;
        % .name - default name
        indices
        % indices of selected annotations in the table
        jScroll
        % java handle to the scroll bar of obj.View.handles.annotationTable
        jTable
        % java handle to the obj.View.handles.annotationTable
        batchModifyExpression
        % expression to use with the batch modify mode
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updatedAnnotations', 'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibAnnotationsController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibAnnotationsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.imarisOptions.radii = NaN;
            obj.imarisOptions.color = [1 0 0 0];
            obj.imarisOptions.name = 'mibSpots';
            
            % find java object for the segmentation table
            obj.jScroll = findjobj(obj.View.handles.annotationTable);
            obj.jTable = obj.jScroll.getViewport.getComponent(0);
            obj.jTable.setAutoResizeMode(obj.jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
                        
            obj.mibModel.mibShowAnnotationsCheck = 1;
            obj.View.handles.precisionEdit.String = num2str(obj.mibModel.mibAnnValuePrecision);
            obj.batchModifyExpression = 'A=A*2';
            obj.updateWidgets();
            
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'updatedAnnotations', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));   % listen for updated annotations
        end
        
        function closeWindow(obj)
            % closing mibAnnotationsController window
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
            % update annotation table
            numberOfLabels = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber();
            
            precision = str2double(obj.View.handles.precisionEdit.String);
            
            if numberOfLabels >= 1
                [labelsText, labelsVal, labelsPos, labelIndices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
                data = cell([numel(labelsText), 5]);
                data(:,1) = labelsText';
                modString = sprintf('%c.%df', '%', precision);
                data(:,2) = arrayfun(@(x) sprintf(modString, x), labelsVal, 'UniformOutput', 0); 
                data(:,3) = arrayfun(@(x) sprintf('%.2f',x), labelsPos(:,1), 'UniformOutput', 0);
                data(:,4) = arrayfun(@(x) sprintf('%.2f',x), labelsPos(:,2), 'UniformOutput', 0);
                data(:,5) = arrayfun(@(x) sprintf('%.2f',x), labelsPos(:,3), 'UniformOutput', 0);
                data(:,6) = arrayfun(@(x) sprintf('%d',x), labelsPos(:,4), 'UniformOutput', 0);
                obj.View.handles.annotationTable.Data = data;
                obj.View.handles.annotationTable.RowName = labelIndices;
            else
                data = cell([6, 1]);
                obj.View.handles.annotationTable.Data = data;
            end
            for colId=0:5
                hCol = obj.jTable.getColumnModel().getColumn(colId);
                if colId == 0
                    hCol.setPreferredWidth(80);
                elseif colId == 1
                    hCol.setPreferredWidth(50);
                else
                    hCol.setPreferredWidth(30);
                end
            end
            
        end
        
        function loadBtn_Callback(obj)
            % function loadBtn_Callback(obj)
            % load annotation from a file or import from Matlab
            button =  questdlg(sprintf('Would you like to import annotations from a file or from the main Matlab workspace?'),'Import/Load annotations','Load from a file','Import from Matlab','Cancel','Load from a file');
            switch button
                case 'Cancel'
                    return;
                case 'Import from Matlab'
                    % get list of available variables
                    availableVars = evalin('base', 'whos');
                    % find only the cell type, because labelsList is array of cells
                    idx = ismember({availableVars.class}, 'struct');
                    
                    labelsList = {availableVars(idx).name}';
                    idx = find(ismember(labelsList, 'Labels')==1);
                    if ~isempty(idx)
                        labelsList{end+1} = idx;
                    end
                    
                    title = 'Input annotations';
                    defAns = {labelsList};
                    prompts = {'Structure name with annotations:'};
                    answer = mibInputMultiDlg([], prompts, defAns, title);
                    if isempty(answer); return; end
                    
                    try
                        Labels = evalin('base', answer{1});
                    catch err
                        errordlg(sprintf('!!! Error !!!\n\n%s', err.message), ...
                            'Wrong variable');
                        return;
                    end
                    if ~isfield(Labels, 'Text')
                        errordlg(sprintf('Wrong structure type!\n\nThe structure should contain the following fields:\nText - cell array with labels\nValues - an array of numbers [optional]\nPositions - a matrix with coordinates [pointIndex, z  x  y  t]'), 'Wrong structure');
                        return;
                    end
                    obj.mibModel.mibDoBackup('labels', 0);
                    
                    if ~isfield(Labels, 'Values')
                        Labels.Values = zeros([numel(Labels.Text), 1]) + 1;
                    end
                    
                    if size(Labels.Positions, 2) == 3  % missing the t
                        Labels.Positions(:, 4) = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                    end
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(Labels.Text, Labels.Positions, Labels.Values);
                case 'Load from a file'
                    [filename, path] = uigetfile(...
                        {'*.ann;',  'Matlab format (*.ann)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Load annotations...', obj.mibModel.myPath);
                    if isequal(filename, 0); return; end % check for cancel
                    
                    obj.mibModel.mibDoBackup('labels', 0);
                    res = load(fullfile(path, filename), '-mat');
                    if isfield(res, 'labelsList')   % old format for saving annotations
                        res.labelText = res.labelsList;
                        res = rmfield(res, 'labelsList');
                    end
                    if isfield(res, 'labelValues')     % old variable for values of annotations
                        res.labelValue = res.labelValues;
                        res = rmfield(res, 'labelValues');
                    end
                    if isfield(res, 'labelPositions')     % old variable for values of annotations
                        res.labelPosition = res.labelPositions;
                        res = rmfield(res, 'labelPositions');
                    end
                    
                    if ~isfield(res, 'labelValue')     % old variable for values of annotations
                        res.labelValue = zeros([numel(res.labelText), 1]) + 1;
                    end
                    
                    if size(res.labelPosition,2) == 3  % missing the t
                        res.labelPosition(:, 4) = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                    end
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(res.labelText, res.labelPosition, res.labelValue);
            end
            obj.updateWidgets();
            
            % alternative way to call plot image, via notify listener
            eventdata = ToggleEventData(0);
            notify(obj.mibModel, 'plotImage', eventdata);
            disp('Import annotations: done!')
        end
        
        function saveBtn_Callback(obj)
            % function saveBtn_Callback(obj)
            % save annotations to a file or export to Matlab
            global mibPath;
            
            [labelText, labelValue, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
            if numel(labelText) == 0; return; end
            
            % rearrange into a structure
            Labels.Text = labelText;
            Labels.Values = labelValue;
            Labels.Positions = labelPosition;
            
            button =  questdlg(sprintf('Would you like to save annotations to a file or export to the main Matlab workspace?'),'Export/Save annotations','Save to a file','Export to Matlab','Cancel','Save to a file');
            if strcmp(button, 'Cancel'); return; end
            if strcmp(button, 'Export to Matlab')
                answer=mibInputDlg({mibPath}, sprintf('Please enter name for the structures with labels:'), ...
                    'Export to Matlab', 'Labels');
                if isempty(answer); return; end
                
                assignin('base', answer{1}, Labels);
                fprintf('Export annotations: structure ''%s'' with fields .Text, .Values, .Positions was exported to Matlab!\n', answer{1});
            else
                obj.saveAnnotationsToFile(labelText, labelPosition, labelValue);
            end
        end
        
        function saveAnnotationsToFile(obj, labelText, labelPosition, labelValue)
            % function saveAnnotationsToFile(obj, labelText, labelPosition, labelValue)
            % save annotations to a file
            %
            % Parameters:
            % labelText: labels of annotations, cell array
            % labelPosition: a matrix with coordinates for the annotations
            % labelValue: an array with annotation values
            
            fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            dotIndex = strfind(fn_out,'.');
            if ~isempty(dotIndex)
                fn_out = [fn_out(1:dotIndex-1) '_Ann'];
            end
            if isempty(strfind(fn_out,'/')) && isempty(strfind(fn_out,'\')) %#ok<STREMP>
                fn_out = fullfile(obj.mibModel.myPath, fn_out);
            end
            if isempty(fn_out)
                fn_out = obj.mibModel.myPath;
            end
            
            Filters = {'*.ann;',  'Matlab format (*.ann)';...
                       '*.csv',   'Comma-separated value (*.csv)';...
                       '*.landmarksAscii',   'Amira landmarks ASCII (*.landmarksAscii)';...
                       '*.landmarksBin',   'Amira landmarks BINARY(*.landmarksBin)';...
                       '*.psi',   'PSI format ASCII(*.psi)';...
                       '*.xls',   'Excel format (*.xls)'; };
            
            [filename, path, FilterIndex] = uiputfile(Filters, 'Save annotations...',fn_out); %...
            if isequal(filename,0); return; end % check for cancel
            fn_out = fullfile(path, filename);
            
            switch Filters{FilterIndex,2}
                case 'Matlab format (*.ann)'   % matlab format
                    options.format = 'ann';
                case 'Comma-separated value (*.csv)'    % csv format
                    options.format = 'csv';
                case 'Excel format (*.xls)'    % excel format
                    options.format = 'xls';
                case 'PSI format ASCII(*.psi)'    % PSI format, compatible with Amira
                    recalcCoordinates = questdlg(sprintf('Recalculate annotations with respect to the current bounding box or save as they are?'),...
                        'Recalculate coordinates', 'Recalculate', 'Save as they are', 'Recalculate');
                    options.format = 'psi';
                    if strcmp(recalcCoordinates, 'Recalculate')
                        options.convertToUnits = true;
                        options.boundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                        options.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
                    end
                otherwise    % landmarks for Amira
                    button = questdlg(sprintf('!!! Warning !!!\n\nWhen exporting points as landmarks for Amira only positions of the annotations are saved!\n\nIf you want to keep labels and values, please use the Amira compatible PSI format!'),...
                        'Export to Amira', 'Continue', 'Cancel', 'Cancel');
                    if strcmp(button, 'Cancel'); return; end
                
                    recalcCoordinates = questdlg(sprintf('Recalculate annotations with respect to the current bounding box or save as they are?'),...
                        'Recalculate coordinates', 'Recalculate', 'Save as they are', 'Recalculate');
                
                    if strcmp(Filters{FilterIndex+numel(Filters)/2}, 'Amira landmarks ASCII (*.landmarksAscii)')
                        options.format = 'landmarksAscii';
                    else
                        options.format = 'landmarksBin';
                    end
                    if strcmp(recalcCoordinates, 'Recalculate')
                        options.convertToUnits = true;
                    end
            end
            options.boundingBox = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            options.pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            
            options.labelText = labelText;
            options.labelPosition = labelPosition;
            options.labelValue = labelValue;
            obj.mibModel.I{obj.mibModel.Id}.hLabels.saveToFile(fn_out, options);
        end
        
        function deleteBtn_Callback(obj)
            % function deleteBtn_Callback(obj)
            % delete all annotations
            obj.mibModel.mibDoBackup('labels', 0);
            obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels();
            % alternative way to call plot image, via notify listener
            eventdata = ToggleEventData(0);
            notify(obj.mibModel, 'plotImage', eventdata);
            obj.updateWidgets();
        end
        
        function annotationTable_CellSelectionCallback(obj, Indices)
            % function annotationTable_CellSelectionCallback(obj, Indices)
            % a callback for cell selection of obj.View.handles.annotationTable
            %
            % Parameters:
            % Indices: index of the selected cell, returned by
            % eventdata.Indices structure of GUI
            
            obj.indices = Indices;
            if obj.View.handles.jumpCheck.Value == 1  % jump to the selected annotation
                obj.tableContextMenu_cb('Jump')
            end
        end
        
        function annotationTable_CellEditCallback(obj, Indices)
            % function annotationTable_CellEditCallback(obj, Indices)
            % a callback for cell edit of obj.View.handles.annotationTable
            %
            % Parameters:
            % Indices: index of the selected cell, returned by
            % eventdata.Indices structure of GUI
            
            data = obj.View.handles.annotationTable.Data;    % get table contents
            rowIndices = obj.View.handles.annotationTable.RowName;  % get row names, that are indices for the labels.
            rowId = Indices(1);
            obj.mibModel.mibDoBackup('labels', 0);
            
            newLabelText = data(rowId, 1);
            newLabelValue = str2double(data{rowId, 2});
            newLabelPos(1) = str2double(data{rowId, 3});
            newLabelPos(2) = str2double(data{rowId, 4});
            newLabelPos(3) = str2double(data{rowId, 5});
            newLabelPos(4) = str2double(data{rowId, 6});
            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(str2double(rowIndices(rowId,:)), newLabelText, newLabelPos, newLabelValue);
            notify(obj.mibModel, 'plotImage');  % notify to plot the image
        end
        
        function precisionEdit_Callback(obj)
            % function precisionEdit_Callback(obj)
            % callback for modification of the precision parameter for the
            % annotation values
            result = editbox_Callback(obj.View.handles.precisionEdit, 'pint', '0', [0, NaN]);
            if result == 0; return; end
            obj.mibModel.mibAnnValuePrecision = str2double(obj.View.handles.precisionEdit.String);
            obj.updateWidgets();
            notify(obj.mibModel, 'plotImage');  % notify to plot the image
        end
        
        function tableContextMenu_cb(obj, parameter)
            % function tableContextMenu_cb(obj, parameter)
            % callbacks for the context menu of obj.View.handles.annotationTable
            %
            % Parameters:
            % parameter: a string with selected option
            % ''Add'' - add annotations
            % ''Modify'' - batch modify selected annotations
            % ''Rename'' - rename selected annotations
            % ''Jump'' - jump to the selected annotation
            % ''Count'' - count annotations
            % ''Clipboard'' - copy selected annotations to the system clipboard
            % ''Export'' - export/save annotations to matlab or to a file
            % ''Imaris'' - export annotations to Imaris
            % ''Delete'' - delete selected annotations
            
            global mibPath;
            orientation = obj.mibModel.getImageProperty('orientation');
            
            switch parameter
                case 'Add'  % add annotation
                    prompt={'Annotation text','Annotation value',...
                        sprintf('Z coordinate (Zmax=%d):', obj.mibModel.getImageProperty('depth'))...
                        sprintf('X coordinate (Xmax=%d):', obj.mibModel.getImageProperty('width'))...
                        sprintf('Y coordinate (Ymax=%d):', obj.mibModel.getImageProperty('height'))...
                        sprintf('T coordinate (Tmax=%d)', obj.mibModel.getImageProperty('time'))};
                    slices = obj.mibModel.getImageProperty('slices');
                    zVal = num2str(slices{orientation}(1));
                    tVal = num2str(slices{5}(1));
                    defaultAnnotationName = obj.mibModel.getImageProperty('defaultAnnotationText');
                    defaultAnnotationValue = obj.mibModel.getImageProperty('defaultAnnotationValue');
                    defAns={defaultAnnotationName, defaultAnnotationValue, zVal, '10', '10', tVal};
                    
                    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Add annotation');
                    if isempty(answer); return; end

                    obj.mibModel.mibDoBackup('labels', 0);
                    labelsText = answer(1);
                    obj.mibModel.setImageProperty('defaultAnnotationText', labelsText{1});
                    labelsValue = str2double(answer(2));
                    obj.mibModel.setImageProperty('defaultAnnotationValue', labelsValue);
                    
                    labelsPosition(1) = str2double(answer{3});
                    labelsPosition(2) = str2double(answer{4});
                    labelsPosition(3) = str2double(answer{5});
                    labelsPosition(4) = str2double(answer{6});
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelsText, labelsPosition, labelsValue);
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Modify'   % batch modify selected annotations
                    if isempty(obj.indices); return; end
                    inputDlgOptions.Title = sprintf('Input an arithmetic operation to modify the annotations\nFor example,\n   "A=A*2" - multiply each value by 2;\n   "A=round(A)" - rounds each value,\n   where A denotes each selected cell');
                    inputDlgOptions.TitleLines = 5;
                    inputDlgOptions.WindowWidth = 1.2;
                    prompt = {'Expression:'};
                    defAns = {obj.batchModifyExpression};
                    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Batch modify', inputDlgOptions);
                    if isempty(answer); return; end
                    currExpression = [answer{1} ';'];
                    [labelsList, labelValues, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
                    
                    for colId = 1:6
                        idx = find(obj.indices(:,2) == colId); %#ok<EFIND>
                        if isempty(idx); continue; end
                        switch colId
                            case 1
                                errordlg(sprintf('!!! Error !!!\nModification of the label names using this function is not yet implemented...'), 'Not implemented');
                                return;
                            case 2
                                A = labelValues(obj.indices(idx,1)); %#ok<NASGU>
                                try
                                    eval(currExpression);
                                catch err
                                    errordlg(sprintf('Wrong expression!\n\n%s\n%s', err.message, err.identifier), 'Wrong expression');
                                    return;
                                end
                                labelValues(obj.indices(idx,1)) = A;
                            otherwise
                                A = labelPositions(obj.indices(idx,1), colId-2); %#ok<NASGU>
                                try
                                    eval(currExpression);
                                catch err
                                    errordlg(sprintf('Wrong expression!\n\n%s\n%s', err.message, err.identifier), 'Wrong expression');
                                    return;
                                end
                                labelPositions(obj.indices(idx,1), colId-2) = A;
                        end
                    end
                    obj.mibModel.mibDoBackup('labels', 0);
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();    % remove current labels
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelsList, labelPositions, labelValues);     % add updated labels
                    obj.batchModifyExpression = currExpression(1:end-1);
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Rename'
                    if isempty(obj.indices); return; end
                    rowId = obj.indices(:, 1);
                    
                    currentName = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(rowId(1));
                    if isempty(currentName); return; end
                    
                    answer = mibInputDlg([], 'New name for the selected annotations:', ...
                        'Rename', currentName{1});
                    if isempty(answer); return; end
                    
                    obj.mibModel.mibDoBackup('labels', 0);
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.renameLabels(rowId, answer(1)); 
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Jump'     % jump to the highlighted annotation
                    if isempty(obj.indices); return; end
                    if isempty(obj.View.handles.annotationTable.Data); return; end
                    
                    rowId = obj.indices(1);
                    getDim.blockModeSwitch = 0;
                    [imgH, imgW, ~, imgZ] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image',NaN,NaN,getDim);
                    if orientation == 4   % xy
                        z = str2double(obj.View.handles.annotationTable.Data{rowId, 3});
                        x = str2double(obj.View.handles.annotationTable.Data{rowId, 4});
                        y = str2double(obj.View.handles.annotationTable.Data{rowId, 5});
                    elseif orientation == 1   % zx
                        z = str2double(obj.View.handles.annotationTable.Data{rowId, 5});
                        x = str2double(obj.View.handles.annotationTable.Data{rowId, 3});
                        y = str2double(obj.View.handles.annotationTable.Data{rowId, 4});
                    elseif orientation == 2   % zy
                        z = str2double(obj.View.handles.annotationTable.Data{rowId, 4});
                        x = str2double(obj.View.handles.annotationTable.Data{rowId, 3});
                        y = str2double(obj.View.handles.annotationTable.Data{rowId, 5});
                    end
                    t = str2double(obj.View.handles.annotationTable.Data{rowId, 6});
                    % do not jump when the label out of image boundaries
                    if x>imgW || y>imgH || z>imgZ
                        warndlg('The annotation is outside of the image boundaries!', 'Wrong coordinates');
                        return;
                    end
                    
                    % move image-view to the object
                    obj.mibModel.I{obj.mibModel.Id}.moveView(x, y);
                    
                    % change t
                    if obj.mibModel.getImageProperty('time') > 1
                        eventdata = ToggleEventData(round(t));
                        notify(obj.mibModel, 'updateTimeSlider', eventdata);
                    end
                    % change z
                    if obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(orientation) > 1 %size(obj.mibModel.I{obj.mibModel.Id}.img{1}, orientation) > 1
                        eventdata = ToggleEventData(round(z));
                        notify(obj.mibModel, 'updateLayerSlider', eventdata);
                    else
                        notify(obj.mibModel, 'plotImage');
                    end
                case 'Count'    % count selected annotations
                    if isempty(obj.indices); return; end
                    data = obj.View.handles.annotationTable.Data;
                    if isempty(data); return; end
                    
                    annIds = unique(obj.indices(:,1));
                    labelsList = data(annIds,1);
                    labelsList = strtrim(labelsList);   % remove the blank spaces
                    labelsValues = cellfun(@(a) str2double(a), data(annIds,2));
                    totalValues = sum(labelsValues);
                    uniqLabels = unique(labelsList);
                    
                    output = sprintf('----------------------------------------------------------:\n');
                    output = [output sprintf('Counting annotations:\n')];
                    output = [output sprintf('Total number of selected annotation categories: %d\n', numel(annIds))];
                    output = [output sprintf('Total number of selected annotation values: %f\n', totalValues)];
                    for labelId=1:numel(uniqLabels)
                        posIds = ismember(labelsList, uniqLabels(labelId));
                        Occurrence = sum(labelsValues(posIds));
                        output = [output sprintf('%s: %f (%.3f percent)\n', uniqLabels{labelId}, Occurrence, Occurrence/totalValues*100)]; %#ok<AGROW>
                    end
                    fprintf(output);
                    clipboard('copy', output);
                    msgbox(sprintf('The annotation counts were printed to the Matlab command window and copied to the system clipboard\nYou can paste results using the Ctrl+V key shortcut'), 'Counting annotations');
                case 'Clipboard'
                    if isempty(obj.indices); return; end
                    
                    data = obj.View.handles.annotationTable.Data;
                    d = data(unique(obj.indices(:,1)), min(obj.indices(:,2)):max(obj.indices(:,2)));
                    cell2clip(d);    % copy to clipboard
                    fprintf('Annotations: %d rows were copied to the system clipboard\n', size(d, 2));
                case 'Export'
                    if isempty(obj.indices); return; end
                    
                    labelText = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelText(obj.indices(:,1));
                    labelValue = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelValue(obj.indices(:,1));
                    labelPosition = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelPosition(obj.indices(:,1), :);
                    obj.saveAnnotationsToFile(labelText, labelPosition, labelValue);

                case 'Imaris' % export annotations to Imaris
                    if isempty(obj.indices); return; end
                    data = obj.View.handles.annotationTable.Data;
                    if isempty(data); return; end
                    annIds = obj.indices(:,1);
                    
                    labelText = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelText(annIds);
                    labelValue = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelValue(annIds);

                    labelPosition = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelPosition(annIds, :);  % [z, x, y, t];
                    %labelPosition = data(annIds,2:5);
                    %labelPosition = cellfun(@str2double, labelPosition);  % generate a matrix [z, x, y, t];
                    labelPosition = [labelPosition(:,2), labelPosition(:,3), labelPosition(:,1), labelPosition(:,4)];   % reshape to [x, y, z, t]
                    
                    % recalculate position in respect to the bounding box
                    bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                    pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
                    labelPosition(:, 1) = labelPosition(:, 1)*pixSize.x + bb(1) - pixSize.x/2;
                    labelPosition(:, 2) = labelPosition(:, 2)*pixSize.y + bb(3) - pixSize.y/2;
                    labelPosition(:, 3) = labelPosition(:, 3)*pixSize.z + bb(5) - pixSize.z;
                    
                    if isnan(obj.imarisOptions.radii)
                        obj.imarisOptions.radii = (max(labelPosition(:, 1))-min(labelPosition(:, 1)))/50/max(labelValue);
                    end
                    prompt = {'Radius scaling factor for spots:', sprintf('Color [R, G, B, A]\nrange from 0 to 1'), 'Name for spots:'};
                    defAns = {num2str(obj.imarisOptions.radii), num2str(obj.imarisOptions.color), labelText{1}};
                    
                    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Export to Imaris');
                    if isempty(answer); return; end
                    
                    obj.imarisOptions.radii = str2double(answer{1});
                    obj.imarisOptions.color = str2num(answer{2}); %#ok<ST2NM>
                    obj.imarisOptions.name = answer{3};
                    
                    options.radii = labelValue * obj.imarisOptions.radii;
                    options.color = obj.imarisOptions.color;
                    options.name = obj.imarisOptions.name;
                    obj.mibModel.connImaris = mibSetImarisSpots(labelPosition, obj.mibModel.connImaris, options);
                    
                case 'Delete'   % delete the highlighted annotation
                    if isempty(obj.indices); return; end
                    data = obj.View.handles.annotationTable.Data;
                    if isempty(data); return; end
                    
                    rowId = obj.indices(:, 1);
                    if numel(rowId) == 1
                        button =  questdlg(sprintf('Delete the following annotation?\n\nLabel: %s\n\nCoordinates (z,x,y,t): %s %s %s %s', data{rowId,1},data{rowId,2},data{rowId,3},data{rowId,4},data{rowId,5}),'Delete annotation','Delete','Cancel','Cancel');
                    else
                        button =  questdlg(sprintf('Delete the multiple annotations?'),'Delete annotation','Delete','Cancel','Cancel');
                    end
                    if strcmp(button, 'Cancel'); return; end
                    
                    obj.mibModel.mibDoBackup('labels', 0);
                    labelIndices = obj.View.handles.annotationTable.RowName;    % get indices of the labels
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(str2num(labelIndices(rowId,:))); %#ok<ST2NM>
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
            end
        end
        
        function resortTablePopup_Callback(obj)
            % function resortTablePopup_Callback(obj, sortBy, direction)
            % Resort the list of annotation labels
            %
            % Parameters:
            %
            % Return values:
            %
            obj.mibModel.mibDoBackup('labels', 1);
            
            sortingList = obj.View.handles.resortTablePopup.String;
            sortBy = lower(sortingList{obj.View.handles.resortTablePopup.Value});
            obj.mibModel.I{obj.mibModel.Id}.hLabels.sortLabels(sortBy);
            obj.updateWidgets();
        end
        
    end
end