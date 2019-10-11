function mibSegmentationRegionGrowing(obj, yxzCoordinate, modifier)
% function mibSegmentationRegionGrowing(obj, yxzCoordinate, modifier)
% Do segmentation using the Region Growing method
%
% Based on Fast 3D/2D Region Growing (MEX), written by Christian Wuerslin, Stanford University.
% http://www.mathworks.com/matlabcentral/fileexchange/41666-fast-3d-2d-region-growing--mex-
% Requires: compiled RegionGrowing_mex.cpp
% To compile: "mex RegionGrowing_mex.cpp"
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
% @code obj.mibSegmentationRegionGrowing(yxzCoordinate, modifier);  // call from mibController; start the region growing segmentation tool from position [y,x]=50,75 @endcode

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
dMaxDif = str2double(obj.mibView.handles.mibSelectionToolEdit.String);  % intensity variation
magicWandRadius = str2double(obj.mibView.handles.mibMagicWandRadius.String);

if ~switch3d    % do region growing in 2d
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
    
    selarea = uint8(regiongrowing(currImage, dMaxDif, [y, x]));
    
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
    
    if magicWandRadius > 0
        distMap =  zeros([size(currImage,1), size(currImage,2)],'uint8');
        distMap(y, x) = 1;
        distMap = bwdist(distMap);
        selarea(distMap>magicWandRadius) = 0;
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
    wb = waitbar(0, 'Please wait...','name','Doing Region Growing in 3D');
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
            obj.mibModel.setImageProperty('blockModeSwitch', 0);
        end
        obj.mibModel.mibDoBackup('selection', 1);
    end
    
    datasetImage = squeeze(cell2mat(obj.mibModel.getData3D('image', NaN, orient, col_channel, options)));
    waitbar(0.3, wb);
    selarea = uint8(regiongrowing(datasetImage, dMaxDif, [h, w, z]));
    waitbar(0.65, wb);
    % limit to the selected material of the model
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMaterial == 1
        datasetImage = cell2mat(obj.mibModel.getData3D('model', NaN, orient, selcontour, options));
        selarea(datasetImage~=1) = 0;
        waitbar(0.4, wb);
    end
    waitbar(0.75, wb);
    % limit selection to the masked area
    if obj.mibModel.I{obj.mibModel.Id}.fixSelectionToMask == 1 && obj.mibModel.getImageProperty('maskExist') == 1
        datasetImage = cell2mat(obj.mibModel.getData3D('mask', NaN, orient, NaN, options));
        selarea(datasetImage~=1) = 0;
    end
    waitbar(0.85, wb);
    if magicWandRadius > 0
        distMap =  zeros(size(selarea), 'uint8');
        distMap(h, w, z) = 1;
        distMap = bwdist(distMap);
        selarea(distMap>magicWandRadius) = 0;
    end
    waitbar(0.95, wb);
        
    if isempty(modifier)
        obj.mibModel.I{obj.mibModel.Id}.clearSelection('3D');
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