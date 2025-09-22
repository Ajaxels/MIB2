% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 15.08.2025
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function writeSubvolumeToLevel(block_tczyx, zarrPath, levelName, tIndex, zStart, imageSwitch)
% function writeSubvolumeToLevel(block_tczyx, zarrPath, levelName, tIndex, zStart, imageSwitch)
% Write a 5D subvolume to a specified Zarr multiscale level.
%
% Parameters:
% block_tczyx : numeric array [T C Z Y X], the subvolume to write
% zarrPath    : string, path to the root Zarr store
% levelName   : string, name of the multiscale level (e.g., 's0', 's1')
% tIndex      : integer, time index (1-based) in the Zarr dataset
% zStart      : integer, starting Z index (1-based) in the Zarr dataset
% imageSwitch    : logical, when true, image with [t,c,z,y,x] dimensions is expected, otherwise labels with [t,z,y,x]

arguments
    block_tczyx {mustBeNumeric}
    zarrPath (1,:) char
    levelName (1,:) char
    tIndex (1,1) {mustBeInteger, mustBePositive}
    zStart (1,1) {mustBeInteger, mustBeNonnegative}
    imageSwitch logical = true
end

%pyrun("import zarr");
storePath = fullfile(zarrPath, levelName);

if imageSwitch  % images
    [T, C, Z, Y, X] = size(block_tczyx);
    pyrun(...
        "arr=zarr.open(storePath, mode='r+');"+...
        "arr[t0:t0+1, 0:C, z0:z0+Z, 0:Y, 0:X] = block", ...
        storePath=storePath, block=block_tczyx, ...
        t0=int32(tIndex-1), C=int32(C), Z=int32(Z), Y=int32(Y), X=int32(X), z0=int32(zStart-1));
else            % labels
    % Force channel = 1 for labels
    %if strcmp(imageSwitch,'label') && size(block_tczyx, 2) ~= 1
    %    block_tczyx = reshape(block_tczyx, [1, 1, size(block_tczyx,3), size(block_tczyx,4), size(block_tczyx,5)]);
    %end

    [T, Z, Y, X] = size(block_tczyx);
    pyrun(...
        "arr=zarr.open(storePath, mode='r+');"+...
        "arr[t0:t0+1, z0:z0+Z, 0:Y, 0:X] = block", ...
        storePath=storePath, block=block_tczyx, ...
        t0=int32(tIndex-1), Z=int32(Z), Y=int32(Y), X=int32(X), z0=int32(zStart-1));
end


