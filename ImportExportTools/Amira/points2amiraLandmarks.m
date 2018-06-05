function res = points2amiraLandmarks(filename, points, options)
% generate amira Hypersurface Ascii file
% in:
% filename - filename to save data
% points - a matrix with points [point number, x, y, z]
% options - a structure with additional options
%   .overwrite - 1-automatically overwrite existing files
%   .format - a string with format: 'binary' or 'ascii'
%   

% Copyright (C) 22.06.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

res = 0;

if nargin < 3;     options = struct();  end
if nargin < 2
    error('Please provide filename for the file and coordinates of points!');
end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'format'); options.format = 'ascii'; end

if options.overwrite == 0
    if exist(filename,'file') == 2
        button = questdlg(sprintf('The file already exist!!!\nOverwrite?'), 'Overwrite', 'Yes', 'No', 'No');
        if strcmp(button, 'No'); return; end
    end
end

fid = fopen(filename,'w');
if strcmp(options.format, 'ascii')
    fprintf(fid,'# Avizo 3D ASCII 2.0\n\n\n');
else
    fprintf(fid,'# Avizo BINARY-LITTLE-ENDIAN 2.1\n\n\n');
end
fprintf(fid,'define Markers %d\n\n', size(points, 1));

fprintf(fid,'Parameters {\n');
fprintf(fid,'\t\tNumSets 1,\n');
fprintf(fid,'\t\tContentType "LandmarkSet"\n');
fprintf(fid,'}\n\n');
fprintf(fid,'Markers { float[3] Coordinates } @1\n\n');
fprintf(fid,'# Data section follows\n');
fprintf(fid,'@1\n');

if strcmp(options.format, 'ascii')
    for i=1:size(points, 1)
        fprintf(fid,'\t%f %f %f\n', points(i,1), points(i,2), points(i,3));
    end
else
    for i=1:size(points, 1)
        fwrite(fid, points(i,:), 'float32', 0, 'l');
    end
end
fprintf(fid,'\n');
fclose(fid);
fprintf('points2amiraLandmarks: saving file %s\n', filename);
res = 1;
