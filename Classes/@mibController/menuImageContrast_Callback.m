function menuImageContrast_Callback(obj, parameter)
% function menuImageContrast_Callback(obj, parameter)
% a callback to Menu->Image->Contrast; do contrast enhancement
%
% Parameters:
% parameter: a string that defines image source:
% - ''CLAHE_2D'', contrast adjustment with CLAHE method for the current slice
% - ''CLAHE_3D'', contrast adjustment with CLAHE method for the shown stack
% - ''CLAHE_4D'', contrast adjustment with CLAHE method for the whole dataset
% - ''NormalizeZ'', normalize layers in the Z-dimension using intensity analysis of complete slices
% - ''NormalizeT'', normalize layers in the Time-dimensionusing intensity analysis of complete slices
% - ''NormalizeMask'', normalize layers using intensity analysis of complete slices
% - ''NormalizeBg'', normalize layers using intensity analysis of complete slices

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if numel(obj.mibModel.I{obj.mibModel.Id}.slices{3}) ~= 1    % get color channel from the selected in the Selection panel
    colCh = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
    if colCh == 0
        msgbox('Please select the color channel!', 'Error!', 'error', 'modal');
        return;
    end
else    % when only one color channel is shown, take it
    colCh = obj.mibModel.I{obj.mibModel.Id}.slices{3};
end

switch parameter
    case {'CLAHE_2D', 'CLAHE_3D', 'CLAHE_4D'}
        % adjust contrast
        obj.mibModel.contrastCLAHE(parameter, colCh);
        obj.plotImage(0);
    case 'NormalizeZ'
        obj.mibModel.contrastNormalizationMemoryOptimized('normalZ', colCh);
        obj.plotImage();
    case 'NormalizeT'
        if obj.mibModel.I{obj.mibModel.Id}.time == 1
            errordlg(sprintf('!!! Error !!!\n\nThe time series normalization requires more than one time point!\nTry Z-stack normalization instead'))
            return;
        end
        obj.mibModel.contrastNormalizationMemoryOptimized('normalT', colCh);
        obj.plotImage();
    case 'NormalizeMask'
        obj.mibModel.contrastNormalizationMemoryOptimized('mask', colCh);
        obj.plotImage();
    case 'NormalizeBg'
        obj.mibModel.contrastNormalizationMemoryOptimized('bgMean', colCh);
        obj.plotImage();
end
end