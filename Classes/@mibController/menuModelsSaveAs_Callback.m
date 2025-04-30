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

function menuModelsSaveAs_Callback(obj, parameter)
% function menuModelsSaveAs_Callback(obj, parameter)
% callback to Menu->Models->Save as
% save model to a file
%
% Parameters:
% parameter: a string
% @li ''saveas'' -> [@em default] start a dialog to select saving format and the filename 
% @li ''save'' -> save using existing filename

% Updates
% 04.06.2018 save TransformationMatrix with AmiraMesh

if nargin < 2; parameter = 'saveas'; end

BatchOpt = struct();
if obj.mibModel.showAllMaterials ~= 1
    BatchOpt.MaterialIndex = num2str(obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2);
end

switch parameter
    case 'save'
        filename = obj.mibModel.saveModel(obj.mibModel.I{obj.mibModel.Id}.modelFilename, BatchOpt);
    case 'saveas'
        filename = obj.mibModel.saveModel([], BatchOpt);
end
if isempty(filename); return; end

% update filelist and highlight the loaded image file
[~, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
obj.updateFilelist([fn ext]);
obj.plotImage();
end
