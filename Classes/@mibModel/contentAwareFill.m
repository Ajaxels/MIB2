function contentAwareFill(obj, BatchOptIn)
% function contentAwareFill(obj, BatchOptIn)
% Fill the selected area using content aware algorithms
%
% Parameters:
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event
% Possible fields,
% @li .Method - cell string, method for content aware fill, {'inpaintCoherent'} or {'inpaintExemplar'};
% @li .Mask - cell string, specification of the layer that should be used for content aware filling {'selection'} or  {'mask'};
% @li .Mode - cell string, apply for current slice or full dataset {'Shown slice (2D)', 'Current stack (3D)', 'Complete volume (4D)'};
% @li .Radius - string, with radius
% @li .FillOrder - cell string, filling order {'gradient', 'tensor'}, only for inpaintExemplar
% @li .SmoothingFactor - string, smoothing factor, only for inpaintCoherent
% @li .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset

% Copyright (C) 16.04.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 27.06.2019, added inpaintExemplar for R2019b and newer

global mibPath;

matlabVersion = ver('Matlab');
matlabVersion = str2double(matlabVersion.Version);
if matlabVersion < 9.6
    warndlg(sprintf('!!! Warning !!!\n\nMatlab R2019a or newer is required!'), 'Matlab is too old');
    notify(obj, 'stopProtocol');
    return;
elseif matlabVersion < 9.7
    PossibleMethods = {'inpaintCoherent'};
else
    PossibleMethods = {'inpaintCoherent','inpaintExemplar'};
end

%% specify default BatchOptIn
PossibleMasks = {'selection', 'mask'};
PossibleModes = {'Shown slice (2D)', 'Current stack (3D)', 'Complete volume (4D)'};
BatchOpt = struct();
if isfield(obj.sessionSettings, 'contentAwareFill')
    BatchOpt.Method = obj.sessionSettings.contentAwareFill.Method;
    BatchOpt.Mask = obj.sessionSettings.contentAwareFill.Mask;
    BatchOpt.Mode = obj.sessionSettings.contentAwareFill.Mode;
    BatchOpt.FillOrder = obj.sessionSettings.contentAwareFill.FillOrder;
else
    BatchOpt.Method = {'inpaintCoherent'};
    BatchOpt.Mask = {'selection'};
    BatchOpt.Mode = {'Shown slice (2D)'};
    BatchOpt.FillOrder = {'gradient'};
end
BatchOpt.Method{2} = PossibleMethods;
BatchOpt.Mask{2} = PossibleMasks;
BatchOpt.Mode{2} = PossibleModes;
BatchOpt.Radius = '5';  % both inpaintCoherent and inpaintExemplar
BatchOpt.SmoothingFactor = '4'; % only for inpaintCoherent
BatchOpt.FillOrder{2} = {'gradient', 'tensor'};    % only for inpaintExemplar
BatchOpt.showWaitbar = true;   % show or not the waitbar
BatchOpt.id = obj.Id;   % optional, id

BatchOpt.mibBatchSectionName = 'Menu -> Image';
BatchOpt.mibBatchActionName = 'Tools for Images -> Content-aware fill';
% tooltips that will accompany the BatchOpt
BatchOpt.mibBatchTooltip.Method = sprintf('Methods for content aware fill, Coherent requires R2019a or newer, Exemplar - R2019b or newer');
BatchOpt.mibBatchTooltip.Mask = sprintf('Specify whether the areas for the content filling are highlighted using selection or mask layers');
BatchOpt.mibBatchTooltip.Mode = sprintf('Apply operation for the current slice (2D), current stack (3D) or the whole dataset (4D)');
BatchOpt.mibBatchTooltip.Radius = sprintf('The radius (Coherent) or PatchSize (Exemplar)');
BatchOpt.mibBatchTooltip.SmoothingFactor = sprintf('[Coherent only]: smoothing factor is used to compute the scales of the Gaussian filters while estimating the coherence direction');
BatchOpt.mibBatchTooltip.FillOrder = sprintf('[Exemplar only]: The filling order denotes the priority function to be used for calculating the patch priority');
BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not the progress bar during execution');

if nargin == 2  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
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

%% Checks
if obj.I{BatchOpt.id}.Virtual.virtual == 1
    toolname = 'The content-aware fill is';
    warndlg(sprintf('!!! Warning !!!\n\n%s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    notify(obj, 'stopProtocol');
    return;
end

%% Settings for the standard mode
if nargin < 2
    prompts = {'Method'; 'Mask'; 'Mode'; 'Radius (Coherent) / PatchSize (Exemplar)'; 'SmoothingFactor (Coherent only)'; 'Fill Order (Exemplar)'};
    defAns = {[BatchOpt.Method{2}, {find(ismember(BatchOpt.Method{2}, BatchOpt.Method{1})==1)}]; ...
              [BatchOpt.Mask{2}, {find(ismember(BatchOpt.Mask{2}, BatchOpt.Mask{1})==1)}]; ...
              [BatchOpt.Mode{2}, {find(ismember(BatchOpt.Mode{2}, BatchOpt.Mode{1})==1)}]; ...
              BatchOpt.Radius; BatchOpt.SmoothingFactor; ...
              [BatchOpt.FillOrder{2}, {find(ismember(BatchOpt.FillOrder{2}, BatchOpt.FillOrder{1})==1)}] };
    
    dlgTitle = 'Content-aware fill';
    options.WindowStyle = 'normal';       % [optional] style of the window
    options.Title = sprintf('Specify parameters for the content-aware fill.\nOnly the shown color channels will be affected');   % [optional] additional text at the top of the window
    options.TitleLines = 2;
    options.Focus = 1;      % [optional] define index of the widget to get focus
    answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); return; end    
   
    BatchOpt.Method(1) = answer(1);
    BatchOpt.Mask(1) = answer(2);
    BatchOpt.Mode(1) = answer(3);
    BatchOpt.Radius = answer{4};
    BatchOpt.SmoothingFactor = answer{5};
    BatchOpt.FillOrder(1) = answer(6);
end

if BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Content-aware fill\nPlease wait...'), 'Name', 'Content-aware fill'); end

% do content aware fill for the shown colors
[height, width, colors, depth, time] = obj.I{BatchOpt.id}.getDatasetDimensions('image', 4, NaN);

switch BatchOpt.Mode{1}
    case 'Shown slice (2D)'
        if ~isfield(BatchOpt, 't')
            BatchOpt.t = [obj.I{BatchOpt.id}.getCurrentTimePoint obj.I{BatchOpt.id}.getCurrentTimePoint];
        end
        if ~isfield(BatchOpt, 'z')
            BatchOpt.z = [obj.I{BatchOpt.id}.getCurrentSliceNumber obj.I{BatchOpt.id}.getCurrentSliceNumber];
        end
        obj.mibDoBackup('image', 0, BatchOpt);   % backup current data
    case 'Current stack (3D)'
        if ~isfield(BatchOpt, 't')
            BatchOpt.t = [obj.I{BatchOpt.id}.getCurrentTimePoint obj.I{BatchOpt.id}.getCurrentTimePoint];
        end
        if ~isfield(BatchOpt, 'z')
            BatchOpt.z = [1 obj.I{BatchOpt.id}.dim_yxczt(obj.I{BatchOpt.id}.orientation)];
        end
        obj.mibDoBackup('image', 1, BatchOpt);   % backup current data
    case 'Complete volume (4D)'
        if ~isfield(BatchOpt, 't')
            BatchOpt.t = [1 obj.I{BatchOpt.id}.dim_yxczt(5)];
        end
        if ~isfield(BatchOpt, 'z')
            BatchOpt.z = [1 obj.I{BatchOpt.id}.dim_yxczt(obj.I{BatchOpt.id}.orientation)];
        end
end

if ~isfield(BatchOpt, 'c')
    BatchOpt.c = colors;
end

Radius = str2num(BatchOpt.Radius); %#ok<ST2NM>
SmoothingFactor = str2double(BatchOpt.SmoothingFactor);
maxWaitbarValue = (diff(BatchOpt.t)+1) * numel(BatchOpt.c);   % for the waitbar
waitbarIndex = 1;
getDataOptions.z = BatchOpt.z;
getDataOptions.id = BatchOpt.id;
for t=BatchOpt.t(1):BatchOpt.t(2)
    mask = logical(cell2mat(obj.getData3D(BatchOpt.Mask{1}, t, NaN, NaN, getDataOptions)));
    for colChId = 1:numel(BatchOpt.c)
        img = cell2mat(obj.getData3D('image', t, NaN, BatchOpt.c(colChId), getDataOptions));
        for z=1:size(img, 4)
            switch BatchOpt.Method{1}
                case 'inpaintCoherent'
                    img(:,:,:,z) = inpaintCoherent(img(:,:,:,z), mask(:,:,z), 'SmoothingFactor', SmoothingFactor, 'Radius', Radius);
                case 'inpaintExemplar'
                    img(:,:,:,z) = inpaintExemplar(img(:,:,:,z), mask(:,:,z), 'FillOrder', BatchOpt.FillOrder{1}, 'PatchSize', Radius);
            end
        end
        obj.setData3D('image', img, t, NaN, BatchOpt.c(colChId), getDataOptions);
        if BatchOpt.showWaitbar; waitbar(waitbarIndex/maxWaitbarValue, wb); waitbarIndex = waitbarIndex + 1; end
    end
end

logText = sprintf('Content-aware fill, Method:%s, c=[%s] z=[%d %d], t=[%d %d], orientation=%d', ...
    BatchOpt.Method{1}, num2str(BatchOpt.c), BatchOpt.z(1), BatchOpt.z(2), ...
    BatchOpt.t(1), BatchOpt.t(2), obj.I{BatchOpt.id}.orientation);
obj.I{BatchOpt.id}.updateImgInfo(logText);

% store used parameters into the session settings structure
obj.sessionSettings.contentAwareFill.Method = BatchOpt.Method(1);
obj.sessionSettings.contentAwareFill.Mask = BatchOpt.Mask(1);
obj.sessionSettings.contentAwareFill.Mode = BatchOpt.Mode(1);
obj.sessionSettings.contentAwareFill.FillOrder = BatchOpt.FillOrder(1);

% notify the batch mode
BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
eventdata = ToggleEventData(BatchOpt);
notify(obj, 'syncBatch', eventdata);

notify(obj, 'plotImage');  % notify to plot the image

if BatchOpt.showWaitbar; delete(wb); end

end