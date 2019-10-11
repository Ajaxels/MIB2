function fnOut = saveMask(obj, filename, BatchOptIn)
% function fnOut = saveMask(obj, filename, BatchOptIn)
% save mask to a file
%
% Parameters:
% filename: string with output filename, when empty a save as dialog is prompted a string,
% otherwise save the mask in the detected format. Additional settings may
% be provided via BatchOptIn structure
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
%
% Return values:
% fnOut: a string with the output mask filename
%
% Copyright (C) 10.09.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
    [DestinationDirectory, fn, ext] = fileparts(filename);
    BatchOpt.Filename = [fn, ext];
else
    if ~isempty(obj.I{BatchOpt.id}.maskImgFilename)
        [DestinationDirectory, fn, ext] = fileparts(obj.I{BatchOpt.id}.maskImgFilename);
    else
        [DestinationDirectory, fn, ext] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
        fn = sprintf('Mask_%s.mask', fn);
    end
    BatchOpt.Filename = fn;
end
BatchOpt.FilenamePolicy = {'Use existing name'};
BatchOpt.FilenamePolicy{2} = {'Use existing name', 'Use new provided name'};
BatchOpt.Format = {'Matlab format (*.mask)'};
BatchOpt.Format{2} = {'Matlab format (*.mask)', ...
                      'Amira mesh binary (*.am)',...
                      'Amira mesh binary RLE compression SLOW (*.am)', ...
                      'Hierarchical Data Format (*.h5)', ...
                      'TIF format (*.tif)', ...
                      'Hierarchical Data Format with XML header (*.xml)'};
BatchOpt.OutputDirectoryPolicy = {'Same as image'};
BatchOpt.OutputDirectoryPolicy{2} = {'Subfolder', 'Full path', 'Same as image'};
if ~isempty(DestinationDirectory)
    BatchOpt.DestinationDirectory = DestinationDirectory; 
else
    BatchOpt.DestinationDirectory = '';
end
BatchOpt.Saving3DPolicy = {'3D stack'};
BatchOpt.Saving3DPolicy{2} = {'3D stack', '2D sequence'};
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Save mask';

BatchOpt.mibBatchTooltip.Filename = sprintf('[Use new provided name only]: new filename for the mask; it is possible to use template [F] that encodes the filename, as for example, Mask_[F]_suffix');
BatchOpt.mibBatchTooltip.FilenamePolicy = sprintf('Use existing name: the filename used during loading of the mask or generated from the dataset name; Use new provided name: filename provided in Filename field');
BatchOpt.mibBatchTooltip.Format = sprintf('Available file formats for saving masks');
BatchOpt.mibBatchTooltip.OutputDirectoryPolicy = sprintf('Subfolder: to a subfolder, relative to the image path; Full path: in the DestinationDirectory path; Same as image: to the image dataset folder');
BatchOpt.mibBatchTooltip.DestinationDirectory = sprintf('Destination directory without the leading slash for the Subfolder policy, or the full path for the Provided full path policy');
BatchOpt.mibBatchTooltip.Saving3DPolicy = sprintf('[TIF only] save images as 3D TIF file or as a sequence of 2D files');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the waitbar');

% additional tweaks
if ~isempty(filename)   % if filename is provided
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
else
    %% the standard mode, when only the output file is provided
    saveImageOptions.MaskColor = obj.preferences.maskcolor;
    fnOut = obj.I{BatchOpt.id}.saveMask(filename, saveImageOptions);
    return;
end
%% when used in standard mode with parameters
if ~isfield(BatchOptIn, 'mibBatchTooltip')  % not using the batch mode
    BatchOptIn.MaskColor = obj.preferences.maskcolor;
    fnOut = obj.I{BatchOpt.id}.saveMask(filename, BatchOptIn);
    return;
end

%% code below is responsible for the batch mode
switch BatchOpt.OutputDirectoryPolicy{1}
    case 'Subfolder'
        [path, fn, ext] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
        BatchOpt.DestinationDirectory = fullfile(path, BatchOpt.DestinationDirectory);
        if exist(BatchOpt.DestinationDirectory, 'dir') ~= 7; mkdir(BatchOpt.DestinationDirectory); end  % create a new directory
        BatchOpt.OutputDirectoryPolicy{1} = 'Full path';    % change the policy
    case 'Same as image'
        BatchOpt.DestinationDirectory = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
        BatchOpt.OutputDirectoryPolicy{1} = 'Full path';    % change the policy
end

if strcmp(BatchOpt.FilenamePolicy{1}, 'Use existing name')
    if isempty(obj.I{BatchOpt.id}.maskImgFilename)
        [~, BatchOpt.Filename] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
        BatchOpt.Filename = sprintf('Mask_%s', BatchOpt.Filename);
    else
        [~, BatchOpt.Filename] = fileparts(obj.I{BatchOpt.id}.maskImgFilename);
    end
else
    templateDetection = strfind(BatchOpt.Filename, '[');  % detect [F] template
    if ~isempty(templateDetection)
        [path, fn] = fileparts(obj.I{BatchOpt.id}.meta('Filename'));
        BatchOpt.Filename = sprintf('%s%s%s', ...
            BatchOpt.Filename(1:templateDetection(1)-1), fn, BatchOpt.Filename(templateDetection(1)+3:end));
    end
end

saveImageOptions.Format = BatchOpt.Format{1};
saveImageOptions.DestinationDirectory = BatchOpt.DestinationDirectory;
saveImageOptions.Saving3DPolicy = BatchOpt.Saving3DPolicy{1};
saveImageOptions.showWaitbar = BatchOpt.showWaitbar;
saveImageOptions.silent = true;
saveImageOptions.MaskColor = obj.preferences.maskcolor;
[~, fn, ext] = fileparts(BatchOpt.Filename);
ext = saveImageOptions.Format(strfind(saveImageOptions.Format, '*')+1:end-1);
BatchOpt.Filename = [fn ext];

fnOut = obj.I{BatchOpt.id}.saveMask(BatchOpt.Filename, saveImageOptions);
if isempty(fnOut); notify(obj, 'stopProtocol'); end
end
