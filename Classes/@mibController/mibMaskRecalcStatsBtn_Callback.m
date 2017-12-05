function mibMaskRecalcStatsBtn_Callback(obj)
% function mibMaskRecalcStatsBtn_Callback(obj)
% recalculate objects for Mask or Model layer to use with the Object Picker
% tool in 3D
%
% This function populates mibModel.maskStat structure
%
%

% Copyright (C) 20.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

wb = waitbar(0, 'Calculating statistics, please wait...', 'WindowStyle', 'modal');
getDataOptions.blockModeSwitch = 0;
if obj.mibView.handles.mibSegmMaskClickModelCheck.Value
    type = 'model';
    colchannel = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
    if colchannel < 0  % do not continue when All is selected
        msgbox(sprintf('Please select Material in the ''Select from list'' and press the ''Recalc.'' button in the Segmentation panel, Object Picker tool again!'),'Warning!','warn');
        delete(wb);
        return;
    end
else
    type = 'mask';
    colchannel = 0;
end
if obj.mibView.handles.mibMagicwandConnectCheck4.Value
    connectionType = 6; % 6-neighbour points
else
    connectionType = 26; % 26-neighbour points
end
if obj.mibModel.I{obj.mibModel.Id}.modelType < 65535
    obj.mibModel.I{obj.mibModel.Id}.maskStat = bwconncomp(cell2mat(obj.mibModel.getData3D(type, NaN, 4, colchannel, getDataOptions)), connectionType); 
    obj.mibModel.I{obj.mibModel.Id}.maskStat.L = labelmatrix(obj.mibModel.I{obj.mibModel.Id}.maskStat);     % create a label matrix for fast search of the indices
    obj.mibModel.I{obj.mibModel.Id}.maskStat.bb = regionprops(obj.mibModel.I{obj.mibModel.Id}.maskStat, 'BoundingBox');     % create a label matrix for fast search of the indices
    obj.mibModel.I{obj.mibModel.Id}.maskStat = rmfield(obj.mibModel.I{obj.mibModel.Id}.maskStat, 'PixelIdxList');   % remove PixelIdxList it is not needed anymore
else
    obj.mibModel.I{obj.mibModel.Id}.maskStat = regionprops(cell2mat(obj.mibModel.getData3D(type, NaN, 4, NaN, getDataOptions)), 'PixelIdxList'); 
end
delete(wb);

end