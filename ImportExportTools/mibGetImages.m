% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function [img, img_info] = mibGetImages(files, img_info, options)
% function [img, img_info] = mibGetImages(files, img_info, options)
% Generate image dataset from the files structure and the img_info containers.Map.
%
% Parameters:
%       files: - > structure from getImageMetadata.m
%          - .object_type -> type of the data, ''movie'', ''hdf5_image'', ''image''
%          - .filename - filenames
%          - .seriesName -> name of the series for HDF5/Bioformats
%          - .height -> image height
%          - .width -> image width
%          - .color -> number of color channels
%          - .noLayers -> number of image slices in the file
%          - .imgClass -> class of the image, ''uint8'',''uint16''...
%          - .dim_xyczt -> dimensions for hdf5_image and Bioformats, AmiraMesh (binned version)
%          - .depth_start - > [@em optional], for Amira Mesh only, to take only specified sections
%          - .depth_end - > [@em optional], for Amira Mesh only, to take only specified sections
%          - .depth_step -> [@em optional], for Amira Mesh only, Z-step to take not all sections
%          - .xy_step -> [@em optional], for Amira Mesh only, XY-step, i.e. binning factor
%          - .resizeMethod -> [@em optional], for Amira Mesh only, resize method for binning the XY-dimension, ''nearest'', ''bilinear'', ''bicubic''
%          - .backgroundColor -> [@em optional], to define a color when generating a stack from images of different XY dimensions. Only files(1).background is needed
%          - .level -> level of the image pyramid to load or an inden within TIF container
%		   - .xMin -> optional for loading of a region within the image, min X coordinate of the region to load
%		   - .xMax -> optional for loading of a region within the image, max X coordinate of the region to load%
%		   - .yMin -> optional for loading of a region within the image, min Y coordinate of the region to load
%		   - .yMax -> optional for loading of a region within the image, max Y coordinate of the region to load
%          - .zMin -> optional for loading of a region within the image, min Z coordinate of the region to load
%		   - .zMax -> optional for loading of a region within the image, max Z coordinate of the region to load
%		   - .xyStep -> optional for loading of a region within the image, XY step, pixels between are skipped
%       img_info: -> containers.Map with details of the dataset from getImageMetadata()
%       options: -> structure with options
%          - .waitbar -> @b 0 - no waitbar, @b 1 - show waitbar
%          - .imgStretch [optional] -> stretch or not the image if it is uint32 class
%          - .silentMode [optional] -> when true - do not ask questions
%
%
% Return values:
%   img: -> image dataset [1:height, 1:width, 1:color, 1:z]
%   img_info: -> modified containers.Map with details of the dataset

% Updates
% 14.04.2022, IB, added loading of subregions from TIF files

if nargin < 2
    img = NaN;
    error('Wrong number of parameters');
end
if nargin < 3;     options.waitbar = 1;  end
if ~isfield(options, 'waitbar');    options.waitbar = 1; end
if ~isfield(options, 'imgStretch');    options.imgStretch = 1; end
if ~isfield(options, 'silentMode');    options.silentMode = false; end

% memory pre-allocation
height = max([files(:).height]);
width = max([files(:).width]);
color = max([files(:).color]);
time = max([files(:).time]);
% calculate the total number of sections in the dataset
maxZ = 0;
if isfield(files, 'zMin')
    for i=1:numel(files)
        maxZ = maxZ + files(i).zMax - files(i).zMin + 1;
    end
else
    for i=1:numel(files)
        maxZ = maxZ + files(i).noLayers;
    end
end

if strcmp(files(1).object_type,'bioformats')    % adjust number of sections, for bio-formats, when more than one serie was selected
    maxZ = maxZ * numel(files(1).seriesName);
end
if isempty(maxZ); return; end

imgClass = files(1).imgClass;
if strcmp(imgClass, 'int16'); imgClass = 'uint16'; end

if isfield(files, 'backgroundColor')
    img = zeros([height, width, color, maxZ, time],imgClass)+files(1).backgroundColor;
else
    img = zeros([height, width, color, maxZ, time],imgClass);
end

% calculate coefficient to update the waitbar 
pixPerSlice = size(img,1)*size(img,2);    % number of pixels in a slice
waitbarUpdateFrequency = max([1 round(4096^2 / pixPerSlice)]);

layer_id = 1;   % z-slice index
no_files = numel(files);

if options.waitbar
    drawnow;
    wb = waitbar(0, sprintf('Loading images\nPlease wait...'), 'Name', 'Loading images...', ...
        'CreateCancelBtn','setappdata(gcbf, ''canceling'', 1)');
end

for fn_index = 1:no_files
    % Check for clicked Cancel button
    if options.waitbar
        if getappdata(wb, 'canceling')
            if options.waitbar; delete(wb); end
            img = NaN;
            img_info = containers.Map;
            return;
        end
    end

    maxY = min([height files(fn_index).height]);
    maxX = min([width files(fn_index).width]);
    maxC = min([color files(fn_index).color]);
    maxT = min([time files(fn_index).time]);
    if strcmp(files(fn_index).object_type, 'movie')      % movie object
        xyloObj = VideoReader(files(fn_index).filename); %#ok<TNMLP>    % for matlab 8.0 and older
        
        for subLayer=1:xyloObj.NumberOfFrames
            I = read(xyloObj, subLayer);
            img(1:maxY,1:maxX,1:maxC,layer_id) = I(1:maxY,1:maxX,1:maxC);

            % update waitbar
            if options.waitbar && mod(subLayer, waitbarUpdateFrequency)==0
                if getappdata(wb, 'canceling')
                    img = NaN;
                    delete(wb);
                    return;
                end
                waitbar(subLayer/xyloObj.NumberOfFrames, wb);
            end
            layer_id = layer_id + 1;
        end
        if options.waitbar; waitbar(layer_id/maxZ, wb); end
    elseif strcmp(files(fn_index).object_type,'nrrd')        % NRRD format
        if ~ismac
            I = nrrdLoadWithMetadata(files(fn_index).filename);
        else
            I = nhdr_nrrd_read(files(fn_index).filename, 1);
        end
        if files(fn_index).dim_xyczt(3) == 1     % greyscale stack/image
            I.data = permute(I.data, [2 1 3]);
        else     % color stack/image
            I.data = permute(I.data, [3 2 1 4]);
        end
        
        img(1:maxY,1:maxX,1:maxC,layer_id:layer_id+files(fn_index).noLayers-1) = I.data;

        % update waitbar
        if options.waitbar && mod(layer_id, waitbarUpdateFrequency)==0
            if getappdata(wb, 'canceling')
                img = NaN;
                delete(wb);
                return;
            end
            waitbar(layer_id/maxZ, wb);
        end

        layer_id = layer_id + files(fn_index).noLayers;
    elseif strcmp(files(fn_index).object_type,'bdv.hdf5')        % BigDataViewer format
        opt.level = img_info('ReturnedLevel');
        imgIn = loadBigDataViewerFormat(files(fn_index).filename, opt, img_info);
        img(1:maxY, 1:maxX, 1:maxC, layer_id:layer_id+files(fn_index).noLayers-1, 1:maxT) = imgIn(1:maxY,1:maxX,1:maxC,1:files(fn_index).noLayers, 1:maxT);
        clear imgIn;

        % update waitbar
        if options.waitbar && mod(layer_id, waitbarUpdateFrequency)==0
            if getappdata(wb, 'canceling')
                img = NaN;
                delete(wb);
                return;
            end
            waitbar(layer_id/maxZ, wb);
        end

        layer_id = layer_id + files(fn_index).noLayers;
    elseif strcmp(files(fn_index).object_type,'hdf5_image') || strcmp(files(fn_index).object_type,'matlab.hdf5')        % HDF5 format
        hdf5_image = h5read(files(fn_index).filename, cell2mat(files(fn_index).seriesName));
        if iscell(hdf5_image)   % if the data is not numerical
            if options.waitbar; delete(wb); end
            assignin('base','hdf5_image',hdf5_image);
            disp('HDF5 reader: created "hdf5_image" variable in the Matlab workspace');
            msgbox(sprintf('mibGetImages:\nCan not read this dataset!\nInstead it was exported as "hdf5_image" to the main Matlab workspace.'),'Error!','error','modal');
            img = NaN;
            return;
        end
        if isa(hdf5_image,'single')   % convert to unsigned integers
            maxVal = max(max(max(max(max(hdf5_image)))));
            if maxVal <= 1  % when data is squeezed between 0 and 1
                hdf5_image = uint8(hdf5_image*255);
                if layer_id == 1; img = uint8(img); end % correct img class
            elseif maxVal <= 255
                hdf5_image = uint8(hdf5_image);
                if layer_id == 1; img = uint8(img); end % correct img class
            elseif maxVal < 65535
                hdf5_image = uint16(hdf5_image);
                if layer_id == 1; img = uint16(img); end % correct img class
            else
                hdf5_image = uint32(hdf5_image);
                if layer_id == 1; img = uint32(img); end % correct img class
            end
            msgbox(sprintf('mibGetImages:\nThe dataset was converted to %s format!',class(hdf5_image)),'Warning!','warn','modal');
        end
        
        img_info('MaxInt') = double(intmax(class(hdf5_image)));
        
        % reshape the dataset if needed
        if isfield(files(fn_index), 'transMatrix')
            hdf5_image = permute(hdf5_image, files(fn_index).transMatrix);
        end
        img(1:maxY,1:maxX,1:maxC,layer_id:layer_id+files(fn_index).noLayers-1,1:maxT) = hdf5_image;
        clear hdf5_image;

        % update waitbar
        if options.waitbar && mod(layer_id, waitbarUpdateFrequency)==0
            if getappdata(wb, 'canceling')
                img = NaN;
                delete(wb);
                return;
            end
            waitbar(layer_id/maxZ, wb);
        end
        layer_id = layer_id + files(fn_index).noLayers;
    elseif strcmp(files(fn_index).object_type,'amiramesh')        % Amira Mesh
        if options.waitbar
            options.hWaitbar = wb;
            options.maxZ = maxZ;
        else
            options.hWaitbar = NaN;
        end     % send waitbar handle to amiraMesh2bitmap
        
        if isfield(files(fn_index), 'depth_start')
            options.depth_start = files(fn_index).depth_start;
            options.depth_end = files(fn_index).depth_end;
            options.depth_step = files(fn_index).depth_step;
            options.xy_step = files(fn_index).xy_step;
            options.resizeMethod = files(fn_index).resizeMethod;
            img(1:maxY,1:maxX,1:maxC,layer_id:layer_id+files(fn_index).noLayers-1) = amiraMesh2bitmap(files(fn_index).filename, options);
            
            % fix BoundingBox info for Amira Mesh binned dataset
            curr_text = img_info('ImageDescription');
            bb_info_exist = strfind(curr_text,'BoundingBox');
            
            if bb_info_exist == 1   % use information from the BoundingBox parameter for pixel sizes if it is exist
                spaces = strfind(curr_text,' ');
                if numel(spaces) < 7; spaces(7) = numel(curr_text); end
                tab_pos = strfind(curr_text,sprintf('\t'));
                pos = min([spaces(7) tab_pos]);
                bb = str2num(curr_text(spaces(1):pos)); %#ok<ST2NM>
                % bb(1) = Xmin
                % bb(2) = Width
                % bb(3) = Ymin
                % bb(4) = Height
                % bb(5) = Zmin
                % bb(6) = Thickness
                
                % BoundingBox 0.00000 54.02070 -0.00000 54.02069 0.00000 3.96000
                % Pixels: 0.0386138 0.04
                
                startZShift = (options.depth_start-1)/files(fn_index).dim_xyczt(4)*(bb(6)-bb(5));
                endZShift = startZShift + (options.depth_step /(files(fn_index).dim_xyczt(4)-1)*(bb(6)-bb(5)))*(max([files(fn_index).noLayers 2])-1); % tweak for Amira Bounding Box bug
                bb(6) = bb(5) + endZShift;
                bb(5) = bb(5) + startZShift;
                str2 = sprintf('BoundingBox %.5f %.5f %.5f %.5f %.5f %.5f ',bb(1),bb(2),bb(3),bb(4),bb(5),bb(6));
                curr_text = img_info('ImageDescription');
                bb_info_exist = strfind(curr_text,'BoundingBox');
                if bb_info_exist == 1
                    spaces = strfind(curr_text,' ');
                    if numel(spaces) < 7; spaces(7) = numel(curr_text); end
                    tab_pos = strfind(curr_text,sprintf('\t'));
                    % 12    14    21    23    28    30
                    pos = min([spaces(7) tab_pos]);
                    img_info('ImageDescription') = [str2 curr_text(pos:end)];
                else
                    img_info('ImageDescription') = [str2 curr_text];
                end
            end
        else
            img(1:maxY,1:maxX,1:maxC,layer_id:layer_id+files(fn_index).noLayers-1) = amiraMesh2bitmap(files(fn_index).filename, options);
        end
        layer_id = layer_id + files(fn_index).noLayers;
        if options.waitbar; waitbar(layer_id/maxZ, wb); end
    elseif strcmp(files(fn_index).object_type,'image')        % standard images
        % % the code below is to load colormaps individually for each
        % % frame, but it seems that there is unique colormap for the whole image, or matlab can't read individual ones 
%         convertGifSwitch = 0;
%         if ~isempty(strfind(files(fn_index).extension, 'gif')) && files(fn_index).noLayers > 1
%             choice = questdlg(sprintf('Convert indexed GIF to truecolor?'), 'Image Format Warning!', 'Yes','No','Yes');
%             if strcmp(choice, 'Yes');
%                 convertGifSwitch = 1;
%                 img_info('ColorType') = 'truecolor';     % change type of the dataset to truecolor
%                 remove(img_info,'ColorTable');   % remove color table
%                 maxC = max([maxC, 3]);
%                 files(fn_index).color = maxC;
%             end
%         end
        
        for subLayer=1:files(fn_index).noLayers
            if ~isfield(files, 'xMin')
                if files(fn_index).noLayers == 1
                    if ~isfield(files, 'level')
                        I = imread(files(fn_index).filename);
                    else
                        I = imread(files(fn_index).filename, files(fn_index).level);
                    end
                else
                    I = imread(files(fn_index).filename,subLayer);
                end
            else
                if files(fn_index).noLayers == 1
                    if ~isfield(files, 'level')
                        I = imread(files(fn_index).filename, ...
                            'PixelRegion', ...
                            {[files(fn_index).yMin files(fn_index).xyStep files(fn_index).yMax], ...
                            [files(fn_index).xMin files(fn_index).xyStep files(fn_index).xMax]});
                    else
                        I = imread(files(fn_index).filename, files(fn_index).level, ...
                            'PixelRegion', ...
                            {[files(fn_index).yMin files(fn_index).xyStep files(fn_index).yMax], ...
                            [files(fn_index).xMin files(fn_index).xyStep files(fn_index).xMax]});
                    end
                else
                    if subLayer < files(fn_index).zMin || subLayer > files(fn_index).zMax; continue; end
                    I = imread(files(fn_index).filename, subLayer, ...
                            'PixelRegion', ...
                            {[files(fn_index).yMin files(fn_index).xyStep files(fn_index).yMax], ...
                            [files(fn_index).xMin files(fn_index).xyStep files(fn_index).xMax]});
                end
            end
            if isa(I, 'single')     % uint32 RGB TIFs may be this class
                if isKey(img_info, 'MaxSampleValue')
                    I = bsxfun(@times, I, reshape(img_info('MaxSampleValue'), 1, 1, []));
                end
            end
            img(1:maxY, 1:maxX, 1:size(I,3), layer_id) = I(1:maxY, 1:maxX, 1:size(I,3));
            % update waitbar
            if options.waitbar && mod(layer_id, waitbarUpdateFrequency)==0
                if getappdata(wb, 'canceling')
                    img = NaN;
                    delete(wb);
                    return;
                end
                waitbar(layer_id/maxZ, wb);
            end
            layer_id = layer_id + 1;
        end
    elseif strcmp(files(fn_index).object_type,'mrc_image')        % IMOD mrc/rec image
        mrcFile = MRCImage(files(fn_index).filename, 1);
        mrc_image = getVolume(mrcFile);
        %mrc_image = flip(mrc_image, 2);     % flip vertically
        if isa(mrc_image,'single') || isa(mrc_image,'int16')
            [minInt, maxInt] = getMinAndMaxDensity(mrcFile); %#ok<NASGU>
            if minInt < 0 && ~options.silentMode
                button =  questdlg(sprintf('mibGetImages:\nThe dataset will be converted to unsigned integer class...'),'Convert image','Yes','Cancel','Yes');
                if strcmp(button, 'Cancel') == 1
                    img_info = containers.Map;
                    return;
                end
                options.silentMode = true;
            end
            if minInt < 0; mrc_image = mrc_image - minInt; end
            %diffInt = maxInt - minInt;
            %if diffInt <= 255
            %    mrc_image = uint8(mrc_image);
            %elseif diffInt <= 65535
            %    mrc_image = uint16(mrc_image);
            %elseif diffInt <= 4294967295
            %    mrc_image = uint32(mrc_image);
            %end
            
            %mrc_image = permute(mrc_image,[2 1 3]);
            %mrc_image = reshape(mrc_image,[maxY maxX 1 size(mrc_image,3)]);
            %img(1:maxY,1:maxX,1:maxC,layer_id:layer_id+files(fn_index).noLayers-1) = mrc_image(1:maxY,1:maxX,1,:);
            
            for subLayer=1:files(fn_index).noLayers
                img(1:maxY,1:maxX,1:maxC,layer_id) = flip(mrc_image(:,:,subLayer)', 1);
                layer_id = layer_id + 1;
                if options.waitbar && mod(layer_id, waitbarUpdateFrequency)==0
                    if getappdata(wb, 'canceling')
                        img = NaN;
                        delete(wb);
                        return;
                    end
                    waitbar(layer_id/maxZ, wb);
                end
            end
        else
            mrc_image = flip(permute(mrc_image, [2 1 3]), 1);
            img(1:maxY, 1:maxX, 1:maxC, layer_id:layer_id+files(fn_index).noLayers-1) = ...
                reshape(mrc_image, [size(mrc_image,1), size(mrc_image,2),1,size(mrc_image,3)]);
        end
        layer_id = layer_id + files(fn_index).noLayers;
        close(mrcFile);
    elseif strcmp(files(fn_index).object_type,'bioformats')        % bioformats images
        bfopenOptions.BioFormatsMemoizerMemoDir = files(fn_index).BioFormatsMemoizerMemoDir;
        if options.waitbar
            bfopenOptions.waitbarHandle = wb;
            bfopenOptions.waitbarUpdateFrequency = waitbarUpdateFrequency;
        end
        if isfield(files, 'DimensionOrder')
            bfopenOptions.DimensionOrder = files(fn_index).DimensionOrder;
        end
        
        % update settings for custom sections, requires xMin, xMax, yMin, yMax, xyStep fields
        if isfield(files, 'xMin')
            bfopenOptions.x1 = files(1).xMin;
            bfopenOptions.y1 = files(1).yMin;
            bfopenOptions.z1 = files(1).zMin;
            bfopenOptions.dx = files(1).xMax - files(1).xMin + 1;
            bfopenOptions.dy = files(1).yMax - files(1).yMin + 1;
            bfopenOptions.dz = files(1).zMax - files(1).zMin + 1;
        end

        for serieIndex=1:numel(files(fn_index).seriesName)
            I  = bfopen4(files(fn_index).origFilename, files(fn_index).seriesName(serieIndex), NaN, bfopenOptions);
            if isempty(I)
                img = NaN;
                return;
            end

            for subLayer=1:files(fn_index).noLayers        % filling image Info structure
                img(1:maxY,1:maxX,1:maxC,layer_id,1:maxT) = I.img(1:maxY,1:maxX,1:maxC,subLayer,1:maxT);
                img_info('ColorType') = I.ColorType;
                img_info('ColorMap') = I.ColorMap;
                layer_id = layer_id + 1;
                if options.waitbar && mod(layer_id, waitbarUpdateFrequency)==0
                    if getappdata(wb, 'canceling')
                        img = NaN;
                        delete(wb);
                        return;
                    end
                    waitbar(layer_id/maxZ, wb);
                end
            end
        end
    elseif strcmp(files(fn_index).object_type,'mibImg')        % bioformats images
        res = load(files(fn_index).filename, '-mat');
        if strcmp(res.options.dimOrder, 'yxzct')
            res.(res.imgVariable) = permute(res.(res.imgVariable), [1 2 4 3 5]);    % permute to yxczt
        end
        img(1:maxY, 1:maxX, 1:maxC, layer_id:layer_id+files(fn_index).noLayers-1) = ...
                res.(res.imgVariable);
        layer_id = layer_id + files(fn_index).noLayers;    
    end
end

% Check for clicked Cancel button; repeat check here to take care of
% loading of large single files
if options.waitbar
    if getappdata(wb, 'canceling')
        delete(wb);
        img = NaN;
        img_info = containers.Map;
        return;
    end
end

if isa(img, 'uint32') && options.imgStretch==1  % convert to 16 bit image format
    maxVal = max(max(max(max(img))));
    minVal = min(min(min(min(img))));
    
    prompt = {sprintf('Enter minimal intensity value\n(this value will be set to 0):'),...
              sprintf('Enter maximal intensity value\n(this value will be set to 65535):')};
    defAns = {num2str(minVal), num2str(maxVal)};
    
    mibInputMultiDlgOpt.PromptLines = [2, 2];
    answer = mibInputMultiDlg([], prompt, defAns, 'Conversion to 16bit format', mibInputMultiDlgOpt);
    if isempty(answer); return; end
    
    %drawnow;    % otherwise crashes
    if isempty(answer)
        if options.waitbar; delete(wb); end
        img = NaN;
        return;
    end
    minVal = str2double(answer{1});
    maxVal = str2double(answer{2});
    % convert to uint16
    %maxVal = mean(maxVal);
    %minVal = mean(minVal);
    img = img-minVal;
    img = uint16(img/((maxVal-minVal)/65535));
    
    img_info('MaxInt') = double(intmax('uint16'));
    img_info('imgClass') = 'uint16';
end

img_info('Height') = height;
img_info('Width') = width;
img_info('Depth') = maxZ;
img_info('Time') = maxT;

% adding needed fields to img_info
if isKey(img_info,'ColorType')
    if strcmp(img_info('ColorType'),'indexed')
        if ~isKey(img_info,'Colormap')    % copy ColorTable to Colormap when no colormap present for indexed images
            img_info('Colormap') = img_info('ColorTable');
        end
    else
        if size(img,3) == 1
            img_info('ColorType') = 'grayscale';
        else
            img_info('ColorType') = 'truecolor';
        end 
    end
else
    if size(img,3) == 1
        img_info('ColorType') = 'grayscale';
    else
        img_info('ColorType') = 'truecolor';
    end
end

if ~isKey(img_info,'ImageDescription')
    img_info('ImageDescription') = '';
end

if options.waitbar; delete(wb); end
end