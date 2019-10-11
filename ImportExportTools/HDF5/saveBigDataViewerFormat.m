function result = saveBigDataViewerFormat(filename, I, options)
% function result = saveBigDataViewerFormat(filename, I, options, ImageDescription)
% Save dataset using the BigDataViewer format of Fiji
%
% The format description: http://fiji.sc/BigDataViewer#About_the_BigDataViewer_data_format
%
% Parameters:
% filename: name of the file: xml or h5
% I: image dataset, [1:height, 1:width, 1:colors, 1:depth, 1:time]
% options:  [@em optional], a structure with extra parameters
%   .ChunkSize - [@em optional], a matrix that defines chunking layout
%   .Deflate - [@em optional], a number that defines gzip compression level (0-9).
%   .SubSampling - [@em optional], a matrix that defines scaling factor for
%          the image pyramid (for example, [1,1,1; 2,2,2; 4,4,4] makes 3 levels)
%   .ResamplingMethod - [@em optional], a string that defines resampling method
%   .t - time point, when time point > 1, the dataset will be added to the exising
%   .lutColor - [@em optional], a matrix with definition of color channels [1:colorChannel, R G B], (0-1)
%   .showWaitbar - if @b 1 - show the wait bar, if @b 0 - do not show
%   .ImageDescription - [@em optional], a string with description of the dataset
%
% Return values:
% result: @b 0 - fail, @b 1 - success

%| 
% @b Examples:
% @code result = saveBigDataViewerFormat('mydataset.h5', I, options);  // save dataset @endcode

% Copyright (C) 31.01.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

result = 0;
if nargin < 3; options = struct(); end

[path, baseName, ext] = fileparts(filename);

options.Datatype = class(I);     % Possible: double,uint64,uint32,uint16,uint8,single,int64,int32,int16,int8

% check options
if ~isfield(options, 'ChunkSize'); options.ChunkSize = [64, 64, 64]; end
if ~isfield(options, 'Deflate'); options.Deflate = 0; end
if ~isfield(options, 'SubSampling'); options.SubSampling = '1,1,1'; end
if ~isfield(options, 'ResamplingMethod'); options.ResamplingMethod = 'bicubic'; end
if ~isfield(options, 't'); options.t = 1; end

height = size(I,1);
width = size(I,2);
colors = size(I,3);
depth = size(I,4);
time = size(I,5);

% check data class
availableClassesList = {'double','uint64','uint32','uint16','uint8','single','int64','int32','int16','int8'};
if ~ismember(options.Datatype, availableClassesList)
    errordlg(sprintf('!!! Error !!!\n\nWrong data class (%s)!\nAvailable classes:\ndouble,uint64,uint32,uint16,uint8,single,int64,int32,int16,int8', options.Datatype), 'Wrong class');
    return;
end

if options.showWaitbar
    set(0, 'DefaulttextInterpreter', 'none'); 
    wb = waitbar(0,sprintf('Saving:\n%s\nPlease wait...', filename),'Name','Saving to BDV');
end

% convert to int16 (the only class accepted by BDV)
if isa(I, 'int16') == 0
    if isa(I, 'uint8')
        I = uint16(I);
    end
    
    I = typecast(I(:),'int16');
    I = reshape(I, [height, width, colors, depth, time]);
    options.Datatype = 'int16';
end

noLevels = size(options.SubSampling,2);
noDims = size(options.SubSampling,1);

if size(options.ChunkSize, 2) ~= noLevels   % when chunk size is defined for one level, use it for all levels
    options.ChunkSize = repmat(options.ChunkSize,[1, noLevels]);
end

if options.showWaitbar;    waitbar(0.1, wb); end
h5Filename = fullfile(path, [baseName '.h5']);
if options.t(1) == 1
    if exist(h5Filename, 'file')==2; delete(h5Filename); end
    
    % % write header
    % datasetName = sprintf('__DATA_TYPES__', colId-1);
    
    for colId = 1:colors
        % generate s00, s01... datasets with resolutions and subdivisions
        datasetName = sprintf('/s%02i/resolutions', colId-1);
        h5create(h5Filename, datasetName, [noDims, noLevels], 'Datatype', 'double','ChunkSize', [noDims, 1]);
        h5write(h5Filename, datasetName, options.SubSampling);
        %h5create(h5Filename, datasetName, [Inf, Inf], 'Datatype', 'double','ChunkSize', [noDims, 1]);
        %h5write(h5Filename, datasetName, options.subSampling, [1 1], [noDims 1]);

        datasetName = sprintf('/s%02i/subdivisions', colId-1);
        h5create(h5Filename, datasetName, [noDims, noLevels], 'Datatype', 'int32','ChunkSize', [noDims, 1]);
        h5write(h5Filename, datasetName, int32(options.ChunkSize));
        %h5create(h5Filename, datasetName, [Inf, Inf], 'Datatype', 'int32','ChunkSize', [noDims, 1]);
        %h5write(h5Filename, datasetName, int32(options.ChunkSize), [1 1], [noDims 1]);
        
        if isfield(options, 'lutColors')
            datasetName = sprintf('/s%02i/color', colId-1);
            h5create(h5Filename, datasetName, [noDims, 1], 'Datatype', 'int32','ChunkSize', [noDims, 1]);
            h5write(h5Filename, datasetName, int32(options.lutColors(colId,:))');
        end
    end
    
    % storing image desciption field
    if isfield(options, 'ImageDescription')
        file_id = H5F.open(h5Filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
        space_id = H5S.create('H5S_SCALAR');
        stype = H5T.copy('H5T_C_S1');
        sz = numel(options.ImageDescription);
        H5T.set_size(stype,sz);
        dataset_id = H5D.create(file_id,'/ImageDescription', stype,space_id,'H5P_DEFAULT');
        H5D.write(dataset_id,stype,'H5S_ALL','H5S_ALL','H5P_DEFAULT', options.ImageDescription);
        H5D.close(dataset_id)
        H5S.close(space_id)
        H5F.close(file_id);
    end
end

index = 1;
% main data loop
for timeId = 1:size(I, 5)
    timeId2 = options.t(1) + timeId - 1;
    for colId = 1:colors
        for levelId = 1:noLevels
            newH = round(height/options.SubSampling(1,levelId));
            newW = round(width/options.SubSampling(2,levelId));
            newZ = round(depth/options.SubSampling(3,levelId));
            
            % % --------- resize dataset
            if newW ~= width || newH ~= height || newZ ~= depth  
                if options.showWaitbar;    waitbar(0.2, wb); end;
                resizeOpt.height = newH;
                resizeOpt.width = newW;
                resizeOpt.depth = newZ;
                resizeOpt.method = options.ResamplingMethod;
                resizeOpt.algorithm = 'imresize';
                imgOut = squeeze(mib_resize3d(I(:, :, colId, :, timeId), [], resizeOpt));
            else
                imgOut = squeeze(I(:,:,colId,:,timeId));
            end
            
            datasetName = sprintf('/t%05i/s%02i/%d/cells', timeId2-1, colId-1, levelId-1);
            
            % make sure that ChunkSize smaller than size of the dataset
            ChunkSize = zeros(size(options.ChunkSize(:,levelId)'));
            for i=1:noDims
                ChunkSize(i) = min([options.ChunkSize(i,levelId) size(imgOut, i)]);
            end
            if options.showWaitbar;    waitbar(0.6, wb); end;
            h5create(h5Filename, datasetName, [newH, newW, newZ], ...
                'Datatype', options.Datatype, 'ChunkSize', ChunkSize, 'Deflate', options.Deflate);
            h5write(h5Filename, datasetName, imgOut);
            %h5create(h5Filename, datasetName, [Inf, Inf, Inf], ...
            %    'Datatype', options.Datatype, 'ChunkSize', ChunkSize, 'Deflate', options.Deflate);
            %h5write(h5Filename, datasetName, imgOut, [1 1 1], [newH, newW, newZ]);
            
            index = index + 1;
            if options.showWaitbar;    waitbar(1, wb); end;
         end
    end
end
if options.showWaitbar;    delete(wb); end;

% % saving string test
% data = 'Hello World!';
% %file_id = H5F.create(h5Filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
% file_id = H5F.open(h5Filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
% space_id = H5S.create('H5S_SCALAR');
% stype = H5T.copy('H5T_C_S1'); 
% sz = numel(data);
% H5T.set_size(stype,sz);
% 
% dataset_id = H5D.create(file_id,'/s00/ImageDescription', stype,space_id,'H5P_DEFAULT');
% H5D.write(dataset_id,stype,'H5S_ALL','H5S_ALL','H5P_DEFAULT',data);
% H5D.close(dataset_id)
% H5S.close(space_id)
% H5F.close(file_id);

end

