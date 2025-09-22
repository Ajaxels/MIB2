% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 15.08.2025
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function dataset = getZarrData(zarrFilename, meta, imageType, orient, col_channel, options)
%GETZARRDATA Read subvolume from a Zarr dataset with optional slicing and type conversion.
%
% Parameters:
%   zarrFilename : string, path to the Zarr dataset (root folder)
%   meta         : metadata structure from readZarrMetadata
%   imageType    : 'image' or 'labels'
%   orient       : [optional] orientation code
%       1 - xz
%       2 - yz
%       4 - yx (original)
%   col_channel  : [optional] for 'image', vector of color channels to select (0 = all)
%                  for 'labels', NaN = all materials, integer = specific material
%   options      : [optional] struct with slicing info
%       .y -> [ymin, ymax] 
%       .x -> [xmin, xmax]
%       .z -> [zmin, zmax]
%       .t -> [tmin, tmax]
%       .level -> pyramid level index (1 = highest resolution)
%
% Return:
%   dataset : array of size [y,x,c,z,t] or variant depending on orientation and imageType

arguments
    zarrFilename (1,:) char
    meta struct
    imageType (1,:) char
    orient double = 4
    col_channel double = 0
    options struct = struct()
end

% --- Default pyramid level ---
if ~isfield(options,'level') || isempty(options.level)
    options.level = 1;
end
levelIdx = options.level;

% --- Metadata for this level ---
levelSize = meta.levelImageSizes(levelIdx, :);   % [z, y, x] for this level
dtype     = meta.dataTypes(levelIdx);            % e.g., 'uint8'

% --- Use full-resolution size for default ranges ---
fullSize = meta.imageSize;  % [z, y, x]

% --- Ensure slicing fields exist ---
if ~isfield(options,'x') || isempty(options.x)
    options.x = [1, fullSize(3)];
end
if ~isfield(options,'y') || isempty(options.y)
    options.y = [1, fullSize(2)];
end
if ~isfield(options,'z') || isempty(options.z)
    options.z = [1, fullSize(1)];
end
if ~isfield(options,'t') || isempty(options.t)
    options.t = [1, meta.numTimePoints];
end

% --- Adjust coordinates for orientation ---
% --- Use scale factors to adjust full-resolution coordinates to level ---
sf = meta.levelScaleFactors(levelIdx, :);  % [zScale, yScale, xScale]

switch orient
    case 1 % xz
        Xidx = ceil(options.y ./ sf(2));  % Y axis -> X
        Yidx = ceil(options.z ./ sf(1));  % Z axis -> Y
        Zidx = ceil(options.x ./ sf(3));  % X axis -> Z
    case 2 % yz
        Xidx = ceil(options.z ./ sf(1));
        Yidx = ceil(options.y ./ sf(2));
        Zidx = ceil(options.x ./ sf(3));
    case 4 % yx
        Xidx = ceil(options.x ./ sf(3));
        Yidx = ceil(options.y ./ sf(2));
        Zidx = ceil(options.z ./ sf(1));
    otherwise
        error('Unsupported orientation');
end

% --- No further downsampling needed; indices are already for the selected level ---
Tidx = options.t(1):options.t(2);

% --- Convert to 0-based for Python ---
Xlim = Xidx - 1;
Ylim = Yidx - 1;
Zlim = Zidx - 1;
Tlim = Tidx - 1;

% --- Color selection ---
if strcmp(imageType,'image')
    if col_channel == 0
        Clim = 0 : meta.numChannels-1; % all channels
    else
        Clim = col_channel(1)-1 : col_channel(end)-1;
    end
else
    Clim = 0 : meta.numChannels-1; % all labels/materials
end

% --- Prepare Zarr path ---
zarrPathLevel = fullfile(zarrFilename, meta.levelNames{levelIdx});
zarrPathLevel = strrep(zarrPathLevel,'\','/');

% --- Build Python slicing string ---
sliceStr = sprintf("%d:%d, %d:%d, %d:%d, %d:%d, %d:%d", ...
    Tlim(1), Tlim(end)+1, Clim(1), Clim(end)+1, ...
    Zlim(1), Zlim(end)+1, Ylim(1), Ylim(end)+1, Xlim(1), Xlim(end)+1);

% --- Read subvolume using Python ---
block = pyrun([ ...
    sprintf("import zarr, numpy as np"), ...
    sprintf("z = zarr.open('%s')", zarrPathLevel), ...
    sprintf("a = np.array(z[%s], dtype=z.dtype)", sliceStr) ...
    ], "a");

% --- Convert to MATLAB type ---
dataset = cast(block, dtype);
dataset = permute(dataset, [4 5 2 3 1]); % convert to [y,x,c,z,t]
end
