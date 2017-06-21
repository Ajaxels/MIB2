function menuMaskExport_Callback(obj, parameter)
% function menuMaskExport_Callback(obj, parameter)
% callback to Menu->Mask->Export, export the Mask layer to Matlab or
% another buffer
%
% Parameters:
% parameter: a string that specify the destination, where the mask layer
% should be exported
% @li 'matlab' - to the main Matlab workspace
% @li 'buffer' - another buffer within MIB

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
global mibPath;
if nargin < 2; parameter = 'matlab'; end

switch parameter
    case 'matlab'
        prompt = {'Variable for the mask image:'};
        title = 'Input variables for export';
        answer = mibInputDlg({mibPath}, prompt, title, 'M');
        if size(answer) == 0; return; end
        wb = waitbar(0, 'Please wait...', 'Name', 'Exporting the mask', 'WindowStyle', 'modal');
        options.blockModeSwitch = 0;
        waitbar(0.05, wb);
        assignin('base', answer{1}, cell2mat(obj.mibModel.getData4D('mask', 4, NaN, options)));
        waitbar(1, wb);
        disp(['Mask export: created variable ' answer{1} ' in the Matlab workspace']);
        delete(wb);
    case 'buffer'
        destinationButton = [];
        for i=1:obj.mibModel.maxId
            if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif') == 0
                destinationButton = i;
                break;
            end
        end    
        if isempty(destinationButton)
            errordlg(sprintf('!!! Error !!!\n\nPlease open another dataset into one of the buffers of MIB and try again!'), 'Missing dataset', 'modal');
            return;
        end
        answer = mibInputDlg({mibPath}, 'Enter destination buffer number (from 1 to 9) to export the mask layer:','Export mask', num2str(destinationButton));
        if isempty(answer); return; end
        destinationButton = str2double(answer{1});
        if strcmp(obj.mibModel.I{destinationButton}.meta('Filename'), 'none.tif')
            errordlg(sprintf('!!! Error !!!\n\nWrong destination!\nThe destination should have an opened dataset with dimensions that match dimensions of the current dataset'), 'Missing dataset', 'modal');
            return;
        end
        wb = waitbar(0, 'Please wait...', 'Name', 'Copying the mask', 'WindowStyle', 'modal');
        options.blockModeSwitch = 0;
        mask = obj.mibModel.getData4D('mask', 4, NaN, options);
        waitbar(0.5, wb);
        options.id = destinationButton;
        obj.mibModel.setData4D('mask', mask, 4, NaN, options);
        waitbar(1, wb);
        fprintf('MIB: the mask layer was exported from %d to %d\n', obj.mibModel.Id, destinationButton);
        delete(wb);
end

