function [par, img_info, dim_xyczt] = getAmiraMeshHeader(filename)
% function [par, img_info, dim_xyczt] = getAmiraMeshHeader(filename)
% Get header of Amira Mesh file
%
% Parameters:
% filename: (@em optional): filename of Amira Mesh file
%
% Return values:
% par: a structure with parameters in format:
%   .Name -> parameter name
%   .Value -> parameter value
% img_info: -> in the format compatible with imageData.img_info containers.Map
% dim_xyczt: -> dimensions of the dataset

% Copyright (C) 27.01.2012 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 09.01.2018, IB added extraction of embedded containers in the amiramesh headers
% 30.01.2019, IB updated to be compatible with version 3

img_info = containers.Map;
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
    if isempty(tline); continue; end
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
        
        try
            parField = [parField '_' tline(1:spaces(1)-1)];
        catch err
            0
        end
        if parField(1) == '_'; parField = parField(2:end); end
        if parField(1) == '_'; parField = parField(2:end); end
        
        value = tline(spaces(1)+1:end);
        
        if value(end) ~= ',' && ~strcmp(parField,'CoordType')
            tline2 = strtrim(fgetl(fid));
            if tline2(1) ~= '}'
                value = sprintf('%s \t %s', value, tline2);
            else
                level = level - 1;
            end
        end
        
        if value(end) == ','
            value = value(1:end-1); 
        end  % remove ending comma 

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

% check the header for proper CoordType and ContentType fields
HxMultiChannelField3_sw = 0;
parNames = {par.Name};
parIndex = find(ismember(parNames, 'ContentType'));
if ~isempty(parIndex)
    if strcmp(par(parIndex(1)).Value,'HxMultiChannelField3') == 1
        HxMultiChannelField3_sw = 1;
    end
end

% get number of data blocks
dataIndex = 1;
while numel(strfind(tline,'# Data section follows')) == 0
    if numel(strfind(tline,'Lattice')) ~= 0
        if numel(strfind(tline,'byte')) ~= 0
            classType(dataIndex) = cellstr('uint8');
        elseif numel(strfind(tline,'ushort')) ~= 0 || numel(strfind(tline,'usingle')) ~= 0
            classType(dataIndex) = cellstr('uint16');
        elseif numel(strfind(tline,'int')) ~= 0
            classType(dataIndex) = cellstr('uint32');
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
fclose(fid);

if HxMultiChannelField3_sw == 1     % each data block is a single color channel
    colorChannels = ones(dataIndex,1)*(dataIndex - 1);
end

warning_state = warning('off');
for p=1:numel(par)
    if strcmp(par(p).Name,'BoundingBox')
        bb = str2num(par(p).Value); %#ok<ST2NM>
        bb = sprintf('%f %f %f %f %f %f', bb(1), bb(2), bb(3), bb(4), bb(5), bb(6));
    else
        fieldName = par(p).Name;
        fieldName = strrep(fieldName,':','_');
        fieldName = strrep(fieldName,'.','_');
        fieldName = strrep(fieldName,'-','_');
        img_info(fieldName) = par(p).Value;
    end
end
warning(warning_state);     % Switch warning back to initial settings
img_info('imgClass') = classType{1};
if max(colorChannels) > 1
    img_info('ColorType') = 'truecolor';
else
    img_info('ColorType') = 'grayscale';
end

if isKey(img_info, 'ImageDescription')
    curr_text = img_info('ImageDescription');
    bb_info_exist = strfind(curr_text,'BoundingBox');
    if bb_info_exist == 1
        spaces = strfind(curr_text,' ');
        if numel(spaces) < 7; spaces(7) = numel(curr_text); end
        tab_pos = strfind(curr_text,sprintf('\t'));
        if isempty(tab_pos); tab_pos = strfind(curr_text,sprintf('|')); end
        % 12    14    21    23    28    30
        pos = min([spaces(7) tab_pos]);
        img_info('ImageDescription') = ['BoundingBox ' bb curr_text(pos:end)];
    else
        img_info('ImageDescription') = ['BoundingBox ' bb curr_text];
    end
else
    if exist('bb','var')
        img_info('ImageDescription') = ['BoundingBox ' bb];
    else
        img_info('ImageDescription') = '';
    end
end
if HxMultiChannelField3_sw == 0 && max(colorChannels) == 4  % RGBA
    colorChannels = 3;
end
    
dim_xyczt = [width height max(colorChannels) depth 1];
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