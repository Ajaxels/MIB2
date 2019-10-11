function [img_info, metaStr]  = getXMLheader(filename)
% function [img_info, metaStr]  = getXMLheader(filename)
% Read XML header for the HDF5 formats (for example, Fiji Big Data Viewer)
%
% Parameters:
% filename: name of the file: myfile.xml
%
% Return values:
% img_info: containers.Map with metadata
% @li img_info('Format') contains format of the HDF5 file, "bdv.hdf5" for Fiji BDV
% metaStr:  a contents of the XML file formatted as Matlab structure

%| 
% @b Examples:
% @code [img_info, metaStr]  = getXMLheader('c:\data\mydataset.xml');  // read xml file @endcode

% Copyright (C) 31.03.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

metaStr = struct();
img_info = containers.Map; % allocate img_info;
if nargin < 1; errordlg(sprintf('!!! Error !!!\n\nThe filename is missing!\nmetaStr = getXMLheader(filename)'));return; end;

% initialize default
pixSize.x = 1;
pixSize.y = 1;
pixSize.z = 1;
pixSize.units = 'um';
pixSize.t = 1;
pixSize.tunits = 'sec';
[dirName, baseName, extName] = fileparts(filename);  % get the absolute directory and extension of the dataset

img_info('ImageDescription') = '';
img_info('XResolution') = [];
img_info('YResolution') = [];
img_info('ResolutionUnit') = 'Inch';

metaStr = xml2struct(filename); % get XML structure
datasetName = fields(metaStr);  % name of the field that contains the metadata
datasetName = datasetName{1};   % convert to char

% get filename
fileH5 = metaStr.(datasetName).SequenceDescription.ImageLoader.hdf5.Text;   % name of hdf5 file
fullfileH5 = fullfile(dirName, fileH5);   % generate fullfile name for the hdf5
fullfileXML = filename;

img_info('Format') = metaStr.(datasetName).SequenceDescription.ImageLoader.Attributes.format;

img_info('Colors') = numel(metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup);

% get optional ImageDescription field
if isfield(metaStr.(datasetName).SequenceDescription.ViewSetups, 'ImageDescription')
    img_info('ImageDescription') = metaStr.(datasetName).SequenceDescription.ViewSetups.ImageDescription.Text;
end
% get optional Datasetname field
if isfield(metaStr.(datasetName).SequenceDescription.ImageLoader, 'Datasetname')
    img_info('Datasetname') = metaStr.(datasetName).SequenceDescription.ImageLoader.Datasetname.Text;
end

% get Materials of the model
if isfield(metaStr.(datasetName).SequenceDescription.ViewSetups, 'Materials')
    materialFieldNames = fieldnames(metaStr.(datasetName).SequenceDescription.ViewSetups.Materials);
    material_list = cell([numel(materialFieldNames), 1]);
    color_list = zeros(numel(materialFieldNames), 3);
    for matId = 1:numel(materialFieldNames)
        material_list{matId} = metaStr.(datasetName).SequenceDescription.ViewSetups.Materials.(materialFieldNames{matId}).Name.Text;
        color_list(matId,:) = str2num(metaStr.(datasetName).SequenceDescription.ViewSetups.Materials.(materialFieldNames{matId}).Color.Text); %#ok<ST2NM>
    end
    img_info('material_list') = material_list;
    img_info('color_list') = color_list;
end

% convert ViewSetup to cell when there is only 1 entry
if ~iscell(metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup)
    ViewSetup{1} = metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup;
else
    ViewSetup = metaStr.(datasetName).SequenceDescription.ViewSetups.ViewSetup;
end

if isfield(ViewSetup{1}, 'name')
    img_info('channelNames') = cellfun(@(x) x.name.Text, ViewSetup', 'UniformOutput', false);
else
    img_info('channelNames') = cellfun(@(x) x.id.Text, ViewSetup', 'UniformOutput', false);
end

if img_info('Colors') > 1
    img_info('ColorType') = 'truecolor';
else
    img_info('ColorType') = 'grayscale';
end

% add optional information about color channels
if isfield(ViewSetup{1}, 'color')
    %img_info('lutColors') = str2num(cell2mat(cellfun(@(x) x.color.Text, ViewSetup', 'UniformOutput', false))); %#ok<ST2NM>
    colorText = cellfun(@(x) x.color.Text, ViewSetup', 'UniformOutput', false);
    for i=1:numel(colorText)
        colorTextVal(i,:) = str2num(colorText{i});
    end
    img_info('lutColors') = colorTextVal;
end


%t1 = str2double(metaStr.(datasetName).SequenceDescription.Timepoints.first.Text);
t2 = str2double(metaStr.(datasetName).SequenceDescription.Timepoints.last.Text)+1;
img_info('Time') = t2;
img_info('Filename') = fullfileH5;
%img_info('SliceName') - [optional] a cell array with names of the slices; for combined Z-stack, it is a name of the file that corresponds to the slice. Dimensions of the array should be equal to the obj.no_stacks
if isfield(ViewSetup{1}, 'voxelSize')
    units = ViewSetup{1}.voxelSize.unit.Text;
    if strcmp(units, sprintf('\xB5m'))  % if units are micrometers
        units = 'um';
    end
    pixSize.units = units;
    voxels = str2num(ViewSetup{1}.voxelSize.size.Text); %#ok<ST2NM>
    pixSize.x = voxels(1);
    pixSize.y = voxels(2);
    pixSize.z = voxels(3);
end
img_info('pixSize') = pixSize;

xyzVal = str2num(ViewSetup{1}.size.Text);   %#ok<ST2NM> % unbinned
if strcmp(img_info('Format'),'bdv.hdf5')
    img_info('Height') = xyzVal(1);
    img_info('Width') = xyzVal(2);
else
    img_info('Height') = xyzVal(1);
    img_info('Width') = xyzVal(2);
end
img_info('Depth') = xyzVal(3);
img_info('ReturnedLevel') = 1;
end