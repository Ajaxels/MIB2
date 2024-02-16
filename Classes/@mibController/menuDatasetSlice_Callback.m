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

function menuDatasetSlice_Callback(obj, parameter)
% function menuDatasetSlice_Callback(obj, parameter)
% a callback to Menu->Dataset->Slice
% do actions with individual slices
%
% Parameters:
% parameter: a string that defines image source:
% - 'copySlice', copy slice (a section from a Z-stack) from one position to another
% - 'insertSlice', insert an empty slice
% - 'deleteSlice', delete slice (a section from a Z-stack) from the dataset
% - 'deleteFrame', delete frame (a section from a time series) from the dataset
% - 'reslice', strided reslicing the dataset so that the selected slices are kept and all others are removed
% - 'swapSlice', swap two or more slices

% Updates
% 28.03.2018, IB added insert an empty slice
% 20.05.2019, updated for the batch mode
% 25.03.2023, added reslicing

% check for the virtual stacking mode and close the controller
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'slice actions';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode\nplease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

switch parameter
    case {'copySlice', 'swapSlice'}
        if strcmp(parameter, 'swapSlice')
            obj.mibModel.copySwapSlice([],[],'swap');
        else
            obj.mibModel.copySwapSlice([],[],'replace');
        end
    case 'insertSlice'
        obj.mibModel.insertEmptySlice();
    case 'deleteSlice'
        obj.mibModel.deleteSlice(4);
    case 'deleteFrame'
        obj.mibModel.deleteSlice(5);
    case 'reslice'
        obj.mibModel.resliceDataset();
end

end