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
% Date: 22.03.2025

function status = materialsRename(obj, materialName, materialIndex, options)
% function status = materialsRename(obj, materialName, materialIndex, options)
% Rename material with index materialIndex using a new materialName
%
% Parameters:
% materialName: [string] new name for materialIndex, when empty generate default name
% materialIndex: [numeric] index of the selected material of the model, when NaN or empty use the currently selected material
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.materialsRename('material03', 3);     // call from mibController; rename material 3 using new name: material03
% @endcode

% Updates
% 

status = false;
if nargin < 4; options = struct; end
if nargin < 3; materialIndex = []; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

% checks
% do nothing is selection is disabled
if obj.enableSelection == 0
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Enable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "yes" and try again...'),'The models are disabled');
    notify(obj.mibModel, 'stopProtocol');
    return;
end

if ~obj.modelExist 
    warndlg(sprintf('Create or load the model first!'), 'No model');
    return;
end

% get index of the currently selected material
if isempty(materialIndex) || isnan(materialIndex)
    materialIndex = obj.selectedAddToMaterial - 2;
end

% update material name
if isempty(materialName) && obj.modelType < 256
    materialName = sprintf('mat%.3d', materialIndex);
end

newMatNames = strsplit(materialName, ',');
newMatNames = strtrim(newMatNames);
newMatNames = newMatNames';

if obj.modelType > 255
    materialId = round(str2double(newMatNames));
    if sum(isnan(materialId)) > 0
        errordlg(sprintf('!!! Error !!!\n\nWrong material index\nPlease enter a numeric value!'), 'Wrong material index', 'modal'); 
        return; 
    end
end

if materialIndex == 0  % rename all material names
    if numel(newMatNames) ~= numel(obj.modelMaterialNames)
        errordlg(sprintf('!!! Error !!!\n\nNumber of new material names should match number of materials (%d) in the table!', numel(obj.modelMaterialNames)), ...
            'Rename material', 'non-modal');
        return;
    end
    obj.modelMaterialNames = newMatNames;
else
    if obj.modelType > 255
        obj.modelMaterialNames(obj.selectedAddToMaterial-2) = newMatNames;
    else
        obj.modelMaterialNames(materialIndex) = newMatNames;
    end
end

status = true;
end