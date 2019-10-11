function menuImageContrast_Callback(obj, parameter)
% function menuImageContrast_Callback(obj, parameter, BatchOptIn)
% a callback to Menu->Image->Contrast; do contrast enhancement
%
% Parameters:
% parameter: a string that defines image source:
% - ''CLAHE'', contrast adjustment with CLAHE method
% - ''Z stack'', normalize layers in the Z-dimension using intensity analysis of complete slices
% - ''Time series'', normalize layers in the Time-dimensionusing intensity analysis of complete slices
% - ''Masked area'', normalize layers using intensity analysis of complete slices
% - ''Background'', normalize layers using intensity analysis of complete slices
% BatchOptIn: a structure for batch processing mode, when NaN return
% a structure with default options via "syncBatch" event

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 27.04.2019, simplified for the batch mode

switch parameter
    case {'Z stack', 'Time series', 'Masked area', 'Background'}
        % normalize contrast
        obj.mibModel.contrastNormalization(parameter);
    case 'CLAHE'
        % adjust contrast with CLAHE
        obj.mibModel.contrastCLAHE();
        obj.plotImage(0);
end