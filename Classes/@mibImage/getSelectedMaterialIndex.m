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

function index = getSelectedMaterialIndex(obj, target)
% function index = getSelectedMaterialIndex(obj)
% return the index of the currently selected material in the mibView.handles.mibSegmentationTable
% 
% Parameters:
% target: a string with optional target column of the table
% @li ''Material'' - (@em default) the selected row in the material column
% @li ''AddTo'' - the selected row in the AddTo column
%
% Return values:
% index: an index of the currently selected material;
% @li ''-1'' - Mask
% @li ''0'' - Exterior
% @li ''1'' - 1st material of the model
% @li ''2'' - 2nd material of the model
%

%| 
% @b Examples:
% @code selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex(); // call from mibController class; return the index of the currently selected material @endcode
% @code selcontour = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex('AddTo'); // call from mibController class; return the index of the currently selected material in the AddTo column @endcode

if nargin < 2; target = 'Material'; end

switch target
    case 'Material'
        index = obj.selectedMaterial;
    case 'AddTo'
        index = obj.selectedAddToMaterial;
end

if obj.modelType < 256
    index = index - 2;
else
    index = index - 2;
    if index > 0
        index = str2double(obj.modelMaterialNames{index});
    end
end
end