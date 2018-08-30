function res = points2psi(filename, points, pntLabels, pntValues, options)
% generate PSI file for Amira
% the file contains cloud of points, their labels and values
%
% Parameters:
% filename: filename to save data
% points: a matrix with points [point number, x, y, z]
% pntLabels: a cell array with labels for each point; can be empty (@em
% default: " "); note the spaces will be replaced with underlines
% pntValues: an array of values for each point; can be empty (@em default: 1)
% options: a structure with additional options
%   .overwrite - 1-automatically overwrite existing files
%   .format - a string with format: 'binary' or 'ascii'
%   
% Return values:
%
% @note @b Important: the data saved in this format can be opened in Amira,
% but saving of the data from amira crashes Amira due to an internal bug in
% Amira. Amira version tested 6.4.0

% Copyright (C) 06.02.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

res = 0;

if nargin < 5;     options = struct();  end
if nargin < 4;     pntValues = [];  end
if nargin < 3;     pntLabels = [];  end
if nargin < 2
    error('Please provide filename for the file and coordinates of points!');
end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'format'); options.format = 'ascii'; end

if isempty(pntValues) 
    pntValues = zeros([size(points, 1), 1]) + 1;  
end
if numel(pntValues) < size(points, 1)
    pntValues = zeros([size(points, 1), 1]) + pntValues(1);  
end

if isempty(pntLabels) 
    pntLabels = repmat(cellstr(' '), [size(points, 2) 1]);  
end
if numel(pntLabels) < size(points, 1) || ischar(pntLabels)
    if iscell(pntLabels)
        pntLabels = repmat(pntLabels(1), [size(points, 1) 1]);
    else
        pntLabels = repmat(cellstr(pntLabels), [size(points, 1) 1]);
    end
end
% replace spaces with underline
for i=1:numel(pntLabels)
    pntLabels{i}(pntLabels{i}==' ') = '_';
end

if options.overwrite == 0
    if exist(filename,'file') == 2
        button = questdlg(sprintf('The file already exist!!!\nOverwrite?'), 'Overwrite', 'Yes', 'No', 'No');
        if strcmp(button, 'No'); return; end
    end
end

% open a file
fid = fopen(filename,'w');
% generate a header
if strcmp(options.format, 'ascii')
    fprintf(fid,'# PSI Format V1.1\n');
else
    errordlg('The binary version for the export is not implemented!', 'points2pci');
    fclose(fid);
    return
    %fprintf(fid,'# Avizo BINARY-LITTLE-ENDIAN 2.1\n\n\n');
end
% generate a comment section
fprintf(fid,'#\n');
fprintf(fid,'# column[0] = "x"\n');
fprintf(fid,'# column[1] = "y"\n');
fprintf(fid,'# column[2] = "z"\n');
fprintf(fid,'# column[3] = "Id"\n');
fprintf(fid,'# column[4] = "Labels"\n');
fprintf(fid,'# column[5] = "Values"\n');
fprintf(fid,'#\n');
fprintf(fid,'# type[4] = string\n');
fprintf(fid,'#\n\n');

noPoints = size(points, 1);

if strcmp(options.format, 'ascii')
    fprintf(fid,'%d -1 -1\n', noPoints);    % number of points, as well as two other parameters, which are ignored by Amira
    fprintf(fid,'  1.838234e+000   0.000000e+000   0.000000e+000\n');   % Next, the bounding box of the data set is specified. 
    fprintf(fid,'  0.000000e+000   1.194710e+000   0.000000e+000\n');   % However, Amira will ignore this definition. 
    fprintf(fid,'  0.000000e+000   0.000000e+000   1.276934e+000\n');   % Instead, the bounding box will be calculated from the point coordinates itself.
    fprintf(fid,'\n');
    for i=1:size(points, 1)
        fprintf(fid,'\t%f\t%f\t%f\t%d\t"%s"\t%d\n', points(i,1), points(i,2), points(i,3), i, pntLabels{i}, pntValues(i));
    end
else
    %for i=1:size(points, 1)
    %    fwrite(fid, points(i,:), 'float32', 0, 'l');
    %end
end
fprintf(fid,'\n');
fclose(fid);
fprintf('points2pci: saving file %s\n', filename);
res = 1;
