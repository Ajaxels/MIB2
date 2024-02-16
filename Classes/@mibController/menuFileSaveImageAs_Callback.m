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

function menuFileSaveImageAs_Callback(obj)
% function menuFileSaveImageAs_Callback(obj)
% a callback to the mibGUI.handles.menuFileSaveImageAs, saves image to a file
%
% Parameters:
% 
% Return values:
%

% Updates
% 04.06.2018 save TransformationMatrix with AmiraMesh
% 22.01.2019 added saving of amira mesh files as 2D sequence

saveImageOptions.DestinationDirectory = obj.mibModel.myPath;
filename = obj.mibModel.I{obj.mibModel.Id}.saveImageAsDialog([], saveImageOptions);
if isempty(filename); return; end
[~, filename, ext] = fileparts(filename);
obj.updateFilelist([filename ext]);     % update list of files, use filename to highlight the saved file
return;
