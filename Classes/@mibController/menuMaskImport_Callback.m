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

% do nothing is selection is disabled
if obj.mibModel.preferences.disableSelection == 1
    warndlg(sprintf('The mask layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The masks are disabled', 'modal');
    return; 
end

switch parameter
    case 'matlab'
        answer = mibInputDlg({mibPath}, 'Mask variable (1:h,1:w,1:z,1:t)', 'Import from Matlab', 'M');
        if size(answer) == 0; return; end
        
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
        
        answer = mibInputDlg({mibPath}, 'Enter buffer number (from 1 to 9) of the dataset that has the mask layer:','Import mask', num2str(destinationButton));
        if isempty(answer); return; end
        
        destinationButton = str2double(answer{1});
        if strcmp(obj.mibModel.I{destinationButton}.meta('Filename'), 'none.tif')
            errordlg(sprintf('!!! Error !!!\n\nWrong origin!\nThe dataset of the mask origin should contain the dataset and the mask'), 'Missing dataset', 'modal');
            return;
        end
        
        if obj.mibModel.I{destinationButton}.maskExist == 0
            errordlg(sprintf('!!! Error !!!\n\nThe mask layer is not present in the origin dataset!'), 'Missing the mask layer', 'modal');
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