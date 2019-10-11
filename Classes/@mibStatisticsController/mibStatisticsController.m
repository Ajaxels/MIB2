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
        anisotropicVoxelsAgree
        % check for warning about anisotropic voxels
        availableProperties2D
        % cell array with the list of available properties for 2D objects
        availableProperties3D
        % cell array with the list of available properties for 3D objects
        availablePropertiesInt
        % cell array with the list of available properties for intensity objects
        histLimits
        % limits for the histogram
        indices
        % indices of selected entries in the statTable
        listener
        % a cell array with handles to listeners
        intType
        % index of the selected mode for the intensity mode
        matlabVersion
        % version of Matlab
        obj2DType
        % index of the selected mode for the object mode
        obj3DType
        % index of the selected mode for the object mode
        runId
        % a vector [datasetId, materialId] for which dataset statistics was calculated
        sortingDirection
        % a variable to keep sorting status for columns, sorting==1 for ascend, sorting==0 for descent
        sortingColIndex
        % a number with the index of the column to use for sorting (i.e. 1, 2, 3, or 4)
        statProperties
        % list of properties to calculate
        STATS
        % a structure with quantification results
        childControllers
        % list of opened subcontrollers
        childControllersIds
        % a cell array with names of initialized child controllers
        BatchOpt
        % a structure compatible with batch operation, see details in the contsructor
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateId', 'showModel'}
                    obj.updateWidgets();
                case 'newDataset'
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
        function obj = mibStatisticsController(mibModel, contIndex, varargin)
            % obj = mibStatisticsController(mibModel, contIndex, varargin)
            % constructor for mibStatisticsController
            %
            % Parameters:
            % mibModel:     a handle to mibModel
            % contIndex: index of the dataset for statistics (1-mask, 2-Exterior, 3, 4 materials of the model)
            
            obj.availableProperties2D = {'Area','ConvexArea','CurveLength','Eccentricity','EquivDiameter',...
                'EndpointsLength','EulerNumber','Extent','FilledArea','FirstAxisLength','HolesArea','MajorAxisLength',...   % '---- 2D objects ----'
                'MinorAxisLength','Orientation','Perimeter','SecondAxisLength','Solidity'};
            obj.availableProperties3D = {'Volume','EndpointsLength','EquatorialEccentricity','FilledArea','HolesArea','MajorAxisLength',...  % '---- 3D objects ----'
                'MeridionalEccentricity','SecondAxisLength','ThirdAxisLength',...
                'ConvexVolume', 'EquivDiameter','Extent','Solidity','SurfaceArea'};
            obj.availablePropertiesInt = {'MinIntensity','MaxIntensity','MeanIntensity','StdIntensity','SumIntensity','Correlation'};  % '---- Intensity ----'
            
            if nargin < 2; contIndex = []; end
            obj.mibModel = mibModel;    % assign model
            if isempty(contIndex); contIndex = mibModel.I{mibModel.Id}.selectedMaterial+2; end
            
            %% Define default BatchOpt structure
            obj.BatchOpt.MaterialIndex = num2str(contIndex);   % index of material to be quantified: -1, mask; 0-exterior; 1,2,etc indices of materials; NaN-complete model for models with more than 255 materials
            obj.BatchOpt.DatasetType = {'3D, Stack'};   % perform opertion on dataset
            obj.BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
            obj.BatchOpt.Shape = {'Shape2D'};         % shape of the objects to detect
            obj.BatchOpt.Shape{2} = {'Shape2D', 'Shape3D'};
            obj.BatchOpt.Mode = {'Object'};         % calculate properties of objects or image intensity under the areas of the objects
            obj.BatchOpt.Mode{2} = {'Object', 'Intensity'};
            obj.BatchOpt.Property = {'Area'};   % property to be calculated
            obj.BatchOpt.Property{2} = [{'---- 2D Object ----'}, obj.availableProperties2D, ...
                                        {'---- 3D Object ----'}, obj.availableProperties3D, ...
                                        {'---- Intensity ----'}, obj.availablePropertiesInt];
            
            obj.BatchOpt.Multiple = false;   % switch to calculate multiple properties
            obj.BatchOpt.MultipleProperty = 'Area; FirstAxisLength; Orientation; SecondAxisLength; MinIntensity; MaxIntensity; MeanIntensity; SumIntensity';   % list of multiple properties to calculate, when Multiple==true
            obj.BatchOpt.Connectivity = {'4/6 connectivity'};         % shape of the objects to detect
            obj.BatchOpt.Connectivity{2} = {'4/6 connectivity', '8/26 connectivity'};
            obj.BatchOpt.Units = {'pixels'};         % shape of the objects to detect
            obj.BatchOpt.Units{2} = {'pixels', 'um'};
            PossibleColChannels = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{obj.mibModel.Id}.colors, 'UniformOutput', false);
            obj.BatchOpt.ColorChannel1 = {'ColCh 1'};         % [Intensity] specify the color channel
            obj.BatchOpt.ColorChannel1{2} = PossibleColChannels;
            obj.BatchOpt.ColorChannel2 = PossibleColChannels(end);         % [Intensity/Correlation] specify the second color channel
            obj.BatchOpt.ColorChannel2{2} = PossibleColChannels;
            obj.BatchOpt.ExportResultsTo = {'Excel format (*.xls)'};    % export results to one of these destinations
            obj.BatchOpt.ExportResultsTo{2} = {'Do not export', 'Export to Matlab', ...
                        'Excel format (*.xls)', 'Comma-separated values (*.csv)', 'Matlab format (*.mat)'};
            imgFilename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            [~, imgFilename] = fileparts(imgFilename);
            obj.BatchOpt.ExportFilename = [filesep imgFilename '_analysis'];    % filename or variable name for the export
            obj.BatchOpt.CropObjectsTo = {'Do not crop'};                       % additionally crop detected objects to files or export to matlab
            obj.BatchOpt.CropObjectsTo{2} = {'Do not crop', 'Crop to Matlab', ...
                'Amira Mesh binary (*.am)','MRC format for IMOD (*.mrc)','NRRD Data Format (*.nrrd)',...
                'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'};
            obj.BatchOpt.CropObjectsMarginXY = '0';     % margin value for the cropping of the objects in XY
            obj.BatchOpt.CropObjectsMarginZ = '0';     % margin value for the cropping of the objects in Z
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
            obj.BatchOpt.showWaitbar = true;   % show or not the waitbar
            
            % add section name and action name for the batch tool
            if contIndex == -1
                obj.BatchOpt.mibBatchSectionName = 'Menu -> Mask';
            else
                obj.BatchOpt.mibBatchSectionName = 'Menu -> Models';
            end
            obj.BatchOpt.mibBatchActionName = 'Get statistics';
            
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.MaterialIndex = sprintf('Index of the material to be quantified. -1: for Mask; 0: for Exterior; 1,2,etc: for indices of materials; NaN-complete model for models with more than 255 materials');
            obj.BatchOpt.mibBatchTooltip.DatasetType = sprintf('Specify whether to apply MorphOps to a shown slice (2D, Slice), the whole stack (3D, Stack) or complete dataset (4D, Dataset)');
            obj.BatchOpt.mibBatchTooltip.Shape = sprintf('Shape of the objects to be identified');
            obj.BatchOpt.mibBatchTooltip.Mode = sprintf('Calculate properties of objects or image intensity under the areas of the objects');
            obj.BatchOpt.mibBatchTooltip.Property = sprintf('Select one of these properties for calculation; the Shape parameter should correspond selected property');
            obj.BatchOpt.mibBatchTooltip.Multiple = sprintf('Check this to calculate multiple properties, use the MultipleProperty field');
            obj.BatchOpt.mibBatchTooltip.MultipleProperty = sprintf('Type names of properties to calculate separated with ";", they will be used when Multiple is true');
            obj.BatchOpt.mibBatchTooltip.Connectivity = sprintf('Connectivity value for object separation');
            obj.BatchOpt.mibBatchTooltip.Units = sprintf('Units for the results, pixels or physical units');
            obj.BatchOpt.mibBatchTooltip.ColorChannel1 = sprintf('[Intensity only] Specify color channel for analysis');
            obj.BatchOpt.mibBatchTooltip.ColorChannel2 = sprintf('[Intensity/Correlation only] Specify the second color channel for correlation analysis');
            obj.BatchOpt.mibBatchTooltip.ExportResultsTo = sprintf('Select destination for calculated results, please provide relative filename to the ExportFilename field');
            obj.BatchOpt.mibBatchTooltip.ExportFilename = sprintf('Name of a new variable in Matlab main workspace or relative to the dataset filename');
            obj.BatchOpt.mibBatchTooltip.CropObjectsTo = sprintf('Additionally crop out detected objects from the dataset and save them to disk or export to Matlab');
            obj.BatchOpt.mibBatchTooltip.CropObjectsOutputName = sprintf('Specify directory name or variable for cropping detected objects');
            obj.BatchOpt.mibBatchTooltip.CropObjectsMarginXY = sprintf('Specify the XY margin in pixels for the cropping the objects out');
            obj.BatchOpt.mibBatchTooltip.CropObjectsMarginZ = sprintf('Specify the Z margin in pixels for the cropping the objects out');
            obj.BatchOpt.mibBatchTooltip.CropObjectsIncludeModel = sprintf('If the model is present also crop out the model and save next to the images');
            obj.BatchOpt.mibBatchTooltip.CropObjectsIncludeModelMaterialIndex = sprintf('Specify index of the material to crop or use NaN to crop all materials of the model');
            obj.BatchOpt.mibBatchTooltip.CropObjectsIncludeMask = sprintf('If the mask is present also crop out the model and save next to the images');
            obj.BatchOpt.mibBatchTooltip.SingleMaskObjectPerDataset = sprintf('Remove all other objects that may apper within the clipping box of the main detected object');
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');
            
            % add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{1};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    return;
                end
                
                obj.BatchOpt.MultipleProperty = 'Area';     % set the default MultipleProperty to area only
                
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptInput);
                
                % checks
                if strcmp(obj.BatchOpt.Property{1},'EndpointsLength') || strcmp(obj.BatchOpt.Property{1},'CurveLength')     % fix connectivity
                    obj.BatchOpt.Connectivity{1} = '8/26 connectivity';
                end
                
                batchModeSwitch = 1;
                obj.runStatAnalysis_Callback(batchModeSwitch);    % with the
                return;
            end
            
            %%
            
            guiName = 'mibStatisticsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % populate units combo box
            obj.View.handles.Units.String = {'pixels', obj.mibModel.I{obj.mibModel.Id}.pixSize.units};
            
            % set default parameters
            obj.intType = 1;                % index of the selected mode for the intensity mode
            obj.obj2DType = 1;              % index of the selected mode for the object mode
            obj.obj3DType = 1;              % index of the selected mode for the object mode
            obj.statProperties = {'Area'};  % list of properties to calculate
            obj.sortingDirection = 0;                % a variable to keep sorting status for columns
            obj.sortingColIndex = 2;        % default sort by value
            obj.indices = [];               % indices for selected rows
            obj.histLimits = [0 1];     % limits for the histogram
            obj.STATS = struct();
            obj.runId = [];
            obj.anisotropicVoxelsAgree = 0;     % warning dialog was shown or not
            
            obj.matlabVersion = ver('Matlab');
            obj.matlabVersion = str2double(obj.matlabVersion.Version);
            obj.updateWidgets();
            
            obj.childControllers = {};    % initialize child controllers
            obj.childControllersIds = {};
            
            if contIndex > 1
                contIndex = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial;
                obj.View.handles.Material.Value = contIndex;
            else
                obj.View.handles.Material.Value = 1;
            end
            
            obj.Material_Callback();
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateId', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));
            obj.listener{2} = addlistener(obj.mibModel, 'newDataset', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));
            obj.listener{3} = addlistener(obj.mibModel, 'showModel', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));
        end
        
        function closeWindow(obj)
            % function purgeControllers(obj, src, evnt)
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
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % via the notify 'syncBatch' event
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
            % 
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        function updateBatchOptFromGUI(obj, hObject)
            % function updateBatchOptFromGUI(obj, hObject)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % hObject: a handle to a widget of GUI
            
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, hObject);
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of the GUI
            
            %fprintf('childController:updateWidgets: %g\n', toc);
            % populate Material
            MaterialValue = obj.View.handles.Material.Value;
            targetList = {'Mask';'Exterior'};
            if obj.mibModel.getImageProperty('modelExist')
                materials = obj.mibModel.getImageProperty('modelMaterialNames');
                if obj.mibModel.I{obj.mibModel.Id}.modelType <= 255
                    targetList = [targetList; materials];
                else
                    targetList = ['Model'; targetList; materials];
                end
            end
            obj.View.handles.Material.String = targetList;
            
            if MaterialValue <= numel(targetList)
                obj.View.handles.Material.Value = MaterialValue;
            else
                obj.View.handles.Material.Value = 1;
            end
            if ~isempty(obj.runId)
                if obj.runId(1) == obj.mibModel.Id
                    if obj.mibModel.I{obj.mibModel.Id}.modelType <= 255
                        obj.View.handles.Material.Value = obj.runId(2) + 2;
                    else
                        if obj.runId(2) > 0
                            obj.View.handles.Material.Value = find(ismember(targetList, num2str(obj.runId(2)))==1);
                        else
                            obj.View.handles.Material.Value = obj.runId(2) + 3;
                        end
                    end
                end
            end
            obj.Material_Callback();
            
            % setting color channels popups
            colorChannels = obj.mibModel.getImageProperty('colors');
            colorChannelsList = cell([colorChannels, 1]);
            for i=1:colorChannels
                colorChannelsList{i} = sprintf('ColCh %d', i);
            end
            obj.View.handles.ColorChannel1.String = colorChannelsList;
            obj.View.handles.ColorChannel2.String = colorChannelsList;
            if numel(colorChannelsList) > 1
                obj.View.handles.ColorChannel2.Value = 2;
            else
                obj.View.handles.ColorChannel2.Value = 1;
            end
            % when only one color channel is shown select it
            slices = obj.mibModel.getImageProperty('slices');
            if numel(slices{3}) == 1
                colorChannelSelection = slices{3};
                obj.View.handles.ColorChannel1.Value = colorChannelSelection;
            else
                obj.View.handles.ColorChannel1.Value = slices{3}(1);
            end
            
            % update the table
            obj.enableStatTable();
            
            obj.BatchOpt.DatasetType(1) = obj.View.handles.DatasetType.String(obj.View.handles.DatasetType.Value);
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
            % @li 'mean' - calculate an average of all selected numbers
            % @li 'sum' - calculate a sum of all selected numbers
            % @li 'min' - find the minimum value of all selected numbers
            % @li 'max' - find the maximum value of all selected numbers
            % @li 'crop' - crop selected objects to a file or Matlab
            % @li 'hist' - show histogram distribution for the selected objects
            % @li 'newLabel', 'addLabel', 'removeLabel' - generate or update the MIB annotations
            % @li 'copyColumn' - copy selected column to the clipboard
            
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
                    parList = obj.View.handles.Property.String;
                    parList = parList{obj.View.handles.Property.Value};
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
                case 'copyColumn'
                    columnIds = unique(obj.indices(:,2));
                    d = data(:, columnIds);
                    num2clip(d);    % copy to clipboard
                    fprintf('Stats: %d rows were copied to the system clipboard\n', size(d,2));
                case {'newLabel', 'addLabel', 'removeLabel'}
                    if strcmp(parameter, 'newLabel')    % clear existing annotations
                        if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 0
                            button = questdlg(sprintf('!!! Warning !!!\n\nDo you want to overwrite the existing annotations?'), ...
                                'Overwrite annotations', 'Overwrite', 'Cancel', 'Cancel');
                            if strcmp(button, 'Cancel'); return; end
                        end
                        obj.mibModel.mibDoBackup('labels', 0);
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();
                    end
                    
                    addObjId = false;
                    addMaterialName = false;
                    materialName = '';
                    customText = '';
                    if ~strcmp(parameter, 'removeLabel')
                        prompts = {'Custom text:'; 'Add material name to the label'; 'Add object Id to the label'};
                        defAns = {''; false; false;};
                        dlgTitle = 'Add annotation settings';
                        options.WindowStyle = 'normal';       
                        options.PromptLines = [1, 1, 1];   
                        options.Title = 'Annotation labels settings:'; 
                        answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                        if isempty(answer); return; end 
                        customText = answer{1};
                        addMaterialName = answer{2};
                        addObjId = answer{3};
                    end
                    
                    property = obj.View.handles.Property.String{obj.View.handles.Property.Value};
                    if ~isempty(customText); materialName = [customText '_' materialName]; end
                    
                    if addMaterialName
                        materialName = [materialName obj.View.handles.Material.String{obj.View.handles.Material.Value} '_'];
                    end
                    colIds = unique(obj.indices(:,1));
                    labelList = repmat({[materialName property]}, [numel(colIds), 1]);
                    
                    if addObjId     % add indices of objects
                        noDecimails = numel(num2str(max(data(obj.indices(:,1)))));
                        if noDecimails <= 2
                            labelList = cellfun(@(x, y) sprintf('%s_%.2d', x, y), labelList, num2cell(data(colIds, 1)), 'UniformOutput', false);
                        elseif noDecimails == 3
                            labelList = cellfun(@(x, y) sprintf('%s_%.3d', x, y), labelList, num2cell(data(colIds, 1)), 'UniformOutput', false);                        
                        elseif noDecimails == 4
                            labelList = cellfun(@(x, y) sprintf('%s_%.4d', x, y), labelList, num2cell(data(colIds, 1)), 'UniformOutput', false);                        
                        elseif noDecimails == 5
                            labelList = cellfun(@(x, y) sprintf('%s_%.5d', x, y), labelList, num2cell(data(colIds, 1)), 'UniformOutput', false);
                        elseif noDecimails == 6
                            labelList = cellfun(@(x, y) sprintf('%s_%.6d', x, y), labelList, num2cell(data(colIds, 1)), 'UniformOutput', false);
                        elseif noDecimails == 7
                            labelList = cellfun(@(x, y) sprintf('%s_%.7d', x, y), labelList, num2cell(data(colIds, 1)), 'UniformOutput', false);          
                        else
                            labelList = cellfun(@(x, y) sprintf('%s_%.10d', x, y), labelList, num2cell(data(colIds, 1)), 'UniformOutput', false);          
                        end
                    end
                    
                    labelValues = data(colIds, 2);
                    positionList = arrayfun(@(index) data(index, 3), colIds);
                    positionList(:,2) = arrayfun(@(objId) obj.STATS(objId).Centroid(1), data(colIds, 1));
                    positionList(:,3) = arrayfun(@(objId) obj.STATS(objId).Centroid(2), data(colIds, 1));
                    positionList(:,4) = arrayfun(@(index) data(index, 4), colIds);
                    
                    if strcmp(parameter, 'removeLabel')
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(positionList);   % remove labels by position
                    else
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelList, positionList, labelValues);
                    end
                    obj.mibModel.mibShowAnnotationsCheck = 1;
                    
                    notify(obj.mibModel, 'updatedAnnotations');
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
        
        function updateSortingSettings(obj)
            % function updateSortingSettings(obj)
            % update settings for sorting the columns of the table
            % obj.sortingDirection
            % obj.sortingColIndex
            
            val = obj.View.handles.sortingPopup.Value;
            list = obj.View.handles.sortingPopup.String;
            switch list{val}
                case 'Value, ascent'
                    obj.sortingDirection = 1;
                    obj.sortingColIndex = 2;
                case 'Value, descent'
                    obj.sortingDirection = 0;
                    obj.sortingColIndex = 2;
                case 'ObjectID, ascent'
                    obj.sortingDirection = 1;
                    obj.sortingColIndex = 1;
                case 'ObjectID, descent'
                    obj.sortingDirection = 0;
                    obj.sortingColIndex = 1;
                case 'SliceNo, ascent'
                    obj.sortingDirection = 1;
                    obj.sortingColIndex = 3;
                case 'SliceNo, descent'
                    obj.sortingDirection = 0;
                    obj.sortingColIndex = 3;
                case 'TimePnt, ascent'
                    obj.sortingDirection = 1;
                    obj.sortingColIndex = 4;
                case 'TimePnt, descent'
                    obj.sortingDirection = 0;
                    obj.sortingColIndex = 4;
            end
            obj.sortBtn_Callback();
        end
        
        function Material_Callback(obj)
            % function Material_Callback(obj)
            % a callback for obj.View.handles.Material
            
            val = obj.View.handles.Material.Value;
            targetList = obj.View.handles.Material.String;
            obj.View.gui.Name = sprintf('"%s" stats...', targetList{val});
            
            if obj.mibModel.I{obj.mibModel.Id}.modelType <= 255
                obj.BatchOpt.MaterialIndex = num2str(val-2);
            else
                if val > 3
                    obj.BatchOpt.MaterialIndex = targetList{val};
                else
                    obj.BatchOpt.MaterialIndex = num2str(val-3);
                end
            end
        end
        
        function Property_Callback(obj)
            % function Property_Callback(obj)
            % a callback for obj.View.handles.Property
            
            list = obj.View.handles.Property.String;
            value = obj.View.handles.Property.Value;
            if strcmp(list{value},'Correlation')
                obj.View.handles.ColorChannel2.Enable = 'on';
            else
                obj.View.handles.ColorChannel2.Enable = 'off';
                if strcmp(list{value},'EndpointsLength') || strcmp(list{value},'CurveLength')
                    if obj.View.handles.Connectivity.Value == 1
                        msgbox('The connectivity parameter was changed from 4 to 8!','Connectivity changed','warn','modal')
                        obj.View.handles.Connectivity.Value = 2;
                        obj.BatchOpt.Connectivity{1} = '8/26 connectivity';
                    end
                end
                
                if strcmp(obj.BatchOpt.Mode{1}, 'Object') 
                    if strcmp(obj.BatchOpt.Shape{1}, 'Shape2D') 
                        obj.obj2DType = obj.View.handles.Property.Value;
                    else
                        obj.obj3DType = obj.View.handles.Property.Value;
                    end
                else
                    obj.intType = obj.View.handles.Property.Value;
                end
            end
            selectedProperty = list{value};
            
            % rename selectedProperty for intensity measurements
            if ismember(selectedProperty, {'SumIntensity', 'StdIntensity', 'MeanIntensity', 'MaxIntensity', 'MinIntensity'})
                colCh = obj.View.handles.ColorChannel1.Value;
                selectedProperty = sprintf('%s_Ch%d', selectedProperty, colCh);
            end
            
            if obj.BatchOpt.Multiple == 1
                % update table if possible
                if isfield(obj.STATS, selectedProperty)
                    data = zeros(numel(obj.STATS),4);
                    if numel(data) ~= 0
                        [data(:,2), data(:,1)] = sort(cat(1,obj.STATS.(selectedProperty)), 'descend');
                        w1 = obj.mibModel.getImageProperty('width');
                        h1 = obj.mibModel.getImageProperty('height');
                        d1 = obj.mibModel.getImageProperty('depth');
                        for row = 1:size(data,1)
                            pixelId = max([1 floor(numel(obj.STATS(data(row,1)).PixelIdxList)/2)]);  % id of the voxel to get a slice number
                            [~, ~, data(row,3)] = ind2sub([w1, h1, d1], ...
                                obj.STATS(data(row,1)).PixelIdxList(pixelId));
                        end
                        data(:, 4) = [obj.STATS(data(:,1)).TimePnt];
                    end
                    data = obj.sortBtn_Callback(data);
                    
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
            
            if obj.BatchOpt.Multiple == 0
                obj.BatchOpt.Property{1} = list{value};
            end
            
        end
        
        function radioButton_Callback(obj, hObject)
            % function radioButton_Callback(obj, hObject)
            % a callback for obj.View.handles.radioButton
            %
            % Parameters:
            % hObject: a handle to the object
            
            if obj.View.handles.Shape2D.Value == 1
                obj.BatchOpt.Shape{1} = 'Shape2D';
            else
                obj.BatchOpt.Shape{1} = 'Shape3D';
            end
            if obj.View.handles.Intensity.Value == 1
                obj.BatchOpt.Mode{1} = 'Intensity';
            else
                obj.BatchOpt.Mode{1} = 'Object';
            end
            
            if strcmp(obj.BatchOpt.Mode{1}, 'Intensity')  % intensity based statistics
                list ={'MinIntensity','MaxIntensity','MeanIntensity','StdIntensity','SumIntensity','Correlation'};
                obj.View.handles.ColorChannel1.Enable = 'on';
                obj.View.handles.Property.Value = obj.intType;
            else                            % object based statistics
                obj.View.handles.ColorChannel1.Enable = 'off';
                obj.View.handles.ColorChannel2.Enable = 'off';
                if strcmp(obj.BatchOpt.Shape{1}, 'Shape2D')
                    list = {'Area','ConvexArea','CurveLength','Eccentricity','EndpointsLength','EquivDiameter','EulerNumber',...
                        'Extent','FilledArea','FirstAxisLength','HolesArea','MajorAxisLength','MinorAxisLength','Orientation',...
                        'Perimeter','SecondAxisLength','Solidity'};
                    obj.View.handles.Property.Value = obj.obj2DType;
                else
                    if obj.matlabVersion >= 9.3
                        list ={'Volume', 'ConvexVolume', 'EndpointsLength','EquatorialEccentricity', 'EquivDiameter','Extent',...
                               'FilledArea','HolesArea','MajorAxisLength', 'MeridionalEccentricity','SecondAxisLength','Solidity',...
                               'SurfaceArea', 'ThirdAxisLength'};
                    else
                        list ={'Volume','EndpointsLength','EquatorialEccentricity','FilledArea','HolesArea','MajorAxisLength','MeridionalEccentricity','SecondAxisLength','ThirdAxisLength'};
                    end
                    obj.View.handles.Property.Value = obj.obj3DType;
                end
            end
            obj.View.handles.Property.String = list;
            hObject.Value = 1;
            
            if strcmp(hObject.Tag, 'Shape2D') 
                obj.BatchOpt.Property{1} = 'Area';  % update properties
                obj.BatchOpt.MultipleProperty = 'Area';  % update properties
                obj.BatchOpt.Multiple = false;
                obj.View.handles.Multiple.Value = 0;
                obj.View.handles.multipleBtn.Enable = 'off';
            elseif strcmp(hObject.Tag, 'Shape3D')
                obj.BatchOpt.Property{1} = 'Volume'; % update properties
                obj.BatchOpt.MultipleProperty = 'Volume';  % update properties
                obj.BatchOpt.Multiple = false;
                obj.View.handles.Multiple.Value = 0;
                obj.View.handles.multipleBtn.Enable = 'off';
                obj.Units_Callback();
            else
                obj.BatchOpt.Property{1} = obj.View.handles.Property.String{obj.View.handles.Property.Value};
            end
            obj.Property_Callback();
            %if obj.View.handles.Multiple.Value == 1;obj.Property_Callback(); end 
        end
        
        function highlightSelection(obj, object_list, mode, sliceNumbers)
            % function highlightSelection(obj, object_list, mode, sliceNumbers)
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
            
            if nargin < 4; sliceNumbers = []; end
            if nargin < 3
                mode = obj.View.handles.detailsPanel.SelectedObject.String;    % what to do with selected objects: Add, Remove, Replace
            end
            
            mode2 = obj.View.handles.Shape.SelectedObject.String;      % 2D/3D objects
            
            getDataOptions.blockModeSwitch = 0;
            [img_height, img_width, ~, img_depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);
            if strcmp(obj.BatchOpt.DatasetType{1}, '2D, Slice') && strcmp(mode2, '2D objects') || (strcmp(mode2, '2D objects') && numel(object_list)==1)
                tic
                currentSlice = obj.STATS(object_list(1)).Centroid(3);
                currentTime = obj.STATS(object_list(1)).TimePnt;
                getDataOptions.t = [currentTime, currentTime];
                
                selection_mask = zeros(img_height, img_width, 'uint8');
                coef = img_height*img_width*(currentSlice-1); % shift pixel indeces back into 2D space
                for i=1:numel(object_list)
                    selection_mask(obj.STATS(object_list(i)).PixelIdxList-coef) = 1;
                end
                
                % the Add and Remove mode work on the subset of the
                % dataset, to make it faster
                if strcmp(mode, 'Add') || strcmp(mode, 'Remove')
                    % get bounding box for the selected objects
                    bb = ceil(reshape([obj.STATS(object_list).BoundingBox], [6 numel(object_list)])');    % [index][x y z w h d]
                    xMin = min(bb(:,1));
                    xMax = max(bb(:,1)+bb(:,4)-1);
                    getDataOptions.x = [xMin xMax];
                    yMin = min(bb(:,2));
                    yMax = max(bb(:,2)+bb(:,5)-1);
                    getDataOptions.y = [yMin yMax];
                end
                
                if strcmp(mode,'Add')
                    selection = cell2mat(obj.mibModel.getData2D('selection', currentSlice, NaN, NaN, getDataOptions));
                    selection = bitor(selection_mask(yMin:yMax, xMin:xMax), selection);   % selection_mask | selection;
                    obj.mibModel.setData2D('selection', {selection}, currentSlice, NaN, NaN, getDataOptions);
                elseif strcmp(mode,'Remove')
                    curr_selection = cell2mat(obj.mibModel.getData2D('selection', currentSlice, NaN, NaN, getDataOptions));
                    curr_selection(selection_mask(yMin:yMax, xMin:xMax)==1) = 0;
                    obj.mibModel.setData2D('selection', {curr_selection}, currentSlice, NaN, NaN, getDataOptions);
                elseif strcmp(mode,'Replace')
                    if (strcmp(mode2,'2D objects') && numel(object_list)==1)
                        obj.mibModel.I{obj.mibModel.Id}.clearSelection();
                    end
                    obj.mibModel.setData2D('selection', {selection_mask}, currentSlice, NaN, NaN, getDataOptions);
                end
                toc
            else
                if numel(object_list) > 1 || strcmp(mode, 'Replace')
                    wb = waitbar(0,'Highlighting selected objects...','Name','Highlighting');
                elseif numel(obj.STATS(object_list(1)).PixelIdxList) > 1000000
                    wb = waitbar(0,'Highlighting selected objects...','Name','Highlighting');
                end
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
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                    obj.mibModel.I{obj.mibModel.Id}.createModel(modelType);
                else
                    maskClass = 'uint8';
                end
                
                for t = timePointsUnuque
                    objects = object_list(ic==index);
                    if ~strcmp(mode, 'obj2model')
                        getDataOptions.PixelIdxList = vertcat(obj.STATS(objects).PixelIdxList);
                        
                        if strcmp(mode,'Add')
                            dataset = zeros(size(getDataOptions.PixelIdxList), maskClass)+1;
                            obj.mibModel.setData3D('selection', dataset, ...
                                t, NaN, 0, getDataOptions);    % selection | selection_mask
                        elseif strcmp(mode,'Remove')
                            dataset = zeros(size(getDataOptions.PixelIdxList), maskClass);
                            obj.mibModel.setData3D('selection', dataset, ...
                                t, NaN, 0, getDataOptions);    % selection | selection_mask
                        elseif strcmp(mode,'Replace')
                            dataset = zeros(size(getDataOptions.PixelIdxList), maskClass)+1;
                            obj.mibModel.setData3D('selection', dataset, ...
                                t, NaN, 0, getDataOptions);    % selection | selection_mask
                        end
                        
                    else    % obj2model
                        selection_mask = zeros([img_height, img_width, img_depth], maskClass);
                        objects = object_list(ic==index);
                        
                        if strcmp(mode2, '2D objects')
                            objIndex = zeros([max(sliceNumbers), 1]); % define index of the object to assign in the resulting model
                            shiftValue = 1;  % define the shift
                        else
                            objIndex = 0;   % define index of the object to assign in the resulting model
                            shiftValue = 1; % define the shift
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
                        
                        % the Add and Remove mode work on the subset of the
                        % dataset, to make it faster
                        if strcmp(mode, 'Add') || strcmp(mode, 'Remove')
                            % get bounding box for the selected objects
                            bb = ceil(reshape([obj.STATS(objects).BoundingBox], [6 numel(objects)])');    % [index][x y z w h d]
                            xMin = min(bb(:,1));
                            xMax = max(bb(:,1)+bb(:,4)-1);
                            getDataOptions.x = [xMin xMax];
                            yMin = min(bb(:,2));
                            yMax = max(bb(:,2)+bb(:,5)-1);
                            getDataOptions.y = [yMin yMax];
                            zMin = min(bb(:,3));
                            zMax = max(bb(:,3)+bb(:,6)-1);
                            getDataOptions.z = [zMin zMax];
                        end
                        obj.mibModel.setData3D('model', {selection_mask}, t, NaN, NaN, getDataOptions);
                    end
                    index = index + 1;
                    if exist('wb', 'var'); waitbar(index/numel(timePointsUnuque), wb); end
                    
                end
                if exist('wb', 'var'); delete(wb); end
                
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
            if xy(1,2) > ylim(2); return; end   % mouse click was too far from the plot
            if xy(1,2) < ylim(1); return; end   % mouse click was too far from the plot
            
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
        
        function Units_Callback(obj)
            % function Units_Callback(obj)
            % callback for change of the unitCombo combo
            curValue = obj.View.handles.Units.String{obj.View.handles.Units.Value};
            
            pixSize = obj.mibModel.getImageProperty('pixSize');
            if ((pixSize.x ~= pixSize.z || pixSize.y ~= pixSize.z) && ~strcmp(curValue, 'pixels') && obj.View.handles.Shape3D.Value == 1) && obj.anisotropicVoxelsAgree == 0
                answer = questdlg(sprintf('!!! Warning !!!\n\nPlease note that calculation of certain 3D properties, such as\nMeridionalEccentricity, EquatorialEccentricity, MajorAxisLength, SecondAxisLength, ThirdAxisLength, EquivDiameter, SurfaceArea\nrequires isotropic voxels!'),...
                    'Attention!!!', 'Confirm', 'Cancel', 'Confirm');
                if strcmp(answer, 'Cancel')
                    obj.View.handles.Units.Value = 1;
                    return;
                end
                obj.anisotropicVoxelsAgree = 1;
            end
            obj.BatchOpt.Units{1} = curValue;
        end
        
        function multipleBtn_Callback(obj)
            % function multipleBtn_Callback(obj)
            % a callback for obj.View.handles.multipleBtn, selecting multiple
            % properties for calculation
            
            obj3d = 1;
            if obj.View.handles.Shape2D.Value == 1
                obj3d = 0;
            end

            if isempty(obj.BatchOpt.MultipleProperty)
                propertyList = obj.BatchOpt.Property(1);
            else
                propertyList = arrayfun(@(x) strtrim(x), split(obj.BatchOpt.MultipleProperty, ';'));
                propertyList(~ismember(propertyList, [obj.availableProperties2D, obj.availableProperties3D, obj.availablePropertiesInt])) = [];    % remove wrongly named properties
            end
            res = mibMaskStatsProps(propertyList, obj3d);
            
            if ~isempty(res)
                propertyList = sort(res);
                customProps = {'CurveLength','EndpointsLength'};
                if sum(ismember(propertyList, customProps)) > 1                    
                    if obj.View.handles.Connectivity.Value == 1
                        msgbox('The connectivity parameter was changed from 4 to 8!', 'Connectivity changed', 'warn', 'modal');
                        obj.View.handles.Connectivity.Value = 2;
                        obj.BatchOpt.Connectivity{1} = '8/26 connectivity';
                    end
                end
                
                list = obj.View.handles.Property.String;
                index = find(ismember(list, propertyList{1})==1);
                if isempty(index)
                    if obj.View.handles.Object.Value == 1    % switch from the object to intensity mode
                        obj.View.handles.Intensity.Value = 1;
                    else                                        % switch from the intensity to the object mode
                        obj.View.handles.Object.Value = 1;
                    end
                    obj.radioButton_Callback(obj.View.handles.Object);
                    list = obj.View.handles.Property.String;
                    index = find(ismember(list, propertyList{1})==1);
                    obj.View.handles.Property.Value = index(1);
                else
                    obj.View.handles.Property.Value = index(1);
                end
                obj.BatchOpt.Property(1) = propertyList(1);
                obj.BatchOpt.MultipleProperty = sprintf('%s; ', propertyList{:});
                obj.BatchOpt.MultipleProperty = obj.BatchOpt.MultipleProperty(1:end-2);     % remove tailoring "; "
            end
        end
        
        function Multiple_Callback(obj)
            % function Multiple_Callback(obj)
            % callback for press of Multiple checkbox
            val = obj.View.handles.Multiple.Value;
            if val == 1
                obj.BatchOpt.Multiple = true;
                obj.View.handles.multipleBtn.Enable = 'on';
            else
                obj.BatchOpt.Multiple = false;
                obj.View.handles.multipleBtn.Enable = 'off';
            end
        end
        
        function exportButton_Callback(obj, BatchModeSwitch)
            % function exportButton_Callback(obj, BatchModeSwitch)
            % a callback for obj.View.handles.exportButton
            % Parameters:
            % BatchModeSwitch: a logical switch indicating using the
            % function from the batch mode
            
            global mibPath;
            if nargin < 2; BatchModeSwitch = 0; end
            
            fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            if BatchModeSwitch == 0
                % export Statistics to Matlab or Excel
                choice = 'Save as...';
                if ~isdeployed
                    choice =  questdlg('Would you like to save results?', 'Export', 'Save as...', 'Export to Matlab', 'Cancel', 'Save as...');
                    if strcmp(choice, 'Cancel'); return; end
                end
                
                filterIndex = 0;
                if strcmp(choice, 'Save as...')
                    if isempty(fn_out)
                        fn_out = obj.mibModel.myPath;
                    else
                        [fn_out, name, ~] = fileparts(fn_out);
                        fn_out = fullfile(fn_out, [name '_analysis']);
                    end
                    [filename, Path, filterIndex] = uiputfile(...
                        {'*.xls',  'Excel format (*.xls)'; ...
                        '*.csv',  'Comma-separated values (*.csv)'; ...
                        '*.mat',  'Matlab format (*.mat)'; ...
                        '*.*',  'All Files (*.*)'}, ...
                        'Save as...',fn_out);
                    if isequal(filename, 0); return; end
                    [~, obj.BatchOpt.ExportFilename, Extension] = fileparts(filename);
                    obj.BatchOpt.ExportResultsTo(1) = obj.BatchOpt.ExportResultsTo{2}(filterIndex+2);
                else
                    obj.BatchOpt.ExportResultsTo{1} = choice;
                    answer = mibInputDlg({mibPath}, ...
                        sprintf('Please name of the variable for the export:'),...
                            'Export to Matlab', 'MIB_stats');
                    if isempty(answer); return; end
                    obj.BatchOpt.ExportFilename = answer{1};
                end
            else
                filterIndex = find(ismember(obj.BatchOpt.ExportResultsTo{2}, obj.BatchOpt.ExportResultsTo{1})) - 2;
                if isempty(fn_out)
                    Path = obj.mibModel.myPath;
                else
                    Path = fileparts(fn_out);
                end
                if filterIndex > 0
                    Extension = obj.BatchOpt.ExportResultsTo{1}(end-4:end-1);
                end
            end
            
            OPTIONS.frame = obj.BatchOpt.DatasetType{1};
            OPTIONS.mode = obj.BatchOpt.Shape{1};   % 2d/3d objects
            OPTIONS.connectivity = obj.BatchOpt.Connectivity{1};   
            OPTIONS.colorChannel1 = obj.BatchOpt.ColorChannel1{1};
            OPTIONS.colorChannel2 = obj.BatchOpt.ColorChannel2{1};
            OPTIONS.units = obj.BatchOpt.Units{1};
            
            if strcmp(obj.BatchOpt.MaterialIndex, '-1') %  Mask 
                OPTIONS.type = 'Mask';
            elseif strcmp(obj.BatchOpt.MaterialIndex, '0')  % Exterior 
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
                if ~strcmp(obj.BatchOpt.MaterialIndex, '-2')  %
                    OPTIONS.material_id = sprintf('%s (%s)', obj.BatchOpt.MaterialIndex, obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{str2double(obj.BatchOpt.MaterialIndex)});
                else
                    OPTIONS.material_id = 'Full model';
                end
            end
            
            if strcmp(OPTIONS.frame, '2D, Slice')
                OPTIONS.slicenumber = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
            else
                OPTIONS.slicenumber = 0;
            end
            
            %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
            curInt = get(0, 'DefaulttextInterpreter');
            set(0, 'DefaulttextInterpreter', 'none');
            
            if strcmp(obj.BatchOpt.ExportResultsTo{1}, 'Export to Matlab')
                fprintf('"%s" structure with results was created in the Matlab workspace\n', obj.BatchOpt.ExportFilename);
                STATSOUT = obj.STATS;
                STATSOUT(1).OPTIONS = OPTIONS;
                assignin('base', obj.BatchOpt.ExportFilename, STATSOUT);
            elseif ismember(obj.BatchOpt.ExportResultsTo{1}, obj.BatchOpt.ExportResultsTo{2}(3:5))
                if obj.BatchOpt.ExportFilename(1) ~= filesep; obj.BatchOpt.ExportFilename = [filesep obj.BatchOpt.ExportFilename]; end  % add slash before the filename
                fn = [Path, obj.BatchOpt.ExportFilename Extension];
                if obj.BatchOpt.showWaitbar; wb = waitbar(0,sprintf('%s\nPlease wait...',fn), 'Name', 'Saving the results', 'WindowStyle', 'modal'); end
                Path2 = fileparts(fn);
                if exist(Path2, 'dir') == 0; mkdir(Path2); end  % create a new directory
                if exist(fn, 'file') == 2;  delete(fn);  end    % delete exising file
                
                if obj.BatchOpt.showWaitbar; waitbar(0.2,wb); end
                if filterIndex == 3     % save as mat file
                    STATS = obj.STATS; %#ok<NASGU>
                    save(fn, 'OPTIONS','STATS');
                elseif filterIndex == 1  ||  filterIndex == 2 % save as Excel file or CSV file
                    STATS = obj.STATS;
                    warning('off', 'MATLAB:xlswrite:AddSheet');
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
                    s(5,1) = {sprintf('CALCULATED IN %s', upper(obj.BatchOpt.Units{1}))};
                    if ~strcmp(OPTIONS.units, 'pixels') && strcmp(OPTIONS.mode, '3D objects') && pixSize.x ~= pixSize.z
                        s(5,6) = {sprintf('ATTENTION CALCULATION OF SOME PARAMETERS (such as Eccentricity, Lengths, Diameter, Surface Area) IN %s REQUIRES ISOTROPIC PIXELS!!!', upper(obj.BatchOpt.Units{1}))};
                    end
                    
                    start=9;
                    s(7,1) = {'Results:'};
                    s(8,1) = {'ObjID'};
                    s(8,3) = {'Centroid px'};
                    s(9,2) = {'X'};
                    s(9,3) = {'Y'};
                    s(9,4) = {'Z'};
                    s(8,5) = {'TimePnt'};
                    noObj = numel(STATS);
                    s(start+1:start+noObj,1) = num2cell(1:noObj);
                    s(start+1:start+noObj,2:4) = num2cell(cat(1,STATS.Centroid));
                    s(start+1:start+noObj,5) = num2cell(cat(1,STATS.TimePnt));
                    
                    STATS = rmfield(STATS, 'Centroid');
                    STATS = rmfield(STATS, 'PixelIdxList');
                    STATS = rmfield(STATS, 'TimePnt');
                    STATS = rmfield(STATS, 'BoundingBox');
                    
                    fieldNames = fieldnames(STATS);
                    fieldNamesForTitles = fieldNames;
                    correlationId = find(ismember(fieldNamesForTitles, 'Correlation'));
                    if ~isempty(correlationId)
                        fieldNamesForTitles(correlationId) = {[fieldNamesForTitles{correlationId} ' ' OPTIONS.colorChannel1 '/' OPTIONS.colorChannel2]};
                    else
                        fieldNamesForTitles = fieldNames;
                    end
                    s(8,6:5+numel(fieldNames)) = fieldNamesForTitles;
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
                    if obj.BatchOpt.showWaitbar; waitbar(0.7,wb); end
                    if filterIndex == 1
                        xlswrite2(fn, s, 'Sheet1', 'A1');
                    else
                        if verLessThan('Matlab','9.6')  % before R2019a
                            fid = fopen(fn, 'w');
                            for i=1:start
                                for j=1:5+numel(fieldNames)
                                    fprintf(fid, '%s,', s{i,j});
                                end
                                fprintf(fid, '\n');
                            end
                            fclose(fid);
                            dlmwrite(fn, cell2mat(s(start+1:end,:)),'delimiter', ',', '-append');
                        else
                            writecell(s, fn);
                        end
                    end
                end
                if obj.BatchOpt.showWaitbar; waitbar(1,wb); delete(wb); end
                disp(['MIB: statistics saved to ' fn]);
            end
            set(0, 'DefaulttextInterpreter', curInt);
        end
        
        function runStatAnalysis_Callback(obj, BatchModeSwitch)
            % function runStatAnalysis_Callback(obj)
            % start quantification analysis
            %
            % Parameters:
            % BatchModeSwitch: logical switch, whether or not the batch mode is used
            
            tic
            if nargin < 2; BatchModeSwitch = 0; end     
            selectedProperty = obj.BatchOpt.Property{1};
            
            if obj.BatchOpt.Multiple == 1
                property = arrayfun(@(x) strtrim(x), split(obj.BatchOpt.MultipleProperty, ';'));
                property(~ismember(property, [obj.availableProperties2D, obj.availableProperties3D, obj.availablePropertiesInt])) = [];    % remove wrongly named properties
                
                if isempty(property)
                    errordlg(sprintf('!!! Error !!!\n\nYou have selected calculation of multiple properties; but none of them is selected!\nPlease press the Define properties button to make selection'), 'Missing properties');
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
            else
                property = cellstr(selectedProperty);
                if strcmp(obj.BatchOpt.Mode{1}, 'Object') && strcmp(obj.BatchOpt.Shape{1}, 'Shape2D') 
                    if ismember(selectedProperty, obj.availableProperties2D) == 0
                        errordlg(sprintf('!!! Error !!!\nSelected property "%s" is not available for the 2D objects', selectedProperty), 'Wrong property name');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                elseif strcmp(obj.BatchOpt.Mode{1}, 'Object') && strcmp(obj.BatchOpt.Shape{1}, 'Shape3D') 
                    if ismember(selectedProperty, obj.availableProperties3D) == 0
                        errordlg(sprintf('!!! Error !!!\nSelected property "%s" is not available for the 3D objects', selectedProperty), 'Wrong property name');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                end
            end
            
            if obj.BatchOpt.Multiple == 1
                colorChannel = 1:obj.mibModel.I{obj.mibModel.Id}.colors;
            else
                colorChannel = str2double(obj.BatchOpt.ColorChannel1{1}(6:end));
            end
            colorChannel1 = str2double(obj.BatchOpt.ColorChannel1{1}(6:end)); % for correlation
            colorChannel2 = str2double(obj.BatchOpt.ColorChannel2{1}(6:end)); % for correlation
            
            selectedMaterial = str2double(obj.BatchOpt.MaterialIndex);
            % for models <= 255:          -1=Mask; 0=Ext; 1-1st material  ...
            % for models > 255: -2=Model; -1=Mask; 0=Ext; 1-1st material, 2-second selected material...
            
            if selectedMaterial ~= -1    % not mask, i.e. model
                if obj.mibModel.getImageProperty('modelExist') == 0
                    errordlg(sprintf('The model is not detected!\n\nPlease create a new model using:\nMenu->Models->New model'),'Missing model');
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
                
                list = obj.mibModel.getImageProperty('modelMaterialNames');
                
                if selectedMaterial == 0
                    materialName = 'Exterior';
                elseif selectedMaterial == -2
                    materialName = 'Model';
                    selectedMaterial = NaN;     % rename selectedMaterial to NaN to obtain all materials using getData methods
                else
                    if obj.mibModel.I{obj.mibModel.Id}.modelType < 256
                        if selectedMaterial>numel(list)
                            errordlg(sprintf('!!! Error !!!\n\nThe wrong material index;\nfor the current model it should be below %d', numel(list)+1), 'Wrong material index');
                            return
                        end
                        materialName = list{selectedMaterial};
                    else
                        materialName = obj.BatchOpt.MaterialIndex;
                    end
                end
                if obj.BatchOpt.showWaitbar
                    if numel(property) == 1
                        wb = waitbar(0,sprintf('Calculating "%s" of %s for %s\nMaterial: "%s"\nPlease wait...',property{1}, obj.BatchOpt.Shape{1}, obj.BatchOpt.DatasetType{1}, materialName),'Name', 'Shape statistics...','WindowStyle','modal');
                    else
                        wb = waitbar(0,sprintf('Calculating multiple parameters of %s for %s\nMaterial: "%s"\nPlease wait...', obj.BatchOpt.Shape{1}, obj.BatchOpt.DatasetType{1}, materialName),'Name','Shape statistics...','WindowStyle','modal');
                    end
                end
            else    % mask
                if obj.mibModel.getImageProperty('maskExist') == 0
                    errordlg(sprintf('The Mask is not detected!\n\nPlease create a new Mask using:\n1.Draw the mask with Brush\n2. Select Segmentation panel->Add to->Mask\n3. Press the "A" shortcut to add the drawn area to the Mask layer'),'Missing model');
                    notify(obj.mibModel, 'stopProtocol');
                    return;
                end
                if obj.BatchOpt.showWaitbar
                    if numel(property) == 1
                        wb = waitbar(0,sprintf('Calculating "%s" of %s for %s\n Material: Mask\nPlease wait...',property{1}, obj.BatchOpt.Shape{1}, obj.BatchOpt.DatasetType{1}),'Name','Shape statistics...','WindowStyle','modal');
                    else
                        wb = waitbar(0,sprintf('Calculating multiple parameters of %s for %s\n Material: Mask\nPlease wait...',obj.BatchOpt.Shape{1}, obj.BatchOpt.DatasetType{1}),'Name','Shape statistics...','WindowStyle','modal');
                    end
                end
            end
            
            getDataOptions.blockModeSwitch = 0;
            [img_height, img_width, ~, img_depth, img_time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, getDataOptions);
            
            t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
            t2 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
            if strcmp(obj.BatchOpt.DatasetType{1}, '4D, Dataset')
                t1 = 1;
                t2 = img_time;
            end
            
            property{end+1} = 'PixelIdxList';
            property{end+1} = 'Centroid';
            property{end+1} = 'TimePnt';
            property{end+1} = 'BoundingBox';
            
            %obj.STATS = cell2struct(cell(size(property)), property, 2);
            %obj.STATS = orderfields(obj.STATS);
            %obj.STATS(1) = [];
            
            obj.STATS = [];
            intProps = {'SumIntensity', 'StdIntensity', 'MeanIntensity', 'MaxIntensity', 'MinIntensity'};
            
            pixSize = obj.mibModel.getImageProperty('pixSize');
            
            for t=t1:t2
                if strcmp(obj.BatchOpt.Shape{1}, 'Shape3D')
                    if strcmp(obj.BatchOpt.DatasetType{1}, '2D, Slice')    % take only objects that are shown in the current slice
                        if obj.BatchOpt.showWaitbar; delete(wb); end
                        msgbox(sprintf('CANCELED!\nThe Shown slice with 3D Mode is not implemented!'),'Error!','error','modal');
                        notify(obj.mibModel, 'stopProtocol');
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
                    
                    if strcmp(obj.BatchOpt.Connectivity{1}, '4/6 connectivity')
                        conn = 6;
                    else
                        conn = 26;
                    end
                    
                    if obj.mibModel.I{obj.mibModel.Id}.orientation ~= 4 && obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch == 1
                        if obj.BatchOpt.showWaitbar; delete(wb); end
                        warndlg(sprintf('!!! Warning !!!\n\nThe block mode is only compatible with the XY orientation of the dataset\nPlease switch the orientation to XY or disable the block mode'),'Wrong orientation');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                    getDataOptions.blockModeSwitch = obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch;
                    if selectedMaterial == -1
                        img = cell2mat(obj.mibModel.getData3D('mask', t, 4, 0, getDataOptions));
                    else
                        img = cell2mat(obj.mibModel.getData3D('model', t, 4, selectedMaterial, getDataOptions));
                    end
                    
                    if sum(ismember(property, 'HolesArea')) > 0
                        img = imfill(img, conn, 'holes') - img;
                    end
                    
                    if obj.mibModel.I{obj.mibModel.Id}.modelType < 256 || ~isnan(selectedMaterial)
                        CC = bwconncomp(img, conn);
                        if CC.NumObjects == 0
                            continue;
                        end
                    else
                        CC = img;
                        imgSize = size(img);
                        clear img;
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0.05,wb); end
                    
                    % calculate common properties
                    STATS = regionprops(CC, {'PixelIdxList', 'Centroid', 'BoundingBox'}); %#ok<*PROP>
                    if isnan(selectedMaterial)   
                        % remove empty entries for models with more than
                        % 255 materials
                        emptyIndeces = find(arrayfun(@(STATS) isempty(STATS.PixelIdxList), STATS));
                        STATS(emptyIndeces) = [];
                        CC = struct();
                        CC.PixelIdxList = {STATS(:).PixelIdxList};
                        CC.NumObjects = numel(CC.PixelIdxList);
                        CC.ImageSize = imgSize;
                        CC.Connectivity = conn;
                    end
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
                    if obj.BatchOpt.showWaitbar; waitbar(0.1,wb); end
                    % calculate matlab standard shape properties
                    prop1 = property(ismember(property, 'HolesArea'));
                    if ~isempty(prop1)
                        STATS2 = regionprops(CC, 'Area');
                        [STATS.HolesArea] = STATS2.Area;
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0.2,wb); end
                    
                    % calculate Eccentricity for 3D objects
                    prop1 = property(ismember(property, {'MeridionalEccentricity', 'EquatorialEccentricity'}));
                    if ~isempty(prop1)
                        STATS2 = regionprops3mib(CC, 'Eccentricity');
                        if sum(ismember(property, 'MeridionalEccentricity')) > 0
                            [STATS.MeridionalEccentricity] = deal(STATS2.MeridionalEccentricity);
                        end
                        if sum(ismember(property,'EquatorialEccentricity')) > 0
                            [STATS.EquatorialEccentricity] = deal(STATS2.EquatorialEccentricity);
                        end
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0.3,wb); end
                    % calculate MajorAxisLength
                    prop1 = property(ismember(property, 'MajorAxisLength'));
                    if ~isempty(prop1)
                        STATS2 = regionprops3mib(CC, 'MajorAxisLength');
                        [STATS.MajorAxisLength] = deal(STATS2.MajorAxisLength);
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0.4,wb); end
                    % calculate 'SecondAxisLength', 'ThirdAxisLength'
                    prop1 = property(ismember(property, {'SecondAxisLength', 'ThirdAxisLength'}));
                    if ~isempty(prop1)
                        STATS2 = regionprops3mib(CC, 'AllAxes');
                        if sum(ismember(property,'SecondAxisLength')) > 0
                            [STATS.SecondAxisLength] = deal(STATS2.SecondAxisLength);
                        end
                        if sum(ismember(property,'ThirdAxisLength')) > 0
                            [STATS.ThirdAxisLength] = deal(STATS2.ThirdAxisLength);
                        end
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0.5,wb); end
                    % calculate EndpointsLength for lines
                    prop1 = property(ismember(property, 'EndpointsLength'));
                    if ~isempty(prop1)
                        STATS3 = regionprops(CC, 'PixelList');
                        if strcmp(obj.BatchOpt.Units{1}, 'pixels')
                            xPix = 1;
                            yPix = 1;
                            zPix = 1;
                        else
                            xPix = pixSize.x;
                            yPix = pixSize.y;
                            zPix = pixSize.z;
                        end
                        
                        for objId=1:numel(STATS3)
                            minZ = STATS3(objId).PixelList(1,3);
                            maxZ = STATS3(objId).PixelList(end,3);
                            minPoints = STATS3(objId).PixelList(STATS3(objId).PixelList(:,3)==minZ,:);   % find points on the starting slice
                            minPoints = [minPoints(1,1:2); minPoints(end,1:2)];  % take 1st and last point
                            maxPoints = STATS3(objId).PixelList(STATS3(objId).PixelList(:,3)==maxZ,:);   % find points on the ending slice
                            maxPoints = [maxPoints(1,1:2); maxPoints(end,1:2)];  % take 1st and last point
                            
                            DD = sqrt( bsxfun(@plus,sum(minPoints.^2,2),sum(maxPoints.^2,2)') - 2*(minPoints*maxPoints') );
                            maxVal = max(DD(:));
                            [row, col] = find(DD == maxVal,1);
                            STATS3(objId).EndpointsLength = sqrt(...
                                ((minPoints(row,1) - maxPoints(col,1))*xPix)^2 + ...
                                ((minPoints(row,2) - maxPoints(col,2))*yPix)^2 + ...
                                ((minZ - maxZ)*zPix)^2 );
                        end
                        [STATS.EndpointsLength] = deal(STATS3.EndpointsLength);
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0.6,wb); end
                    
                    % calculate Intensities
                    prop1 = property(ismember(property, intProps));
                    if ~isempty(prop1)
                        for i = 1:numel(colorChannel)
                            img = squeeze(cell2mat(obj.mibModel.getData3D('image', t, 4, colorChannel(i), getDataOptions)));
                            STATS2 = regionprops(CC, img, 'PixelValues');
                            % convert to double
                            vals = arrayfun(@(x) double(x.PixelValues), STATS2, 'UniformOutput', false);
                            STATS2 = cell2struct(vals', {'PixelValues'});
                            if sum(ismember(property, 'MinIntensity')) > 0
                                calcVal = cellfun(@min, struct2cell(STATS2),'UniformOutput', false);
                                fieldName = sprintf('MinIntensity_Ch%d', colorChannel(i));
                                [STATS.(fieldName)] = calcVal{:};
                            end
                            if sum(ismember(property, 'MaxIntensity')) > 0
                                calcVal = cellfun(@max, struct2cell(STATS2),'UniformOutput', false);
                                fieldName = sprintf('MaxIntensity_Ch%d', colorChannel(i));
                                [STATS.(fieldName)] = calcVal{:};
                            end
                            if sum(ismember(property, 'MeanIntensity')) > 0
                                calcVal = cellfun(@mean, struct2cell(STATS2),'UniformOutput', false);
                                fieldName = sprintf('MeanIntensity_Ch%d', colorChannel(i));
                                [STATS.(fieldName)] = calcVal{:};
                            end
                            if sum(ismember(property, 'SumIntensity')) > 0
                                calcVal = cellfun(@sum, struct2cell(STATS2),'UniformOutput', false);
                                fieldName = sprintf('SumIntensity_Ch%d', colorChannel(i));
                                [STATS.(fieldName)] = calcVal{:};
                            end
                            if sum(ismember(property, 'StdIntensity')) > 0
                                calcVal = cellfun(@std2, struct2cell(STATS2),'UniformOutput', false);
                                fieldName = sprintf('StdIntensity_Ch%d', colorChannel(i));
                                [STATS.(fieldName)] = calcVal{:};
                            end
                        end
                    end
                    
                    if obj.BatchOpt.showWaitbar; waitbar(0.7, wb); end
                    prop1 = property(ismember(property, {'ConvexVolume', 'EquivDiameter','Extent',...
                        'Solidity','SurfaceArea'}));
                    if ~isempty(prop1)
                        STATS2 = table2struct(regionprops3(CC, prop1));
                        fieldNames = fieldnames(STATS2);
                        for i=1:numel(fieldNames)
                            [STATS.(fieldNames{i})] = STATS2.(fieldNames{i});
                        end
                    end
                    
                    if obj.BatchOpt.showWaitbar; waitbar(0.8,wb); end
                    % calculate correlation between channels
                    prop1 = property(ismember(property, 'Correlation'));
                    if ~isempty(prop1)
                        img = cell2mat(obj.mibModel.getData3D('image', t, 4, 0, getDataOptions));
                        img1 = squeeze(img(:,:,colorChannel1,:));
                        img2 = squeeze(img(:,:,colorChannel2,:));
                        clear img;
                        for object=1:numel(STATS)
                            STATS(object).Correlation = corr2(img1(STATS(object).PixelIdxList), img2(STATS(object).PixelIdxList));
                        end
                    end
                    [STATS.TimePnt] = deal(t);  % add time points
                    
                    % recalculate to units if needed
                    if ~strcmp(obj.BatchOpt.Units{1}, 'pixels')
                        fieldNames = fieldnames(STATS);
                        for i=1:numel(fieldNames)
                            switch fieldNames{i}
                                case {'Volume', 'FilledArea', 'ConvexVolume', 'HolesArea'}
                                    STATSTEMP = cell2struct(num2cell([STATS.(fieldNames{i})]* pixSize.x * pixSize.y * pixSize.z), (fieldNames{i}),1);
                                    [STATS.(fieldNames{i})] = STATSTEMP.(fieldNames{i});
                                case {'MajorAxisLength','SecondAxisLength','ThirdAxisLength','EquivDiameter'}
                                    STATSTEMP = cell2struct(num2cell([STATS.(fieldNames{i})] * (pixSize.x + pixSize.y)/2), (fieldNames{i}),1);
                                    [STATS.(fieldNames{i})] = STATSTEMP.(fieldNames{i});
                                case 'SurfaceArea'
                                    STATSTEMP = cell2struct(num2cell([STATS.(fieldNames{i})] * (pixSize.x + pixSize.y)/2 * pixSize.z), (fieldNames{i}),1);
                                    [STATS.(fieldNames{i})] = STATSTEMP.(fieldNames{i});
                            end
                        end
                    end
                    
                    % recalculate PixelIdxList to the full dataset
                    if getDataOptions.blockModeSwitch == 1
                        [yMin, yMax, xMin, xMax, zMin, zMax] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage(4);
                        convertPixelOpt.y = [yMin yMax]; % y-dimensions of the cropped dataset
                        convertPixelOpt.x = [xMin xMax]; % x-dimensions of the cropped dataset
                        convertPixelOpt.z = [zMin, zMax]; % z-dimensions of the cropped dataset
                        for ooId = 1:CC.NumObjects
                            STATS(ooId).PixelIdxList = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(STATS(ooId).PixelIdxList, convertPixelOpt);
                            % recalculate centroids
                            STATS(ooId).Centroid(1) = STATS(ooId).Centroid(1) + xMin - 1;
                            STATS(ooId).Centroid(2) = STATS(ooId).Centroid(2) + yMin - 1;
                            % recalculate bounding boxes
                            STATS(ooId).BoundingBox(1)= STATS(ooId).BoundingBox(1) + xMin - 1;
                            STATS(ooId).BoundingBox(2)= STATS(ooId).BoundingBox(2) + yMin - 1;
                        end
                    end
                    if isempty(obj.STATS)
                        obj.STATS = STATS;
                        obj.STATS = orderfields(STATS');
                    else
                        obj.STATS = [obj.STATS orderfields(STATS')];
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(0.95,wb); end
                else    % ---------------- 2D objects -------------------
                    if strcmp(obj.BatchOpt.Connectivity{1}, '4/6 connectivity')
                        conn = 4;
                    else
                        conn = 8;
                    end
                    
                    % calculate statistics in XY plane
                    orientation = obj.mibModel.getImageProperty('orientation');
                    
                    if strcmp(obj.BatchOpt.DatasetType{1}, '2D, Slice')
                        start_id = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
                        end_id = start_id;
                    else
                        start_id = 1;
                        end_id = obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(orientation);
                    end
                    
                    customProps = {'EndpointsLength','CurveLength','HolesArea'};
                    shapeProps = {'Solidity', 'Perimeter', 'Orientation', 'MinorAxisLength', 'MajorAxisLength', 'FilledArea', 'Extent', 'EulerNumber',...
                        'EquivDiameter', 'Eccentricity', 'ConvexArea', 'Area'};
                    shapeProps3D = {'FirstAxisLength','SecondAxisLength'};     % these properties are calculated by regionprops3mib
                    intCustomProps = 'Correlation';
                    commonProps = {'PixelIdxList', 'Centroid', 'BoundingBox'};
                    
                    getDataOptions.t = [t t];
                    getDataOptions.blockModeSwitch = 0;
                    for lay_id=start_id:end_id
                        if obj.BatchOpt.showWaitbar; waitbar((lay_id-start_id)/(end_id-start_id),wb); end
                        if selectedMaterial == -1   % mask
                            slice = cell2mat(obj.mibModel.getData2D('mask', lay_id, orientation, NaN, getDataOptions));
                        else
                            slice = cell2mat(obj.mibModel.getData2D('model', lay_id, orientation, selectedMaterial, getDataOptions));
                        end
                        
                        % get objects
                        if ~isempty(property(ismember(property,'HolesArea')))     % calculate curve length in units
                            slice = imfill(slice, conn, 'holes') - slice;
                        end
                        
                        if ~isnan(selectedMaterial)
                            CC = bwconncomp(slice,conn);
                            if CC.NumObjects == 0
                                continue;
                            end
                        else
                            CC = slice;
                        end
                        
                        % calculate common properties
                        STATS = regionprops(CC, commonProps);
                        
                        if isnan(selectedMaterial)
                            % remove empty entries for models with more than
                            % 255 materials
                            emptyIndeces = find(arrayfun(@(STATS) isempty(STATS.PixelIdxList), STATS));
                            STATS(emptyIndeces) = [];
                            CC = struct();
                            CC.PixelIdxList = {STATS(:).PixelIdxList};
                            CC.NumObjects = numel(CC.PixelIdxList);
                            CC.ImageSize = size(slice);
                            CC.Connectivity = conn;
                        end
                        
                        % calculate matlab standard shape properties
                        prop1 = property(ismember(property,shapeProps));
                        if ~isempty(prop1)
                            STATS2 = regionprops(CC, prop1);
                            fieldNames = fieldnames(STATS2);
                            
                            for i=1:numel(fieldNames)
                                [STATS.(fieldNames{i})] = STATS2.(fieldNames{i});
                            end
                            %                             else
                            %                                 for i=1:numel(fieldNames)
                            %                                     switch fieldNames{i}
                            %                                         case {'Area', 'ConvexArea', 'FilledArea'}
                            %                                             STATSTEMP = cell2struct(num2cell([STATS2.(fieldNames{i})]* pixSize.x * pixSize.y), (fieldNames{i}),1);
                            %                                             [STATS.(fieldNames{i})] = STATSTEMP.(fieldNames{i});
                            %                                         case {'MajorAxisLength','MinorAxisLength','EquivDiameter','Perimeter'}
                            %                                             STATSTEMP = cell2struct(num2cell([STATS2.(fieldNames{i})] * (pixSize.x + pixSize.y)/2), (fieldNames{i}),1);
                            %                                             [STATS.(fieldNames{i})] = STATSTEMP.(fieldNames{i});
                            %                                         otherwise
                            %                                             [STATS.(fieldNames{i})] = STATS2.(fieldNames{i});
                            %                                     end
                            %                                 end
                            %                             end
                        end
                        
                        % calculate regionprop3mib shape properties
                        prop1 = property(ismember(property, shapeProps3D));
                        if ~isempty(prop1)
                            try
                                STATS2 = regionprops3mib(CC, prop1{:});
                            catch err
                                0;
                            end
                            fieldNames = fieldnames(STATS2);
                            for i=1:numel(fieldNames)
                                [STATS.(fieldNames{i})] = STATS2.(fieldNames{i});
                            end
                        end
                        
                        % detects length between the end points of each object, applicable only to lines
                        prop1 = property(ismember(property, 'EndpointsLength'));
                        if ~isempty(prop1)
                            STATS2 = regionprops(CC, 'PixelList');
                            for objId=1:numel(STATS2)
                                STATS(objId).EndpointsLength = sqrt((STATS2(objId).PixelList(1,1) - STATS2(objId).PixelList(end,1))^2 + ...
                                    (STATS2(objId).PixelList(1,2) - STATS2(objId).PixelList(end,2))^2);
                            end
                            clear STAT2;
                        end
                        % calculate curve length in pixels
                        prop1 = property(ismember(property,'CurveLength'));
                        if ~isempty(prop1)
                            STATS2 = mibCalcCurveLength(CC);
                            if isstruct(STATS2)
                                [STATS.CurveLength] = deal(STATS2.CurveLengthInPixels);
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
                            for i = 1:numel(colorChannel)
                                STATS2 = regionprops(CC, cell2mat(obj.mibModel.getData2D('image', lay_id, orientation, colorChannel(i), getDataOptions)), 'PixelValues');
                                % convert to double
                                vals = arrayfun(@(x) double(x.PixelValues), STATS2, 'UniformOutput', false);
                                STATS2 = cell2struct(vals', {'PixelValues'});
                                if sum(ismember(property, 'MinIntensity')) > 0
                                    calcVal = cellfun(@min, struct2cell(STATS2),'UniformOutput', false);
                                    fieldName = sprintf('MinIntensity_Ch%d', colorChannel(i));
                                    [STATS.(fieldName)] = calcVal{:};
                                    %[STATS.MaxIntensity3] = deal([calcVal{:}; calcVal{:}])
                                end
                                if sum(ismember(property, 'MaxIntensity')) > 0
                                    calcVal = cellfun(@max, struct2cell(STATS2),'UniformOutput', false);
                                    fieldName = sprintf('MaxIntensity_Ch%d', colorChannel(i));
                                    [STATS.(fieldName)] = calcVal{:};
                                end
                                if sum(ismember(property, 'MeanIntensity')) > 0
                                    calcVal = cellfun(@mean, struct2cell(STATS2),'UniformOutput', false);
                                    fieldName = sprintf('MeanIntensity_Ch%d', colorChannel(i));
                                    [STATS.(fieldName)] = calcVal{:};
                                end
                                if sum(ismember(property, 'SumIntensity')) > 0
                                    calcVal = cellfun(@sum, struct2cell(STATS2),'UniformOutput', false);
                                    fieldName = sprintf('SumIntensity_Ch%d', colorChannel(i));
                                    [STATS.(fieldName)] = calcVal{:};
                                end
                                if sum(ismember(property, 'StdIntensity')) > 0
                                    calcVal = cellfun(@std2, struct2cell(STATS2),'UniformOutput', false);
                                    fieldName = sprintf('StdIntensity_Ch%d', colorChannel(i));
                                    [STATS.(fieldName)] = calcVal{:};
                                end
                            end
                        end
                        % calculate correlation between channels
                        prop1 = property(ismember(property, 'Correlation'));
                        if ~isempty(prop1)
                            img = cell2mat(obj.mibModel.getData2D('image', lay_id, orientation, 0, getDataOptions));
                            img1 = img(:, :, colorChannel1);
                            img2 = img(:, :, colorChannel2);
                            for object=1:numel(STATS)
                                STATS(object).Correlation = corr2(img1(STATS(object).PixelIdxList),img2(STATS(object).PixelIdxList));
                            end
                        end
                        
                        %                         prop1 = property(ismember(property, regprops3Props));
                        %                         if ~isempty(prop1)
                        %
                        %                         end
                        
                        % recalculate to units if needed
                        if ~strcmp(obj.BatchOpt.Units{1}, 'pixels')
                            fieldNames = fieldnames(STATS);
                            for i=1:numel(fieldNames)
                                switch fieldNames{i}
                                    case {'Area', 'ConvexArea', 'FilledArea', 'HolesArea'}
                                        STATSTEMP = cell2struct(num2cell([STATS.(fieldNames{i})]* pixSize.x * pixSize.y), (fieldNames{i}),1);
                                        [STATS.(fieldNames{i})] = STATSTEMP.(fieldNames{i});
                                    case {'CurveLength','EndpointsLength','MajorAxisLength','MinorAxisLength','EquivDiameter','Perimeter','FirstAxisLength','SecondAxisLength',}
                                        STATSTEMP = cell2struct(num2cell([STATS.(fieldNames{i})] * (pixSize.x + pixSize.y)/2), (fieldNames{i}),1);
                                        [STATS.(fieldNames{i})] = STATSTEMP.(fieldNames{i});
                                end
                            end
                        end
                        
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
                            STATS = arrayfun(@(s) setfield(s, 'BoundingBox', [s.BoundingBox(1) s.BoundingBox(2) lay_id s.BoundingBox(3) s.BoundingBox(4) 1]), STATS);
                        end
                        [STATS.TimePnt] = deal(t);  % add time points
                        if isempty(obj.STATS)
                            obj.STATS = STATS;
                            obj.STATS = orderfields(STATS');
                        else
                            obj.STATS = [obj.STATS orderfields(STATS')];
                        end
                    end
                end
            end
            
            % store information about which dataset was quantified
            if isnan(selectedMaterial); selectedMaterial = -2; end  % restore index of the selectedMaterial for full model
            obj.runId = [obj.mibModel.Id, selectedMaterial];
            if BatchModeSwitch==0; obj.enableStatTable(); end
            
            if obj.BatchOpt.showWaitbar; waitbar(.9, wb, sprintf('Reformatting the indices\nPlease wait...')); end
            data = zeros(numel(obj.STATS),4);
            if numel(data) ~= 0
                % rename selected property MaxIntensity -> MaxIntensity_Ch3
                if ismember(selectedProperty, intProps)
                    selectedProperty = sprintf('%s_Ch%d', selectedProperty, colorChannel1);
                end
                
                if isfield(obj.STATS, selectedProperty)
                    [data(:,2), data(:,1)] = sort(cat(1, obj.STATS.(selectedProperty)), 'descend');
                else
                    [data(:,2), data(:,1)] = sort(cat(1, obj.STATS.(property{1})), 'descend');
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
            
            if obj.BatchOpt.showWaitbar; waitbar(1,wb); end
            data = obj.sortBtn_Callback(data);
            if BatchModeSwitch==0; obj.View.handles.statTable.Data = data; end
            
            data = data(:,2);
            [a,b] = hist(data, 256);
            obj.histLimits = [min(b) max(b)];
            if BatchModeSwitch==0
                bar(obj.View.handles.histogram, b, a);
                obj.histScale_Callback();
                grid(obj.View.handles.histogram); 
            end
            
            if obj.BatchOpt.showWaitbar; delete(wb); end
            
            if BatchModeSwitch == 1
                if ~strcmp(obj.BatchOpt.ExportResultsTo{1}, 'Do not export')
                    % export results when the batch mode used
                    obj.exportButton_Callback(BatchModeSwitch);
                end
                if ~strcmp(obj.BatchOpt.CropObjectsTo{1}, 'Do not crop')
                    obj.startController('mibCropObjectsController', obj, BatchModeSwitch);
                end
            end
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt(obj.BatchOpt);
            toc
        end
        
        function data = sortBtn_Callback(obj, data)
            % function sortBtn_Callback(obj, data)
            % sort the table
            %
            % Parameters:
            % data: a matrix with contents of the table
            
            if nargin < 2; data = obj.View.handles.statTable.Data; end
            
            if iscell(data); return; end   % nothing to sort
            if obj.sortingDirection == 1     % ascend sorting
                [data(:,obj.sortingColIndex), index] = sort(data(:, obj.sortingColIndex), 'ascend');
            else
                [data(:, obj.sortingColIndex), index] = sort(data(:, obj.sortingColIndex), 'descend');
            end
            
            if obj.sortingColIndex == 2
                data(:,1) = data(index, 1);
                data(:,3) = data(index, 3);
                data(:,4) = data(index, 4);
            elseif obj.sortingColIndex == 1
                data(:,2) = data(index, 2);
                data(:,3) = data(index, 3);
                data(:,4) = data(index, 4);
            elseif obj.sortingColIndex == 3
                data(:,1) = data(index, 1);
                data(:,2) = data(index, 2);
                data(:,4) = data(index, 4);
            elseif obj.sortingColIndex == 4
                data(:,1) = data(index, 1);
                data(:,2) = data(index, 2);
                data(:,3) = data(index, 3);
            end
            if nargin < 2
                obj.View.handles.statTable.Data = data;
            end
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
            addlistener(obj.childControllers{id}, 'closeEvent', @(src,evnt) mibStatisticsController.purgeControllers(obj, src, evnt));   % static
        end
        
    end
end



