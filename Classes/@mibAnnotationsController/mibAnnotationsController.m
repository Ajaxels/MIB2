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

classdef mibAnnotationsController < handle
    % classdef mibAnnotationsController < handle
    % a controller class for the list of annotations available via
    % MIB->Menu->Models->Annotations->List of annotations
    
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
        batchModifyExpressionOperation
        % operation
        batchModifyExpressionFactor
        % factor to modify value
        childControllers
        % list of opened subcontrollers
        childControllersIds
        % a cell array with names of initialized child controllers
        BatchOpt
        % BatchOpt structure
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

        function purgeControllers(obj, src, evnt)
            % function purgeControllers(obj, src, evnt)
            % find index of the child controller and purge it
            %
            
            id = obj.findChildId(class(src));
            
            % delete the child controller
            delete(obj.childControllers{id});
            
            % clear the handle
            obj.childControllers(id) = [];
            obj.childControllersIds(id) = [];
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

            % add icons to buttons
            obj.View.handles.settingsButton.CData = obj.mibModel.sessionSettings.guiImages.settings;
            
            obj.mibModel.mibShowAnnotationsCheck = 1;
            obj.View.handles.precisionEdit.String = num2str(obj.mibModel.mibAnnValuePrecision);
            obj.batchModifyExpressionOperation = 'Multiply';
            obj.batchModifyExpressionFactor = '1.5';
            obj.updateWidgets();
            
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'updatedAnnotations', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));   % listen for updated annotations

            obj.BatchOpt.CropObjectsTo = {'Amira Mesh binary (*.am)'};                       % additionally crop detected objects to files or export to matlab
            obj.BatchOpt.CropObjectsTo{2} = {'Do not crop', 'Crop to Matlab', ...
                'Amira Mesh binary (*.am)','MRC format for IMOD (*.mrc)','NRRD Data Format (*.nrrd)',...
                'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'};
            obj.BatchOpt.CropObjectsMarginXY = '256';     % width of the image patch
            obj.BatchOpt.CropObjectsMarginZ = '256';     % height of the image patch
            obj.BatchOpt.CropObjectsDepth = '1';     % depth of the image patch
            obj.BatchOpt.Generate3DPatches = false;     % generate 3D patches
            obj.BatchOpt.CropObjectsIncludeModel = {'Do not include'};
            obj.BatchOpt.CropObjectsIncludeModel{2} = {'Do not include', 'Crop to Matlab', 'Matlab format (*.model)', ...
                    'Amira Mesh binary (*.am)', 'MRC format for IMOD (*.mrc)', 'NRRD Data Format (*.nrrd)', ...
                    'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)}'};
            obj.BatchOpt.CropObjectsIncludeModelMaterialIndex = 'NaN';  % index of the material for cropping the models, or NaN to crop all materials
            obj.BatchOpt.CropObjectsIncludeMask = {'Do not include'};
            obj.BatchOpt.CropObjectsIncludeMask{2} = {'Do not include', 'Crop to Matlab', 'Matlab format (*.mask)', ...
                    'Amira Mesh binary (*.am)', 'MRC format for IMOD (*.mrc)', 'NRRD Data Format (*.nrrd)', ...
                    'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'};
            obj.BatchOpt.CropObjectsOutputName = 'CropOut';     % name of the variable template or directory for the object crop
            obj.BatchOpt.SingleMaskObjectPerDataset = false;    % check to remove all other objects that may apper within the clipping box of the main detected object
            
            obj.BatchOpt.CropObjectsJitter = false;     % enable jitter for centroids
            if ~isfield(obj.mibModel.sessionSettings, 'annotationsCropPatches') || ~isfield(obj.mibModel.sessionSettings.annotationsCropPatches, 'CropObjectsJitterVariation')
                obj.mibModel.sessionSettings.annotationsCropPatches.CropObjectsJitterVariation = '50';
                obj.mibModel.sessionSettings.annotationsCropPatches.CropObjectsJitterSeed = '0';
            end
            obj.BatchOpt.CropObjectsJitterVariation = obj.mibModel.sessionSettings.annotationsCropPatches.CropObjectsJitterVariation;   % variation of the jitter in pixels
            obj.BatchOpt.CropObjectsJitterSeed = obj.mibModel.sessionSettings.annotationsCropPatches.CropObjectsJitterSeed;    % initialization of the random generator, when 0-random
            
            obj.BatchOpt.showWaitbar = true;
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
            global mibPath;
            
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
                    [filename, path, indx] = mib_uigetfile(...
                        {'*.ann;',  'Matlab format (*.ann)'; ...
                        '*.csv;',  'CSV format (*.csv)'; ...
                        '*.landmarkAscii;',  'landmarkAscii Amira format (*.landmarkAscii)'; ...
                        '*.landmarkBin;',  'landmarkBin Amira format (*.landmarkBin)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Load annotations...', obj.mibModel.myPath);
                    if isequal(filename, 0); return; end % check for cancel
                    fullFilename = fullfile(path, filename{1});
                    
                    obj.mibModel.mibDoBackup('labels', 0);
                    switch indx
                        case 1  % matlab, ann-file
                            res = load(fullFilename, '-mat');
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
                            
                        case 2  % csv file
                            opts = detectImportOptions(fullFilename);
                            T = readtable(fullFilename, opts);
                            varNames = T.Properties.VariableNames;
                            varNames2 = ['do not import', sort(varNames)];
                            
                            prompts = {'Annotation name'; 'Annotation value'; 'Z coordinate (pixels)'; 'X coordinate (pixels)'; 'Y coordinate (pixels)'; 'T coordinate (pixels)'};
                            defAns = {[varNames2, {1}], [varNames2, {1}], [varNames2, {1}], [varNames2, {1}], [varNames2, {1}], [varNames2, {1}]};
                            dlgTitle = 'Import from CSV';
                            options.PromptLines = [1, 1, 1, 1, 1, 1];   % number of lines for widget titles
                            options.Title = 'Select column names in CSV file that to these fields';   % additional text at the top of the window
                            options.TitleLines = 2;                   % [optional] make it twice tall, number of text lines for the title
                            options.WindowWidth = 1.2;    % [optional] make window x1.2 times wider
                            options.Columns = 1;    % [optional] define number of columns
                            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                            if isempty(answer); return; end
                            
                            % allocate space
                            N = numel(T(:,1));  % number of entries in the input table
                            res.labelText = repmat({'Label'}, [N,1]);
                            res.labelValue = zeros([N, 1]);
                            res.labelPosition = ones([N, 4]);
                            
                            if ~strcmp(answer{1}, 'do not import')  % import label names
                                if isnumeric(T.(answer{1})(1))
                                    res.labelText  = cellstr(string(T.(answer{1})));
                                else
                                    res.labelText  = T.(answer{1});
                                end
                            end
                            if ~strcmp(answer{2}, 'do not import')  % import label values
                                if isnumeric(T.(answer{2})(1))
                                    res.labelValue  = T.(answer{2});
                                else
                                    res.labelValue  = cellstr(str2double(T.(answer{2})));
                                end
                            end
                            for fieldId = 3:6   % z  x  y  t
                                if ~strcmp(answer{fieldId}, 'do not import')  % import label values
                                    if isnumeric(T.(answer{fieldId})(1))
                                        res.labelPosition(:, fieldId-2) = T.(answer{fieldId});
                                    else
                                        res.labelPosition(:, fieldId-2) = cellstr(str2double(T.(answer{fieldId})));
                                    end
                                end
                            end
                        case {3, 4}  % landmarkAscii file
                            % get points as matrix [pointId, [x,y,z]]
                            amiraLandmarks = amiraLandmarks2points(fullFilename);
                            % add Time dimension
                            res = struct();
                            res.labelText = repmat({'AmiraLandmark'}, [size(amiraLandmarks,1), 1]);
                            res.labelValue = ones([size(amiraLandmarks,1), 1]);
                            res.labelPosition = ones([size(amiraLandmarks,1), 4]);
                            
                            % convert from units to pixels
                            % and rearrange to [z, x, y] format from [x, y, z] 
                            bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
                            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;

                            % z
                            res.labelPosition(:,1) = round((amiraLandmarks(:,3) - bb(5) + pixSize.z)/pixSize.z);
                            % x
                            res.labelPosition(:,2) = (amiraLandmarks(:,1) - bb(1) + pixSize.x/2)/pixSize.x; % x
                            % y
                            res.labelPosition(:,3) = (amiraLandmarks(:,2) - bb(3) + pixSize.y/2)/pixSize.y; 

                        otherwise
                            return
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
            
            global mibPath;
            
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
            
            Filters = {'*.ann',  'Matlab format (*.ann)';...
                       '*.csv',   'Comma-separated value (*.csv)';...
                       '*.landmarkAscii',   'Amira landmarks ASCII (*.landmarkAscii)';...
                       '*.landmarkBin',   'Amira landmarks BINARY(*.landmarkBin)';...
                       '*.psi',   'PSI format ASCII(*.psi)';...
                       '*.xls',   'Excel format (*.xls)'; };
            [filename, path, FilterIndex] = uiputfile(Filters, 'Save annotations...', fn_out); %...
            if isequal(filename,0); return; end % check for cancel
            
            fn_out = fullfile(path, filename);
            
            if ~isfield(obj.mibModel.sessionSettings, 'Annotations'); obj.mibModel.sessionSettings.Annotations = struct(); end
            if ~isfield(obj.mibModel.sessionSettings.Annotations, 'recalculateCoordinates')
                obj.mibModel.sessionSettings.Annotations.recalculateCoordinates = 1;
                obj.mibModel.sessionSettings.Annotations.addLabelToFilename = true;
            end
                    
            switch Filters{FilterIndex,2}
                case 'Matlab format (*.ann)'   % matlab format
                    options.format = 'ann';
                case 'Comma-separated value (*.csv)'    % csv format
                    options.format = 'csv';
                case 'Excel format (*.xls)'    % excel format
                    options.format = 'xls';
                case 'PSI format ASCII(*.psi)'    % PSI format, compatible with Amira
                    prompts = {'Recalculate annotations with respect to the current bounding box or save as they are?'; 'Add annotation label to filename'};
                    defAns = {{'Recalculate', 'Save as they are', obj.mibModel.sessionSettings.Annotations.recalculateCoordinates}; obj.mibModel.sessionSettings.Annotations.addLabelToFilename};
                    dlgTitle = 'Export annotations in PSI format';
                    options.WindowStyle = 'normal';      
                    options.PromptLines = [2, 1];   
                    options.WindowWidth = 1.2;    
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end
                    
                    % update session settings
                    obj.mibModel.sessionSettings.Annotations.recalculateCoordinates = selIndex(1);
                    obj.mibModel.sessionSettings.Annotations.addLabelToFilename = logical(answer{2});

                    options.addLabelToFilename = obj.mibModel.sessionSettings.Annotations.addLabelToFilename;
                    options.format = 'psi';
                    if strcmp(answer{1}, 'Recalculate')
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
                
                    if strcmp(Filters{FilterIndex+numel(Filters)/2}, 'Amira landmarks ASCII (*.landmarkAscii)')
                        options.format = 'landmarkAscii';
                    else
                        options.format = 'landmarkBin';
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

            % generate slice names for export
            if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
                if numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName')) == obj.mibModel.I{obj.mibModel.Id}.depth
                    sliceNames = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                else
                    sliceNames = repmat(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'), [max(options.labelPosition(:,1)), 1]);
                end
            else
                [~, sliceNames, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                sliceNames = repmat({[sliceNames, ext]}, [max(options.labelPosition(:,1)), 1]);
            end

            sliceValsZ = round(options.labelPosition(:,1));
            sliceValsZ(sliceValsZ<=0) = [];
            options.sliceNames = sliceNames(sliceValsZ);

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
            
            notify(obj.mibModel, 'updateId');  % notify to plot the image
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
            % ''CropPatches'' - crop patches from image around selected annotations
            % ''Mask'' - copy selected annotations to the mask layer
            % ''Interpolate'' - interpolate between two selected annotations; add result as new annotations
            % ''Export'' - export/save annotations to matlab or to a file
            % ''Imaris'' - export annotations to Imaris
            % ''OrderTop'', ''OrderUp'', ''OrderDown'', ''OrderBottom'' - change order of the annotation in the list
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
                case {'OrderTop', 'OrderUp', 'OrderDown', 'OrderBottom'}     % 
                    [labelsList, labelValues, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
                    indicesList = 1:numel(labelsList);
                    switch parameter
                        case 'OrderTop'
                            newIndices = [obj.indices(:,1); indicesList(~ismember(indicesList, obj.indices(:,1)))'];
                        case 'OrderUp'
                            newIndices = indicesList;
                            for i=1:numel(labelsList)
                                if ismember(i, obj.indices(:,1)-1)
                                    newIndices(i+1) = newIndices(i);
                                    newIndices(i) = indicesList(i+1);
                                end
                            end
                            obj.indices(:,1) = obj.indices(:,1) - 1;
                        case 'OrderDown'
                            newIndices = indicesList;
                            for i=numel(labelsList):-1:1
                                if ismember(i, obj.indices(:,1))
                                    if i==numel(labelsList); return; end
                                    newIndices(i) = newIndices(i+1);
                                    newIndices(i+1) = indicesList(i);
                                end
                            end
                            obj.indices(:,1) = obj.indices(:,1) + 1;
                        case 'OrderBottom'
                            newIndices = [indicesList(~ismember(indicesList, obj.indices(:,1)))'; obj.indices(:,1)];
                    end
                    
                    labelsList = labelsList(newIndices);
                    labelValues = labelValues(newIndices);
                    labelPositions = labelPositions(newIndices, :);
                    
                    obj.mibModel.mibDoBackup('labels', 0);
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();    % remove current labels
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelsList, labelPositions, labelValues);     % add updated labels
                    
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Modify'   % batch modify selected annotations
                    if isempty(obj.indices); return; end
                    operations = {'Set value', 'Add', 'Subtract', 'Multiply', 'Divide', 'Round', 'Floor', 'Ceil'};
                    inputDlgOptions.Title = sprintf('Select dedired operation modify selected values using the provided factor:');
                    inputDlgOptions.TitleLines = 2;
                    inputDlgOptions.WindowWidth = 1.2;
                    prompt = {'Type of operation:', 'Factor:'};
                    defAns = {[operations, find(ismember(operations, obj.batchModifyExpressionOperation))]; obj.batchModifyExpressionFactor};
                    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Batch modify', inputDlgOptions);
                    if isempty(answer); return; end
                    obj.batchModifyExpressionOperation = answer{1};
                    obj.batchModifyExpressionFactor = answer{2};
                    [labelsList, labelValues, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels();
                    
                    value = str2double(obj.batchModifyExpressionFactor);
                    
                    for colId = 1:6
                        idx = find(obj.indices(:,2) == colId); %#ok<EFIND>
                        if isempty(idx); continue; end
                        switch colId
                            case 1
                                errordlg(sprintf('!!! Error !!!\nModification of the label names using this function is not yet implemented...'), 'Not implemented');
                                return;
                            case 2
                                A = labelValues(obj.indices(idx,1)); %#ok<NASGU>
                                labelValues(obj.indices(idx,1)) = A;
                            otherwise
                                A = labelPositions(obj.indices(idx,1), colId-2); %#ok<NASGU>
                                labelPositions(obj.indices(idx,1), colId-2) = A;
                        end
                        
                        switch obj.batchModifyExpressionOperation
                            case 'Set value'
                                A(:) = value;
                            case 'Add'
                                A = A + value;
                            case 'Subtract'
                                A = A - value;
                            case 'Multiply'
                                A = A * value;
                            case 'Divide'
                                A = A / value;
                            case 'Round'
                                A = round(A);
                            case 'Floor'
                                A = floor(A);
                            case 'Ceil'
                                A = ceil(A);
                        end
                        switch colId
                            case 1
                                errordlg(sprintf('!!! Error !!!\nModification of the label names using this function is not yet implemented...'), 'Not implemented');
                                return;
                            case 2
                                labelValues(obj.indices(idx,1)) = A;
                            otherwise
                                labelPositions(obj.indices(idx,1), colId-2) = A;
                        end
                    end
                    obj.mibModel.mibDoBackup('labels', 0);
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();    % remove current labels
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelsList, labelPositions, labelValues);     % add updated labels
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Rename'
                    if isempty(obj.indices); return; end
                    rowId = unique(obj.indices(:, 1));
                    
                    currentName = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(rowId(1));
                    if isempty(currentName); return; end
                    
                    prompts = {'String to search for'; 'Replace with'};
                    defAns = {''; currentName{1}};
                    dlgTitle = 'Rename annotations';
                    dlgOptions.Focus = 2;
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, dlgOptions);
                    if isempty(answer); return; end

                    obj.mibModel.mibDoBackup('labels', 0);
                    if isempty(answer{1})
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.renameLabels(rowId, answer(2)); 
                    else
                        labels = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(rowId);
                        labels = strrep(labels, answer{1}, answer{2});
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.renameLabels(rowId, labels); 
                    end
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
                case 'ClipboardPaste'
                    if isempty(obj.indices); return; end
                    % do backup
                    obj.mibModel.mibDoBackup('labels', 1);

                    startIndex = obj.indices(1, 1);
                    if obj.indices(1, 2) == 1 % update label text
                        values = clipboard('paste');
                        if isempty(values); return; end
                        values = strsplit(values)';
                        values(cellfun(@(x) isempty(x), values)) = [];
                        
                        endIndex = startIndex + numel(values) - 1;

                        listOfIds = startIndex:endIndex;
                        [labelsList, labelValues, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(listOfIds');
                        labelsList = values;
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(listOfIds', labelsList, labelPositions, labelValues);
                    elseif obj.indices(1, 2) == 2 % values    
                        % convert to values
                        values = str2num(clipboard('paste')); %#ok<ST2NM>
                        if isempty(values); return; end
                        endIndex = startIndex + numel(values) - 1;
                        listOfIds = startIndex:endIndex;
                        [labelsList, labelValues, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(listOfIds');
                        labelValues = values;
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(listOfIds', labelsList, labelPositions, labelValues);
                    else                     % update positions
                        % convert to values
                        values = str2num(clipboard('paste')); %#ok<ST2NM>
                        if isempty(values); return; end
                        endIndex = startIndex + numel(values) - 1;
                        listOfIds = startIndex:endIndex;
                        [labelsList, labelValues, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(listOfIds');
                        labelPositions(:, obj.indices(1, 2)-2) = values;
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(listOfIds', labelsList, labelPositions, labelValues);
                    end

                    jScrollPosition = obj.jScroll.getViewport.getViewPosition(); % store the view position of the table
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                    drawnow;
                    obj.jScroll.getViewport.setViewPosition(jScrollPosition);
                    obj.jScroll.repaint;
                case 'Mask'
                    if isempty(obj.indices); return; end
                    
                    prompts = {'Mode'; 'Spot size policy (fixed - all spots will have the same radius; scaled - not implemented)'; 'Spot radius in pixels or scale factor'};
                    defAns = {{'2D spots', '3D spots', 1}; {'Fixed value', 'Scaled from Value', 1}; '1'};
                    dlgTitle = 'Conversion to Mask';
                    options.PromptLines = [1, 2, 1];  
                    options.WindowWidth = 1.0;
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end 
                    wb = waitbar(0, sprintf('Getting the annotations\nPlease wait'));
                    
                    if obj.mibModel.I{obj.mibModel.Id}.maskExist
                        setDataOptions.blockModeSwitch = 0;
                        obj.mibModel.mibDoBackup('mask', 1, setDataOptions);
                    end
                    obj.mibModel.I{obj.mibModel.Id}.clearMask();
                    
                    data = obj.View.handles.annotationTable.Data;
                    d = data(unique(obj.indices(:,1)), 3:6);    % [z, x, y, t]
                    d2 = ceil(str2double(d));
                    % remove those that are out of bounds
                    d2(d2(:,1)<1, :) = [];  % z
                    d2(d2(:,1)>obj.mibModel.I{obj.mibModel.Id}.depth, :) = [];  % z
                    d2(d2(:,2)<1, :) = [];  % x
                    d2(d2(:,2)>obj.mibModel.I{obj.mibModel.Id}.width, :) = [];  % x
                    d2(d2(:,3)<1, :) = [];  % y
                    d2(d2(:,3)>obj.mibModel.I{obj.mibModel.Id}.height, :) = [];  % y
                    d2(d2(:,4)<1, :) = [];  % t
                    d2(d2(:,4)>obj.mibModel.I{obj.mibModel.Id}.time, :) = [];  % t
                    
                    %timeVec = unique(str2double(d(:,4)));   % get unique time points for the labels
                    switch answer{2}
                        case 'Fixed value'
                            waitbar(0.05, wb, sprintf('Placing the seeds\nPlease wait'));
                            for pntId = 1:size(d2, 1)
                                getDataOpt.x = d2(pntId, 2);
                                getDataOpt.y = d2(pntId, 3);
                                getDataOpt.z = d2(pntId, 1);
                                getDataOpt.t = d2(pntId, 4);
                                obj.mibModel.I{obj.mibModel.Id}.setData('mask', 1, 4, NaN, getDataOpt);
                            end
                            waitbar(0.3, wb, sprintf('Growing the seeds\nPlease wait'));
                            if str2double(answer{3}) > 1
                                BatchOptDilate.TargetLayer = {'mask'};
                                BatchOptDilate.DatasetType = {'4D, Dataset'};
                                BatchOptDilate.DilateMode = {answer{1}(1:2)};     % 2D or 3D spots
                                BatchOptDilate.StrelSize = answer{3};
                                obj.mibModel.dilateImage(BatchOptDilate);
                            end
                            waitbar(1, wb, 'Done!');
                            notify(obj.mibModel, 'plotImage');  % notify to plot the image
                            delete(wb);
                            
                            if size(d,1) ~= size(d2,1)
                                warndlg(sprintf('!!! Warning !!!\n%d annotations were out of image boundaries and were not rendered!', size(d,1)-size(d2,1)), 'Results');
                            end
                        case 'Scaled from Value'
                            errordlg(sprintf('!!! Error !!!\n\nThese mode is not yet implemented'));
                            return
                    end
                    notify(obj.mibModel, 'showMask');
                case 'Interpolate'
                    if isempty(obj.indices) || size(obj.indices, 1) == 1; return; end
                    % get selected annotations; labelPosition as [id][z,x,y,t]
                    [labelNames, labelValues, labelPosition, labelIndices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(obj.indices(:,1));
                    
                    % makesure that there is a single annotation per slice
                    if numel(unique(labelPosition(:,1))) ~= size(obj.indices, 1)
                        errordlg(sprintf('!!! Error !!!\n\nPlease make sure that the selected annotations have only 1 annotation per slice!'));
                        return;
                    end
                    
                    % define interpolation settings
                    interpolationMethod = {'linear'};
                    selIndex = 1;
                    if size(obj.indices, 1) >  2; interpolationMethod = [interpolationMethod, {'cubic'}]; end
                    if size(obj.indices, 1) >  3; interpolationMethod = [interpolationMethod, {'spline'}]; end
                    if size(obj.indices, 1) >  2
                        interpolationMethod{end+1} = 1;
                        prompts = {'Specify interpolation method:'};
                        defAns = {interpolationMethod};
                        dlgTitle = 'Interpolation method';
                        options.msgBoxOnly = false;
                        [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                        if isempty(answer); return; end 
                    end
                    interpolationMethod = interpolationMethod{selIndex};
                    % do backup
                    obj.mibModel.mibDoBackup('labels', 0);
                    
                    % sort annotations based on Z and define their range
                    [~, ids] = sort(labelPosition, 1);
                    labelPosition = labelPosition(ids(:,1), :);
                    labelValues = labelValues(ids(:,1));
                    labelNames = labelNames(ids(:,1));
                    
                    z_range = min(labelPosition(:,1)):max(labelPosition(:,1));  % range vector between min and max Z
                    % Interpolate x and y values for each z value
                    x_interp = interp1(labelPosition(:, 1), labelPosition(:, 2), z_range, interpolationMethod);     % x_interp = interp1([z1 z2], [x1 x2], z_range);
                    y_interp = interp1(labelPosition(:, 1), labelPosition(:, 3), z_range, interpolationMethod);     % y_interp = interp1([z1 z2], [y1 y2], z_range);
                    v_interp = interp1(labelPosition(:, 1), labelValues, z_range, interpolationMethod);   % values
                    newPositions = [z_range', x_interp', y_interp', repmat(labelPosition(1,4), [numel(z_range), 1])];
                  
                    % generate new labels
                    newLabelName = [];
                    for zId = 1:size(labelPosition(:,1),1)-1
                        noSlices = labelPosition(zId+1,1)-1 - labelPosition(zId,1) + 1; 
                        newLabelName = [newLabelName; repmat(labelNames(zId), [noSlices, 1])]; %#ok<AGROW>
                    end
                    newLabelName(end+1) = labelNames(zId+1);

                    % remove selected labels
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(labelIndices);
                    % add new interpolated labels
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(newLabelName, newPositions, v_interp);
                    
                    obj.updateWidgets();
                    notify(obj.mibModel, 'plotImage');  % notify to plot the image
                case 'Export'
                    if isempty(obj.indices); return; end
                    indList = unique(obj.indices(:,1));
                    labelText = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelText(indList);
                    labelValue = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelValue(indList);
                    labelPosition = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelPosition(indList, :);
                    obj.saveAnnotationsToFile(labelText, labelPosition, labelValue);
                case 'CropPatches' % crop patches from image around selected annotations
                    if isempty(obj.indices); return; end
                    indList = unique(obj.indices(:,1));
                    annotationLabels.positions = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelPosition(indList, :);     % [z, x, y, t];
                    annotationLabels.names = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelText(indList);
                    BatchModeSwitch = false;
                    obj.startController('mibCropObjectsController', obj, BatchModeSwitch, annotationLabels);
                case 'Imaris' % export annotations to Imaris
                    if isempty(obj.indices); return; end
                    data = obj.View.handles.annotationTable.Data;
                    if isempty(data); return; end
                    annIds = unique(obj.indices(:,1));
                    
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
                    
                    rowId = unique(obj.indices(:, 1));
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
        
        function mibAnnotationsGUI_KeyPressFcn(obj, eventdata)
            % function mibAnnotationsGUI_KeyPressFcn(obj, eventdata)
            % callback from key presses within the mibAnnotationsGUI
            
            if ismember('control', eventdata.Modifier)
                switch lower(eventdata.Key)
                    case 'z'
                        %notify(obj.mibModel, 'undoneBackup');  % notify to do undo
                        %obj.updateWidgets();
                end
            end
        end

        function annotationTable_KeyPressFcn(obj, eventdata)
            % function annotationTable_KeyPressFcn(obj, eventdata)
            % callback from key pressed within the obj.View.handles.annotationTable

            if ismember('control', eventdata.Modifier)
                if ismember('shift', eventdata.Modifier)
                    switch eventdata.Key
                        case 'uparrow'
                            obj.tableContextMenu_cb('OrderTop');
                        case 'downarrow'
                            obj.tableContextMenu_cb('OrderBottom');
                    end
                else
                    switch eventdata.Key
                        case 'uparrow'
                            obj.tableContextMenu_cb('OrderUp');
                        case 'downarrow'
                            obj.tableContextMenu_cb('OrderDown');
                    end
                end
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
        
        function startController(obj, controllerName, varargin)
            % function startController(obj, controllerName, varargin)
            % start a child controller using provided name, see more in see more in mibController.startController
            %
            % Parameters:
            % controllerName: a string with name of a child controller, for example, 'mibImageAdjController'
            % varargin: additional optional controllers or parameters
            %
            
            id = obj.findChildId(controllerName);        % define/find index for this child controller window
            if ~isempty(id); return; end   % return if controller is already opened
            
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
            addlistener(obj.childControllers{id}, 'closeEvent', @(src,evnt) mibAnnotationsController.purgeControllers(obj, src, evnt));   % static
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

        function settingsBtn_Callback(obj)
            % function settingsBtn_Callback(obj)
            % define additional settings for the annotations
            global mibPath;
            
            prompts = {sprintf('Show annotations for extra slices (positive integer):'), 'Annotation size:', 'Pick new color:'};
            defAns = {sprintf('%d', obj.mibModel.preferences.SegmTools.Annotations.ShownExtraDepth); ...
                {'1 (pt 8)', '2 (pt 10)', '3 (pt 12)', '4 (pt 14)', '5 (pt 16)', '6 (pt 18)', '7 (pt 20)', obj.mibModel.preferences.SegmTools.Annotations.FontSize}; ...
                false; ...
                };
            dlgTitle = 'Annotation settings';
            options.WindowStyle = 'normal';       % [optional] style of the window
            options.PromptLines = [2; 1; 1];   % [optional] number of lines for widget titles
            options.WindowWidth = 1.2;    % [optional] make window x1.2 times wider
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            
            value = str2double(answer{1});
            if isnan(value)
                errordlg(sprintf('!!! Error !!!\n\nA wrong value ("%s") was provided!\nPlease enter positive integer or 0', answer{1}), 'Wrong value');
                return
            end
            
            % get new color for the annotations
            if answer{3}
                sel_color = obj.mibModel.preferences.SegmTools.Annotations.Color;
                c = uisetcolor(sel_color, 'Annotations color');
                if length(c) > 1
                    obj.mibModel.preferences.SegmTools.Annotations.Color = c;
                end
            end
            
            obj.mibModel.preferences.SegmTools.Annotations.ShownExtraDepth = abs(round(value));
            obj.mibModel.preferences.SegmTools.Annotations.FontSize = selIndex(2);
            notify(obj.mibModel, 'plotImage');
        end
        
    end
end