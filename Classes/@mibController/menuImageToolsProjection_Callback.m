function menuImageToolsProjection_Callback(obj, BatchOptIn)
% function menuImageToolsProjection_Callback(obj, BatchOptIn)
% callback to the Menu->Image->Tools->Intensity projection, calculate
% intensity projection of the dataset
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details
% Possible fields,
% @li .ProjectionType - cell string with type of the intensity projection,
% one of these: {'Max', 'Min', 'Mean', 'Median', 'Sum', 'Focus stacking'}
% @li .Dimension - cell string, with dimension, {'Y', 'X', 'C', 'Z', 'T'}
% @li .Destination - cell string with id of the destination container, {'Container 1'};
% @li .showWaitbar - logical, show or not the waitbar

% Copyright (C) 09.03.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;

% specify default BatchOptIn
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0
    PossibleProjections = {'Max', 'Min', 'Mean', 'Median', 'Sum', 'Focus stacking'};
    PossibleDimensions = {'Y', 'X', 'C', 'Z', 'T'};
else
    PossibleProjections = {'Max', 'Min', 'Mean', 'Median', 'Sum'};
    PossibleDimensions = {'Z'};
end
PossibleDestinations = arrayfun(@(x) sprintf('Container %d', x), 1: obj.mibModel.maxId, 'UniformOutput', false);
BatchOpt = struct();

% update the Batch opt from the session settings structure
if isfield(obj.mibModel.sessionSettings, 'intensityProjection')
    if ismember(obj.mibModel.sessionSettings.intensityProjection.ProjectionType, PossibleProjections)   % check for correct projection, because it is different in normal and virtual modes
        BatchOpt.ProjectionType = obj.mibModel.sessionSettings.intensityProjection.ProjectionType;
    else
        BatchOpt.ProjectionType = {'Max'};
    end
    if ismember(obj.mibModel.sessionSettings.intensityProjection.Dimension, PossibleDimensions)
        BatchOpt.Dimension = obj.mibModel.sessionSettings.intensityProjection.Dimension;
    else
        BatchOpt.Dimension = {'Z'};
    end
else
    BatchOpt.ProjectionType = {'Max'};
    BatchOpt.Dimension = {'Z'};
end
BatchOpt.ProjectionType{2} = PossibleProjections;
BatchOpt.Dimension{2} = PossibleDimensions;
BatchOpt.Destination = {'Container 1'};
BatchOpt.Destination{2} = PossibleDestinations;
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Menu -> Image';
BatchOpt.mibBatchActionName = 'Tools for Images -> Intensity projection';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.ProjectionType = sprintf('Projection type to generate; when "Sum" projection is used the image class may be changed, as result the Max intensity value should be updated (View settings panel->Display)');
BatchOpt.mibBatchTooltip.Dimension = sprintf('Dimension for the projection calculation');
BatchOpt.mibBatchTooltip.Destination = sprintf('Send the result to the specified container');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');


%obj.mibModel.sessionSettings.intensityProjection.Dimension = BatchOpt.Dimension{1};

if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            
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
end

if nargin < 2
    if obj.mibModel.getImageProperty('modelExist') == 1 || obj.mibModel.getImageProperty('maskExist') == 1
        button = questdlg(...
            sprintf('!!! Warning !!!\n\nThe existing model and mask will be removed during calculation of the image intensity projection!'),...
            'Intensity projection', 'Continue','Cancel','Cancel');
        if strcmp(button, 'Cancel'); return; end
    end
    prompts = {'Projection type'; 'Dimension'; 'Destination buffer'};
    destBuffers = PossibleDestinations;
    destBuffers{end+1} = obj.mibModel.Id;
    defAns = {[BatchOpt.ProjectionType{2}, {find(ismember(BatchOpt.ProjectionType{2}, BatchOpt.ProjectionType{1})==1)}]; ...
                  [BatchOpt.Dimension{2}, {find(ismember(BatchOpt.Dimension{2}, BatchOpt.Dimension{1})==1)}]; ...
                  destBuffers};
    dlgTitle = 'Calculation of intensity projection';
    options.WindowStyle = 'normal';       % [optional] style of the window
    options.Title = 'Intensity projection parameters';   % [optional] additional text at the top of the window
    options.Focus = 1;      % [optional] define index of the widget to get focus
    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); return; end    
   
    BatchOpt.ProjectionType(1) = answer(1);
    BatchOpt.Dimension(1) = answer(2);
    BatchOpt.Destination(1) = answer(3);
end

projectionType = lower(BatchOpt.ProjectionType{1});
dim = find(ismember(PossibleDimensions, BatchOpt.Dimension{1})==1);  % index of dimension over which to calculate projection
bufferId = find(ismember(PossibleDestinations, BatchOpt.Destination{1})==1);

if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Generating the projection\nPlease wait...'), 'Name', 'Projection'); end

getDataOptions.blockModeSwitch = 0;
[height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, getDataOptions);
colors = numel(colors);

if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0
    if strcmp(projectionType, 'focus stacking')
        if depth < 3
            errordlg('Focus stacking requires at least 3 images assembled into a Z-stack');
            if BatchOpt.showWaitbar; delete(wb); end
            notify(obj.mibModel, 'stopProtocol');
            return;
        end
        if dim ~= 4
            res = questdlg(sprintf('!!! Warning !!!\n\nThe focus stacking is only available for the Z-dimention!\nContinue?'), 'Dimension issue', 'Continue', 'Cancel', 'Continue');
            if strcmp(res, 'Cancel'); if BatchOpt.showWaitbar; delete(wb); end; notify(obj.mibModel, 'stopProtocol'); return; end
        end
        dim = 4;    % only available for the Z-stacks
        I = zeros([height, width, colors, 1, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'));
        if time > 1
            fstackOptions.showWaitbar = 0; 
        else
            fstackOptions.showWaitbar = 1;
        end
        for t = 1:time
            Iin = cell2mat(obj.mibModel.getData3D('image', t, 4, 0, getDataOptions));
            I(:,:,:,1,t) = fstack_mib(Iin, fstackOptions);
        end
    else
        I = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
        if BatchOpt.showWaitbar; waitbar(0.1, wb); end
        switch projectionType
            case 'min'
                I = min(I, [], dim);
            case 'max'
                I = max(I, [], dim);
            case 'mean'
                classOfImg = class(I);
                I = mean(I, dim);
                evalStr = sprintf('I = %s(I);', classOfImg);
                eval(evalStr);
            case 'median'
                I = median(I, dim);       
            case 'sum'
                I = sum(I, dim);       
        end
    end
    if BatchOpt.showWaitbar; waitbar(0.8, wb); end
    if dim < 3  % permute the matrix
        if dim == 1
            I = permute(I, [4, 2, 3, 1, 5]);
        elseif dim == 2
            I = permute(I, [1, 4, 3, 2, 5]);
        end
    end
    if BatchOpt.showWaitbar; waitbar(0.9, wb); end
else        % virtual stacking mode
    % allocate space for the output image
    switch projectionType
        case 'min'
            shift = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
            I = zeros([height, width, colors, 1, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass')) + shift;
        case 'max'
            I = zeros([height, width, colors, 1, time], obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'));
        case {'mean', 'sum'}
            I = zeros([height, width, colors, 1, time]);
    end
    if BatchOpt.showWaitbar; waitbar(0.1, wb); end
    for t = 1:time
        getDataOptions.t = t;
        for z = 1:depth
            Icur = cell2mat(obj.mibModel.getData2D('image', z, 4, 0, getDataOptions));
            switch projectionType
                case 'min'
                    I(:,:,:,1,t) = min(I(:,:,:,1,t), Icur);
                case 'max'
                    I(:,:,:,1,t) = max(I(:,:,:,1,t), Icur);
                case 'mean'
                    I(:,:,:,1,t) = I(:,:,:,1,t) + double(Icur)/depth;
                case 'sum'
                    I(:,:,:,1,t) = I(:,:,:,1,t) +Icur;
            end
        end
        if BatchOpt.showWaitbar; waitbar(t/time, wb); end
    end
end

% convert from double to the image class
imgClass = obj.mibModel.I{obj.mibModel.Id}.meta('imgClass');
if isa(I, 'double')
    switch projectionType
        case 'mean'
            commandStr = sprintf('I = %s(I);', obj.mibModel.I{obj.mibModel.Id}.meta('imgClass'));
            eval(commandStr);
        case 'sum'
            maxVal = max(I(:));
            if maxVal < intmax('uint8')
                I = uint8(I);
                imgClass = 'uint8';
            elseif maxVal < intmax('uint16')
                I = uint16(I);
                imgClass = 'uint16';
            elseif maxVal < intmax('uint32')
                I = uint32(I);
                imgClass = 'uint32';
            end
    end
end

if BatchOpt.showWaitbar; waitbar(0.95, wb); end

logText = sprintf('%s-intensity projection, dim=%c', lower(BatchOpt.ProjectionType{1}), BatchOpt.Dimension{1});
% store view port structure
if ~strcmp(BatchOpt.Dimension{1}, 'C'); viewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;   end
if bufferId == obj.mibModel.Id
    if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
        newMode = obj.mibModel.I{obj.mibModel.Id}.switchVirtualStackingMode(0, obj.mibModel.preferences.disableSelection);
        if isempty(newMode); if BatchOpt.showWaitbar; delete(wb); end; notify(obj.mibModel, 'stopProtocol'); return; end
    end
    setDataOptions.replaceDatasetSwitch = 1;    % force to replace dataset
    setDataOptions.keepModel = 0;   % reinitialize the model
    obj.mibModel.setData4D('image', I, 4, 0, setDataOptions);
    obj.mibModel.I{obj.mibModel.Id}.meta('imgClass') = imgClass;
    if ~strcmp(BatchOpt.Dimension{1}, 'C')
        obj.mibModel.I{obj.mibModel.Id}.viewPort = viewPort;   % restore viewport
    end
    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(logText);
    notify(obj.mibModel, 'newDataset');
else
    if obj.mibModel.I{bufferId}.Virtual.virtual == 1; obj.mibModel.I{bufferId}.clearContents(); end % close the readers, otherwise the files stay locked
    meta = containers.Map(keys(obj.mibModel.I{obj.mibModel.Id}.meta), values(obj.mibModel.I{obj.mibModel.Id}.meta));
    meta('Height') = size(I,1);
    meta('Width') = size(I,2);
    meta('Colors') = size(I,3);
    meta('Depth') = size(I,4);
    meta('Time') = size(I,5);
    meta('imgClass') = imgClass;
    obj.mibModel.I{bufferId} = mibImage(I, meta);
    if ~strcmp(BatchOpt.Dimension{1}, 'C')
        obj.mibModel.I{bufferId}.viewPort = viewPort;   % restore viewport
    end
    eventdata = ToggleEventData(bufferId);
    notify(obj.mibModel, 'newDataset', eventdata);
    obj.mibModel.I{bufferId}.updateImgInfo(logText);
end
if BatchOpt.showWaitbar; waitbar(1, wb); end
obj.updateGuiWidgets();
obj.plotImage();

% store used parameters into the session settings structure
obj.mibModel.sessionSettings.intensityProjection.ProjectionType = BatchOpt.ProjectionType(1);
obj.mibModel.sessionSettings.intensityProjection.Dimension = BatchOpt.Dimension(1);

% notify the batch mode
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

if BatchOpt.showWaitbar; delete(wb); end
end