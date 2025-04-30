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
% Date: 19.03.2025

function status = materialsInsert(obj, materialIndex, materialName, options)
% function status = materialsInsert(obj, materialIndex, materialName, options)
% Insert material with materialName into position materialIndex
%
% Parameters:
% materialIndex: [numeric] index of the new material of the model
% materialName: [string] name of the new material of the model
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.materialsInsert(5, 'material5');     // call from mibController; insert 'material5' into position 5
% @endcode

% Updates
% 

status = false;
if nargin < 4; options = struct; end
if nargin < 3; materialName = []; end
if nargin < 2; materialIndex = []; end
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

maxVal = 0;
if isempty(materialIndex) || isnan(materialIndex)
    if obj.modelType < 256
        materialIndex = numel(obj.modelMaterialNames) + 1;
    else
        % find next empty index
        for t=1:obj.time
            options.t = t;
            M = obj.getData('model', 4, NaN, options);
            maxVal = max([maxVal max(max(max(M)))]);
        end
        materialIndex = maxVal + 1;
    end
end

if materialIndex > obj.modelType
    warndlg(sprintf('!!! Warning !!!\n\nThe current type of the model can only have %d materials!\n\nPlease convert it to another suitable type and try again:\nMenu->Models->Type', obj.modelType), ...
        'Max number of materials exceeded', 'modal');
    return;
end

if isempty(materialName) && obj.modelType < 256
    materialName = sprintf('mat%.3d', materialIndex);
end

if options.showWaitbar
    if obj.modelType > 256
        wb = waitbar(0, sprintf('Inserting material %d\nPlease wait...', materialIndex), ...
            'Name', 'Insert material', ...
            'WindowStyle', 'modal'); 
    else
        wb = waitbar(0, sprintf('Inserting "%s" into position %d\nPlease wait...', materialName, materialIndex), ...
            'Name', 'Insert material', ...
            'WindowStyle', 'modal'); 
    end
end

tic

maxTime = obj.time;
if obj.modelType > 256
    for t=1:maxTime
        options.t = t;
        M = obj.getData('model', 4, NaN, options);
        % shift materials
        mask = (M >= materialIndex);
        M(mask) = M(mask) + 1;
        obj.setData('model', M, 4, NaN, options);

        if options.showWaitbar; waitbar(t/maxTime , wb); end
    end
else
    if materialIndex == numel(obj.modelMaterialNames) + 1
        % no shift needed only add new material name to the list of
        % materials
        obj.modelMaterialNames{end+1,1} = materialName;
    else
        for t=1:maxTime
            options.t = t;
            M = obj.getData('model', 4, NaN, options);
            % shift materials
            mask = (M >= materialIndex);
            M(mask) = M(mask) + 1;
            obj.setData('model', M, 4, NaN, options);

            if options.showWaitbar; waitbar(t/maxTime , wb); end
        end
        
        % shift material names 
        if materialIndex == 1
            obj.modelMaterialNames = [{materialName}; obj.modelMaterialNames];
        else
            newMaterialNames = obj.modelMaterialNames(1:materialIndex-1);
            obj.modelMaterialNames = [newMaterialNames; {materialName}; obj.modelMaterialNames(materialIndex:end)];
        end
    end
    % add new color if needed
    if size(obj.modelMaterialColors, 1) < numel(obj.modelMaterialNames)
        obj.modelMaterialColors(end+1, :) = rand([1,3]);
    end
end
toc

if options.showWaitbar; waitbar(1, wb); delete(wb); end
status = true;
end