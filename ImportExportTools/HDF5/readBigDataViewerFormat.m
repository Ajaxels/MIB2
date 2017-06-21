function [img_info, I] = readBigDataViewerFormat(filename, orient, options)
% function [img_info, I] = readBigDataViewerFormat(filename, orient, options)
% Read completely the BigDataViewer format of Fiji into Matlab
%
% The format description: http://fiji.sc/BigDataViewer#About_the_BigDataViewer_data_format
%
% Parameters:
% filename: name of the file: xml or h5
% orient: [@em optional], can be @em NaN
% @li when @b 0 (@b default) returns the dataset transposed to the current orientation (obj.orientation)
% @li when @b 1 returns transposed dataset to the zx configuration: [y,x,c,z,t] -> [x,z,c,y,t]
% @li when @b 2 returns transposed dataset to the zy configuration: [y,x,c,z,t] -> [y,z,c,y,t]
% @li when @b 3 not used
% @li when @b 4 returns original dataset to the yx configuration: [y,x,c,z,t]
% @li when @b 5 not used
% options:  [@em optional], a structure with extra parameters
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose, height
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose, width
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth
% @li .c -> [@em optional], [indices] coordinates of the dataset to take after transpose, depth
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
% @li .level -> [@em optional], magnification level of the pyramid: 1-for unbinned
%
% Return values:
% img_info: containers.Map with metadata
% I: [@em optional], a dataset 

%| 
% @b Examples:
% @code img_info = readBigDataViewerFormat('mydataset.xml');  // read only metadata @endcode
% @code img_info = readBigDataViewerFormat('mydataset.h5');  // read only metadata directly from hdf5 dataset @endcode
% @code [img_info, I] = readBigDataViewerFormat('mydataset.xml');   // read both metadata and dataset @endcode

% Copyright (C) 21.01.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 3; options=struct(); end;
if nargin < 2; orient=4; end;
if nargin < 1; 
    filename = 'mitosis_default_parameters.xml';
    %filename = 'mitosis_3setups.xml';
    %filename = 'confocal-series-8bit.xml';   % still stored as 16 bit end;
end

if orient == 0 || isnan(orient); orient = 4; end;
[dirName, baseName, extName] = fileparts(filename);  % get the absolute directory and extension of the dataset
img_info = containers.Map; % allocate img_info;

% initialize default
pixSize.x = 1;
pixSize.y = 1;
pixSize.z = 1;
pixSize.units = 'um';
pixSize.t = 1;
pixSize.tunits = 'sec';

if strcmpi(extName, '.xml')    % get meta structure
    metaStr = xml2struct(filename);  % get XML structure
    datasetName = fields(metaStr);  % name of the field that contains the metadata
    datasetName = datasetName{1};   % convert to char

    % get filename
    fileH5 = metaStr.(datasetName).SequenceDescription.ImageLoader.hdf5.Text;   % name of hdf5 file
    fullfileH5 = fullfile(dirName, fileH5);   % generate fullfile name for the hdf5
    fullfileXML = filename;
    
    img_info('Format') = metaStr.(datasetName).SequenceDescription.ImageLoader.Attributes.format;
    
    img_info('Colors') = numel(metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup);
    
    % convert ViewSetup to cell when there is only 1 entry
    if ~iscell(metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup)
        ViewSetup{1} = metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup;
    else
        ViewSetup = metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup;
    end
    %if isfield(metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup{1}, 'name')
    if isfield(ViewSetup{1}, 'name')
        %img_info('channelNames') = cellfun(@(x) x.name.Text, metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup', 'UniformOutput', false);
        img_info('channelNames') = cellfun(@(x) x.name.Text, ViewSetup', 'UniformOutput', false);
    else
        img_info('channelNames') = cellfun(@(x) x.id.Text, ViewSetup', 'UniformOutput', false);
    end
    
%     xyzVal = str2num(metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup{1}.size.Text); %#ok<ST2NM>
%     img_info('Height') = xyzVal(2);
%     img_info('Width') = xyzVal(1);
%     img_info('Depth') = xyzVal(3);
    if img_info('Colors') > 1
        img_info('ColorType') = 'truecolor';
    else
        img_info('ColorType') = 'grayscale';
    end
    %t1 = str2double(metaStr.(datasetName).SequenceDescription.Timepoints.first.Text);
    t2 = str2double(metaStr.(datasetName).SequenceDescription.Timepoints.last.Text)+1;
    %img_info('Time') = [t1 t2];
    img_info('Time') = t2;
    img_info('ImageDescription') = '';
    img_info('XResolution') = [];
    img_info('YResolution') = [];
    img_info('ResolutionUnit') = 'Inch';
    img_info('Filename') = fullfileH5;
    %img_info('SliceName') - [optional] a cell array with names of the slices; for combined Z-stack, it is a name of the file that corresponds to the slice. Dimensions of the array should be equal to the obj.no_stacks
    if isfield(ViewSetup{1}, 'voxelSize')
        units = ViewSetup{1}.voxelSize.unit.Text;
        if strcmp(units, sprintf('\xB5m'))
            units = 'um';
        end
        pixSize.units = units;
        voxels = str2num(ViewSetup{1}.voxelSize.size.Text); %#ok<ST2NM>
        pixSize.x = voxels(1);
        pixSize.y = voxels(2);
        pixSize.z = voxels(3);
    end
    img_info('pixSize') = pixSize;
else
    fullfileH5 = filename;
    fullfileXML = [];
end

% 5D dataset, 5Z, 2C, 50T
info = h5info(fullfileH5);
offsetIndex = find(ismember({info.Groups(:).Name}, '/t00000') == 1);  % index of the first timepoint
if isempty(fullfileXML)
    groupNames = {info.Groups.Name};    % get group names
    setupsId = strfind(groupNames, '/s');   % find number of color channels
    img_info('Colors') = sum(cell2mat(setupsId));

    img_info('channelNames') = arrayfun(@(x) cellstr(x.Name), info.Groups(2:offsetIndex-1));
    if img_info('Colors') > 1
        img_info('ColorType') = 'truecolor';
    else
        img_info('ColorType') = 'grayscale';
    end
    %img_info('Time') = numel(info.Groups) - offsetIndex + 1;
    img_info('Time') = sum(cell2mat(strfind({info.Groups(:).Name}, '/t')));
    img_info('ImageDescription') = '';
    img_info('XResolution') = [];
    img_info('YResolution') = [];
    img_info('ResolutionUnit') = 'Inch';
    img_info('Filename') = fullfileH5;
    img_info('pixSize') = pixSize;
    img_info('Format') = 'bdv.hdf5';    % assign as big data viewer format
end

noLevels = numel(info.Groups(offsetIndex).Groups(1).Groups);  % number of levels in the image pyramid

if isfield(options, 'level');   % level of the pyramid to return, 1 for full resolution
    if options.level(1) < 1 || options.level(1) > noLevels
        errordlg(sprintf('!!! Error !!!\n\nThe level value (%d) is out of range!\nThe "options.level" should be between 1 and %d', options.level, noLevels));
    end
    level = options.level;
else
    level = 1;
end
xyzVal = info.Groups(offsetIndex).Groups(1).Groups(level).Datasets.Dataspace.Size;    % unbinned
img_info('Height') = xyzVal(2);
img_info('Width') = xyzVal(1);
img_info('Depth') = xyzVal(3);
img_info('ReturnedLevel') = level;
img_info('Levels') = noLevels;

if img_info('Time') == 0; img_info('Time') = 1; end;

dataType = info.Groups(offsetIndex).Groups(1).Groups(level).Datasets.Datatype.Type;
if strcmp('H5T_STD_I16LE', dataType)
    img_info('imgClass') = 'uint16';
else
    errordlg('Check image class, i.e. implement uint8!');
end

% % a bit on a format;
% info.Groups(1);           % Name: '/__DATA_TYPES__' 
% info.Groups(2);           % Name: '/s00'; color channel 1,   2 datasets: 'resolutions' and 'subdivisions'
% % read resolutions, i.e. number of setups in pyramid.
% % resolutions(:,1) -> [1; 1; 1] -> original dataset without binning
% % resolutions(:,2) -> [2; 2; 2] -> bin2 in each direction
% % resolutions(:,3) -> [4; 4; 2] -> bin4 in XY and 2 in Z
% resolutions = h5read(fullfileH5, [info.Groups(2).Name '/' info.Groups(2).Datasets(1).Name]);  
% 
% info.Groups(3);           % Name: '/s01'; color channel 2,   2 datasets: 'resolutions' and 'subdivisions'
% resolutions = h5read(fullfileH5, [info.Groups(2).Name '/' info.Groups(2).Datasets(1).Name]);  % read resolutions
% 
% % info.Groups(4:54) - time points
% info.Groups(offsetIndex);           % Name '/t00000', first time point, has 2 Groups by number of color channels
% info.Groups(offsetIndex).Groups;     % has 2 Groups by number of color channels: /t00000/s00 and /t00000/s01
% info.Groups(offsetIndex).Groups(1).Groups;     % has 1 (mitosis_default_parameters)
% %               (could be more if multi-angle SPIM sequence, i.e. drosophila.h5 = 4) datasets, Name: '/t00000/s00/0'
% %               or pyramid i.e. mitosis_3setups.h5 = 3) datasets, Names:
% %               '/t00000/s00/0', '/t00000/s00/1', '/t00000/s00/2'
% info.Groups(offsetIndex).Groups(1).Groups(1).Datasets;     % dataset details
% 
% % read dataset '/t00000/s00/0/cells'
% offsetIndex = 4;     % offset in the indices of HDF5 file, the offsetIndex has index of the first time point
% cMax = numel(info.Groups(offsetIndex).Groups);   % number of color channels
% setupId = 1;    % 1 - for the unbinned dataset
% dimentions = info.Groups(offsetIndex).Groups(1).Groups(setupId).Datasets.Dataspace.Size;    % unbinned
% tMax = numel(info.Groups)-offsetIndex+1;

if nargout > 1  % get dataset when required
    
    if ~strcmpi(img_info('Format'), 'bdv.hdf5')
        I = [];
        meta = [];
        errordlg(sprintf('!!! Wrong format !!!\n\nThe format name should be "bdv.hdf5"\nbut it is "%s"', metaStr.(datasetName).SequenceDescription.ImageLoader.Attributes.format),'Wrong format!');
    end
    
    % define part of the dataset to take
    if isfield(options, 'x')   % min/max width
        if options.x(1) < 1 || options.x(1) > img_info('Width') || options.x(2) < 1 || options.x(2) > img_info('Width')
            errordlg(sprintf('!!! Error !!!\n\nThe X value [%d:%d] is out of range!\nThe "options.x" should be between 1 and %d', options.x(1),options.x(2),img_info('Width')));
        end
        x = options.x;
    else
        x = [1 img_info('Width')];
    end
    if isfield(options, 'y')   % min/max height
        if options.y(1) < 1 || options.y(1) > img_info('Height') || options.y(2) < 1 || options.y(2) > img_info('Height')
            errordlg(sprintf('!!! Error !!!\n\nThe Y value [%d:%d] is out of range!\nThe "options.y" should be between 1 and %d', options.y(1),options.y(2),img_info('Height')));
        end
        y = options.y;
    else
        y = [1 img_info('Height')];
    end
    if isfield(options, 'z')   % min/max depth, z
        if options.z(1) < 1 || options.z(1) > img_info('Depth') || options.z(2) < 1 || options.z(2) > img_info('Depth')
            errordlg(sprintf('!!! Error !!!\n\nThe Z value [%d:%d] is out of range!\nThe "options.z" should be between 1 and %d', options.z(1),options.z(2),img_info('Depth')));
        end
        z = options.z;
    else
        z = [1 img_info('Depth')];
    end
    if isfield(options, 'c')   % vector of color channels
        if min(options.c) < 1 || max(options.c) > img_info('Colors')
            errordlg(sprintf('!!! Error !!!\n\nThe C value is out of range!\nThe "options.c" should be between 1 and %d', img_info('Colors')));
        end
        c = options.c;
    else
        c = 1:img_info('Colors');
    end
    if isfield(options, 't')   % min/max time point
        if options.t(1) < 1 || options.t(1) > img_info('Time') || options.z(2) < 1 || options.z(2) > img_info('Time')
            errordlg(sprintf('!!! Error !!!\n\nThe T value [%d:%d] is out of range!\nThe "options.t" should be between 1 and %d', options.t(1),options.t(2),img_info('Time')));
        end
        t = options.t;
    else
        t = [1 img_info('Time')];
    end
    
    width = diff(x)+1;
    height = diff(y)+1;
    depth = diff(z)+1;
    if strcmp(img_info('imgClass'), 'uint16')
        dataset = zeros([width, height, depth, numel(c), diff(t)+1], 'uint16');  % allocate space
    else
        % add here uint8
    end
    timeCount = 0;  % time index for the output
    for timePnt=t(1):t(2)
        timeIndex = timePnt + offsetIndex - 1;  % index in the HDF5 file
        timeCount = timeCount + 1;
        % assuming 1 setup
        for ch=c
            groupName = info.Groups(timeIndex).Groups(ch).Groups(level).Name;
            datasetName = info.Groups(timeIndex).Groups(ch).Groups(level).Datasets.Name;
            dummy = h5read(fullfileH5, [groupName '/' datasetName], [x(1), y(1), z(1)], [width, height, depth]);
            
            % have to typecast, otherwise
            % example = h5read('mitosis.h5', '/t00000/s00/0/cells');
            % min(example(:)) == -32748
            dummy2 = typecast(dummy(:),'uint16');
            dummy = reshape(dummy2, size(dummy));
            
            dataset(:,:,:,ch, timePnt) = dummy;
        end
    end
    I = permute(dataset, [2 1 4 3 5]);    % permute for MIB [y,x,c,z,t];
    
    % test of read string
    % dummy = h5read(fullfileH5, [info.Groups(1).Name '/' info.Groups(1).Datasets(1).Name]);
end
end