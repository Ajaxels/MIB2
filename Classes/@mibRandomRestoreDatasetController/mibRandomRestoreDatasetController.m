classdef mibRandomRestoreDatasetController < handle
    % classdef mibRandomRestoreDatasetController < handle
    % a controller class for chopping the dataset into several smaller ones
    
    % Copyright (C) 16.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        inputFilename = []
        % a char with filename to the project file, *.mibShuffle
        Settings = struct()
        % a structure with project settings
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibRandomRestoreDatasetController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibRandomRestoreDatasetGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % update output directory
            obj.inputFilename = fullfile(obj.mibModel.myPath, 'Shuffled', 'Shuffled.mibShuffle');
            obj.View.handles.projectFilenameEdit.String = obj.inputFilename;
            obj.View.handles.projectFilenameEdit.TooltipString = obj.inputFilename;
            
			obj.updateWidgets();
        end
        
        function closeWindow(obj)
            % closing mibRandomRestoreDatasetController  window
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
            if exist(obj.inputFilename, 'file') ~= 0
                obj.updateProjectDetails(); 
            end
            
        end
        
        function updateProjectDetails(obj)
            % function updateProjectDetails(obj)
            % update details of the project in the file
            if isempty(fieldnames(obj.Settings)); return; end
            
            obj.View.handles.randomDirsList.String = obj.Settings.outputDirName;
            obj.View.handles.destinationDirsList.String = obj.Settings.inputDirName;
            obj.View.handles.numImagesText.String = sprintf('Total number of images: %d', numel(obj.Settings.InputImagesCombined));
        end
        
        function projectFilenameEdit_Callback(obj)
            % function fileEdit_Callback(obj)
            % update filename of the project file with details
            
            filename = obj.View.handles.projectFilenameEdit.String;
            if exist(filename, 'file') == 0   % directory does not exist
                errordlg(sprintf('!!! Error !!!\n\nThere is no file with the following filename:\n%s', filename), 'Wrong filename');
                obj.View.handles.projectFilenameEdit.String = obj.inputFilename;
                return;
            end
            obj.inputFilename = filename;
            obj.View.handles.projectFilenameEdit.TooltipString = obj.inputFilename;
            
            % update project details
            res = load(obj.inputFilename, '-mat');
            if ~isfield(res, 'Settings')
                errordlg('Something is wrong with the project file!');
                return;
            end
            obj.Settings = res.Settings; %#ok<CPROP>
            
            obj.updateWidgets();
        end
        
        function selectSettingsFileBtn_Callback(obj)
            % function selectSettingsFileBtn_Callback(obj)
            % callback for obj.View.handles.selectSettingsFileBtn select
            % filename with the project details
            
            filename = obj.inputFilename;
            if exist(filename, 'file') == 0   % file does not exist
                filename = obj.mibModel.myPath;
            end
            
            [filename, path] = uigetfile('*.mibShuffle', 'Select a project file', filename);
            if filename == 0; return; end
            
            obj.inputFilename = fullfile(path, filename);
            obj.View.handles.projectFilenameEdit.String = obj.inputFilename;
            obj.View.handles.projectFilenameEdit.TooltipString = obj.inputFilename;
            
            % update project details
            load(obj.inputFilename, '-mat');
            if ~exist('Settings', 'var')
                errordlg('Something is wrong with the project file!');
                return;
            end
            obj.Settings = Settings; %#ok<CPROP>
            
            obj.updateWidgets();
        end
        
        function updateDir(obj, parameter)
            % function updateDir(obj, parameter)
            % update directory name for restore
            %
            % Parameters:
            % parameter: a char that defines which list should be updated
            %  'randomDirsList'
            %  'destinationDirsList'
            
            if isempty(fieldnames(obj.Settings)); return; end
            
            dirList = obj.View.handles.(parameter).String;
            selValue = obj.View.handles.(parameter).Value;
            dirName = dirList{selValue};
            
            dirName = uigetdir(dirName, 'Select directory');
            if isequal(dirName, 0); return; end
            
            switch parameter
                case 'randomDirsList'
                    obj.Settings.outputDirName{selValue} = dirName;
                case 'destinationDirsList'
                    obj.Settings.inputDirName{selValue} = dirName;
            end
            obj.updateWidgets();
        end
                
            
        
        function restoreBtn_Callback(obj)
            % function restoreBtn_Callback(obj)
            % restore the dataset
            includeMasks = obj.View.handles.includeMaskCheck.Value;   % switch to include or not model files that are places in the input folders
            
            filename = obj.inputFilename;
            if exist(filename, 'file') == 0   % file does not exist
                errordlg(sprintf('!!! Error !!!\n\nThere is no file with the following filename:\n%s', filename), 'Wrong filename');
                return;
            end
%             Details of the Settings structure            
%             Settings =  struct;     % structure with settings
%             Settings.inputDirName = [];  % paths to the input directories
%             Settings.InputImagesCombined = [];  % combined list of all files in the input directories
%             Settings.InputImagesSliceNumber = [];   % a vector with slice number of each file in the input directory
%             Settings.inputIndices = [];     % indices of the input directories for each input file
%             Settings.outputDirName = cell([outputDirNum, 1]);   % paths to the output directories
%             Settings.OutputImagesCombined = {}; % combined list of all files in the output directories
%             Settings.outputIndices = [];    % indices of the output directories for each output file
%             Settings.OutputIndicesSorted = {};  % sorted indices for each output directory: 
%              % index = Settings.OutputIndicesSorted{1}(1) - corresponds to Settings.InputImagesCombined(index)
            
            wb = waitbar(0, sprintf('Loading models\nPlease wait...'), 'Name', 'Restore shuffled images');
            InputModels = {};
            
            % load the models from the randomized directories
            for dirId=1:numel(obj.Settings.outputDirName)
                fileList = dir(obj.Settings.outputDirName{dirId});   % list of files in each of the input directories
                fileList = {fileList.name};
                
                for i=1:numel(fileList)
                    [~,~,ext] = fileparts(fileList{i});
                    if ismember(ext, {'.model'})
                        inputModelFilenames{dirId} = fullfile(obj.Settings.outputDirName{dirId}, fileList{i}); %#ok<AGROW>
                        InputModels{dirId} = load(inputModelFilenames{dirId}, '-mat'); %#ok<AGROW>
                    end
                    
                    % get filenames for masks
                    if includeMasks
                        if ismember(ext, {'.mask'})
                            inputMaskFilenames{dirId} = fullfile(obj.Settings.outputDirName{dirId}, fileList{i}); %#ok<NASGU>
                        end
                    end
                end
            end
            if isempty(InputModels)
                errordlg('Directories with shuffled images should contain .model files!', 'No models');
                delete(wb);
                return;
            end
            waitbar(0.5, wb, sprintf('Generating restored models\nPlease wait...'));
            
            modelVariable = InputModels{1}.modelVariable;
            modelMaterialColors = InputModels{1}.modelMaterialColors;
            modelMaterialNames = InputModels{1}.modelMaterialNames;
            modelType = InputModels{1}.modelType;
            
            % get model dimensions
            height = size(InputModels{1}.(InputModels{1}.modelVariable),1);
            width = size(InputModels{1}.(InputModels{1}.modelVariable),2);
            
            indexShift = 0;     % this is shift of linear indices when progressing from one unrandomized folder to another
            for dirId = 1:numel(obj.Settings.inputDirName)
                outputIndices = find(obj.Settings.inputIndices==dirId);     % find linear indices for each unrandomized directory
                mibModel = zeros([height, width, numel(outputIndices)], class(InputModels{1}.(InputModels{1}.modelVariable)));  % allocate space
                % define labels
                labelPosition = [];
                labelText = {};
                labelValues = [];
            
                for sliceIndex = 1:numel(outputIndices)
                    outputDirId = 0;
                    sliceNumber = [];
                    while isempty(sliceNumber)  % look for the slice number in the randomized model
                        outputDirId = outputDirId + 1;
                        sliceNumber = find(obj.Settings.OutputIndicesSorted{outputDirId} == sliceIndex+indexShift);
                    end
                    % copy the slice to a restored model
                    mibModel(:,:,sliceIndex) = InputModels{outputDirId}.(InputModels{outputDirId}.modelVariable)(:,:,sliceNumber);
                    
                    % add and shift annotations
                    if isfield(InputModels{outputDirId}, 'labelPosition')
                        labelIndices = find(InputModels{outputDirId}.labelPosition(:,1)==sliceNumber);
                        currPos = InputModels{outputDirId}.labelPosition(labelIndices,:);
                        currPos(:,1) = sliceIndex;  % replace z-value
                        labelPosition = [labelPosition; currPos];
                        labelText = [labelText; InputModels{outputDirId}.labelText(labelIndices,:)];
                        labelValues = [labelValues; InputModels{outputDirId}.labelValues(labelIndices,:)];
                    end
                end
                indexShift = indexShift + numel(outputIndices);     % add index shift
                
                % generate the data-tag for the model filenames
                formatOut = 'yymmdd';
                dateTag = datestr(now, formatOut);
                
                % generate model filename
                modelFilename = fullfile(obj.Settings.inputDirName{dirId}, sprintf('Labels_RestoreRand_%s.model', dateTag));
                
                % save the model
                if isempty(labelPosition)
                    save(modelFilename, 'mibModel','modelVariable','modelMaterialColors','modelMaterialNames','modelType', '-mat', '-v7.3');
                else
                    save(modelFilename, 'mibModel','modelVariable','modelMaterialColors','modelMaterialNames','modelType',...
                        'labelPosition', 'labelText', 'labelValues', '-mat', '-v7.3');
                end
                clear mibModel;
            end
            
            if includeMasks    % restore also the masks
                waitbar(0.8, wb, sprintf('Generating the mask files\nPlease wait...'));
                % load masks
                for dirId=1:numel(obj.Settings.outputDirName)
                    InputModels{dirId} = load(inputMaskFilenames{dirId}, '-mat'); %#ok<AGROW>
                end
                
                % get model dimensions
                height = size(InputModels{1}.maskImg, 1);
                width = size(InputModels{1}.maskImg, 2);
                
                indexShift = 0;     % this is shift of linear indices when progressing from one unrandomized folder to another
                for dirId = 1:numel(obj.Settings.inputDirName)
                    outputIndices = find(obj.Settings.inputIndices==dirId);     % find linear indices for each unrandomized directory
                    maskImg = zeros([height, width, numel(outputIndices)], class(InputModels{1}.maskImg));  % allocate space
                    
                    for sliceIndex = 1:numel(outputIndices)
                        outputDirId = 0;
                        sliceNumber = [];
                        while isempty(sliceNumber)  % look for the slice number in the randomized model
                            outputDirId = outputDirId + 1;
                            sliceNumber = find(obj.Settings.OutputIndicesSorted{outputDirId} == sliceIndex+indexShift);
                        end
                        % copy the slice to a restored model
                        maskImg(:,:,sliceIndex) = InputModels{outputDirId}.maskImg(:,:,sliceNumber);
                    end
                    indexShift = indexShift + numel(outputIndices);     % add index shift
                    
                    % generate the data-tag for the model filenames
                    formatOut = 'yymmdd';
                    dateTag = datestr(now, formatOut);
                    
                    % generate model filename
                    maskFilename = fullfile(obj.Settings.inputDirName{dirId}, sprintf('Mask_RestoreRand_%s.mask', dateTag));
                    
                    % save mask
                    save(maskFilename, 'maskImg', '-mat', '-v7.3');
                end
            end
            
            waitbar(1, wb, sprintf('Finishing\nPlease wait...'));
            disp('MIB: the models from shuffled datasets were restored!')
            delete(wb);
            %obj.closeWindow();
        end
    end
end