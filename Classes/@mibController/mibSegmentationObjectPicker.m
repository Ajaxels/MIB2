function mibSegmentationObjectPicker(obj, yxzCoordinate, modifier)
% function mibSegmentationObjectPicker(obj, yxzCoordinate, modifier)
% Select 2d/3d objects from the Mask or Model layers
%
% Parameters:
% yxzCoordinate: a vector with [y,x,z] coodrinates of the starting point,
% for 2d case it is enough to have only [y, x].
% modifier: a string, to specify what to do with the generated selection
% - @em empty - makes new selection
% - @em ''control'' - removes selection from the existing one
%
% Return values:
% 

%| @b Examples:
% @code yxzCoordinate = [50, 75]; @endcode
% @code handles = obj.mibSegmentationObjectPicker(yxzCoordinate, modifier);  // call from mibController; select object at position [y,x]=50,75 @endcode

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
options.blockModeSwitch = obj.mibModel.getImageProperty('blockModeSwitch');

if obj.mibView.handles.mibSegmMaskClickModelCheck.Value
    type = 'model';
    if obj.mibModel.getImageProperty('modelExist') == 0
        msg = [{'Model was not found!'}
            {'Please create a model first...'}
            ];
        msgbox(msg,'Error!','error','modal');
        return;
    end
    colchannel = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;
else
    type = 'mask';
    if obj.mibModel.getImageProperty('maskExist') == 0
        msg = [{'No mask found!'}
            {'Generate the mask layer first'}
            ];
        msgbox(msg, 'Error!', 'error', 'modal');
        return;
    end
    colchannel = 0;
end

if switch3d
    h = yxzCoordinate(1);
    w = yxzCoordinate(2);
    z = yxzCoordinate(3);
else
    yCrop = yxzCoordinate(1);
    xCrop = yxzCoordinate(2);
end

[axesX, axesY] = obj.mibModel.getAxesLimits();
orientation = obj.mibModel.getImageProperty('orientation');

% update modifier for Lasso, Rectangle, Ellipse, Polyline tools
if obj.mibView.handles.mibFilterSelectionPopup.Value > 1 && obj.mibView.handles.mibFilterSelectionPopup.Value < 6
    if obj.mibView.handles.mibSegmObjectPickerPanelAddPopup.Value == 2 % subtract mode
        modifier = 'control';
    else
        modifier = '';
    end
end
    
switch obj.mibView.handles.mibFilterSelectionPopup.Value
    case 1 % selection with mouse button
        if switch3d
            options.blockModeSwitch = 0;
            
            permuteSwitch = 4;  % get dataset in the XY orientation
            obj_id = obj.mibModel.I{obj.mibModel.Id}.maskStat.L(h, w, z);
            if obj_id == 0; return; end;
            
            % define subset of data for selection
            bb = obj.mibModel.I{obj.mibModel.Id}.maskStat.bb(obj_id).BoundingBox;
            options.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(5))-1];
            options.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(4))-1];
            options.z = [ceil(bb(3)) ceil(bb(3))+floor(bb(6))-1];
            
            obj.mibModel.mibDoBackup('selection', 1, options);

            % get current selection
            currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, permuteSwitch, NaN, options));
            objSelection = zeros(size(currSelection), 'uint8');
            objSelection(obj.mibModel.I{obj.mibModel.Id}.maskStat.L(options.y(1):options.y(2), ...
                options.x(1):options.x(2), options.z(1):options.z(2)) == obj_id) = 1;
            
            % limit to the selected material of the model
            if obj.mibView.handles.mibSegmSelectedOnlyCheck.Value && strcmp(type, 'mask')
                selcontour = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;  % get selected contour
                datasetImage = cell2mat(obj.mibModel.getData3D('model', NaN, permuteSwitch, selcontour, options));
                objSelection(datasetImage~=1) = 0;
            end
            
            % limit selection to the masked area
            if obj.mibView.handles.mibMaskedAreaCheck.Value && obj.mibModel.getImageProperty('maskExist') && strcmp(type, 'model')
                datasetImage = cell2mat(obj.mibModel.getData3D('mask', NaN, permuteSwitch, NaN, options));
                objSelection(datasetImage~=1) = 0;
            end
            
            if isempty(modifier)
                currSelection(objSelection==1) = 1;
                obj.mibModel.setData3D('selection', currSelection, NaN, permuteSwitch, NaN, options);
            elseif strcmp(modifier, 'control')  % subtracts selections
                currSelection(objSelection==1) = 0;
                obj.mibModel.setData3D('selection', currSelection, NaN, permuteSwitch, NaN, options);
            end
            return;
        else
            obj.mibModel.mibDoBackup('selection', 0);
            if strcmp(type,'model') && obj.mibView.handles.mibSegmSelectedOnlyCheck.Value % model with selected only switch
                mask = cell2mat(obj.mibModel.getData2D(type, NaN, NaN, colchannel));
            elseif strcmp(type,'model')
                mask = cell2mat(obj.mibModel.getData2D(type));     % model
                colchannel = mask(yCrop, xCrop);
                if colchannel == 0; return; end;
                %mask = bitand(mask, colchannel);
                mask = bitand(mask, 63)==colchannel;
            else
                mask = cell2mat(obj.mibModel.getData2D(type)); % mask
            end
            selarea = uint8(bwselect(mask, xCrop, yCrop, 4));
        end
    case 2 % selection with lasso tool
        obj.mibView.gui.Pointer = 'cross';
        obj.mibView.gui.WindowButtonDownFcn = [];
        
        h = imfreehand(obj.mibView.handles.mibImageAxes);
        selected_mask = uint8(h.createMask);
        delete(h);
        
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        obj.mibView.gui.Pointer = 'crosshair';
        
        options.blockModeSwitch = 1;
        currMask = cell2mat(obj.mibModel.getData2D(type, NaN, NaN, colchannel, options));
        selected_mask = imresize(selected_mask, [size(currMask,1) size(currMask,2)], 'method', 'nearest');
        
        CC = regionprops(selected_mask,'BoundingBox');
        bb = CC.BoundingBox;
        bb(1) = bb(1) + max([1 ceil(axesX(1))])-1;
        bb(2) = bb(2) + max([1 ceil(axesY(1))])-1;
        
        if orientation == 4
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 1
            backupOptions.x = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 2
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        end
        
        if switch3d
            obj.mibModel.mibDoBackup(type, 1, backupOptions);
            permuteSwitch = NaN;    % get dataset in the shown orientation
            maskDataset = cell2mat(obj.mibModel.getData3D(type, NaN, permuteSwitch, colchannel, options));
            selarea = zeros(size(maskDataset), 'uint8');
            for layer_id = 1:size(selarea, 3)
                selarea(:,:,layer_id) = bitand(selected_mask, maskDataset(:, :, layer_id));
            end
        else
            obj.mibModel.mibDoBackup('selection', 0);
            selarea = bitand(selected_mask, currMask);
        end;
    case 3 % selection with rectangle tool
         obj.mibView.gui.Pointer = 'cross';
        obj.mibView.gui.WindowButtonDownFcn = [];
        
        h =  imrect(obj.mibView.handles.mibImageAxes);
        selected_mask = uint8(h.createMask);
        delete(h);
        
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        obj.mibView.gui.Pointer = 'crosshair';
        
        options.blockModeSwitch = 1;
        currMask = cell2mat(obj.mibModel.getData2D(type, NaN, NaN, colchannel, options));
        selected_mask = imresize(selected_mask, [size(currMask,1) size(currMask,2)], 'method', 'nearest');
        
        CC = regionprops(selected_mask,'BoundingBox');
        bb = CC.BoundingBox;
        bb(1) = bb(1) + max([1 ceil(axesX(1))])-1;
        bb(2) = bb(2) + max([1 ceil(axesY(1))])-1;
        
        if orientation == 4
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 1
            backupOptions.x = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 2
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        end
        
        if switch3d
            obj.mibModel.mibDoBackup(type, 1, backupOptions);
            permuteSwitch = NaN;    % get dataset in the shown orientation
            maskDataset = cell2mat(obj.mibModel.getData3D(type, NaN, permuteSwitch, colchannel, options));
            selarea = zeros(size(maskDataset),'uint8');
            for layer_id = 1:size(selarea, 3)
                selarea(:,:,layer_id) = bitand(selected_mask,  maskDataset(:,:,layer_id));
            end
        else
            obj.mibModel.mibDoBackup('selection', 0);
            selarea = bitand(selected_mask, currMask);
        end;
    case 4 % selection with ellipse tool
        obj.mibView.gui.Pointer = 'cross';
        obj.mibView.gui.WindowButtonDownFcn = [];
        
        h = imellipse(obj.mibView.handles.mibImageAxes);
        selected_mask = uint8(h.createMask);
        delete(h);
        
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        obj.mibView.gui.Pointer = 'crosshair';
        
        options.blockModeSwitch = 1;
        currMask = cell2mat(obj.mibModel.getData2D(type, NaN, NaN, colchannel, options));
        selected_mask = imresize(selected_mask, [size(currMask,1) size(currMask,2)], 'method', 'nearest');
        
        CC = regionprops(selected_mask,'BoundingBox');
        bb = CC.BoundingBox;
        bb(1) = bb(1) + max([1 ceil(axesX(1))])-1;
        bb(2) = bb(2) + max([1 ceil(axesY(1))])-1;
        
        if orientation == 4
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 1
            backupOptions.x = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 2
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        end
        
        if switch3d
            obj.mibModel.mibDoBackup(type, 1, backupOptions);
            permuteSwitch = NaN;
            maskDataset = cell2mat(obj.mibModel.getData3D(type, NaN, permuteSwitch, colchannel, options));
            selarea = zeros(size(maskDataset),'uint8');
            for layer_id = 1:size(selarea, 3)
                selarea(:,:,layer_id) = bitand(selected_mask, maskDataset(:,:,layer_id));
            end
        else
            obj.mibModel.mibDoBackup('selection', 0);
            selarea = bitand(selected_mask, currMask);
        end;
    case 5 % selection with polyline tool
        obj.mibView.gui.Pointer = 'cross';
        obj.mibView.gui.WindowButtonDownFcn = [];
        
        h =  impoly(obj.mibView.handles.mibImageAxes);
        selected_mask = uint8(h.createMask);
        delete(h);
        
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        obj.mibView.gui.Pointer = 'crosshair';
        
        options.blockModeSwitch = 1;
        currMask = cell2mat(obj.mibModel.getData2D(type, NaN, NaN, colchannel, options));
        selected_mask = imresize(selected_mask, [size(currMask,1) size(currMask,2)], 'method', 'nearest');
        
        CC = regionprops(selected_mask,'BoundingBox');
        bb = CC.BoundingBox;
        bb(1) = bb(1) + max([1 ceil(axesX(1))])-1;
        bb(2) = bb(2) + max([1 ceil(axesY(1))])-1;
        
        if orientation == 4
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.x = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 1
            backupOptions.x = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        elseif orientation == 2
            backupOptions.y = [ceil(bb(2)) ceil(bb(2))+floor(bb(4))-1];
            backupOptions.z = [ceil(bb(1)) ceil(bb(1))+floor(bb(3))-1];
        end
        
        if switch3d
            obj.mibModel.mibDoBackup(type, 1, backupOptions);
            permuteSwitch = NaN;
            maskDataset = cell2mat(obj.mibModel.getData3D(type, NaN, permuteSwitch, colchannel, options));
            selarea = zeros(size(maskDataset),'uint8');
            for layer_id = 1:size(selarea, 3)
                selarea(:,:,layer_id) = bitand(selected_mask, maskDataset(:,:,layer_id));
            end
        else
            obj.mibModel.mibDoBackup('selection', 0);
            selarea = bitand(selected_mask, currMask);
        end;
    case 6 % Select mask within current Selection layer
        if switch3d==1 | strcmp(modifier, 'shift')==1  %#ok<OR2>
            obj.mibModel.mibDoBackup('selection', 1);
            modifier = 'new';
            permuteSwitch = 4;
            mask = cell2mat(obj.mibModel.getData3D(type, NaN, permuteSwitch, colchannel, options));
            sel = cell2mat(obj.mibModel.getData3D('selection', NaN, permuteSwitch, colchannel, options));
            selarea = bitand(mask,  sel);
        else
            obj.mibModel.mibDoBackup('selection', 0);
            currMask = cell2mat(obj.mibModel.getData2D(type, NaN, NaN, colchannel));
            currSelection = cell2mat(obj.mibModel.getData2D('selection'));
            selarea = bitand(currMask,  currSelection);
            modifier = 'new';
        end
end

selcontour = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;  % get selected contour
if switch3d
    % limit to the selected material of the model
    if obj.mibView.handles.mibSegmSelectedOnlyCheck.Value && strcmp(type, 'mask')
        datasetImage = cell2mat(obj.mibModel.getData3D('model', NaN, permuteSwitch, selcontour, options));
        selarea(datasetImage~=1) = 0;
    end
    
    % limit selection to the masked area
    if obj.mibView.handles.mibMaskedAreaCheck.Value && obj.mibModel.getImageProperty('maskExist') && strcmp(type, 'model')
        datasetImage = cell2mat(obj.mibModel.getData3D('mask', NaN, permuteSwitch, NaN, options));
        selarea(datasetImage~=1) = 0;
    end
    
    if isempty(modifier)
        currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, permuteSwitch, NaN, options));
        obj.mibModel.setData3D('selection', bitor(currSelection, selarea), NaN, permuteSwitch, NaN, options);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, permuteSwitch, NaN, options));
        currSelection(selarea==1) = 0;
        obj.mibModel.setData3D('selection', currSelection, NaN, permuteSwitch, NaN, options);
    elseif strcmp(modifier, 'new')  % tweak for case 7 % Select mask within current Selection layer
        obj.mibModel.setData3D('selection', selarea, NaN, permuteSwitch, NaN, options);
    end
else
    % limit to the selected material of the model
    if obj.mibView.handles.mibSegmSelectedOnlyCheck.Value && strcmp(type, 'mask')
        currModel = cell2mat(obj.mibModel.getData2D('model', NaN, NaN, selcontour));
        selarea = bitand(selarea, currModel);
    end
    
    % limit selection to the masked area
    if obj.mibView.handles.mibMaskedAreaCheck.Value && obj.mibModel.getImageProperty('maskExist') && strcmp(type, 'model')
        currModel = cell2mat(obj.mibModel.getData2D('mask'));
        selarea = bitand(selarea, currModel);
    end
    
    
    if isempty(modifier) % combines selections
        currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        obj.mibModel.setData2D('selection', bitor(currSelection, selarea), NaN, NaN, NaN, options);
    elseif strcmp(modifier, 'control')  % subtracts selections
        currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        currSelection(selarea==1) = 0;
        obj.mibModel.setData2D('selection', currSelection, NaN, NaN, NaN, options);
    elseif strcmp(modifier, 'new')  % tweak for case 7 % Select mask within current Selection layer
        obj.mibModel.setData2D('selection', selarea, NaN, NaN, NaN, options);
    end
end


obj.plotImage();

end
