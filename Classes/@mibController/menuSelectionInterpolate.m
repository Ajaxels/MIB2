function menuSelectionInterpolate(obj)
% function menuSelectionInterpolate(obj)
% a callback to the Menu->Selection->Interpolate; interpolates shapes of the selection layer
%
% Parameters:
% 
% Return values:
%


% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
tic
selection = cell2mat(obj.mibModel.getData3D('selection'));

wb = waitbar(0,'Please wait...','Name','Interpolating...','WindowStyle','modal');
if strcmp(obj.mibModel.preferences.interpolationType, 'shape')    % shape interpolation
    [selection, bb] = mibInterpolateShapes(selection, obj.mibModel.preferences.interpolationNoPoints);
    if isempty(bb)
        delete(wb);
        return;
    end
    storeOptions.y = [bb(3), bb(4)];
    storeOptions.x = [bb(1), bb(2)];
    storeOptions.z = [bb(5), bb(6)];
    obj.mibModel.mibDoBackup('selection', 1, storeOptions);
else    % line interpolation
    obj.mibModel.mibDoBackup('selection', 1);
    selection = mibInterpolateLines(selection, obj.mibModel.preferences.interpolationNoPoints, obj.mibModel.preferences.interpolationLineWidth);
end

obj.mibModel.setData3D('selection',selection);
waitbar(1,wb);
delete(wb);
toc
obj.plotImage(0);
end