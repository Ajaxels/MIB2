function [result, options] = mibImage2tiff(filename, imageS, options, ImageDescription)
% function [result, options] = mibImage2tiff(filename, imageS, options, ImageDescription)
% Save image in TIF format, 2D slices or 3D stacks
%
% Parameters:
% filename: filename for the output file
% imageS: dataset to save [1:height, 1:width, 1:color_channels, 1:no_stacks] or [1:height, 1:width, 1:no_stacks]
% options: a structure with optional parameters
% - .cmap: a color map for indexed images, otherwise @em NaN
% - .Saving3d: ''multi'' - save all stacks into a single file
%              ''sequence'' - generate a sequence of files
%              @em NaN -> type will be asked
% - .overwrite, if @b 1 do not check whether file with provided filename already exists
% - .Resolution - vector with two elements for X and Y resolution
% - .Compression: ''none'', ''lzw'', ''packbits''
% - .showWaitbar: show a progress bar, @b 1 - on, @b 0 - off
% - .SliceName: [optional] A cell array with filenames without path
% - .useOriginals: when SliceName is provided and useOriginals==1, those filenames are used
% ImageDescription: - a cell string, or array of cells
%
% Return values:
% result: result of the function: @b 1 - success, @b 0 - fail
% options: structure with used options

% Copyright (C) 19.07.2010 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 04.08.2010, IB, compatible with indexed images
% 12.10.2011, IB, show/not show waitbar option, new input via structures
% 17.04.2014, IB, modified to allow saving files using the original filename
% 11.02.2016, IB, added options to the return values

% example:
%   ib_image2tiff(file_name, image_var, options, 'test');

%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
result = 0;
if nargin < 2
    error('Please provide filename and image!');
end
if nargin > 4
    error('Outdated syntax, fix it!');
end

if nargin < 4
    ImageDescription = cellstr('');
end
if ischar(ImageDescription)
    ImageDescription = cellstr(ImageDescription);
end
if nargin < 3
    options.showWaitbar = 1;
    options.Compression = 'lzw';
    options.Resolution = [72 72];
    options.overwrite = 0;
    options.Saving3d = NaN;
    options.cmap = NaN;
end

if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end
if ~isfield(options, 'Compression'); options.Compression = 'lzw'; end
if ~isfield(options, 'Resolution'); options.Resolution = [72 72]; end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'Saving3d'); options.Saving3d = NaN; end
if ~isfield(options, 'cmap'); options.cmap = NaN; end

if isempty(options.Resolution); options.Resolution = [72 72]; end

if isnan(options.Saving3d)
    choice = questdlg('Would you like to save it as a 3D-tif or as a sequence of 2D-tif files?','Save as...','3D-TIF','Sequence of 2D files','Cancel','3D-TIF');
    switch choice
        case 'Cancel'
            disp('Cancelled!')
            return;
        case '3D-TIF'
            options.Saving3d = 'multi';
        case 'Sequence of 2D files'
            options.Saving3d = 'sequence';
    end
end

if options.overwrite == 0
    if exist(filename, 'file') == 2
        reply = questdlg(sprintf('!!! Warning !!!\n\n The file alreadt exists! Overwrite?'),'Overwrite', 'Overwrite', 'Cancel', 'Cancel');
        if strcmp(reply, 'Cancel'); return; end
    end
end

% if numel(size(imageS)) == 3 && size(imageS,3) ~= 3
%     imageS = reshape(imageS,size(imageS,1), size(imageS,2), 1, size(imageS,3));
% end

%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 

% reform image description - that each frame will have it
if numel(ImageDescription) < size(imageS,4) && numel(ImageDescription) > 0
    ImageDescription = repmat(ImageDescription(1),size(imageS,4),1);
elseif numel(ImageDescription) == 0
    ImageDescription = repmat(cellstr(''),size(imageS,4),1);
end

if isnan(options.cmap)  % grayscale or rgb image
    if size(imageS,3) == 2
        imageS(:,:,3,:) =  zeros(size(imageS(:,:,2,:)));
    elseif size(imageS,3) > 3
        msgbox(sprintf('Data with more than 3 components not supported for TIFF files\n\nPlease use AmiraMesh format instead!'))
        return;
    end
end

files_no = size(imageS, 4);
if options.showWaitbar
    wb = waitbar(0,sprintf('%s\nPlease wait...',filename),'Name','Saving images','WindowStyle','modal');
    set(findall(wb,'type','text'),'Interpreter','none');
    waitbar(0, wb);
end
if strcmp(options.Saving3d,'multi')
    if isnan(options.cmap)  % grayscale or rgb image
        imwrite(squeeze(imageS(:,:,:,1)),filename,'tif','WriteMode','overwrite','Description',cell2mat(ImageDescription(1)),'Resolution',options.Resolution,'Compression',options.Compression);
        for num = 2:files_no
            imwrite(squeeze(imageS(:,:,:,num)),filename,'tif','WriteMode','append','Description',cell2mat(ImageDescription(num)),'Resolution',options.Resolution,'Compression',options.Compression);
            if options.showWaitbar; waitbar(num/files_no,wb); end
        end
    else    % indexed image
        imwrite(imageS(:,:,:,1),options.cmap,filename,'tif','Compression','lzw','WriteMode','overwrite','Description',cell2mat(ImageDescription(1)),'Resolution',options.Resolution,'Compression',options.Compression);
        for num = 2:files_no
            imwrite(imageS(:,:,:,num),options.cmap,filename,'tif','Compression','lzw','WriteMode','append','Description',cell2mat(ImageDescription(num)),'Resolution',options.Resolution,'Compression',options.Compression);
            if options.showWaitbar; waitbar(num/files_no,wb); end
        end
    end
    options.SliceName{1} = filename;
elseif strcmp(options.Saving3d,'sequence')
    sequentialFn = 1;
    if isfield(options, 'SliceName') && numel(options.SliceName) > 1
        if isfield(options, 'useOriginals')
            if options.useOriginals == 1
                sequentialFn = 0;
            else
                sequentialFn = 1;
            end
        else
            choice = questdlg('Would you like to use original or sequential filenaming?','Save as TIF...','Original','Sequential','Cancel','Sequential');
            switch choice
                case 'Cancel'
                    disp('Cancelled!')
                    if options.showWaitbar; delete(wb); end
                    return;
                case 'Original'
                    sequentialFn = 0;
                case 'Sequential'
                    sequentialFn = 1;
            end
        end
    end
    
    [pathstr, name] = fileparts(filename);
    if sequentialFn     % generate sequential filenames
        for i = 1:files_no
            options.SliceName{i} = fullfile(pathstr, generateSequentialFilename(name, i, files_no));
        end
    else                % use original filenames
        % remove existing extension
        for i=1:numel(options.SliceName)
            [~, options.SliceName{i}] = fileparts(options.SliceName{i});
        end
        
        % find duplicates in the filenames
        %for i=1:numel(options.SliceName)
        i=1;
        while i <= numel(options.SliceName)
            duplicatesNo = sum(cell2mat((strfind(options.SliceName(:), options.SliceName{i}))));
            if duplicatesNo > 1   % unique filename is found
                for j=i:i+duplicatesNo-1
                    options.SliceName{j} = generateSequentialFilename(options.SliceName{j}, j-i+1, duplicatesNo);
                end
                i = i + duplicatesNo;
            else
                options.SliceName{i} = [options.SliceName{i} '.tif'];
                i = i + 1;
            end
        end
        
        % generate full path
        for i=1:files_no
            options.SliceName{i} = fullfile(pathstr, options.SliceName{i});
        end
    end
    
    
    for num = 1:files_no
        if isnan(options.cmap)  % grayscale or rgb image
            imwrite(imageS(:,:,:,num),options.SliceName{num},'tif','Compression',options.Compression,'Description',cell2mat(ImageDescription(num)),'Resolution',options.Resolution);
        else            % indexed image
            imwrite(imageS(:,:,:,num),options.cmap,options.SliceName{num},'tif','Compression',options.Compression,'Description',cell2mat(ImageDescription(num)),'Resolution',options.Resolution);
        end
        if options.showWaitbar; waitbar(num/files_no,wb); end
    end
else
    error('Error: wrong saving type, use ''multi'' or ''sequence''');
end
if options.showWaitbar; waitbar(1); end
disp(['image2tiff: ' options.SliceName{1} ' was/were created!']);
if options.showWaitbar; delete(wb); end
set(0, 'DefaulttextInterpreter', curInt); 
result = 1;
end

% supporting function to generate sequential filenames
function fn = generateSequentialFilename(name, num, files_no)
% name - a filename template
% num - sequential number to generate
% files_no - total number of files in sequence
if files_no == 1
    fn = [name '.tif'];
elseif files_no < 100
    fn = [name '_' sprintf('%02i',num) '.tif'];
elseif files_no < 1000
    fn = [name '_' sprintf('%03i',num) '.tif'];
elseif files_no < 10000
    fn = [name '_' sprintf('%04i',num) '.tif'];
elseif files_no < 100000
    fn = [name '_' sprintf('%05i',num) '.tif'];
elseif files_no < 1000000
    fn = [name '_' sprintf('%06i',num) '.tif'];
elseif files_no < 10000000
    fn = [name '_' sprintf('%07i',num) '.tif'];    
end
end