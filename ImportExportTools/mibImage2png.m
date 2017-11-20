function result = mibImage2png(filename, imageS, options)
% function result = mibImage2png(filename, imageS, options)
% Save image in PNG format, 2D slices
%
% Parameters:
% filename: filename for the output file
% imageS: dataset to save [1:height, 1:width, 1:color_channels, 1:no_stacks] or [1:height, 1:width, 1:no_stacks]
% options: a structure with optional parameters
% - .overwrite, if @b 1 do not check whether file with provided filename already exists
% - .Comment: - a string with a comment
% - .cmap: a color map for indexed images, otherwise @em NaN
% - .showWaitbar: @b 1 - on, @b 0 - off, show a progress bar
% - .XResolution: A scalar indicating the number of pixels/unit in thehorizontal direction
% - .YResolution: A scalar indicating the number of pixels/unit in thevertical direction
% - .ResolutionUnit: Units for the resolution
% - .Reshape: a switch to reshape dataset before saving
% - .SliceName: [optional] A cell array with filenames without path
%
% Return values:
% result: result of the function: @b 1 - success, @b 0 - fail

% Copyright (C) 11.11.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% ver 1.01 - 17.04.2014, modified to allow saving files using the original filename

%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex

result = 0;
if nargin < 2
    error('Please provide filename and image!');
end
if nargin < 3
    options = struct('overwrite', 1,'Comment', 'Microscopy Image Browser'); 
end
if ~isfield(options, 'overwrite'); options.overwrite = 0;    end;
if ~isfield(options, 'Comment');     options.Comment = '';    end;
if ~isfield(options, 'cmap'); options.cmap = NaN;    end;
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1;    end;
if ~isfield(options, 'XResolution'); options.XResolution = 72;    end;
if ~isfield(options, 'YResolution'); options.YResolution = 72;    end;
if ~isfield(options, 'ResolutionUnit'); options.ResolutionUnit = 'Unknown';    end;
if ~isfield(options, 'Reshape'); options.Reshape = 1;    end;

if isempty(options.Comment); options.Comment = 'Microscopy Image Browser'; end;

if options.overwrite == 0
    if exist(filename,'file') == 2
        reply = input('File exists! Overwrite? [y/N]:','s');
        if ~strcmp(reply,'y'); disp('Cancel, nothing was saved!'); return; end;
    end;
end
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 

% reshape matrix if needed
if options.Reshape
    if numel(size(imageS)) == 3 && size(imageS,3) ~= 3
        imageS = reshape(imageS,size(imageS,1), size(imageS,2), 1, size(imageS,3));
    end
end

if size(imageS,3) == 2
    imageS(:,:,3,:) =  zeros(size(imageS(:,:,2,:)));
elseif size(imageS,3) > 3
    msgbox('Data with more than 3 components not supported for PNG files')
    return;
end

files_no = size(imageS,4);
if options.showWaitbar;
    wb = waitbar(0,sprintf('%s\nPlease wait...',filename),'Name','Saving images','WindowStyle','modal');
    waitbar(0, wb);
end;

sequentialFn = 1;
if isfield(options, 'SliceName')
%     choice = questdlg('Would you like to use original or sequential filenaming?','Save as PNG...','Original','Sequential','Cancel','Sequential');
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
            options.SliceName{i} = [options.SliceName{i} '.png'];
            i = i + 1;
        end
    end
    
    % generate full path
    for i=1:files_no
        options.SliceName{i} = fullfile(pathstr, options.SliceName{i});
    end
end

% saving images
for num = 1:files_no
    if isnan(options.cmap)  % grayscale or rgb image
        imwrite(imageS(:,:,:,num),options.SliceName{num}, 'png', 'Comment', options.Comment, ...
            'XResolution', options.XResolution,  'YResolution', options.YResolution, 'ResolutionUnit', options.ResolutionUnit);
    else            % indexed image
        imwrite(imageS(:,:,:,num),options.cmap,options.SliceName{num},'png', 'Comment', options.Comment,...
            'XResolution', options.XResolution,  'YResolution', options.YResolution, 'ResolutionUnit', options.ResolutionUnit);
    end
    if options.showWaitbar; waitbar(num/files_no,wb); end;
end

if options.showWaitbar; waitbar(1); end;
disp(['image2png: ' options.SliceName{1} ' was/were created!']);
if options.showWaitbar; delete(wb); end;
set(0, 'DefaulttextInterpreter', curInt); 
result = 1;
end

% supporting function to generate sequential filenames
function fn = generateSequentialFilename(name, num, files_no)
% name - a filename template
% num - sequential number to generate
% files_no - total number of files in sequence
if files_no == 1
    fn = [name '.png'];
elseif files_no < 100
    fn = [name '_' sprintf('%02i',num) '.png'];
elseif files_no < 1000
    fn = [name '_' sprintf('%03i',num) '.png'];
elseif files_no < 10000
    fn = [name '_' sprintf('%04i',num) '.png'];
elseif files_no < 100000
    fn = [name '_' sprintf('%05i',num) '.png'];
elseif files_no < 1000000
    fn = [name '_' sprintf('%06i',num) '.png'];
end
end