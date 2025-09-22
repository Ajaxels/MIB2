% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 15.08.2025
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function [levelNames, scaleFactors, levelImageTranslations, levelImageSizes] = calculateMultiscaleLevels(imageSize, voxelSize, minImageSize)
% function [levelNames, scaleFactors, levelImageTranslations, levelImageSizes] = calculateMultiscaleLevels(imageSize, voxelSize, minImageSize)
% Calculate multiscale levels and cumulative downsampling factors.
%
% First step: downsample high-resolution axes to make voxels isotropic.
% Subsequent steps: uniform 2x downsampling until any dimension reaches minImageSize.
%
% Parameters:
% imageSize    : [z y x] numeric array
% voxelSize    : [z y x] numeric array
% minImageSize : [z y x] numeric array
%
% Returns:
% levelNames   : {'s0','s1',...}
% scaleFactors : nLevels x 3 numeric array of cumulative per-axis downsampling factors
% levelImageSizes   : nLevels x 3 numeric array of image sizes at each level
% levelImageTranslations : [nLevels x 3] physical translation offsets relative to s0

arguments
    imageSize (1,3) {mustBeInteger, mustBePositive}
    voxelSize (1,3) {mustBePositive}
    minImageSize (1,3) {mustBeInteger, mustBePositive}
end

levelNames   = {'s0'};
scaleFactors = ones(1,3);      % cumulative downsampling relative to original
levelImageSizes   = imageSize;      % size at each level
levelImageTranslations = zeros(1,3);     % physical offsets relative to s0

currentSize    = imageSize;
currentVoxel   = voxelSize;
cumulativeFactor = ones(1,3);
currentTranslation = zeros(1,3);

% --- Step 1: isotropic voxel adjustment ---
factor   = ones(1,3);
maxVoxel = max(currentVoxel);
for dim = 1:3
    if currentVoxel(dim) < maxVoxel
        factor(dim) = 2;
    end
end

% compute translation offset from rounding
offsetVoxels = (mod(currentSize, factor) ~= 0) .* 0.5 .* voxelSize .* cumulativeFactor;
currentTranslation = currentTranslation + offsetVoxels;

currentSize    = ceil(currentSize ./ factor);
currentVoxel   = currentVoxel .* factor;
cumulativeFactor = cumulativeFactor .* factor;

levelNames{end+1}      = 's1';
scaleFactors(end+1,:)  = cumulativeFactor;
levelImageSizes(end+1,:)    = currentSize;
levelImageTranslations(end+1,:)  = currentTranslation;

% --- Step 2: uniform downsampling ---
lvl = 2;
while all(currentSize > minImageSize)
    factor = ones(1,3);
    for dim = 1:3
        if currentSize(dim) > minImageSize(dim)
            factor(dim) = 2;
        end
    end

    % Stop if any dimension would go below minImageSize
    if any(currentSize ./ factor < minImageSize)
        break;
    end

    % compute translation offset from rounding
    offsetVoxels = (mod(currentSize, factor) ~= 0) .* 0.5 .* voxelSize .* cumulativeFactor;
    currentTranslation = currentTranslation + offsetVoxels;

    currentSize    = ceil(currentSize ./ factor);
    currentVoxel   = currentVoxel .* factor;
    cumulativeFactor = cumulativeFactor .* factor;

    levelNames{end+1}      = sprintf('s%d', lvl);
    scaleFactors(end+1,:)  = cumulativeFactor;
    levelImageTranslations(end+1,:)  = currentTranslation;
    levelImageSizes(end+1,:)    = currentSize;

    lvl = lvl + 1;
end
end