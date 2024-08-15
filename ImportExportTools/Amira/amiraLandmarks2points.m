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
% Date: 07.08.2024

function points = amiraLandmarks2points(filename)
% read amira landmark coordinates
%
% Parameters:
% filename - filename to load amira landmark data
%
% Return values:
% points: array of points as [x, y, z]

points = [];
if nargin < 1
    [filename, path] = mib_uigetfile(...
        {'*.landmarkAscii;',  'landmarkAscii Amira format (*.landmarkAscii)'; ...
        '*.landmarkBin;',  'landmarkBin Amira format (*.landmarkBin)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Load landmarks...');
    if isequal(filename, 0); return; end % check for cancel
    filename = fullfile(path, filename{1});
end

fid = fopen(filename, 'r', 'n', 'UTF-8');

% define type of data
tline = fgetl(fid);
if strcmp(tline(1:16), '# Avizo 3D ASCII') % strcmp(tline, '# AmiraMesh 3D ASCII 2.0')
    type = 'ascii';
elseif strcmp(tline(1:20), '# Avizo BINARY-LITTL') % strcmp(tline, '# AmiraMesh BINARY-LITTLE-ENDIAN 2.1')
    type = 'binary';
else
    disp('Error! Unknown type'); return;
end


% get number of markers
while numel(strfind(tline, 'define Markers')) == 0
    tline = fgetl(fid);
end
noMarkers = str2double(tline(15:end)); 
% allocate space
points = zeros([noMarkers, 3]);

% fast-forward for the data section
while numel(strfind(tline,'# Data section follows')) == 0
    tline = fgetl(fid);
end
% get line with @1
tline = fgetl(fid);

index = 1;
if strcmp(type,'ascii')
    tline = fgetl(fid);
    while ~feof(fid) || ~isempty(tline)
        points(index, :) = str2num(tline); %#ok<ST2NM>
        index = index + 1;
        tline = fgetl(fid);
    end
    fclose(fid);
elseif strcmp(type,'binary')
    A = fread(fid, 'single');
    points = reshape(A, [3, noMarkers]);
    points = points';
    fclose(fid);
end
