function menuMaskImport_Callback(obj, parameter)
% function menuMaskImport_Callback(obj, parameter)
% callback to Menu->Mask->Import, import the Mask layer from Matlab or
% another buffer of MIB
%
% Parameters:
% parameter: a string that specify the origin, from where the mask layer
% should be imported
% @li 'matlab' - from the main Matlab workspace
% @li 'buffer' - from another buffer within MIB

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
    toolname = 'Import of masks is';
    warndlg(sprintf('!!! Warning !!!\n\n%s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1
    warndlg(sprintf('The mask layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The masks are disabled', 'modal');
    return; 
end

switch parameter
    case 'matlab'
        availableVars = evalin('base', 'whos');
        idx = ismember({availableVars.class}, {'uint8', 'uint16', 'uint32', 'uint64','int8', 'int16', 'int32', 'int64', 'double', 'single'});
        if sum(idx) == 0
            errordlg(sprintf('!!! Error !!!\nNothing to import...'), 'Nothing to import');
            return;
        end
        ImageVars = {availableVars(idx).name}';
        ImageSize = {availableVars(idx).size}';
        ImageClass = {availableVars(idx).class}';
        ImageVarsDetails = ImageVars;
        % add deteiled description to the text
        for i=1:numel(ImageVarsDetails)
            ImageVarsDetails{i} = sprintf('%s: %s [%s]', ImageVars{i}, ImageClass{i}, num2str(ImageSize{i}));
        end
        
        % find index of the I variable if it is present
        idx2 = find(ismember(ImageVars, 'M')==1);
        if ~isempty(idx2)
            ImageVarsDetails{end+1} = idx2;
        else
            ImageVarsDetails{end+1} = 1;
        end
        
        prompts = {'Mask variable (1:h,1:w,1:z,1:t):'};
        defAns = {ImageVarsDetails};
        title = 'Import Mask from Matlab';
        [answer, selIndex] = mibInputMultiDlg({obj.mibPath}, prompts, defAns, title);
        if isempty(answer); return; end
        %answer(1) = ImageVars(contains(ImageVarsDetails(1:end-1), answer{1})==1);
        answer(1) = ImageVars(selIndex(1));
        
        wb = waitbar(0, sprintf('Importing mask\nPlease wait...'),'Name','Import Mask', 'WindowStyle', 'modal');
        if (~isempty(answer{1}))
            try
                mask = evalin('base',answer{1});
            catch exception
                errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message),...
                    'Misssing variable!', 'modal');
                delete(wb);
                return;
            end
            if size(mask, 1) ~= obj.mibModel.I{obj.mibModel.Id}.height || ...
                    size(mask,2) ~= obj.mibModel.I{obj.mibModel.Id}.width 
                msgbox(sprintf('Mask and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nMask (HxWxZ) = %d x %d x %d pixels',...
                    obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width, obj.mibModel.I{obj.mibModel.Id}.depth, ...
                    size(mask, 1), size(mask, 2), size(mask, 3)), 'Error!', 'error', 'modal');
                delete(wb);
                return;
            end
            obj.mibModel.mibDoBackup('mask', 1);
            waitbar(0.4, wb);
            setDataOptions.blockModeSwitch = 0;
            if size(mask, 3) == 1
                if obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
                    if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                        obj.mibModel.I{obj.mibModel.Id}.maskImg{1} = ...
                            zeros([obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width,...
                            obj.mibModel.I{obj.mibModel.Id}.depth, obj.mibModel.I{obj.mibModel.Id}.time], 'uint8');
                    end
                end
                obj.mibModel.setData2D('mask', mask, NaN, NaN, 0, setDataOptions);
            elseif size(mask, 3) == obj.mibModel.I{obj.mibModel.Id}.depth && size(mask, 4) == 1
                obj.mibModel.setData3D('mask', mask, NaN, 4, NaN, setDataOptions);
            elseif size(mask, 4) == obj.mibModel.I{obj.mibModel.Id}.time
                obj.mibModel.setData4D('mask', mask, 4, NaN, setDataOptions);
            end
            waitbar(0.95, wb);
            [pathstr, name] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.mibModel.I{obj.mibModel.Id}.maskImgFilename = fullfile(pathstr, sprintf('Mask_%s.mask', name));
            waitbar(1, wb);
            delete(wb);
        end
    case 'buffer'
        % find buffers that have the mask layer
        sourceBuffer = arrayfun(@(i) obj.mibModel.I{i}.maskExist, 1:obj.mibModel.maxId);
        sourceBuffer = find(sourceBuffer==1);   % find buffer indices
        sourceBuffer = sourceBuffer(sourceBuffer~=obj.mibModel.Id);     % remove currently opened buffer from the list
        
        if isempty(sourceBuffer)
            errordlg(sprintf('!!! Error !!!\n\nThe Mask layer has not been found!'), 'Missing mask', 'modal');
            return;
        end
        sourceBuffer = arrayfun(@(x) {num2str(x)}, sourceBuffer);   % convert to string cell array
        prompts = {'Please select the buffer number:'};
        defAns = {sourceBuffer};
        title = 'Import Mask from another dataset';
        answer = mibInputMultiDlg({obj.mibPath}, prompts, defAns, title);
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
        options.id = destinationButton;
        mask = obj.mibModel.getData4D('mask', 4, NaN, options);
        waitbar(0.5, wb);
        options.id = obj.mibModel.Id;
        obj.mibModel.setData4D('mask', mask, 4, NaN, options);
        waitbar(1, wb);
        fprintf('MIB: the mask layer was imported from %d to %d\n', destinationButton, obj.mibModel.Id);
        delete(wb);
end
obj.mibView.handles.mibMaskShowCheck.Value = 1;
obj.mibMaskShowCheck_Callback();
end