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
% Date: 24.03.2025

function status = materialsSwapColors(obj, material1, material2)
% function status = materialsSwapColors(obj, material1, material2)
% Swap colors for material1 and material2 in the model
%
% Parameters:
% material1: [numeric] index of the first material of the model
% material2: [numeric] index of the second material of the model
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.materialsSwapColors(1,2);     // call from mibController; swap colors of material 1 and material 2
% @endcode

% Updates
% 

status = false;
if nargin < 3
    warndlg(sprintf('materialsSwap: numbers of two materials whose colors should be swapped are required'), 'Missing material indices');
    return; 
end

% checks
% do nothing is selection is disabled
if obj.enableSelection == 0
    errordlg(sprintf('The models are switched off!\n\nPlease make sure that the "Enable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "yes" and try again...'),'The models are disabled');
    notify(obj.mibModel, 'stopProtocol');
    return;
end
if ~obj.modelExist 
    errordlg(sprintf('Create or load the model first!'), 'No model');
    return;
end
if obj.modelType > 256
    errordlg(sprintf('Swapping of material colors in the model is only available for models with up to 255 materials!'), 'Wrong model type');
    return;
end

% nothing is needed
if material1 == material2; status = true; return; end

% swap material names and material colors
if obj.modelType < 256
    newOrder = 1:numel(obj.modelMaterialNames);
    newOrder(material1) = material2;
    newOrder(material2) = material1;
    obj.modelMaterialColors = obj.modelMaterialColors(newOrder, :); % reorder color maps
end

status = true;
end