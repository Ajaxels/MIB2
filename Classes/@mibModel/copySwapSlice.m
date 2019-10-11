function copySwapSlice(obj, SourceSlice, TargetSlice, mode, BatchOptIn)
% function copySwapSlice(obj, SourceSlice, TargetSlice, mode, BatchOptIn)
% Copy/swap slice(s) within the dataset
%
% Parameters:
% SourceSlice: number of the source slice, can be empty: []
% TargetSlice: number of the destination slice
% mode: a string with desired mode:
%   ''replace'' - replace the target slice with the source slice [@em default]
%   ''insert'' - insert the target slice before the source slice
%   ''swap'' - swap source and target slices
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Mode - cell string, "swap": swap two slices; "replace": replace target slice with source slice; "insert" - insert source slice before target slice
% @li .SourceSlice - string, index(es) of the source slice(es)
% @li .TargetSlice - string, index(es) of the destinations slice(es)
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 

%| 
% @b Examples:
% @code 
% // for the normal mode
% obj.mibModel.copySlice(4, 10); // call from mibController class; copy slice 4 to slice 10
% obj.mibModel.copySlice(4, 10, 'swap'); // call from mibController class; swap slice 4 and slice 10
% obj.mibModel.copySlice(4, 10, 'insert'); // call from mibController class; insert slice 4 and before slice 10
% @endcode
% @code 
% // for the batch mode
% BatchOptIn.Dimension = {'time'};     // delete slice from the time domain, otherwise use {'depth'}
% BatchOptIn.DeletePosition = '2:10';     // define positions, where delete the slices
% obj.mibModel.deleteSlice([], [], BatchOptIn); // call from mibController class; in the batch mode
% @endcode

% Copyright (C) 20.05.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates

global mibPath; % path to mib installation folder

if nargin < 4; mode = []; end
if nargin < 3
    errordlg(sprintf('!!! Error !!!\n\nmibModel.copySlice:\nTarget slice is required!'));
    return; 
end

%% populate BatchOpt with default values
BatchOpt = struct();
if ~isempty(mode)
    BatchOpt.Mode = {mode};
else
    BatchOpt.Mode = {'replace'};
end
BatchOpt.Mode{2} = {'replace', 'insert', 'swap'};  % cell array with options

if isempty(SourceSlice)
    BatchOpt.SourceSlice = num2str(obj.I{obj.Id}.getCurrentSliceNumber()); % string, source position
else
    BatchOpt.SourceSlice = num2str(SourceSlice);
end

if isempty(TargetSlice)
    BatchOpt.TargetSlice = BatchOpt.SourceSlice; % string, destination position
else
    BatchOpt.TargetSlice = num2str(SourceSlice);
end
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
if strcmp(BatchOpt.Mode{1}, 'swap')
    BatchOpt.mibBatchActionName = 'Slice -> Swap slices';
else
    BatchOpt.mibBatchActionName = 'Slice -> Copy slice';
end
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Mode = sprintf('"swap": swap two slices; "replace": replace target slice with source slice; "insert" - insert source slice before target slice');
BatchOpt.mibBatchTooltip.SourceSlice = sprintf('index(es) of the source slice(es)');
BatchOpt.mibBatchTooltip.TargetSlice = sprintf('index(es) of the destinations slice(es)');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 5  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 2nd parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

%% define parameters
maxSlice = obj.I{BatchOpt.id}.dim_yxczt(obj.I{BatchOpt.id}.orientation);
if nargin < 5
    if strcmp(mode, 'swap')
        textString1 = 'Index or indices of the source slice(s):';
        textString2 = 'Index or indices of the destination slice(s):';
        mibInputMultiDlgOptions.PromptLines = [1, 1, 1];
    else
        textString1 = 'Index of the source slice:';
        textString2 = 'Index of the destination slice (use 0 to insert the slice at the end of the dataset):';
        mibInputMultiDlgOptions.PromptLines = [1, 1, 2];
    end
    
    prompt = {'Replace or insert slice at the destination:', textString1, textString2};
    defAns = {[BatchOpt.Mode{2}, find(ismember(BatchOpt.Mode{2}, BatchOpt.Mode{1})==1)], ...
        BatchOpt.SourceSlice, BatchOpt.TargetSlice};
    
    mibInputMultiDlgOptions.Title = sprintf('Please enter the slice numbers (1-%d)', maxSlice);
    mibInputMultiDlgOptions.TitleLines = 2;
    
    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Copy slice', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    BatchOpt.Mode(1) = answer(1);
    BatchOpt.SourceSlice = answer{2};
    BatchOpt.TargetSlice = answer{3};
end

SourceSlice = str2num(BatchOpt.SourceSlice); %#ok<ST2NM>
TargetSlice = str2num(BatchOpt.TargetSlice); %#ok<ST2NM>

if isempty(SourceSlice) || isempty(TargetSlice)
    errordlg(sprintf('!!! Error !!!\n\nWrong format of SourceSlice or TargetSlice'));
    notify(obj, 'stopProtocol');
    return;
end

if TargetSlice == 0
    BatchOpt.Mode{1} = 'insert';
    TargetSlice = maxSlice + 1; %:maxSlice+numel(sliceNumberFrom); 
end

switch BatchOpt.Mode{1}
    case 'replace'
        result = obj.I{BatchOpt.id}.copySlice(SourceSlice, TargetSlice, NaN, BatchOpt); 
        if result == 0; notify(obj, 'stopProtocol'); return; end
    case 'insert'
        getDataOpt.blockmodeSwitch = 0;
        getDataOpt.id = BatchOpt.id;
        img = cell2mat(obj.getData2D('image', SourceSlice(1), NaN, NaN, getDataOpt));
        if isKey(obj.I{BatchOpt.id}.meta, 'SliceName')
            SliceName = obj.I{BatchOpt.id}.meta('SliceName');
            if numel(SliceName) > 1
                meta = containers.Map;
                SliceName = SliceName{SourceSlice};
                [~, fn, ext] = fileparts(SliceName);
                SliceName = [fn '_copy' ext];
                meta('SliceName') = cellstr(SliceName);
            else
                meta = containers.Map;
            end
        else
            meta = containers.Map;
        end
        obj.I{BatchOpt.id}.insertSlice(img, TargetSlice, meta, BatchOpt);
        notify(obj, 'newDataset');  % notify newDataset
    case 'swap'
        result = obj.I{BatchOpt.id}.swapSlices(SourceSlice, TargetSlice, NaN, BatchOpt); 
        if result == 0; notify(obj, 'stopProtocol'); return; end
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');  % notify plotImage
end