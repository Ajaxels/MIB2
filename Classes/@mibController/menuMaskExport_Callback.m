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

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'Export of masks is';
    warndlg(sprintf('!!! Warning !!!\n\n%s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

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
        % find buffers that have the mask layer
        destinationBuffer = 1:obj.mibModel.maxId;
        destinationButton = 1;
        bufferListIds = obj.mibModel.Id:-1:1;   % get the previous container if possible
        bufferListIds = [bufferListIds, obj.mibModel.Id:obj.mibModel.maxId];
        bufferListIds(bufferListIds==obj.mibModel.Id) = [];
        for i = bufferListIds
            if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif') == 0
                destinationButton = i;
                break;
            end
        end
        
        %for i=1:obj.mibModel.maxId
        %    if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif') == 0 && i ~= obj.mibModel.Id
        %        destinationButton = i;
        %        break;
        %    end
        %end

        destinationBuffer = arrayfun(@(x) {num2str(x)}, destinationBuffer);   % convert to string cell array
        prompts = {'Enter destination to export the Mask layer:'};
        defAns = {[destinationBuffer, destinationButton]};
        title = 'Export Mask to another dataset';
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
        if isempty(answer); return; end
        destinationButton = str2double(answer{1});
        
        % check dimensions
        [height, width, ~, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
        [height2, width2, ~, depth2, time2] = obj.mibModel.I{destinationButton}.getDatasetDimensions('image');
        if height ~= height2 || width~=width2 || depth~=depth2 || time~=time2
            errordlg(sprintf('!!! Error !!!\n\nDimensions mismatch [height x width x depth x time]\nCurrent dimensions: %d x %d x %d x %d\nImported dimensions: %d x %d x %d x %d', height, width, depth, time, height2, width2, depth2, time2), 'Wrong dimensions', 'modal');
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

