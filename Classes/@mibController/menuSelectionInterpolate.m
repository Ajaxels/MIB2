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
% 18.08.2017, IB, fix backup before interpolation for YZ and XZ
% orientations

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'interpolation is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The selection layer is disabled','modal');
    return; 
end
tic
selection = cell2mat(obj.mibModel.getData3D('selection'));

if obj.mibModel.getImageProperty('blockModeSwitch') == 0
    xShift = 0;
    yShift = 0;
    zShift = 0;
else
    transposeTo4 = 1;
    [yMin, ~, xMin, ~, zMin, ~] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage(transposeTo4);
    xShift = xMin - 1;
    yShift = yMin - 1;
    zShift = zMin - 1;
end

wb = waitbar(0,'Please wait...','Name','Interpolating...','WindowStyle','modal');
if strcmp(obj.mibModel.preferences.interpolationType, 'shape')    % shape interpolation
    [selection, bb] = mibInterpolateShapes(selection, obj.mibModel.preferences.interpolationNoPoints);
    if isempty(bb)
        delete(wb);
        return;
    end
    
    % bb = [xMin, xMax, yMin, yMax, zMin, zMax]
    if obj.mibModel.I{obj.mibModel.Id}.orientation == 1     % xz
        storeOptions.y = [bb(5)+yShift, bb(6)+yShift];  % [minPnt, maxPnt]
        storeOptions.z = [bb(1)+zShift, bb(2)+zShift];
        storeOptions.x = [bb(3)+xShift, bb(4)+xShift];
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 % yz
        storeOptions.y = [bb(3)+yShift, bb(4)+yShift];  % [minPnt, maxPnt]
        storeOptions.z = [bb(1)+zShift, bb(2)+zShift];
        storeOptions.x = [bb(5)+xShift, bb(6)+xShift];
    elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 4 % yx
        storeOptions.y = [bb(3)+yShift, bb(4)+yShift];  % [minPnt, maxPnt]
        storeOptions.x = [bb(1)+xShift, bb(2)+xShift];
        storeOptions.z = [bb(5)+zShift, bb(6)+zShift];    
    end
    
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