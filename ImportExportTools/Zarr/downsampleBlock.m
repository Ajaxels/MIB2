% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 15.08.2025
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function out = downsampleBlock(chunkData, relFactors, imageSwitch)
% function out = downsampleBlock(chunkData, relFactors, imageSwitch)
% Downsample a 5D block ([T C Z Y X]) by relative factors.
%
% Parameters:
% chunkData : numeric array [T C Z Y X], input block to downsample
% relFactors : 1x3 numeric array, relative downsampling factors [Z_factor Y_factor X_factor]
% imageSwitch : logical, when true, image with [t,c,z,y,x] dimensions is expected, otherwise labels with [t,z,y,x]
%
% Returns:
% out        : numeric array [T C newZ newY newX], downsampled block with same class as input

arguments
    chunkData {mustBeNumeric}
    relFactors (1,3) {mustBePositive, mustBeFinite}
    imageSwitch logical = true
end

chunkSize = size(chunkData);
Z = chunkSize(end-2);
Y = chunkSize(end-1);
X = chunkSize(end);
T = chunkSize(1);

newZ = max(floor(Z / relFactors(1)), 1);
newY = max(floor(Y / relFactors(2)), 1);
newX = max(floor(X / relFactors(3)), 1);

% Choose interpolation method
interpMethod = 'cubic';
if ~imageSwitch % labels
    interpMethod = 'nearest';
end

if imageSwitch  % images
    C = chunkSize(2);
    out = zeros([T, C, newZ, newY, newX], class(chunkData));
    % Downsample each time point and channel separately
    if newZ > 1 % 3D chunkData
        for t = 1:T
            for c = 1:C
                out(t,c,:,:,:) = imresize3(squeeze(chunkData(t,c,:,:,:)), [newZ, newY, newX], interpMethod);
            end
        end
    else % 2D block 
        for t = 1:T
            for c = 1:C
                out(t,c,:,:,:) = imresize(squeeze(chunkData(t,c,1,:,:)), [newY, newX], interpMethod);
            end
        end
    end
else        % labels
    out = zeros([T, newZ, newY, newX], class(chunkData));
    % Downsample each time point and channel separately
    if newZ > 1 % 3D chunkData
        for t = 1:T
            out(t,:,:,:) = imresize3(squeeze(chunkData(t,:,:,:)), [newZ, newY, newX], interpMethod);
        end
    else
        for t = 1:T
            out(t,:,:,:) = imresize(squeeze(chunkData(t,1,:,:)), [newY, newX], interpMethod);
        end
    end
end
