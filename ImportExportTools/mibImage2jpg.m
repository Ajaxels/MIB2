function result = mibImage2jpg(filename, imageS, options)
% function result = mibImage2jpg(filename, imageS, options)
% Save image in JPG format, 2D slices
%
% Parameters:
% filename: filename for the output file
% imageS: dataset to save [1:height, 1:width, 1:color_channels, 1:no_stacks] or [1:height, 1:width, 1:no_stacks]
% options: a structure with optional parameters
% - .overwrite, if @b 1 do not check whether file with provided filename already exists
% - .Comment: - a string with a comment
% - .showWaitbar: @b 1 - on, @b 0 - off, show a progress bar
% - .cmap: a color map for indexed images, otherwise @em NaN
% - .Compression: Specifies the type of compression used: ''lossy'' or ''lossless''
% - .Quality: A number between 0 and 100; higher numbers mean higherquality (less image degradation due to compression), but the resultingfile size is larger.
% - .SliceName: [optional] A cell array with filenames without path
%
% Return values:
% result: result of the function: @b 1 - success, @b 0 - fail

% Copyright (C) 10.05.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% ver 1.01 - 16.04.2014, modified to allow saving files using the original filename

%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 

result = 0;
if nargin < 2; error('Please provide filename and image!'); end
if nargin < 3; options = struct('overwrite', 1,'Comment', ''); end
if ~isfield(options, 'overwrite'); options.overwrite = 0;    end
if ~isfield(options, 'Comment');     options.Comment = '';    end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1;    end
if ~isfield(options, 'cmap'); options.cmap = NaN;    end

if options.overwrite == 0
    if exist(filename,'file') == 2
        reply = input('File exists! Overwrite? [y/N]:','s');
        if ~strcmp(reply,'y'); disp('Save image: cancelled!'); return; end
    end
end

%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 

% reshape matrix if needed
if numel(size(imageS)) == 3 && size(imageS,3) ~= 3
    imageS = reshape(imageS,size(imageS,1), size(imageS,2), 1, size(imageS,3));
end

if size(imageS,3) == 2
    imageS(:,:,3,:) =  zeros(size(imageS(:,:,2,:)));
elseif size(imageS,3) > 3
    msgbox('Data with more than 3 components not supported for JPG files')
    return;
end

if ~isfield(options, 'Compression') || ~isfield(options, 'Quality')
    prompt = {'Compression mode (lossy, lossless):','Quality (0-100):'};
    dlg_title = 'JPG Parameters';
    def = {'lossy','90'};
    answer = inputdlg(prompt,dlg_title,1,def);
    if isempty(answer); return; end
    options.Compression = answer{1};
    options.Quality = str2double(answer{2});
end

files_no = size(imageS,4);
if options.showWaitbar
    wb = waitbar(0,sprintf('%s\nPlease wait...',filename),'Name','Saving images','WindowStyle','modal');
    waitbar(0, wb);
end

sequentialFn = 1;
if isfield(options, 'SliceName')
%     choice = questdlg('Would you like to use original or sequential filenaming?','Save as JPEG...','Original','Sequential','Cancel','Sequential');
%     switch choice
%         case 'Cancel'
%             disp('Cancelled!')
%             return;
%         case 'Original'
%             sequentialFn = 0;
%         case 'Sequential'
%             sequentialFn = 1;
%     end
    sequentialFn = 0;
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
            options.SliceName{i} = [options.SliceName{i} '.jpg'];
            i = i + 1;
        end
    end
    
    % generate full path
    for i=1:files_no
        options.SliceName{i} = fullfile(pathstr, options.SliceName{i});
    end
end

if size(imageS(:,:,:,1),3) > 1 && ~strcmp(class(imageS), 'uint8') %#ok<STISA>
    if options.showWaitbar; delete(wb); end
    errordlg(sprintf('!!! Error !!!\n\nIt is not possile to save %s images as JPEGs', class(imageS)),'Wrong image class');
    return;
end

% saving images
for num = 1:files_no
    if isnan(options.cmap)  % grayscale or rgb image
        imwrite(imageS(:,:,:,num),options.SliceName{num}, 'jpg', 'Comment', options.Comment, 'Mode', options.Compression, 'Quality', options.Quality);
    else            % indexed image
        imwrite(imageS(:,:,:,num),options.cmap,options.SliceName{num},'jpg', 'Comment', options.Comment, 'Mode', options.Compression, 'Quality', options.Quality);
    end
    
    if options.showWaitbar; waitbar(num/files_no,wb); end
end

if options.showWaitbar; waitbar(1); end
disp(['image2jpg: ' options.SliceName{1} ' was/were created!']);
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
    fn = [name '.jpg'];
elseif files_no < 100
    fn = [name '_' sprintf('%02i',num) '.jpg'];
elseif files_no < 1000
    fn = [name '_' sprintf('%03i',num) '.jpg'];
elseif files_no < 10000
    fn = [name '_' sprintf('%04i',num) '.jpg'];
elseif files_no < 100000
    fn = [name '_' sprintf('%05i',num) '.jpg'];
elseif files_no < 1000000
    fn = [name '_' sprintf('%06i',num) '.jpg'];
elseif files_no < 10000000
    fn = [name '_' sprintf('%07i',num) '.jpg'];    
end
end
