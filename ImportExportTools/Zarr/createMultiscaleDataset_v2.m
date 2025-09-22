function createMultiscaleDataset_v2(zarrPath, imageSize, imageType, levelNames, scaleXYZ, Options)
% function createMultiscaleDataset(zarrPath, imageSize, imageType, levelNames, scaleXYZ, Options)
% Creates a multiscale OME-Zarr dataset including arrays and metadata.
%
% Parameters:
% zarrPath   : string, path to the top-level Zarr folder
% imageSize  : integer [T, C, Z, Y, X] size of the original image as [time, colors, depth, height, width]
% imageType  : string, data type of the image (e.g., 'uint8', 'float32')
% levelNames : cell array of strings, names of the multiscale levels, e.g. {'s0','s1','s2'}
% scaleXYZ   : [nLevels x 3] array of scale factors [Z Y X], e.g. [1 1 1; 2 2 2; 4 4 4]
% Options    : struct with additional options
%   .chunks            - chunk size for each dimension as [T, C, Z, Y, X]
%   .compressionType   - string, compression algorithm: 'blosc', 'gzip', 'none'
%   .compressionLevel  - numeric, compression level:
%                          0 (no compression),
%                          1 (fastest, least compression),
%                          9 (slowest, best compression),
%                         -1 (default, usually = 6)
%   .zarrFormat        - int, 2 or 3 (default: 2 for MoBIE)
%   .dataType          - string, 'image' ([T,C,Z,Y,X]) or 'labels' ([T,Z,Y,X])
%   .shards            - [t c z y x] sharding sizes (default: []), only Zarr v3
%   .voxelSize         - [1x3] physical voxel size along [Z Y X] (default: [1 1 1])
%   .voxelUnits        - string, units of voxel size ('nanometers','micrometers','pixels', etc.)
%   .levelTranslations - [nLevels x 3] physical translations per level (default: zeros)
%   .customAttributes  - struct of extra attributes to add to root.attrs (default: empty)
%
% Return values:
%   None. Creates group metadata and per-level arrays with attributes.
%
% Example:
%   Options.voxelSize = [0.3 0.1 0.1];
%   Options.voxelUnits = 'micrometers';
%   createMultiscaleDataset('my.zarr',[1 3 50 512 512],'uint16',{'s0','s1'},[1 1 1; 2 2 2],Options);

% Updates
% 23.08.2025, consolidated createMultiscaleDataset_v1 and
%             writeTopLevelZattrs; added customAttributes

arguments
    zarrPath (1,:) char
    imageSize (1,:) double {mustBePositive}
    imageType (1,:) char
    levelNames cell
    scaleXYZ (:,3) double {mustBePositive}
    Options struct = struct()
end

% pyrun("import zarr");

% ------------------
% Defaults
% ------------------
if ~isfield(Options,'chunks'), Options.chunks = [1 1 128 128 128]; end
if ~isfield(Options,'shards'), Options.shards = []; end
if ~isfield(Options,'zarrFormat'), Options.zarrFormat = 2; end
if ~isfield(Options,'compressionType'), Options.compressionType = 'gzip'; end
if ~isfield(Options,'compressionLevel'), Options.compressionLevel = 1; end
if ~isfield(Options,'dataType'), Options.dataType ='image'; end
if ~isfield(Options,'voxelSize'), Options.voxelSize = [1 1 1]; end
if ~isfield(Options,'voxelUnits'), Options.voxelUnits = 'micrometers'; end
if ~isfield(Options,'levelTranslations'), Options.levelTranslations = zeros(size(scaleXYZ)); end
if ~isfield(Options,'customAttributes'), Options.customAttributes = struct(); end

% replace slashes
zarrPath = strrep(zarrPath,'\','/');
% make new folder for the zarr output
if ~isfolder(zarrPath), mkdir(zarrPath); end

% ------------------
% Compressor setup
% ------------------
pyrun("compressors = None");
if ~strcmpi(Options.compressionType,'none')
    if Options.zarrFormat == 2
        pyrun("import numcodecs");
        switch lower(Options.compressionType)
            case 'gzip'
                pyrun("compressors = numcodecs.GZip(level=Options_clevel)", ...
                    Options_clevel=int32(Options.compressionLevel));
            case 'blosc'
                pyrun("compressors = numcodecs.Blosc(cname='zstd', clevel=Options_clevel, shuffle=numcodecs.Blosc.BITSHUFFLE)", ...
                    Options_clevel=int32(Options.compressionLevel));
            otherwise
                error('Unsupported compression type: %s', Options.compressionType);
        end
    elseif Options.zarrFormat == 3
        switch lower(Options.compressionType)
            case 'gzip'
                pyrun("from numcodecs import GZip");
                pyrun("compressors = GZip(level=Options_clevel)", ...
                    Options_clevel=int32(Options.compressionLevel));
            case 'blosc'
                pyrun("from zarr.codecs import BloscCodec");
                pyrun("compressors = BloscCodec(cname='zstd', clevel=Options_clevel, shuffle='bitshuffle')", ...
                    Options_clevel=int32(Options.compressionLevel));
            otherwise
                error('Unsupported compression type: %s', Options.compressionType);
        end
    end
end

% ------------------
% Create arrays + dataset metadata
% ------------------
datasets = [];
for lvl = 1:numel(levelNames)
    % Compute level shape
    szLvl = max(ceil(imageSize(end-2:end) ./ scaleXYZ(lvl,:)),1);
    if strcmp(Options.dataType,'image')
        imageShape = [imageSize(1), imageSize(2), szLvl];
    else
        imageShape = [imageSize(1), szLvl];
    end

    storePath = fullfile(zarrPath, levelNames{lvl});

    if Options.zarrFormat == 2
        % use open_array function as create_array is not comatible with
        % dimension_separator parameter
        pyrun("zarr.open_array(store=store, shape=imageShape, chunks=imageChunks, dtype=dtype, compressor=compressors, zarr_format=2, dimension_separator='/', mode='w')", ...
            store=storePath, imageShape=int32(imageShape), imageChunks=int32(Options.chunks), dtype=imageType);
    elseif Options.zarrFormat == 3
        if ~isempty(Options.shards)
            pyrun("zarr.create_array(store=store, shape=imageShape, chunks=imageChunks, dtype=dtype, compressors=compressors, zarr_format=zarrFormat, shards=tuple(shards))", ...
                store=storePath, imageShape=int32(imageShape), imageChunks=int32(Options.chunks), dtype=imageType, ...
                zarrFormat=int32(Options.zarrFormat), shards=int32(Options.shards));
        else
            pyrun("zarr.create_array(store=store, shape=imageShape, chunks=imageChunks, dtype=dtype, compressors=compressors, zarr_format=zarrFormat)", ...
                store=storePath, imageShape=int32(imageShape), imageChunks=int32(Options.chunks), dtype=imageType, ...
                zarrFormat=int32(Options.zarrFormat));
        end
    else
        error('Unsupported zarr format type: %d', Options.zarrFormat);
    end

    % Metadata entry for this level
    scale       = Options.voxelSize .* scaleXYZ(lvl,:);   % physical voxel size
    translation = Options.levelTranslations(lvl,:);       % physical shift
    datasets = [datasets, struct( ...
        'path', levelNames{lvl}, ...
        'coordinateTransformations', { { ...
            struct('type','scale','scale',scale), ...
            struct('type','translation','translation',translation) ...
        } } ...
    )];
end

% ------------------
% Root attributes
% ------------------

% Axes: include T,C if present
if strcmp(Options.dataType,'image')
    axesList = { ...
        struct('type','time','name','t','unit','seconds'), ...
        struct('type','channel','name','c','unit',''), ...
        struct('type','space','name','z','unit',Options.voxelUnits), ...
        struct('type','space','name','y','unit',Options.voxelUnits), ...
        struct('type','space','name','x','unit',Options.voxelUnits) ...
    };
else
    axesList = { ...
        struct('type','time','name','t','unit','seconds'), ...
        struct('type','space','name','z','unit',Options.voxelUnits), ...
        struct('type','space','name','y','unit',Options.voxelUnits), ...
        struct('type','space','name','x','unit',Options.voxelUnits) ...
    };
end

zattrs_struct = struct( ...
    'multiscales', { { ...
        struct( ...
            'name', '', ...
            'type', Options.dataType, ...
            'version', '0.4', ...
            'axes', {axesList}, ...
            'datasets', {datasets}, ...
            'coordinateTransformations', {{} } ...
        ) } } ...
);

% Merge custom attributes
customFields = fieldnames(Options.customAttributes);
for k = 1:numel(customFields)
    fn = customFields{k};
    zattrs_struct.(fn) = Options.customAttributes.(fn);
end

% Encode as JSON for Python
zattrs_json = jsonencode(zattrs_struct);

% Write to root.attrs using zarr API with explicit zarr_format
if Options.zarrFormat == 2
    pyrun([ ...
        "root = zarr.open_group(storePath, mode='a', zarr_format=2)" ...
        "root.attrs.update(json.loads(attrs_json))" ...
        ], ...
        storePath=zarrPath, ...
        attrs_json=zattrs_json);
else
    pyrun([ ...
        "root = zarr.open_group(storePath, mode='a', zarr_format=3)" ...
        "root.attrs.update(json.loads(attrs_json))" ...
        ], ...
        storePath=zarrPath, ...
        attrs_json=zattrs_json);
end

% fprintf('Multiscale dataset created with %d levels at %s.\n', numel(levelNames), zarrPath);
end
