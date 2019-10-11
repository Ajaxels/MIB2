function [bitmap, par] = amiraMesh2bitmap(filename, options)
% function [bitmap, par] = amiraMesh2bitmap(filename, options)
% Converts Amira Mesh to bitmap matrix [1:height, 1:width, 1:colors, 1:no_stacks]
%
% Parameters:
% filename: (@em optional), a filename of amira mesh file, when omitted a file selection dialog is started.
% options: a structure with extra options
% - .hWaitbar -> handles to the existing waitbar
% - .maxZ -> maximal number of z-slices in the dataset
% - .depth_start - > [@em optional], to take only specified sections
% - .depth_end - > [@em optional], to take only specified sections
% - .depth_step -> [@em optional], Z-step to take not all sections
% - .xy_step -> [@em optional], XY-step, i.e. binning factor
% - .resizeMethod -> [@em optional], resize Method for binning the XY-dimension
%
% Return values:
% bitmap: - dataset, [1:height, 1:width, 1:colors, 1:no_stacks]
% par: - structure with parameters from Amira Mesh file

% Copyright (C) 27.01.2012 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% ver 1.01 - 10.02.2012, memory performance improvement, added waitbar
% ver 1.02 - 14.02.2012, read binary data performance increase up to 8 times
% ver 1.03 - 17.08.2012, check for Amira Mesh Labels;
% ver 1.04 - 13.03.2013, load binned or cropped dataset
% ver 1.05 - 17.10.2014, fix of waitbar for R2014b
% ver 1.06 - 29.09.2015, added use of amiraLabels2bitmap for Labels
% ver 1.07 - 09.01.2018, added extraction of embedded containers in the amiramesh headers
% ver 1.08 - 30.01.2019, updated to be compatible with version AM 3

% -- debug block starts --
%filename = '.am';
%nargin = 1;
% -- debug block ends --

bitmap = NaN;
if nargin < 2; options = struct(); end
if ~isfield(options, 'hWaitbar');    options.hWaitbar = NaN; end

customSections=0;
if isfield(options, 'depth_start')
    customSections=1;
end

if nargin < 1
    [filename, pathname] = uigetfile( ...
        {'*.am','Amira mesh labels(*.am)';
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file');
    if filename == 0; return; end
    filename = [pathname filename];
end
fid = fopen(filename, 'r');

% define type of data
tline = fgetl(fid);
if strcmp(tline(1:20), '# AmiraMesh 3D ASCII') % if strcmp(tline, '# AmiraMesh 3D ASCII 2.0')    
    type = 'ascii';
elseif strcmp(tline(1:20), '# AmiraMesh BINARY-L') || strcmp(tline(1:20),'# AmiraMesh 3D BINAR') %elseif strcmp(tline, '# AmiraMesh BINARY-LITTLE-ENDIAN 2.1') || strcmp(tline,'# AmiraMesh 3D BINARY 2.0')
    type = 'binary';
else
    disp('Error! Unknown type'); return;
end

% define lattice info
while numel(strfind(tline,'Lattice')) == 0
    tline = fgetl(fid);
end
spaces = strfind(tline,' ');
width = str2double(tline(spaces(2):spaces(3)));
height = str2double(tline(spaces(3):spaces(4)));
depth = str2double(tline(spaces(4):end));

depth_start = 1;
depth_end = depth;
depth_step = 1;
xy_step = 1;

if customSections
    depth_start = options.depth_start;
    depth_end = options.depth_end;
    depth_step = options.depth_step;
    xy_step = options.xy_step;
    depth = floor((depth_end - depth_start + 1)/depth_step);
    resizeMethod = options.resizeMethod;
end

% get Parameters
while numel(strfind(tline,'Parameters')) == 0
    tline = fgetl(fid);
end

par = struct();
level = 0;
% skiping the header
parIndex = 1;
removeGroup.Switch = 0;  % indicator to remove certain groups
removeGroup.Level = 0;  % indicator if the level to remove certain groups

while numel(strfind(tline, 'Lattice')) == 0
    tline = strtrim(fgetl(fid));
    if numel(strfind(tline, 'Lattice')) ~= 0; break; end
    if level == 0; field = cellstr(''); end
    
    openGroup = strfind(tline, '{');
    closeGroup = strfind(tline, '}');
    if ~isempty(openGroup) & isempty(closeGroup)
        level = level + 1;
        if strcmp(strtrim(tline(1:openGroup(1)-1)),'im_browser')    % remove the group made with im_browser
            field(level) = cellstr('');
        elseif strcmp(strtrim(tline(1:openGroup(1)-1)),'HistoryLogHead')    % remove the group HistoryLogHead
            removeGroup.Switch = 1;
            removeGroup.Level = level;  % indicator if the level to remove certain groups            
        elseif tline(end) == '{' && level > 1
            if removeGroup.Switch == 1; continue; end
            level = level - 1;
            par(parIndex).Name = field{level};
            %a = loopHeader(fid, tline, level);
            par(parIndex).Value = cellstr(loopHeader(fid, tline, level));
            parIndex = parIndex + 1;
        else
            field(level) = cellstr(tline(1:openGroup(1)-1));
        end
    elseif isempty(openGroup) & ~isempty(closeGroup)
        level = level - 1;
        if removeGroup.Switch == 1 && removeGroup.Level == level
            removeGroup.Switch = 0;
        end
        if level == -1; break; end  % end of the Parameters section
        field(level+1) = cellstr('');
    else
        if removeGroup.Switch == 1; continue; end    % skip elements 
        
        spaces = strfind(strtrim(tline), ' ');
        if isempty(spaces); continue; end
        parField = '';
        for lev = 1:level
            parField = [parField '_' field{lev}];
        end
        parField = [parField '_' tline(1:spaces(1)-1)];
        if parField(1) == '_'; parField = parField(2:end); end
        if parField(1) == '_'; parField = parField(2:end); end
        value = tline(spaces(1)+1:end);
        if value(end) == ','; value = value(1:end-1); end  % remove ending comma
        if numel(value)>0 && value(1) == '"' && value(end) == '"'
            value = value(2:end-1);
        elseif numel(value)>0
            if isempty(strfind(value, ' '))
                value = str2num(value); 
            end
        end   % remove quotation marks from strings 

        %par.(parField) = cellstr(value);
        par(parIndex).Name = parField;
        par(parIndex).Value = value;
        parIndex = parIndex + 1;
    end
end

% check the header for proper CoordType
for i=1:numel(par)
    if strcmp(par(i).Name,'CoordType')
        %CoordType = par(i).Value;
        if strcmp(par(i).Value,'uniform') == 0
            error('amiraMesh2bitmap: Wrong CoordType, works only with "uniform" data');
        end
    end
end

% get number of data blocks
dataIndex = 1;
while numel(strfind(tline,'# Data section follows')) == 0
    if numel(strfind(tline,'Lattice')) ~= 0
        if numel(strfind(tline,'byte Labels')) ~= 0 
            fclose(fid);
            if customSections == 1
                msgbox(sprintf('The Amira Mesh Labels is not yet implemented for partial opening of the dataset!\n\nPlease open full dataset'),'Error','error','modal');
            else
                bitmap = amiraLabels2bitmap(filename);    
            end
            return;
        end
        if numel(strfind(tline,'byte')) ~= 0
            classType(dataIndex) = cellstr('uint8');
            bytesPerPixel = 1;
        elseif numel(strfind(tline,'ushort')) ~= 0 || numel(strfind(tline,'usingle')) ~= 0
            classType(dataIndex) = cellstr('uint16');
            bytesPerPixel = 2;
        end
        % define number of colors
        openBlock = strfind(tline,'[');
        closeBlock = strfind(tline,']');
        if ~isempty(openBlock) && ~isempty(closeBlock)
            colorChannels(dataIndex) = str2double(tline(openBlock+1:closeBlock-1));
        else
            colorChannels(dataIndex) = 1;
        end
        dataIndex = dataIndex + 1;
    end
    tline = fgetl(fid);
end

maxColors = sum(colorChannels);
if numel(colorChannels) == 1 && colorChannels(1) == 4   % RGB image encoded as RGB+Alpha
    bitmap = zeros([floor(height/xy_step), floor(width/xy_step), maxColors-1, depth], classType{1});
else
    bitmap = zeros([floor(height/xy_step), floor(width/xy_step), maxColors, depth], classType{1});
end

if ~isfield(options, 'maxZ') 
    maxZ = (dataIndex - 1)*depth;   % for waitbar
else
    maxZ = options.maxZ;
end

color_id = 0;
for dataBlock = 1:dataIndex - 1
    tline = fgetl(fid); % @1
    color_id = color_id + 1;
    if customSections   % fseek to the start of the section to load
        fseek(fid, height*width*colorChannels(dataBlock)*(depth_start-1)*bytesPerPixel, 0);
    end
    zIndex = 1;
    for zLayer=depth_start:depth_step:depth_end
        if strcmp(type,'ascii')     % get ascii
            dataVec = zeros(height*width*colorChannels(dataBlock),1,classType{dataBlock});
            for index=1:height*width*colorChannels(dataBlock)
                dataVec(index) = str2double(fgetl(fid));
            end
        else    % get binary
            if customSections == 1 && zIndex > 1 && depth_step ~= 1   % fseek undesired block
                fseek(fid, height*width*colorChannels(dataBlock)*(depth_step-1)*bytesPerPixel, 0);
            end
            dataVec = fread(fid, height*width*colorChannels(dataBlock), ['*' classType{dataBlock}], 0, 'ieee-le'); % get single frame
            %dataVec = fread(fid, height*width*colorChannels(dataBlock), classType{dataBlock}, 0, 'ieee-le'); % get single frame
        end
%         if strcmp(classType{dataBlock},'uint8')     % convert to proper class
%             dataVec = uint8(dataVec);
%         elseif strcmp(classType{dataBlock},'uint16')
%             dataVec = uint16(dataVec);
%         end
        if colorChannels(dataBlock)==1
            dataVec = reshape(dataVec,[width, height])';
            if xy_step ~= 1
                dataVec = imresize(dataVec, [floor(height/xy_step) floor(width/xy_step)], resizeMethod);
            end
            bitmap(:,:,color_id:color_id+colorChannels(dataBlock)-1,zIndex) = dataVec;
        else
            dataVec = reshape(dataVec,[colorChannels(dataBlock), width, height]);
            dataVec = permute(dataVec,[3 2 1]);
            if xy_step ~= 1
                dataVec = imresize(dataVec, [floor(height/xy_step) floor(width/xy_step)], resizeMethod);
            end
            if colorChannels(dataBlock) == 4 && numel(colorChannels) == 1 % RGB+Alpha, remove Alpha
                bitmap(:,:,color_id:color_id+colorChannels(dataBlock)-2,zIndex) = dataVec(:,:,1:3);
            else
                bitmap(:,:,color_id:color_id+colorChannels(dataBlock)-1,zIndex) = dataVec;
            end
        end
        %if ~isnan(options.hWaitbar) && mod(zIndex, ceil(maxZ/20))==0;
        if ishandle(options.hWaitbar) && mod(zIndex, ceil(maxZ/20))==0          
            waitbar((zIndex)/maxZ,options.hWaitbar);
        end
        zIndex = zIndex + 1;
    end
    if depth_step == 1
        tline = fgetl(fid);     % character return symbol
    end
end
fclose(fid);

disp(['amiraMesh2bitmap: ' filename ' was loaded!']);
end

function parValueText = loopHeader(fid, parValueText, level)
% collect inbedded containers as a plain text
while level >= 1
    tline = strtrim(fgetl(fid));

    if tline(end) == '{'    % open group
        level = level + 1;
        parValueText = sprintf('%s\n%s', parValueText, tline);
    elseif tline(end) == '}'    % close group
        openGroup = strfind(tline, '{');
        closeGroup = strfind(tline, '}');
        if numel(openGroup) < numel(closeGroup)     % close the group
            level = level - 1;
            parValueText = sprintf('%s\n}', parValueText);
        else    % situation when: \"Deblur\" setVar \"CustomHelp\" {deblur.html}
            parValueText = sprintf('%s\n%s', parValueText, tline);
        end
    else
        parValueText = sprintf('%s\n%s', parValueText, tline);
    end
    %sprintf('Level: %d, %s', level, tline)
end
end