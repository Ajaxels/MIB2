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
% Date: 14.03.2025

function status = materialsReorder(obj, newOrder, options)
% function status = materialsReorder(obj, newOrder, options)
% Reorder materials in the model
%
% Parameters:
% newOrder: [string] new order of materials in the model
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.newOrder('10:-1:1');     // call from mibController; invert the order of materials
% @endcode

% Updates
% 

status = false;
if nargin < 3; options = struct; end
if nargin < 2
    warndlg(sprintf('materialsReorder: string with new order of materials is required'), 'Missing parameters');
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
if obj.modelType > 256
    warndlg(sprintf('Reordering of materials is only supported form models with up to 256 materials!'), 'Not implemented');
    return;
end
if ~obj.modelExist 
    warndlg(sprintf('Create or load the model first!'), 'No model');
    return;
end
newOrderNumerical =  str2num(newOrder); %#ok<ST2NM>
if numel(newOrderNumerical) ~= numel(obj.modelMaterialNames)
    errordlg(sprintf('Number of matirals should match number of materials of the current model!\nCurrent model: %d materials\nReordered list: %d materials', numel(obj.modelMaterialNames), numel(newOrderNumerical)), ...
        'Wrong number of materials');
    return;
end

if options.showWaitbar
    wb = waitbar(0,sprintf('%s\nPlease wait...', newOrder), ...
        'Name', 'Reordering materials', ...
        'WindowStyle','modal'); 
end

tic
maxTime = obj.time;
for t=1:maxTime
    options.t = t;
    M = obj.getData('model', 4, NaN, options);
    % mapping: 0 stays 0, then required order for 1, 2, 3...
    % ensure mapping matches M's class
    mapping = cast([0, newOrderNumerical], 'like', M); 

    % remap the indices in M
    M_new = mapping(M + 1); % Add 1 to M to align with MATLAB 1-based indexing
    obj.setData('model', M_new, 4, NaN, options);

    if options.showWaitbar; waitbar(t/maxTime , wb); end
end
clear M;

if obj.modelType < 256
    obj.modelMaterialColors = obj.modelMaterialColors(newOrderNumerical, :); % reorder color maps
    obj.modelMaterialNames = obj.modelMaterialNames(newOrderNumerical);  % reorder material names
    obj.lastSegmSelection = [2 1];
end
toc

if options.showWaitbar; waitbar(1, wb); delete(wb); end
status = true;
end