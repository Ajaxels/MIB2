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
            
            if isempty(obj.View.handles.randomDirsList.Value);  obj.View.handles.randomDirsList.Value = 1; end
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
            load(obj.inputFilename, '-mat');
            if ~exist('Settings', 'var')
                errordlg('Something is wrong with the project file!');
                return;
            end
            obj.Settings = Settings; %#ok<CPROP>
            
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
            
            if exist(dirName, 'dir') == 0
                dirName = obj.mibModel.myPath;
            end
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
            includeModels = obj.View.handles.includeModelCheck.Value;   % switch to include or not model files that are places in the input folders
            includeMasks = obj.View.handles.includeMaskCheck.Value;   % switch to include or not mask files that are places in the input folders
            includeAnnotations = obj.View.handles.includeAnnotationsCheck.Value;   % switch to include or not annotations files that are places in the input folders
            %includeMeasurements = 1;
            
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
            
            % check directories
            for dirId=1:numel(obj.Settings.outputDirName)
                if exist(obj.Settings.outputDirName{dirId}, 'dir') == 0
                    errordlg(sprintf('!!! Error !!!\n\nThe specified directory with shuffled images was not found!\n\n%s\n\nMost likely it was renamed or copied somewhere, please use the right mouse click over the directory name to update it', obj.Settings.outputDirName{dirId}));
                    return;
                end
            end
            for dirId=1:numel(obj.Settings.inputDirName)
                if exist(obj.Settings.inputDirName{dirId}, 'dir') == 0
                    errordlg(sprintf('!!! Error !!!\n\nThe specified destination directory was not found!\n\n%s\n\nMost likely it was renamed or copied somewhere, please use the right mouse click over the directory name to update it', obj.Settings.inputDirName{dirId}));
                    return;
                end
            end

            wb = waitbar(0, sprintf('Loading models\nPlease wait...'), 'Name', 'Restore shuffled images');
            InputModels = {};
            
            % load the models from the randomized directories
            for dirId=1:numel(obj.Settings.outputDirName)
                fileList = dir(obj.Settings.outputDirName{dirId});   % list of files in each of the input directories
                fileList = {fileList.name};
                
                % check for number of model, mask and annotation files
                checkExtensions = {};
                if includeModels; checkExtensions = [checkExtensions, {'.model'}]; end %#ok<AGROW>
                if includeMasks; checkExtensions = [checkExtensions, {'.mask'}]; end %#ok<AGROW>
                if includeAnnotations; checkExtensions = [checkExtensions, {'.ann'}]; end %#ok<AGROW>
                if includeMeasurements; checkExtensions = [checkExtensions, {'.measure'}]; end %#ok<AGROW>
                [~,~,extVec] = cellfun(@fileparts, fileList, 'UniformOutput', false);
                
                for i=1:numel(checkExtensions)
                    currentExtension = checkExtensions{i};
                    if sum(ismember(extVec, currentExtension)) ~= 1
                        if strcmp(currentExtension, '.ann')
                            extraInfo = '';
                        else
                            extraInfo = sprintf('\n\nIf you have multiple files they can be combined:\n1. Combine all images in the folder;\n2. Load the %ss, use the Shift key to select multiple %s files\n3. Save the combined %s\n4. Remove all other %s files from the directory', ...
                                currentExtension(2:end), currentExtension(2:end), currentExtension(2:end), currentExtension(2:end));
                        end
                        errordlg(sprintf('!!! Error !!!\nThe *.%s file is missing or there are more then one *.%s file!\n\nPlease make sure that there is a single *.%s file in each directory%s', ...
                            currentExtension(2:end), currentExtension(2:end), currentExtension(2:end), extraInfo));
                        delete(wb);
                        return;
                    end
                end
                
                if includeModels
                    [~,~,extVec] = cellfun(@fileparts, fileList, 'UniformOutput', false);
                    if sum(ismember(extVec, '.model')) ~= 1
                        errordlg(sprintf('!!! Error !!!\n\nThe *.model file is missing or there are more then one *.model file!\nPlease make sure that there is a single *.model file in each directory\n\nIf you have multiple files they can be combined:\n1. Combine all images in the folder;\n2. Load the models, use the Shift key to select multiple model files\n3. Save the combined model\n4. Remove all other model files from the directory'));
                        delete(wb);
                        return;
                    end
                end
                if includeMasks
                    [~,~,extVec] = cellfun(@fileparts, fileList, 'UniformOutput', false);
                    if sum(ismember(extVec, '.mask')) ~= 1
                        errordlg(sprintf('!!! Error !!!\n\nThe *.mask file is missing or there are more then one *.mask file!\nPlease make sure that there is a single *.mask file in each directory\n\nIf you have multiple files they can be combined:\n1. Combine all images in the folder;\n2. Load the masks, use the Shift key to select multiple model files\n3. Save the combined mask\n4. Remove all other mask files from the directory'));
                        delete(wb);
                        return;
                    end
                end
                if includeMeasurements
                    [~,~,extVec] = cellfun(@fileparts, fileList, 'UniformOutput', false);
                    if sum(ismember(extVec, '.measure')) ~= 1
                        errordlg(sprintf('!!! Error !!!\n\nThe *.measure file is missing or there are more then one *.measure file!\nPlease make sure that there is a single *.measure file in each directory'));
                        delete(wb);
                        return;
                    end
                end
                
                for i=1:numel(fileList)
                    [~,~,ext] = fileparts(fileList{i});
                    if includeModels
                        if ismember(ext, {'.model'})
                            inputModelFilenames{dirId} = fullfile(obj.Settings.outputDirName{dirId}, fileList{i}); %#ok<AGROW>
                            InputModels{dirId} = load(inputModelFilenames{dirId}, '-mat'); %#ok<AGROW>
                        end
                    end
                    
                    % get filenames for masks
                    if includeMasks
                        if ismember(ext, {'.mask'})
                            inputMaskFilenames{dirId} = fullfile(obj.Settings.outputDirName{dirId}, fileList{i}); %#ok<AGROW,NASGU>
                        end
                    end
                    
                    % get filenames for masks
                    if includeAnnotations
                        if ismember(ext, {'.ann'})
                            inputAnnotationsFilenames{dirId} = fullfile(obj.Settings.outputDirName{dirId}, fileList{i}); %#ok<AGROW,NASGU>
                        end
                    end
                    
                    if includeMeasurements
                        if ismember(ext, {'.measure'})
                            inputMeasurementsFilenames{dirId} = fullfile(obj.Settings.outputDirName{dirId}, fileList{i}); %#ok<AGROW,NASGU>
                        end
                    end
                    
                end
            end

            waitbar(0.5, wb, sprintf('Generating restored models\nPlease wait...'));
            
            if includeModels
                if isempty(InputModels)
                    errordlg('Directories with shuffled images should contain .model files!', 'No models');
                    delete(wb);
                    return;
                end
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
                    mibModel = zeros([height, width, numel(outputIndices)], class(InputModels{1}.(InputModels{1}.modelVariable)));  %#ok<PROP> % allocate space
                    % define labels
                    labelPosition = [];
                    labelText = {};
                    labelValue = [];

                    for sliceIndex = 1:numel(outputIndices)
                        outputDirId = 0;
                        sliceNumber = [];
                        while isempty(sliceNumber)  % look for the slice number in the randomized model
                            outputDirId = outputDirId + 1;
                            sliceNumber = find(obj.Settings.OutputIndicesSorted{outputDirId} == sliceIndex+indexShift);
                        end
                        % copy the slice to a restored model
                        mibModel(:,:,sliceIndex) = InputModels{outputDirId}.(InputModels{outputDirId}.modelVariable)(:,:,sliceNumber); %#ok<PROP>

                        % add and shift annotations
                        if isfield(InputModels{outputDirId}, 'labelPosition')
                            labelIndices = find(InputModels{outputDirId}.labelPosition(:,1)==sliceNumber);
                            currPos = InputModels{outputDirId}.labelPosition(labelIndices,:);
                            currPos(:,1) = sliceIndex;  % replace z-value
                            labelPosition = [labelPosition; currPos];
                            labelText = [labelText; InputModels{outputDirId}.labelText(labelIndices,:)];
                            labelValue = [labelValue; InputModels{outputDirId}.labelValue(labelIndices,:)];
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
                            'labelPosition', 'labelText', 'labelValue', '-mat', '-v7.3');
                    end
                    clear mibModel;
                end
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
            
            if includeAnnotations    % restore also the masks
                waitbar(0.9, wb, sprintf('Generating the annotation files\nPlease wait...'));
                % load randomized annotations
                for dirId=1:numel(obj.Settings.outputDirName)
                    InputModels{dirId} = load(inputAnnotationsFilenames{dirId}, '-mat'); %#ok<AGROW>
                end
                
                for dirId = 1:numel(obj.Settings.inputDirName)
                    outputIndices = find(obj.Settings.inputIndices==dirId);     % find linear indices for each unrandomized directory
                    labelPosition = [];
                    labelText = {};
                    labelValue = [];
                    
                    for sliceIndex = 1:numel(outputIndices)
                        dirInId = obj.Settings.outputIndices(outputIndices(sliceIndex));   % index of the randomized directory
                        randomSliceNumber = find(obj.Settings.OutputIndicesSorted{dirInId} == outputIndices(sliceIndex));  % slice number of the randomized dataset that correspond to sliceIndex of the non-rand dataset
                        
                        posIndices = find(InputModels{dirInId}.labelPosition(:,1) == randomSliceNumber);    % find annotations in the random dataset
                        
                        if ~isempty(posIndices)
                            currPos = InputModels{dirInId}.labelPosition(posIndices, :);
                            currPos(:,1) = sliceIndex;
                            labelPosition = [labelPosition; currPos]; %#ok<AGROW>
                            labelText = [labelText; InputModels{dirInId}.labelText(posIndices)]; %#ok<AGROW>
                            labelValue = [labelValue; InputModels{dirInId}.labelValue(posIndices)]; %#ok<AGROW>
                        end
                    end
                    
                    % generate the data-tag for the model filenames
                    formatOut = 'yymmdd';
                    dateTag = datestr(now, formatOut);
                    
                    % generate model filename
                    annotationFilename = fullfile(obj.Settings.inputDirName{dirId}, sprintf('Annotations_RestoreRand_%s.ann', dateTag));
                    
                    % save mask
                    save(annotationFilename, 'labelPosition', 'labelText', 'labelValue', '-mat', '-v7.3');
                end
            end
            
            if includeMeasurements
                waitbar(0.9, wb, sprintf('Generating the measurement files\nPlease wait...'));
                % load randomized annotations
                for dirId=1:numel(obj.Settings.outputDirName)
                    InputModels{dirId} = load(inputMeasurementsFilenames{dirId}, '-mat'); %#ok<AGROW>
                end
                
                for dirId = 1:numel(obj.Settings.inputDirName)
                    outputIndices = find(obj.Settings.inputIndices==dirId);     % find linear indices for each unrandomized directory
                    
                    for sliceIndex = 1:numel(outputIndices)
                        dirInId = obj.Settings.outputIndices(outputIndices(sliceIndex));   % index of the randomized directory
                        randomSliceNumber = find(obj.Settings.OutputIndicesSorted{dirInId} == outputIndices(sliceIndex));  % slice number of the randomized dataset that correspond to sliceIndex of the non-rand dataset
                        posIndices = find([InputModels{dirInId}.Data.Z] == randomSliceNumber);    % find annotations in the random dataset
                        
                        if ~isempty(posIndices)
                            CurrData = InputModels{dirInId}.Data(posIndices);
                            [CurrData.Z] = deal(sliceIndex);
                            if sliceIndex > 1
                                Data = [Data, CurrData]; %#ok<AGROW>
                            else
                                Data = CurrData;
                            end
                        end
                    end
                    
                    % generate the data-tag for the model filenames
                    formatOut = 'yymmdd';
                    dateTag = datestr(now, formatOut);
                    
                    % generate measurement filename
                    measurementsFilename = fullfile(obj.Settings.inputDirName{dirId}, sprintf('Measure_RestoreRand_%s.measure', dateTag));
                    
                    % save measurements
                    save(measurementsFilename, 'Data', '-mat', '-v7.3');
                end
            end
            
            waitbar(1, wb, sprintf('Finishing\nPlease wait...'));
            disp('MIB: the models from shuffled datasets were restored!')
            delete(wb);
            %obj.closeWindow();
        end
    end
end