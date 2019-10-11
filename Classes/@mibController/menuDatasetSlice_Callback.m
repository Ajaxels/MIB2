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
% - 'swapSlice', swap two or more slices

% Copyright (C) 02.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 28.03.2018, IB added insert an empty slice
% 20.05.2019, updated for the batch mode

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
end

end