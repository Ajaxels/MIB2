classdef mibRandomDatasetController < handle
    % classdef mibRandomDatasetController < handle
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
        inputDirs = []
        % a cell array with list of directories for the input
        outputDir = []
        % output directory for export
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibRandomDatasetController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibRandomDatasetGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % update output directory
            obj.outputDir = fullfile(obj.mibModel.myPath, 'Shuffled');
            obj.View.handles.dirEdit.String = obj.outputDir;
            
			obj.updateWidgets();
        end
        
        function closeWindow(obj)
            % closing mibRandomDatasetController  window
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
            % set default directory for the export
            obj.View.handles.inputDirsList.String = obj.inputDirs;
        end
        
        function addDirBtn_Callback(obj)
            % function addDirBtn_Callback(obj)
            % add directory to the list
            
            %folder_name = uigetdir(obj.mibModel.myPath, 'Select directory');
            folder_name = uigetfile_n_dir(obj.mibModel.myPath, 'Select directory');
            if isequal(folder_name, 0); return; end
            
            obj.inputDirs = [obj.inputDirs; folder_name'];
            
            %obj.inputDirs(end+numel(folder_name)-1) = folder_name';
            obj.updateWidgets();
            obj.View.handles.inputDirsList.Value = numel(obj.inputDirs);
        end
        
        function removeDirBtn_Callback(obj)
            % function removeDirBtn_Callback(obj)
            % remove directory from the list
            
            dir = obj.View.handles.inputDirsList.String{obj.View.handles.inputDirsList.Value};
            obj.inputDirs(ismember(obj.inputDirs, dir)) = [];
            obj.updateWidgets();
            obj.View.handles.inputDirsList.Value = numel(obj.inputDirs);
        end
        
        function selectDirBtn_Callback(obj)
            % function selectDirBtn_Callback(obj)
            % callback for obj.View.handles.selectDirBtn select directory
            % for the export
            
            folder_name = obj.outputDir;
            if exist(folder_name, 'dir') == 0   % directory does not exist
                folder_name = fileparts(folder_name);
            end
            
            folder_name = uigetdir(folder_name, 'Select output directory');
            if isequal(folder_name, 0); return; end
            
            obj.View.handles.dirEdit.String = folder_name;
            obj.outputDir = folder_name;
        end
        
        function dirEdit_Callback(obj)
            % function dirEdit_Callback(obj)
            % callback for obj.View.handles.dirEdit select directory
            % for the export
            
            folder_name = obj.View.handles.dirEdit.String;
            if exist(folder_name, 'dir') == 0
                choice = questdlg(sprintf('!!! Warnging !!!\nThe target directory:\n%s\nis missing!\n\nCreate?', folder_name), ...
                    'Create Directory', ...
                    'Create','Cancel','Cancel');
                if strcmp(choice, 'Cancel')
                    obj.View.handles.dirEdit.String = obj.outputDir;
                    return;
                end
                mkdir(folder_name);
            end
            obj.outputDir = folder_name;
        end
        
        function randomBtn_Callback(obj)
            % function randomBtn_Callback(obj)
            % chop the dataset
            
            outDir = obj.outputDir;     % main output directory
            fnTemplate = obj.View.handles.filenameTemplate.String;  % filename template for generation of output files
            outputDirNum = str2double(obj.View.handles.outputDirNumEdit.String);    % number of output directories
            includeModels = obj.View.handles.includeModelCheck.Value;   % switch to include or not model files that are placed in the input folders
            includeMasks = obj.View.handles.includeMaskCheck.Value;   % switch to include or not model files that are placed in the input folders
            includeAnnotations = obj.View.handles.includeAnnotationsCheck.Value;   % switch to include or not annotation files that are placed in the input folders
            filenameExtension = lower(obj.View.handles.filenameExtension.String); % extension for filenames with images
            
            Settings =  struct;     % structure with settings
            Settings.inputDirName = obj.View.handles.inputDirsList.String;  % paths to the input directories
            Settings.InputImagesCombined = [];  % combined list of all files in the input directories
            Settings.InputImagesSliceNumber = [];   % a vector with slice number of each file in the input directory
            Settings.inputIndices = [];     % indices of the input directories for each input file
            Settings.outputDirName = cell([outputDirNum, 1]);   % paths to the output directories
            Settings.OutputImagesCombined = {}; % combined list of all files in the output directories
            Settings.outputIndices = [];    % indices of the output directories for each output file
            Settings.OutputIndicesSorted = {};  % sorted indices for each output directory: 
             % index = Settings.OutputIndicesSorted{1}(1) - corresponds to Settings.InputImagesCombined(index)
            
            inputModelFilenames = [];    % filenames for the input model files
            
            if isempty(Settings.inputDirName); return; end
            
            wb = waitbar(0, sprintf('Checking input files\nPlease wait...'), 'Name', 'Randomize images');
            
            for dirId=1:numel(Settings.inputDirName)
                fileList = dir(Settings.inputDirName{dirId});   % list of files in each of the input directories
                fnames = {fileList.name};
                fileList = fnames(~[fileList.isdir]);     % exclude directory names from the list
                excludeFiles = zeros([numel(fileList), 1]);     % generate a vector with indices of the files that should be removed from the list
                for i=1:numel(fileList)
                    [~,~,ext] = fileparts(fileList{i});
                    %if ~ismember(lower(ext), ['.' filenameExtension])
                    if ~strcmp(lower(ext), ['.' filenameExtension]) %#ok<STCI>  % add to the exculude files list
                        excludeFiles(i) = 1;
                    end
                    if includeModels    % find filenames for the models
                        if ismember(ext, {'.model'})
                            inputModelFilenames{dirId} = fullfile(Settings.inputDirName{dirId}, fileList{i}); %#ok<AGROW>
                            InputModels{dirId} = load(inputModelFilenames{dirId}, '-mat'); %#ok<AGROW>
                        end
                    end
                    
                    if includeMasks    % find filenames for the masks
                        if ismember(ext, {'.mask'})
                            inputMaskFilenames{dirId} = fullfile(Settings.inputDirName{dirId}, fileList{i}); %#ok<AGROW>
                        end
                    end
                    
                    if includeAnnotations    % find filenames for the annotations
                        if ismember(ext, {'.ann'})
                            inputAnnotationsFilenames{dirId} = fullfile(Settings.inputDirName{dirId}, fileList{i});  %#ok<AGROW>
                        end
                    end
                end
                fileList(excludeFiles==1) = [];     % exclude files with '.mat' and '.model' extensions
                
                fileList = fullfile(Settings.inputDirName{dirId}, fileList);
                Settings.InputImagesCombined = [Settings.InputImagesCombined, fileList];
                Settings.InputImagesSliceNumber = [Settings.InputImagesSliceNumber, 1:numel(fileList)];
                Settings.inputIndices = [Settings.inputIndices; zeros([numel(fileList),1])+dirId];
            end
            Settings.outputIndices = randi(outputDirNum, [numel(Settings.InputImagesCombined), 1]);
            
            waitbar(0.1, wb, sprintf('Creating output directories\nPlease wait...'));
            overwrite = 0;
            for dirId = 1:outputDirNum
                Settings.outputDirName(dirId) = {fullfile(outDir, sprintf('Subset_%.3d', dirId))};
                if exist(Settings.outputDirName{dirId}, 'file') == 0
                    mkdir(Settings.outputDirName{dirId});
                else
                    if overwrite == 0
                        answer = questdlg(sprintf('!!! Warning !!!\n\nThe output directory already exist!\nAll files in the output directory will be removed!'),...
                            'Overwrite directory', 'Remove files and continue', 'Cancel', 'Cancel');
                        if strcmp(answer, 'Cancel'); delete(wb); return; end
                        overwrite = 1;
                    end
                    delete(fullfile(Settings.outputDirName{dirId}, '*.*'));
                end
            end
            
            waitbar(0.2, wb, sprintf('Copying the files\nPlease wait...'));
            randomFilenameNumbers = randperm(numel(Settings.InputImagesCombined));
            for imgId = 1:numel(Settings.InputImagesCombined)
                [~,~,ext] = fileparts(Settings.InputImagesCombined{imgId});
                Settings.OutputImagesCombined(imgId) = {fullfile(Settings.outputDirName{Settings.outputIndices(imgId)}, sprintf('%s_%.4d%s', fnTemplate, randomFilenameNumbers(imgId), ext))};
                copyfile(Settings.InputImagesCombined{imgId}, Settings.OutputImagesCombined{imgId});
            end
            % generate Settings.OutputIndicesSorted
            for dirId = 1:outputDirNum
                curDirIndices = find(Settings.outputIndices==dirId);    % find indices of files
                [~,sortedIndices] = sort(randomFilenameNumbers(curDirIndices));
                curDirIndices = curDirIndices(sortedIndices);
                Settings.OutputIndicesSorted{dirId} = curDirIndices;
            end
            
            if includeModels
                waitbar(0.6, wb, sprintf('Generating the model files\nPlease wait...'));
                % get model dimensions
                height = size(InputModels{1}.(InputModels{1}.modelVariable),1);
                width = size(InputModels{1}.(InputModels{1}.modelVariable),2);
                
                modelVariable = InputModels{1}.modelVariable;
                modelMaterialColors = InputModels{1}.modelMaterialColors;
                modelMaterialNames = InputModels{1}.modelMaterialNames;
                modelType = InputModels{1}.modelType;
                
                for dirId = 1:outputDirNum
                    curDirIndices = Settings.OutputIndicesSorted{dirId};
                    mibModel = zeros([height, width, numel(curDirIndices)], class(InputModels{1}.(InputModels{1}.modelVariable)));  % allocate space
                    %curDirIndices = sort(randomFilenameNumbers(curDirIndices));     % because MIB sorts files based on their names the curIndeces should be extracted from randomFilenameNumbers
                    
                    % define labels
                    labelPosition = [];
                    labelText = {};
                    labelValue = [];
                    
                    for sliceIndex = 1:numel(curDirIndices)
                        inputDirIndex = Settings.inputIndices(curDirIndices(sliceIndex));   % index of the input directory with the image
                        modelVariable = InputModels{inputDirIndex}.modelVariable;   % model variable in the structure
                        sliceNumber = Settings.InputImagesSliceNumber(curDirIndices(sliceIndex));   % index of the slice in the model
                        mibModel(:,:,sliceIndex) = InputModels{inputDirIndex}.(modelVariable)(:,:,sliceNumber);
                        if isfield(InputModels{inputDirIndex}, 'labelPosition')
                            labelIndices = find(InputModels{inputDirIndex}.labelPosition(:,1)==sliceNumber);
                            currPos = InputModels{inputDirIndex}.labelPosition(labelIndices,:);
                            currPos(:,1) = sliceIndex;  % replace z-value
                            labelPosition = [labelPosition; currPos];
                            labelText = [labelText; InputModels{inputDirIndex}.labelText(labelIndices,:)];
                            labelValue = [labelValue; InputModels{inputDirIndex}.labelValue(labelIndices,:)];
                        end
                    end
                    modelFilename = fullfile(Settings.outputDirName{dirId}, sprintf('Labels_%s_%.3d.model', fnTemplate, dirId));
                    if isempty(labelPosition)
                        save(modelFilename, 'mibModel','modelVariable','modelMaterialColors','modelMaterialNames','modelType', '-mat', '-v7.3');
                    else
                        save(modelFilename, 'mibModel','modelVariable','modelMaterialColors','modelMaterialNames','modelType',...
                            'labelPosition', 'labelText', 'labelValue', '-mat', '-v7.3');    
                    end
                end
                clear mibModel;
            end
            
            if includeMasks    % randomize also the masks
                waitbar(0.8, wb, sprintf('Generating the mask files\nPlease wait...'));
                % load masks
                for dirId=1:numel(Settings.inputDirName)   
                    InputModels{dirId} = load(inputMaskFilenames{dirId}, '-mat');
                end
                
                % get model dimensions
                height = size(InputModels{1}.maskImg, 1);
                width = size(InputModels{1}.maskImg, 2);
                for dirId = 1:outputDirNum
                    curDirIndices = Settings.OutputIndicesSorted{dirId};
                    maskImg = zeros([height, width, numel(curDirIndices)], class(InputModels{1}.maskImg));  % allocate space
                    
                    for sliceIndex = 1:numel(curDirIndices)
                        inputDirIndex = Settings.inputIndices(curDirIndices(sliceIndex));   % index of the input directory with the image
                        sliceNumber = Settings.InputImagesSliceNumber(curDirIndices(sliceIndex));   % index of the slice in the model
                        maskImg(:,:,sliceIndex) = InputModels{inputDirIndex}.maskImg(:, :, sliceNumber);
                    end
                    
                    maskFilename = fullfile(Settings.outputDirName{dirId}, sprintf('%s_%.3d.mask', fnTemplate, dirId));
                    save(maskFilename, 'maskImg', '-mat', '-v7.3');
                end
            end
            
            if includeAnnotations    % randomize also the annotations
                waitbar(0.9, wb, sprintf('Generating the annotation files\nPlease wait...'));
                % load annotations
                for dirId=1:numel(Settings.inputDirName)   
                    InputModels{dirId} = load(inputAnnotationsFilenames{dirId}, '-mat');
                end
                
                for dirId = 1:outputDirNum
                    curDirIndices = Settings.OutputIndicesSorted{dirId};
                    
                    labelPosition = [];
                    labelText = {};
                    labelValue = [];
                    
                    for sliceIndex = 1:numel(curDirIndices)
                        inputDirIndex = Settings.inputIndices(curDirIndices(sliceIndex));   % index of the input directory with the image
                        sliceNumber = Settings.InputImagesSliceNumber(curDirIndices(sliceIndex));   % index of the slice in the model
                        
                        ind = find(InputModels{inputDirIndex}.labelPosition(:,1)==sliceNumber);
                        if ~isempty(ind)
                            pos = InputModels{inputDirIndex}.labelPosition(ind,:,:,:);
                            pos(:,1) = sliceIndex;  % replace z-value
                            labelPosition = [labelPosition; pos]; %#ok<AGROW>
                            labelText = [labelText; InputModels{inputDirIndex}.labelText(ind)]; %#ok<AGROW>
                            labelValue = [labelValue; InputModels{inputDirIndex}.labelValue(ind)]; %#ok<AGROW>
                        end
                    end
                    
                    annotationFilename = fullfile(Settings.outputDirName{dirId}, sprintf('%s_%.3d.ann', fnTemplate, dirId));
                    save(annotationFilename, 'labelPosition','labelText','labelValue', '-mat', '-v7.3');
                end
            end
            
            % generate Excel file
            if obj.View.handles.generateExcelCheck.Value
                waitbar(0.95, wb, sprintf('Generating Excel file\nPlease wait...'));
                fnOut = fullfile(outDir, sprintf('%s.xls', fnTemplate));
                if exist(fnOut, 'file') == 2
                    delete(fnOut);
                end
                warning('off', 'MATLAB:xlswrite:AddSheet');
                % Sheet 1
                s = {'Rename and Shuffle parameters'};
                s(2,1) = {'Note! MIB opens images sorted in alphabetical order'};
                
                s(4,1) = {'Slice No.'}; s(4,2) = {'Original filename'}; s(4,3) = {'->'}; s(4,4) = {'Slice No.'}; s(4,5) = {'Renamed and Shuffled filename'};
                
                noFiles = numel(Settings.InputImagesCombined);
                s(6:6+noFiles-1, 1) = num2cell(Settings.InputImagesSliceNumber');
                s(6:6+noFiles-1, 2) = Settings.InputImagesCombined';
                s(6:6+noFiles-1, 3) = repmat({'->'}, [noFiles, 1]);
                
                sliceNo = zeros([noFiles, 1]);  % slice numbers for shuffled folders
                for dirId=1:numel(Settings.OutputIndicesSorted)
                    [~, sortedInd] = sort(Settings.OutputIndicesSorted{dirId});
                    sliceNo(Settings.outputIndices==dirId) = sortedInd;
                end
                s(6:6+noFiles-1, 4) = num2cell(sliceNo);
                s(6:6+noFiles-1, 5) = Settings.OutputImagesCombined';
                
                dy = 6+noFiles+2;
                s(dy,1) = {'Slice No.'}; s(dy,2) = {'Renamed and Shuffled filename'}; s(dy,3) = {'->'}; s(dy,4) = {'Slice No.'}; s(dy,5) = {'Original filename'};
                
                dy = dy + 2;
                shiftY = 0;     % generate slice numbers
                for dirId=1:numel(Settings.OutputIndicesSorted)
                    noSlices = numel(Settings.OutputIndicesSorted{dirId});
                    sliceVec = 1:noSlices;
                    s(dy+shiftY:dy+shiftY+noSlices-1, 1) = num2cell(sliceVec');
                    shiftY = noSlices;
                end
                s(dy:dy+noFiles-1, 2) = Settings.OutputImagesCombined(cell2mat(Settings.OutputIndicesSorted'))';
                s(dy:dy+noFiles-1, 3) = repmat({'->'}, [noFiles, 1]);
                s(dy:dy+noFiles-1, 4) = num2cell(Settings.InputImagesSliceNumber(cell2mat(Settings.OutputIndicesSorted'))');
                s(dy:dy+noFiles-1, 5) = Settings.InputImagesCombined(cell2mat(Settings.OutputIndicesSorted'))';
                
                xlswrite2(fnOut, s, 'Results', 'A1');
                fprintf('Rename and shuffle: exporting parameters in the Excel format: done\n%s\n', fnOut);
            end
            
            waitbar(0.99, wb, sprintf('Finishing\nPlease wait...'));
            fnOut = fullfile(outDir, sprintf('%s.mibShuffle', fnTemplate));
            save(fnOut, 'Settings');
            
            waitbar(1, wb);
            
            disp('MIB: the datasets were shuffled!')
            delete(wb);
            %obj.closeWindow();
        end
    end
end