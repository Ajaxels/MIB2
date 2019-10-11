function mibSegmentationSpot(obj, y, x, modifier, BatchOptIn)
% mibSegmentationSpot(obj, y, x, modifier, BatchOptIn)
% Do segmentation using the spot tool
%
% Parameters:
% y: y-coordinate of the spot center
% x: x-coordinate of the spot center
% modifier: a string, to specify what to do with the generated selection
% - @em empty - makes new selection
% - @em ''control'' - removes selection from the existing one
% BatchOptIn: a structure for batch processing mode, when NaN return
%   a structure with default options via "syncBatch" event, see Declaration of the BatchOpt structure below for details, the function
%   variables are preferred over the BatchOptIn variables
% @li .Radius - Spot radius in pixels
% @li .X - Vector or a single X coordinate of the spot center
% @li .Y - Vector or a single X coordinate of the spot center
% @li .Z - Vector or a single Z coordinate of the spot center, keep empty to use the currently shown
% @li .Mode - Add or subtract spot at the provided coordinate(s)
% @li .Check3D - Make spot in 3D, the spot will be shown on all slices
% @li .FixSelectionToMask - Apply thresholding only to the masked area
% @li .FixSelectionToMaterial - Apply thresholding only to the area of the selected material; use Modify checkboxes to update the selected material
% @li .Orientation - Orientation of the dataset
% @li .Target - Destination layer for spot
% @li .showWaitbar - Show or not the progress bar during execution

% Return values:

% Copyright (C) 22.02.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

radius = str2double(obj.mibView.handles.mibSegmSpotSizeEdit.String)-2;
if radius < 1; radius = 0.5; end
radius = round(radius);

%% Declaration of the BatchOpt structure
BatchOpt = struct();
BatchOpt.id = obj.mibModel.Id;   % optional, id
BatchOpt.Radius = num2str(radius);
if ~isempty(x)
    BatchOpt.X = num2str(x);
else
    BatchOpt.X = '';    
end
if ~isempty(y)
    BatchOpt.Y = num2str(y);
else
    BatchOpt.Y = '';
end
BatchOpt.Z = '';
if isempty(modifier)
    BatchOpt.Mode = {'add'};
else
    if strcmp(modifier, 'shift')
        BatchOpt.Mode = {'add'};
    else
        BatchOpt.Mode = {'erase'};
    end
end
BatchOpt.Mode{2} = {'add', 'erase'};
BatchOpt.Check3D = logical(obj.mibView.handles.mibActions3dCheck.Value);
BatchOpt.FixSelectionToMask = logical(obj.mibModel.I{BatchOpt.id}.fixSelectionToMask);  
BatchOpt.FixSelectionToMaterial = logical(obj.mibModel.I{BatchOpt.id}.fixSelectionToMaterial);  
BatchOpt.Orientation{2} = {'XZ', 'YZ', 'not available', 'YX'};  
BatchOpt.Orientation(1) = BatchOpt.Orientation{2}(obj.mibModel.I{BatchOpt.id}.orientation);  
BatchOpt.Target = {'selection'};
BatchOpt.Target{2} = {'selection', 'mask'};
BatchOpt.showWaitbar = true;   % show or not the waitbar

BatchOpt.mibBatchSectionName = 'Panel -> Segmentation';    % section name for the Batch
BatchOpt.mibBatchActionName = 'Spot';

BatchOpt.mibBatchTooltip.Radius = 'Spot radius in pixels';
BatchOpt.mibBatchTooltip.X = 'Vector or a single X coordinate of the spot center';
BatchOpt.mibBatchTooltip.Y = 'Vector or a single X coordinate of the spot center';
BatchOpt.mibBatchTooltip.Z = 'Vector or a single Z coordinate of the spot center, keep empty to use the currently shown';
BatchOpt.mibBatchTooltip.Mode = 'Add or subtract a spot at the provided coordinate(s)';
BatchOpt.mibBatchTooltip.Check3D = 'Make spot in 3D, the spot will be shown on all slices';
BatchOpt.mibBatchTooltip.FixSelectionToMask = 'Apply spot only to the masked area';
BatchOpt.mibBatchTooltip.FixSelectionToMaterial = 'Apply spot only to the area of the selected material; use Modify checkboxes to update the selected material';
BatchOpt.mibBatchTooltip.Orientation = 'Orientation of the dataset';
BatchOpt.mibBatchTooltip.Target = 'Destination layer for spot';
BatchOpt.mibBatchTooltip.showWaitbar = 'Show or not the progress bar during execution';

%% 
if nargin == 5  % batch mode 
    if isstruct(BatchOptIn) == 0
        if isnan(BatchOptIn)     % when varargin{3} == NaN return possible settings
            % trigger syncBatch event to send BatchOptInOut to mibBatchController 
            BatchOpt = rmfield(BatchOpt, 'id');     % remove id field
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 5th parameter is required!'));
        end
        return;
    else
        % add/update BatchOpt with the provided fields in BatchOptIn
        % combine fields from input and default structures
        BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptIn);
    end
end

%%
selcontour = obj.mibModel.I{BatchOpt.id}.getSelectedMaterialIndex();
xVec = str2num(BatchOpt.X); %#ok<ST2NM>
yVec = str2num(BatchOpt.Y); %#ok<ST2NM>
if isempty(BatchOpt.Z)
    zVec = obj.mibModel.I{BatchOpt.id}.getCurrentSliceNumber();
else
    zVec = str2num(BatchOpt.Z);     %#ok<ST2NM>
end
if numel(xVec) ~= numel(yVec)
    errordlg(sprintf('!!! Error !!!\n\nNumber of X and Y coordinate mismatch!'), 'Spot segmentation');
    notify(obj.mibModel, 'stopProtocol');
    return;
end
if numel(zVec) < numel(xVec)    % make the zVec equal to xVec and yVec
    zVec = repmat(zVec(1), [1, numel(xVec)]);
end

orientation = find(ismember(BatchOpt.Orientation{2}, BatchOpt.Orientation{1}));
options.id = BatchOpt.id;
radius = str2double(BatchOpt.Radius);

showWaitbarLocal = 0;
if BatchOpt.showWaitbar && (BatchOpt.Check3D || numel(xVec) > 1)
    showWaitbarLocal = 1;
end
if showWaitbarLocal; wb = waitbar(0, 'Please wait...', 'Name', 'Spot segmentation'); end
backupOptions.id = BatchOpt.id;

for index = 1:numel(xVec)
    options.x = [xVec(index)-radius xVec(index)+radius];
    options.y = [yVec(index)-radius yVec(index)+radius];
    options.z = [zVec(index) zVec(index)];
    options.blockModeSwitch = 0;
    % recalculate x and y for the obtained cropped image
    x = radius + min([options.x(1) 1]);
    y = radius + min([options.y(1) 1]);

    currSelection = cell2mat(obj.mibModel.getData2D(BatchOpt.Target{1}, zVec(index), orientation, NaN, options));
    currSelection2 = zeros(size(currSelection), 'uint8');
    currSelection2(y, x) = 1;
    currSelection2 = bwdist(currSelection2); 
    currSelection2 = uint8(currSelection2 <= radius);

    if BatchOpt.Check3D
        if orientation == 4
            backupOptions.y = options.y;
            backupOptions.x = options.x;
        elseif orientation == 1
            backupOptions.x = options.y;
            backupOptions.z = options.x;
        elseif orientation == 2
            backupOptions.y = options.y;
            backupOptions.z = options.x;
        end

        if numel(xVec) == 1; obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 1, backupOptions); end
        
        orient = orientation;
        [localHeight, localWidth, localColor, localThick] = obj.mibModel.I{BatchOpt.id}.getDatasetDimensions(BatchOpt.Target{1}, orient, NaN, options);
        selarea = zeros([size(currSelection,1), size(currSelection,2), localThick],'uint8');
        options.z = [1, localThick];
        for layer_id = 1:size(selarea, 3)
            selarea(:,:,layer_id) = currSelection2;
        end

        % limit to the selected material of the model
        if BatchOpt.FixSelectionToMaterial
            currSelection = cell2mat(obj.mibModel.getData3D('model', NaN, orient, selcontour, options));
            selarea = bitand(selarea, currSelection);
        end
        % limit selection to the masked area
        if BatchOpt.FixSelectionToMask && obj.mibModel.I{BatchOpt.id}.maskExist   % do selection only in the masked areas
            currSelection = cell2mat(obj.mibModel.getData3D('mask', NaN, orient, selcontour, options));
            selarea = bitand(selarea, currSelection);
        end

        currSelection = cell2mat(obj.mibModel.getData3D(BatchOpt.Target{1}, NaN, orient, NaN, options));
        if strcmp(BatchOpt.Mode{1}, 'add')    % combines selections
            obj.mibModel.setData3D(BatchOpt.Target{1}, bitor(selarea, currSelection), NaN, orient, NaN, options);
        else  % subtracts selections
            currSelection(selarea==1) = 0;
            obj.mibModel.setData3D(BatchOpt.Target{1}, currSelection, NaN, orient, NaN, options);
        end
    else
        if index == 1   % do backup
            if numel(xVec) == 1
                obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 0, options); 
            else
                if numel(unique(zVec)) == 1
                    backupOpt.id = options.id;
                    backupOpt.z = options.z;
                    obj.mibModel.mibDoBackup(BatchOpt.Target{1}, 0, backupOpt); 
                end
            end
        end
        selarea = currSelection2;

        % limit to the selected material of the model
        if BatchOpt.FixSelectionToMaterial
            currModel = cell2mat(obj.mibModel.getData2D('model', zVec(index), orientation, selcontour, options));
            selarea = bitand(selarea, currModel);
        end

        % limit selection to the masked area
        if BatchOpt.FixSelectionToMask && obj.mibModel.I{BatchOpt.id}.maskExist
            currModel = cell2mat(obj.mibModel.getData2D('mask', zVec(index), orientation, NaN, options));
            selarea = bitand(selarea, currModel);
        end

        if strcmp(BatchOpt.Mode{1}, 'add')    % combines selections
            obj.mibModel.setData2D(BatchOpt.Target{1}, bitor(currSelection, selarea), zVec(index), orientation, NaN, options);
        else   % subtracts selections
            currSelection(selarea==1) = 0;
            obj.mibModel.setData2D(BatchOpt.Target{1}, currSelection, zVec(index), orientation, NaN, options);
        end
    end
    if showWaitbarLocal; wb = waitbar(index/numel(xVec), wb); end
end
if showWaitbarLocal; delete(wb); end
obj.plotImage();
