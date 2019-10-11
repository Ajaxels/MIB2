function fnOut = saveMask(obj, filename, options)
% function fnOut = saveMask(obj, filename, options)
% save mask to a file
%
% Parameters:
% filename: [@em optional] a string with filename, when empty a dialog for
% filename selection is shown; when the filename is provided its extension defines the output format, unless the
% format is provided in the options structure
% options: an optional structure with additional parameters
% @li .Format - string with the output format, as in the Formats variable below, for example 'Matlab format (*.mask)'
% @li .DestinationDirectory - string, with destination directory, if filename has no full path
% @li .Saving3DPolicy - string, [TIF only] save images as 3D TIF file or as
% a sequence of 2D files ('3D stack', '2D sequence')
% @li .MaskColor - vector numeric [r g b] from 0 to 1 with the mask color
% @li .showWaitbar - logical, show or not the waitbar
% @li .silent  - logical, do not ask any questions and use default parameters
%
% Return values:
% fnOut -> output mask filename
%
% Copyright (C) 10.09.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

global mibPath;

fnOut = [];
if nargin < 3; options = struct(); end
if nargin < 2; filename = []; end

if obj.maskExist == 0
    warndlg(sprintf('!!! Warning !!!\n\nThe mask layer is not present!'), 'Missing the mask');
    return; 
end

Formats = {'*.mask',  'Matlab format (*.mask)'; ...
    '*.am',  'Amira mesh binary (*.am)'; ...
    '*.am',  'Amira mesh binary RLE compression SLOW (*.am)'; ...
    '*.h5',   'Hierarchical Data Format (*.h5)'; ...
    '*.tif',  'TIF format (*.tif)'; ...
    '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
    '*.*',  'All Files (*.*)'
    };
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end
if ~isfield(options, 'silent'); options.silent = false; end
if ~isfield(options, 'MaskColor'); options.MaskColor = [1 0 1]; end

% check for destination directory
if ~isempty(filename)
    [pathStr, fnameStr, ext] = fileparts(filename);
    if isempty(pathStr)
        if isfield(options, 'DestinationDirectory')
            filename = fullfile(options.DestinationDirectory, filename);
        else
            msgbox('Destination directory for saving masks was not provided!', 'Error!', 'error', 'modal');
            return;
        end
    end
end

% define output filename
if isempty(filename)
    fnOut = obj.maskImgFilename;
    if isempty(fnOut)
        fnOut = obj.meta('Filename');
        if isempty(strfind(fnOut, '/')) && isempty(strfind(fnOut, '\')) && isfield(options, 'DestinationDirectory') %#ok<STREMP>
            fnOut = fullfile(options.DestinationDirectory, fnOut);
        end
        [path, fnOut] = fileparts(fnOut);
        fnOut = ['Mask_' fnOut '.mask'];
        fnOut = fullfile(path, fnOut);
    end
    
    if isempty(fnOut) && isfield(options, 'DestinationDirectory')
        fnOut = fullfile(options.DestinationDirectory, 'Mask_.mask');
    elseif isempty(fnOut)
        fnOut = [];
    end
    
    if ~isempty(fnOut)
        extFilter = '*.mask';
        
        formatListPosition = find(ismember(Formats(:,1), extFilter));
        if isempty(formatListPosition)
            Formats = Formats([end 1:end-1],:);
        else
            formatListPosition = formatListPosition(1);
            selectedFilter = Formats(formatListPosition, :);
            Formats(formatListPosition, :) = [];
            Formats = [selectedFilter; Formats];
        end
        dotPosition = strfind(fnOut, '.');
        if ~isempty(dotPosition)
            fnOut = [fnOut(1:dotPosition(end)) 'mask'];
        else
            fnOut = [fnOut '.mask'];
        end
    end
    
    [fn, pathStr, FilterIndex] = uiputfile(Formats, 'Save mask...', fnOut); %...
    if isequal(fn, 0); return; end % check for cancel
    
    if strcmp(Formats{FilterIndex,2}, 'All Files (*.*)')
        warndlg(sprintf('!!! Warning !!!\n\nThe output format was not selected!'), 'Missing output format', 'modal');
        return;
    end
    options.Format = Formats{FilterIndex, 2};
    fnOut = fullfile(pathStr, fn);
else
    [pathStr, fnameStr, ext] = fileparts(filename);
    extFilter = ['*' ext];
    
    if ~isfield(options, 'Format')  % detect output format
        formatListPosition = find(ismember(Formats(1:end-1,1), extFilter));
        if isempty(formatListPosition); msgbox('The output format can''t be identified!', 'Error!', 'error', 'modal'); return; end
        formatListPosition = formatListPosition(1);
        options.Format = Formats{formatListPosition, 2};
    else
        if ismember(options.Format, Formats(:,2)) == 0
            errMsg = sprintf('The provided output format "%s" is not valid\n\nUse one of these options:\n%s', options.Format);
            for i=1:size(Formats, 1)-1
                errMsg = sprintf('%s%s\n', errMsg, Formats{i,2});
            end
            
            msgbox(errMsg, 'Error!', 'error', 'modal');
            return;
        end
    end
    fnOut = filename;
end

tic
warning('off', 'MATLAB:handle_graphics:exceptions:SceneNode');
if strcmp(options.Format, 'Matlab format (*.mask)')
    if options.showWaitbar
        wb = waitbar(0, sprintf('%s\nPlease wait...', fnOut), 'Name', 'Saving the mask', 'WindowStyle', 'modal');
        wb.Children.Title.Interpreter = 'none';
        drawnow;
    end
    maskImg = obj.getData('mask', 4, NaN);
    if options.showWaitbar; waitbar(0.4, wb); end
    save(fnOut, 'maskImg', '-v7.3');
    if options.showWaitbar; waitbar(1, wb); delete(wb); end
else
    [path, filename, ext] = fileparts(fnOut);
    ext = lower(ext);
    t1 = obj.slices{5}(1);
    t2 = t1;
    
    if obj.time > 1
        button = 'Save as series of 3D datasets';
        if ~ismember(ext, {'.xml', '.h5'})
            if options.silent == 0
                button = questdlg(sprintf('!!! Warning !!!\nIt is not possible to save 4D dataset into a single file!\n\nHowever it is possible to save the currently shown Z-stack, or to make a series of files'), ...
                    'Save mask', 'Save as series of 3D datasets', 'Save the currently shown Z-stack', 'Cancel', 'Save as series of 3D datasets');
                if strcmp(button, 'Cancel'); return; end
            end
        end
        if strcmp(button, 'Save as series of 3D datasets')
            t1 = 1;
            t2 = obj.time;
        else
            t1 = obj.getCurrentTimePoint();
            t2 = t1;
        end
    end
    
    showLocalWaitbar = 0;
    if options.showWaitbar
        if t1 ~= t2
            showLocalWaitbar = 1;
            wb = waitbar(0, sprintf('Saving %s\nPlease wait...', options.Format), 'Name', 'Saving images...', 'WindowStyle', 'modal');
            wb.Children.Title.Interpreter = 'none';
            drawnow;
            dT = t2-t1+1;
        end
    end
    
    for t=t1:t2
        if t1~=t2   % generate filename
            fnOutLocal = generateSequentialFilename(filename, t, t2-t1+1, ext);
        else
            fnOutLocal = [filename ext];
        end
        
        getDataOptions.t = [t t];
        mask = obj.getData('mask', 4, NaN, getDataOptions);
        
        if options.showWaitbar
            showWaitbar = ~showLocalWaitbar;
        else
            showWaitbar = 0;
        end % show or not waitbar in bitmap2amiraMesh
        
        switch options.Format
            case 'Amira mesh binary RLE compression SLOW (*.am)'     % Amira mesh binary RLE compression
                bb = obj.getBoundingBox();
                pixStr = obj.pixSize;
                pixStr.minx = bb(1);
                pixStr.miny = bb(3);
                pixStr.minz = bb(5);
                bitmap2amiraLabels(fullfile(path, fnOutLocal), mask, 'binaryRLE', pixStr, options.MaskColor, cellstr('Mask'), 1, showWaitbar);
            case 'Amira mesh binary (*.am)'     % Amira mesh binary
                bb = obj.getBoundingBox();
                pixStr = obj.pixSize;
                pixStr.minx = bb(1);
                pixStr.miny = bb(3);
                pixStr.minz = bb(5);
                bitmap2amiraLabels(fullfile(path, fnOutLocal), mask, 'binary', pixStr, options.MaskColor, cellstr('Mask'), 1, showWaitbar);
            case {'Hierarchical Data Format (*.h5)', 'Hierarchical Data Format with XML header (*.xml)'} % hdf5 format
                if t==t1    % getting parameters for saving dataset
                    if options.silent == 0
                        HDFoptions = mibSaveHDF5Dlg(obj);
                    else
                         HDFoptions.Format = 'matlab.hdf5';
                         HDFoptions.SubSampling = [1;1;1];
                         HDFoptions.ChunkSize = [min([64 obj.height]); min([64 obj.width]); min([64 obj.depth])];
                         HDFoptions.Deflate = 0;
                         HDFoptions.xmlCreate = 1;
                    end
                    if isempty(HDFoptions)
                        if showLocalWaitbar; delete(wb); end
                        return;
                    end
                    
                    if strcmp(HDFoptions.Format, 'bdv.hdf5')
                        warndlg('Export of masks in using the Big Data Viewer format is not implemented!');
                        if showLocalWaitbar; delete(wb); end
                        return;
                    end
                    HDFoptions.filename = fnOut;
                    ImageDescription = obj.meta('ImageDescription');  % initialize ImageDescription
                end
                
                % permute dataset if needed
                if strcmp(HDFoptions.Format, 'bdv.hdf5')
                    % permute image to swap the X and Y dimensions
                    %mask = permute(mask, [2 1 5 3 4]);
                else
                    % permute image to add color dimension to position 3
                    mask = permute(mask, [1 2 4 3]);
                end
                
                if t==t1    % updating parameters for saving dataset
                    HDFoptions.height = size(mask, 1);
                    HDFoptions.width = size(mask, 2);
                    HDFoptions.colors = 1;
                    if strcmp(HDFoptions.Format, 'bdv.hdf5')
                        %options.depth = size(mask,4);
                    else
                        HDFoptions.depth = size(mask, 4);
                    end
                    HDFoptions.time = obj.time;
                    HDFoptions.pixSize = obj.pixSize;    % !!! check .units = 'um'
                    HDFoptions.showWaitbar = ~showLocalWaitbar;        % show or not waitbar in data saving function
                    HDFoptions.lutColors = options.MaskColor;    % store LUT colors for materials
                    HDFoptions.ImageDescription = ImageDescription;
                    HDFoptions.DatasetName = filename;
                    HDFoptions.overwrite = 1;
                    HDFoptions.maskMaterialNames = {'Mask'}; % names for materials
                    % saving xml file if needed
                    if HDFoptions.xmlCreate
                        saveXMLheader(HDFoptions.filename, HDFoptions);
                    end
                end
                HDFoptions.t = t;
                switch HDFoptions.Format
                    case 'bdv.hdf5'
                        HDFoptions.pixSize.units = sprintf('\xB5m'); % '?m';
                        saveBigDataViewerFormat(HDFoptions.filename, mask, HDFoptions);
                    case 'matlab.hdf5'
                        HDFoptions.order = 'yxczt';
                        image2hdf5(fullfile(path, [filename '.h5']), mask, HDFoptions);
                end
            case 'TIF format (*.tif)'
                ImageDescription = {obj.meta('ImageDescription')};
                resolution(1) = obj.meta('XResolution');
                resolution(2) = obj.meta('YResolution');
                if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                    savingOptions = struct('Resolution', resolution, 'overwrite', 1, 'Saving3d', NaN, 'cmap', NaN);
                    if isfield(options, 'Saving3DPolicy')
                        if strcmp(options.Saving3DPolicy, '3D stack')
                            savingOptions.Saving3d = 'multi';
                        else
                            savingOptions.Saving3d = 'sequence';
                        end
                    end
                end
                savingOptions.showWaitbar = showWaitbar;  % show or not waitbar in ib_image2tiff
                mask = reshape(mask,[size(mask,1) size(mask,2) 1 size(mask,3)]);
                [result, savingOptions] = mibImage2tiff(fullfile(path, fnOutLocal), mask, savingOptions, ImageDescription);
        end
        if showLocalWaitbar;    waitbar(t/dT, wb);    end
    end
    if showLocalWaitbar; delete(wb); end
end
obj.maskImgFilename = fnOut;
disp(['mask: ' fnOut ' has been saved']);
toc;