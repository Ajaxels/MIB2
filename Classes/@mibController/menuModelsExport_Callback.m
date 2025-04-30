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

function menuModelsExport_Callback(obj, exportTo)
% function menuModelsExport_Callback(obj, exportTo)
% callback to Menu->Models->Export
% export the Model layer to the main Matlab workspace
%
% Parameters:
% exportTo: a string with destination for the export
% @li 'matlab' - to Matlab workspace
% @li 'imaris' - to Imaris

% Updates
% 28.03.2025 moved to mibModel.modelExport

if nargin < 2; exportTo = []; end

BatchOpt = struct();
if isempty(exportTo)
    BatchOpt.ExportTo = {'matlab'};
else 
    BatchOpt.ExportTo = {exportTo};
end
BatchOpt.ExportTo = {'matlab'};
BatchOpt.ExportTo{2} = {'matlab', 'imaris'};  % cell array with the list of available actions
BatchOpt.MaterialIndex = ''; % no index, export the whole model
BatchOpt.MaterialOutputVariable = 'O'; 
obj.mibModel.modelExport(BatchOpt);
end