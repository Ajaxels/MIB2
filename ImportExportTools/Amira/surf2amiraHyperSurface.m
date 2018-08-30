function res = surf2amiraHyperSurface(filename, surface, options)
% generate amira Hypersurface Ascii file
% 
% Parameters:
% filename: filename to save data
% surface: a structure with surface information
%       .vertices - coordinates of vertices [Nx3]
%       .faces    - indeces of vertices for each face/triangle
% options: a structure with additional options
%   .overwrite - 1-automatically overwrite existing files
%   .format - a string with format: 'binary' or 'ascii'
%   
% Return values:
% res: result of the function run, @b 1 - success, @b 0 - fail

% Copyright (C) 2010 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 19.05.2017, IB added options structure

res = 0;

if nargin < 3
    options = struct();
end
if nargin < 2
    error('Please provide filename for the surface and structure with surface data!');
end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'format'); options.format = 'ascii'; end

if options.overwrite == 0
    if exist(filename,'file') == 2
        button = questdlg(sprintf('The file already exist!!!\nOverwrite?'), 'Overwrite', 'Yes', 'No', 'No');
        if strcmp(button, 'No'); return; end
    end
end

GridBox(1) = min(surface.vertices(:,1));
GridBox(2) = max(surface.vertices(:,1));
GridBox(3) = min(surface.vertices(:,2));
GridBox(4) = max(surface.vertices(:,2));
GridBox(5) = min(surface.vertices(:,3));
GridBox(6) = max(surface.vertices(:,3));

dx = GridBox(2)-GridBox(1);
dy = GridBox(4)-GridBox(3);
dz = GridBox(6)-GridBox(5);

GridSize(1) = 1000;
GridSize(2) = round(1000*dy/dx);
GridSize(3) = round(1000*dz/dx);

fid = fopen(filename,'w');
if strcmp(options.format, 'ascii')
    fprintf(fid,'# HyperSurface 0.1 ASCII\n\n');
else
    fprintf(fid,'# HyperSurface 0.1 BINARY\n\n');
end
fprintf(fid,'Parameters {\n');
fprintf(fid,'\t\tMaterials {\n');
fprintf(fid,'\t\t\t\tExterior {\n');
fprintf(fid,'\t\t\t\t\t\tId 1,\n');
fprintf(fid,'\t\t\t\t\t\tColor 1 0.7996 0.4\n');
fprintf(fid,'\t\t\t\t}\n');
fprintf(fid,'\t\t\t\tInside {\n');
fprintf(fid,'\t\t\t\t\t\tColor 1 0.7996 0.4,\n');
fprintf(fid,'\t\t\t\t\t\tId 2\n');
fprintf(fid,'\t\t\t\t}\n');
fprintf(fid,'\t\t}\n');
fprintf(fid,'\t\tBoundaryIds {\n');
fprintf(fid,'\t\t\t\tId0 {\n');
fprintf(fid,'\t\t\t\t\t\tId 0,\n');
fprintf(fid,'\t\t\t\t\t\tInfo "undefined"\n');
fprintf(fid,'\t\t\t\t}\n');
fprintf(fid,'\t\t\t\tName "BoundaryConditions"\n');
fprintf(fid,'\t\t}\n');
fprintf(fid,'\t\tGridBox %.1f %.1f %.1f %.1f %.1f %.1f,\n',GridBox(1),GridBox(2),GridBox(3),GridBox(4),GridBox(5),GridBox(6));
fprintf(fid,'\t\tGridSize %d %d %d,\n',GridSize(1),GridSize(2),GridSize(3));
fprintf(fid,'\t\tOriginalSize %d %d %d 10000,\n',GridSize(1),GridSize(2),GridSize(3));
fprintf(fid,'\t\tSimplifyMaxDist 0,\n');
fprintf(fid,'\t\tSimplifyMaxError 0\n');
fprintf(fid,'}\n\n');
fprintf(fid,'Vertices %d\n',size(surface.vertices,1));
if strcmp(options.format, 'ascii')
    for i=1:size(surface.vertices,1)
        fprintf(fid,'\t%f %f %f\n',surface.vertices(i,1),surface.vertices(i,2),surface.vertices(i,3));
    end
else
    for i=1:size(surface.vertices,1)
        fwrite(fid, surface.vertices(i,:), 'single', 0, 'b');
    end
    fprintf(fid,'\n');
end
fprintf(fid,'NBranchingPoints 0\n');
fprintf(fid,'NVerticesOnCurves 0\n');
fprintf(fid,'BoundaryCurves 0\n');
fprintf(fid,'Patches 1\n');
fprintf(fid,'{\n');
fprintf(fid,'InnerRegion Inside\n');
fprintf(fid,'OuterRegion Exterior\n');
fprintf(fid,'BoundaryID 0\n');
fprintf(fid,'BranchingPoints 0\n\n');
fprintf(fid,'Triangles %d\n',size(surface.faces,1));
if strcmp(options.format, 'ascii')
    for i=1:size(surface.faces,1)
        fprintf(fid,'\t%d %d %d\n',surface.faces(i,1),surface.faces(i,2),surface.faces(i,3));
    end
else
    for i=1:size(surface.faces,1)
        fwrite(fid, surface.faces(i,:), 'uint32', 0, 'b');
    end
    fprintf(fid,'\n');
end
fprintf(fid,'}\n');
fclose(fid);
res = 1;
