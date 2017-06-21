function [img, img_info, pixSize] = mibLoadImages(filenames, options)
% function [img, img_info, pixSize] = mibLoadImages(filenames, options)
% Load images from the list of files
% 
% Load images contained in the array of cells 'filesnames' and return 'img_info' containers.Map 
%
% Parameters:
% filenames: array of cells with filenames
% options: -> a structure with parameters
%     - .mibBioformatsCheck -> if @b 0 -> open standard image types, if @b 1 -> open images using BioFormats library
%     - .waitbar -> @b 1 - show waitbar, @b 0 - do not show waitbar
%     - .customSections -> @b 0 or @b 1, when @b 1 take some custom section(s) from the dataset
%     - .mibPath [optional] a string with path to MIB directory, an optional parameter to mibInputDlg.m 
%     - .Font -> [optional] a structure with the Font settings from mib to initialize new dialog
%           .FontName 
%           .FontUnits
%           .FontSize 
%
% Return values:
% img: - a dataset, [1:height, 1:width, 1:colors, 1:no_stacks]
% img_info: - a containers.Map with meta-data and image details
% pixSize: - a structure with voxel dimensions,
% @li .x - physical width of a pixel
% @li .y - physical height of a pixel
% @li .z - physical thickness of a pixel
% @li .t - time between the frames for 2D movies
% @li .tunits - time units
% @li .units - physical units for x, y, z. Possible values: [m, cm, mm, um, nm]

% Copyright (C) 06.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
global mibPath;
global Font;

tic
if nargin < 2; options = struct(); end

if ~isfield(options, 'mibBioformatsCheck');    options.mibBioformatsCheck = 0; end
if ~isfield(options, 'waitbar');        options.waitbar = 0; end
if ~isfield(options, 'customSections');     options.customSections = 0; end
if ~isfield(options, 'mibPath');    options.mibPath = mibPath;  end
if ~isfield(options, 'Font');    options.Font = Font;  end

autoCropSw = 0;     % auto crop images that have dimension mismatch

no_files = numel(filenames);

files = struct();   % structure that keeps info about each file in the series
% .object_type -> 'movie', 'hdf5_image', 'image'
% .seriesName -> name of the series for HDF5
% .height
% .width
% .color
% .noLayers -> number of image frames in the file
% .imgClass -> class of the image

for i=1:no_files
    files(i).filename = cell2mat(filenames(i));
end
[img_info, files, pixSize] = mibGetImageMetadata(filenames, options); % get meta data for the datasets
if isempty(keys(img_info))
    img = NaN;
    return;
end

% fill img_info and preallocate memory for the dataset
% check files for dimensions and class
if strcmp(files(1).imgClass, 'int16') || strcmp(files(1).imgClass, 'uint32')
    choice = questdlg(sprintf('The original image is in the %s format\n\nIt will be converted into uint16 format!', files(1).imgClass), ...
        'Image Format Warning!', ...
        'Sure','Cancel','Sure');
    if strcmp(choice, 'Cancel')
        img = NaN;
        return;
    end
end

if numel(unique(cell2mat({files.color}))) > 1 || numel(unique(cell2mat({files.height}))) > 1 || numel(unique(cell2mat({files.width}))) > 1 && autoCropSw==0
    answer = mibInputDlg({options.mibPath}, sprintf('!!! Warning !!!\nThe XY dimensions or number of color channels mismatch!\nContinue anyway?\n\nEnter the background color intensity (0-%d):', intmax(files(1).imgClass)),'Dimensions mismatch','0');
    if isempty(answer)
        img=NaN;
        return;
    end
    files(1).backgroundColor = str2double(answer{1});   % add information about background color
end

% loading the datasets
getImagesOpt.waitbar = options.waitbar;
[img, img_info] = mibGetImages(files, img_info, getImagesOpt);
[img_info, pixSize] = mibUpdatePixSizeAndResolution(img_info, pixSize);
toc
end

