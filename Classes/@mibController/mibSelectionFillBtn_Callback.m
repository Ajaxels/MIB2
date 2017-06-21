function mibSelectionFillBtn_Callback(obj, sel_switch)
% function mibSelectionFillBtn_Callback(obj, sel_switch)
% a callback to the mibGUI.handles.mibSelectionFillBtn, allows to fill holes for the Selection layer
%
% Parameters:
% sel_switch: a string that defines where filling of holes should be done:
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
if obj.mibModel.preferences.disableSelection == 1; return; end

tic;
selContour = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;
selectedOnly = obj.mibView.handles.mibSegmSelectedOnlyCheck.Value;
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

if strcmp(sel_switch,'2D')
    obj.mibModel.mibDoBackup('selection', 0);
    filled_img = imfill(cell2mat(obj.mibModel.getData2D('selection')),'holes');
    if selectedOnly
        filled_img = filled_img & cell2mat(obj.mibModel.getData2D('model', NaN, NaN, selContour));
    end
    obj.mibModel.setData2D('selection', {filled_img});
else 
    if strcmp(sel_switch,'3D') 
        obj.mibModel.mibDoBackup('selection', 1);
        t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
        t2 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(2);
        wb = waitbar(0,'Filling holes in 2D for a whole Z-stack...','WindowStyle','modal');
    else
        t1 = 1;
        t2 = obj.mibModel.I{obj.mibModel.Id}.time;
        wb = waitbar(0,'Filling holes in 2D for a whole dataset...','WindowStyle','modal');
    end
    max_size = size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
    max_size2 = max_size*(t2-t1+1);
    index = 1;
    
    for t=t1:t2
        options.t = [t, t];
        for layer_id=1:max_size
            if mod(index, 10)==0; waitbar(layer_id/max_size2, wb); end
            slice = cell2mat(obj.mibModel.getData2D('selection', layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, 0, options));
            if max(max(slice)) < 1; continue; end
            slice = imfill(slice,'holes');
            if selectedOnly
                slice = slice & cell2mat(obj.mibModel.getData2D('model', layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, selContour, options));
            end
            obj.mibModel.setData2D('selection', {slice}, layer_id, obj.mibModel.I{obj.mibModel.Id}.orientation, 0, options);
            index = index + 1;
        end
    end
    delete(wb);
    toc
end
obj.plotImage(0);
end