function result = bitmap2amiraMesh(filename, bitmap, img_info, options)
% function result = bitmap2amiraMesh(filename, bitmap, img_info, options)
% Convert bitmap matrix to Amira Mesh binary format
%
% Parameters:
% filename: filename for Amira Mesh file
% bitmap: a dataset, [1:height, 1:width, 1:colors, 1:no_stacks]
% img_info: img_info 'containers.Map' from im_browser.m
% options: a structure with some optional parameters
% - .overwrite - if @b 1 do not check whether file with provided filename already exists
% - .showWaitbar - if @b 1 - show the wait bar, if @b 0 - do not show
% - .colors - [@em optional] - a matrix of colors for multiple color channels, format: [color channel][Red Green Blue] in
% range from 0-1. Applicable to the @em HxMultiChannelField3 type of data saving.
% - .Saving3d: ''multi'' - save all stacks into a single file
%              ''sequence'' - generate a sequence of files
% - .SliceName: [optional] a cell array with filenames without path
%
% Return values:
% result: result of the function run, @b 1 - success, @b 0 - fail

% % Copyright (C) 27.01.2012 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% ver 1.01 - 10.02.2012, memory performance improvement
% ver 1.02 - 07.11.2013, added .colors
% ver 1.03 - 17.09.2014, fix for saving parameters that are in structures
% ver 1.04 - 04.06.2018 save TransformationMatrix with AmiraMesh
% ver 1.05 - 22.01.2019 added saving of amira mesh files as 2D sequence

result = 0;
if nargin < 2
    error('Please provide filename, and bitmap matrix!');
end
if nargin < 3   % generate img_info
    img_info = [];
end
if isempty(img_info);  img_info = containers.Map('KeyType', 'char', 'ValueType', 'any'); end

if nargin < 4   
    options = struct();
    options.parameters.CoordType =  '"uniform"';
end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end
if ~isfield(options, 'Saving3d'); options.Saving3d = 'multi'; end
% overwrite lutColors in the img_info
if isfield(options, 'colors')
    img_info('lutColors') = options.colors;
end
if options.overwrite == 0
    if exist(filename,'file') == 2
        choice = questdlg('File exists! Overwrite?', 'Warning!', 'Continue','Cancel','No thank you');
        if ~strcmp(choice,'Continue'); disp('Canceled, nothing was saved!'); return; end
    end
end

if options.showWaitbar
  %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
  curInt = get(0, 'DefaulttextInterpreter'); 
  set(0, 'DefaulttextInterpreter', 'none'); 
  wb = waitbar(0,sprintf('%s\nPlease wait...',filename), 'Name', 'Saving images as Amira Mesh...', 'WindowStyle', 'modal');
  set(findall(wb, 'type', 'text'), 'Interpreter', 'none');
  waitbar(0, wb);
else
    wb = [];
end

if strcmp(options.Saving3d, 'multi')    % save dataset as a single stack
    saveAmFile(filename, bitmap, img_info, options, wb);
else    % save dataset as sequence of images
    [saveDir, saveFn, saveExt] = fileparts(filename);
    if ~isfield(options, 'SliceName') || numel(options.SliceName) ~= size(bitmap, 4)
        options.SliceName = arrayfun(@(i) generateSequentialFilename(saveFn, i, size(bitmap, 4), saveExt), 1:size(bitmap, 4), 'UniformOutput', false)';
    end
    
    for fnId = 1:size(bitmap, 4)
        saveAmFile(fullfile(saveDir, options.SliceName{fnId}), bitmap(:,:,:,fnId), img_info, options, wb);
    end
end

disp(['bitmap2amiraMesh: ' filename ' was created!']);
result = 1;
if options.showWaitbar; set(0, 'DefaulttextInterpreter', curInt); delete(wb); end
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

function saveAmFile(filename, bitmap, img_info, options, wb)

HxMultiChannelField3 = 0;
%if size(bitmap,3)==2 || size(bitmap,3)>3 % save as HxMultiChannelField3
if size(bitmap, 3) > 1 % save as HxMultiChannelField3
    HxMultiChannelField3 = 1;
end

fid = fopen(filename, 'w');
% saving the file type into header
fprintf(fid,'# AmiraMesh BINARY-LITTLE-ENDIAN 2.1\n\n\n');

% saving the header
fprintf(fid,'define Lattice %d %d %d\n\n', size(bitmap,2), size(bitmap,1), size(bitmap,4));
fprintf(fid,'Parameters {\n');

if isKey(img_info,'Content'); remove(img_info,'Content'); end
if isKey(img_info,'BoundingBox'); remove(img_info,'BoundingBox'); end
if isKey(img_info,'CoordType'); remove(img_info,'CoordType'); end
if isKey(img_info,'SliceName'); remove(img_info,'SliceName'); end  % remove slice name, because it is a cell array

fields = keys(img_info);
fprintf(fid,'\tim_browser {\n');
for fieldIdx = 1:numel(fields)
    % modify keys names, i.e. remove spaces and other
    % special characters, to be compatible with AmiraMesh
    % format
    currKey = regexprep(fields{fieldIdx},'[_%! ()[]{}/|\\#?.,]', '_');
    currKey = strrep(currKey, sprintf('\xC5'), 'A');    % replace Angstrem with A
    currKey = strrep(currKey, sprintf('\xB5'), 'u');    % replace mu with u
    
    if isstruct(img_info(fields{fieldIdx}))
        extraFields = fieldnames(img_info(fields{fieldIdx}));
        for extraFieldId = 1:numel(extraFields)
            currKey2 = regexprep(extraFields{extraFieldId},'[_%! ()[]{}/|\\#?.,]', '_');
            currKey2 = strrep(currKey2, sprintf('\xC5'), 'A');   % replace Angstrem with A
            currKey2 = strrep(currKey2, sprintf('\xB5'), 'u');   % replace mu with u
        
            if isstruct(img_info(fields{fieldIdx}).(extraFields{extraFieldId})) || numel(img_info(fields{fieldIdx}).(extraFields{extraFieldId})) > 1
                fprintf(fid, '\t\t%s_%s skipped,\n',currKey, currKey2);
            elseif ~ischar(img_info(fields{fieldIdx}).(extraFields{extraFieldId}))
                fprintf(fid, '\t\t%s_%s %s,\n',currKey, currKey2, num2str(img_info(fields{fieldIdx}).(extraFields{extraFieldId})));
            else
                fprintf(fid, '\t\t%s_%s %s,\n',currKey, currKey2, img_info(fields{fieldIdx}).(extraFields{extraFieldId}));
            end
        end
    elseif iscell(img_info(fields{fieldIdx}))
        continue;
    elseif ~ischar(img_info(fields{fieldIdx})) && ~isa(img_info(fields{fieldIdx}), 'containers.Map')
        if numel(img_info(fields{fieldIdx})) == 1 
            fprintf(fid, '\t\t%s %s,\n', currKey, num2str(img_info(fields{fieldIdx})));    
        else
            fprintf(fid, '\t\t%s %s,\n',currKey ,sprintf('"%s"', mat2str(img_info(fields{fieldIdx}))));    
        end
    elseif ~isa(img_info(fields{fieldIdx}), 'containers.Map')
        fprintf(fid, '\t\t%s "%s",\n',currKey ,img_info(fields{fieldIdx}));
    end
end
fprintf(fid,'\t}\n');

if HxMultiChannelField3
    for ch = 1:size(bitmap,3)
        fprintf(fid, '\tChannel%d {\n',ch);
        fieldName = sprintf('Channel%d_DataWindow', ch);
        if isKey(img_info, fieldName)
            fprintf(fid, '\t\tDataWindow %s,\n',img_info(fieldName));
        else
            fprintf(fid, '\t\tDataWindow %d %d,\n', min(min(min(bitmap(:,:,ch,:)))), max(max(max(bitmap(:,:,ch,:)))) );
        end
        fieldName = sprintf('Channel%d_Color', ch);
        if isKey(img_info, 'lutColors')
            lutColors = img_info('lutColors');
            fprintf(fid, '\t\tColor %f %f %f\n', lutColors(ch,1), lutColors(ch,2), lutColors(ch,3));
        elseif isKey(img_info, fieldName)
            fprintf(fid, '\t\tColor %s\n', img_info(fieldName));
        else
            if isfield(options, 'colors')
                fprintf(fid, '\t\tColor %f %f %f\n', options.colors(ch,1), options.colors(ch,2), options.colors(ch,3));
            else
                fprintf(fid, '\t\tColor 0 1 0\n');
            end
        end
            fprintf(fid, '\t}\n');
    end
    fprintf(fid,'\tContentType "HxMultiChannelField3",\n');
else
    if isa(bitmap(1), 'uint8')
        imgClass = 'byte';
    else
        imgClass = 'ushort';
    end
    fprintf(fid,'\tContent "%dx%dx%d %s, uniform coordinates",\n', size(bitmap,2), size(bitmap,1), size(bitmap,4), imgClass);
end

bb = [0 max([size(bitmap,2) 2])-1 0 max([size(bitmap,1) 2])-1 0 max([size(bitmap,4) 2])-1];
if isKey(img_info, 'ImageDescription')
    curr_text = img_info('ImageDescription');
    bb_info_exist = strfind(curr_text,'BoundingBox');
    if bb_info_exist == 1   % use information from the BoundingBox parameter for pixel sizes if it is exist
        spaces = strfind(curr_text,' ');
        if numel(spaces) < 7; spaces(7) = numel(curr_text); end
        tab_pos = strfind(curr_text,sprintf('\t'));
        pos = min([spaces(7) tab_pos]);
        bb = str2num(curr_text(spaces(1):pos)); %#ok<ST2NM>
    end
end
fprintf(fid,'\tBoundingBox %s,\n', num2str(bb));
fprintf(fid,'\tCoordType "uniform"');
if isKey(img_info, 'TransformationMatrix')    % save transformation matrix
    fprintf(fid,'\tTransformationMatrix %s\n', num2str(img_info('TransformationMatrix')));
else
    fprintf(fid,'\n');
end
fprintf(fid,'}\n\n');

if isa(bitmap(1), 'uint8')
    imgClass = 'byte';
else
    imgClass = 'ushort';
end

if options.showWaitbar; waitbar(.05,wb); end
maxZ = size(bitmap,4);

if size(bitmap, 3) == 1  % grayscale images
    fprintf(fid,'Lattice { %s Data } @1\n\n', imgClass);
    fprintf(fid,'# Data section follows\n');
    fprintf(fid,'@1\n');
    
    for zIndex = 1:maxZ
        img = bitmap(:,:,1,zIndex);
        img = reshape(permute(img,[3 2 1]),1,[])';
        fwrite(fid, img, class(img), 0, 'ieee-le');  
        if options.showWaitbar && mod(zIndex, ceil(maxZ/20))==0
            waitbar(zIndex/maxZ, wb);
        end
    end
% elseif size(bitmap,3) == 3  % RGB images + Alpha
%     fprintf(fid,'Lattice { %s[4] Data } @1\n\n', imgClass);
%     fprintf(fid,'# Data section follows\n');
%     fprintf(fid,'@1\n');
%     width = size(bitmap,2);
%     height = size(bitmap,1);
%     % reshape the matrix into a vector
%     for zIndex = 1:maxZ
%         img = bitmap(:,:,:,zIndex);
%         img(:,:,4,:) = zeros(height,width,1); % add alpha channel
%         img = reshape(permute(img,[3 2 1]),1,[])';
%         fwrite(fid, img, class(img), 0, 'ieee-le');  
%         if options.showWaitbar && mod(zIndex, ceil(maxZ/20))==0;
%             waitbar(zIndex/maxZ, wb);
%         end
%     end
else
    maxIndex = maxZ * size(bitmap,3);
    index = 1;
    for ch = 1:size(bitmap,3)
        fprintf(fid,'Lattice { %s Data%d } @%d\n', imgClass, ch, ch);
    end
    fprintf(fid,'\n');
    fprintf(fid,'# Data section follows');
    for ch = 1:size(bitmap,3)
        fprintf(fid,'\n');
        fprintf(fid,'@%d\n', ch);
        for zIndex = 1:maxZ
            img = bitmap(:,:,ch,zIndex);
            img = reshape(permute(img,[3 2 1]),1,[])';
            fwrite(fid, img, class(img), 0, 'ieee-le');
            if options.showWaitbar && mod(index, ceil(maxIndex/20))==0
                waitbar(index/maxIndex, wb);
            end
        index = index + 1;    
        end
    end
end
fprintf(fid,'\n');
fclose(fid);
end