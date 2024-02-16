% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function resliceDataset(obj, sliceNumbers, orientation, BatchOptIn)
% function resliceDataset(obj, sliceNumbers, orientation, BatchOptIn)
% stride reslicing the dataset so that the selected slices are kept and all others are removed
%
% Parameters:
% sliceNumbers: [string] the number of the slices to keep, can be a range in MATLAB
% format as 1:10:end to keep each 10th slice, can be empty: []
% orientation: [@em optional], can be @em NaN (current orientation)
% @li when @b 0 (@b default) remove slice from the current orientation (obj.orientation)
% @li when @b 1 remove slice from the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 remove slice from the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 remove slice from the yx configuration: [y,x,c,z,t]
% @li when @b 5 not implemented
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event, the function
% variables are preferred over the BatchOptIn variables
% @li .Dimension - cell string, {'height', 'width', 'depth'} - dimension for reslicing
% @li .sliceNumbers - string, indices of slices to keep, for example: "1, 79:85"
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 

%| 
% @b Examples:
% @code 
% // for the normal mode
% obj.mibModel.resliceDataset('1:10:end'); // call from mibController class; keep each 10th slice
% @endcode
% @code 
% // for the batch mode
% BatchOptIn.Dimension = {'depth'};     // reslice depth dimension
% BatchOptIn.sliceNumbers = '1:10:end';     // define positions, where delete the slices
% obj.mibModel.deleteSlice([], [], BatchOptIn); // call from mibController class; in the batch mode
% @endcode

% Updates

global mibPath; % path to mib installation folder

if nargin < 3; sliceNumbers = []; end
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
    otherwise
        errordlg(sprintf('!!! Error !!!\n\nmibModel.deleteSlice:\nWrong orientation!'));
        notify(obj, 'stopProtocol');
        return;
end
BatchOpt.Dimension{2} = {'height', 'width', 'depth'};  % cell array with options
if isempty(sliceNumbers)
    BatchOpt.sliceNumbers = '1:2:end'; % string, delete position
else
    BatchOpt.sliceNumbers = num2str(sliceNumbers);
end
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
BatchOpt.mibBatchActionName = 'Slice -> Stride reslicing';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Dimension = sprintf('Dimension where perform reslicing');
BatchOpt.mibBatchTooltip.sliceNumbers = sprintf('Indices of slices to keep\nfor example: "1, 10:10:end"');
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
maxSlice = obj.I{BatchOpt.id}.dim_yxczt(orientation);    % maximal available slice number

if nargin < 4
    prompt = {'Dimension:',...
        sprintf('Slice index(es) to keep\n(e.g. 1, 5, 10, 20:30, 50:5:end):')};
    
    defAns = {[BatchOpt.Dimension{2}, find(ismember(BatchOpt.Dimension{2}, BatchOpt.Dimension{1})==1)],...
               BatchOpt.sliceNumbers};
    
    mibInputMultiDlgOptions.Title = sprintf('Please enter the slice numbers (1:%d) to keep; all other slices will be deleted', maxSlice);
    mibInputMultiDlgOptions.TitleLines = 2;
    mibInputMultiDlgOptions.WindowStyle = 'normal';
    mibInputMultiDlgOptions.PromptLines = [1, 2];
    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Reslice dataset', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    % replace end with the max number of slices
    slicesNumbers = strrep(answer{2}, 'end', num2str(maxSlice));

    if isnan(str2num(slicesNumbers))
        errordlg(sprintf('!!! Error !!!\n\nWrong number!'));
        return;
    end
    
    BatchOpt.Dimension(1) = answer(1);
    BatchOpt.sliceNumbers = answer{2};
end

%%

switch BatchOpt.Dimension{1}    % get desired orientation
    case 'height'; orientation = 1;
    case 'width'; orientation = 2;
    case 'depth'; orientation = 4;
    case 'time'; orientation = 5;
end

slicesNumbers = strrep(BatchOpt.sliceNumbers, 'end', num2str(maxSlice));

result = obj.I{BatchOpt.id}.resliceDataset(str2num(slicesNumbers), orientation, BatchOpt); %#ok<ST2NM>
if result == 0; notify(obj, 'stopProtocol'); return; end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'newDataset');  % notify newDataset
notify(obj, 'plotImage');  % notify plotImage
end