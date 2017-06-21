function mibSelectionDilateBtn_Callback(obj, sel_switch)
% function mibSelectionDilateBtn_Callback(obj, sel_switch)
% a callback to the mibGUI.handles.mibSelectionDilateBtn, expands the selection layer
%
% Parameters:
% sel_switch: a string that defines where dilation should be done:
% @li when @b '2D' dilate for the currently shown slice
% @li when @b '3D' dilate for the currently shown z-stack
% @li when @b '4D' dilate for the whole dataset

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

% do nothing is selection is disabled
if obj.mibModel.preferences.disableSelection == 1; return; end;

if nargin < 2
    modifier = obj.mibView.gui.CurrentModifier;
    if sum(ismember({'alt','shift'}, modifier)) == 2
        sel_switch = '4D';
    elseif sum(ismember({'alt','shift'}, modifier)) == 1
        sel_switch = '3D';
    else
        sel_switch = '2D';
    end
end

% tweak when only one time point
if strcmp(sel_switch, '4D') && obj.mibModel.I{obj.mibModel.Id}.time == 1
    sel_switch = '3D';
end

switch3d = obj.mibView.handles.mibActions3dCheck.Value;
if switch3d == 1
    button = questdlg(sprintf('You are going to dilate the image in 3D!\nContinue?'),'Dilate 3D objects','Continue','Cancel','Continue');
    if strcmp(button, 'Cancel'); return; end;
end

if (switch3d && ~strcmp(sel_switch, '4D') ) || strcmp(sel_switch, '3D')
    obj.mibModel.mibDoBackup('selection', 1);
else
    obj.mibModel.mibDoBackup('selection', 0);
end
diff_switch = obj.mibView.handles.mibSelectionDifferenceCheck.Value;   % if 1 will make selection as a difference

% define the time points
if strcmp(sel_switch, '4D')
    t1 = 1;
    t2 = obj.mibModel.I{obj.mibModel.Id}.time;
else    % 2D, 3D
    t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
    t2 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(2);
end

adapt_coef = str2double(obj.mibView.handles.mibDilateAdaptCoefEdit.String);
sel_col_ch = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
if sel_col_ch == 0 && obj.mibView.handles.mibAdaptiveDilateCheck.Value == 1
    msgbox('Please select the color channel!','Error!','error','modal');
    return;
end
selected = NaN;
if obj.mibView.handles.mibSegmSelectedOnlyCheck.Value  % area for dilation is taken only from selected contour
    selected = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;
end;

width = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 2);
height = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, 1);
extraSmoothing = obj.mibView.handles.mibAdaptiveSmoothCheck.Value;

se_size_txt = obj.mibView.handles.mibStrelSizeEdit.String;
semicolon = strfind(se_size_txt,';');
if ~isempty(semicolon)  % when 2 values are provided take them
    se_size(1) = str2double(se_size_txt(1:semicolon(1)-1));     % for x and y
    se_size(2) = str2double(se_size_txt(semicolon(1)+1:end));   % for z
else                    % when only 1 value - calculate the second from the pixSize
    if switch3d
        se_size(1) = str2double(se_size_txt); % for y and x
        se_size(2) = round(se_size(1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.z); % for z
    else
        se_size(1) = str2double(se_size_txt); % for y
        se_size(2) = se_size(1);    % for x
    end
end

if se_size(1) == 0 || se_size(2) == 0
    msgbox('Strel size should be larger than 0','Wrong strel size','error','modal');
    return;
end

if switch3d         % do in 3d
    wb = waitbar(0,sprintf('Dilating selection...\nStrel width: XY=%d x Z=%d',se_size(1)*2+1,se_size(2)*2+1),'Name','Dilating...','WindowStyle','modal');
    se = zeros(se_size(1)*2+1,se_size(1)*2+1,se_size(2)*2+1);    % do strel ball type in volume
    [x,y,z] = meshgrid(-se_size(1):se_size(1),-se_size(1):se_size(1),-se_size(2):se_size(2));
    %ball = sqrt(x.^2+y.^2+(se_size(2)/se_size(1)*z).^2);
    %se(ball<sqrt(se_size(1)^2+se_size(2)^2)) = 1;
    ball = sqrt((x/se_size(1)).^2+(y/se_size(1)).^2+(z/se_size(2)).^2);
    se(ball<=1) = 1;
    
    index = 1;
    tMax = t2-t1+1;
    for t=t1:t2
        waitbar(index/tMax, wb);
        selection = obj.mibModel.getData3D('selection', t, 4);
        if isnan(selected)  % dilate to all pixels around selection
            selection = imdilate(selection{1}, se);
        else                % dilate using pixels only from the selected countour
            model = obj.mibModel.getData3D('model', t, 4, selected);
            selection = bitand(imdilate(selection{1},se), model{1});
        end
        if obj.mibView.handles.mibAdaptiveDilateCheck.Value
            img = cell2mat(obj.mibModel.getData3D('image', t, 4, sel_col_ch));
            existingSelection = cell2mat(obj.mibModel.getData3D('selection', t, 4));
            mean_val = mean2(img(existingSelection==1));
            std_val = std2(img(existingSelection==1))*adapt_coef;
            diff_mask = imabsdiff(selection, existingSelection); % get difference to see only added mask
            updated_mask = zeros(size(selection), 'uint8');
            img(~diff_mask) = 0;
            low_limit = mean_val-std_val;%-thres_down;
            high_limit = mean_val+std_val;%+thres_up;
            if low_limit < 1; low_limit = 1; end;
            if high_limit > 255; high_limit = 255; end;
            updated_mask(img>=low_limit & img<=high_limit) = 1;
            selection = existingSelection;
            selection(updated_mask==1) = 1;
            CC = bwconncomp(selection,18);  % keep it connected to the largest block
            [~, idx] = max(cellfun(@numel,CC.PixelIdxList));
            selection = zeros(size(selection),'uint8');
            selection(CC.PixelIdxList{idx}) = 1;
        end
        if diff_switch
            selection = imabsdiff(uint8(selection), cell2mat(obj.mibModel.getData3D('selection', t, 4)));
        end
        obj.mibModel.setData3D('selection', {selection}, t, 4);
    end
else                % do in 2d
    %se = strel('rectangle',[se_size(1)*2+1 se_size(2)*2+1]);
    %se = strel('rectangle',[se_size(1) se_size(2)]);
    
    se = zeros([se_size(1)*2+1 se_size(2)*2+1],'uint8');
    se(se_size(1)+1,se_size(2)+1) = 1;
    se = bwdist(se);
    se = uint8(se <= se_size(1));
    
    connect8 = obj.mibView.handles.mibMagicwandConnectCheck.Value;
    if strcmp(sel_switch,'2D')
        start_no = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
        end_no = start_no;
    else
        wb = waitbar(0,sprintf('Dilating selection...\nStrel size: %dx%d px', se_size(1),se_size(2)),'Name','Dilating...','WindowStyle','modal');
        start_no=1;
        end_no=size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
    end
    
    max_size2 = (end_no-start_no+1)*(t2-t1+1);
    index = 1;
    
    for t=t1:t2
        options.t = [t, t];
        for layer_id=start_no:end_no
            if t1 ~= t2 && mod(layer_id, 10)==0; waitbar(index/max_size2, wb); end;
            selection = cell2mat(obj.mibModel.getData2D('selection', layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, 0, options));
            if max(max(selection)) < 1; continue; end;
            if ~isnan(selected)
                model = cell2mat(obj.mibModel.getData2D('model', layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, selected, options));
            end

            if obj.mibView.handles.mibAdaptiveDilateCheck.Value
                img = cell2mat(obj.mibModel.getData2D('image', layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, sel_col_ch, options));
                remember_selection = selection;
                STATS = regionprops(logical(remember_selection), 'BoundingBox','PixelList');    % get all original objects before dilation
                sel = zeros(size(selection),'uint8');
                
                for object=1:numel(STATS)   % cycle through the objects
                    bb =  floor(STATS(object).BoundingBox);
                    coordXY =  STATS(object).PixelList(1,:);    % coordinate of a pixel that belongs to selected object
                    coordXY(1) = coordXY(1)-max([1 bb(1)-ceil(se_size(2)/2)])+1;
                    coordXY(2) = coordXY(2)-max([1 bb(2)-ceil(se_size(1)/2)])+1;
                    
                    cropImg = img(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])); % crop image
                    cropRemembered = remember_selection(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])); % crop selection to an area around the object
                    if connect8
                        cropRemembered = bwselect(cropRemembered, coordXY(1),coordXY(2), 8);   % pickup only the object
                    else
                        cropRemembered = bwselect(cropRemembered, coordXY(1),coordXY(2), 4);   % pickup only the object
                    end
                    
                    if isnan(selected) % dilate to all pixels around selection
                        cropSelection = imdilate(cropRemembered,se);
                    else                % dilate using pixels only from the selected countour
                        cropModel = model(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])); % crop model
                        cropSelection = imdilate(cropRemembered,se) & (cropModel==1 | cropRemembered);
                    end
                    
                    mean_val = mean2(cropImg(cropRemembered==1));
                    std_val = std2(cropImg(cropRemembered==1))*adapt_coef;
                    diff_mask = cropSelection - cropRemembered; % get difference to see only added mask
                    cropImg(~diff_mask) = 0;
                    low_limit = mean_val-std_val;
                    high_limit = mean_val+std_val;
                    if low_limit < 1; low_limit = 1; end;
                    if high_limit > 255; high_limit = 255; end;
                    newCropSelection = zeros(size(cropRemembered),'uint8');
                    newCropSelection(cropImg>=low_limit & cropImg<=high_limit) = 1;
                    newCropSelection(cropRemembered==1) = 1;    % combine original and new selection
                    
                    if extraSmoothing
                        se2 = strel('rectangle',[handles.adaptiveSmoothingFactor handles.adaptiveSmoothingFactor]);
                        newCropSelection = imdilate(imerode(newCropSelection,se2),se2);
                        newCropSelection(cropImg<low_limit & cropImg>high_limit) = 0;
                        newCropSelection(cropRemembered==1) = 1;    % combine original and new selection
                    end
                    if connect8
                        newCropSelection = bwselect(newCropSelection,coordXY(1),coordXY(2),8);   % get only a one connected object, removing unconnected components
                    else
                        newCropSelection = bwselect(newCropSelection,coordXY(1),coordXY(2),4);   % get only a one connected object, removing unconnected components
                    end
                    sel(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)])) = ...
                        newCropSelection | sel(max([1 bb(2)-ceil(se_size(1)/2)]):min([height bb(2)+bb(4)+ceil(se_size(1)/2)]), max([1 bb(1)-ceil(se_size(2)/2)]):min([width bb(1)+bb(3)+ceil(se_size(2)/2)]));
                end
                if diff_switch
                    sel = sel - remember_selection;
                end
            else
                if diff_switch  % result of dilation is only expantion of the area
                    if isnan(selected)  % dilate to all pixels around selection
                        sel = imdilate(selection,se)-selection;
                    else                % dilate using pixels only from the selected countour
                        sel = imdilate(selection,se) & model==selected;
                    end
                else            % result of dilation is object's area + expantion of that area
                    if isnan(selected)  % dilate to all pixels around selection
                        sel = imdilate(selection,se);
                    else                % dilate using pixels only from the selected countour
                        sel = imdilate(selection,se) & bitor(model, selection);
                    end
                end
            end
            obj.mibModel.setData2D('selection', {sel}, layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, 0, options);
        end
    end
end
if exist('wb','var'); delete(wb); end;

obj.plotImage(0);
end