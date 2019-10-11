function updateServiceMetadata(obj, metaIn)
% function updateServiceMetadata(obj, metaIn)
% update service metadata of MIB based on obj.img and metaIn
%
% Parameters:
% metaIn: [@em optional], a containers map with parameters that should be preserved
%
% Return values:
%

%|
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.updateServiceMetadata(); // call from mibController to clear the class @endcode

% Copyright (C) 16.08.2018, Ilya Belevich (ilya.belevich @ helsinki.fi)
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
%

if nargin < 2
    metaIn = containers.Map();
    % information about the dataset, an instance of the 'containers'.'Map' class
    % Default keys:
    % @li @b ColorType - a string witg type of colors - grayscale, truecolor, hsvcolor, indexed
    % @li @b ImageDescription - ''''
    % @li @b Filename - ''none.tif''
    % @li @b SliceName - @em [optional] a cell array with names of the slices; for combined Z-stack, it is a name of the file that corresponds to the slice. Dimensions of the array should be equal to the  obj.no_stacks
    % @li @b Height
    % @li @b Width
    % @li @b Depth
    % @li @b Colors
    % @li @b Time
    % @li @b MaxInt - maximal number that can be stored in the image container (255 for 8bit, 65535 for 16 bit)
    % @li @b imgClass - a string with image class, 'uint8', 'uint16', 'uint32';
end

% check correct class of metaIn
if ~isa(metaIn, 'containers.Map')
    errordlg(sprintf('!!! Error !!!\n\nmibImage.updateServiceMetadata\nThe provided metaIn variable does not belong to the containers.Map class!\nUpdating the metadata using default values'));
    metaIn = containers.Map();
end

% initialize metaOut
metaOut = containers.Map();

% check for the virtual mode and a dummy image
if obj.Virtual.virtual == 1
    if strcmp(obj.img{1}, 'im_browser_dummy.h5')
        keySet = {'Height', 'Width', 'Depth', 'Time', 'Colors', 'imgClass', 'MaxInt',...
            'ColorType', 'ImageDescription', 'Filename', ...
            'Virtual_slicesPerFile', 'Virtual_readerId', 'Virtual_objectType', 'Virtual_seriesName', 'Virtual_filenames'};
        valueSet = [512, 512, 1, 1, 1, {'uint8'}, 255, ...
            {'grayscale'}, {sprintf('|')}, {'none.tif'}, ...
            1, 1, {{'matlab.hdf5'}}, {{'/im_browser_dummy'}}, {'im_browser_dummy.h5'}];
        metaIn = containers.Map(keySet, valueSet);
    end
end

%% update MetaOut containers

% update Height, Width, Time, Colors
if isKey(metaIn, 'Height') && isKey(metaIn, 'Width') && isKey(metaIn, 'Time') && isKey(metaIn, 'Colors')
    metaOut('Height') = metaIn('Height');
    metaOut('Width') = metaIn('Width');
    metaOut('Time') = metaIn('Time');
    metaOut('Colors') = metaIn('Colors');
else
    if obj.Virtual.virtual == 0     % memory resident mode
        metaOut('Height') = size(obj.img{1}, 1);   % height of the dataset
        metaOut('Width') = size(obj.img{1}, 2);    % width of the dataset
        metaOut('Colors') = size(obj.img{1}, 3); % number of color channels
        metaOut('Time') = size(obj.img{1}, 5);    % number of time points
    else                            % hdd resident mode
        if strcmp(obj.Virtual.objectType{1}, 'bioformats')     % bio-formats
            metaOut('Height') = obj.img{1}.getSizeY();   % height of the dataset
            metaOut('Width') = obj.img{1}.getSizeX();    % width of the dataset
            metaOut('Colors') = obj.img{1}.getSizeC(); % number of color channels
            metaOut('Time') = obj.img{1}.getSizeT();    % number of time points
        else
            errordlg('not implemented!');
            obj.clearContents();
            return;
        end
    end
end

% update Depth
if isKey(metaIn, 'Depth')
    metaOut('Depth') = metaIn('Depth');
else
    if obj.Virtual.virtual == 0     % memory resident mode
        metaOut('Depth') = size(obj.img{1}, 4);      % number of slices in the dataset
    else                            % hdd resident mode
        if strcmp(obj.Virtual.objectType{1}, 'bioformats')    % bio-formats
            slicePerFile = arrayfun(@(ind) obj.img{ind}.getSizeZ(), 1:numel(obj.img), 'UniformOutput', 1);
            metaOut('Depth') = sum(slicePerFile);  % number of stacks in the combined dataset
        else
            errordlg('not implemented!');
            obj.clearContents();
            return;
        end
    end
end

% update imgClass key with a string corresponding to the image class:
% 'uint8', 'uint16'...
if isKey(metaIn, 'imgClass')
    metaOut('imgClass') = metaIn('imgClass');
else
    if obj.Virtual.virtual == 0     % memory resident mode
        metaOut('imgClass') = class(obj.img{1}(1));    % get string with class name for images
    else                            % hdd resident mode
        if strcmp(obj.Virtual.objectType{1}, 'bioformats')     % bio-formats
            switch obj.img{1}.getPixelType
                case 1
                    metaOut('imgClass') = 'uint8';
                case 3
                    metaOut('imgClass') = 'uint16';
                case 5
                    metaOut('imgClass') = 'uint32';
                otherwise
                    errordlg('Virtual stacks! This class is not implemented!');
                    obj.clearContents();
                    return;
            end
        else
            errordlg('not implemented!');
            obj.clearContents();
            return;
        end
    end
end

% update MaxInt, identifying the maximal intensity value for the class
if isKey(metaIn, 'MaxInt')
    metaOut('MaxInt') = metaIn('MaxInt');
else
    metaOut('MaxInt') = double(intmax(metaOut('imgClass')));
end

% update 'ColorType': truecolor, grayscale, hsvcolor, indexed
if isKey(metaIn, 'ColorType')
    metaOut('ColorType') = metaIn('ColorType');
else
    if metaOut('Colors') > 1
        metaOut('ColorType') = 'truecolor';
    else
        metaOut('ColorType') = 'grayscale';
    end
end

% update ImageDescription
if isKey(metaIn, 'ImageDescription')
    metaOut('ImageDescription') = metaIn('ImageDescription');
else
    metaOut('ImageDescription') = sprintf('|');
end

% update ImageDescription
if isKey(metaIn, 'Filename')
    metaOut('Filename') = metaIn('Filename');
else
    metaOut('Filename') = 'none.tif';
end

% check for required fields for the virtual mode
if obj.Virtual.virtual == 1     % hdd resident mode
    if ~isKey(metaIn, 'Virtual_slicesPerFile') || ~isKey(metaIn, 'Virtual_readerId') || ...
            ~isKey(metaIn, 'Virtual_objectType') || ~isKey(metaIn, 'Virtual_seriesName') || ~isKey(metaIn, 'Virtual_filenames')
        
        errordlg('Virtual stacks!\nMissing required fields: Virtual_slicesPerFile, Virtual_readerId, Virtual_objectType, Virtual_seriesName or Virtual_filenames in the meta');
        obj.clearContents();
        return;
    else
        metaOut('Virtual_slicesPerFile') = metaIn('Virtual_slicesPerFile');
        metaOut('Virtual_readerId') = metaIn('Virtual_readerId');
        metaOut('Virtual_objectType') = metaIn('Virtual_objectType');
        metaOut('Virtual_seriesName') = metaIn('Virtual_seriesName');
        metaOut('Virtual_filenames') = metaIn('Virtual_filenames');
        
    end
end

%% Update class variables

obj.height = metaOut('Height');
obj.width = metaOut('Width');
obj.colors = metaOut('Colors');
obj.depth = metaOut('Depth');
obj.time = metaOut('Time');

obj.dim_yxczt = [obj.height, obj.width, obj.colors obj.depth obj.time];     % needed for virtual datasets as replacement of size(obj.img{1})

obj.viewPort.min = zeros([obj.colors, 1]);
obj.viewPort.max = zeros([obj.colors, 1]) + double(metaOut('MaxInt'));
obj.viewPort.gamma = zeros([obj.colors, 1]) + 1;

% obj.slices{1} = [1, obj.height];   % height [min, max]
% obj.slices{2} = [1, obj.width];   % width [min, max]
% obj.slices{3} = 1:obj.colors;      % list of shown color channels [1, 2, 3, 4...]
% obj.slices{4} = [1, 1];                 % z-values, [min, max]
% obj.slices{5} = [1, 1];                 % time points, [min, max]

% update obj.slices
current_layer = obj.slices{obj.orientation}(1);
obj.slices{1} = [1, obj.height];
obj.slices{2} = [1, obj.width];
obj.slices{3} = 1:obj.colors;
obj.slices{4} = [1, obj.depth];
obj.slices{5} = [min([obj.slices{5} obj.time]) min([obj.slices{5} obj.time])];
obj.slices{obj.orientation} = [min([obj.dim_yxczt(obj.orientation) current_layer]), min([obj.dim_yxczt(obj.orientation) current_layer])];

obj.current_yxz(1) = min([obj.current_yxz(1) obj.height]);
obj.current_yxz(2) = min([obj.current_yxz(2) obj.width]);
obj.current_yxz(3) = min([obj.current_yxz(3) obj.depth]);

% virtual dataset related fields
if obj.Virtual.virtual == 1
    % array of how many slices in each opened file
    obj.Virtual.slicesPerFile = metaOut('Virtual_slicesPerFile');
    % an array which directs each slice of the combined dataset to correct reader
    obj.Virtual.readerId = metaOut('Virtual_readerId');
    obj.Virtual.objectType = metaOut('Virtual_objectType');
    obj.Virtual.seriesName = metaOut('Virtual_seriesName');
    obj.Virtual.filenames = metaOut('Virtual_filenames');
end

% add colors to the LUT color table and update it
if obj.colors > size(obj.lutColors,1)
    for i=size(obj.lutColors,1)+1:obj.colors
        obj.lutColors(i,:) = [rand(1) rand(1) rand(1)];
    end
end

if isKey(metaIn, 'lutColors')
    if ischar(metaIn('lutColors')); metaIn('lutColors') = str2num(metaIn('lutColors')); end %#ok<ST2NM>
    obj.lutColors(1:size(metaIn('lutColors'),1), :) = metaIn('lutColors');
end

% modify filename for the mask
if isempty(obj.maskImgFilename)
    pathStr = fileparts(metaOut('Filename'));
    if ~isempty(pathStr)
        [pathStr, filenameStr] = fileparts(metaOut('Filename'));
        obj.maskImgFilename = fullfile(pathStr, ['Mask_' filenameStr '.mask']);
    end
end

if obj.height < obj.current_yxz(1); obj.current_yxz(1) = obj.height; end
if obj.width < obj.current_yxz(2); obj.current_yxz(2) = obj.width; end
if obj.depth < obj.current_yxz(3); obj.current_yxz(3) = obj.depth; end

%% generate obj.meta
keys1 = keys(metaOut);
values1 = values(metaOut);
keys2 = keys(metaIn);
remove(metaIn, keys1(ismember(keys1, keys2)));  % remove keys that were updated in metaOut from metaIn
keys2 = keys(metaIn);
values2 = values(metaIn);

KeySet = [keys1, keys2];
ValueSet = [values1, values2];
obj.meta = containers.Map(KeySet, ValueSet);

[obj.meta, obj.pixSize] = mibUpdatePixSizeAndResolution(obj.meta);  % update pixsize and resolution

% update volren 
R = [0 0 0];
S = [1*obj.magFactor,...
     1*obj.magFactor,...
     1*obj.pixSize.x/obj.pixSize.z*obj.magFactor];
T = [0 0 0];

obj.volren.show = 0;    % do not show the volume rendering
obj.volren.viewer_matrix = [];
obj.volren.previewImg = [];
obj.volren.showFullRes = 1;
obj.volren.viewer_matrix = makeViewMatrix(R, S, T);

if obj.selectedColorChannel > obj.colors; obj.selectedColorChannel = 1; end

