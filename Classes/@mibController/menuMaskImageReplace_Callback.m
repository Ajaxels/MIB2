function menuMaskImageReplace_Callback(obj, type, BatchOptIn)
% function menuMaskImageReplace_Callback(obj, type, BatchOptIn)
% callback to Menu->Mask->Replace color; 
% Replace image intensities in the @em Masked or @em Selected areas with new intensity value
%
% Parameters:
% type: a string with source layer
% @li 'mask' - replace image intensities under the Mask layer
% @li 'selection' - replace image intensities under the Selection layer
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Target - cell string, {'mask', 'selection'} - layer to containing the areas to replace
% @li .ColorIntensity - string,new color intensity for the masked/selected area, one or more numbers from above 0
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Copyright (C) 10.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath
%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(type)
    BatchOpt.Target = {type};
else
    BatchOpt.Target = {'mask'};
end
BatchOpt.Target{2} = {'mask', 'selection'};
BatchOpt.ColorChannel = '0';
BatchOpt.ColorIntensity = '0';
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.mibModel.Id;   % optional, id

switch BatchOpt.Target{1}
    case 'mask'
        BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Replace masked area in the image';
    case 'selection'
        BatchOpt.mibBatchSectionName = 'Menu -> Selection';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Replace selected area in the image';
end
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Target = sprintf('Layer with areas to be replaced on the image');
BatchOpt.mibBatchTooltip.ColorChannel = sprintf('Indices of the color channel to replace, 0 - replace all');
BatchOpt.mibBatchTooltip.ColorIntensity = sprintf('New color intensity for the masked/selected area, one or more numbers from 0 (black) to %d (white)', obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt'));
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%% Batch mode check actions
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

%% initial checks
% check for the virtual stacking mode and return
if obj.mibModel.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = '';
    warndlg(sprintf('!!! Warning !!!\n\nThis action is%s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

if strcmp(obj.mibModel.I{BatchOpt.id}.meta('ColorType'), 'indexed')
    msgbox('Not compatible with indexed images!');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

%% Settings for normal run
max_slice = obj.mibModel.I{BatchOpt.id}.dim_yxczt(obj.mibModel.I{BatchOpt.id}.orientation);
max_time = obj.mibModel.I{BatchOpt.id}.time;
if nargin < 3
    prompt = {sprintf('Please provide intensity for a new color [0-%d]:', ...
            obj.mibModel.I{BatchOpt.id}.meta('MaxInt')); ...
        sprintf('Time point (1:%d; 0 for all):', max_time); ...
        sprintf('Slice number (1:%d; 0 for all):', max_slice); ...
        'Color channels (0 for all):'};
    title = 'Replace color';
    time_pnt = obj.mibModel.I{BatchOpt.id}.getCurrentTimePoint();
    slice_no = obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber();
    defAns = {repmat('0, ', 1, obj.mibModel.I{BatchOpt.id}.colors); num2str(time_pnt); num2str(slice_no); '0'};
    mibInputMultiDlgOptions.PromptLines = [1, 1, 1, 1];
    mibInputMultiDlgOptions.Title = sprintf('Your are going to replace the *%s* area in the image.', type);
    mibInputMultiDlgOptions.TitleLines = 2;
    
    answer = mibInputMultiDlg({mibPath}, prompt, defAns, title, mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    BatchOpt.ColorIntensity = answer{1}; 
    BatchOpt.ColorChannel = answer{4};  % list of color channels to modify
    
    time_pnt = str2num(answer{2}); %#ok<*ST2NM>
    BatchOpt.t = [min(time_pnt) max(time_pnt)];
    
    slice_id = str2num(answer{3});
    BatchOpt.z = [min(slice_id) max(slice_id)];
end

%%
channel_id = str2num(BatchOpt.ColorChannel);
if channel_id(1) == 0
    noColorChannels = obj.mibModel.I{BatchOpt.id}.colors;
else
    noColorChannels = numel(str2num(BatchOpt.ColorChannel));
end
color_id = str2num(BatchOpt.ColorIntensity);
if numel(color_id) ~= noColorChannels
    color_id = repmat(color_id(1), 1, noColorChannels);
end

if isfield(BatchOpt, 't'); time_pnt = BatchOpt.t; else; time_pnt = 0; end
if isfield(BatchOpt, 'z'); slice_id = BatchOpt.z; else; slice_id = 0; end

getDataOptions.showWaitbar = BatchOpt.showWaitbar;
getDataOptions.id = BatchOpt.id;
% do backups
if slice_id(1) ~= 0 && time_pnt(1) ~= 0
    getDataOptions.z = [min(slice_id) max(slice_id)];
    getDataOptions.t = [min(time_pnt) max(time_pnt)];
    obj.mibModel.mibDoBackup('image', 0, getDataOptions); 
elseif time_pnt(1) ~= 0
    getDataOptions.t = [min(time_pnt) max(time_pnt)];
    obj.mibModel.mibDoBackup('image', 1, getDataOptions); 
end

obj.mibModel.I{BatchOpt.id}.replaceImageColor(type, color_id, channel_id, slice_id, time_pnt, getDataOptions);
obj.plotImage();

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

end
