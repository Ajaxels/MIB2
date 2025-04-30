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
% Date: 13.03.2025

function status = materialsRemove(obj, materialIndex, options)
% function status = materialsRemove(obj, materialIndex, options)
% Remove material from the model
%
% Parameters:
% materialIndex: [numeric] index or indices of materials to be removed from the model, when empty or NaN use the currently selected material
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.materialsRemove('3');     // call from mibController; delete material 3 from the model, obj.model
% @endcode

% Updates
% 

global mibPath; % path to mib installation folder

status = false;
if nargin < 3; options = struct; end
if nargin < 2; materialIndex = []; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

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

materialIndex = sort(materialIndex);
if materialIndex < 1
    errordlg(sprintf('Index of the material to be removed should be above 0!'), 'Wrong index');
    return;
end

if options.showWaitbar
    wb = waitbar(0,sprintf('Removing material: %s from the model\nPlease wait...', num2str(materialIndex)), ...
        'Name','Delete color channels', ...
        'WindowStyle','modal'); 
end

keepMaterials = 1:numel(obj.modelMaterialNames);
keepMaterials(ismember(keepMaterials, materialIndex)) = [];
if options.showWaitbar; waitbar(.01, wb); end

tic
maxTime = obj.time;
for t=1:maxTime
    options.t = t;
    model2 = obj.getData('model', 4, NaN, options);
    if obj.modelType < 256
        [logicalMember, indexValue] = ismember(model2, keepMaterials);
        model = zeros(size(model2), class(model2));
        model(logicalMember==1) = indexValue(logicalMember==1);
        obj.setData('model', model, 4, NaN, options);
    else
        model2(ismember(model2, materialIndex)) = 0;
        obj.setData('model', model2, 4, NaN, options);
    end
    if options.showWaitbar; waitbar(t/maxTime , wb); end
end
clear model2;

if obj.modelType < 256
    obj.modelMaterialColors(materialIndex,:) = [];  % remove color of the removed material
    obj.modelMaterialNames(materialIndex) = [];  % remove material name from the list of materials
    obj.lastSegmSelection = [2 1];
end
toc

if options.showWaitbar; waitbar(1, wb); delete(wb); end
status = true;
end