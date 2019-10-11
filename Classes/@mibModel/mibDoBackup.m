function mibDoBackup(obj, type, switch3d, getDataOptions)
% function mibDoBackup(obj, type, switch3d, getDataOptions)
% Store the dataset for Undo
%
% The dataset is stored in imageUndo class
% 
% Parameters:
% type: ''image'', ''selection'', ''mask'', ''model'', 'labels',
% ''everything'' (for mibImage.modelType==63 only), ''lines3d'', ''labels''
% switch3d: - a switch to define a 2D or 3D mode to store the dataset dataset
% - @b 0 - 2D slice
% - @b 1 - 3D dataset
% getDataOptions: - an optional structure with extra parameters
% @li .y -> [@em optional], [ymin, ymax] of the part of the dataset to store
% @li .x -> [@em optional], [xmin, xmax] of the part of the dataset to store
% @li .z -> [@em optional], [zmin, zmax] of the part of the dataset to store
% @li .t -> [@em optional], [tmin, tmax] of the part of the dataset to store
% @li .roiId -> [@em optional], use or not the ROI mode (@b when missing or less than 0, return full dataset; @b 0 - return all shown ROIs dataset, @b Index or [] - return ROI with this index or currently selected)
% @li .id -> [@em optional], index of the dataset to backup

%|
% @b Examples:
% @code obj.mibModel.mibDoBackup('labels', 0);     // call from mibController: store labels @endcode
% @code obj.mibModel.mibDoBackup('selection', 1);     // call from mibController: store the selection layer for 3D dataset @endcode

% Copyright (C) 15.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 01.07.2019 added getDataOptions.id option

% check for the virtual stacking mode and return
if obj.I{obj.Id}.Virtual.virtual == 1
    if ismember(type, {'mask','selection','model','everything'})    % disable backup for these modes
        return;
    end
end

% cancel if the undo system is disabled
if obj.U.enableSwitch == 0; return; end
if nargin < 4; getDataOptions = struct(); end
if ~isfield(getDataOptions, 'id'); getDataOptions.id = obj.Id; end

if strcmp(type, 'lines3d')
    obj.U.store(type, {copy(obj.I{getDataOptions.id}.hLines3D)});
    return;
end

% replace types 'selection','mask','model' to 'everything' for uint6 models
if obj.I{getDataOptions.id}.modelType == 63
    if strcmp(type, 'selection') || strcmp(type, 'mask') || strcmp(type, 'model')
        type = 'everything';
    end
end

% return when no mask
if strcmp(type, 'mask') && obj.I{getDataOptions.id}.maskExist == 0;  return;   end

[axesX, axesY] = obj.getAxesLimits(getDataOptions.id);
orientation = obj.I{getDataOptions.id}.orientation;
blockModeSwitch = obj.I{getDataOptions.id}.blockModeSwitch;
roiIds = 1;     % number of datasets to store

if ~isfield(getDataOptions, 'orient')
    if switch3d == 1
        getDataOptions.orient = 4; 
    else
        getDataOptions.orient = obj.I{getDataOptions.id}.orientation; 
    end
end

% disable the block mode for the getData
getDataOptions.blockModeSwitch = 0;
getDataOptions.switch3d = switch3d;
getDataOptions.modelExist = obj.I{getDataOptions.id}.modelExist;
getDataOptions.maskExist = obj.I{getDataOptions.id}.maskExist;

% deal with the ROI mode
if isfield(getDataOptions, 'roiId') && blockModeSwitch == 0     % roi mode is disabled in when the block mode switch is on
    % populate getDataOptions from roiId
    if isempty(getDataOptions.roiId); getDataOptions.roiId = obj.I{getDataOptions.id}.selectedROI;  end
    
    %if getDataOptions.roiId == -1
    %    getDataOptions = rmfield(getDataOptions,'roiId');
    %else
    if getDataOptions.roiId >= 0
        roiIds = getDataOptions.roiId;
        if roiIds >= 0
            if roiIds == 0
                [~, roiIds] = obj.I{getDataOptions.id}.hROI.getNumberOfROI();  % get number of ROI for the selected orientation
            end
            roiId2 = 1;
            getDataOptions.x = zeros([numel(roiIds), 2]);
            getDataOptions.y = zeros([numel(roiIds), 2]);
            for roiId = 1:numel(roiIds)
                bb = obj.I{getDataOptions.id}.hROI.getBoundingBox(roiIds(roiId));
                getDataOptions.x(roiId2, :) = [bb(1), bb(2)];
                getDataOptions.y(roiId2, :) = [bb(3), bb(4)];
                roiId2 = roiId2 + 1;
            end
            getDataOptions.orient = obj.I{getDataOptions.id}.orientation;
            
        end
    end
else
    % remove roiId field if it is present; while working with the block mode
    %if isfield(getDataOptions, 'roiId'); getDataOptions = rmfield(getDataOptions,'roiId'); end;       
    getDataOptions.roiId = -1; % turn off the ROI mode
end

% when the block mode is enabled store only information inside the shown
% block, when ROI is not shown
if blockModeSwitch
    if switch3d
        if orientation==1     % xz
            if ~isfield(getDataOptions, 'x')
                getDataOptions.z = ceil(axesX);
            end
            if ~isfield(getDataOptions, 'y')
                getDataOptions.x = ceil(axesY);
            end
        elseif orientation==2 % yz
            if ~isfield(getDataOptions, 'x')
                getDataOptions.z = ceil(axesX);
            end
            if ~isfield(getDataOptions, 'y')
                getDataOptions.y = ceil(axesY);
            end
        elseif orientation==4 % yx
            if ~isfield(getDataOptions, 'x')
                getDataOptions.x = ceil(axesX);
            end
            if ~isfield(getDataOptions, 'y')
                getDataOptions.y = ceil(axesY);
            end
        end
        % make sure that the coordinates within the dimensions of the dataset
        if isfield(getDataOptions, 'x')
            getDataOptions.x = [max([getDataOptions.x(1) 1]) min([getDataOptions.x(2) obj.I{getDataOptions.id}.width])];
        end
        if isfield(getDataOptions, 'y')
            getDataOptions.y = [max([getDataOptions.y(1) 1]) min([getDataOptions.y(2) obj.I{getDataOptions.id}.height])];
        end
        if isfield(getDataOptions, 'z')
            getDataOptions.z = [max([getDataOptions.z(1) 1]) min([getDataOptions.z(2) obj.I{getDataOptions.id}.depth])];
        end
        getDataOptions.orient = 4;  % force the orientation for 3D datasets to XY
    else
        [blockHeight, blockWidth] = obj.I{getDataOptions.id}.getDatasetDimensions('image', orientation, 0, getDataOptions);
        if ~isfield(getDataOptions, 'x')
            getDataOptions.x = ceil(axesX);
            getDataOptions.x = [max([getDataOptions.x(1) 1]) min([getDataOptions.x(2) blockWidth])];
        end
        if ~isfield(getDataOptions, 'y')
            getDataOptions.y = ceil(axesY);
            getDataOptions.y = [max([getDataOptions.y(1) 1]) min([getDataOptions.y(2) blockHeight])];
        end
        getDataOptions.orient = orientation; 
    end
end

if ~isfield(getDataOptions, 'z') && switch3d==0
    sliceNo = obj.I{getDataOptions.id}.getCurrentSliceNumber();
    getDataOptions.z = [sliceNo, sliceNo];
    getDataOptions.z = repmat(getDataOptions.z, [numel(roiIds), 1]);
end

if ~isfield(getDataOptions, 't')
    timePnt = obj.I{getDataOptions.id}.getCurrentTimePoint();
    getDataOptions.t = [timePnt, timePnt];
    getDataOptions.t = repmat(getDataOptions.t, [numel(roiIds), 1]);
end

if switch3d == 1        % 3D mode
    if strcmp(type, 'image')
        getDataOptions.viewPort = obj.I{getDataOptions.id}.viewPort;
        obj.U.store(type, obj.getData3D(type, NaN, getDataOptions.orient, 0, getDataOptions), obj.I{getDataOptions.id}.meta, getDataOptions);
    elseif strcmp(type, 'labels')
        [labels.labelText, labels.labelValue, labels.labelPosition] = obj.I{getDataOptions.id}.hLabels.getLabels();
        obj.U.store(type, {labels}, NaN);
    elseif strcmp(type, 'measurements')
        obj.U.store(type, {obj.I{getDataOptions.id}.hMeasure.Data}, NaN);
    else
        if obj.I{getDataOptions.id}.disableSelection == 1; return; end    % do not make backups if selection is disabled
        if strcmp(type, 'image')
            obj.U.store(type, obj.getData3D(type, NaN, getDataOptions.orient, 0, getDataOptions), NaN, getDataOptions);
        else
            obj.U.store(type, obj.getData3D(type, NaN, getDataOptions.orient, NaN, getDataOptions), NaN, getDataOptions);
        end
    end
else                    % 2D mode
    if strcmp(type, 'image')
        getDataOptions.viewPort = obj.I{getDataOptions.id}.viewPort;
        obj.U.store(type, obj.getData2D(type, getDataOptions.z(1), getDataOptions.orient, 0, getDataOptions), obj.I{getDataOptions.id}.meta, getDataOptions);
    elseif strcmp(type, 'labels')
        [labels.labelText, labels.labelValue, labels.labelPosition] = obj.I{getDataOptions.id}.hLabels.getLabels();
        obj.U.store(type, {labels}, NaN, getDataOptions);
    elseif strcmp(type, 'measurements')
        obj.U.store(type, {obj.I{getDataOptions.id}.hMeasure.Data}, NaN, getDataOptions);
    else
        if obj.I{getDataOptions.id}.disableSelection == 1; return; end    % do not make backups if selection is disabled
        if strcmp(type, 'image')
            obj.U.store(type, obj.getData2D(type, getDataOptions.z(1), getDataOptions.orient, 0, getDataOptions), NaN, getDataOptions);
        else
            obj.U.store(type, obj.getData2D(type, getDataOptions.z(1), getDataOptions.orient, NaN, getDataOptions), NaN, getDataOptions);
        end
    end
end
%sprintf('Backup: Index=%d, numel=%d, max=%d', handles.U.undoIndex, numel(handles.U.undoList), handles.U.max_steps)
end