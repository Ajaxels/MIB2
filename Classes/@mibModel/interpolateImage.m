function interpolateImage(obj, imgType, intType, BatchOptIn)
% function interpolateImage(obj, imgType, intType, BatchOptIn)
% interpolate 'mask', 'selection' or 'model' layer
%
% Parameters:
% imgType: a string with type of the layer for the interpolation
% @li ''selection'' - smooth the 'Selection' layer [@em default]
% @li ''mask'' - smooth the 'Mask' layer
% @li ''model'' - smooth the 'Model' layer
% intType: a string with type of the interpolation algorithm to use
% @li 'shape' - interpolation suitable for blobs
% @li 'line' - interpolation suitable for lines
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Target - cell string, {'mask', 'selection', 'model'} - layer to smooth
% @li .InterpolationType - cell string, {'shape', 'line'} - type of the interpolation
% @li .MaterialIndex - string [@em only @em for @em models], with index of the material
% @li .id -> [@em optional], index of the dataset to process
% @li .showWaitbar - logical, show or not the waitbar
% 
% Return values:
% 

% Copyright (C) 30.07.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3; intType = []; end
if nargin < 2; imgType = []; end
    
%% Declaration of the BatchOpt structure
BatchOpt = struct();
if ~isempty(imgType)
    BatchOpt.Target = {imgType};
else
    BatchOpt.Target = {'selection'};
end
BatchOpt.Target{2} = {'mask', 'selection', 'model'};

if ~isempty(intType)
    BatchOpt.InterpolationType = {intType};
else
    BatchOpt.InterpolationType = {obj.preferences.interpolationType};
end
BatchOpt.InterpolationType{2} = {'shape', 'line'};
BatchOpt.MaterialIndex = '1';
BatchOpt.showWaitbar = true;   % show or not the waitbar

switch BatchOpt.Target{1}
    case 'selection'
        BatchOpt.mibBatchSectionName = 'Menu -> Selection';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Interpolate selection';
    case 'mask'
        BatchOpt.mibBatchSectionName = 'Menu -> Mask';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Interpolate mask';
    case 'model'
        BatchOpt.mibBatchSectionName = 'Menu -> Models';    % section name for the Batch
        BatchOpt.mibBatchActionName = 'Interpolate material';
end

% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Target = sprintf('Layer to be interpolated');
BatchOpt.mibBatchTooltip.InterpolationType = sprintf('Type of the interpolation algorithm; "shape" is suitable for blobs, while "line" is more suitable for membranes');
BatchOpt.mibBatchTooltip.MaterialIndex = sprintf('[Only for models] index of material in the model to be interpolated');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

%% Batch mode check actions
if nargin == 4  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt.id = obj.Id;   % default BatchOpt.id
        BatchOpt.t = obj.I{obj.Id}.getCurrentTimePoint;   % default BatchOpt.t - time point
        BatchOptLocal = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
        BatchOpt = rmfield(BatchOpt, 'id');     % remove id from the BatchOpt structure
        BatchOpt = rmfield(BatchOpt, 't');     % remove t from the BatchOpt structure
    end
else
    BatchOptLocal = BatchOpt;   % make BatchOptLocal for standard call of the function
    BatchOptLocal.id = obj.Id;   % default BatchOpt.id
    BatchOptLocal.t = obj.I{obj.Id}.getCurrentTimePoint;   % default BatchOpt.t - time point
end

%% do nothing is selection is disabled
if obj.I{BatchOptLocal.id}.disableSelection == 1
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The selection layer is disabled', 'modal');
    notify(obj, 'stopProtocol');
    return; 
end

% check for the virtual stacking mode and return
if obj.I{BatchOptLocal.id}.Virtual.virtual == 1
    toolname = 'interpolation is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

tic
if BatchOptLocal.showWaitbar; wb = waitbar(0,'Please wait...','Name','Interpolating...','WindowStyle','modal'); end

% do backup
getDataOpt.id = BatchOptLocal.id;
getDataOpt.t = BatchOptLocal.t;

switch BatchOptLocal.Target{1}
    case {'mask', 'selection'}
        selection = cell2mat(obj.getData3D(BatchOptLocal.Target{1}, BatchOptLocal.t, NaN, NaN, getDataOpt));
    case 'model'
        MaterialIndex = str2double(BatchOptLocal.MaterialIndex);
        if MaterialIndex < 1
            if BatchOptLocal.showWaitbar; delete(wb); end
            notify(obj, 'stopProtocol');
            return; 
        end
        selection = cell2mat(obj.getData3D(BatchOptLocal.Target{1}, BatchOptLocal.t, NaN, MaterialIndex, getDataOpt));
end

if obj.I{getDataOpt.id}.blockModeSwitch == 0
    xShift = 0;
    yShift = 0;
    zShift = 0;
else
    transposeTo4 = 1;
    [yMin, ~, xMin, ~, zMin, ~] = obj.I{getDataOpt.id}.getCoordinatesOfShownImage(transposeTo4);
    xShift = xMin - 1;
    yShift = yMin - 1;
    zShift = zMin - 1;
end

storeOptions.id = getDataOpt.id;
if strcmp(BatchOptLocal.InterpolationType{1}, 'shape')    % shape interpolation
    [selection, bb] = mibInterpolateShapes(selection, obj.preferences.interpolationNoPoints);
    if isempty(bb)
        if BatchOptLocal.showWaitbar; delete(wb); end
        return;
    end
    
    % bb = [xMin, xMax, yMin, yMax, zMin, zMax]
    if obj.I{getDataOpt.id}.orientation == 1     % xz
        storeOptions.y = [bb(5)+yShift, bb(6)+yShift];  % [minPnt, maxPnt]
        storeOptions.z = [bb(1)+zShift, bb(2)+zShift];
        storeOptions.x = [bb(3)+xShift, bb(4)+xShift];
    elseif obj.I{getDataOpt.id}.orientation == 2 % yz
        storeOptions.y = [bb(3)+yShift, bb(4)+yShift];  % [minPnt, maxPnt]
        storeOptions.z = [bb(1)+zShift, bb(2)+zShift];
        storeOptions.x = [bb(5)+xShift, bb(6)+xShift];
    elseif obj.I{getDataOpt.id}.orientation == 4 % yx
        storeOptions.y = [bb(3)+yShift, bb(4)+yShift];  % [minPnt, maxPnt]
        storeOptions.x = [bb(1)+xShift, bb(2)+xShift];
        storeOptions.z = [bb(5)+zShift, bb(6)+zShift];    
    end
else    % line interpolation
    selection = mibInterpolateLines(selection, obj.preferences.interpolationNoPoints, obj.preferences.interpolationLineWidth);
end
obj.mibDoBackup(BatchOptLocal.Target{1}, 1, storeOptions);

switch BatchOptLocal.Target{1}
    case {'mask', 'selection'}
        obj.setData3D(BatchOptLocal.Target{1}, selection, BatchOptLocal.t, NaN, NaN, getDataOpt);
    case 'model'
        obj.setData3D(BatchOptLocal.Target{1}, selection, BatchOptLocal.t, NaN, MaterialIndex, getDataOpt);
end
if BatchOptLocal.showWaitbar; waitbar(1,wb); end
toc

% notify the batch mode
BatchOptLocal = rmfield(BatchOptLocal, 'id');     % remove id from the BatchOpt structure
BatchOptLocal = rmfield(BatchOptLocal, 't');     % remove t from the BatchOpt structure
eventdata = ToggleEventData(BatchOptLocal);
notify(obj, 'syncBatch', eventdata);
if BatchOpt.showWaitbar; delete(wb); end

notify(obj, 'plotImage');  % notify to plot the image

end


