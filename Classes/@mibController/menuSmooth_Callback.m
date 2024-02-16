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

function menuSmooth_Callback(obj, type)
% function menuSmooth_Callback(obj, type)
% callback to the smooth mask, selection or model layer
%
% Parameters:
% type: a string with type of the layer for the smoothing
% - ''selection'' - run size exclusion on the Selection layer
% - ''model'' - - run size exclusion on the Model layer
% - ''mask'' - - run size exclusion on the Mask layer

% Updates
% 

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.enableSelection == 0
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Enable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "yes" and try again...'),...
        'The selection layer is disabled', 'modal');
    return; 
end

% Smooth Mask, Selection or Model layers
obj.mibModel.smoothImage(type);
obj.plotImage();

end