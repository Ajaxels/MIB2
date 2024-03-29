% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function [img, header] = getMRCfile(filename)
% function [img, header] = getMRCfile(filename)
% Read data in MRC/REC format
%
% Parameters:
% filename: [@em optional] filename
%
% Return values:
% img: - the dataset, [1:height, 1:width, 1:no_stacks]
% header: a structure with the MRC header

%| Format description: 
%      http://ami.scripps.edu/software/mrctools/mrc_specification.php

% Updates
% 

img = NaN;
header = struct();
if nargin < 1
    [filename, pathname] = mib_uigetfile( ...
        {'*.rec; *.mrc','MRC file (*.mrc; *.rec)';
         '*.*',  'All Files (*.*)'}, ...
         'Pick a file');
    if isequal(filename, 0); return; end
    filename = [pathname filename{1}];
end

[fid,message]=fopen(filename, 'r', 'ieee-le'); % open in Little-endian ordering
if fid == -1
    fclose(fid);
    error(['Can''t open ' filename ' ->' message]);
end

value = fread(fid, 1, 'int32');
if abs(value) > 999999  % change to Big-endian ordering
    fclose(fid);
    fid = fopen(filename, 'r', 'ieee-be');
    value=fread(filename,1,'int32'); 
end

header.Width = value;
header.Height = fread(fid, 1, 'int32');
header.Thickness = fread(fid, 1, 'int32');
type = fread(fid,1,'int32');
switch type
    case 0   % image : signed 8-bit bytes range -128 to 127
        header.type = '*uint8';
    case 1   % image : 16-bit halfwords
        header.type = '*int16';
    case 2   % image : 32-bit reals
        header.type = '*float32';
    case 3   % transform : complex 16-bit integers
        header.type = type;
        fclose(fid);
        error('Transform type is not supported');
    case 4   % transform : complex 32-bit reals
        header.type = type;
        fclose(fid);
        error('Transform type is not supported');
    case 6   % image : unsigned 16-bit range 0 to 65535
        header.type = '*uint16';
    case 16  % unsigned char * 3 (for rgb data, non-standard)
        fclose(fid);
        error('This type is not yet supported');
    otherwise
        header.type = type;
end
header.NXSTART = fread(fid, 1, 'int32');  % number of first column in map (Default = 0)
header.NYSTART = fread(fid, 1, 'int32');  % number of first row in map
header.NZSTART = fread(fid, 1, 'int32');  % number of first section in map
header.MX = fread(fid, 1, 'int32');  % number of intervals along X
header.MY = fread(fid, 1, 'int32');  % number of intervals along Y
header.MZ = fread(fid, 1, 'int32');  % number of intervals along Z
header.dxAngstrom = fread(fid, 1, 'float32')/header.Width;  % x-resolution in Angstrom
header.dyAngstrom = fread(fid, 1, 'float32')/header.Height;  % y-resolution in Angstrom
header.dzAngstrom = fread(fid, 1, 'float32')/header.Thickness;  % z-resolution in Angstrom
header.CellAngleA = fread(fid, 1, 'float32');  % Cell angles
header.CellAngleB = fread(fid, 1, 'float32');  % Cell angles
header.CellAngleC = fread(fid, 1, 'float32');  % Cell angles
header.MapC = fread(fid, 1, 'int32');  % axis corresp to cols (1,2,3 for X,Y,Z)
header.MapR = fread(fid, 1, 'int32');  % axis corresp to rows (1,2,3 for X,Y,Z)
header.MapS = fread(fid, 1, 'int32');  % axis corresp to sections (1,2,3 for X,Y,Z)
header.DMin = fread(fid, 1, 'float32');  % minimum density value
header.DMax = fread(fid, 1, 'float32');  % maximum density value
header.DMean = fread(fid, 1, 'float32');  % mean density value
header.ISPG = fread(fid, 1, 'int32');  % space group number 0 or 1 (default=0)
header.NSYMBT = fread(fid, 1, 'int32');  % number of bytes used for symmetry data (0 or 80)
header.Extra = fread(fid, 25, 'int32');  % extra space used for anything   - 0 by default
header.OriginX = fread(fid, 1, 'int32');  %  origin in X,Y,Z used for transforms
header.OriginY = fread(fid, 1, 'int32');  %  origin in X,Y,Z used for transforms
header.OriginZ = fread(fid, 1, 'int32');  %  origin in X,Y,Z used for transforms
header.Map = fread(fid, 4, '*char');  % character string 'MAP ' to identify file type
header.MACHST = fread(fid, 4, '*char');  %  machine stamp
header.RMS = fread(fid, 1, 'int32');  %  rms deviation of map from mean density
header.NLABL = fread(fid, 1, 'int32');  %  number of labels being used
for i=1:header.NLABL
    header.labels(i,1:80)=fread(fid,80,'*char')';
end

fseek(fid, 1024, -1);
[img, counter] = fread(fid, header.Width*header.Height*header.Thickness, header.type);
%[img, counter] = fread(fid, header.Width*header.Height*header.Thickness, '*int8');
fclose(fid);
if counter ~= header.Width*header.Height*header.Thickness
    error('File is not complete!');
end
img2 =  reshape(img, [header.Width header.Height header.Thickness]);

if strcmp(header.type, '*int16')
    img = zeros(size(img2),'uint16');
    img(:,:,:) = img2 - min(min(min(img2)));
    img = permute(img,[2 1 3]);
else
    img = permute(img2,[2 1 3]);
end

