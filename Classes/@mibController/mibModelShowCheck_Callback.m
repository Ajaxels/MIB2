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

function mibModelShowCheck_Callback(obj)
% function mibModelShowCheck_Callback(obj)
% callback to the mibGUI.handles.mibModelShowCheck to toggle the Model layer on/off
%
% Parameters:
% 
% Return values
%

% Updates
% 


if obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
    obj.mibView.handles.mibModelShowCheck.Value = 0;
    obj.mibModel.mibModelShowCheck = 0;
    return;
end
obj.mibModel.mibModelShowCheck = obj.mibView.handles.mibModelShowCheck.Value;
obj.mibModel.I{obj.mibModel.Id}.generateModelColors();
obj.plotImage(0);
end
