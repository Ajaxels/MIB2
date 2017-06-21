function menuDatasetTrasform_Callback(obj, mode)
% function menuDatasetTrasform_Callback(obj, mode)
% a callback to Menu->Dataset->Transform...
% do different transformation with the dataset
%
% Parameters:
% mode: a string with a transormation mode:
% @li 'flipH', flip the dataset horizontally
% @li 'flipV', flip the dataset vertically
% @li 'flipZ', flip the Z-stacks of the dataset
% @li 'flipT', flip the time vector of the dataset
% @li 'rot90', rotate dataset 90 degrees clockwise 
% @li 'rot-90', rotate dataset 90 degrees counterclockwise 
% @li 'xy2zx', transpose the dataset so that YX->XZ
% @li 'xy2zy', transpose the dataset so that YX->YZ
% @li 'zx2zy', transpose the dataset so that XZ->YZ

% Copyright (C) 01.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.mibModel.U.clearContents(); % clear undo history

switch mode
    case {'flipH', 'flipV','flipZ','flipT'}
        obj.mibModel.flipDataset(mode);
    case {'rot90', 'rot-90'}
        obj.mibModel.rotateDataset(mode);
    case {'xy2zx', 'xy2zy','zx2zy','z2t'}
        obj.mibModel.transposeDataset(mode);
end
end