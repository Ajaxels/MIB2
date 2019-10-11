function mibSelectionClearBtn_Callback(obj)
% function mibSelectionClearBtn_Callback(obj)
% a callback to the mibGUI.handles.mibSelectionClearBtn, allows to clear the Selection layer
%
% Parameters:

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 25.09.2019 updated for batch mode and moved to mibModel.clearSelection

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end

modifier = obj.mibView.gui.CurrentModifier;
if sum(ismember({'alt', 'shift'}, modifier)) == 2
    if obj.mibModel.I{obj.mibModel.Id}.time == 1
        DatasetType = '3D, Stack';
    else
        DatasetType = '4D, Dataset';
    end
elseif sum(ismember({'alt','shift'}, modifier)) == 1
    DatasetType = '3D, Stack';
else
    DatasetType = '2D, Slice';
end

% tweak when only one time point
if strcmp(DatasetType , '4D, Dataset') && obj.mibModel.I{obj.mibModel.Id}.time == 1
    DatasetType  = '3D, Stack';
end

obj.mibModel.clearSelection(DatasetType);

end