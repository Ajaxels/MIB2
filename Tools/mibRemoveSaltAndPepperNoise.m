function img = mibRemoveSaltAndPepperNoise(img, BatchOpt, cpuParallelLimit)
% function mibRemoveSaltAndPepperNoise(img, BatchOpt, cpuParallelLimit)
% remove salt and pepper noise from image. The images are filtered using
% the median filter, after that a difference between the original and the
% median filtered images is taken. Pixels that have threshold higher than
% BatchOpt.IntensityThreshold{1} value are considered as noise and removed
% 
% Parameters:
% img: image as [height, width, colors, depth]
% BatchOpt: structure with parameters
% @li .HSize - [char] strel element size for the median filter
% @li .IntensityThreshold{1} - [number] noise intensity threshold, pixels that have intensity variation of original image -minus- median filtered image higher than this number will be removed
% @li .NoiseType{1} - type of noise to remove; one of the following - ''salt and pepper'', ''salt only'', ''pepper only'', where salt refers for the
% white noise pixels, and pepper for the black noise pixels
% @li .showWaitbar - logical, show or not the waitbar
% @li .UseParallelComputing - logical, use or not the parallel computing
% cpuParallelLimit:  number of CPU to use for parallel processing
%
% Return values:
% img: denoised image

%| 
% @b Example:
% @code 
% I = imread('eight.tif');  // get image
% J = imnoise(I,'salt & pepper',0.05);  // add noise
% BatchOpt.HSize = '3';
% BatchOpt.IntensityThreshold{1} = 50;
% BatchOpt.NoiseType{1} = 'salt and pepper';
% Jfiltered = mibRemoveSaltAndPepperNoise(J, BatchOpt);

% Copyright (C) 05.12.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3; cpuParallelLimit = 0; end
if nargin < 2; BatchOpt = struct(); end
if ~isfield(BatchOpt, 'HSize'); BatchOpt.HSize = '3'; end
if ~isfield(BatchOpt, 'IntensityThreshold'); BatchOpt.IntensityThreshold{1} = 50; end
if ~isfield(BatchOpt, 'NoiseType'); BatchOpt.NoiseType{1} = 'salt and pepper'; end
if ~isfield(BatchOpt, 'showWaitbar'); BatchOpt.showWaitbar = true; end
if ~isfield(BatchOpt, 'UseParallelComputing'); BatchOpt.UseParallelComputing = false; end

hSize = str2num(BatchOpt.HSize); %#ok<ST2NM>
if numel(hSize) == 1; hSize = [hSize, hSize]; end

[height, width, colors, depth] = size(img);

% create waitbar
if BatchOpt.showWaitbar
    pwb = PoolWaitbar(depth, sprintf('Removing salt & pepper noise\nPlease wait...'), [], 'Salt & pepper');
else
    pwb = [];   % have to init it for parfor loops
end

% define usage of parallel computing
if BatchOpt.UseParallelComputing
    parforArg = cpuParallelLimit;
else
    parforArg = 0;
end

maxVal = intmax(class(img(1)));    % max value for the class

doBlack = ~isempty(strfind(BatchOpt.NoiseType{1}, 'pepper'));    % find dark pepper noise
doWhite = ~isempty(strfind(BatchOpt.NoiseType{1}, 'salt'));      % find white salt noise

%for z = 1:depth
imgClass = class(img(1));
parfor (z = 1:depth, parforArg)    
    for colCh = 1:colors
        I1 = img(:,:,colCh,z);  % get image
        I2 = medfilt2(img(:,:,colCh,z), hSize, 'symmetric');  % median filter        D = zeros([height, width], imgClass);
        D = zeros([height, width], imgClass); 
        
        if doBlack
            D = D + ((maxVal-I1) - (maxVal-I2));  % get hotpixels
        end
        if doWhite
            D = D + (I1-I2);  % get hotpixels
        end
        I1(D > BatchOpt.IntensityThreshold{1}) = I2(D > BatchOpt.IntensityThreshold{1});
        img(:,:,colCh,z) = I1;
    end
    if BatchOpt.showWaitbar == 1; pwb.increment(); end
end
if BatchOpt.showWaitbar == 1; delete(pwb); end
