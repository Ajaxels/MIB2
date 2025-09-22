% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 15.08.2025
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function meta = readZarrMetadata(zarrPath, opts)
% function meta = readZarrMetadata(zarrPath, opts)
% Reads MoBIE-style OME-Zarr metadata for all downsampling levels or a specific step.
%
% Parameters:
% zarrPath : string, path to the root Zarr dataset
% opts.downsampleLevel (optional) : 0 = original resolution, 1 = first
%               downsample, etc, when missing or empty return information for all
%               downsampled volumes
%
% Returns:
% meta : struct with fields:
%    .imageSize     -> [t c z y x] size of highest resolution
%    .imageUnits    -> [t c z y x] cell array with image units
%    .levelNames    -> cell array of level names ('s0', 's1', ...)
%    .levelImageSizes    -> [nLevels x 3] array of sizes for each level
%    .levelScaleFactors  -> [nLevels x 3] cumulative per-axis downsampling factors
%    .levelVoxelSizes    -> [nLevels x 3] voxel sizes for each level
%    .levelImageTranslations        -> [nLevels x 3] translation offsets for each level
%    .chunkSizes    -> [nLevels x 5] chunk sizes for each level
%    .shardSizes    -> [nLevels x 5] shard sizes for each level (NaN if not present)
%    .dataTypes           -> {nLevels x 1} MATLAB-style data type strings
%    .numChannels         -> scalar, number of channels in dataset
%    .numTimePoints       -> scalar, number of time points in dataset
%    .customAttributes    -> structure with custom attributes
%    .zarrFormat         -> 2 or 3

arguments
    zarrPath (1,:) char
    opts struct = struct()
end

if ~isfield(opts, 'downsampleLevel'); opts.downsampleLevel = []; end

% --- Detect Zarr version ---
zarr2AttrFile = fullfile(zarrPath, '.zattrs');
zarr3MetaFile = fullfile(zarrPath, 'zarr.json');

if isfile(zarr2AttrFile)
    zarrFormat = 2;
elseif isfile(zarr3MetaFile)
    zarrFormat = 3;
else
    error('No .zattrs (Zarr v2) or zarr.json (Zarr v3) found in %s', zarrPath);
end

% import python zarr
try
    pyrun(["import zarr", "import numpy as np"]);
catch err
     mibShowErrorDialog([], err, 'Read Zarr metadata error');
end

% --- Read top-level metadata ---
if zarrFormat == 2
    txt = fileread(zarr2AttrFile);
    rootMeta = jsondecode(txt);
elseif zarrFormat == 3
    txt = fileread(zarr3MetaFile);
    rootMeta = jsondecode(txt);
else
    error('Unexpected Zarr version');
end

% --- Extract multiscales ---
if isfield(rootMeta, 'multiscales')
    ms = rootMeta.multiscales;
    % Extract custom top-level attributes
    customAttrs = rmfield(rootMeta, 'multiscales'); % everything except multiscales
elseif zarrFormat == 3 && isfield(rootMeta, 'attributes') && isfield(rootMeta.attributes, 'multiscales')
    ms = rootMeta.attributes.multiscales;
    % Extract custom top-level attributes
    customAttrs = rmfield(rootMeta.attributes, 'multiscales'); % everything except multiscales
else
    error('No "multiscales" entry found in top-level metadata');
end

% --- Extract level names ---
if isstruct(ms.datasets)
    allLevelNames = {ms.datasets.path};
else
    error('Unexpected format: ms.datasets is not a struct array.');
end
nTotalLevels = numel(allLevelNames);

% --- Extract image units ---
if isstruct(ms.axes)
    imageUnits = {ms.axes.unit};
    imageUnits = strrep(imageUnits, 'nanometers', 'nm');
    imageUnits = strrep(imageUnits, 'micrometers', 'um');
    imageUnits = strrep(imageUnits, 'millimeters', 'mm');
    imageUnits = strrep(imageUnits, 'pixels', 'um');
else
    imageUnits = {'','','','',''};
end

% If specific level requested
if ~isempty(opts.downsampleLevel)
    if opts.downsampleLevel < 0 || opts.downsampleLevel >= nTotalLevels
        error('Requested downsampleLevel=%d exceeds available levels (%d)', ...
            opts.downsampleLevel, nTotalLevels-1);
    end
    levelNames = {allLevelNames{opts.downsampleLevel+1}};
else
    levelNames = allLevelNames;
end

nLevels = numel(levelNames);

% Initialize outputs
levelImageSizes   = nan(nLevels,3);
levelVoxelSizes        = nan(nLevels,3);
levelImageTranslations = nan(nLevels,3);
chunkSizes        = nan(nLevels, 5);
shardSizes        = nan(nLevels, 5);
dataTypes         = strings(nLevels,1);
numChannels       = NaN;
numTimePoints     = NaN;

swapChunkWithShards = false; % when true swap the detected values for chunks and shards, not sure but they looked mixed

% Loop through levels
for i = 1:nLevels
    lvlName = levelNames{i};

    % Find dataset entry
    dsIdx = find(strcmp({ms.datasets.path}, lvlName), 1);
    if isempty(dsIdx)
        error('Dataset entry for level "%s" not found in multiscales.', lvlName);
    end

    % --- Get voxel size and translation ---
    cts = ms.datasets(dsIdx).coordinateTransformations;
    scale = nan(1,3);
    trans = zeros(1,3);
    for c = 1:numel(cts)
        ct = cts{c};
        if isfield(ct,'type')
            switch lower(ct.type)
                case 'scale'
                    scale = reshape(ct.scale,1,3);
                case 'translation'
                    trans = reshape(ct.translation,1,3);
            end
        end
    end
    levelVoxelSizes(i,:) = scale;
    levelImageTranslations(i,:) = trans;

    % --- Read array metadata (.zarray for v2, array metadata for v3) ---
    if zarrFormat == 2
        arrMetaFile = fullfile(zarrPath, lvlName, '.zarray');
    elseif zarrFormat == 3
        arrMetaFile = fullfile(zarrPath, lvlName, 'zarr.json'); % Zarr v3 may have array metadata in same location
    end

    if isfile(arrMetaFile)
        arrMeta = jsondecode(fileread(arrMetaFile));

        if isfield(arrMeta, 'shape')
            levelImageSizes(i,:) = reshape(arrMeta.shape(end-2:end),1,3);
            if i == 1 % assume s0 has full dims
                numTimePoints = arrMeta.shape(1);
                numChannels   = arrMeta.shape(2);
            end
        end
        if isfield(arrMeta, 'chunks')
            chunkSizes(i,:) = arrMeta.chunks';
        elseif isfield(arrMeta, 'chunk_grid')
            chunkSizes(i,:) = arrMeta.chunk_grid.configuration.chunk_shape;
        end
        if isfield(arrMeta, 'codecs') && isfield(arrMeta.codecs, 'configuration') && isfield(arrMeta.codecs.configuration, 'chunk_shape')
            shardSizes(i,:) = arrMeta.codecs.configuration.chunk_shape';
            swapChunkWithShards = true; % swap chunks and shards
        end

        % Convert dtype to MATLAB string
        if isfield(arrMeta, 'dtype')  % zarr2
            rawType = arrMeta.dtype;
            t = erase(rawType, {'<','>','|'});  % strip endian markers
            switch t
                case 'u1'
                    dataTypes(i) = "uint8";
                case 'u2'
                    dataTypes(i) = "uint16";
                case 'u4'
                    dataTypes(i) = "uint32";
                case 'i1'
                    dataTypes(i) = "int8";
                case 'i2'
                    dataTypes(i) = "int16";
                case 'i4'
                    dataTypes(i) = "int32";
                case 'f4'
                    dataTypes(i) = "single";
                case 'f8'
                    dataTypes(i) = "double";
                otherwise
                    dataTypes(i) = rawType; % fallback
            
            end
        elseif isfield(arrMeta, 'data_type') % % zarr3
            dataTypes(i) = arrMeta.data_type;
        end
    end
end

% Determine image size from s0 if available
idxS0 = find(strcmp({ms.datasets.path}, 's0'), 1);
if ~isempty(idxS0)
    lvlName = ms.datasets(idxS0).path;
    if zarrFormat == 2
        arrMetaFile = fullfile(zarrPath, lvlName, '.zarray');
    else
        arrMetaFile = fullfile(zarrPath, lvlName, 'zarr.json'); % Zarr v3
    end

    if isfile(arrMetaFile)
        arrMeta = jsondecode(fileread(arrMetaFile));
        imageSize = arrMeta.shape';
    else
        imageSize = nan(1, 5);
    end
else
    imageSize = nan(1, 5);
end

% --- Calculate cumulative scale factors relative to original resolution ---
levelScaleFactors = nan(nLevels, 3);
for i = 1:nLevels
    levelScaleFactors(i,:) = round(imageSize(end-2:end) ./ levelImageSizes(i,:));
end

meta = struct();
meta.imageSize    = imageSize;
meta.levelNames   = levelNames;
meta.levelImageSizes   = levelImageSizes;
meta.levelVoxelSizes   = levelVoxelSizes;
meta.imageUnits = imageUnits;
meta.levelImageTranslations = levelImageTranslations;
if ~swapChunkWithShards
    meta.chunkSizes   = chunkSizes;
    meta.shardSizes   = shardSizes;
else
    meta.chunkSizes   = shardSizes;
    meta.shardSizes   = chunkSizes;
end
meta.levelScaleFactors = levelScaleFactors;
meta.dataTypes    = dataTypes;
meta.numChannels  = numChannels;
meta.numTimePoints = numTimePoints;
meta.customAttributes = customAttrs;
meta.zarrFormat  = zarrFormat;
end
