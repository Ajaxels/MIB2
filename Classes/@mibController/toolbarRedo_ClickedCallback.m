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

function toolbarRedo_ClickedCallback(obj)
% function toolbarRedo_ClickedCallback(obj)
% do one step forward in the undo history
%
% Parameters:
% 

% Updates
% 

index = obj.mibModel.U.undoIndex + 1;
if index > numel(obj.mibModel.U.undoList); return; end;
obj.mibDoUndo(index);
end