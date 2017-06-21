function menuMaskInvert_Callback(obj, type)
% function menuMaskInvert_Callback(obj, type)
% callback to Menu->Mask->Invert; invert the Mask/Selection layer
%
% Parameters:
% type: a string with the layer to invert
% @li 'mask' - invert the Mask layer
% @li 'selection' - invert the Selection layer

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% do nothing is selection is disabled
if obj.mibModel.preferences.disableSelection == 1
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The selection layer is disabled','modal');
    return; 
end;

if strcmp(type, 'mask')
    if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0; return; end;
end
obj.mibModel.mibDoBackup(type, 1);

options.roiId = [];     % enable use of ROIs
if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
    mask = obj.mibModel.getData4D(type, NaN, 0, options);
    for roi=1:numel(mask)
        mask{roi} = 1 - mask{roi};
    end
    obj.mibModel.setData4D(type, mask, NaN, 0, options);
else
    mask = obj.mibModel.getData4D('everything', NaN, NaN, options);
    if strcmp(type, 'mask')
        bitxorValue = 64;
    else
        bitxorValue = 128;
    end
        
    for roi=1:numel(mask)
        mask{roi} = bitxor(mask{roi}, bitxorValue);
    end
    obj.mibModel.setData4D('everything', mask, NaN, NaN, options);
end
obj.plotImage();
end