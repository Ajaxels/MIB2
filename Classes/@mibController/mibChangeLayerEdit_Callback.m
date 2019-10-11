function mibChangeLayerEdit_Callback(obj, parameter, BatchOptIn)
% function mibChangeLayerEdit_Callback(obj, parameter, BatchOptIn)
% A callback for changing the slices of the 3D dataset by entering a new slice number
% 
% Parameters:
% parameter: [@b optional], when provided:
% @li 0 - set dataset to the last slice, used as a callback for mibView.mibLastSliceBtn
% @li 1 - set dataset to the first slice, used as a callback for mibView.mibFirstSliceBtn
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event
% @li .SliceNumber -> string, slice number to show
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
    parameter = str2double(obj.mibView.handles.mibChangeLayerEdit.String);
    status = obj.mibView.editbox_Callback(obj.mibView.handles.mibChangeLayerEdit,...
        'pint',1,[1 obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation)]);
    if status == 0; return; end
end

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.SliceNumber = num2str(parameter);

BatchOpt.mibBatchSectionName = 'Panel -> Image view';
BatchOpt.mibBatchActionName = 'Change slice number';

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.SliceNumber = sprintf('Enter a new slice number; use 0 to show the last slice of the dataset');

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
    if obj.mibModel.I{obj.mibModel.Id}.orientation == 4   % xy
        maxVal = obj.mibModel.I{obj.mibModel.Id}.depth;
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1   % xz
        maxVal = obj.mibModel.I{obj.mibModel.Id}.height;
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2   % yz
        maxVal = obj.mibModel.I{obj.mibModel.Id}.width;
    end
    
    val = str2double(BatchOpt.SliceNumber);
    if val == 0
        val = num2str(maxVal);
    else
        if val > maxVal
            val = maxVal;
        elseif val < 0
            val = 1;
        end
    end
    BatchOpt.SliceNumber = num2str(val);
    obj.mibView.handles.mibChangeLayerEdit.String = BatchOpt.SliceNumber;
end

obj.mibView.handles.mibChangeLayerSlider.Value = str2double(BatchOpt.SliceNumber);
obj.mibChangeLayerSlider_Callback();
end