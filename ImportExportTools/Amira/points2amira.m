function res = points2amira(filename, points, pntLabels, pntValues, options)
% generate AM file for Amira with cloud of points, their labels and values
%
% Parameters:
% filename: filename to save data
% points: a matrix with points [point number, x, y, z]
% pntLabels: a cell array with labels for each point; can be empty (@em default: " ")
% pntValues: an array of values for each point; can be empty (@em default: 1)
% options: a structure with additional options
%   .overwrite - 1-automatically overwrite existing files
%   .format - a string with format: 'binary' or 'ascii'
%   
% Return values:

% @note NOTE! this function is not yet work properly, due to some bugs in
% Amira

% Copyright (C) 05.02.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
if ~isfield(options, 'format'); options.format = 'binary'; end

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

points = [8.352947 1.752578 4.632574; 8.509810 1.760786 4.562837; 8.420821 1.760786 4.632574; 8.509810 1.770845 4.632574];
pntLabels = {'Ilya', 'Kathy', 'Kristina', 'Karen'};
pntValues = [25, 314, 272, 255];

if options.overwrite == 0
    if exist(filename,'file') == 2
        button = questdlg(sprintf('The file already exist!!!\nOverwrite?'), 'Overwrite', 'Yes', 'No', 'No');
        if strcmp(button, 'No'); return; end
    end
end

noPoints = size(points, 1);

% open a file
fid = fopen(filename,'w');
% generate a header
if strcmp(options.format, 'ascii')
    errordlg('The ascii version for the export is not implemented!', 'points2pci');
    fclose(fid);
    return
    %fprintf(fid,'# PSI Format V1.1\n');
else
    fprintf(fid,'# AmiraMesh BINARY-LITTLE-ENDIAN 2.1\n\n\n');
end
fprintf(fid,'define Points %d\n', noPoints);
fprintf(fid,'define LABEL_Labels %d\n', numel(cell2mat(pntLabels))+numel(pntLabels)-1);     % number of characters including one empty character between labels
fprintf(fid,'\n');

% write the Parameters header
fprintf(fid,'Parameters {\n');
fprintf(fid,'\t_symbols {\n');
fprintf(fid,'\t\tC000 "V"\n');
fprintf(fid,'\t}\n');
fprintf(fid,'\tContentType "HxCluster"\n');
fprintf(fid,'}\n');
fprintf(fid,'\n');

% define sections
fprintf(fid,'Points { float[3] Coordinates } @1\n');    % coordinates of the points
fprintf(fid,'Points { int Ids } @2\n');                 % IDs of the points
fprintf(fid,'Points { float Values } @3\n');            % values of the points
fprintf(fid,'LABEL_Labels { byte strings } @4\n');      % labels of the points
fprintf(fid,'\n');
fprintf(fid,'# Data section follows\n');
if strcmp(options.format, 'ascii')
    fprintf(fid,'%d -1 -1\n', noPoints);
    fprintf(fid,'  1.838234e+000   0.000000e+000   0.000000e+000\n');
    fprintf(fid,'  0.000000e+000   1.194710e+000   0.000000e+000\n');
    fprintf(fid,'  0.000000e+000   0.000000e+000   1.276934e+000\n');
    fprintf(fid,'\n');
    for i=1:size(points, 1)
        fprintf(fid,'  %f   %f   %f %d "%s"\t%d\n', points(i,1), points(i,2), points(i,3), i, pntLabels{i}, pntValues(i));
    end
else
    % saving coordinates
    fprintf(fid,'@1\n');
    for i=1:noPoints
        fwrite(fid, points(i,:), 'float32', 0, 'l');
    end
    fprintf(fid,'\n');
    % saving Ids
    fprintf(fid,'@2\n');
    for i=1:noPoints
        fwrite(fid, i, 'uint32', 0, 'l');
    end
    fprintf(fid,'\n');
    % saving Values
    fprintf(fid,'@3\n');
    for i=1:noPoints
        fwrite(fid, pntValues(i), 'float32', 0, 'l');
    end
    fprintf(fid,'\n');
    % saving Labels
    fprintf(fid,'@4\n');
    for i=1:noPoints
        label = pntLabels{i};
        for j=1:numel(label)
            fwrite(fid, label(j), 'char', 0, 'l');
        end
        fwrite(fid, 0, 'uint8', 0, 'l');    % add an empty character 00 between the labels
    end
    
end
fprintf(fid,'\n');
fclose(fid);
fprintf('points2pci: saving file %s\n', filename);
res = 1;
