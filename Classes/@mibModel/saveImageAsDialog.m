function fnOut = saveImageAsDialog(obj, filename, BatchOptIn)
% function fnOut = saveImageAsDialog(obj, filename, BatchOptIn)
% save image to a file
%
% Parameters:
% filename: [@em optional] a string with filename, when empty asks for a dialog
% when provided the extension will define the output format, unless the
% format is provided in the BatchOptIn structure
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Format - a string with the output format, as in the Formats variable below, for example 'Amira Mesh binary file sequence (*.am)'
% @li .filenameGenerator - a string, when 'sequential' the filenames will be
%   generated as a sequence, when 'original' the original filenames will be used
% @li .DestinationDirectory - a string with destination directory, if filename has no full path
% @li .showWaitbar - logical show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% fnOut: a string with the output filename

% Copyright (C) 29.08.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

fnOut = [];
if nargin < 3; BatchOptIn = struct(); end
if nargin < 2; filename = []; end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
if isfield(BatchOptIn, 'id')
    BatchOpt.id = BatchOptIn.id;   % optional, id
else
    BatchOpt.id = obj.Id;   % optional, id    
end
if ~isempty(filename)
    BatchOpt.Filename = filename;
else
    [path, fn, ext] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
    BatchOpt.Filename = fn;
end
BatchOpt.FilenamePolicy = {'Use existing name'};
BatchOpt.FilenamePolicy{2} = {'Use existing name', 'Use new provided name'};
BatchOpt.Format = {'TIF format uncompressed (*.tif)'};
BatchOpt.Format{2} = {'Amira Mesh binary (*.am)', ...
                      'Amira Mesh binary file sequence (*.am)',...
                      'Joint Photographic Experts Group (*.jpg)', ...
                      'Hierarchical Data Format (*.h5)', ...
                      'MRC format for IMOD (*.mrc)', ...
                      'NRRD Data Format (*.nrrd)',...
                      'Portable Network Graphics (*.png)',...
                      'TIF format LZW compression (*.tif)',...
                      'TIF format uncompressed (*.tif)',...
                      'OME-TIFF 5D (*.tiff)',...
                      'OME-TIFF 2D sequence (*.tiff)',...
                      'Hierarchical Data Format with XML header (*.xml)'};
                 
BatchOpt.OutputDirectoryPolicy = {'Subfolder'};
BatchOpt.OutputDirectoryPolicy{2} = {'Subfolder', 'Full path', 'Same as loaded'};
BatchOpt.DestinationDirectory = 'MIB_SaveAs';
BatchOpt.FilenameGenerator = {'Use sequential filename'};
BatchOpt.FilenameGenerator{2} = {'Use original filename', 'Use sequential filename'};
BatchOpt.Saving3DPolicy = {'3D stack'};
BatchOpt.Saving3DPolicy{2} = {'3D stack','2D sequence'};
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Menu -> File';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Save dataset';
BatchOpt.mibBatchTooltip.Filename = sprintf('[Use new provided name only]: new filename for the image');
BatchOpt.mibBatchTooltip.FilenamePolicy = sprintf('Use existing name: the filename used during loading of the model; Use new provided name: filename provided in Filename field');
BatchOpt.mibBatchTooltip.Format = sprintf('Available file formats for saving images');
BatchOpt.mibBatchTooltip.OutputDirectoryPolicy = sprintf('Subfolder: to subfolder, relative to loading; Full path: save to the provided in DestinationDirectory path; Same as loaded: to the same folder from where images were loaded');
BatchOpt.mibBatchTooltip.DestinationDirectory = sprintf('Destination directory without the leading slash for the Subfolder policy, or the full path for the Provided full path policy');
BatchOpt.mibBatchTooltip.FilenameGenerator = sprintf('Original: the filename template from the original; Sequential: filenames tempate from the provided Filename');
BatchOpt.mibBatchTooltip.Saving3DPolicy = sprintf('[TIF only] save images as 3D TIF file or as a sequence of 2D files');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the waitbar');

% additional tweaks
if ~isempty(filename)   % if filename is provided
    [path, fn, ext] = fileparts(filename);
    if isempty(path)    % update DestinationDirectory
        BatchOpt.DestinationDirectory = obj.myPath; 
    else
        BatchOpt.DestinationDirectory = path; 
    end
    BatchOpt.Filename = [fn ext];
    BatchOpt.OutputDirectoryPolicy{1} = 'Full path';    % update OutputDirectoryPolicy
    
    % identify the format from extension
    if ~isfield(BatchOptIn, 'Format')
        formatIndex = [];
        for i=1:numel(BatchOpt.Format{2})
            extStr = BatchOpt.Format{2}{i}(strfind(BatchOpt.Format{2}{i}, '*')+1:end-1);
            if strcmp(extStr, ext); formatIndex = i; break; end
        end
        if isempty(formatIndex)
            errordlg('The output format can''t be identified!', 'Error!'); 
            notify(obj, 'stopProtocol');
            return;
        else
            BatchOpt.Format{1} = BatchOpt.Format{2}{formatIndex};
        end
    end
end

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
    
    %filename = dir(fullfile(BatchOpt.DirectoryName{1}, BatchOpt.FilenameFilter));   % get list of files
    %filename2 = arrayfun(@(filename) fullfile(BatchOpt.DirectoryName{1}, filename.name), filename, 'UniformOutput', false);  % generate full paths
    %notDirsIndices = arrayfun(@(filename2) ~isdir(cell2mat(filename2)), filename2);     % get indices of not directories
    %fn = filename2(notDirsIndices);     % generate full path file names
    %filename = {filename(notDirsIndices).name}';
    %batchModeSwitch = 1;    % indicates that the function is running in the batch mode
else
    %% the standard mode, when only the output file is provided
    fnOut = obj.I{BatchOpt.id}.saveImageAsDialog(fullfile(BatchOpt.DestinationDirectory, BatchOpt.Filename));
    return;
end
%% when used in standard mode with parameters
if ~isfield(BatchOptIn, 'mibBatchTooltip')  % not using the batch mode
    fnOut = obj.I{BatchOpt.id}.saveImageAsDialog(filename, BatchOptIn);
    return;
end

%% code below is responsible for the batch mode
switch BatchOpt.OutputDirectoryPolicy{1}
    case 'Subfolder'
        [path, fn, ext] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
        BatchOpt.DestinationDirectory = fullfile(path, BatchOpt.DestinationDirectory);
        if exist(BatchOpt.DestinationDirectory, 'dir') ~= 7; mkdir(BatchOpt.DestinationDirectory); end  % create a new directory
        BatchOpt.OutputDirectoryPolicy{1} = 'Full path';    % change the policy
    case 'Same as loaded'
        BatchOpt.DestinationDirectory = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
        BatchOpt.OutputDirectoryPolicy{1} = 'Full path';    % change the policy
end

if strcmp(BatchOpt.FilenamePolicy{1}, 'Use existing name')
    [~, BatchOpt.Filename] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
end

saveImageOptions.Format = BatchOpt.Format{1};
saveImageOptions.FilenameGenerator = BatchOpt.FilenameGenerator{1};
saveImageOptions.DestinationDirectory = BatchOpt.DestinationDirectory;
saveImageOptions.Saving3DPolicy = BatchOpt.Saving3DPolicy{1};
saveImageOptions.showWaitbar = BatchOpt.showWaitbar;
saveImageOptions.silent = true;

[~, fn, ext] = fileparts(BatchOpt.Filename);
ext = saveImageOptions.Format(strfind(saveImageOptions.Format, '*')+1:end-1);
BatchOpt.Filename = [fn ext];

fnOut = obj.I{BatchOpt.id}.saveImageAsDialog(BatchOpt.Filename, saveImageOptions);

