function [img_info, files, pixSize] = mibGetImageMetadata(filenames, options)
% function [img_info, files, pixSize] = mibGetImageMetadata(filenames, options, handles)
% Get metadata for images
%
% Parameters:
% filenames: a cell array with filenames of images
% options: a structure with additional parameters
% .mibBioformatsCheck -> @b 0 or @b 1; when @b 1 use the BioFormats library
% .waitbar -> @b 0 or @b 1; when @b 1 shows the progress bar
% .customSections -> @b 0 or @b 1; when @b 1 obtain part of the dataset
% .mibPath -> [optional] a string with path to MIB directory, an optional parameter to mibInputDlg.m
% .id - id of the current dataset, needed to generate filename for Memoizer class for the virtual mode
% .BioFormatsMemoizerMemoDir -> obj.mibModel.preferences.dirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats
% .BioFormatsIndices -> numeric, indices of images in file container to be opened with BioFormats 
% .Font -> [optional] a structure with the font settings from mib
%    .FontName
%    .FontUnits
%    .FontSize
%
% Return values:
% img_info: in the format compatible with imageData.img_info containers.Map
% files: a structure with file-info, can be empty: []
% - .object_type -> 'movie', 'hdf5_image', 'image'
% - .filename
% - .seriesName -> index of the series for HDF5/Bioformats
% - .seriesRealName -> real names of the series for Bioformats
% - .height
% - .width
% - .color
% - .noLayers -> number of image frames in the file
% - .imgClass -> class of the image
% - .dim_xyczt -> dimensions for hdf5_image and Bioformats
% - .BioFormatsMemoizerMemoDir -> path to directory containing BioFormats Memoizer memo file, only for BioFormats reader
% pixSize: a structure with voxel dimensions (.x, .y, .z, .units, .t, .tunits)

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
if isempty(options); options = struct(); end

if ~isfield(options, 'mibBioformatsCheck');    options.mibBioformatsCheck = 0; end
if ~isfield(options, 'waitbar');    options.waitbar = 0; end
if ~isfield(options, 'mibPath');    options.mibPath = mibPath;  end
if ~isfield(options, 'Font');    options.Font = Font;  end
if ~isfield(options, 'customSections');    options.customSections = 0; end
if ~isfield(options, 'virtual');    options.virtual = 0; end
if ~isfield(options, 'id');    options.id = 1;  end
if ~isfield(options, 'BioFormatsMemoizerMemoDir');    options.BioFormatsMemoizerMemoDir = 'c:\temp';  end

pixSize.x = 1;
pixSize.y = 1;
pixSize.z = 1;
pixSize.units = 'um';
pixSize.t = 1;
pixSize.tunits = 's';

img_info = containers.Map;
video_formats = VideoReader.getFileFormats();   % for matlab version 8.0 and older
image_formats = imformats();  % get readable image formats
no_files = numel(filenames);
layer_id = 1;

if options.waitbar==1; wb = waitbar(0,sprintf('Loading metadata\nPlease wait...'),'Name','Metadata import'); end

files = struct();   % structure that keeps info about each file in the series
% .object_type -> 'movie', 'hdf5_image', 'image'
% .filename
% .seriesName -> name of the series for HDF5/Bioformats
% .extension -> filename extension
% .height
% .width
% .color
% .time
% .noLayers -> number of image frames in the file
% .imgClass -> class of the image
% .dim_xyczt -> dimensions for hdf5_image and Bioformats
% .hDataset -> handle to Bioformats dataset

for fn_index = 1:no_files
    if exist(filenames{fn_index}, 'file') == 0
        errordlg(sprintf('!!! Error !!!\n\nThe required file\n %s\nwas not found!', filenames{fn_index}), ...
            'Wrong filename');
        img_info = containers.Map;
        if options.waitbar==1; delete(wb); end
        return;
    end
    
    [dirId, fnId, ext] = fileparts(filenames{fn_index});
    ext = lower(ext);
    files(fn_index).extension = ext;
    % get image information
    if strfind([video_formats.Extension], ext(2:end)) > 0 & options.mibBioformatsCheck == 0      %#ok<AND2> % movie object
        files(fn_index).filename = cell2mat(filenames(fn_index));
        xyloObj = VideoReader(files(fn_index).filename);  %#ok<TNMLP>
        
        files(fn_index).object_type = 'movie';
        files(fn_index).noLayers = xyloObj.NumberOfFrames;
        I = read(xyloObj, 1); % read first slice
        files(fn_index).height = size(I,1);
        files(fn_index).width = size(I,2);
        files(fn_index).color = size(I,3);
        files(fn_index).time = 1;
        files(fn_index).imgClass = class(I);
        
        if fn_index == 1
            fields = sort(fieldnames(xyloObj));
            for ind = 1:numel(fields)
                img_info(fields{ind}) = xyloObj.(fields{ind});
            end
        end
        if isKey(img_info, 'ColorType')
            if ~strcmp(img_info('ColorType'), 'truecolor')
                img_info = containers.Map;
                msgbox(sprintf('!!! Error !!!\n\nmibGetImageMetadata: files have dissimilar ColorType'),'Mixed colors','error','modal');
                if options.waitbar==1; delete(wb); end
                return;
            end
        else
            img_info('ColorType') = 'truecolor';
        end
    elseif strfind('xml', ext(2:end)) > 0 & options.mibBioformatsCheck == 0     %#ok<AND2>
        img_info  = getXMLheader(filenames{fn_index});
        
        files(fn_index).filename = img_info('Filename');
        files(fn_index).object_type = img_info('Format');
        files(fn_index).extension = 'xml';
        files(fn_index).color = img_info('Colors');
        files(fn_index).level = img_info('ReturnedLevel');
        files(fn_index).ColorType = img_info('ColorType');
        if img_info('Time') == 0;  img_info('Time') = 1;    end    % when time is 0 make it 1;
        files(fn_index).time = img_info('Time');
        if isKey(img_info, 'Datasetname')
            files(fn_index).seriesName = {img_info('Datasetname')};
            remove(img_info,'Datasetname');
        end
        
        if strcmpi(img_info('Format'), 'matlab.hdf5')  % matlab
            %infoHDF5 = h5info(files(fn_index).filename, files(fn_index).seriesName);
            % read a single point to determine the class of the dataset
            I = h5read(files(fn_index).filename, cell2mat(files(fn_index).seriesName), [1 1 1 1 1], [1 1 1 1 1]);
            img_info('imgClass') = class(I);
            files(fn_index).imgClass = class(I);
            files(fn_index).dim_xyczt = [img_info('Width'), img_info('Height'), img_info('Colors'), img_info('Depth'), img_info('Time')];
            
            pixSize = img_info('pixSize');
            remove(img_info,'pixSize');
            
        elseif strcmpi(img_info('Format'), 'bdv.hdf5')  % big data viewer format
            info = h5info(img_info('Filename'));
            offsetIndex = find(ismember({info.Groups(:).Name}, '/t00000') == 1);  % index of the first timepoint
            noLevels = numel(info.Groups(offsetIndex).Groups(1).Groups);  % number of levels in the image pyramid
            img_info('Levels') = noLevels;
            
            pixSize = img_info('pixSize');
            remove(img_info,'pixSize');
            
            if noLevels > 1
                prompt = sprintf('The dataset contains %d image(s)\nPlease choose the one to take (enter "1" to get image in the original size):', noLevels);
                answer = mibInputDlg({options.mibPath}, prompt, 'Select image', '1');
                if isempty(answer); if options.waitbar==1; delete(wb); end; img_info = containers.Map; return; end
                level = str2double(answer);
                if level < 1 || level > noLevels
                    if options.waitbar==1; delete(wb); end
                    errordlg(sprintf('!!! Error !!!\n\nmibGetImageMetadata: Wrong number!\nThe number should be between 1 and %d', noLevels));
                    img_info = containers.Map;
                    return;
                end
                
                if fn_index == 1
                    % update dimensions and pixel sizes for the binned datasets
                    xyzVal = info.Groups(offsetIndex).Groups(1).Groups(level).Datasets.Dataspace.Size;    % unbinned
                    pixSize.x = pixSize.x * img_info('Height')/xyzVal(2);
                    pixSize.y = pixSize.y * img_info('Width')/xyzVal(1);
                    pixSize.z = pixSize.z * img_info('Depth')/xyzVal(3);

                    img_info('Height') = xyzVal(2);
                    img_info('Width') = xyzVal(1);
                    img_info('Depth') = xyzVal(3);
                    img_info('ReturnedLevel') = level;
                end
            end
            
            % detect data type
            dataType = info.Groups(offsetIndex).Groups(1).Groups(img_info('ReturnedLevel')).Datasets.Datatype.Type;
            switch dataType
                case {'H5T_STD_I16LE','H5T_STD_U16LE'}
                    img_info('imgClass') = 'uint16';
                case {'H5T_STD_I8LE','H5T_STD_U8LE'}
                    img_info('imgClass') = 'uint8';
                otherwise
                    if options.waitbar==1; delete(wb); end
                    errordlg(sprintf('Ops!\nmibGetImageMetadata: check image class (%s) and implement!', dataType));
                    return;
            end
            files(fn_index).imgClass = img_info('imgClass');
            
            files(fn_index).dim_xyczt = [img_info('Width'), img_info('Height'), img_info('Colors'), img_info('Depth'), img_info('Time')];
        else
            if options.waitbar==1; delete(wb); end
            img_info = containers.Map;
            errordlg(sprintf('!!! Error !!!\n\nmibGetImageMetadata: can''t detect the format!'));
            return;
        end
        files(fn_index).height = img_info('Height');
        files(fn_index).width = img_info('Width');
        files(fn_index).noLayers = img_info('Depth');
    elseif strfind('h5hdf', ext(2:end)) > 0 & options.mibBioformatsCheck == 0         %#ok<AND2> % HDF5 format
        files(fn_index).filename = cell2mat(filenames(fn_index));
        files(fn_index).object_type = 'hdf5_image';
        [files(fn_index).seriesName, metadata_sw, dim_yxczt, transMatrix] = selectHDFSeries(cellstr(files(fn_index).filename), options.Font);
        pause(.1);
        if strcmp(files(fn_index).seriesName,'Cancel')
            img_info = containers.Map;
            if options.waitbar==1; delete(wb); end
            return;
        end
        
        % dataset should be transposed
        if ~isnan(transMatrix(1))
            dim_yxczt = dim_yxczt(transMatrix);
        end
        
        info = struct();
        info.DatasetName = cell2mat(files(fn_index).seriesName);
        info.Filename = files(fn_index).filename;
        infoHDF5 = h5info(files(fn_index).filename, cell2mat(files(fn_index).seriesName));
        
        if numel(infoHDF5.Attributes) > 0
            attrIndex = find(ismember({infoHDF5.Attributes.Name},'axistags')==1);
            if ~isempty(attrIndex)  % axistags are present -> i.e. Ilastik dataset
                if iscell(infoHDF5.Attributes(attrIndex).Value)
                    axistags = infoHDF5.Attributes(attrIndex).Value{:};
                else
                    axistags = infoHDF5.Attributes(attrIndex).Value;
                end
                try
                    axistags = p_json(axistags);  % parse the axistags
                    img_info('ImageDescription') = axistags.axes{1}.description;
                catch err
                    % fix, the following case:
                    %
                    % "description": "BoundingBox 22.85280 64.00440 70.62840 104.57640 0.00000 2.40120    |<?xml version="1.0" encodi...
                    % },
                    descriptionId = strfind(axistags, 'description');
                    braketId = strfind(axistags, '}');
                    if ~isempty(descriptionId)
                        braketId2 = braketId(find(braketId>descriptionId(1)));
                        descriptionText = axistags(descriptionId(1)+14:braketId2(1)-4);
                    end
                    img_info('ImageDescription') = descriptionText;
                end
            end
        end
        
        %axistags = h5readatt(files(fn_index).filename, cell2mat(files(fn_index).seriesName), 'axistags');
        
        %         if metadata_sw  % read meta data
        %             if ~isempty(infoHDF5.Attributes)
        %                 for i=1:numel(infoHDF5.Attributes)
        %                     if isnumeric(infoHDF5.Attributes(i).Value)
        %                         if size(infoHDF5.Attributes(i).Value,1) > 1
        %                             info.(infoHDF5.Attributes(i).Name) = num2str(infoHDF5.Attributes(i).Value');
        %                         else
        %                             info.(infoHDF5.Attributes(i).Name) = num2str(infoHDF5.Attributes(i).Value);
        %                         end
        %                     else
        %                         info.(infoHDF5.Attributes(i).Name) = infoHDF5.Attributes(i).Value;
        %                     end
        %                 end
        %             end
        %         end
        
        
        % read a single point to determine the class of the dataset
        I = h5read(files(fn_index).filename, cell2mat(files(fn_index).seriesName),ones(1,sum(dim_yxczt>0)),ones(1,sum(dim_yxczt>0)));
        %I = h5read(files(fn_index).filename, cell2mat(files(fn_index).seriesName),ones(1,sum(dim_yxczt>1)),ones(1,sum(dim_yxczt>1)));
        
        if fn_index == 1
            fields = sort(fieldnames(info));
            for ind = 1:numel(fields)
                img_info(fields{ind}) = info.(fields{ind});
            end
        end
        
        if dim_yxczt(3) == 1
            currentColorType = 'grayscale';
        else
            currentColorType = 'truecolor';
        end
        
        if isKey(img_info, 'ColorType')
            if ~strcmp(img_info('ColorType'), currentColorType)
                img_info = containers.Map;
                if options.waitbar==1; delete(wb); end
                msgbox('mibGetImageMetadata: files have dissimilar ColorType','Mixed colors','error','modal');
                return;
            end
        else
            img_info('ColorType') = currentColorType;
        end
        
        files(fn_index).noLayers = max([1 dim_yxczt(4)]);
        files(fn_index).height = max([1 dim_yxczt(1)]);
        files(fn_index).width = max([1 dim_yxczt(2)]);
        files(fn_index).color = max([1 dim_yxczt(3)]);
        files(fn_index).time = max([dim_yxczt(5) 1]);
        files(fn_index).imgClass = class(I);
        files(fn_index).dim_xyczt = dim_yxczt;
        if ~isnan(transMatrix(1))
            files(fn_index).transMatrix = transMatrix;
        end
    elseif numel(strfind('nrrd', ext(2:end))) > 0 && options.mibBioformatsCheck == 0     % NRRD format
        files(fn_index).filename = cell2mat(filenames(fn_index));
        [meta, datatype] = get_nrrd_metadata(files(fn_index).filename);
        dims = str2num(meta.sizes); %#ok<ST2NM>
        files(fn_index).object_type = 'nrrd';
        if str2double(meta.dimension) == 4  % color image or stack
            files(fn_index).dim_xyczt = [dims(2), dims(3), dims(1), dims(4), 1];
            img_info('ColorType') = 'truecolor';
        else                                % grayscale image or stack
            files(fn_index).dim_xyczt = [dims(1), dims(2), 1, dims(3), 1];
            img_info('ColorType') = 'grayscale';
        end
        files(fn_index).noLayers = files(fn_index).dim_xyczt(4);
        files(fn_index).height = files(fn_index).dim_xyczt(2);
        files(fn_index).width =  files(fn_index).dim_xyczt(1);
        files(fn_index).color =  files(fn_index).dim_xyczt(3);
        files(fn_index).time = 1;
        
        files(fn_index).imgClass = datatype;
        if fn_index == 1
            openBr = strfind(meta.spacedirections, '(');
            closeBr = strfind(meta.spacedirections, ')');
            voxX = str2num(meta.spacedirections(openBr(1)+1:closeBr(1)-1)); %#ok<ST2NM>
            pixSize.x = voxX(1);
            voxY = str2num(meta.spacedirections(openBr(2)+1:closeBr(2)-1)); %#ok<ST2NM>
            pixSize.y = voxY(2);
            voxZ = str2num(meta.spacedirections(openBr(3)+1:closeBr(3)-1)); %#ok<ST2NM>
            pixSize.z = voxZ(3);
            if isfield(meta, 'spaceorigin')
                shiftsXYZ = str2num(meta.spaceorigin(2:end-1)); %#ok<ST2NM>
                shiftsXYZ(1) = -shiftsXYZ(1);
                shiftsXYZ(2) = -shiftsXYZ(2);
            else
                shiftsXYZ = [0;0;0];
            end
            img_info('ImageDescription') = sprintf('BoundingBox %.5f %.5f %.5f %.5f %.5f %.5f', shiftsXYZ(1),shiftsXYZ(1)+pixSize.y*max([1 (files(fn_index).dim_xyczt(1)-1)]),...
                shiftsXYZ(2),shiftsXYZ(2)+pixSize.x*max([1 (files(fn_index).dim_xyczt(2)-1)]),...
                shiftsXYZ(3),shiftsXYZ(3)+pixSize.z*max([1 (files(fn_index).dim_xyczt(4)-1)]));
        end
    elseif numel(strfind('am', ext(2:end))) > 0 && options.mibBioformatsCheck == 0     % Amira Mesh
        files(fn_index).filename = cell2mat(filenames(fn_index));
        files(fn_index).object_type = 'amiramesh';
        [~, info, dim_xyczt] = getAmiraMeshHeader(files(fn_index).filename);
        if isKey(img_info, 'ColorType')
            if ~strcmp(img_info('ColorType'), info('ColorType'))
                img_info = containers.Map;
                msgbox('Files have dissimilar ColorType','Mixed colors','error','modal');
                if options.waitbar==1; delete(wb); end
                return;
            end
        else
            img_info('ColorType') = info('ColorType');
        end
        
        % update lutColors
        if isKey(info, 'Channel1_Color')
            lutColors = zeros([dim_xyczt(3), 3]);
            for colId=1:dim_xyczt(3)
                colChName = sprintf('Channel%d_Color', colId);
                lutColors(colId, :) = str2num(info(colChName));
            end
            if isKey(img_info, 'lutColors')
                lutColorsExiting = img_info('lutColors');
                lutColorsExiting(1:size(lutColors,1),:) = lutColors;
                img_info('lutColors') = lutColorsExiting;
            else
                img_info('lutColors') = lutColors;
            end
            
        end
        
        if options.customSections
            result = ib_amiraImportGui(dim_xyczt);
            if ~isstruct(result)
                if options.waitbar==1; delete(wb); end
                img_info = containers.Map;
                if options.waitbar==1; delete(wb); end
                return;
            end
            
            files(fn_index).noLayers = numel(result.startIndex:result.zstep:result.endIndex);
            files(fn_index).depth_start = result.startIndex;
            files(fn_index).depth_end = result.endIndex;
            if files(fn_index).noLayers == 1
                files(fn_index).depth_step = 1;
            else
                files(fn_index).depth_step = result.zstep;
            end
            files(fn_index).xy_step = result.xystep;
            files(fn_index).resizeMethod = result.method;
            files(fn_index).height = floor(dim_xyczt(2)/result.xystep);
            files(fn_index).width = floor(dim_xyczt(1)/result.xystep);
        else
            files(fn_index).noLayers = dim_xyczt(4);
            files(fn_index).height = dim_xyczt(2);
            files(fn_index).width = dim_xyczt(1);
        end
        
        % update pixel size
        if fn_index == 1
            bbStart = strfind(info('ImageDescription'), 'BoundingBox');
            if ~isempty(bbStart)
                info('ImageDescription') = strrep(info('ImageDescription'), sprintf('\t'), '|');    % replace tabs (from old MIB versions) with |
                brakePnt = strfind(info('ImageDescription'), '|');
                if isempty(brakePnt); brakePnt = numel(info('ImageDescription'))+1; end
                try
                    brakePnt = brakePnt(1);
                    bbString = info('ImageDescription');
                    bb_coord = str2num(bbString(bbStart+11:brakePnt-1)); %#ok<ST2NM>
                    dx = bb_coord(2)-bb_coord(1);
                    dy = bb_coord(4)-bb_coord(3);
                    dz = bb_coord(6)-bb_coord(5);
                catch err
                    dx = max([files(fn_index).width 2])-1;
                    dy = max([files(fn_index).height 2])-1;
                    dz = max([files(fn_index).noLayers 2])-1;
                end
            end

            pixSize.x = dx/(max([files(fn_index).width 2])-1);  % tweek for saving single layered tifs for Amira
            pixSize.y = dy/(max([files(fn_index).height 2])-1);
            pixSize.z = dz/(max([files(fn_index).noLayers 2])-1);
            if pixSize.z == 0; pixSize.z = min([pixSize.x pixSize.y]); end
            pixSize.units = 'um';
            
            % update img_info
            info('Filename') = files(fn_index).filename;
            fields = sort(keys(info));
            for ind = 1:numel(fields)
                if ~strcmp(fields{ind}, 'lutColors')
                    img_info(fields{ind}) = info(fields{ind});
                else
                    if ischar(info(fields{ind}))
                        img_info(fields{ind}) = str2num(info(fields{ind})); %#ok<ST2NM>
                    end
                end
            end
        end
        
        files(fn_index).color = dim_xyczt(3);
        files(fn_index).time = 1;
        
        files(fn_index).dim_xyczt = dim_xyczt;
        files(fn_index).imgClass = info('imgClass');
    elseif strfind(cell2mat([image_formats.ext]), ext(2:end)) > 0 & options.mibBioformatsCheck == 0 %#ok<AND2> % standard image types
        files(fn_index).filename = cell2mat(filenames(fn_index));
        files(fn_index).object_type = 'image';
        info = imfinfo(files(fn_index).filename);
        if fn_index == 1    % extra check for tif files with pyramids
            if numel(info) > 1 && strcmp(ext(2:end), 'tif')
                if info(1).Width ~= info(2).Width
                    resText = 'W:H ';
                    for ii=1:numel(info)
                        resText = sprintf('%s%dx%d; ', resText, info(ii).Width, info(ii).Height);
                    end
                    prompt = sprintf('This is pyramidal TIF that has %d sub-images [%s]\nPlease choose the one to take (enter "1" to get image in the original size):', numel(info),resText);
                    answer = mibInputDlg({options.mibPath}, prompt, 'Select image', '1');
                    if isempty(answer); if options.waitbar==1; delete(wb); end; return; end
                    files(fn_index).level = str2double(answer);
                end
            end
        end
        if isfield(files, 'level')
            info = info(files(1).level);
            files(fn_index).level = files(1).level;
        end
        
        fields = sort(fieldnames(info));
        NumberOfFrames = numel(info);
        
        % convert cells to chars
        for fieldIdx = 1:numel(fields)
            if iscell(info(1).(fields{fieldIdx}))
                if numel(info.(fields{fieldIdx})) < 2   % sometimes there are more cell arrays in the metadata, skip those % TODO in future
                    info.(fields{fieldIdx}) = cell2mat(info.(fields{fieldIdx}));
                end
            end
        end
        
        % move Comment to the ImageDescription for jpg files
        if strcmp(ext, '.jpg') || strcmp(ext, '.png')
            info.ImageDescription = info.Comment;
            info = rmfield(info, 'Comment');
            fields = sort(fieldnames(info));
        end
        
        files(fn_index).height = info(1).Height;
        files(fn_index).width = info(1).Width;
        files(fn_index).noLayers = NumberOfFrames;
        files(fn_index).time = 1;
        
        switch info(1).BitDepth     % alternative field is info(1).BitsPerSample but not all formats have it
            case {8, 24}    % grayscale and RGB
                files(fn_index).imgClass = 'uint8';
            case {16, 48}   % grayscale and RGB
                files(fn_index).imgClass = 'uint16';
            case {32, 96}   % grayscale and RGB
                files(fn_index).imgClass = 'uint32';
            otherwise
                files(fn_index).imgClass = 'single';
        end
        
        if isKey(img_info, 'ColorType')
            if ~strcmp(img_info('ColorType'), info(1).ColorType)
                img_info = containers.Map;
                if options.waitbar==1; delete(wb); end
                msgbox(sprintf('!!! Error !!!\n\nmibGetImageMetadata: files have dissimilar ColorType'),'Mixed colors','error','modal');
                return;
            end
        end
        
        if strcmp(info(1).ColorType, 'truecolor')
            files(fn_index).color = 3;
        else
            files(fn_index).color = 1;
        end
        
        % update pixel size
        if fn_index == 1
            % generate img_info taking information from the 1st image
            currKeys = keys(img_info);
            fields(ismember(fields, {'StripByteCounts', 'StripOffsets','UnknownTags'})) = [];
            addFieldsIds = find(ismember(fields, currKeys) == 0);
            for ind=1:numel(addFieldsIds)
                img_info(fields{ind}) = info(1).(fields{ind});
            end
            
            if isKey(img_info, 'ImageDescription')
                bbStart = strfind(img_info('ImageDescription'), 'BoundingBox');
                if ~isempty(bbStart)
                    brakePnt = strfind(img_info('ImageDescription'), '|');
                    if isempty(brakePnt)
                        brakePnt = strfind(img_info('ImageDescription'), sprintf('\t'));
                        if isempty(brakePnt)
                            brakePnt = strfind(img_info('ImageDescription'), sprintf('\n'));
                        end
                    end
                    if ~isempty(brakePnt)
                        brakePnt = brakePnt(1);
                        bbString = img_info('ImageDescription');
                        bb_coord = str2num(bbString(bbStart+11:brakePnt-1)); %#ok<ST2NM>
                        dx = bb_coord(2)-bb_coord(1);
                        dy = bb_coord(4)-bb_coord(3);
                        dz = bb_coord(6)-bb_coord(5);
                        
                        pixSize.x = dx/(max([files(fn_index).width 2])-1);  % tweek for saving single layered tifs for Amira
                        pixSize.y = dy/(max([files(fn_index).height 2])-1);
                        pixSize.z = dz/(max([files(fn_index).noLayers 2])-1);
                        if pixSize.z == 0; pixSize.z = min([pixSize.x pixSize.y]); end
                        pixSize.units = 'um';
                    end
                end
            end
        end
        
    elseif strfind('recmrcstpreali', ext(2:end)) > 0 & options.mibBioformatsCheck == 0         %#ok<AND2> % MRC format
        files(fn_index).filename = cell2mat(filenames(fn_index));
        files(fn_index).object_type = 'mrc_image';
        mrcFile = MRCImage(files(fn_index).filename,0);  % create pointer to a file volume
        info = getHeader(mrcFile);     % get header
        % reshape the labels into ImageDescription
        pixSize.x = info.cellDimensionX/info.nX/10000;
        pixSize.y = info.cellDimensionY/info.nY/10000;
        pixSize.z = info.cellDimensionZ/info.nZ/10000;
        pixSize.units = 'um';
        xyzZero(1) = info.xOrigin/10000;
        xyzZero(2) = info.yOrigin/10000;
        xyzZero(3) = info.zOrigin/10000;
        dx = (info.nX-1)*pixSize.x;
        dy = (info.nY-1)*pixSize.y;
        dz = (info.nZ-1)*pixSize.z;
        labelOut = sprintf('BoundingBox %.6f %.6f %.6f %.6f %.6f %.6f \t',...
            xyzZero(1), xyzZero(1)+dx, ...
            xyzZero(2), xyzZero(2)+dy, ...
            xyzZero(3), xyzZero(3)+dz);
        
        for labelId = 1:size(info.labels,1)
            labelOut = sprintf('%s|%s', labelOut, regexprep(info.labels(labelId,:), '\s+', ' '));
        end
        info.ImageDescription = labelOut;
        if isKey(img_info, 'ColorType')
            if ~strcmp(img_info('ColorType'), 'grayscale')
                img_info = containers.Map;
                msgbox('Files have dissimilar ColorType','Mixed colors','error','modal');
                if options.waitbar==1; delete(wb); end
                return;
            end
        else
            info.ColorType = 'grayscale';
        end
        info.Filename = files(fn_index).filename;
        info = rmfield(info, 'labels');
        
        if fn_index == 1
            fields = sort(fieldnames(info));
            for ind = 1:numel(fields)
                img_info(fields{ind}) = info.(fields{ind});
            end
        end
        
        layer_id = layer_id + info.nZ;
        files(fn_index).height = info.nY;
        files(fn_index).width = info.nX;
        files(fn_index).noLayers = info.nZ;
        files(fn_index).color = 1;
        files(fn_index).time = 1;
        
        [minInt, maxInt] = getMinAndMaxDensity(mrcFile);
        diffInt = maxInt - minInt;
        
        if diffInt <= 255
            files(fn_index).imgClass = 'uint8';
        elseif diffInt <= 65535
            files(fn_index).imgClass = 'uint16';
        elseif diffInt <= 4294967295
            files(fn_index).imgClass = 'uint32';
        else
            img_info=containers.Map;
            if options.waitbar==1; delete(wb); end
            return;
        end
        close(mrcFile);
    elseif options.mibBioformatsCheck == 1    % load meta for bio-formats
        if fn_index == 1
            %r = bfGetReader(filenames{fn_index});       % init the reader
            % Cache the initialized readers for each file and close the reader
            filesTemp.hDataset = loci.formats.Memoizer(bfGetReader(), 0, java.io.File(options.BioFormatsMemoizerMemoDir));
            filesTemp.hDataset.setId(filenames{fn_index});
            
            numSeries = filesTemp.hDataset.getSeriesCount();
            if numSeries > 1
                if ~isfield(options, 'BioFormatsIndices')
                    [filesTemp.seriesIndex, filesTemp.hDataset, metaSwitch, filesTemp.dim_xyczt, filesTemp.seriesRealName] = ...
                        selectLociSeries(filenames(fn_index), options.Font, filesTemp.hDataset);  % select series with BioFormats
                else
                    if isempty(options.BioFormatsIndices)
                        filesTemp.seriesIndex = 1:numSeries;
                    else
                        filesTemp.seriesIndex = options.BioFormatsIndices;
                    end
                    metaSwitch = 1;
                    filesTemp.dim_xyczt = zeros(numel(filesTemp.seriesIndex), 5);
                    filesTemp.seriesRealName = cell([numel(filesTemp.seriesIndex), 1]);
                    for i=1:numel(filesTemp.seriesIndex)
                        filesTemp.hDataset.setSeries(i - 1);
                        filesTemp.dim_xyczt(i, 1) = filesTemp.hDataset.getSizeX();
                        filesTemp.dim_xyczt(i, 2) = filesTemp.hDataset.getSizeY();
                        filesTemp.dim_xyczt(i, 3) = filesTemp.hDataset.getSizeC();    % number of color layers
                        filesTemp.dim_xyczt(i, 4) = filesTemp.hDataset.getSizeZ();
                        filesTemp.dim_xyczt(i, 5) = filesTemp.hDataset.getSizeT();    % number of time layers
                        filesTemp.seriesRealName{i} = char(filesTemp.hDataset.getMetadataStore().getImageName(i-1));
                    end
                end
            else    % do not show the series selection dialog
                filesTemp.seriesIndex = 1;
                filesTemp.hDataset.setSeries(filesTemp.seriesIndex - 1);
                metaSwitch = 1;
                filesTemp.dim_xyczt(1) = filesTemp.hDataset.getSizeX();
                filesTemp.dim_xyczt(2) = filesTemp.hDataset.getSizeY();
                filesTemp.dim_xyczt(3) = filesTemp.hDataset.getSizeC();    % number of color layers
                filesTemp.dim_xyczt(4) = filesTemp.hDataset.getSizeZ();
                filesTemp.dim_xyczt(5) = filesTemp.hDataset.getSizeT();    % number of time layers
                filesTemp.seriesRealName{1} = char(filesTemp.hDataset.getMetadataStore().getImageName(0));
            end
            
            omeMeta = filesTemp.hDataset.getMetadataStore();
        else
            filesTemp.hDataset = loci.formats.Memoizer(bfGetReader(), 0, java.io.File(options.BioFormatsMemoizerMemoDir));
            filesTemp.hDataset.setId(filenames{fn_index});
            filesTemp.hDataset.setSeries(filesTemp.seriesIndex(1)-1);
            
            noSeriesTemp = numel(filesTemp.seriesIndex);
            filesTemp.dim_xyczt(1:noSeriesTemp, 1) = filesTemp.hDataset.getSizeX();
            filesTemp.dim_xyczt(1:noSeriesTemp, 2) = filesTemp.hDataset.getSizeY();
            filesTemp.dim_xyczt(1:noSeriesTemp, 3) = filesTemp.hDataset.getSizeC();
            filesTemp.dim_xyczt(1:noSeriesTemp, 4) = filesTemp.hDataset.getSizeZ();
            filesTemp.dim_xyczt(1:noSeriesTemp, 5) = filesTemp.hDataset.getSizeT();
        end
        % have to implement use of DimensionOrder
        filesTemp.DimensionOrder = char(filesTemp.hDataset.getDimensionOrder);
        
        if strcmp(filesTemp.seriesIndex, 'Cancel'); if options.waitbar==1; delete(wb); end; return; end
        
        if ~isfloat(filesTemp.seriesIndex)
            img_info = containers.Map;
            for i=1:numel(files)
                if ~isempty(filesTemp.hDataset)
                    filesTemp.hDataset.close();
                end
            end
            if options.waitbar==1; delete(wb); end
            return;
        end
        
        for fileSubIndex = 1:numel(filesTemp.seriesIndex)
            files(layer_id).filename = cell2mat(filenames(fn_index));
            files(layer_id).origFilename = files(layer_id).filename;
            files(layer_id).object_type = 'bioformats';
            files(layer_id).seriesName = filesTemp.seriesIndex(fileSubIndex);
            files(layer_id).dim_xyczt = filesTemp.dim_xyczt;
            files(layer_id).DimensionOrder = filesTemp.DimensionOrder;
            files(layer_id).BioFormatsMemoizerMemoDir = options.BioFormatsMemoizerMemoDir;    % path to directory containing the memo files
            
            %files(layer_id).seriesRealName = filesTemp.seriesRealName{fileSubIndex};
            [~, files(layer_id).seriesRealName] = fileparts(filesTemp.seriesRealName{fileSubIndex});
            
            if metaSwitch == 1 && fn_index == 1 && fileSubIndex == 1 % read full metadata for the first file
                % extract metadata table for this series
                metadataList = filesTemp.hDataset.getGlobalMetadata();
                %                 if metadataList.isEmpty
                %                     % metadataList = filesTemp.hDataset.getMetadata(); % for old bio-formats
                %                     metadataList = filesTemp.hDataset.getSeriesMetadata();
                %                 end
                
                %                 % test of work with OME-metadata
                %                 omeMeta = filesTemp.hDataset.getMetadataStore();
                %                 omeXML = char(omeMeta.dumpXML());    % to xml
                %                 omeXML = strrep(omeXML,sprintf('\xB5'),'u');     % replace utf-8 characters
                %                 omeXML = strrep(omeXML,sprintf('\xC5'),'A');
                %                 dummyXMLFilename = fullfile(dirId, 'dummy.xml');    % save xml to a file
                %                 fid = fopen(dummyXMLFilename, 'w');
                %                 fprintf(fid,'%s',omeXML);
                %                 fclose(fid);
                %                 omeStruct = xml2struct(dummyXMLFilename);           % load and convert xml to structure
                %                 delete(dummyXMLFilename);           % delete dummy xml file
                
                metadataKeys = metadataList.keySet().iterator();
                for i=1:metadataList.size()
                    currKey = metadataKeys.nextElement();
                    if isempty(currKey); continue; end
                    value = metadataList.get(currKey);
                    
                    % modify keys names, i.e. remove spaces and other
                    % special characters, to be compatible with AmiraMesh
                    % format
                    %currKey = regexprep(currKey,'[_%! ()[]{}/|\\#?.,]', '_');
                    %currKey = strrep(currKey,sprintf('\xC5'),'A');
                    %currKey = strrep(currKey,sprintf('\xB5'),'u');
                    img_info(currKey) = value;
                end
                
                % load additional SeriesMetadata
                metadataList = filesTemp.hDataset.getSeriesMetadata();
                metadataKeys = metadataList.keySet().iterator();
                SeriesMetadata = containers.Map;
                for i=1:metadataList.size()
                    currKey = metadataKeys.nextElement();
                    if isempty(currKey); continue; end
                    value = metadataList.get(currKey);
                    
                    % modify keys names, i.e. remove spaces and other
                    % special characters, to be compatible with AmiraMesh
                    % format
                    %currKey = regexprep(currKey,'[_%! ()[]{}/|\\#?.,]', '_');
                    %currKey = strrep(currKey,sprintf('\xC5'),'A');
                    %currKey = strrep(currKey,sprintf('\xB5'),'u');
                    SeriesMetadata(currKey) = value;
                end
                img_info('SeriesMetadata') = SeriesMetadata;
                
                %                 keySet = metadataList.keySet();
                %                 keySet = keySet.toArray();
                %                 warning off; %#ok<WNOFF>
                %
                %                 for keyIndex=1:numel(keySet)
                %                     key = keySet(keyIndex);
                %                     if isempty(key); continue; end;
                %                     value =  metadataList.get(key);
                %                     if isempty(value); continue; end;
                %
                %                     % modify keys names to allow use them as field names
                %                     field = key;
                %                     field = strrep(field,'_','');
                %                     field = strrep(field,'[','_');
                %                     field = strrep(field,']',' ');
                %                     field = strrep(field,'(','_');
                %                     field = strrep(field,')',' ');
                %                     field = strrep(field,'-','_');
                %                     field = strrep(field,'/','_');
                %                     field = strrep(field,'\','_');
                %                     field = strrep(field,'|','_');
                %                     field = strrep(field,'#','');
                %                     field = strrep(field,'?','');
                %                     field = strrep(field,sprintf('\xC5'),'A');
                %                     field = strrep(field,sprintf('\xB5'),'u');
                %                     field = strrep(field,'.','_');
                %                     field = strrep(field,' ','_');
                %                     field = strrep(field, 65533, '');
                %                     field = strtrim(field);
                %
                %                     if numel(field) < 1; continue; end;
                %
                %                     img_info(field) = value;
                %
                %                 end
                %                 warning on; %#ok<WNON>
            end
            
            img_info('Filename') = files(layer_id).filename;
            img_info('SeriesNumber') = files(layer_id).seriesName;
            %img_info('SeriesName') = files(layer_id).seriesRealName;
            
            files(layer_id).height = filesTemp.dim_xyczt(fileSubIndex, 2);
            files(layer_id).width = filesTemp.dim_xyczt(fileSubIndex, 1);
            if filesTemp.dim_xyczt(fileSubIndex, 4) == 1 && filesTemp.dim_xyczt(fileSubIndex, 5) > 1 && options.virtual == 0
                files(layer_id).noLayers = max([filesTemp.dim_xyczt(fileSubIndex, 4) filesTemp.dim_xyczt(fileSubIndex, 5)]);
                files(fn_index).time = 1;
            else
                files(layer_id).noLayers = filesTemp.dim_xyczt(fileSubIndex, 4);
                files(fn_index).time = filesTemp.dim_xyczt(fileSubIndex, 5);
            end
            files(layer_id).color = filesTemp.dim_xyczt(fileSubIndex, 3);
            
            bpp = filesTemp.hDataset.getBitsPerPixel();
            if bpp <= 8
                files(layer_id).imgClass = 'uint8';
            elseif bpp <= 16
                files(layer_id).imgClass = 'uint16';
            elseif bpp <= 32
                files(layer_id).imgClass = 'uint32';
            else
                files(layer_id).imgClass = 'double';
            end
            
            [path, name, ext] = fileparts(files(layer_id).filename);
            if numel(filesTemp.seriesIndex) > 1     % when more than one image is taken from the image container generate a unique filename
                files(layer_id).filename = fullfile(path, [name '__' files(layer_id).seriesRealName ext]);
            end
            layer_id = layer_id + 1;
        end
        filesTemp.hDataset.close();
        
        % update pixel size
        %omeMeta = filesTemp.hDataset.getMetadataStore();
        if fn_index == 1
            %omeMeta = filesTemp.hDataset.getMetadataStore();
            omeXML = char(omeMeta.dumpXML());    % to xml
            omeXML = strrep(omeXML, sprintf('\xB5'),'u');     % mu, replace utf-8 characters
            omeXML = strrep(omeXML,sprintf('\xC5'),'A');      % Angstrem
            
            dummyXMLFilename = fullfile(dirId, 'dummy.xml');    % save xml to a file
            fid = fopen(dummyXMLFilename, 'w');
            if fid == -1
                dummyXMLFilename = fullfile(tempdir, 'dummy.xml');
                fid = fopen(dummyXMLFilename, 'w');
            end
            fprintf(fid, '%s', omeXML);
            fclose(fid);
            meta = xml2struct(dummyXMLFilename);           % load and convert xml to structure
            delete(dummyXMLFilename);           % delete dummy xml file
            img_info('meta') = meta.OME;
            
            try     % old vws data do not have this option
                xVal = double(omeMeta.getPixelsPhysicalSizeX(filesTemp.seriesIndex(fileSubIndex)-1).value(ome.units.UNITS.MICROM));
                if isempty(xVal)
                    pixSize.x = 1;   % in um
                    pixSize.y = 1;   % in um
                else
                    pixSize.x = double(omeMeta.getPixelsPhysicalSizeX(filesTemp.seriesIndex(fileSubIndex)-1).value(ome.units.UNITS.MICROM));   % in um
                    pixSize.y = double(omeMeta.getPixelsPhysicalSizeY(filesTemp.seriesIndex(fileSubIndex)-1).value(ome.units.UNITS.MICROM));   % in um
                end
                zVal = omeMeta.getPixelsPhysicalSizeZ(filesTemp.seriesIndex(fileSubIndex)-1);
                if isempty(zVal)
                    pixSize.z = pixSize.y;   % in um
                else
                    pixSize.z = double(omeMeta.getPixelsPhysicalSizeZ(filesTemp.seriesIndex(fileSubIndex)-1).value(ome.units.UNITS.MICROM));   % in um
                end
            catch err
                continue;
            end
            
            % fix X and Y for dm4
            [~,~,ext] = fileparts(filenames{fn_index});
            if strcmp(ext, '.dm4') && pixSize.x ~= pixSize.y
                pixSize.z = pixSize.x;
                pixSize.x = pixSize.y;
            end
            
            pixSize.units = 'um';
            
            try
                dt = omeMeta.getPlaneDeltaT(0,0);
            catch err
                dt = [];
            end
            if ~isempty(dt)
                if double(dt.value) == 0    % force pixSize.t be 1
                    pixSize.t = 1;
                else
                    pixSize.t = double(dt.value);
                end
            else
                pixSize.t = 1;
            end
            pixSize.tunits = 's';
        end
        
        % get colors for the color channels
        colorsVec = [files.color];
        maxColorChannel = max(colorsVec);
        indexOfDataset = find(colorsVec==maxColorChannel,1);     % index with largest number of colors
        indexOfDataset = files(indexOfDataset).seriesName-1;
        if ~isempty(omeMeta.getChannelColor(indexOfDataset, 0))
            rgb = zeros(maxColorChannel, 3);
            for colCh=1:maxColorChannel
                rgb(colCh, 1) = omeMeta.getChannelColor(indexOfDataset, colCh-1).getRed();
                rgb(colCh, 2) = omeMeta.getChannelColor(indexOfDataset, colCh-1).getGreen();
                rgb(colCh, 3) = omeMeta.getChannelColor(indexOfDataset, colCh-1).getBlue();
            end
            img_info('lutColors') = rgb/255;
        elseif ~isempty(omeMeta.getChannelExcitationWavelength(indexOfDataset, 0))
            rgb = zeros(maxColorChannel, 3);
            for colCh=1:maxColorChannel
                Wavelength = double(omeMeta.getChannelEmissionWavelength(indexOfDataset, colCh-1).value());
                %Wavelength = double(omeMeta.getChannelExcitationWavelength(indexOfDataset, colCh-1).value());
                rgb(colCh, :) = wavelength2rgb(Wavelength);
            end
            img_info('lutColors') = rgb/255;
        end
    end
    
    if options.waitbar==1 && mod(layer_id, ceil(no_files/20))==0
        waitbar(fn_index/no_files,wb);
    end
end

% replace CR and LF characters with spaces
if isKey(img_info,'ImageDescription') && ~isempty(img_info('ImageDescription'))
    img_info('ImageDescription') = strrep(strrep(img_info('ImageDescription'), sprintf('%s', 13), ' '), sprintf('%s', 10), '');
    if numel(unique([files.width])) > 1 || numel(unique([files.height])) > 1
        % require to recalculate the bounding box
        bbStart = strfind(img_info('ImageDescription'), 'BoundingBox');
        if ~isempty(bbStart)
            brakePnt = strfind(img_info('ImageDescription'), '|');
            if isempty(brakePnt); brakePnt = numel(img_info('ImageDescription'))+1; end
            try
                brakePnt = brakePnt(1);
                bbString = img_info('ImageDescription');
                bb = str2num(bbString(bbStart+11:brakePnt-1)); %#ok<ST2NM>
            catch err
                bb = [0 0 0 0 0 0];
            end
            bb(2) = max([files.width])*pixSize.x + bb(1);
            bb(4) = max([files.height])*pixSize.y + bb(3);
            bb(6) = sum([files.noLayers])*pixSize.z + bb(5);
            
            str2 = sprintf('BoundingBox %.5f %.5f %.5f %.5f %.5f %.5f ',bb(1),bb(2),bb(3),bb(4),bb(5),bb(6));
            curr_text = img_info('ImageDescription');
            bb_info_exist = strfind(curr_text, 'BoundingBox');
            if bb_info_exist == 1
                spaces = strfind(curr_text,'|');
                if ~isempty(spaces)
                    img_info('ImageDescription') = [str2 curr_text(spaces(1):end)];
                else
                    img_info('ImageDescription') = str2;
                end
            else
                img_info('ImageDescription') = [str2 curr_text];
            end
        end
    end
end


switch files(1).imgClass
    case {'single', 'double'}
        img_info('MaxInt') = realmax(files(1).imgClass);
    otherwise
        img_info('MaxInt') = double(intmax(files(1).imgClass));
end
img_info('Colors') = files(1).color;
img_info('imgClass') = files(1).imgClass; 

% generate layerNames, which are the file names of the datasets that were
% used to generate a stack
if numel(files) > 1
    SliceName = cell(sum(arrayfun(@(x) x.noLayers, files)), 1);
    index = 1;
    for fileId = 1:numel(files)
        [~, fnShort, ext]  = fileparts(files(fileId).filename);
        SliceName(index:index+files(fileId).noLayers-1) = repmat(cellstr(strcat(fnShort, ext)), [files(fileId).noLayers 1]);
        index = index+files(fileId).noLayers;
    end
    img_info('SliceName') = SliceName;
else
    [~, fnShort, ext]  = fileparts(files.filename);
    img_info('SliceName') = cellstr(strcat(fnShort, ext));
end

if options.waitbar==1; delete(wb); end
img_info('Filename') = filenames{1};
end
