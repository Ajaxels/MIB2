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

function mibRescaleWidgets(hGui)
% function mibRescaleWidgets(hGui)
% rescale widgets for different operating systems
%
% Parameters:
% hGui: handle to a window to be rescaled
%
% Return values:

%| 
% @b Examples:
% @code mibRescaleWidgets(handles.mibGUI);     // rescales widgets of mibGUI @endcode

% Updates
% 28.10.2016, IB adaptation for HG2

global scalingGUI;
if isempty(scalingGUI); return; end 

% do not scale when scaling == 1
if scalingGUI.scaling == 1; return; end

scaleFactor = scalingGUI.scaling;
scaleWidgets = rmfield(scalingGUI, {'scaling', 'systemscaling'});

% list of affected widgets
%list = {'uipanel','uibuttongroup','uitab','uitabgroup','axes','uitable','uicontrol'};
list = fieldnames(scaleWidgets);
hGui.Visible = 'off';

for j=1:numel(list)
    if scaleWidgets.(list{j}) == 1
        h = findall(hGui, 'type', list{j});
        for i=1:numel(h)
            try
                units = h(i).Units;
                if ~strcmp(units, 'normalized') && ~strcmp(h(i).Parent.Units, 'normalized')
                    h(i).Position = h(i).Position*scaleFactor;
                end
            catch err
                disp(err)
            end
        end
    end
end
% finally update the main window
hGui.Position(3) = hGui.Position(3)*scaleFactor;
hGui.Position(4) = hGui.Position(4)*scaleFactor;
hGui.Visible = 'on';
end