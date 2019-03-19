function [bitmap] = amiraLabels2bitmap(filename)
% function [bitmap] = amiraLabels2bitmap(filename)
% Converts Amira Mesh Labels to bitmap matrix, for Amira ver. 5.2.2
%
% Parameters:
% filename: (@em optional), filename of Amira Mesh labels, when omitted a file selection dialog is started
%
% Return values:
% bitmap: an image of the amira label fields as [1:height, 1:width, 1:colors, 1:no_stacks]

% Copyright (C) 19.07.2010 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% ver 1.01 - 18.05.2012 - updated read procedure
% ver 1.02 - 06.08.2012 - compatible with RLE compression algorithm
% ver 1.03 - 30.01.2019, IB updated to be compatible with version 3

tic
bitmap = NaN;
if nargin < 1
    [filename, pathname] = uigetfile( ...
        {'*.am','Amira mesh labels(*.am)';
         '*.*',  'All Files (*.*)'}, ...
         'Pick a file');
    if filename == 0; return; end
    filename = [pathname filename];
end
%filename = 'ER.am';
fid = fopen(filename, 'r');

% define type of data
tline = fgetl(fid);
if strcmp(tline(1:20), '# AmiraMesh 3D ASCII') % strcmp(tline, '# AmiraMesh 3D ASCII 2.0')
    type = 'ascii';
elseif strcmp(tline(1:20), '# AmiraMesh BINARY-L') % strcmp(tline, '# AmiraMesh BINARY-LITTLE-ENDIAN 2.1')
    type = 'binary';
else
    disp('Error! Unknown type'); return;
end

% define lattice info
while numel(strfind(tline,'Lattice')) == 0
    tline = fgetl(fid);
end
spaces = strfind(tline,' ');
width = str2num(tline(spaces(2):spaces(3))); %#ok<ST2NM>
height = str2num(tline(spaces(3):spaces(4))); %#ok<ST2NM>
depth = str2num(tline(spaces(4):end)); %#ok<ST2NM>

tline = '';
% skiping the header until Lattice { byte Labels } to find out the compression settings
while numel(strfind(tline,'Lattice')) == 0
    tline = fgetl(fid);
end
if strfind(tline, 'HxByteRLE')
    RLEcompression = 1;
    indx = strfind(tline, 'HxByteRLE');
    elementsInFile = str2num(tline(indx+10:end-1));
else
    RLEcompression = 0;
end
if isempty(strfind(tline, 'Labels'))
    msgbox(sprintf('Wrong data type!\nRequires Labels in the Lattice description!'), 'Error!', 'error');
    return;
end

if strfind(tline, 'byte')
    imgClass = 'uint8';
elseif strfind(tline, 'ushort')
    imgClass = 'uint16';
elseif strfind(tline, 'int')
    imgClass = 'uint32';
else
    msgbox('Wrong data type!', 'Error!', 'error');
    return;
end

% skiping the rest of the header
while numel(strfind(tline,'# Data section follows')) == 0
    tline = fgetl(fid);
end
tline = fgetl(fid); % '@1'

elements_no = height*width*depth;
if strcmp(type,'ascii')
    bitmap_vec = zeros(elements_no,1,'uint8'); 
    for index=1:elements_no
        bitmap_vec(index) = str2num(fgetl(fid));
    end
    fclose(fid);
else
    if RLEcompression == 0
        switch imgClass
            case 'uint8'
                bitmap_vec = fread(fid, height*width*depth, '*uint8', 0, 'ieee-le');
            case 'uint16'
                bitmap_vec = fread(fid, height*width*depth, '*uint16', 0, 'ieee-le');
            case 'uint32'
                bitmap_vec = fread(fid, height*width*depth, '*uint32', 0, 'ieee-le');
            end
        fclose(fid);
    elseif RLEcompression == 1  % read RLE compressed block
        switch imgClass
            case 'uint8'
                bitmap_vec = zeros(elements_no, 1, 'uint8');
                index = double(1);
                vec = fread(fid, elementsInFile, '*uint8');
            case 'uint16'
                bitmap_vec = zeros(elements_no, 1, 'uint16');
                index = double(1);
                vec = fread(fid, elementsInFile, '*uint16');
            case 'uint32'
                bitmap_vec = zeros(elements_no, 1, 'uint32');
                index = double(1);
                vec = fread(fid, elementsInFile, '*uint32');
        end
        fclose(fid);
        
        i=1;
        while i < numel(vec)
            pixel = vec(i); 
            count = double(bitand(pixel, 127));

            if bitand(pixel, 128)      % no compression
                bitmap_vec(index:index+count-1) = vec(i+1:i+count);
                i = i + count + 1;
            else
                bitmap_vec(index:index+count-1) = vec(i+1);
                i = i + 2;
            end
            index = index + count;
        end
        
%         while ~feof(fid)
%             pixel = fread(fid, 1); 
%             count = bitand(pixel, 127);
%             if bitand(pixel, 128)      % no compression
%                 bitmap_vec(index:index+count-1) = fread(fid, count, '*uint8'); 
%             else
%                 bitmap_vec(index:index+count-1) = fread(fid, 1, '*uint8');
%                 %index
%                 %count
%             end
%             index = index + count;
%         end
    end
end

% fclose(fid);
%bitmap_list = reshape(permute(bitmap,[2 1 3]),1,[])';
bitmap = reshape(bitmap_vec,[width, height, depth]);
bitmap= permute(bitmap,[2 1 3]);
toc
disp(['amiraLabels2bitmap: ' filename ' was loaded!']);


