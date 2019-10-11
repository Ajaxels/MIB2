function menuImageInvert_Callback(obj, mode, BatchOptIn)
% function menuImageInvert_Callback(obj, mode, BatchOptIn)
% callback for Menu->Image->Invert image; start invert image 
%
% Parameters:
% mode: a string that defines part of the dataset to be inverted. When
% empty BatchOptIn structure will be used or '4D' mode
% @li when @b '2D' invert the currently shown slice
% @li when @b '3D' invert the currently shown z-stack
% @li when @b '4D' invert the whole dataset
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .ColorChannels - cell string, ids of color channel, one of these {'Shown channels'}, {'All channels'}
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% 

% Copyright (C) 03.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 18.03.2019, updated for the batch mode

PossibleOptions_mode = {'Shown slice (2D)','Current stack (3D)','Complete volume (4D)'};
PossibleOptions_colch = {'Shown channels','All channels'};
BatchOpt = struct();
BatchOpt.Mode = {'Complete volume (4D)'};
BatchOpt.Mode{2} = PossibleOptions_mode;
BatchOpt.ColorChannels = {'Shown channels'};
BatchOpt.ColorChannels{2} = PossibleOptions_colch;
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Image';
BatchOpt.mibBatchActionName = 'Invert image';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Mode = sprintf('Select part of the dataset to be inverted: shown slice (2D), current slice (3D) or the whole dataset (4D)');
BatchOpt.mibBatchTooltip.ColorChannels = sprintf('Identify color channels for inversion');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 3  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
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

%%
% check for the virtual stacking mode and close the controller
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'image invert is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

if nargin < 2
    mode = BatchOpt.Mode{1}(end-2:end-1);
else
    if isempty(mode)
        mode = BatchOpt.Mode{1}(end-2:end-1);
    end
end

% define color channels to be inverted
if nargin < 3
    if numel(obj.mibView.handles.mibColChannelCombo.String)-1 > numel(obj.mibModel.I{BatchOpt.id}.slices{3})
        strText = sprintf('Would you like to invert shown or all channels?');
        button = questdlg(strText, 'Invert Image', 'Shown channels', 'All channels', 'Cancel', 'Shown channels');
        if strcmp(button, 'Cancel'); return; end
        if strcmp(button, 'All channels')
            BatchOpt.ColorChannels(1) = {'All channels'};
            %colChannel = 0;
        end
    end
end
if strcmp(BatchOpt.ColorChannels{1}, 'All channels')
    colChannel = 0;
else
    colChannel = NaN;
end
result = obj.mibModel.invertImage(mode, colChannel, BatchOpt);

if result == 1
    switch mode
        case '2D'
            BatchOpt.Mode{1} = 'Shown slice (2D)'; %{'Shown slice (2D)','Current stack (3D)','Complete volume (4D)'}
            if ~isfield(BatchOpt, 't'); BatchOpt.t = [obj.mibModel.I{BatchOpt.id}.getCurrentTimePoint() obj.mibModel.I{BatchOpt.id}.getCurrentTimePoint()]; end
            if ~isfield(BatchOpt, 'z'); BatchOpt.z = [obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber() obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber()]; end
        case '3D'
            BatchOpt.Mode{1} = 'Current stack (3D)'; 
            if ~isfield(BatchOpt, 't'); BatchOpt.t = [obj.mibModel.I{BatchOpt.id}.getCurrentTimePoint() obj.mibModel.I{BatchOpt.id}.getCurrentTimePoint()]; end
        case '4D'
            BatchOpt.Mode{1} = 'Complete volume (4D)'; 
    end
    BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
    eventdata = ToggleEventData(BatchOpt);
    notify(obj.mibModel, 'syncBatch', eventdata);
end

end