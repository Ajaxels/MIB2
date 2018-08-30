function menuSelectionToMaskBorder_Callback(obj)
% function menuSelectionToMaskBorder_Callback(obj)
% callback to Menu->Selection->Expand to Mask border
% expand selection to borders of the Masked layer
%
% Parameters:
% 

% Copyright (C) 10.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = '';
    warndlg(sprintf('!!! Warning !!!\n\nThis action is%s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The selection layer is disabled','modal');
    return; 
end

wb = waitbar(0, 'Expanding Selection to fit 3D Mask...','WindowStyle','modal');
tic;
if obj.mibModel.getImageProperty('time') == 1
    obj.mibModel.mibDoBackup('selection', 1);
end

for t=1:obj.mibModel.getImageProperty('time')
    getDataOptions.blockModeSwitch = 0; % do for the full dataset
    selection = cell2mat(obj.mibModel.getData3D('selection', t, 4, 0, getDataOptions));
    CC1 = bwconncomp(selection, 26);    % get objects from the selection layer.
    CC2 = bwconncomp(cell2mat(obj.mibModel.getData3D('mask', t, 4, 0, getDataOptions)), 26);    % get objects from the mask layer.
    CC2_objects = 1:CC2.NumObjects; % vector that have indices of all mask objects
    obj.mibModel.I{obj.mibModel.Id}.clearSelection(NaN, NaN, NaN, t);
    selection = zeros(size(selection), 'uint8');
    
    waitbar_step = round(CC1.NumObjects/10);
    
    for selObj = 1:CC1.NumObjects
        if mod(selObj, waitbar_step)==0; waitbar(selObj/CC1.NumObjects,wb); end
        pixel_id = CC1.PixelIdxList{selObj}(1); % one index from each selection objects
        %[y,x,z] = ind2sub(size(handles.Img{handles.Id}.I.selection),pixel_id);
        for id = CC2_objects
            if ~isempty(find(CC2.PixelIdxList{id}==pixel_id)) %#ok<EFIND>
                CC2_objects = CC2_objects(CC2_objects ~= selObj);
                selection(CC2.PixelIdxList{id}) = 1;
            end
        end
    end
    obj.mibModel.setData3D('selection', selection, t, 4, 0, getDataOptions);
    waitbar(t/obj.mibModel.I{obj.mibModel.Id}.time, wb);
end
delete(wb);
toc;
obj.plotImage();
end
