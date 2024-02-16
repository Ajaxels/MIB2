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

function mibChannelMixerTable_CellSelectionCallback(obj, Indices)
% function mibChannelMixerTable_CellSelectionCallback(obj, Indices)
% a callback selection of a cell in obj.mibView.handles.mibChannelMixerTable
%
% Parameters:
% Indices: row and column indices of the cell(s) edited
% 

% Updates
% 

if isempty(Indices); return; end
obj.mibView.handles.mibChannelMixerTable.UserData = Indices;   % store selected position

if Indices(1, 2) == 3 % start color selection dialog
    if obj.mibView.handles.mibLutCheckbox.Value == 0
        warndlg(sprintf('The colors for the color channels may be selected only in the LUT mode!\n\nTo enable the LUT mode please select the LUT checkbox\n(View Settings Panel->LUT checkbox)'),'Warning!');
        return;
    end
    figTitle = ['Set color for channel ' num2str(Indices(1))];
    lutColors = obj.mibModel.getImageProperty('lutColors');
    c = uisetcolor(lutColors(Indices(1),:), figTitle);
    if length(c) == 1; return; end
    lutColors(Indices(1),:) = c;
    obj.mibModel.setImageProperty('lutColors', lutColors);
    obj.updateGuiWidgets();
    
    % redraw image in the im_browser axes
    obj.plotImage(0);
end

end