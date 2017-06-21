function menuMaskSaveAs_Callback(obj)
% function menuMaskSaveAs_Callback(obj)
% callback to Menu->Mask->Save As; save the Mask layer to a file
%
% Parameters:
% 

% Copyright (C) 02.08.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% Save mask layer to a file in Matlab format
if obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
    disp('Cancelled: No mask information found!'); 
    return; 
end;
if isnan(obj.mibModel.I{obj.mibModel.Id}.maskImgFilename)
    [pathstr, name] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
    fn_out = fullfile(pathstr, ['Mask_' name '.mask']);
    if isempty(strfind(fn_out,'/')) && isempty(strfind(fn_out,'\'))
        fn_out = fullfile(obj.mibModel.myPath, fn_out);
    end
    if isempty(fn_out)
        fn_out = obj.mibModel.myPath;
    end
else
    fn_out = obj.mibModel.I{obj.mibModel.Id}.maskImgFilename;
end;

[filename, path, FilterIndex] = uiputfile(...
    {'*.mask',  'Matlab format (*.mask)'; ...
    '*.am',  'Amira mesh binary RLE compression SLOW (*.am)'; ...
    '*.am',  'Amira mesh binary (*.am)'; ...
    '*.tif',  'TIF format (*.tif)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Save mask data...', fn_out);
if isequal(filename,0); return; end; % check for cancel

%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 
wb = waitbar(0, sprintf('%s\nPlease wait...', fullfile(path, filename)), ...
    'Name', 'Saving the mask', 'WindowStyle', 'modal');

getDataOptions.blockModeSwitch = 0;
waitbar(0.1, wb);

if FilterIndex == 1     % matlab file
    maskImg = cell2mat(obj.mibModel.getData4D('mask', 4, NaN, getDataOptions)); %#ok<NASGU>
    save([path filename], 'maskImg', '-v7.3');
else
    t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
    t2 = t1;
    if obj.mibModel.I{obj.mibModel.Id}.time > 1
        button = questdlg(sprintf('!!! Warning !!!\nIt is not possible to save 4D dataset into a single file!\n\nHowever it is possible to save the currently shown Z-stack, or to make a series of files'), ...
            'Save mask', 'Save as series of 3D datasets', 'Save the currently shown Z-stack', 'Cancel', 'Save as series of 3D datasets');
        if strcmp(button, 'Cancel'); return; end;
        if strcmp(button, 'Save as series of 3D datasets')
            t1 = 1;
            t2 = obj.mibModel.I{obj.mibModel.Id}.time;
        end
    end
    [~,filename, ext] = fileparts(filename);
    
    for t=t1:t2
        if t1~=t2   % generate filename
            fnOut = generateSequentialFilename(filename, t, t2-t1+1, ext);
        else
            fnOut = [filename ext];
        end        
        
        maskImg = cell2mat(obj.mibModel.getData3D('mask', t, 4, NaN, getDataOptions));
        if FilterIndex == 2 || FilterIndex == 3      % Amira mesh
            if FilterIndex == 2
                amiraType = 'binaryRLE';
            else
                amiraType = 'binary';
            end
            bb = obj.mibModel.I{obj.mibModel.Id}.getBoundingBox();
            pixStr = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            pixStr.minx = bb(1);
            pixStr.miny = bb(3);
            pixStr.minz = bb(5);
            bitmap2amiraLabels([path fnOut], maskImg, amiraType, pixStr, obj.mibModel.preferences.maskcolor, cellstr('Mask'), 1);    
        elseif FilterIndex == 4   % as tif
            ImageDescription = {obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription')};
            resolution(1) = obj.mibModel.I{obj.mibModel.Id}.meta('XResolution');
            resolution(2) = obj.mibModel.I{obj.mibModel.Id}.meta('YResolution');
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                savingOptions = struct('Resolution', resolution, 'overwrite', 1, 'Saving3d', NaN, 'cmap', NaN);
            end
            maskImg = reshape(maskImg, [size(maskImg,1) size(maskImg,2) 1 size(maskImg,3)]);
            [result, savingOptions] = mibImage2tiff(fullfile(path, fnOut), maskImg, savingOptions, ImageDescription); 
            if isfield(savingOptions, 'SliceName'); savingOptions = rmfield(savingOptions, 'SliceName'); end; % remove SliceName field when saving series of 2D files
        end
    end
end

waitbar(0.9, wb);
obj.mibModel.I{obj.mibModel.Id}.maskImgFilename = fullfile(path, filename);
sprintf('The mask %s was saved!', fullfile(path, filename));
waitbar(1, wb);
set(0, 'DefaulttextInterpreter', curInt); 
delete(wb);
end