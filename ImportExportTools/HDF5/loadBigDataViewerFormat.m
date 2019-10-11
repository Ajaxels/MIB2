function [I, img_info] = loadBigDataViewerFormat(filename, options, img_info)
% function [I, img_info] = loadBigDataViewerFormat(filename, options, img_info)
% Read completely the BigDataViewer format of Fiji into Matlab
%
% The format description: http://fiji.sc/BigDataViewer#About_the_BigDataViewer_data_format
%
% Parameters:
% filename: name of the file: xml or h5
% options:  [@em optional], a structure with extra parameters
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose, height
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose, width
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth
% @li .c -> [@em optional], [indices] coordinates of the dataset to take after transpose, depth
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
% @li .level -> [@em optional], magnification level of the pyramid: 1-for unbinned
% @li .waitbar -> [@em optional] @b 0 - no waitbar, @b 1 - show waitbar
% img_info: [@em optional] a container.Maps with details of the dataset obtained from XML file
%
% Return values:
% I: a dataset
% img_info: img_info structure with parameters of the dataset

%|
% @b Examples:
% @code [I, img_info] = loadBigDataViewerFormat('mydataset.h5');   // read dataset @endcode
% @code 
% options.x = [50 500];     // define subarea to take
% options.y = [50 500];
% options.level = 2;        // define level of the image pyramid
% [I, img_info] = loadBigDataViewerFormat('mydataset.h5', options);   // load subarea of the dataset 
% @endcode

% Copyright (C) 31.01.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 3; img_info = containers.Map; end
if nargin < 2; options=struct(); end
if nargin < 1
    errordlg(sprintf('!!! Error !!!\n\nThe filename is missing!\nI = loadBigDataViewerFormat(filename, options)'));
    return;
end
I = [];

if ~isfield(options, 'waitbar');    options.waitbar = 1; end

if options.waitbar; wb = waitbar(0, sprintf('Loading HDF5 file structure\nPlease wait...'), 'Name', 'Loading HFD5...'); end

info = h5info(filename);
offsetIndex = find(ismember({info.Groups(:).Name}, '/t00000') == 1);  % index of the first timepoint

if isempty(img_info)   % when no img_info, populate it from the HDF5 file
    % initialize default
    pixSize.x = 1;
    pixSize.y = 1;
    pixSize.z = 1;
    pixSize.units = 'um';
    pixSize.t = 1;
    pixSize.tunits = 'sec';

    groupNames = {info.Groups.Name};    % get group names
    setupsId = strfind(groupNames, '/s');   % find number of color channels
    img_info('Colors') = sum(cell2mat(setupsId));
    
    img_info('channelNames') = arrayfun(@(x) cellstr(x.Name), info.Groups(2:offsetIndex-1));
    if img_info('Colors') > 1
        img_info('ColorType') = 'truecolor';
    else
        img_info('ColorType') = 'grayscale';
    end
    img_info('Time') = sum(cell2mat(strfind({info.Groups(:).Name}, '/t')));
    img_info('ImageDescription') = '';
    img_info('XResolution') = [];
    img_info('YResolution') = [];
    img_info('ResolutionUnit') = 'Inch';
    img_info('Filename') = filename;
    img_info('pixSize') = pixSize;
    img_info('Format') = 'bdv.hdf5';    % assign as big data viewer format
    
    noLevels = numel(info.Groups(offsetIndex).Groups(1).Groups);  % number of levels in the image pyramid
    
    if isfield(options, 'level')  % level of the pyramid to return, 1 for full resolution
        if options.level(1) < 1 || options.level(1) > noLevels
            if options.waitbar; delete(wb); end
            errordlg(sprintf('!!! Error !!!\n\nThe level value (%d) is out of range!\nThe "options.level" should be between 1 and %d', options.level, noLevels));
            return;
        end
        img_info('ReturnedLevel') = options.level;
    else
        prompt = sprintf('The dataset contains %d image(s)\nPlease choose the one to take (enter "1" to get image in the original size):', noLevels);
        answer = mibInputDlg([], prompt, 'Select image', '1');
        if isempty(answer); if options.waitbar==1; delete(wb); end; return; end
        img_info('ReturnedLevel') = str2double(answer);
        if img_info('ReturnedLevel') < 1 || img_info('ReturnedLevel') > noLevels
            errordlg(sprintf('!!! Error !!!\n\nWrong number!\nThe number should be between 1 and %d', noLevels));
            return;
        end
    end
    xyzVal = info.Groups(offsetIndex).Groups(1).Groups(img_info('ReturnedLevel')).Datasets.Dataspace.Size;    % unbinned
    img_info('Height') = xyzVal(2);
    img_info('Width') = xyzVal(1);
    img_info('Depth') = xyzVal(3);
    img_info('Levels') = noLevels;
    if img_info('Time') == 0; img_info('Time') = 1; end
    % detect data type
    dataType = info.Groups(offsetIndex).Groups(1).Groups(img_info('ReturnedLevel')).Datasets.Datatype.Type;
    switch dataType
        case {'H5T_STD_I16LE','H5T_STD_U16LE'}
            img_info('imgClass') = 'uint16';
        case {'H5T_STD_I8LE','H5T_STD_U8LE'}
            img_info('imgClass') = 'uint8';
        otherwise
            if options.waitbar==1; delete(wb); end
            errordlg(sprintf('Ops!\nloadBigDataViewerFormat: check image class (%s) and implement!', dataType));
            return;
    end
end
dataType = info.Groups(offsetIndex).Groups(1).Groups(img_info('ReturnedLevel')).Datasets.Datatype.Type;

% define part of the dataset to take
if isfield(options, 'x')   % min/max width
    if options.x(1) < 1 || options.x(1) > img_info('Width') || options.x(2) < 1 || options.x(2) > img_info('Width')
        if options.waitbar==1; delete(wb); end
        errordlg(sprintf('!!! Error !!!\n\nThe X value [%d:%d] is out of range!\nThe "options.x" should be between 1 and %d', options.x(1),options.x(2),img_info('Width')));
    end
    x = options.x;
else
    x = [1 img_info('Width')];
end
if isfield(options, 'y')   % min/max height
    if options.y(1) < 1 || options.y(1) > img_info('Height') || options.y(2) < 1 || options.y(2) > img_info('Height')
        if options.waitbar==1; delete(wb); end
        errordlg(sprintf('!!! Error !!!\n\nThe Y value [%d:%d] is out of range!\nThe "options.y" should be between 1 and %d', options.y(1),options.y(2),img_info('Height')));
    end
    y = options.y;
else
    y = [1 img_info('Height')];
end
if isfield(options, 'z')   % min/max depth, z
    if options.z(1) < 1 || options.z(1) > img_info('Depth') || options.z(2) < 1 || options.z(2) > img_info('Depth')
        if options.waitbar==1; delete(wb); end
        errordlg(sprintf('!!! Error !!!\n\nThe Z value [%d:%d] is out of range!\nThe "options.z" should be between 1 and %d', options.z(1),options.z(2),img_info('Depth')));
    end
    z = options.z;
else
    z = [1 img_info('Depth')];
end
if isfield(options, 'c')   % vector of color channels
    if min(options.c) < 1 || max(options.c) > img_info('Colors')
        if options.waitbar==1; delete(wb); end
        errordlg(sprintf('!!! Error !!!\n\nThe C value is out of range!\nThe "options.c" should be between 1 and %d', img_info('Colors')));
    end
    c = options.c;
else
    c = 1:img_info('Colors');
end
if isfield(options, 't')   % min/max time point
    if options.t(1) < 1 || options.t(1) > img_info('Time') || options.z(2) < 1 || options.z(2) > img_info('Time')
        if options.waitbar==1; delete(wb); end
        errordlg(sprintf('!!! Error !!!\n\nThe T value [%d:%d] is out of range!\nThe "options.t" should be between 1 and %d', options.t(1),options.t(2),img_info('Time')));
    end
    t = options.t;
else
    t = [1 img_info('Time')];
end

width = diff(x)+1;
height = diff(y)+1;
depth = diff(z)+1;
level = img_info('ReturnedLevel');

dataset = zeros([width, height, depth, numel(c), diff(t)+1], img_info('imgClass'));  % allocate space
%dataset = zeros([height, width, depth, numel(c), diff(t)+1], img_info('imgClass'));  % allocate space
timeCount = 0;  % time index for the output
if options.waitbar; waitbar(0.05, wb, sprintf('Loading HDF5 images\nPlease wait...')); end

for timePnt=t(1):t(2)
    timeIndex = timePnt + offsetIndex - 1;  % index in the HDF5 file
    timeCount = timeCount + 1;
    % assuming 1 setup
    for ch=c
        groupName = info.Groups(timeIndex).Groups(ch).Groups(level).Name;
        datasetName = info.Groups(timeIndex).Groups(ch).Groups(level).Datasets.Name;
        dummy = h5read(filename, [groupName '/' datasetName], [x(1), y(1), z(1)], [width, height, depth]);
        %dummy = h5read(filename, [groupName '/' datasetName], [y(1), x(1), z(1)], [height width depth]);
        
        % have to typecast, otherwise
        % example = h5read('mitosis.h5', '/t00000/s00/0/cells');
        % min(example(:)) == -32748
        
        switch dataType
            case 'H5T_STD_U16LE'
            
            case 'H5T_STD_U8LE'
                
            case 'H5T_STD_I16LE'
                dummy2 = typecast(dummy(:),'uint16');
                dummy = reshape(dummy2, size(dummy));
            case 'H5T_STD_I8LE'
                dummy2 = typecast(dummy(:),'uint8');
                dummy = reshape(dummy2, size(dummy));
        end
        
        dataset(:,:,:,ch, timePnt) = dummy;
    end
    if options.waitbar; waitbar((timePnt-t(1))/(diff(t)+1), wb, sprintf('Loading HDF5 images\nPlease wait...')); end
end
I = permute(dataset, [2 1 4 3 5]);    % permute for MIB [y,x,c,z,t];

% test of read string
% dummy = h5read(fullfileH5, [info.Groups(1).Name '/' info.Groups(1).Datasets(1).Name]);

if options.waitbar; delete(wb); end
end



