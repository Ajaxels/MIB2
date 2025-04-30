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

function status = materialsSwap(obj, material1, material2, options)
% function status = materialsSwap(obj, material1, material2, options)
% Swap material1 and material2 in the model
%
% Parameters:
% material1: [numeric] index of the first material of the model
% material2: [numeric] index of the second material of the model
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.materialsSwap(1,2);     // call from mibController; swap positions of material 1 and material 2
% @endcode

% Updates
% 

status = false;
if nargin < 4; options = struct; end
if nargin < 3
    warndlg(sprintf('materialsSwap: numbers of two materials that should be swapped is required'), 'Missing materials');
    return; 
end
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

% nothing is needed
if material1 == material2; return; end

if options.showWaitbar
    if obj.modelType > 256
        wb = waitbar(0, sprintf('%d <-> %d\nPlease wait...', material1, material2), ...
            'Name', 'Swapping materials', ...
            'WindowStyle', 'modal'); 
    else
        wb = waitbar(0, sprintf('%d(%s) <-> %d(%s)\nPlease wait...', material1, obj.modelMaterialNames{material1}, material2, obj.modelMaterialNames{material2}), ...
            'Name', 'Swapping materials', ...
            'WindowStyle', 'modal'); 
    end
end

tic
maxTime = obj.time;
for t=1:maxTime
    options.t = t;
    M = obj.getData('model', 4, NaN, options);
    M1 = (M == material1);
    M(M==material2) = material1;
    M(M1==1) = material2;
    obj.setData('model', M, 4, NaN, options);

    if options.showWaitbar; waitbar(t/maxTime , wb); end
end
clear M;

% swap material names and material colors
if obj.modelType < 256
    newOrder = 1:numel(obj.modelMaterialNames);
    newOrder(material1) = material2;
    newOrder(material2) = material1;
    obj.modelMaterialColors = obj.modelMaterialColors(newOrder, :); % reorder color maps
    obj.modelMaterialNames = obj.modelMaterialNames(newOrder);  % reorder material names
end
toc

if options.showWaitbar; waitbar(1, wb); delete(wb); end
status = true;
end