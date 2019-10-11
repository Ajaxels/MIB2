function colorChannelActions(obj, mode, channel1, channel2, BatchOptIn)
% function colorChannelActions(obj, mode, channel1, channel2, BatchOptIn)
% handling various color channel operations
%
% Parameters:
% mode: a string with the operaion to perform
% ''Insert empty channel'' - insert color channel
% ''Copy channel'' - copy one color channel to another
% ''Invert channel'' - invert color channel
% ''Rotate channel'' - rotate color channel
% ''Swap channels'' - swap two color channels
% ''Delete channel'' - delete color channel
% channel1: index of the first color channel
% channel2: index of the second color channel (for @em copy and @em swap
% modes) or rotation angle for the ''Rotate channel'' mode
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Action - cell string, {'Insert empty channel', 'Copy channel', 'Invert channel', 'Rotate channel', 'Swap channels', 'Delete channel'} - action to perform
% @li .Channel1 - string, index of the first (source) color channel
% @li .Channel2 - string, index of the second (target) color channel
% @li .RotationAngle - string, rotation angle
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 

%| 
% @b Examples:
% @code
% obj.mibModel.colorChannelActions('Delete channel'); // start delete color channel operation
% @endcode
% @code 
% BatchOptIn.Action = {'Delete channel'};     // define add a dataset as a new time point
% BatchOptIn.Channel1 = '2';     // define to insert the empty image to the second frame
% obj.mibModel.colorChannelActions([],[],[],BatchOptIn); // call from mibController class; in the batch mode - delete 2nd color channel
% @endcode
%
% Copyright (C) 21.05.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates

global mibPath;

if nargin < 4; channel2 = []; end
if nargin < 3; channel1 = []; end
if nargin < 2; mode = 'Insert empty channel'; end

% populate BatchOpt with default values
BatchOpt = struct();
if ~isempty(mode)
    BatchOpt.Action = {mode};
else
    BatchOpt.Action = {'Insert empty channel'};
end
BatchOpt.Action{2} = {'Insert empty channel', 'Copy channel', 'Invert channel', 'Rotate channel', 'Swap channels', 'Delete channel'};  % cell array with options

if isempty(channel1)
    BatchOpt.Channel1 = num2str(max([1 obj.I{obj.Id}.selectedColorChannel])); % string, source position
else
    BatchOpt.Channel1 = num2str(channel1);
end

if isempty(channel2)
    BatchOpt.Channel2 = num2str(max([1 obj.I{obj.Id}.selectedColorChannel])); % string, source position
    BatchOpt.RotationAngle = '90'; % string, rotation angle
else
    BatchOpt.Channel2 = num2str(channel2);
    if strcmp(BatchOpt.Action{1}, 'Rotate channel')
        if mod(channel2, 90) ~= 0
            errordlg(sprintf('!!! Error !!!\n\nThe rotation angle should be one of these numbers: 90, 180, -90'), 'Wrong rotation!');
            notify(obj, 'stopProtocol');
            return;
        end
    end
    BatchOpt.RotationAngle = num2str(channel2);
end
BatchOpt.showWaitbar = true;   % logical, show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Image';
BatchOpt.mibBatchActionName = 'Color channel actions';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Action = sprintf('Specify action for the color channels');
BatchOpt.mibBatchTooltip.Channel1 = sprintf('Index or indices of the first color channel to use');
BatchOpt.mibBatchTooltip.Channel2 = sprintf('Index or indices of the second color channel to use');
BatchOpt.mibBatchTooltip.RotationAngle = sprintf('Rotation angle\nshould be -90, 0, 90, 180 etc');
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

% define parameters
if nargin < 5
    mibInputMultiDlgOptions.Title = BatchOpt.Action{1};
    mibInputMultiDlgOptions.TitleLines = 1;
    if ismember(BatchOpt.Action{1}, {'Copy channel', 'Swap channels'})
        textString1 = 'Index of the source color channel:';
        textString2 = 'Index of the target color channel:';
        prompt = {textString1; textString2};
        mibInputMultiDlgOptions.PromptLines = [1, 1];
        defAns = {BatchOpt.Channel1, BatchOpt.Channel2};    
    elseif strcmp(BatchOpt.Action{1}, 'Rotate channel')
        textString1 = 'Index of the color channel:';
        textString2 = 'Rotation angle (90, 180, -90):';
        prompt = {textString1; textString2};
        mibInputMultiDlgOptions.PromptLines = [1, 1];
        defAns = {BatchOpt.Channel1, BatchOpt.RotationAngle};    
    else
        prompt = {'Index of the color channel:'};
        mibInputMultiDlgOptions.PromptLines = 1;
        defAns = {BatchOpt.Channel1};
    end
    answer = mibInputMultiDlg({mibPath}, prompt, defAns, 'Copy slice', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    BatchOpt.Channel1 = answer{1};
    if ismember(BatchOpt.Action{1}, {'Copy channel', 'Swap channels'})
        BatchOpt.Channel2 = answer{2};
    end
    if strcmp(BatchOpt.Action{1}, 'Rotate channel')
        BatchOpt.RotationAngle = answer{2};
    end
end

channel1 = str2num(BatchOpt.Channel1); %#ok<*ST2NM>
if strcmp(BatchOpt.Action{1}, 'Rotate channel')
    angle = str2num(BatchOpt.RotationAngle);
else
    channel2 = str2num(BatchOpt.Channel2);
end

switch BatchOpt.Action{1}
    case 'Insert empty channel'
        obj.I{BatchOpt.id}.insertEmptyColorChannel(channel1, BatchOpt);
        notify(obj, 'newDataset');
    case 'Copy channel'
        obj.I{BatchOpt.id}.copyColorChannel(channel1, channel2, BatchOpt);
        notify(obj, 'newDataset');
    case 'Invert channel'
        if obj.I{BatchOpt.id}.time < 2; obj.mibDoBackup('image', 1, BatchOpt);  end
        obj.I{BatchOpt.id}.invertColorChannel(channel1, BatchOpt);
    case 'Rotate channel'
        if obj.I{BatchOpt.id}.time < 2; obj.mibDoBackup('image', 1, BatchOpt); end
        obj.I{BatchOpt.id}.rotateColorChannel(channel1, angle, BatchOpt);     
    case 'Swap channels'
        if obj.I{BatchOpt.id}.time < 2; obj.mibDoBackup('image', 1, BatchOpt);  end
        obj.I{BatchOpt.id}.swapColorChannels(channel1, channel2, BatchOpt);
    case 'Delete channel'
        obj.I{BatchOpt.id}.deleteColorChannel(channel1, BatchOpt);
        notify(obj, 'newDataset');
end

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');  % notify plotImage




