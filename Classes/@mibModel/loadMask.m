function loadMask(obj, mask, BatchOptIn)
% function loadMask(obj, mask, BatchOptIn)
% load mask from a file or import when mask variable is provided
%
%
% Parameters:
% mask: [@em optional], a matrix contaning a mask to load [1:obj.height, 1:obj.width, 1:obj.no_stacks, 1:obj.time]
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .DirectoryName - cell with directory name
% @li .FilenameFilter - filter for filenames or filename of the mask file
% to load, also compatible with template Labels_[F].mask, where [F] - is
% filename of the open dataset
% @li .showWaitbar - show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 
%

%| 
% @b Examples:
% @code obj.mibModel.loadMask();     // call from mibController; load a mask @endcode
% @code obj.mibModel.loadMask(mask, BatchOptIn);     // call from mibController; import a mask @endcode
 
% Copyright (C) 11.09.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3; BatchOptIn = struct(); end
if nargin < 2; mask = []; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.DirectoryName = {obj.myPath};   % specify the target directory
BatchOpt.DirectoryName{2} = {obj.myPath, 'Inherit from dataset filename'};  % this option forces the directories to be provided from the Dir/File loops
BatchOpt.FilenameFilter = 'Mask_[F].mask';
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Load mask';
BatchOpt.mibBatchTooltip.DirectoryName = sprintf('Directory name, where the mask file is located, use the right mouse click over the Parameters table to modify the directory');
BatchOpt.mibBatchTooltip.FilenameFilter = sprintf('Filter for filenames: template with [F] - indicates filename of the open dataset; could also be a filename');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the waitbar');

%% Batch mode check actions
if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
    if isempty(mask)
        if strcmp(BatchOpt.DirectoryName{1}, 'Inherit from dataset filename')   % update mask directory name
            path = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
            if isempty(path)
                BatchOpt.DirectoryName{1} = obj.myPath;
            else
                BatchOpt.DirectoryName{1} = path;
            end
        end
        subFolders = strfind(BatchOpt.FilenameFilter, filesep);     % check for presence of subfolders
        if ~isempty(subFolders)
            BatchOpt.DirectoryName{1} = fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter(1:subFolders(end)));
            BatchOpt.FilenameFilter = BatchOpt.FilenameFilter(subFolders(end)+1:end);
        end
    
        templateDetection = strfind(BatchOpt.FilenameFilter, '[');  % detect [F] template
        if ~isempty(templateDetection)
            [path, fn] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
            BatchOpt.FilenameFilter = sprintf('%s%s%s', ...
                BatchOpt.FilenameFilter(1:templateDetection(1)-1), fn, BatchOpt.FilenameFilter(templateDetection(1)+3:end));
        end
    
        filename = dir(fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter));   % get list of files
        filename2 = arrayfun(@(filename) fullfile(BatchOpt.DirectoryName{1}, filename.name), filename, 'UniformOutput', false);  % generate full paths
        notDirsIndices = arrayfun(@(filename2) ~isdir(cell2mat(filename2)), filename2);     % get indices of not directories
        fn = filename2(notDirsIndices);     % generate full path file names
        filename = {filename(notDirsIndices).name}';
        if isempty(filename)
            errordlg(sprintf('!!! Error !!!\n\nLoad mask: wrong mask name:\n%s', fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter)));
            notify(obj, 'stopProtocol');
            return;
        end
    end
    batchModeSwitch = 1;    % indicates that the function is running in the batch mode
else
    [filename, BatchOpt.DirectoryName{1}] = uigetfile(...
    {'*.mask;',  'Matlab format (*.mask)'; ...
    '*.am;',  'Amira mesh format (*.am)'; ...
    '*.h5',   'Hierarchical Data Format (*.h5)'; ...
    '*.tif;', 'TIF format (*.tif)'; ...
    '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
    '*.*', 'All Files (*.*)'}, ...
    'Open mask data...',  BatchOpt.DirectoryName{1}, 'MultiSelect', 'on');        

    if isequal(filename, 0); return; end % check for cancel
    if ischar(filename); filename = cellstr(filename); end     % convert to cell type
    
    batchModeSwitch = 0;    % indicates that the function is running in the gui mode
end

% check for the virtual stacking mode and return
if obj.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'masks are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

% do nothing is selection is disabled
if obj.I{BatchOpt.id}.disableSelection == 1
    warndlg(sprintf('The mask layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The models are disabled', 'modal');
    return; 
end

tic
% do 3D backup when time == 1
if obj.I{BatchOpt.id}.time < 2
    BackupOpt.id = BatchOpt.id;
    obj.mibDoBackup('mask', 1, BackupOpt); 
end

obj.I{BatchOpt.id}.blockModeSwitch = 0;  % disable the blockMode
if ~isfield(BatchOpt, 'showWaitbar'); BatchOpt.showWaitbar = true; end

setDataOptions.blockModeSwitch = 0;
setDataOptions.id = BatchOpt.id;
[height, width, color, depth, time] = obj.I{obj.Id}.getDatasetDimensions('image', 4, NaN, setDataOptions);

% create mask layer, if needed
if obj.I{BatchOpt.id}.maskExist == 0 && ...
        obj.I{BatchOpt.id}.modelType ~= 63
    obj.I{BatchOpt.id}.maskImg{1} = zeros([height, width, depth, time], 'uint8');
    obj.I{BatchOpt.id}.maskExist = 1;
end

if isempty(mask) % mask and BatchOpt were not provided, load mask from a file
    if BatchOpt.showWaitbar
        warning('off', 'MATLAB:handle_graphics:exceptions:SceneNode');
        wb = waitbar(0,sprintf('%s\nPlease wait.',filename{1}), 'Name', 'Loading mask', 'WindowStyle', 'modal');
        wb.Children.Title.Interpreter = 'none';
        drawnow;
    end
    
    for fnId = 1:numel(filename)
        if strcmp(filename{fnId}(end-1:end),'am') % loading amira mesh
            mask = amiraLabels2bitmap(fullfile(BatchOpt.DirectoryName{1}, filename{fnId}));
        elseif strcmp(filename{fnId}(end-3:end),'mask') % loading matlab format
            mask = load(fullfile(BatchOpt.DirectoryName{1}, filename{fnId}), '-mat');
            field_name = fieldnames(mask);
            mask = mask.(field_name{1});
        elseif strcmp(filename{fnId}(end-1:end),'h5') || strcmp(filename{fnId}(end-2:end),'xml')  % loading mask in hdf5 format
            BatchOpt.mibBioformatsCheck = 0;
            BatchOpt.waitbar = 0;
            mask = mibLoadImages({fullfile(BatchOpt.DirectoryName{1}, filename{fnId})}, BatchOpt);
            %mask = squeeze(mask);
            mask = permute(mask, [1 2 4 5 3]);    % remove 3rd dimension, i.e. color
        else % loading mask in tif format and other standard formats
            options.bioformatsCheck = 0;
            options.progressDlg = 0;
            options.id = obj.Id;   % id of the current dataset
            options.BioFormatsMemoizerMemoDir = obj.preferences.dirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats
            [mask, ~, ~] = mibLoadImages({fullfile(BatchOpt.DirectoryName{1}, filename{fnId})}, options);
            mask =  squeeze(mask);
            mask = uint8(mask>0);    % set masked areas as 1
        end
        
        % check dimensions
        if size(mask,1) == height && size(mask,2) == width
            % do nothing
        elseif size(mask,1) == width && size(mask,2) == height
            % permute
            mask = permute(mask, [2 1 3 4]);
        else
            msgbox('Mask image and loaded image dimensions mismatch!', 'Error!', 'error', 'modal');
            if BatchOpt.showWaitbar; delete(wb); end
            notify(obj, 'stopProtocol');
            return;
        end
        
        if size(mask, 4) > 1 && size(mask, 4) == time   % update complete 4D dataset
            obj.setData4D('mask', mask, 4, 0, setDataOptions);
        elseif size(mask, 4) == 1 && size(mask,3) == depth  % update complete 3D dataset
            if numel(filename) > 1
                obj.setData3D('mask', mask, fnId, 4, 0, setDataOptions);
            else
                obj.setData3D('mask', mask, NaN, 4, 0, setDataOptions);
            end
        elseif size(mask, 4) == 1 && size(mask,3) < depth  % mask is smaller than the dataset
            setDataOptions.z = [1 size(mask,3)];
            if batchModeSwitch == 0
                answer = questdlg(sprintf('!!! Warning !!!\n\nDepth of the Mask is smaller than the size of the dataset\nDataset dimensions:\nheight x width x colors x depth x time: %d x %d x %d x %d x %d\n\nMask dimensions: %s\n\nWould you like to load it?', ...
                    height, width, color, depth, time, num2str(size(mask))), 'Load a mask', 'Load', 'Cancel', 'Load');
                if strcmp(answer, 'Cancel')
                    if BatchOpt.showWaitbar; delete(wb); end
                    return; 
                end
            end
            
            if numel(filename) > 1
                obj.setData3D('mask', mask, fnId, 4, 0, setDataOptions);
            else
                obj.setData3D('mask', mask, NaN, 4, 0, setDataOptions);
            end
        elseif size(mask, 4) == 1 && size(mask,3) > depth  % mask is larger than the dataset
            if batchModeSwitch == 0
                answer = questdlg(sprintf('!!! Warning !!!\n\nDepth of the Mask is larger than the size of the dataset\nDataset dimensions:\nheight x width x colors x depth x time: %d x %d x %d x %d x %d\n\nMask dimensions: %s\n\nWould you like to load it?', ...
                    height, width, color, depth, time, num2str(size(mask))), 'Load a mask', 'Load', 'Cancel', 'Load');
                if strcmp(answer, 'Cancel'); if BatchOpt.showWaitbar; delete(wb); end; return; end
            end
            
            if numel(filename) > 1
                obj.setData3D('mask', mask, fnId(1:depth), 4, 0, setDataOptions);
            else
                obj.setData3D('mask', mask(:,:,1:depth), NaN, 4, 0, setDataOptions);
            end
        elseif size(mask, 3) == 1
            if numel(filename) > 1
                obj.setData2D('mask', mask, fnId, 4, 0, setDataOptions);
            else
                obj.setData2D('mask', mask, NaN, 4, 0, setDataOptions);
            end
        end
        if BatchOpt.showWaitbar; waitbar(fnId/numel(filename), wb); end
    end
    obj.I{BatchOpt.id}.maskImgFilename = fullfile(BatchOpt.DirectoryName{1}, filename{1});
else
    if BatchOpt.showWaitbar; wb = waitbar(0,sprintf('Importing the mask\nPlease wait.'), 'Name', 'Loading mask', 'WindowStyle', 'modal'); end
    [pathTemp, fnTemplate] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
    
    obj.I{BatchOpt.id}.maskImgFilename = fullfile(pathTemp, ['Mask_' fnTemplate '.mask']); 
    
    % check H/W/Z dimensions
    if size(mask, 1) ~= obj.I{BatchOpt.id}.height || size(mask,2) ~= obj.I{BatchOpt.id}.width || size(mask,3) ~= obj.I{BatchOpt.id}.depth
        if BatchOpt.showWaitbar; delete(wb); end
        notify(obj, 'stopProtocol');
        msgbox(sprintf('mask and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nmask (HxWxZ) = %d x %d x %d pixels',...
            obj.I{BatchOpt.id}.height, obj.I{BatchOpt.id}.width, obj.I{BatchOpt.id}.depth, size(mask,1), size(mask,2), size(mask,3)),'Error!','error','modal');
        return;
    end
    
    if size(mask, 4) > 1 && size(mask, 4) == obj.I{BatchOpt.id}.time   % update complete 4D dataset
        obj.setData4D('mask', {mask}, 4, NaN, BatchOpt);
    elseif size(mask, 4) == 1 && size(mask,3) == obj.I{BatchOpt.id}.depth  % update complete 3D dataset
        obj.setData3D('mask', {mask}, NaN, 4, NaN, BatchOpt);
    elseif size(mask, 3) == 1
        obj.setData2D('mask', {mask}, NaN, 4, NaN, BatchOpt);
    else
        
    end
end

if BatchOpt.showWaitbar; waitbar(1,wb); end

eventdata = ToggleEventData(1);   % show the mask checkbox on
notify(obj, 'showMask', eventdata);

if BatchOpt.showWaitbar; delete(wb); end
toc
end