function createMultiscaleDataset_v1(zarrPath, imageSize, imageType, levelNames, scaleXYZ, Options)
% function createMultiscaleDataset_v1(zarrPath, imageSize, imageType, levelNames, scaleXYZ, Options)
% Creates a multiscale Zarr dataset.
%
% Parameters:
% zarrPath   : string, path to the top-level Zarr folder
% imageSize  : integer [T, C, Z, Y, X] size of the original image as [time, colors, depth, height, width]
% imageType  : string, data type of the image (e.g., 'uint8', 'float32')
% levelNames : cell array, cell array of strings, names of the multiscale levels, e.g. {'s0','s1','s2'}
% scaleXYZ   : Nx3 array of scale factors for each level [Z Y X], e.g. [1 1 1; 2 2 2; 4 4 4];
% Options    : struct with additional options
%   .chunks          - chunk size for each dimension as [T, C, Z, Y, X]
%   .compressionType - string, type of the compression algorithm 'blosc', 'gzip', 'none'
%   .compressionLevel- numeric, compression level: 
%           - 0 (no compression), 
%           - 1 (fastest, least compression), 
%           - 9 (slowest, best compression), 
%           - -1 (default compression level, usually equivalent to 6 in zlib)
%   .zarrFormat      - int, 2 or 3 (default: 2 for MoBIE)
%   .dataType        - string, 'image' for dimensions [T, C, Z, Y, X] or 'label' for dimensions [T, Z, Y, X]
%   .shards          - [t c z y x] sharding sizes (default: []), only for Zarr v3
%
% Return values:
%
% Examples

arguments
    zarrPath (1,:) char
    imageSize (1,:) double {mustBePositive}
    imageType (1,:) char
    levelNames cell
    scaleXYZ (:,3) double {mustBePositive}
    Options struct
end

% Defaults
if ~isfield(Options, 'chunks'), Options.chunks = [1 1 128 128 128]; end
if ~isfield(Options, 'shards'), Options.shards = []; end
if ~isfield(Options, 'zarrFormat'), Options.zarrFormat = 2; end % MoBIE = Zarr v2
if ~isfield(Options, 'compressionType'), Options.compressionType = 'gzip'; end
if ~isfield(Options, 'compressionLevel'), Options.compressionLevel = 1; end
if ~isfield(Options, 'dataType'); Options.dataType ='image'; end

% replace slashes
zarrPath = strrep(zarrPath,'\','/');

% Chunk size
imageChunks = Options.chunks;
%if strcmp(Options.dataType,'label'), imageChunks(2) = 1; end

if ~isfolder(zarrPath), mkdir(zarrPath); end

% pyrun("import zarr");

% % Create top-level Zarr group
% % Done later in write_top_level_zattrs.m
% pyrun("g = zarr.open_group(storePath, mode='w')", storePath=strrep(zarrPath,'\','/'));
% % Add multiscale metadata with placeholders
% datasets = cellfun(@(n) struct('path', n), levelNames, 'UniformOutput', false);
% attrs = struct('multiscales', struct('version', '0.4', 'name', 'dataset', 'datasets', {datasets}, 'type', Options.dataType));
% pyrun("import json; g.attrs.update(json.loads(attrs_json))", attrs_json=jsonencode(attrs));

% Compressor setup
if ~strcmp(Options.compressionType, 'none')
    if Options.zarrFormat == 2
        pyrun("import numcodecs");
        switch lower(Options.compressionType)
            case 'gzip'
                pyrun("compressors = numcodecs.GZip(level=Options_clevel)", Options_clevel=int32(Options.compressionLevel));
            case 'blosc'
                pyrun("compressors = numcodecs.Blosc(cname='zstd', clevel=Options_clevel, shuffle=numcodecs.Blosc.BITSHUFFLE)", ...
                    Options_clevel=int32(Options.compressionLevel));
            otherwise
                error('Unsupported compression type: %s', Options.compressionType);
        end
    elseif Options.zarrFormat == 3
        if strcmpi(Options.compressionType, 'gzip')
            pyrun("from numcodecs import GZip");
            pyrun("compressors = GZip(level=Options_clevel)", Options_clevel=int32(Options.compressionLevel));
        else
            pyrun("from zarr.codecs import BloscCodec");
            pyrun("compressors = BloscCodec(cname='zstd', clevel=Options_clevel, shuffle='bitshuffle')", ...
                Options_clevel=int32(Options.compressionLevel));
        end
    end
else
    pyrun("compressors = None");
end

% Create arrays for each level
for lvl = 1:numel(levelNames)
    % Compute level shape
    szLvl = max(ceil(imageSize(end-2:end) ./ scaleXYZ(lvl,:)),1);
    if strcmp(Options.dataType,'image')
        imageShape = [imageSize(1), imageSize(2), szLvl];
    else
        imageShape = [imageSize(1), szLvl];
    end

    % Path for this level
    storePath = fullfile(zarrPath, levelNames{lvl});

    if Options.zarrFormat == 2
        % use open_array function as create_array is not comatible with
        % dimension_separator parameter
        pyrun("zarr.open_array(store=store, shape=imageShape, chunks=imageChunks, dtype=dtype, compressor=compressors, zarr_format=2, dimension_separator='/', mode='w')", ...
            store=storePath, imageShape=int32(imageShape), imageChunks=int32(imageChunks), dtype=imageType);
    else
        % Create Zarr array with optional shards for Zarr v3
        if isfield(Options,'shards') && ~isempty(Options.shards)
            pyrun("zarr.create_array(store=store, shape=imageShape, chunks=imageChunks, dtype=dtype, compressors=compressors, zarr_format=zarrFormat, shards=tuple(shards))", ...
                store=storePath, imageShape=int32(imageShape), imageChunks=int32(imageChunks), dtype=imageType, zarrFormat=int32(Options.zarrFormat), shards=int32(Options.shards));
        else
            pyrun("zarr.create_array(store=store, shape=imageShape, chunks=imageChunks, dtype=dtype, compressors=compressors, zarr_format=zarrFormat)", ...
                store=storePath, imageShape=int32(imageShape), imageChunks=int32(imageChunks), dtype=imageType, zarrFormat=int32(Options.zarrFormat));
        end
    end
end

fprintf('Multiscale dataset created with %d levels.\n', numel(levelNames));
end
