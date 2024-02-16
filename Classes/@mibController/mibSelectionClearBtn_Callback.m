% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function mibSelectionClearBtn_Callback(obj)
% function mibSelectionClearBtn_Callback(obj)
% a callback to the mibGUI.handles.mibSelectionClearBtn, allows to clear the Selection layer
%
% Parameters:

% Updates
% 25.09.2019 updated for batch mode and moved to mibModel.clearSelection

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.enableSelection == 0; return; end

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