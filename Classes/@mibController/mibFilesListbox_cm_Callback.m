function mibFilesListbox_cm_Callback(obj, parameter, BatchOptIn)
% function mibFilesListbox_cm_Callback(obj, parameter, BatchOptIn)
% a context menu to the to the handles.mibFilesListbox, the menu is called
% with the right mouse button
%
% Parameters:
% parameter: a string with parameters for the function
% @li 'Combine datasets' - [@em default] Combine selected datasets 
% @li 'Load part of dataset' - Load part of the dataset
% @li 'Load each N-th dataset' - Load each N-th dataset
% @li 'Insert into open dataset' - Insert into the open dataset
% @li 'Combine files as color channels' - Combine files as color channels
% @li 'Add as new color channel' - Add as a new color channel
% @li 'Add each N-th dataset as new color channel' - Add each N-th dataset as a new color channel
% @li 'rename' - Rename selected file
% @li 'delete' - Delete selected files
% @li 'file_properties' - File properties
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Mode -> [cell], desired mode to combine the images: 'Combine datasets', 'Load each N-th dataset', 'Insert into open dataset', 'Combine files as color channels', 'Add as new color channel', 'Add each N-th dataset as new color channel'
% @li .DirectoryName -> [cell] directory name, where the files are located, use the right mouse click over the Parameters table to modify the directory
% @li .FilenameFilter -> [string] filter for filenames: *.* - process all files in the directory; *.tif - process only the TIF files; could also be a filename
% @li .UseBioFormats -> [logical] when checked the Bio-Formats reader will be used
% @li .BioFormatsIndices -> [string, BioFormats only] indices of images to be opened for file containers, when empty load all
% @li .EachNthStep -> [string] define step to be used for combining images using each N-th option
% @li .BackgroundColorIntensity -> [string] Intensity of the background color for cases, when width/height of combined images mismatch
% @li .InsertDatasetDimension -> [Insert only, cell] Image dimension to insert the dataset: 'depth', 'time'
% @li .InsertDatasetPosition -> [Insert only, string] insert position; 1 - beginning of the open dataset; 0 - end of the open dataset\nor type any number to define position
% @li .showWaitbar -> [logical] show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Copyright (C) 10.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 13.03.2019, fixed for 5D datasets
% 28.08.2019, added BatchMode

global mibPath; % path to mib installation folder
if nargin < 2; parameter = 'Combine datasets'; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(parameter)
    BatchOpt.Mode = {parameter};
else
    BatchOpt.Mode = {'Combine datasets'};
end
BatchOpt.Mode{2} = {'Combine datasets', 'Load each N-th dataset', ...
        'Insert into open dataset', 'Combine files as color channels', 'Add as new color channel', ...
        'Add each N-th dataset as new color channel'};
BatchOpt.DirectoryName = {obj.mibModel.myPath};   % specify the target directory
BatchOpt.DirectoryName{2} = {obj.mibModel.myPath, 'Inherit from Directory/File loop'};  % this option forces the directories to be provided from the Dir/File loops
filter = obj.mibView.handles.mibFileFilterPopup.String{obj.mibView.handles.mibFileFilterPopup.Value};
if strcmp(filter, 'all known')
    BatchOpt.FilenameFilter = '*.*';
else
    BatchOpt.FilenameFilter = ['*.' filter];
end
BatchOpt.UseBioFormats = logical(obj.mibView.handles.mibBioformatsCheck.Value);
BatchOpt.BioFormatsIndices = '';
BatchOpt.EachNthStep = '2'; 
BatchOpt.BackgroundColorIntensity = '65535'; 
BatchOpt.InsertDatasetDimension = {'depth'}; 
BatchOpt.InsertDatasetDimension{2} = {'depth', 'time'};
BatchOpt.InsertDatasetPosition = '0';
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> File';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Load and combine images';
BatchOpt.mibBatchTooltip.Mode = sprintf('Desired mode to combine the images');
BatchOpt.mibBatchTooltip.DirectoryName = sprintf('Directory name, where the files are located, use the right mouse click over the Parameters table to modify the directory');
BatchOpt.mibBatchTooltip.FilenameFilter = sprintf('Filter for filenames: *.* - process all files in the directory; *.tif - process only the TIF files; could also be a filename');
BatchOpt.mibBatchTooltip.UseBioFormats = sprintf('When checked the Bio-Formats reader will be used');
BatchOpt.mibBatchTooltip.BioFormatsIndices = sprintf('[BioFormats only] indices of images to be opened for file containers, when empty load all');
BatchOpt.mibBatchTooltip.EachNthStep = sprintf('Define step to be used for combining images using each N-th option');
BatchOpt.mibBatchTooltip.BackgroundColorIntensity = sprintf('Intensity of the background color for cases, when width/height of combined images mismatch');
BatchOpt.mibBatchTooltip.InsertDatasetDimension = sprintf('[Insert only] Image dimension to insert the dataset');
BatchOpt.mibBatchTooltip.InsertDatasetPosition = sprintf('[Insert only] insert position; 1 - beginning of the open dataset; 0 - end of the open dataset\nor type any number to define position');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the waitbar');

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
    filename = dir(fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter));   % get list of files
    filename2 = arrayfun(@(filename) fullfile(BatchOpt.DirectoryName{1}, filename.name), filename, 'UniformOutput', false);  % generate full paths
    notDirsIndices = arrayfun(@(filename2) ~isdir(cell2mat(filename2)), filename2);     % get indices of not directories
    fn = filename2(notDirsIndices);     % generate full path file names
    filename = {filename(notDirsIndices).name}';
    batchModeSwitch = 1;    % indicates that the function is running in the batch mode
else
    % generate a dataset from the selected files
    % generate list of files
    val = obj.mibView.handles.mibFilesListbox.Value;
    list = obj.mibView.handles.mibFilesListbox.String;
    filename = list(val);
    notDirsIndices = logical(zeros([numel(filename), 1]));
    for i=1:numel(filename)
        if ~strcmp(filename{i}, '.') && ~strcmp(filename{i}, '..') && filename{i}(1) ~= '['
            notDirsIndices(i) = 1;
        end
    end
    fn = arrayfun(@(filename) fullfile(BatchOpt.DirectoryName{1}, cell2mat(filename)), filename(notDirsIndices), 'UniformOutput', false);  % generate full paths
    
    if strcmp(BatchOpt.Mode{1}, 'Load each N-th dataset') || strcmp(BatchOpt.Mode{1}, 'Add each N-th dataset as new color channel')
        answer = mibInputDlg({mibPath}, sprintf('There are %d file selected; please enter the loading step:\n\nFor example when step is 2 \nMIB loads each second dataset', numel(fn)),'Enter the step','2');
        if isempty(answer); return; end
        BatchOpt.EachNthStep = answer{1};
    end
    batchModeSwitch = 0;    % indicates that the function is running in the gui mode
end

if numel(fn) < 1
    errordlg(sprintf('No files were selected!!!\nPlease select desired files and try again!\nYou can use Ctrl and Shift for the selection.'), 'Wrong selection!');
    notify(obj.mibModel, 'stopProtocol');
    return; 
end

%%
options.mibBioformatsCheck = BatchOpt.UseBioFormats;
options.waitbar = BatchOpt.showWaitbar;
options.mibPath = mibPath;
options.id = BatchOpt.id;   % id of the current dataset
options.BioFormatsMemoizerMemoDir = obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats
if batchModeSwitch == 1    % batch mode is used
    options.BackgroundColorIntensity = str2double(BatchOpt.BackgroundColorIntensity);   % add background color intensity, for cases when size of the combined slices mismatch; see more in mibLoadImages 
    options.silentMode = true;  % do not ask any questions in the subfunctions, i.e. insertSlice
    options.BioFormatsIndices = str2num(BatchOpt.BioFormatsIndices);    % get indices of images to load using bioformats
end


% if (strcmp(BatchOpt.Mode{1}, 'Load each N-th dataset') || strcmp(BatchOpt.Mode{1}, 'Add each N-th dataset as new color channel')) && numel(filename) == 1     % combines all files in the directory starting from the selected
%     filename = filename(val:end);
% else
%     filename = filename(val);       % take the selected datasets
% end

if strcmp(BatchOpt.Mode{1}, 'Load each N-th dataset') || strcmp(BatchOpt.Mode{1}, 'Add each N-th dataset as new color channel')
    step = str2double(BatchOpt.EachNthStep);
    fn = fn(1:step:end);
end

switch BatchOpt.Mode{1}
    case {'Combine datasets', 'Load each N-th dataset', 'Load part of dataset', 'Combine files as color channels'}
        if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1 && strcmp(BatchOpt.Mode{1}, 'Combine files as color channels')
            toolname = 'The colors can not be combined in the virtual stacking mode.';
            warndlg(sprintf('!!! Warning !!!\n\n%s\nPlease switch to the memory-resident mode and try again', ...
                toolname), 'Not implemented');
            notify(obj.mibModel, 'stopProtocol');
            return;
        end
        
        if strcmp(BatchOpt.Mode{1}, 'Load part of dataset')
            options.customSections = 1;     % to load part of the dataset, for AM only
        end
        options.virtual = obj.mibModel.I{BatchOpt.id}.Virtual.virtual;
        
        if ~strcmp(BatchOpt.Mode{1}, 'Combine files as color channels') 
            [img, img_info, pixSize] = mibLoadImages(fn, options);
            if isempty(img)
                errordlg(sprintf('!!! Error !!!\n\nIt is not possible to load the dataset...\nDimensions mismatch, perhaps?'), 'Wrong file', 'modal');
                notify(obj.mibModel, 'stopProtocol');
                return;
            end
            if isKey(img_info, 'lutColors')
                currColors = img_info('lutColors');
                lutColors = currColors;
                index1 = size(lutColors,1);
                index2 = 1;
                while size(lutColors,1) < size(img,3)
                    lutColors(index1+1, :) = currColors(index2,:);
                    index1 = index1 + 1;
                    index2 = index2 + 1;
                    if index2 > size(currColors,1); index2 = 1; end
                end
                img_info('lutColors') = lutColors;
            end
        else
            for colChannelId = 1:numel(fn)
                if colChannelId==1
                    [img_temp, img_info, pixSize] = mibLoadImages(fn(colChannelId), options);
                    if isempty(img_temp)
                        errordlg(sprintf('!!! Error !!!\n\nIt is not possible to load the dataset...\nDimensions mismatch, perhaps?'), 'Wrong file', 'modal');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                    img = zeros([img_info('Height'), img_info('Width'), img_info('Colors')*numel(fn), img_info('Depth'), img_info('Time')], img_info('imgClass'));
                    img(:,:,1:img_info('Colors'),:,:) = img_temp;
                    lutColors = zeros(img_info('Colors')*numel(fn), 3);
                    if isKey(img_info, 'lutColors')
                        lutTemp = img_info('lutColors');
                        lutColors(1:img_info('Colors'), :) = lutTemp(1:img_info('Colors'));
                    end
                else
                    [img_temp, img_info_temp, pixSize] = mibLoadImages(fn(colChannelId), options);
                    if isempty(img_temp)
                        errordlg(sprintf('!!! Error !!!\n\nIt is not possible to load the dataset...\nDimensions mismatch, perhaps?'), 'Wrong file', 'modal');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                    
                    if img_info('Height') ~= img_info_temp('Height') || img_info('Width') ~= img_info_temp('Width') || ...
                        img_info('Depth') ~= img_info_temp('Depth') || img_info('Time') ~= img_info_temp('Time')
                        errordlg(sprintf('!!! Error !!!\n\nDimensions mismatch!\nWhen combining colors please make sure that your images have the same Height, Width, Depth and Time dimensions'),'Dimensions mismatch');
                        notify(obj.mibModel, 'stopProtocol');
                        return;
                    end
                    img(:,:,colChannelId*img_info('Colors')-img_info('Colors')+1:colChannelId*img_info('Colors'), :, :) = img_temp;
                    if isKey(img_info_temp, 'lutColors')
                        lutTemp = img_info_temp('lutColors');
                        lutColors(colChannelId*img_info('Colors')-img_info('Colors')+1:colChannelId*img_info('Colors'), :) = lutTemp(1:img_info('Colors'));
                    end
                end
            end
            img_info('ColorType') = 'truecolor';
            if isKey(img_info, 'lutColors')
                img_info('lutColors') = lutColors;
            end
            img_info('Colors') = img_info('Colors')*numel(fn);
        end
        
        obj.mibModel.I{BatchOpt.id}.clearContents(img, img_info, obj.mibModel.preferences.disableSelection);
        obj.mibModel.I{BatchOpt.id}.pixSize = pixSize;
        notify(obj.mibModel, 'newDataset');   % notify mibController about a new dataset; see function obj.Listner2_Callback for details
        obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection = [2 1];  % last selected contour for use with the 'e' button
        obj.plotImage(1);
        
        % update list of recent directories
        dirPos = ismember(obj.mibModel.preferences.recentDirs, BatchOpt.DirectoryName{1});
        if sum(dirPos) == 0
            obj.mibModel.preferences.recentDirs = [obj.mibModel.myPath obj.mibModel.preferences.recentDirs];    % add the new folder to the list of folders
            if numel(obj.mibModel.preferences.recentDirs) > 14    % trim the list
                obj.mibModel.preferences.recentDirs = obj.mibModel.preferences.recentDirs(1:14);
            end
        else
            % re-sort the list and put the opened folder to the top of
            % the list
            obj.mibModel.preferences.recentDirs = [obj.mibModel.preferences.recentDirs(dirPos==1) obj.mibModel.preferences.recentDirs(dirPos==0)];
        end
        obj.mibView.handles.mibRecentDirsPopup.String = obj.mibModel.preferences.recentDirs;
    case 'Insert into open dataset'
        if batchModeSwitch == 0
            prompts = {'Dimension:'; ...
                sprintf('Position\n1 - beginning of the open dataset\n0 - end of the open dataset\nor type any number to define position')};
            if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 0
                defAns = {{'depth', 'time', 1}; '0'};
            else
                defAns = {{'depth', 1}; '0'};    
            end
            options.PromptLines = [1, 4];
            dlgtitle = 'Insert dataset';
            options.Title = 'Where the new dataset should be inserted?';
            options.TitleLines = 1;
            options.Focus = 2;
            output = mibInputMultiDlg([], prompts, defAns, dlgtitle, options);
            if isempty(output); return; end
            insertPosition = str2double(output{2});
            options.dim = output{1};
        else
            insertPosition = str2double(BatchOpt.InsertDatasetPosition);
            options.dim = BatchOpt.InsertDatasetDimension{1};
            options.bgColor = str2double(BatchOpt.InsertDatasetPosition);
        end
        options.virtual = obj.mibModel.I{BatchOpt.id}.Virtual.virtual;
        [img, img_info, ~] = mibLoadImages(fn, options);
        obj.mibModel.I{BatchOpt.id}.insertSlice(img, insertPosition, img_info, options);
        
        if obj.mibView.handles.mibLutCheckbox.Value == 1
            obj.mibModel.I{BatchOpt.id}.slices{3} = 1:obj.mibModel.I{BatchOpt.id}.meta('Colors');
        else
            obj.mibModel.I{BatchOpt.id}.slices{3} = 1:min([obj.mibModel.I{BatchOpt.id}.meta('Colors') 3]);
        end
        notify(obj.mibModel, 'newDataset');   % notify mibView about a new dataset; see function obj.mibView.Listner2_Callback for details
        obj.plotImage(1);
    case 'rename'
        if numel(fn) ~= 1
            msgbox('Please select a single file!', 'Rename file', 'warn');
            return;
        end
        %options.Resize='on';
        %options.WindowStyle='normal';
        %options.Interpreter='none';
        [path, filename, ext] = fileparts(fn{1});
        answer = mibInputDlg({obj.mibPath}, 'Please enter new file name','Rename file',[filename, ext]);
        if isempty(answer); return; end
        movefile(fn{1}, fullfile(path, answer{1}));
        obj.updateFilelist(answer{1});
    case 'delete'
        if numel(fn) == 1
            msg = sprintf('You are going to delete\n%s', fn{1});
        else
            msg = sprintf('You are going to delete\n%d files', numel(fn));
        end
        button =  questdlg(msg,'Delete file(s)?','Delete','Cancel','Cancel');
        if strcmp(button, 'Cancel') == 1; return; end
        for i=1:numel(fn)
            delete(fn{i});
        end
        obj.updateFilelist();
    case 'file_properties'
        if exist('fn','var') == 0; return; end
        properties = dir(fn{1});
        msgbox(sprintf('Filename: %s\nDate: %s\nSize: %.3f KB', properties.name, properties.date, properties.bytes/1000),...
            'File info');
    case {'Add as new color channel' 'Add each N-th dataset as new color channel'}   % add color channel
        if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
            toolname = 'The color channels can not be added in the virtual stacking mode.';
            warndlg(sprintf('!!! Warning !!!\n\n%s\nPlease switch to the memory-resident mode and try again', ...
                toolname), 'Not implemented');
            notify(obj.mibModel, 'stopProtocol');
            return;
        end

        [img, img_info, ~] = mibLoadImages(fn, options);
        if isempty(img(1)); notify(obj.mibModel, 'stopProtocol'); return; end
        
        if isKey(img_info, 'lutColors')
            lutColors = img_info('lutColors');
            lutColors = lutColors(1:size(img,3),:);
        else
            lutColors = NaN;
        end
        
        result = obj.mibModel.I{BatchOpt.id}.addColorChannel(img, NaN, lutColors);
        if result == 0; notify(obj.mibModel, 'stopProtocol'); return; end
        notify(obj.mibModel, 'newDataset');   % notify mibView about a new dataset; see function obj.mibView.Listner2_Callback for details
        obj.plotImage(1);
end

unFocus(obj.mibView.handles.mibFilesListbox);   % remove focus from hObject
end