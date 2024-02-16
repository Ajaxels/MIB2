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

function mibSelectionButton_Callback(obj, action)
% function mibSelectionButton_Callback(obj, action)
% a callback to 'A', 'S', 'R' buttons in the Selection panel of obj.mibView.gui
%
% Parameters:
% action: a string that defines type of the action:
% @li when @b 'add' add selection to the active material of the model or to the Mask layer
% @li when @b 'subtract' subtract selection from the active material of the model or from the Mask layer
% @li when @b 'replace' replace the active material of the model or the Mask layer with selection

% Updates
% 

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.enableSelection == 0; return; end

if obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo') == -1    % Selection to Model
    layerTo = 'mask';
else    % Selection to Mask
    layerTo = 'model';
end

modifier = obj.mibView.gui.CurrentModifier;
if sum(ismember({'alt','shift'}, modifier)) == 2
    sel_switch = '4D, Dataset';
elseif sum(ismember({'alt','shift'}, modifier)) == 1
    sel_switch = '3D, Stack';
else
    sel_switch = '2D, Slice';
end

switch action
    case 'add'
        obj.mibModel.moveLayers('selection', layerTo, sel_switch, 'add');
    case 'subtract'
        obj.mibModel.moveLayers('selection', layerTo, sel_switch, 'remove');
    case 'replace'
        obj.mibModel.moveLayers('selection', layerTo, sel_switch, 'replace');
end

end