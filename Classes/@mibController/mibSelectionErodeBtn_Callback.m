function mibSelectionErodeBtn_Callback(obj, sel_switch)
% function mibSelectionErodeBtn_Callback(obj, sel_switch)
% a callback to the mibGUI.handles.mibSelectionErodeBtn, shrinks the selection layer
%
% Parameters:
% sel_switch: [@em optional] a string that defines where erosion should be done:
% @li when @b '2D' fill holes for the currently shown slice
% @li when @b '3D' fill holes for the currently shown z-stack
% @li when @b '4D' fill holes for the whole dataset

% Copyright (C) 19.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
    button = questdlg(sprintf('You are going to erode the image in 3D!\nContinue?'),'Erode 3D objects','Continue','Cancel','Continue');
    if strcmp(button, 'Cancel'); return; end
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

se_size_txt = obj.mibView.handles.mibStrelSizeEdit.String;
semicolon = strfind(se_size_txt,';');
if ~isempty(semicolon)  % when 2 values are provided take them
    se_size(1) = str2double(se_size_txt(1:semicolon(1)-1));     % for y and x
    se_size(2) = str2double(se_size_txt(semicolon(1)+1:end));   % for z (or x in 2d mode)
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

if switch3d         % do in 3D
    wb = waitbar(0,sprintf('Eroding selection...\nStrel size: XY=%d x Z=%d',se_size(1)*2+1,se_size(2)*2+1),'Name','Eroding...','WindowStyle','modal');
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
        selection{1} = imerode(selection{1}, se);
        if diff_switch
            selection{1} = imabsdiff(selection{1}, cell2mat(obj.mibModel.getData3D('selection', t, 4)));
        end
        obj.mibModel.setData3D('selection',selection, t, 4);
        index = index + 1;
    end
    delete(wb);
else    % do in 2d layer by layer
    %se = strel('disk',[se_size(1) se_size(2)],0);
    %se = strel('rectangle',[se_size(1) se_size(2)]);
    
    se = zeros([se_size(1)*2+1 se_size(2)*2+1],'uint8');
    se(se_size(1)+1,se_size(2)+1) = 1;
    se = bwdist(se); 
    se = uint8(se <= se_size(1));

    if strcmp(sel_switch,'2D')
        eroded_img = imerode(cell2mat(obj.mibModel.getData2D('selection')), se);
        if diff_switch   % if 1 will make selection as a difference
            eroded_img = cell2mat(obj.mibModel.getData2D('selection')) - eroded_img;
        end
        obj.mibModel.setData2D('selection', {eroded_img});
    else
        wb = waitbar(0,sprintf('Eroding selection...\nStrel size: %dx%d px', se_size(1),se_size(2)),'Name','Eroding...','WindowStyle','modal');
        max_size = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
        max_size2 = max_size*(t2-t1+1);
        index = 1;
        
        for t=t1:t2
            options.t = [t, t];
            for layer_id=1:max_size
                if mod(layer_id, 10)==0; waitbar(index/max_size2, wb); end
                slice = obj.mibModel.getData2D('selection', layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, 0, options);
                if max(max(slice{1})) < 1; continue; end
                eroded_img{1} = imerode(slice{1}, se);
                if diff_switch   % if 1 will make selection as a difference
                    eroded_img{1} = slice{1} - eroded_img{1};
                end
                obj.mibModel.setData2D('selection', eroded_img, layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, 0, options);
                index = index + 1;
            end
        end
        delete(wb);
    end
end
obj.plotImage(0);
end