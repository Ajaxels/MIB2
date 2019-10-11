function result = image2hdf5(filename, imageS, options)
% function result = image2hdf5(filename, imageS, options, ImageDescription)
% Save image into hdf5 format
%
% Parameters:
% filename: filename for hdf file
% imageS: original dataset [1:height, 1:width, 1:colors, 1:no_stacks] or [1:height, 1:width, 1:no_stacks]
% options: [@em optional] a structure with additional parameters
%  - .ChunkSize - a matrix [y, x, z] of chunk size
%  - .Deflate - a number 0-9, defines gzip compression level (0-9)
%  - .overwrite, if @b 1 do not check whether file with provided filename alaready exists
%  - .showWaitbar, @b 1 - show the progress bar, @b 0 - do not show
%  - .lutColors, - not yet implemented
%  - .pixSize, - not yet implemented
%  - .ImageDescription, - a cell string with dataset description
%  - .DatasetName, - a cell string or a containers.Map with metadata
%  - .order, - a string with order of the axes, 'yxczt'
%  - .height - height of the full dataset, required for the initialization (i.e. when options.t==1);
%  - .width - width of the full dataset, required for the initialization (i.e. when options.t==1);
%  - .colors - number of colors of the full dataset, required for the initialization (i.e. when options.t==1);
%  - .depth - depth of the full dataset, required for the initialization (i.e. when options.t==1);
%  - .time - time of the full dataset, required for the initialization (i.e. when options.t==1);
%  - .x - define a minimal X point for data to store
%  - .y - define a minimal Y point for data to store
%  - .z - define a minimal Z point for data to store
%  - .t - define a minimal T point for data to store
%  - .DatasetType - a string, type of the dataset 'image', 'model', 'mask'
%  - .DatasetClass - a string, image class of the dataset, uint8, uint16...
%
% Return values:
% result: result of the function run, @b 1 - success, @b 0 - fail

% Copyright (C) 19.01.2012 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 06.04.2016, IB heavily updated 

% example:
%   image2hdf5('saveme.h5', image_var, options, 'test');

result = 0;
if nargin < 3; options = struct(); end
if nargin < 2; error('Please provide filename and image!'); end

if ~isfield(options, 'ChunkSize'); options.ChunkSize = [];    end
if ~isfield(options, 'Deflate'); options.Deflate = 0;    end
if ~isfield(options, 'overwrite'); options.overwrite = 0;    end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1;    end
if ~isfield(options, 'height'); options.height = size(imageS, 1);    end
if ~isfield(options, 'width'); options.width = size(imageS, 2);    end
if ~isfield(options, 'colors'); options.colors = size(imageS, 3);    end
if ~isfield(options, 'depth'); options.depth = size(imageS, 4);    end
if ~isfield(options, 'time'); options.time = size(imageS, 5);    end
if ~isfield(options, 'x'); options.x = 1;    end
if ~isfield(options, 'y'); options.y = 1;    end
if ~isfield(options, 'z'); options.z = 1;    end
if ~isfield(options, 't'); options.t = 1;    end
if ~isfield(options, 'DatasetName')    % Set dataset name and check for the leading slash
    options.DatasetName = '/MIB_Export';    
else
    if options.DatasetName(1) ~= '/'
        options.DatasetName = ['/' options.DatasetName];
    end
end
if ~isfield(options, 'ImageDescription'); options.ImageDescription = '';    end
if ~isfield(options, 'DatasetType'); options.DatasetType = 'image';    end
if ~isfield(options, 'DatasetClass'); options.DatasetClass = class(imageS);    end

if ~isfield(options, 'order')
    options.order = 'yxczt';    
end

if options.overwrite == 0
    if exist(filename,'file') == 2
        reply = questdlg(sprintf('!!! Warning !!!\n\nThe file exists!\nOverwrite?'),'Overwrite','Overwrite','Cancel','Cancel');
        if strcmp(reply,'Cancel'); return; end
    end
end

% % permute the matrix to make it yxczt
% if isempty(strfind(options.order,'c')) && ndims(imageS) < 5
%     imageS = reshape(imageS, size(imageS,1), size(imageS,2), 1, size(imageS,3),size(imageS,4));
% end

if options.showWaitbar
    %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
	curInt = get(0, 'DefaulttextInterpreter'); 
	set(0, 'DefaulttextInterpreter', 'none'); 
    wb = waitbar(0,sprintf('%s\nPlease wait...',filename),'Name','Saving images as hdf5...','WindowStyle','modal');
    waitbar(0, wb); 
end

if exist(filename,'file') && options.t == 1  % for overwrite
    fileNameDelete = filename;
    delete(fileNameDelete);
end

% create dataset
if options.t == 1
    if options.showWaitbar; waitbar(.05,wb,sprintf('%s\nCreate file container...',filename)); end
    if isempty(options.ChunkSize)   % do not chunk the data
        options.ChunkSize = [options.height, options.width, 1, options.depth, 1];
    end
    h5create(filename, options.DatasetName, [options.height, options.width, options.colors, options.depth, options.time], ...
            'Datatype', options.DatasetClass, 'Deflate', options.Deflate, ...
            'ChunkSize', [options.ChunkSize(1) options.ChunkSize(2) 1 options.ChunkSize(3) 1]);
end

if options.showWaitbar; waitbar(.1,wb,sprintf('%s\nSaving images...',filename)); end
getDataOpt.showWaitbar = 0;     % do not show waitbar in getDataVirt
maxIndex = options.time*ceil(options.depth/options.ChunkSize(3));

counterIndex = 1;
if isfield(options, 'mibImage')     % tweak to save HDF5 in the virtual mode, without loaded imageS
    for t=1:options.time
        getDataOpt.t = t;
        for z=1:ceil(options.depth/options.ChunkSize(3))
            getDataOpt.z = [(z-1)*options.ChunkSize(3)+1, z*options.ChunkSize(3)];
            for x=1:ceil(options.width/options.ChunkSize(2))
                getDataOpt.x = [(x-1)*options.ChunkSize(2)+1, x*options.ChunkSize(2)];
                for y=1:ceil(options.height/options.ChunkSize(1))
                    getDataOpt.y = [(y-1)*options.ChunkSize(1)+1, y*options.ChunkSize(1)];
                    img2 = options.mibImage.getDataVirt(options.DatasetType, 4, 0, getDataOpt);
                    h5write(filename, options.DatasetName, img2, ...
                        [getDataOpt.y(1), getDataOpt.x(1), 1, getDataOpt.z(1), getDataOpt.t(1)],...
                        [size(img2,1), size(img2,2), size(img2,3), size(img2,4),size(img2,5)]);
                end
            end
            if options.showWaitbar; waitbar(counterIndex/maxIndex, wb); end
            counterIndex = counterIndex + 1;
        end
    end
else
    h5write(filename, options.DatasetName, imageS, ...
        [options.y, options.x, 1, options.z, options.t],...
        [size(imageS,1), size(imageS,2), size(imageS,3), size(imageS,4),size(imageS,5)]);
end

if options.showWaitbar; waitbar(.9,wb,sprintf('%s\nSaving metadata...',filename)); end

% generate axistags to be compatible with Ilastik
% see more here:
% https://ukoethe.github.io/vigra/doc-release/vigranumpy/#vigra.AxisInfo

axistags = sprintf('{\n"axes": [\n');
% should be in reverse order
for i=numel(options.order):-1:1
    % identify the typeFlag
    switch options.order(i)
        case 't'
            typeFlag = '8';
        case 'c'
            typeFlag = '1';
        otherwise
            typeFlag = '2';
    end
    
    axistags = sprintf('%s {\n  "key": "%s",\n', axistags, options.order(i));
    axistags = sprintf('%s  "typeFlags": %s,\n', axistags, typeFlag);
    axistags = sprintf('%s  "resolution": 0,\n', axistags);
    axistags = sprintf('%s  "description": "%s"\n', axistags, options.ImageDescription);
    axistags = sprintf('%s },\n', axistags);
end
axistags(end-1) = []; % remove comma
axistags = sprintf('%s]\n', axistags); % close axes field
axistags = sprintf('%s}', axistags); % close axistags

h5writeatt(filename, options.DatasetName, 'axistags', axistags);

% metaFields = keys(ImageDescription);
% 
% for index=1:numel(metaFields)
%     h5writeatt(filename,ImageDescription('DatasetName'), metaFields{index}, ImageDescription(metaFields{index}));
% end

if options.showWaitbar; waitbar(1, wb); end
disp(['image2hdf5: ' filename ' was created!']);
if options.showWaitbar; delete(wb); set(0, 'DefaulttextInterpreter', curInt); end
result = 1;
end