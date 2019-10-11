function mibSegmentationMagicWand(obj, yxzCoordinate, modifier)
% function mibSegmentationMagicWand(obj, yxzCoordinate, modifier)
% Do segmentation using the Magic Wand tool
%
% Parameters:
% yxzCoordinate: a vector with [y,x,z] coodrinates of the starting point,
% for 2d case it is enough to have only [y, x].
% modifier: a string, to specify what to do with the generated selection
% - @em empty - makes new selection
% - @em ''shift'' - add selection to the existing one
% - @em ''control'' - removes selection from the existing one
%
% Return values:
% 

%| @b Examples:
% @code yxzCoordinate = [50, 75]; @endcode
% @code obj.mibSegmentationMagicWand(yxzCoordinate, modifier);  // call from mibController; start the magic wand tool from position [y,x]=50,75 @endcode

% Copyright (C) 20.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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

tic
switch3d = obj.mibView.handles.mibActions3dCheck.Value;     % use tool in 3d
selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
threshold1 = str2double(obj.mibView.handles.mibSelectionToolEdit.String); % getting low threshold shift for magic wand tool
threshold2 = str2double(obj.mibView.handles.mibMagicUpThresEdit.String); % getting up threshold shift for magic wand tool

col_channel = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;   
if col_channel == 0
    if obj.mibModel.getImageProperty('colors') > 1
        msgbox('Please select the color channel!','Error!','error','modal');
        return;
    else
        col_channel = 1;
    end
end

if obj.mibModel.getImageProperty('depth') < 3; switch3d = 0; end
magicWandRadius = str2double(obj.mibView.handles.mibMagicWandRadius.String);

if ~switch3d    % do magic wand in 2d
    x = yxzCoordinate(2);
    y = yxzCoordinate(1);
    obj.mibModel.mibDoBackup('selection', 0);
    if magicWandRadius > 0
        options.x = [x-magicWandRadius x+magicWandRadius];
        options.y = [y-magicWandRadius y+magicWandRadius];
        % recalculate x and y for the obtained cropped image
        x = magicWandRadius + min([options.x(1) 1]);
        y = magicWandRadius + min([options.y(1) 1]);
        options.blockModeSwitch = 0;
    else
        options = struct();
    end
    currImage = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, col_channel, options));
    val = currImage(y, x); % intensity
    upper = val + threshold2;
    lower = val - threshold1;
    selarea = zeros([size(currImage,1), size(currImage,2)], 'uint8') + 1;
    
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
        currModel = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, selcontour, options));
        selarea = bitand(selarea, currModel);
    end
    
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask && obj.mibModel.getImageProperty('maskExist') == 1
        currModel = cell2mat(obj.mibModel.getData2D('mask', NaN, NaN, NaN, options));
        selarea = bitand(selarea, currModel);
    end
    
    selarea(currImage < lower) = 0;
    selarea(currImage > upper) = 0;
    
    if obj.mibView.handles.mibMagicwandConnectCheck.Value   % select connected regions with 8 points connection
        selarea = uint8(bwselect(selarea, x, y, 8));
    elseif obj.mibView.handles.mibMagicwandConnectCheck4.Value  % select connected regions with 4 points connection
        selarea = uint8(bwselect(selarea, x, y, 4));
    end
    
    if magicWandRadius > 0
        distMap =  zeros([size(currImage, 1), size(currImage, 2)], 'uint8');
        distMap(y, x) = 1;
        distMap = bwdist(distMap);
        selarea(distMap > magicWandRadius) = 0;
    end
    
    if strcmp(modifier, 'shift')    % combines selections
        currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        obj.mibModel.setData2D('selection', bitor(currSelection, selarea), NaN, NaN, NaN, options);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        currSelection(selarea==1) = 0;
        obj.mibModel.setData2D('selection', currSelection, NaN, NaN, NaN, options);
    else
        slices = obj.mibModel.getImageProperty('slices');
        obj.mibModel.I{obj.mibModel.Id}.clearSelection([slices{1}(1), slices{1}(2)], [slices{2}(1), slices{2}(2)], ...
                                                       [slices{4}(1), slices{4}(2)], [slices{5}(1), slices{5}(1)]);
        obj.mibModel.setData2D('selection', selarea, NaN, NaN, NaN, options);
    end
else    % do magic wand in 3d
    wb = waitbar(0, 'Please wait...','name','Doing Magic Wand in 3D');
    orient = 4;
    waitbar(0.05, wb);
    h = yxzCoordinate(1);
    w = yxzCoordinate(2);
    z = yxzCoordinate(3);
    if magicWandRadius > 0  % limit magic wand to smaller area
        options.x = [w-magicWandRadius w+magicWandRadius];  % calculate crop area
        options.y = [h-magicWandRadius h+magicWandRadius];
        options.z = [z-magicWandRadius z+magicWandRadius];
        % recalculate x and y for the obtained cropped image
        w = magicWandRadius + min([options.x(1) 1]);
        h = magicWandRadius + min([options.y(1) 1]);
        z = magicWandRadius + min([options.z(1) 1]);
        obj.mibModel.mibDoBackup('selection', 1, options);
        options.blockModeSwitch = 0;
    else
        options = struct();
        if obj.mibModel.getImageProperty('orientation') ~= 4    % the block mode is only implemented for the XY orientation
            options.blockModeSwitch = 0;
            obj.mibModel.setImageProperty('blockModeSwitch', 0)
        end
        obj.mibModel.mibDoBackup('selection', 1);
    end
    
    datasetImage = cell2mat(obj.mibModel.getData3D('image', NaN, orient, col_channel, options));
    
    val = datasetImage(h, w, 1, z); % intensity
    upper = val + threshold2;
    lower = val - threshold1;
    selarea = zeros([size(datasetImage,1) size(datasetImage,2) size(datasetImage,4)], 'uint8');
    waitbar(0.3, wb);
    selarea(datasetImage>=lower & datasetImage<=upper) = 1;
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
        datasetImage = cell2mat(obj.mibModel.getData3D('model', NaN, orient, selcontour, options));
        selarea(datasetImage~=1) = 0;
        waitbar(0.4, wb);
    end
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask == 1 && obj.mibModel.getImageProperty('maskExist') == 1
        datasetImage = cell2mat(obj.mibModel.getData3D('mask', NaN, orient, NaN, options));
        selarea(datasetImage~=1) = 0;
    end
    waitbar(0.5, wb);
    
    id = 0;
    if obj.mibView.handles.mibMagicwandConnectCheck.Value || obj.mibView.handles.mibMagicwandConnectCheck4.Value   % select only connected areas
        if obj.mibView.handles.mibMagicwandConnectCheck4.Value
            CC = bwconncomp(selarea,6); % 6-neighbour points
        else
            CC = bwconncomp(selarea,26); % 26-neighbour points
        end
        if CC.NumObjects == 0
            return;
        end;
        xyz_index = sub2ind(size(selarea), h, w, z);
        find_switch = 1;
        while find_switch
            id = id + 1;
            if id > numel(CC.PixelIdxList) 
                delete(wb);
                return; 
            end;
            if ~isempty(find(CC.PixelIdxList{id}==xyz_index, 1, 'first'))
                find_switch = 0;
            end
        end
        selarea = zeros(size(selarea), 'uint8');
        selarea(CC.PixelIdxList{id}) = 1;
    end
    
    if magicWandRadius > 0
        distMap =  zeros(size(selarea), 'uint8');
        distMap(h, w, z) = 1;
        distMap = bwdist(distMap);
        selarea(distMap>magicWandRadius) = 0;
    end
    waitbar(0.9, wb);
        
    if isempty(modifier)
        obj.clearSelection('3D');
        obj.mibModel.setData3D('selection', selarea, NaN, orient, NaN, options);
    elseif strcmp(modifier, 'shift')    % combines selections
        currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, orient, NaN, options));
        obj.mibModel.setData3D('selection', bitor(currSelection, selarea), NaN, orient, NaN, options);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, orient, NaN, options));
        currSelection(selarea==1) = 0;
        obj.mibModel.setData3D('selection', currSelection, NaN, orient, NaN, options);
    end
    waitbar(1, wb);
    delete(wb);
end
toc
end