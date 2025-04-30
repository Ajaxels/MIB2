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
% Date: 28.03.2025

function status = modelExportToMatlab(obj, materialOutputVariable, materialIndex, materialOutputIndex, options)
% function status = modelExportToMatlab(obj, materialOutputVariable, materialIndex, materialOutputIndex, options)
% Export model or material of the model to MATLAB main workspace. The
% exported variable has following fields:
%   .model 3D or 4D matrix [1:height, 1:width, 1:depth, 1:time] with the model
%   .modelMaterialNames - cell array with names of the exported materials
%   .modelMaterialColors - matrix with colors of materials [colorID; R,G,B] in the range from 0 to 1
%   .modelType - integer with the model type, 64, 255, 65535
%
% Parameters:
% materialOutputVariable: [string, default="O"] name of the output variable to create in the main MATLAB workspace 
% materialIndex: [integer or NaN, default=NaN] index of material to export, when NaN export complete model
% materialOutputIndex: [integer, default=1] value for the exported material, used only when a single material is exported, typical values 1 or 255
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code 
% obj.mibModel.I{obj.mibModel.Id}.modelExportToMatlab('Model', NaN);     // call from mibController; export complete model and assign into Model variable
% @endcode
% @code 
% obj.mibModel.I{obj.mibModel.Id}.modelExportToMatlab('Material3', 3);     // call from mibController; export 3rd material of the model Material3 variable
% @endcode

status = false;
if nargin < 5; options = struct; end
if nargin < 4; materialOutputIndex = 1; end
if nargin < 3; materialIndex = NaN; end
if nargin < 2; materialOutputVariable = 'O'; end
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

if options.showWaitbar;  wb = waitbar(0, 'Please wait...', 'Name', 'Exporting the model', 'WindowStyle', 'modal'); end

options.blockModeSwitch = 0;
O.model = obj.getData('model', 4, materialIndex, options);
if options.showWaitbar; waitbar(0.4, wb); end

O.modelMaterialNames = obj.modelMaterialNames;
O.modelMaterialColors = obj.modelMaterialColors;
O.modelType = obj.modelType;    % store the model type
if ~isnan(materialIndex) 
    if materialOutputIndex ~= 1
        O.model = O.model*materialOutputIndex;
    end
    O.modelMaterialNames = O.modelMaterialNames(materialIndex);
    O.modelMaterialColors = O.modelMaterialColors(materialIndex, :);
end

if obj.hLabels.getLabelsNumber() > 1  % save annotations
    [O.labelText, O.labelValue, O.labelPosition] = obj.hLabels.getLabels(); %#ok<NASGU,ASGLU>
end
if options.showWaitbar; waitbar(0.6, wb); end

assignin('base', materialOutputVariable, O);
disp(['Model export: created structure ' materialOutputVariable ' in the main MATLAB workspace']);

if options.showWaitbar; waitbar(1, wb); delete(wb); end
status = true;
end