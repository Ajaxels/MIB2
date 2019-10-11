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
%     - .imgStretch [optional] -> stretch or not the image if it is uint32 class
%     - .Font -> [optional] a structure with the Font settings from mib to initialize new dialog
%           .FontName 
%           .FontUnits
%           .FontSize 
%     - .virtual - a switch to open dataset in the virtual mode
%     - .id - id of the current dataset, needed to generate filename for Memoizer class of BioFormats
%     - .BioFormatsMemoizerMemoDir -> obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats
%     - .BackgroundColorIntensity -> numeric, background intensity for cases, when width/height of combined images mismatch, when it is missing a dialog box is shown
%     - .BioFormatsIndices -> numeric, indices of images in file container to be opened with BioFormats 
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

if nargin < 2; options = struct(); end

if ~isfield(options, 'mibBioformatsCheck');    options.mibBioformatsCheck = 0; end
if ~isfield(options, 'waitbar');        options.waitbar = 0; end
if ~isfield(options, 'customSections');     options.customSections = 0; end
if ~isfield(options, 'mibPath');    options.mibPath = mibPath;  end
if ~isfield(options, 'imgStretch');    options.imgStretch = 1;  end
if ~isfield(options, 'Font');    options.Font = Font;  end
if ~isfield(options, 'virtual');    options.virtual = 0;  end
if ~isfield(options, 'id');    options.id = 1;  end
if ~isfield(options, 'BioFormatsMemoizerMemoDir');    options.BioFormatsMemoizerMemoDir = 'c:\temp';  end

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
    img = [];
    return;
end
tic;

% dealing with virtual stacks
if options.virtual == 1
    % check files
    errorText = [];
    if numel(unique([files.height])) > 1; errorText = 'Heights'; end
    if numel(unique([files.width])) > 1; errorText = 'Widths'; end
    if numel(unique([files.color])) > 1; errorText = 'Colors'; end
    if ~isempty(errorText)
        %errordlg(sprintf('!!! Error !!!\n\n%s of images mismatch!', errorText));
        img = [];
        return;
    end
    
    if files(1).color == 1
        img_info('ColorType') = 'grayscale';
    else
        img_info('ColorType') = 'truecolor';
    end
    img_info('Height') = files(1).height; % files(1).hDataset.getSizeY();
    img_info('Width') = files(1).width; % files(1).hDataset.getSizeX();
    img_info('Colors') = files(1).color; % files(1).hDataset.getSizeC();
    img_info('Time') = files(1).dim_xyczt(1,5); % files(1).hDataset.getSizeT();
    img_info('imgClass') = files(1).imgClass; 
    
    slicesPerFile = arrayfun(@(ind) files(ind).noLayers, 1:numel(files), 'UniformOutput', 1); % slicesPerFile = arrayfun(@(ind) files(ind).hDataset.getSizeZ(), 1:numel(files), 'UniformOutput', 1);
    slicesPerFile = slicesPerFile';
    img_info('Depth') = sum(slicesPerFile);
    % define readerId, which is a vector with length equal to the total
    % number of slices. Each element identifies the reader index for
    % desired slice number of the combined dataset:
    % readerId(5) = 3; indicates that slice number 5 is stored in the reader 3
    readerId = zeros([img_info('Depth'), 1]);   
    index = 0;
    for id=1:numel(slicesPerFile)
        for sliceId = 1:slicesPerFile(id)
            index = index + 1;
            readerId(index) = id;
        end
    end
    img_info('Virtual_slicesPerFile') = slicesPerFile;
    img_info('Virtual_readerId') = readerId;
    img_info('Virtual_filenames') = filenames';     % get filenames, needed for deep copy of the reader
    
    Virtual_objectType = cell([numel(files), 1]);
    Virtual_seriesName = cell([numel(files), 1]);
    
    if ~isKey(img_info,'ImageDescription'); img_info('ImageDescription') = ''; end
    [img_info, pixSize] = mibUpdatePixSizeAndResolution(img_info, pixSize);
    img = cell([numel(files), 1]);
    for i=1:numel(files)
        switch files(i).object_type
            case 'bioformats'
                %img{i} = files(i).hDataset;   % get readers
                img{i} = files(i).origFilename;
            case {'matlab.hdf5', 'hdf5_image'}
                img{i} = files(i).filename;   % get readers
            %case 'amiramesh'
            %    img{i} = files(i).filename;   % get readers
            otherwise
                errordlg('This format is not yet implemented for the virtual mode!');
                img = [];
                return; 
        end
        Virtual_objectType{i} = files(i).object_type;
        if iscell(files(i).seriesName)
            Virtual_seriesName(i) = files(i).seriesName;
        else
            Virtual_seriesName{i} = files(i).seriesName;
        end
    end
    img_info('Virtual_objectType') = Virtual_objectType;
    img_info('Virtual_seriesName') = Virtual_seriesName;
    toc;
    return;
end

% fill img_info and preallocate memory for the dataset
% check files for dimensions and class
if options.imgStretch == 1
    if strcmp(files(1).imgClass, 'int16') || strcmp(files(1).imgClass, 'uint32') %|| ...
        %strcmp(files(1).imgClass, 'single') || strcmp(files(1).imgClass, 'double')    
        choice = questdlg(sprintf('The original image is in the %s format\n\nIt will be converted into uint16 format!', files(1).imgClass), ...
            'Image Format Warning!', ...
            'Sure', 'Keep 32bit', 'Cancel', 'Sure');
        if strcmp(choice, 'Cancel'); img = []; return; end
        if strcmp(choice, 'Keep 32bit');options.imgStretch = 0; end
    end
end

if numel(unique(cell2mat({files.color}))) > 1 || numel(unique(cell2mat({files.height}))) > 1 || numel(unique(cell2mat({files.width}))) > 1 && autoCropSw==0
    if ~isfield(options, 'BackgroundColorIntensity')
        answer = mibInputDlg({options.mibPath}, sprintf('!!! Warning !!!\nThe XY dimensions or number of color channels mismatch!\nContinue anyway?\n\nEnter the background color intensity (0-%d):', intmax(files(1).imgClass)),'Dimensions mismatch', num2str(intmax(files(1).imgClass)));
        if isempty(answer)
            img=[];
            return;
        end
        files(1).backgroundColor = str2double(answer{1});   % add information about background color
    else
        files(1).backgroundColor = options.BackgroundColorIntensity;   % add information about background color
    end
    
end

% loading the datasets
getImagesOpt.waitbar = options.waitbar;
getImagesOpt.imgStretch = options.imgStretch;
[img, img_info] = mibGetImages(files, img_info, getImagesOpt);
[img_info, pixSize] = mibUpdatePixSizeAndResolution(img_info, pixSize);
toc
end

