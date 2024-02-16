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

function mibSelectionFillBtn_Callback(obj)
% function mibSelectionFillBtn_Callback(obj)
% a callback to the mibGUI.handles.mibSelectionFillBtn, allows to fill holes for the Selection layer
%
% Parameters:

% Updates
% 25.09.2019, moved to mibModel.fillSelectionOrMask

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.enableSelection == 0; return; end

if nargin < 2
    modifier = obj.mibView.gui.CurrentModifier;
    if sum(ismember({'alt','shift'}, modifier)) == 2
        sel_switch = '4D, Dataset';
    elseif sum(ismember({'alt','shift'}, modifier)) == 1
        sel_switch = '3D, Stack';
    else
        sel_switch = '2D, Slice';
    end
end
% tweak when only one time point
if strcmp(sel_switch, '4D, Dataset') && obj.mibModel.I{obj.mibModel.Id}.time == 1
    sel_switch = '3D, Stack';
end

obj.mibModel.fillSelectionOrMask(sel_switch, 'selection');
end