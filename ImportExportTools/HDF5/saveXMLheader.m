function result  = saveXMLheader(filename, options)
% function result  = saveXMLheader(filename, options)
% Save XML header for the HDF5 formats (for example, Fiji Big Data Viewer)
%
% Parameters:
% filename: name of the file: myfile.xml
% options: a structure with parameters
% .Format - a string, template for storing data "bdv.hdf5", 'ilastik.hdf5', 'matlab.hdf5'
% .height - height of the dataset
% .width - width of the dataset
% .colors - number of colors in the dataset
% .depth - number of z-stacks of the dataset
% .time - number of time points
% .pixSize - a structure with pixel size of the dataset (.x .y .z .units)
% .lutColor - [@em optional], a matrix with definition of color channels [1:colorChannel, R G B], (0-1); or colors for materials of the model
% .ImageDescription - [@em optional], a string with description of the dataset
% .DatasetName - [@em optional], name of the dataset in the H5 file (not used with Big Data Viewer)
% .ModelMaterialNames [@em optional], a cell array with names of materials
%
% Return values:
% result: @b 0 - fail, @b 1 - success

%| 
% @b Examples:
% @code saveXMLheader('c:\data\mydataset.xml', options);  // save xml file @endcode

% Copyright (C) 31.03.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

result = 0;
if nargin < 2; options = struct(); end;

if ~isfield(options, 'Format'); options.Format = 'bdv.hdf5'; end;
if ~isfield(options, 'DatasetName'); 
    options.DatasetName = '\MIB_Export'; 
else
    if options.DatasetName(1) ~= '/'
        options.DatasetName = ['/' options.DatasetName];
    end
end;

[path, baseName, ext] = fileparts(filename);
xmlFilename = fullfile(path, [baseName '.xml']);


% saving xml file
% A structure containing:
% s.XMLname.Attributes.attrib1 = "Some value";
% s.XMLname.Element.Text = "Some text";
% s.XMLname.DifferentElement{1}.Attributes.attrib2 = "2";
% s.XMLname.DifferentElement{1}.Text = "Some more text";
% s.XMLname.DifferentElement{2}.Attributes.attrib3 = "2";
% s.XMLname.DifferentElement{2}.Attributes.attrib4 = "1";
% s.XMLname.DifferentElement{2}.Text = "Even more text";
%
% Will produce:
% <XMLname attrib1="Some value">
%   <Element>Some text</Element>
%   <DifferentElement attrib2="2">Some more text</Element>
%   <DifferentElement attrib3="2" attrib4="1">Even more text</DifferentElement>
% </XMLname>

%delete([baseName '.xml']);

s = struct();
s.SpimData.AttributesText.version = '0.2';
s.SpimData.BasePath.Text = '.';
s.SpimData.BasePath.AttributesText.type = 'relative';

s.SpimData.SequenceDescription.ImageLoader.AttributesText.format = options.Format;
s.SpimData.SequenceDescription.ImageLoader.hdf5.Text = [baseName '.h5'];
s.SpimData.SequenceDescription.ImageLoader.hdf5.AttributesText.type = 'relative';
s.SpimData.SequenceDescription.ImageLoader.Datasetname.Text= options.DatasetName;

% add extra field with image description
if isfield(options, 'ImageDescription')
    s.SpimData.SequenceDescription.ViewSetups.ImageDescription.Text = options.ImageDescription;
end
% generate list of materials and their colors
if isfield(options, 'ModelMaterialNames')
    for matId = 1:numel(options.ModelMaterialNames)
        s.SpimData.SequenceDescription.ViewSetups.Materials.(sprintf('Material%03i',matId)).Name.Text = options.ModelMaterialNames{matId};
        s.SpimData.SequenceDescription.ViewSetups.Materials.(sprintf('Material%03i',matId)).Color.Text = num2str(options.lutColors(matId,:));
    end
end

s.SpimData.SequenceDescription.ViewSetups.Attributes.AttributesText.name = 'channel';
    
% color channel section
for colId = 1:options.colors
    s.SpimData.SequenceDescription.ViewSetups.Attributes.Channel{colId}.id.Text = num2str(colId);
    s.SpimData.SequenceDescription.ViewSetups.Attributes.Channel{colId}.name.Text = num2str(colId);

    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.id.Text = num2str(colId - 1);
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.name.Text = sprintf('channel %d', colId);
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.size.Text = sprintf('%d %d %d', options.height, options.width, options.depth);
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.voxelSize.unit.Text = options.pixSize.units;
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.voxelSize.size.Text = sprintf('%f %f %f', options.pixSize.y, options.pixSize.x, options.pixSize.z);
    s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.attributes.channel.Text = num2str(colId);
    
    % add extra field with information about color channel
    if isfield(options, 'lutColors')
        s.SpimData.SequenceDescription.ViewSetups.ViewSetup{colId}.color.Text = num2str(options.lutColors(colId,:));
    end
end

% time points setup
s.SpimData.SequenceDescription.Timepoints.AttributesText.type = 'range';
s.SpimData.SequenceDescription.Timepoints.first.Text = '0';
s.SpimData.SequenceDescription.Timepoints.last.Text = num2str(options.time-1);

% registration section
index = options.time*options.colors;    % index of the registration to store
for t=(options.time-1):-1:0
    for colId = (options.colors-1):-1:0
        s.SpimData.ViewRegistrations.ViewRegistration{index}.AttributesText.timepoint = num2str(t);
        s.SpimData.ViewRegistrations.ViewRegistration{index}.AttributesText.setup = num2str(colId);
        s.SpimData.ViewRegistrations.ViewRegistration{index}.ViewTransform.AttributesText.type = 'affine';
        s.SpimData.ViewRegistrations.ViewRegistration{index}.ViewTransform.affine.Text = ...
            sprintf('%f 0.0 0.0 0.0 0.0 %f 0.0 0.0 0.0 0.0 %f 0.0', options.pixSize.y, options.pixSize.x, options.pixSize.z);
        index = index - 1;
    end
end
struct2xml(s, xmlFilename);
result = 1;

end