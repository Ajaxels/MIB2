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

    
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        indices
        % indices of selected annotations in the table
        jScroll
        % java handle to the scroll bar of obj.View.handles.annotationTable
        jTable
        % java handle to the obj.View.handles.annotationTable
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
			
            % find java object for the segmentation table
            obj.jScroll = findjobj(obj.View.handles.annotationTable);
            obj.jTable = obj.jScroll.getViewport.getComponent(0);
            obj.jTable.setAutoResizeMode(obj.jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
            
            obj.mibModel.mibShowAnnotationsCheck = 1;
                    
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

            if numberOfLabels >= 1
                [labelsText, labelsPos, labelIndices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
                data = cell([numel(labelsText), 5]);
                data(:,1) = labelsText';
                data(:,2) = arrayfun(@(x) sprintf('%.2f',x),labelsPos(:,1),'UniformOutput',0);
                data(:,3) = arrayfun(@(x) sprintf('%.2f',x),labelsPos(:,2),'UniformOutput',0);
                data(:,4) = arrayfun(@(x) sprintf('%.2f',x),labelsPos(:,3),'UniformOutput',0);
                data(:,5) = arrayfun(@(x) sprintf('%d',x),labelsPos(:,4),'UniformOutput',0);
                obj.View.handles.annotationTable.RowName = labelIndices;
                obj.View.handles.annotationTable.Data = data;
            else
                data = cell([5,1]);
                obj.View.handles.annotationTable.Data = data;
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
                    title = 'Input variables for import';
                    lines = [1 30];
                    def = {'labelsList', 'labelPositions'};
                    prompt = {'A variable for the annotation labels:','A variable for the annotation coordinates:'};
                    answer = inputdlg(prompt, title, lines, def, 'on');
                    if size(answer) == 0; return; end;
                    obj.mibModel.mibDoBackup('labels', 0);
                    labelsList = evalin('base',answer{1});
                    labelPositions = evalin('base',answer{2});
                    if size(labelPositions,2) == 3  % missing the t
                        labelPositions(:, 4) = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                    end
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(labelsList, labelPositions);
                case 'Load from a file'
                    [filename, path] = uigetfile(...
                        {'*.ann;',  'Matlab format (*.ann)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Load annotations...', obj.mibModel.myPath);
                    if isequal(filename, 0); return; end; % check for cancel
                    obj.mibModel.mibDoBackup('labels', 0);
                    res = load(fullfile(path, filename), '-mat');
                    if size(res.labelPositions,2) == 3  % missing the t
                        res.labelPositions(:, 4) = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
                    end
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(res.labelsList, res.labelPositions);
            end
            obj.updateWidgets();
            
            % alternative way to call plot image, via notify listener
            eventdata = ToggleEventData(0);
            notify(obj.mibModel, 'plotImage', eventdata);
            %obj.plotImage(0);
            disp('Import annotations: done!')
        end
        
        function saveBtn_Callback(obj)
            % function saveBtn_Callback(obj)
            % save annotations to a file or export to Matlab
            
            [labelsList, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
            if numel(labelsList) == 0; return; end;
            
            button =  questdlg(sprintf('Would you like to save annotations to a file or export to the main Matlab workspace?'),'Export/Save annotations','Save to a file','Export to Matlab','Cancel','Save to a file');
            if strcmp(button, 'Cancel'); return; end;
            if strcmp(button, 'Export to Matlab')
                title = 'Input variables to export';
                lines = [1 30];
                def = {'labelsList', 'labelPositions'};
                prompt = {'A variable for the annotation labels:','A variable for the annotation coordinates:'};
                answer = inputdlg(prompt, title, lines, def, 'on');
                if size(answer) == 0; return; end;
                assignin('base',answer{1},labelsList);
                assignin('base',answer{2},labelPositions);
                fprintf('Export annotations ("%s" and "%s") to Matlab: done!\n', answer{1}, answer{2});
                return;
            end
            
            fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            dotIndex = strfind(fn_out,'.');
            if ~isempty(dotIndex)
                fn_out = fn_out(1:dotIndex-1);
            end
            if isempty(strfind(fn_out,'/')) && isempty(strfind(fn_out,'\'))
                fn_out = fullfile(obj.mibModel.myPath, fn_out);
            end
            if isempty(fn_out)
                fn_out = obj.mibModel.myPath;
            end
            
            Filters = {'*.ann;',  'Matlab format (*.ann)';...
                '*.xls',   'Excel format (*.xls)'; };
            
            [filename, path, FilterIndex] = uiputfile(Filters, 'Save annotations...',fn_out); %...
            if isequal(filename,0); return; end; % check for cancel
            fn_out = fullfile(path, filename);
            if strcmp('Matlab format (*.ann)', Filters{FilterIndex,2})    % matlab format
                save(fn_out, 'labelsList', 'labelPositions', '-mat', '-v7.3');
            elseif strcmp('Excel format (*.xls)', Filters{FilterIndex,2})    % excel format
                wb = waitbar(0,'Please wait...','Name','Generating Excel file...','WindowStyle','modal');
                warning off MATLAB:xlswrite:AddSheet
                % Sheet 1
                s = {sprintf('Annotations for %s', obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));};
                s(4,1) = {'Annotation text'};
                s(3,3) = {'Coordinates'};
                s(4,2) = {'Z'};
                s(4,3) = {'X'};
                s(4,4) = {'Y'};
                s(4,5) = {'T'};
                roiId = 4;
                for i=1:numel(labelsList)
                    s(roiId+i, 1) = labelsList(i);
                    s{roiId+i, 2} = labelPositions(i,1);
                    s{roiId+i, 3} = labelPositions(i,2);
                    s{roiId+i, 4} = labelPositions(i,3);
                    s{roiId+i, 5} = labelPositions(i,4);
                end
                xlswrite2(fn_out, s, 'Sheet1', 'A1');
                waitbar(1, wb);
                delete(wb);
            end
            fprintf('Saving annotations to %s: done!\n', fn_out);
        end
        
        function deleteBtn_Callback(obj)
        % function deleteBtn_Callback(obj)
        % delete all annotations
        obj.mibModel.mibDoBackup('labels', 0);
        obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels();
        % alternative way to call plot image, via notify listener
        eventdata = ToggleEventData(0);
        notify(obj.mibModel, 'plotImage', eventdata);
        %obj.plotImage(0);
        obj.updateWidgets();
        end
        
        function annotationTable_CellSelectionCallback(obj, Indices)
            % function annotationTable_CellSelectionCallback(obj, Indices)
            % a callback for cell selection of obj.View.handles.annotationTable
            %
            % Parameters:
            % Indices: index of the selected cell, returned by
            % eventdata.Indices structure of GUI
            
            if obj.View.handles.jumpCheck.Value == 1  % jump to the selected annotation
                if isempty(Indices); return; end;
                rowId = Indices(1);
                data = obj.View.handles.annotationTable.Data;    % get table contents
                if size(data,1) < rowId; return; end;
                
                getDim.blockModeSwitch = 0;
                [imgH, imgW, ~, imgZ] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', NaN, NaN, getDim);
                orientation = obj.mibModel.getImageProperty('orientation');
                if orientation == 4   % xy
                    z = str2double(data{rowId,2});
                    x = str2double(data{rowId,3});
                    y = str2double(data{rowId,4});
                elseif orientation == 1   % zx
                    z = str2double(data{rowId,4});
                    x = str2double(data{rowId,2});
                    y = str2double(data{rowId,3});
                elseif orientation == 2   % zy
                    z = str2double(data{rowId,3});
                    x = str2double(data{rowId,2});
                    y = str2double(data{rowId,4});
                end
                t = str2double(data{rowId,5});
                % do not jump when the label out of image boundaries
                if x>imgW || y>imgH || z>imgZ
                    warndlg('The annotation is outside of the image boundaries!','Wrong coordinates');
                    return;
                end;
                
                % move image-view to the object
                obj.mibModel.I{obj.mibModel.Id}.moveView(x, y);
                
                % change t
                if obj.mibModel.getImageProperty('time') > 1
                    eventdata = ToggleEventData(floor(t));
                    notify(obj.mibModel, 'updateTimeSlider', eventdata);
                end
                % change z
                if size(obj.mibModel.I{obj.mibModel.Id}.img{1}, orientation) > 1
                    eventdata = ToggleEventData(floor(z));
                    notify(obj.mibModel, 'updateLayerSlider', eventdata);
                else
                    notify(obj.mibModel, 'plotImage');
                end
            end
            obj.indices = Indices;
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
            
            newLabelText = data(rowId,1);
            newLabelPos(1) = str2double(data{rowId,2});
            newLabelPos(2) = str2double(data{rowId,3});
            newLabelPos(3) = str2double(data{rowId,4});
            newLabelPos(4) = str2double(data{rowId,5});
            obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(str2double(rowIndices(rowId,:)), newLabelText, newLabelPos);
            notify(obj.mibModel, 'plotImage');  % notify to plot the image
        end
        
        function tableContextMenu_cb(obj, parameter)
            % function tableContextMenu_cb(obj, parameter)
            % callbacks for the context menu of obj.View.handles.annotationTable
            %
            % Parameters:
            % parameter: a string with selected option
            orientation = obj.mibModel.getImageProperty('orientation');
            
            switch parameter
                case 'Add'  % add annotation
                    prompt={'Annotation text',...
                        sprintf('Z coordinate (Zmax=%d):', obj.mibModel.getImageProperty('depth'))...
                        sprintf('X coordinate (Xmax=%d):', obj.mibModel.getImageProperty('width'))...
                        sprintf('Y coordinate (Ymax=%d):', obj.mibModel.getImageProperty('height'))...
                        sprintf('T coordinate (Tmax=%d)', obj.mibModel.getImageProperty('time'))};
                    name='Add annotation';
                    numlines=1;
                    slices = obj.mibModel.getImageProperty('slices');
                    
                    zVal = num2str(slices{orientation}(1));
                    tVal = num2str(slices{5}(1));
                    defaultAnnotationName = obj.mibModel.getImageProperty('defaultAnnotationText');
                    defaultanswer={defaultAnnotationName, zVal, '10', '10', tVal};
                    answer=inputdlg(prompt, name, numlines, defaultanswer);
                    if isempty(answer); return; end;
                    
                    obj.mibModel.mibDoBackup('labels', 0);
                    labelsText = answer(1);
                    obj.mibModel.setImageProperty('defaultAnnotationText', labelsText{1});
                    
                    labelsPosition(1) = str2double(answer{2});
                    labelsPosition(2) = str2double(answer{3});
                    labelsPosition(3) = str2double(answer{4});
                    labelsPosition(4) = str2double(answer{5});
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelsText, labelsPosition);
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Jump'     % jump to the highlighted annotation
                    if isempty(obj.indices); return; end;
                    data = obj.View.handles.annotationTable.Data;
                    if isempty(data); return; end;
                                        
                    rowId = obj.indices(1);
                    getDim.blockModeSwitch = 0;
                    [imgH, imgW, ~, imgZ] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image',NaN,NaN,getDim);
                    if orientation == 4   % xy
                        z = str2double(data{rowId,2});
                        x = str2double(data{rowId,3});
                        y = str2double(data{rowId,4});
                    elseif orientation == 1   % zx
                        z = str2double(data{rowId,4});
                        x = str2double(data{rowId,2});
                        y = str2double(data{rowId,3});
                    elseif orientation == 2   % zy
                        z = str2double(data{rowId,3});
                        x = str2double(data{rowId,2});
                        y = str2double(data{rowId,4});
                    end
                    t = str2double(data{rowId,5});
                    % do not jump when the label out of image boundaries
                    if x>imgW || y>imgH || z>imgZ
                        warndlg('The annotation is outside of the image boundaries!', 'Wrong coordinates');
                        return;
                    end;
                    
                    % move image-view to the object
                    obj.mibModel.I{obj.mibModel.Id}.moveView(x, y);
                    
                    % change t
                    if obj.mibModel.getImageProperty('time') > 1
                        eventdata = ToggleEventData(floor(t));
                        notify(obj.mibModel, 'updateTimeSlider', eventdata);
                    end
                    % change z
                    if size(obj.mibModel.I{obj.mibModel.Id}.img{1}, orientation) > 1
                        eventdata = ToggleEventData(floor(z));
                        notify(obj.mibModel, 'updateLayerSlider', eventdata);
                    else
                        notify(obj.mibModel, 'plotImage');
                    end
                case 'Delete'   % delete the highlighted annotation
                    if isempty(obj.indices); return; end;
                    data = obj.View.handles.annotationTable.Data;
                    if isempty(data); return; end;
                    
                    rowId = obj.indices(:, 1);
                    if numel(rowId) == 1
                        button =  questdlg(sprintf('Delete the following annotation?\n\nLabel: %s\n\nCoordinates (z,x,y,t): %s %s %s %s', data{rowId,1},data{rowId,2},data{rowId,3},data{rowId,4},data{rowId,5}),'Delete annotation','Delete','Cancel','Cancel');
                    else
                        button =  questdlg(sprintf('Delete the multiple annotations?'),'Delete annotation','Delete','Cancel','Cancel');
                    end
                    if strcmp(button, 'Cancel'); return; end;
                    
                    obj.mibModel.mibDoBackup('labels', 0);
                    labelIndices = obj.View.handles.annotationTable.RowName;    % get indices of the labels
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(str2num(labelIndices(rowId,:))); %#ok<ST2NM>
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
            end
        end
    end
end