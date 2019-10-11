function menuFileChoppedImage_Callback(obj, parameter)
% function menuFileChoppedImage_Callback(obj, parameter)
% a callback to Menu->File->Chopped images, chop/rechop dataset to/from
% smaller subsets
%
% Parameters:
% parameter: [@em optional] a string that defines image source:
% - 'import', [default] import multiple datasets and assemble them in one big dataset
% - 'export', chop the currently opened dataset to a set of smaller ones

% Copyright (C) 20.01.201, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 2;     parameter = 'import'; end

switch parameter
    case 'import'
        if ~strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'), 'none.tif')
            button = questdlg(...
                sprintf('!!! Warning !!!\n\nIf you select "Generate new stack" and "Images" in the following dialog, the currenly opened in the buffer %d dataset will be replaced!\n\nAre you sure?\n\nAlternatively, select an empty buffer (the buttons in the upper part of the Directory contents panel) and try again...', obj.mibModel.Id),'!! Warning !!','OK','Cancel','Cancel');
            if strcmp(button, 'Cancel'); return; end
        end
        
        % check for the virtual stacking mode and disable it
        if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
            result = obj.toolbarVirtualMode_ClickedCallback(0);  % switch to the memory-resident mode
            if isempty(result) || result == 1; return; end
        end
        
        obj.startController('mibRechopDatasetController');
        obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection = [2 1];  % last selected contour for use with the 'e' button
    case 'export'
        obj.startController('mibChopDatasetController');
end