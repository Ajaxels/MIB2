function insertEmptySlice(obj, BatchOptIn)
% function insertEmptySlice(obj, BatchOptIn)
% Insert an empty slice into the existing volume
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event
% @li .Dimension - a cell string with targeted dimension: {'depth', 'time'}; 
% @li .InsertPosition - char, position where to insert the new slice/volume starting from @b 1, when @em 0 - add img to the end of the dataset
% @li .BackgroundColor = char, intensity of the background color
% @li .showWaitbar = true;   % logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Return values:
% 

%| 
% @b Examples:
% @code 
% BatchOptIn.Dimension = {'time'};     // define add a dataset as a new time point
% BatchOptIn.InsertPosition = '2';     // define to insert the empty image to the second frame
% BatchOptIn.BackgroundColor = '128';     // define background intensity
% obj.mibModel.insertEmptySlice(BatchOptIn); // call from mibController class; add img as a new time point
% @endcode

% Copyright (C) 09.05.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates

global mibPath; % path to mib installation folder

% populate default values
BatchOpt = struct();
BatchOpt.Dimension = {'depth'}; % a cell string with targeted dimension
BatchOpt.Dimension{2} = {'depth', 'time'};  % cell array with options
BatchOpt.InsertPosition = num2str(obj.I{obj.Id}.getCurrentSliceNumber());    % char, position where to insert the new slice/volume starting from @b 1, when @em 0 - add img to the end of the dataset
BatchOpt.BackgroundColor = num2str(intmax(obj.I{obj.Id}.meta('imgClass')));   % char, intensity of the background color
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
BatchOpt.mibBatchActionName = 'Slice -> Insert an empty slice';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Dimension = sprintf('Dimension to which insert an empty slice');
BatchOpt.mibBatchTooltip.InsertPosition = sprintf('Insert the slice before the specified position;\nuse 0 to insert to the end of the dataset');
BatchOpt.mibBatchTooltip.BackgroundColor = sprintf('Intensity of the background');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 1st parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

switch BatchOpt.Dimension{1}    % get desired orientation
    case 'depth'; orientation = 4;
    case 'time'; orientation = 5;
end
maxIntValue = intmax(obj.I{BatchOpt.id}.meta('imgClass'));   % maximal intensity value for the image
maxSlice = obj.I{BatchOpt.id}.dim_yxczt(orientation);    % maximal available slice number

% define parameters
if nargin < 2
    prompt = {'Dimension:',...
        'Destination slice index (use 0 to insert a slice into the end of the dataset):', ...
        sprintf('Intensity of background (0 for black-%d for white)', maxIntValue)};
    
    defAns = {[BatchOpt.Dimension{2}, find(ismember(BatchOpt.Dimension{2}, BatchOpt.Dimension{1})==1)],...
               BatchOpt.InsertPosition, ...
               BatchOpt.BackgroundColor};
    
    mibInputMultiDlgOptions.Title = sprintf('Please enter the slice number (1-%d) and background intensity', maxSlice);
    mibInputMultiDlgOptions.TitleLines = 2;
    mibInputMultiDlgOptions.PromptLines = [1, 2, 1];
    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Insert an empty slice', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    if isnan(str2double(answer{2})) || isnan(str2double(answer{3}))
        errordlg(sprintf('!!! Error !!!\n\nWrong number!'));
        return;
    end
    
    BatchOpt.Dimension(1) = answer(1);
    BatchOpt.InsertPosition = answer{2};
    BatchOpt.BackgroundColor = answer{3};
end

getDataOpt.blockmodeSwitch = 0;
[height, width] = obj.I{BatchOpt.id}.getDatasetDimensions('image', NaN, NaN, getDataOpt);
colors = obj.I{BatchOpt.id}.colors;
img = zeros([height, width, colors], obj.I{BatchOpt.id}.meta('imgClass')) + str2double(BatchOpt.BackgroundColor);

insertDataOptions.dim = BatchOpt.Dimension{1};
insertDataOptions.BackgroundColorIntensity = str2double(BatchOpt.BackgroundColor);
insertDataOptions.showWaitbar = BatchOpt.showWaitbar;
obj.I{BatchOpt.id}.insertSlice(img, str2double(BatchOpt.InsertPosition), [], insertDataOptions);

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'newDataset');  % notify newDataset
notify(obj, 'plotImage');  % notify plotImage
end