function contrastCLAHE(obj, mode, BatchOptIn)
% function contrastCLAHE(obj, mode, BatchOptIn)
% Do CLAHE Contrast-limited adaptive histogram equalization for the XY plane of the dataset for the currently shown or
% all slices
%
% Parameters:
% mode: [@em optional], mode for use with CLAHE
% - ''Shown slice (2D)'', contrast adjustment with CLAHE method for the current slice
% - ''Current stack (3D)'', contrast adjustment with CLAHE method for the shown stack
% - ''Complete volume (4D)'', contrast adjustment with CLAHE method for the whole dataset
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Mode - cell string {'Shown slice (2D)','Current stack (3D)','Complete volume (4D)'} - dataset type
% @li .ColChannel = {'All channels', 'Shown channels', 'ColCh 1'} - color channels for CLAHE
% @li .NumTiles - string, number of tiles
% @li .ClipLimit - string, contrast enhancement limit
% @li .NBins - string, number of histogram bins used to build a contrast enhancing transformation
% @li .Distribution - cell string, {'uniform', 'rayleigh', 'exponential'} - desired histogram shape
% @li .Alpha - string, distribution parameter, for 'rayleigh' and 'exponential'
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
%

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 28.04.2019, updated for the batch mode

global mibPath;

if nargin < 2; mode = []; end
if ~isempty(mode); obj.preferences.CLAHE.Mode = mode; end
if ~isfield(obj.preferences.CLAHE, 'Mode'); obj.preferences.CLAHE.Mode = 'Current stack (3D)'; end

%% Declaration of the BatchOpt structure
PossibleColChannels = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.I{obj.Id}.colors, 'UniformOutput', false);
PossibleColChannels = ['All channels', 'Shown channels', PossibleColChannels];
BatchOpt = struct();
BatchOpt.Mode = {obj.preferences.CLAHE.Mode};     % define dataset type
BatchOpt.Mode{2} = {'Shown slice (2D)','Current stack (3D)','Complete volume (4D)'};
BatchOpt.ColChannel = {'All channels'};     % Define color channels for CLAHE
BatchOpt.ColChannel{2} = PossibleColChannels;
BatchOpt.NumTiles = num2str(obj.preferences.CLAHE.NumTiles); % Number of tiles
BatchOpt.ClipLimit = num2str(obj.preferences.CLAHE.ClipLimit);   %  Contrast enhancement limit
BatchOpt.NBins = num2str(obj.preferences.CLAHE.NBins);   %  Number of histogram bins used to build a contrast enhancing transformation
BatchOpt.Distribution = {obj.preferences.CLAHE.Distribution};   % Desired histogram shape
BatchOpt.Distribution{2} = {'uniform', 'rayleigh', 'exponential'};
BatchOpt.Alpha = num2str(obj.preferences.CLAHE.Alpha);   % Distribution parameter, for 'rayleigh' and 'exponential'
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Image';
BatchOpt.mibBatchActionName = 'Contrast -> Contrast-limited adaptive histogram equalization';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Mode = sprintf('Specify part of the dataset for CLAHE');
BatchOpt.mibBatchTooltip.ColChannel = sprintf('Specify color channels for CLAHE');
BatchOpt.mibBatchTooltip.NumTiles = sprintf('Type 2 values to specify number of tiles');
BatchOpt.mibBatchTooltip.ClipLimit = sprintf('Contrast enhancement limit');
BatchOpt.mibBatchTooltip.NBins = sprintf('Number of histogram bins used to build a contrast enhancing transformation');
BatchOpt.mibBatchTooltip.Distribution = sprintf('Specify histogram shape');
BatchOpt.mibBatchTooltip.Alpha = sprintf('["rayleigh" and "exponential"]:\nDistribution parameter');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

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
end

% check for the virtual stacking mode
if obj.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'contrast normalization';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

% check for color type
if strcmp(obj.I{BatchOpt.id}.meta('ColorType'), 'indexed')
    msgbox(sprintf('Please convert to grayscale or truecolor data format first!\nMenu->Image->Mode->'),...
        'Change format!', 'error', 'modal');
    notify(obj, 'stopProtocol');
    return;
end

% not batch mode, check for settings
if nargin < 3
    prompt = {'Mode:', 'Color channel:','Number of Tiles:',...
        'Clip Limit in the range [0 1] that specifies a contrast enhancement limit. Higher numbers result in more contrast:',...
        'NBins, a positive integer scalar specifying the number of bins for the histogram used in building a contrast enhancing transformation. Higher values result in greater dynamic range at the cost of slower processing speed:',...
        'Distribution:',...
        'Alpha, a nonnegative real scalar specifying a distribution parameter, not for uniform distribution:'};
    
    defAns = {[BatchOpt.Mode{2}, find(ismember(BatchOpt.Mode{2}, BatchOpt.Mode{1})==1)],...
        [BatchOpt.ColChannel{2}, 1],...
        BatchOpt.NumTiles, BatchOpt.ClipLimit, BatchOpt.NBins, ...
        [BatchOpt.Distribution{2}, find(ismember(BatchOpt.Distribution{2}, BatchOpt.Distribution{1})==1)],...
        BatchOpt.Alpha};
    mibInputMultiDlgOpt.PromptLines = [1, 1, 1, 3, 5, 1, 2];
    mibInputMultiDlgOpt.Title = sprintf('You are going to change image contrast by Contrast-limited adaptive histogram equalization\nYou can always undo it with Ctrl-Z');
    mibInputMultiDlgOpt.TitleLines = 3;
    mibInputMultiDlgOpt.Columns = 2;
    mibInputMultiDlgOpt.WindowWidth = 2;
    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Enter CLAHE parameters', mibInputMultiDlgOpt);
    if isempty(answer); return; end
    
    BatchOpt.Mode(1) = answer(1);
    BatchOpt.ColChannel(1) = answer(2);
    BatchOpt.NumTiles = answer{3};
    BatchOpt.ClipLimit = answer{4};
    BatchOpt.NBins = answer{5};
    BatchOpt.Distribution(1) = answer(6);
    BatchOpt.Alpha = answer{7};
end

tic
if BatchOpt.showWaitbar; wb = waitbar(0,'Adjusting contrast with CLAHE...', 'Name', 'CLAHE', 'WindowStyle', 'modal'); end

[maxH, maxW, maxC, maxZ, maxT] = obj.I{BatchOpt.id}.getDatasetDimensions('image', NaN);

switch BatchOpt.Mode{1}
    case 'Shown slice (2D)'
        if ~isfield(BatchOpt, 't')
            BatchOpt.t = [obj.I{BatchOpt.id}.getCurrentTimePoint(), obj.I{BatchOpt.id}.getCurrentTimePoint()];
        end
        if ~isfield(BatchOpt, 'z')
            BatchOpt.z = [obj.I{BatchOpt.id}.getCurrentSliceNumber(), obj.I{BatchOpt.id}.getCurrentSliceNumber()];
        end
    case 'Current stack (3D)'
        if ~isfield(BatchOpt, 't')
            BatchOpt.t = [obj.I{BatchOpt.id}.getCurrentTimePoint(), obj.I{BatchOpt.id}.getCurrentTimePoint()];
        end
        if ~isfield(BatchOpt, 'z')
            BatchOpt.z = [1, maxZ];
        end
    case 'Complete volume (4D)'
        if ~isfield(BatchOpt, 't')
            BatchOpt.t = [1 maxT];
        end
        if ~isfield(BatchOpt, 'z')
            BatchOpt.z = [1, maxZ];
        end
end
if BatchOpt.t(1) == BatchOpt.t(2)     % do backup
    backupOpt.z = BatchOpt.z;
    backupOpt.t = BatchOpt.t;
    backupOpt.id = BatchOpt.id;
    obj.mibDoBackup('image', 1, backupOpt);
end

% obtain the color channel
switch BatchOpt.ColChannel{1}
    case 'All channels'
        colorChannel = 1:obj.I{BatchOpt.id}.colors;
    case 'Shown channels'
        colorChannel = maxC;
    otherwise
        colorChannel = str2double(BatchOpt.ColChannel{1}(7:end));
end

NumTiles = str2num(BatchOpt.NumTiles); %#ok<ST2NM>
if numel(NumTiles)==1
    NumTiles = [NumTiles, NumTiles]; 
    BatchOpt.NumTiles = sprintf('%d, %d', NumTiles(1), NumTiles(2));
end
ClipLimit = str2double(BatchOpt.ClipLimit);
NBins = str2double(BatchOpt.NBins);
Distribution = BatchOpt.Distribution{1};
Alpha = str2double(BatchOpt.Alpha);

getDataOptions.roiId = [];  % enable use of the ROI mode
getDataOptions.id = BatchOpt.id;
maxWaitbarIndex = (BatchOpt.t(2)-BatchOpt.t(1)+1)*(BatchOpt.z(2)-BatchOpt.z(1)+1);
waitbarIndex = 1;
for colCh = 1:numel(colorChannel)
    for t=BatchOpt.t(1):BatchOpt.t(2)
        getDataOptions.t = [t t];
        for z=BatchOpt.z(1):BatchOpt.z(2)
            img = obj.getData2D('image', z, NaN, colorChannel(colCh), getDataOptions);
            
            for ind = 1:numel(img)
                img2 = img{ind};
                
                if strcmp(Distribution,'uniform')
                    img2 = adapthisteq(img2,...
                        'NumTiles', NumTiles, 'clipLimit', ClipLimit, 'NBins', NBins, 'Distribution', Distribution);
                else
                    img2 = adapthisteq(img2,...
                        'NumTiles', NumTiles, 'clipLimit', ClipLimit, 'NBins', NBins, 'Distribution', Distribution, 'Alpha', Alpha);
                end
                img{ind} = img2;
            end
            obj.setData2D('image', img, z, NaN, colorChannel(colCh), getDataOptions);
            
            if BatchOpt.showWaitbar
                waitbar(waitbarIndex/maxWaitbarIndex, wb); 
                waitbarIndex = waitbarIndex + 1;
            end
        end
    end
end

log_text = ['CLAHE; NumTiles: ' num2str(obj.preferences.CLAHE.NumTiles) ';clipLimit: ' num2str(obj.preferences.CLAHE.ClipLimit)...
    ';NBins:' num2str(obj.preferences.CLAHE.NBins) ';Distribution:' obj.preferences.CLAHE.Distribution ';Alpha:' num2str(obj.preferences.CLAHE.Alpha) ';ColCh:' num2str(colCh)];
obj.I{BatchOpt.id}.updateImgInfo(log_text);

% update preference settings
obj.preferences.CLAHE.NumTiles = NumTiles;
obj.preferences.CLAHE.ClipLimit = ClipLimit;
obj.preferences.CLAHE.NBins = NBins;
obj.preferences.CLAHE.Distribution = Distribution;
obj.preferences.CLAHE.Alpha = Alpha;

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');  % notify to plot the image

if BatchOpt.showWaitbar; delete(wb); end
toc
end
