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

function generateModelColors(obj)
% function generateModelColors(obj)
% Generate list of colors for materials of a model. 
%
% When a new material is added to a model, this function generates a random color for it.
%
% Parameters:
% 
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.generateModelColors();  // call from mibController, generate colors @endcode
% @code obj.mibModel.getImageMethod('generateModelColors'); // call from mibController via a wrapper function getImageMethod @endcode

% Updates
% 
status = 0;
if size(obj.modelMaterialColors,1) < numel(obj.modelMaterialNames)
    for i=size(obj.modelMaterialColors,1)+1:numel(obj.modelMaterialNames)
        obj.modelMaterialColors(i,:) = [rand(1) rand(1) rand(1)];
    end
end
status = 1;
end