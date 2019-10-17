function fnOut = saveImageAsDialog(obj, filename, options)
% function fnOut = saveImageAsDialog(obj, filename, options)
% save image to a file
%
% Parameters:
% filename: [@em optional] a string with filename, when empty a dialog for
% filename selection is shown; when the filename is provided its extension defines the output format, unless the
% format is provided in the options structure
% options: an optional structure with additional parameters
% @li .Format - string with the output format, as in the Formats variable below, for example 'Amira Mesh binary file sequence (*.am)'
% @li .FilenameGenerator - string, when ''Use original
% filename'' -> use original filenames of the loaded datasets; ''Use
% sequential filename'' -> the filenames are generated in sequence using
% the first filename of the loaded dataset as template
% @li .DestinationDirectory - string, with destination directory, if filename has no full path
% @li .Saving3DPolicy - string, [TIF only] save images as 3D TIF file or as a sequence of 2D files
% @li .showWaitbar - logical, show or not the waitbar
% @li .silent  - logical, do not ask any questions and use default parameters
%
% Return values:
% fnOut: a string with the output filename

% Copyright (C) 26.03.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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

Formats = {'*.am',  'Amira Mesh binary (*.am)';...
    '*.am',  'Amira Mesh binary file sequence (*.am)';...
    '*.jpg',  'Joint Photographic Experts Group (*.jpg)'; ...
    '*.h5',   'Hierarchical Data Format (*.h5)'; ...
    '*.mrc',  'MRC format for IMOD (*.mrc)'; ...
    '*.nrrd',  'NRRD Data Format (*.nrrd)'; ...
    '*.png',   'Portable Network Graphics (*.png)'; ...
    '*.tif',  'TIF format LZW compression (*.tif)'; ...
    '*.tif',  'TIF format uncompressed (*.tif)'; ...
    '*.xml',   'Hierarchical Data Format with XML header (*.xml)'; ...
    '*.*',  'All Files (*.*)'};

%    '*.tiff',  'OME-TIFF 5D (*.tiff)'; ...
%    '*.tiff',  'OME-TIFF 2D sequence (*.tiff)'; ...


if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end
if ~isfield(options, 'silent'); options.silent = false; end

if size(obj.img{1}, 1) < 1; msgbox('No image detected!', 'Error!', 'error', 'modal'); return; end

% check for destination directory
if ~isempty(filename)
    [pathStr, fnameStr, ext] = fileparts(filename);
    if isempty(pathStr)
        if isfield(options, 'DestinationDirectory')
            filename = fullfile(options.DestinationDirectory, filename);
        else
            msgbox('Destination directory was not provided!', 'Error!', 'error', 'modal');
            return;
        end
    end
end

% define output filename
if isempty(filename)
    fn_out = obj.meta('Filename');
    if isempty(strfind(fn_out, '/')) && isempty(strfind(fn_out, '\')) && isfield(options, 'DestinationDirectory') %#ok<STREMP>
        fn_out = fullfile(options.DestinationDirectory, fn_out);
    end
    if isempty(fn_out) && isfield(options, 'DestinationDirectory')
        fn_out = fullfile(options.DestinationDirectory, 'output.tif');
    elseif isempty(fn_out)
        fn_out = [];
    end
    if ~isempty(fn_out)
        [pathStr, fnameStr, ext] = fileparts(fn_out);
        extFilter = ['*' ext];
    
        formatListPosition = find(ismember(Formats(:,1), extFilter));
        if isempty(formatListPosition)
            Formats = Formats([end 1:end-1],:);
        else
            formatListPosition = formatListPosition(1);
            selectedFilter = Formats(formatListPosition, :);
            Formats(formatListPosition, :) = [];
            Formats = [selectedFilter; Formats];
        end
    end
    
    [filename, pathStr, FilterIndex] = uiputfile(Formats, 'Save image...',fn_out); %...
    if isequal(filename, 0); return; end % check for cancel
    
    % use this to ensure that the provided filename will be used
    %options.FilenameGenerator = 'Use sequential filename';
    
    if strcmp(Formats{FilterIndex,2}, 'All Files (*.*)')
        warndlg(sprintf('!!! Warning !!!\n\nThe output format was not selected!'), 'Missing output format', 'modal');
        return;
    end
    
    options.Format = Formats{FilterIndex, 2};
    
    % check update parameters of the dataset
    res = obj.updatePixSizeResolution();
    if res == 0; return; end   % cancel
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
end

t1 = 1;
t2 = obj.time;
if obj.time > 1 && isempty(strfind(options.Format, 'Hierarchical'))
    if options.silent == 0
        button = questdlg(sprintf('!!! Warning !!!\nIt is not possible to save 4D dataset into a single file using "%s"\nHowever,\n - it is possible to save a series of 3D files;\n - save the currently shown Z-stack;\n - or save 4D data using the HDF format (press Cancel and select Hierarchical Data Format during saving)', options.Format), ...
            'Save image','Save as series of 3D datasets','Save the currently shown Z-stack','Cancel','Save as series of 3D datasets');
        if strcmp(button, 'Cancel'); return; end
    else
        button = 'Save as series of 3D datasets';
    end
    if strcmp(button, 'Save as series of 3D datasets')
        t1 = 1;
        t2 = obj.time;
    else
        t1 = obj.slices{5}(1);
        t2 = t1;
    end
end

[~, filename, ext] = fileparts(filename);

pause(.1);
showLocalWaitbar = false;   % switch to show or not waitbar in this function
if t1 ~= t2
    showLocalWaitbar = options.showWaitbar;
    wb = waitbar(0,sprintf('Saving %s\nPlease wait...',options.Format),...
        'Name','Saving images...','WindowStyle','modal');
    dT = t2-t1+1;
end

% check naming of the files during saving of image sequence
if ismember(options.Format, ...
        {'Amira Mesh binary file sequence (*.am)', 'Joint Photographic Experts Group (*.jpg)', 'Portable Network Graphics (*.png)', ...
        'OME-TIFF 2D sequence (*.tiff)'})
    
    if ~isfield(options, 'FilenameGenerator')
        options.FilenameGenerator = 'Use sequential filename';
        if isKey(obj.meta, 'SliceName') && ...
                numel(obj.meta('SliceName')) == obj.depth && obj.time == 1
            
            exportChoice2D = questdlg('Would you like to use original or sequential filenaming?', 'Define naming', 'Use original filename', 'Use sequential filename', 'Cancel', 'Use sequential filename');
            if strcmp(exportChoice2D, 'Cancel'); return; end
            options.FilenameGenerator = exportChoice2D;
        end
    end
end

if ismember(options.Format, {'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'})
    if ~isfield(options, 'FilenameGenerator') && ~isfield(options, 'Saving3DPolicy')
        if obj.depth == 1
            options.Saving3DPolicy = '3D stack';
            options.FilenameGenerator = 'Use sequential filename';
        else
            prompts = {'Filename generator'; 'Multidimensional saving policy'};
            defAns = {{'Use original filename', 'Use sequential filename', 2}; ...
                {'3D stack', '2D sequence', 1}};
            dlgTitle = 'TIF saving settings';
            options.WindowStyle = 'normal';       % [optional] style of the window
            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end
            options.FilenameGenerator = answer{1};
            options.Saving3DPolicy = answer{2};
        end
    end
end

tic

for t=t1:t2
    if t1 ~= t2   % generate filename
        fnOut = generateSequentialFilename(filename, t, t2-t1+1, ext);
    else
        fnOut = [filename ext];
    end
    
    % get the obtain the image or keep it empty for the virtual mode
    % saving, used only for 'matlab.hdf5' options.Format
    if ismember(options.Format, {'Hierarchical Data Format (*.h5)', 'Hierarchical Data Format with XML header (*.xml)'}) && ...
            obj.Virtual.virtual == 1
        img = [];
    else
        %img = cell2mat(obj.getData3D('image', t, 4, 0, getDataOptions));
        getDataOptions.t = [t t];
        img = obj.getData('image', 4, 0, getDataOptions);    
    end
    
    switch options.Format
        case 'Amira Mesh binary (*.am)'    % am format
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                savingOptions = struct('overwrite', 1);
                savingOptions.colors = obj.lutColors;   % store colors for color channels 0-1;
                savingOptions.showWaitbar = ~showLocalWaitbar;  % show or not waitbar in bitmap2amiraMesh
                savingOptions.Saving3d = 'multi';    % save all stacks to a single file
            end
            bitmap2amiraMesh(fullfile(pathStr, fnOut), img, ...
                containers.Map(keys(obj.meta),values(obj.meta)), savingOptions);
        case 'Amira Mesh binary file sequence (*.am)'    % am format, as sequence of files
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                savingOptions = struct('overwrite', 1);
                savingOptions.colors = obj.lutColors;   % store colors for color channels 0-1;
                savingOptions.showWaitbar = ~showLocalWaitbar;  % show or not waitbar in bitmap2amiraMesh
                savingOptions.Saving3d = 'sequence';    % save as sequence of files
            end
            
            % generate filenames
            if strcmp(options.FilenameGenerator, 'Use original filename') && isKey(obj.meta, 'SliceName')
                if obj.time > 1
                    [~, savingOptions.SliceName] = cellfun(@fileparts, obj.meta('SliceName'), 'UniformOutput', false);
                    savingOptions.SliceName = cellfun(@strcat, savingOptions.SliceName, ...
                        repmat({sprintf('_T%03d', t)}, [numel(obj.meta('SliceName')), 1]), ...
                        repmat({ext}, [numel(obj.meta('SliceName')), 1]), 'UniformOutput', false);
                else
                    [~, savingOptions.SliceName] = cellfun(@fileparts, obj.meta('SliceName'), 'UniformOutput', false);
                    savingOptions.SliceName = cellfun(@strcat, savingOptions.SliceName, repmat({ext}, [numel(obj.meta('SliceName')), 1]), 'UniformOutput', false);
                end
            else    % Sequential
                if obj.time > 1
                    savingOptions.SliceName = arrayfun(@(i) generateSequentialFilename(sprintf('%s_T%03d', filename, t), i, size(img, 4), ext), 1:size(img, 4), 'UniformOutput', false)';
                else
                    savingOptions.SliceName = arrayfun(@(i) generateSequentialFilename(filename, i, size(img, 4), ext), 1:size(img, 4), 'UniformOutput', false)';
                end
            end
            
            bitmap2amiraMesh(fullfile(pathStr, fnOut), img, ...
                containers.Map(keys(obj.meta),values(obj.meta)), savingOptions);
        case {'Hierarchical Data Format (*.h5)', 'Hierarchical Data Format with XML header (*.xml)' }   % hdf5 format
            if t==t1    % getting parameters for saving dataset
                if options.silent == 0
                    optionsHDF = mibSaveHDF5Dlg(obj);
                    if isempty(optionsHDF)
                        if showLocalWaitbar; delete(wb); end
                        return;
                    end
                else
                    optionsHDF.Format = 'matlab.hdf5';
                    optionsHDF.SubSampling = [1;1;1];
                    optionsHDF.ChunkSize = [min([64 obj.height]); min([64 obj.width]); min([64 obj.depth])];
                    optionsHDF.Deflate = 0;
                    optionsHDF.xmlCreate = 1;
                end
                tic;
                %if strcmp(options.FilenameGenerator, 'Use original filename')
                %    SliceNames = obj.meta('SliceName');
                %    [~, filename, ext] = fileparts(SliceNames{1});
                %    optionsHDF.filename = fullfile(pathStr, [filename ext]);
                %else
                    optionsHDF.filename = fullfile(pathStr, [filename ext]);
                %end
                ImageDescription = obj.meta('ImageDescription');  % initialize ImageDescription
            end
            
            % permute dataset if needed
            if strcmp(optionsHDF.Format, 'bdv.hdf5')
                % permute image to swap the X and Y dimensions
                img = permute(img, [2 1 3 4 5]);
            end
            
            if t == t1    % updating parameters for saving dataset
                optionsHDF.height = obj.height;
                optionsHDF.width = obj.width;
                optionsHDF.colors = obj.colors;
                optionsHDF.depth = obj.depth;
                optionsHDF.time = obj.time;
                optionsHDF.pixSize = obj.pixSize;    % !!! check .units = 'um'
                optionsHDF.showWaitbar = ~showLocalWaitbar;        % show or not waitbar in data saving function
                optionsHDF.lutColors = obj.lutColors;    % store LUT colors for channels
                optionsHDF.ImageDescription = ImageDescription;
                optionsHDF.DatasetName = filename;
                optionsHDF.overwrite = 1;
                optionsHDF.DatasetType = 'image';
                optionsHDF.DatasetClass = obj.meta('imgClass');
                if obj.Virtual.virtual == 1 && strcmp(optionsHDF.Format, 'matlab.hdf5')
                    optionsHDF.mibImage = obj;
                end
                
                % saving xml file if needed
                if optionsHDF.xmlCreate
                    saveXMLheader(optionsHDF.filename, optionsHDF);
                end
            end
            
            optionsHDF.t = t;
            switch optionsHDF.Format
                case 'bdv.hdf5'
                    optionsHDF.pixSize.units = sprintf('\xB5m'); % '?m';
                    saveBigDataViewerFormat(optionsHDF.filename, img, optionsHDF);
                case 'matlab.hdf5'
                    image2hdf5(fullfile(pathStr, [filename '.h5']), img, optionsHDF);
            end
        case 'Joint Photographic Experts Group (*.jpg)'    % jpg format
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                savingOptions = struct('overwrite', 1,'Comment', obj.meta('ImageDescription'));
                if strcmp(obj.meta('ColorType'), 'indexed')
                    savingOptions.cmap = obj.meta('Colormap');
                else
                    savingOptions.cmap = NaN;
                end
                if options.silent == 0
                    prompt = {'Compression mode:'; 'Quality (0-100):'};
                    dlg_title = 'JPG Parameters';
                    defAns = {{'lossy','lossless'}; '90'};
                
                    answer = mibInputMultiDlg({mibPath}, prompt, defAns, dlg_title);
                    if isempty(answer); return; end
        
                    savingOptions.Compression = answer{1};
                    savingOptions.Quality = str2double(answer{2});
                else
                    savingOptions.Compression = 'lossless';
                    savingOptions.Quality = 90;
                end
                savingOptions.showWaitbar = ~showLocalWaitbar;
                
                % get list of filenames for slices
                if strcmp(options.FilenameGenerator, 'Use original filename') && isKey(obj.meta, 'SliceName')
                    SliceName = obj.meta('SliceName');
                    if numel(SliceName) == obj.depth
                        savingOptions.SliceName = SliceName; 
                    end
                end
            end
            mibImage2jpg(fullfile(pathStr, fnOut), img, savingOptions);
        case 'MRC format for IMOD (*.mrc)'    % MRC format
            if ~isfield(options, 'FilenameGenerator'); options.FilenameGenerator = 'Use sequential filename'; end
            if size(img,3) > 1
                errordlg(sprintf('!!! Error !!!\n\nIt is not possile to save %s images in the MRC format', class(img)), 'Wrong image class');
                return;
            end
            if strcmp(options.FilenameGenerator, 'Use original filename') && isKey(obj.meta, 'SliceName')
                SliceNames = obj.meta('SliceName');
                [~, filename, ext] = fileparts(SliceNames{1});
                savingOptions.volumeFilename = fullfile(pathStr, [filename '.mrc']);
            else
                savingOptions.volumeFilename = fullfile(pathStr, fnOut);
            end
            savingOptions.pixSize = obj.pixSize;
            savingOptions.showWaitbar = ~showLocalWaitbar;
            mibImage2mrc(img, savingOptions);
        case 'Portable Network Graphics (*.png)'    % PNG format
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                savingOptions = struct('overwrite', 1,'Comment', obj.meta('ImageDescription'),...
                    'XResolution', obj.meta('XResolution'), 'YResolution', obj.meta('YResolution'), ...
                    'ResolutionUnit', 'Unknown', 'Reshape', 0);
                if strcmp(obj.meta('ColorType'), 'indexed')
                    savingOptions.cmap = obj.meta('Colormap');
                else
                    savingOptions.cmap = NaN;
                end
                % get list of filenames for slices
                if strcmp(options.FilenameGenerator, 'Use original filename') && isKey(obj.meta, 'SliceName')
                    SliceName = obj.meta('SliceName');
                    if numel(SliceName) == obj.depth
                        savingOptions.SliceName = SliceName; 
                    end
                end
                savingOptions.showWaitbar = ~showLocalWaitbar;
            end
            mibImage2png(fullfile(pathStr, fnOut), img, savingOptions);
        case 'NRRD Data Format (*.nrrd)'   % PNG format
            if ~isfield(options, 'FilenameGenerator'); options.FilenameGenerator = 'Use sequential filename'; end
            savingOptions = struct('overwrite', 1);
            savingOptions.showWaitbar = ~showLocalWaitbar;
            bb = obj.getBoundingBox();
            if strcmp(options.FilenameGenerator, 'Use original filename') && isKey(obj.meta, 'SliceName')
                SliceNames = obj.meta('SliceName');
                [~, filename, ext] = fileparts(SliceNames{1});
                volumeFilename = fullfile(pathStr, [filename '.nrrd']);
            else
                volumeFilename = fullfile(pathStr, fnOut);
            end
            bitmap2nrrd(volumeFilename, img, bb, savingOptions);
        case {'OME-TIFF 5D (*.tiff)', 'OME-TIFF 2D sequence (*.tiff)'}   % OME.TIFF single file
            savingOptions.pixSize = obj.pixSize;
            savingOptions.showWaitbar = ~showLocalWaitbar;
            savingOptions.lutColors = obj.lutColors;    % store LUT colors for channels
            savingOptions.ImageDescription = {obj.meta('ImageDescription')};  % initialize ImageDescription;
            savingOptions.overwrite = 1;
            savingOptions.DatasetType = 'image';
            savingOptions.DimensionOrder = 'XYCZT';     % define dimensions order for the dataset
            if strcmp(options.Format, 'OME-TIFF 5D (*.tiff)')
                savingOptions.Saving3d = '5D'; % 'multi'' - save all stacks into a single file; ''sequence'' - generate a sequence of files
            else
                error('not yet implemented');
                savingOptions.Saving3d = '2D'; % 'multi'' - save all stacks into a single file; ''sequence'' - generate a sequence of files
                if strcmp(options.FilenameGenerator, 'Use original filename') && isKey(obj.meta, 'SliceName'); savingOptions.SliceName = obj.meta('SliceName'); end
            end
            
            %savingOptions.Compression = 'none'; % ''none'', ''lzw''
            %if obj.Virtual.virtual == 1 && strcmp(options.Format, 'matlab.hdf5')
            %    savingOptions.mibImage = obj;
            %end
            mibImage2ometiff(fullfile(pathStr, fnOut), img, savingOptions);
        otherwise    % tif format
            if exist('savingOptions', 'var') == 0   % define parameters for the first time use
                colortype = obj.meta('ColorType');
                if strcmp('TIF format LZW compression (*.tif)', options.Format)
                    compression = 'lzw';
                else
                    compression = 'none';
                end
                if strcmp(colortype,'indexed')
                    cmap = obj.meta('Colormap');
                else
                    cmap = NaN;
                end
                ImageDescription = {obj.meta('ImageDescription')};
                
                savingOptions = struct('Resolution', [obj.meta('XResolution') obj.meta('YResolution')],...
                    'overwrite', 1, 'Saving3d', NaN, 'cmap', cmap, 'Compression', compression);
                savingOptions.showWaitbar = ~showLocalWaitbar;
                if obj.depth == 1; savingOptions.Saving3d = 'multi'; end
                
                % get list of filenames for slices
                %if strcmp(options.FilenameGenerator, 'original'); savingOptions.SliceName = obj.meta('SliceName'); end
                if isKey(obj.meta, 'SliceName') && strcmp(options.FilenameGenerator, 'Use original filename')
                    savingOptions.SliceName = obj.meta('SliceName');
                end
            end
            if isfield(options, 'Saving3DPolicy')
                if strcmp(options.Saving3DPolicy, '3D stack')
                    savingOptions.Saving3d = 'multi';
                else
                    savingOptions.Saving3d = 'sequence';
                end
            end
            
            volumeFilename = fullfile(pathStr, fnOut);
            if strcmp(options.FilenameGenerator, 'Use original filename') && isKey(obj.meta, 'SliceName')
                if strcmp(options.Saving3DPolicy, '3D stack')
                    SliceNames = obj.meta('SliceName');
                    [~, filename, ext] = fileparts(SliceNames{1});
                    volumeFilename = fullfile(pathStr, [filename '.tif']);
                else
                    [~, filename] = fileparts(obj.meta('Filename'));
                    volumeFilename = fullfile(pathStr, [filename '.tif']);
                end
            end
            savingOptions.useOriginals = 0;
            if strcmp(options.FilenameGenerator, 'Use original filename')
                savingOptions.useOriginals = 1;
            end
            
            [result, savingOptions] = mibImage2tiff(volumeFilename, img, savingOptions, ImageDescription);
            if isfield(savingOptions, 'SliceName'); savingOptions = rmfield(savingOptions, 'SliceName'); end % remove SliceName field when saving series of 2D files
    end
    if showLocalWaitbar;        waitbar(t/dT, wb);    end
end
fnOut = fullfile(pathStr, fnOut);   % generate full filename

if showLocalWaitbar; delete(wb); end
toc;
end

% supporting function to generate sequential filenames
function fn = generateSequentialFilename(name, num, files_no, ext)
% name - a filename template
% num - sequential number to generate
% files_no - total number of files in sequence
% ext - string with extension
if files_no == 1
    fn = [name ext];
elseif files_no < 100
    fn = [name '_' sprintf('%02i',num) ext];
elseif files_no < 1000
    fn = [name '_' sprintf('%03i',num) ext];
elseif files_no < 10000
    fn = [name '_' sprintf('%04i',num) ext];
elseif files_no < 100000
    fn = [name '_' sprintf('%05i',num) ext];
elseif files_no < 1000000
    fn = [name '_' sprintf('%06i',num) ext];
elseif files_no < 10000000
    fn = [name '_' sprintf('%07i',num) ext];
end
end