function header = getMRCheader(filename)
% function header = getMRCheader(filename)
% Read header of MRC/REC file
%
% Parameters:
% filename: [@em optional] filename
%
% Return values:
% header: a structure with the MRC header

%| Format description: 
%      http://bio3d.colorado.edu/imod/doc/mrc_format.txt
%      http://ami.scripps.edu/software/mrctools/mrc_specification.php

% Copyright (C) 2010 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

header = struct();
if nargin < 1
    [filename, pathname] = uigetfile( ...
        {'*.rec; *.mrc','MRC file (*.mrc; *.rec)';
         '*.*',  'All Files (*.*)'}, ...
         'Pick a file');
    if filename == 0; return; end;
    filename = fullfile(pathname, filename);
end

[fid,message]=fopen(filename,'r');
if fid == -1
    error(['Can''t open ' filename ' ->' message]);
end


header.Width = fread(fid, 1, 'int32');
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
        error('Transform type is not supported');
    case 4   % transform : complex 32-bit reals
        header.type = type;
        error('Transform type is not supported');
    case 6   % image : unsigned 16-bit range 0 to 65535
        header.type = '*uint16';
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
header.ISPG = fread(fid, 1, 'float32');  % space group number 0 or 1 (default=0)
header.NSYMBT = fread(fid, 1, 'float32');  % number of bytes used for symmetry data (0 or 80)
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
end;

fclose(fid);
