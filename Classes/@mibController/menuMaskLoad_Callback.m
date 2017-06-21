function menuMaskLoad_Callback(obj)
% function menuMaskLoad_Callback(obj)
% callback to Menu->Mask->Load Mask; load the Mask layer to MIB from a file
%
% Parameters:
% 

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
    warndlg(sprintf('The mask layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The models are disabled', 'modal');
    return; 
end;

% do 3D backup when time == 1
if obj.mibModel.getImageProperty('time') < 2
    obj.mibModel.mibDoBackup('mask', 1);
end

mypath = obj.mibView.handles.mibPathEdit.String;
[filename, path] = uigetfile(...
    {'*.mask;',  'Matlab format (*.mask)'; ...
    '*.am;',  'Amira mesh format (*.am)'; ...
    '*.tif;', 'TIF format (*.tif)'; ...
    '*.*', 'All Files (*.*)'}, ...
    'Open mask data...', mypath, 'MultiSelect', 'on');
if isequal(filename,0); return; end; % check for cancel
if ischar(filename); filename = cellstr(filename); end;     % convert to cell type
%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 

wb = waitbar(0,sprintf('%s\nPlease wait...', ...
    fullfile(path, filename{1})), 'Name', 'Loading the mask', 'WindowStyle', 'modal');
waitbar(0, wb);

if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0 && ...
        obj.mibModel.I{obj.mibModel.Id}.modelType ~= 63
    obj.mibModel.I{obj.mibModel.Id}.maskImg{1} = ...
        zeros([obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width, obj.mibModel.I{obj.mibModel.Id}.depth, obj.mibModel.I{obj.mibModel.Id}.time], 'uint8');
    obj.mibModel.I{obj.mibModel.Id}.maskExist = 1;
end
setDataOptions.blockModeSwitch = 0;

for fnId = 1:numel(filename)
    if strcmp(filename{1}(end-1:end),'am') % loading amira mesh
        res = amiraLabels2bitmap(fullfile(path, filename{fnId}));
    elseif strcmp(filename{1}(end-3:end),'mask') % loading matlab format
        res = load(fullfile(path, filename{fnId}),'-mat');
        field_name = fieldnames(res);
        res = res.(field_name{1});
    else % loading mask in tif format and other standard formats
        options.bioformatsCheck = 0;
        options.progressDlg = 0;
        [res, ~, ~] = mibLoadImages({fullfile(path, filename{fnId})}, options);
        res =  squeeze(res);
        res = uint8(res>0);    % set masked areas as 1
    end
    
    % check dimensions
    if size(res,1) == obj.mibModel.I{obj.mibModel.Id}.height && size(res,2) == obj.mibModel.I{obj.mibModel.Id}.width
        % do nothing
    elseif size(res,1) == obj.mibModel.I{obj.mibModel.Id}.width && size(res,2) == obj.mibModel.I{obj.mibModel.Id}.height
        % permute
        res = permute(res, [2 1 3 4]);
    else
        msgbox('Mask image and loaded image dimensions mismatch!', 'Error!', 'error', 'modal');
        delete(wb);
        return;
    end
%     % check H/W/Z dimensions
%     if size(res, 1) ~= obj.mibModel.I{obj.mibModel.Id}.height || ...
%             size(res,2) ~= obj.mibModel.I{obj.mibModel.Id}.width || ...
%             size(res,3) ~= obj.mibModel.I{obj.mibModel.Id}.depth
%         if exist('wb','var'); delete(wb); end;
%         
%         msgbox(sprintf('Mask and image dimensions mismatch!\nImage (HxWxZ) = %d x %d x %d pixels\nMask (HxWxZ) = %d x %d x %d pixels',...
%             obj.mibModel.I{obj.mibModel.Id}.height, obj.mibModel.I{obj.mibModel.Id}.width, obj.mibModel.I{obj.mibModel.Id}.depth, size(res,1), size(res,2), size(res,3)), 'Error!', 'error', 'modal');
%         return;
%     end
    
    if size(res, 4) > 1 && size(res, 4) == obj.mibModel.I{obj.mibModel.Id}.time   % update complete 4D dataset
        obj.mibModel.setData4D('mask', res, 4, 0, setDataOptions);
    elseif size(res, 4) == 1 && size(res,3) == obj.mibModel.I{obj.mibModel.Id}.depth  % update complete 3D dataset
        if numel(filename) > 1
            obj.mibModel.setData3D('mask', res, fnId, 4, 0, setDataOptions);
        else
            obj.mibModel.setData3D('mask', res, NaN, 4, 0, setDataOptions);
        end
    elseif size(res, 3) == 1
        if numel(filename) > 1
            obj.mibModel.setData2D('mask', res, fnId, 4, 0, setDataOptions);
        else
            obj.mibModel.setData2D('mask', res, NaN, 4, 0, setDataOptions);
        end
    end
    waitbar(fnId/numel(filename),wb);
end
obj.mibModel.I{obj.mibModel.Id}.maskImgFilename = fullfile([path filename{1}]);
waitbar(1,wb);

obj.mibView.handles.mibMaskShowCheck.Value = 1;
obj.mibMaskShowCheck_Callback();
delete(wb);
set(0, 'DefaulttextInterpreter', curInt); 
end