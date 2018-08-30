function menuSelectionBuffer_Callback(obj, parameter)
% function menuSelectionBuffer_Callback(obj, parameter)
% a callback to Menu->Selection to Buffer... to Copy/Paste/Clear of the selection of the shown layer
%
% Parameters:
% parameter: a string that defines image source:
% - ''copy'', store selection from the current layer to a buffer
% - ''paste'', paste selection from the buffer to the current layer
% - ''pasteall'', paste selection from the buffer to all Z-layers
% - ''clear'', clear selection buffer

% Copyright (C) 20.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 26.04.2017, IB, added paste to all z-slices

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = '';
    warndlg(sprintf('!!! Warning !!!\n\nThis action is%s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1; return; end
options.blockModeSwitch = 0;

switch parameter
    case 'copy'
        obj.mibModel.storedSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
    case 'paste'
        if isempty(obj.mibModel.storedSelection)
            msgbox(sprintf('Error!\nThe buffer is empty!'),'Error!','error','modal');
            return;
        end
        currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        if min(size(currSelection) == size(obj.mibModel.storedSelection)) == 1
            obj.mibModel.mibDoBackup('selection', 0);
            obj.mibModel.setData2D('selection', bitor(obj.mibModel.storedSelection, currSelection), NaN, NaN, NaN, options);
            obj.plotImage(0);
        else
            msgbox(sprintf('Error!\nThe size of the buffered and current selections mismatch!\nTry to change the orientation of the dataset...'),'Error!','error','modal');
        end
    case 'pasteall'
        if isempty(obj.mibModel.storedSelection)
            msgbox(sprintf('Error!\nThe buffer is empty!'), 'Error!', 'error', 'modal');
            return;
        end
        wb = waitbar(0, sprintf('Pasting selection to layers\nPlease wait...'), 'Name', 'Paste selection', 'WindowStyle', 'modal');
        options.blockModeSwitch = 0;
        currSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        [~, ~, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, options);
        if min(size(currSelection) == size(obj.mibModel.storedSelection)) == 1
            obj.mibModel.mibDoBackup('selection', 1);
            for z=1:depth
                currSelection = cell2mat(obj.mibModel.getData2D('selection', z, NaN, NaN, options));
                obj.mibModel.setData2D('selection', bitor(obj.mibModel.storedSelection, currSelection), z, NaN, NaN, options);
                waitbar(z/depth, wb);
            end
            obj.plotImage(0);
            delete(wb);
        else
            msgbox(sprintf('Error!\nThe size of the buffered and current selections mismatch!\nTry to change the orientation of the dataset...'),'Error!','error','modal');
        end
    case 'clear'
        obj.mibModel.storedSelection = [];
end
end