% --- Executes on button press in selectionClearBtn.
function mibSelectionClearBtn_Callback(obj, sel_switch)
% function mibSelectionClearBtn_Callback(obj, sel_switch)
% a callback to the mibGUI.handles.mibSelectionClearBtn, allows to clear the Selection layer
%
% Parameters:
% sel_switch: a string to define where selection should be cleared:
% @li when @b '2D' clear selection from the currently shown slice
% @li when @b '3D' clear selection from the currently shown z-stack
% @li when @b '4D' clear selection from the whole dataset

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates

% do nothing is selection is disabled
if obj.mibModel.preferences.disableSelection == 1; return; end;

if nargin < 2
    modifier = obj.mibView.gui.CurrentModifier;
    if sum(ismember({'alt','shift'}, modifier)) == 2
        if handles.Img{handles.Id}.I.time == 1
            sel_switch = '3D';
        else
            sel_switch = '4D';
        end
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

getDataOptions.blockModeSwitch = obj.mibModel.getImageProperty('blockModeSwitch');
[h, w, ~, d, ~] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, 0, getDataOptions);

if strcmp(sel_switch,'2D')
    obj.mibModel.mibDoBackup('selection', 0);
    img = zeros([h, w], 'uint8');
    obj.mibModel.setData2D('selection', {img});
else 
    if strcmp(sel_switch,'3D') 
        obj.mibModel.mibDoBackup('selection', 1);
        t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
        t2 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(2);
        wb = waitbar(0,'Clearing the Selection layer for a whole Z-stack...','WindowStyle','modal');
    else
        t1 = 1;
        t2 = obj.mibModel.I{obj.mibModel.Id}.time;
        wb = waitbar(0,'Clearing the Selection layer for a whole dataset...','WindowStyle','modal');
    end
    
    img = zeros([h, w, d], 'uint8');
    for t=t1:t2
        obj.mibModel.setData3D('selection', {img}, t, obj.mibModel.I{obj.mibModel.Id}.orientation);
    end
    delete(wb);
end
obj.plotImage(0);
end