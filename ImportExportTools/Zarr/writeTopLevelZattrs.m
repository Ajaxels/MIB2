function writeTopLevelZattrs(zarrPath, levelNames, scaleXYZ, levelImageTranslations, voxelSize, voxelUnits, zarrFormat)
% writeTopLevelZattrs
% Creates top-level .zattrs and .zgroup for a multiscale Zarr dataset.
%
% Parameters:
% zarrPath               : string, root Zarr folder where .zattrs and .zgroup will be written
% levelNames              : cell array of strings, e.g., {'s0','s1','s2'}
% scaleXYZ                : [nLevels x 3] numeric array of scale factors relative to original [z y x]
% levelImageTranslations  : [nLevels x 3] physical translations (same units as voxelSize) for each level
% voxelSize               : [1 x 3] numeric array, physical size of one voxel along [z y x]
% voxelUnits              : string, units for the axes ('nanometers', 'micrometers', 'millimeters', 'pixels')
%                            Default: 'micrometers'
% zarrFormat              : number with zarr format version, 2 or 3
%
% The translations and scales are written in MoBIE/N5 OME-Zarr compatible format.

arguments
    zarrPath (1,:) char
    levelNames cell
    scaleXYZ (:,3) double
    levelImageTranslations (:,3) double
    voxelSize (1,3) double {mustBePositive}
    voxelUnits (1,:) char = 'micrometers'
    zarrFormat (1,1) double = 2
end

if ~isfolder(zarrPath)
    mkdir(zarrPath);
end

% Build datasets array for each level
datasets = [];
for i = 1:numel(levelNames)
    scale       = voxelSize .* scaleXYZ(i,:);          % physical scale in [z y x]
    translation = levelImageTranslations(i,:);        % physical translation in [z y x]

    dataset_struct = struct( ...
        'path', levelNames{i}, ...
        'coordinateTransformations', { { ...
            struct('type','scale','scale',scale), ...
            struct('type','translation','translation',translation) ...
        } } ...
    );

    datasets = [datasets, dataset_struct];
end

% Build top-level JSON structure
zattrs_struct = struct( ...
    'multiscales', { { ...
        struct( ...
            'name', '', ...  % placeholder for dataset name
            'type', 'Average', ...
            'version', '0.4', ...
            'axes', { { ...
                struct('type','space','name','z','unit',voxelUnits), ...
                struct('type','space','name','y','unit',voxelUnits), ...
                struct('type','space','name','x','unit',voxelUnits) ...
            } }, ...
            'datasets', {datasets}, ...
            'coordinateTransformations', {{} } ...
        ) } } ...
);

% Convert to JSON
jsonStr = jsonencode(zattrs_struct, 'PrettyPrint', true);

% Write .zattrs
fid = fopen(fullfile(zarrPath,'.zattrs'),'w');
fwrite(fid,jsonStr,'char');
fclose(fid);

% Create .zgroup
fid = fopen(fullfile(zarrPath,'.zgroup'),'w');
fwrite(fid, sprintf('{"zarr_format": %d}', zarrFormat));
fclose(fid);

fprintf('Top-level .zattrs and .zgroup created at %s\n', zarrPath);
end