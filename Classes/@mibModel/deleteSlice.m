function deleteSlice(obj, orientation, sliceNumber, BatchOptIn)
% function deleteSlice(obj, orientation, sliceNumber, BatchOptIn)
% Delete a slice from the volume
%
% Parameters:
% orientation: [@em optional], can be @em NaN (current orientation)
% @li when @b 0 (@b default) remove slice from the current orientation (obj.orientation)
% @li when @b 1 remove slice from the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 remove slice from the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 remove slice from the yx configuration: [y,x,c,z,t]
% @li when @b 5 remove slice from the t configuration
% sliceNumber: the number of the slice to delete, can be empty: []
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event, the function
% variables are preferred over the BatchOptIn variables
% @li .Dimension - cell string, {'height', 'width', 'depth', 'time'} - dimension from where delete slices
% @li .DeletePosition - string, indices of slices to delete, for example: "1,79:85"
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 

%| 
% @b Examples:
% @code 
% // for the normal mode
% obj.mibModel.deleteSlice(4, 10); // call from mibController class; delete slice number 10 
% @endcode
% @code 
% // for the batch mode
% BatchOptIn.Dimension = {'time'};     // delete slice from the time domain, otherwise use {'depth'}
% BatchOptIn.DeletePosition = '2:10';     // define positions, where delete the slices
% obj.mibModel.deleteSlice([], [], BatchOptIn); // call from mibController class; in the batch mode
% @endcode

% Copyright (C) 17.05.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates

global mibPath; % path to mib installation folder

if nargin < 3; sliceNumber = []; end
if nargin < 2; orientation = []; end

%% populate default values
BatchOpt = struct();
BatchOpt.id = obj.Id;   % optional, id
if isempty(isnan(orientation)) || isnan(orientation); orientation = obj.I{BatchOpt.id}.orientation; end
if orientation == 0; orientation = obj.I{BatchOpt.id}.orientation; end
switch orientation
    case 1; BatchOpt.Dimension = {'height'};
    case 2; BatchOpt.Dimension = {'width'};
    case 4; BatchOpt.Dimension = {'depth'};
    case 5; BatchOpt.Dimension = {'time'};
    otherwise
        errordlg(sprintf('!!! Error !!!\n\nmibModel.deleteSlice:\nWrong orientation!'));
        notify(obj, 'stopProtocol');
        return;
end
BatchOpt.Dimension{2} = {'height', 'width', 'depth', 'time'};  % cell array with options
if isempty(sliceNumber)
    if strcmp(BatchOpt.Dimension{1}, 'time')
            BatchOpt.DeletePosition = num2str(obj.I{BatchOpt.id}.getCurrentTimePoint);   % string, delete position
    else
        BatchOpt.DeletePosition = num2str(obj.I{BatchOpt.id}.getCurrentSliceNumber()); % string, delete position
    end
else
    BatchOpt.DeletePosition = num2str(sliceNumber);
end
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
BatchOpt.mibBatchActionName = 'Slice -> Delete slice/frame';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Dimension = sprintf('Dimension from where delete slices');
BatchOpt.mibBatchTooltip.DeletePosition = sprintf('Indices of slices to delete\nfor example: "1,79:85"');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 4  % batch mode 
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
if nargin < 4
    maxSlice = obj.I{BatchOpt.id}.dim_yxczt(orientation);    % maximal available slice number
    
    prompt = {'Dimension:',...
        'Slice index(es) to delete:'};
    
    defAns = {[BatchOpt.Dimension{2}, find(ismember(BatchOpt.Dimension{2}, BatchOpt.Dimension{1})==1)],...
               BatchOpt.DeletePosition};
    
    mibInputMultiDlgOptions.Title = sprintf('Please enter the slice/frame number (1-%d) to delete', maxSlice);
    mibInputMultiDlgOptions.TitleLines = 2;
    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Delete slice/frame', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    if isnan(str2num(answer{2}))
        errordlg(sprintf('!!! Error !!!\n\nWrong number!'));
        return;
    end
    
    BatchOpt.Dimension(1) = answer(1);
    BatchOpt.DeletePosition = answer{2};
end

%%

switch BatchOpt.Dimension{1}    % get desired orientation
    case 'height'; orientation = 1;
    case 'width'; orientation = 2;
    case 'depth'; orientation = 4;
    case 'time'; orientation = 5;
end

result = obj.I{BatchOpt.id}.deleteSlice(str2num(BatchOpt.DeletePosition), orientation, BatchOpt); %#ok<ST2NM>
if result == 0; notify(obj, 'stopProtocol'); return; end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'newDataset');  % notify newDataset
notify(obj, 'plotImage');  % notify plotImage
end