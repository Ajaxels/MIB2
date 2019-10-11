function mibChangeTimeEdit_Callback(obj, parameter, BatchOptIn)
% function mibChangeTimeEdit_Callback(obj, parameter, BatchOptIn)
% A callback for changing the time points of the dataset by entering a new time value
% 
% Parameters:
% parameter: [@b optional], when provided:
% @li 0 - set dataset to the last slice, used as a callback for mibView.mibLastSliceBtn
% @li 1 - set dataset to the first slice, used as a callback for mibView.mibFirstSliceBtn
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event
% @li .FrameNumber -> string, frame number to show
%
%
% Return values:
%

% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 19.09.2019 updated for the batch mode

if nargin < 3; BatchOptIn = struct; end
if nargin < 2; parameter = []; end


if isempty(parameter)
    parameter = str2double(obj.mibView.handles.mibChangeTimeEdit.String);
    status = obj.mibView.editbox_Callback(obj.mibView.handles.mibChangeTimeEdit,...
        'pint',1,[1 obj.mibModel.I{obj.mibModel.Id}.time]);
    if status == 0; return; end
end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.FrameNumber = num2str(parameter);

BatchOpt.mibBatchSectionName = 'Panel -> Image view';
BatchOpt.mibBatchActionName = 'Change frame/time number';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.FrameNumber = sprintf('Enter a new frame number; use 0 to show the last time point of the dataset');

%%
if isstruct(BatchOptIn) == 0
    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
        % trigger syncBatch event to send BatchOptInOut to mibBatchController
        eventdata = ToggleEventData(BatchOpt);
        notify(obj.mibModel, 'syncBatch', eventdata);
    else
        errordlg(sprintf('A structure as the 2nd parameter is required!'));
    end
    return;
else
    % add/update BatchOpt with the provided fields in BatchOptIn
    % combine fields from input and default structures
    BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
end

if nargin > 1
    maxTime = obj.mibModel.I{obj.mibModel.Id}.time;
    val = str2double(BatchOpt.FrameNumber);
    if val == 0
        val = maxTime;
    elseif val > maxTime
        val = maxTime;
    elseif val < 0
        val = 1;
    end
    BatchOpt.FrameNumber = num2str(val);
    obj.mibView.handles.mibChangeTimeEdit.String = BatchOpt.FrameNumber;
end
obj.mibView.handles.mibChangeTimeSlider.Value = str2double(BatchOpt.FrameNumber);
obj.mibChangeTimeSlider_Callback();
end