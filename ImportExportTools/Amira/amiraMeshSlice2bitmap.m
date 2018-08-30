function bitmap = amiraMeshSlice2bitmap(filename, sliceNo, x1, y1, x2, y2, options)
% function bitmap = amiraMeshSlice2bitmap(filename, sliceNo, x1, y1, x2, y2)
% Extracts a slice or its subsection from Amira Mesh to bitmap matrix [1:height, 1:width, 1:colors]
%
% Parameters:
% filename: (@em optional), a filename of amira mesh file, when omitted a file selection dialog is started.
% sliceNo: slice number
% x1: starting x point
% y1: starting y point
% x2: ending x point
% y2: ending y point
% options: an optional structure with additional parameters
%   .classType - a string with the class of the image, 'uint8', 'uint16', 'uint32'
%   .width - width of the image
%   .height - height of the image
%   .depth - depth of the image
%   .colors - number of colors
%
% Return values:
% bitmap: - dataset, [1:height, 1:width, 1:colors]

% Copyright (C) 21.06.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates

bitmap = [];
if nargin < 7; options = struct(); end
if nargin < 2; sliceNo = 1; end
if nargin < 1
    [filename, pathname] = uigetfile( ...
        {'*.am','Amira mesh labels(*.am)';
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file');
    if filename == 0; return; end
    filename = [pathname filename];
end
fid = fopen(filename, 'r');

fseek(fid, 1215, 'bof'); % skip to position after @1, which is 1215 for Huh7.am, find it with ftell

% % define type of data
% tline = fgetl(fid);
% if strcmp(tline, '# AmiraMesh 3D ASCII 2.0')
%     type = 'ascii';
% elseif strcmp(tline, '# AmiraMesh BINARY-LITTLE-ENDIAN 2.1') || strcmp(tline,'# AmiraMesh 3D BINARY 2.0')
%     type = 'binary';
% else
%     disp('Error! Unknown type'); return;
% end
% 
% if ~isfield(options, 'width') || ~isfield(options, 'height') || ~isfield(options, 'depth')
%     % define lattice info
%     while numel(strfind(tline,'Lattice')) == 0
%         tline = fgetl(fid);
%     end
%     spaces = strfind(tline,' ');
%     options.width = str2double(tline(spaces(2):spaces(3)));
%     options.height = str2double(tline(spaces(3):spaces(4)));
%     options.depth = str2double(tline(spaces(4):end));
% end
% 
% % get Parameters
% %while numel(strfind(tline,'Parameters')) == 0
% %    tline = fgetl(fid);
% %end
% 
% tline = fgetl(fid);
% if ~isfield(options, 'classType') || ~isfield(options, 'colors')
%     % get number of data blocks
%     dataIndex = 1;
%     while numel(strfind(tline,'# Data section follows')) == 0
%         if numel(strfind(tline,'Lattice')) ~= 0
%             if numel(strfind(tline,'byte Labels')) ~= 0 
%                 fclose(fid);
%                 if customSections == 1
%                     msgbox(sprintf('The Amira Mesh Labels is not yet implemented for partial opening of the dataset!\n\nPlease open full dataset'),'Error','error','modal');
%                 else
%                     bitmap = amiraLabels2bitmap(filename);    
%                 end
%                 return;
%             end
%             if numel(strfind(tline,'byte')) ~= 0
%                 options.classType(dataIndex) = cellstr('uint8');
%                 bytesPerPixel = 1;
%             elseif numel(strfind(tline,'ushort')) ~= 0 || numel(strfind(tline,'usingle')) ~= 0
%                 options.classType(dataIndex) = cellstr('uint16');
%                 bytesPerPixel = 2;
%             end
%             % define number of colors
%             openBlock = strfind(tline,'[');
%             closeBlock = strfind(tline,']');
%             if ~isempty(openBlock) && ~isempty(closeBlock)
%                 colorChannels(dataIndex) = str2double(tline(openBlock+1:closeBlock-1));
%             else
%                 colorChannels(dataIndex) = 1;
%             end
%             dataIndex = dataIndex + 1;
%         end
%         tline = fgetl(fid);
%     end
%     maxColors = sum(colorChannels);
% else
%     switch options.classType{1}
%         case 'uint8'
%             bytesPerPixel = 1;
%         case 'uint16'
%             bytesPerPixel = 2;
%         case 'uint32'
%             bytesPerPixel = 4;            
%     end
%     maxColors = sum(options.colors);
%     dataIndex = 2;
%     colorChannels(1) = options.colors;
% end
% 
% while numel(strfind(tline,'# Data section follows')) == 0
%     tline = fgetl(fid);
% end

%if numel(colorChannels) == 1 && colorChannels(1) == 4   % RGB image encoded as RGB+Alpha
%    bitmap = zeros([floor(height/xy_step), floor(width/xy_step), maxColors-1, depth], options.classType{1});
%else
    maxColors = options.colors;
    dataIndex = 2;
    colorChannels(1) = options.colors;
    switch options.classType{1}
        case 'uint8'
            bytesPerPixel = 1;
        case 'uint16'
            bytesPerPixel = 2;
        case 'uint32'
            bytesPerPixel = 4;            
    end
    bitmap = zeros([y2-y1+1, x2-x1+1, maxColors], options.classType{1});
%end

color_id = 0;
for dataBlock = 1:dataIndex - 1
    %tline = fgetl(fid); %#ok<NASGU> % @1
    color_id = color_id + 1;
    % fseek to the start of the section to load
    fseek(fid, options.height*options.width*colorChannels(dataBlock)*(sliceNo-1)*bytesPerPixel, 0);
    
    bitmap = zeros([x2-x1+1, y2-y1+1, options.colors], options.classType{1});
    for yIndex=1:y2-y1+1
        %if strcmp(type,'ascii')     % get ascii
            %             dataVec = zeros(height*width*colorChannels(dataBlock),1,classType{dataBlock});
            %             for index=1:height*width*colorChannels(dataBlock)
            %                 dataVec(index) = str2double(fgetl(fid));
            %             end
        %else    % get binary
            fseek(fid, (y1-1)*bytesPerPixel, 0);  % fseek dX block
            bitmap(:,yIndex) = fread(fid, x2-x1+1, ['*' options.classType{dataBlock}], 0, 'ieee-le'); % get a row of pixels
            fseek(fid, (options.height-y2)*bytesPerPixel, 0);  % fseek dX block
        %end
    end
    bitmap = permute(bitmap, [2 1]);
    
%     if colorChannels(dataBlock)==1
%         %dataVec = reshape(dataVec, [x2-x1+1, y2-y1+1])';
%         bitmap(:,:,color_id:color_id+colorChannels(dataBlock)-1) = dataVec;
%     else
%         %dataVec = reshape(dataVec, [colorChannels(dataBlock), x2-x1+1, y2-y1+1]);
%         dataVec = permute(dataVec, [2 1]);
%         
%         if colorChannels(dataBlock) == 4 && numel(colorChannels) == 1 % RGB+Alpha, remove Alpha
%             bitmap(:,:,color_id:color_id+colorChannels(dataBlock)-2) = dataVec(:,:,1:3);
%         else
%             bitmap(:,:,color_id:color_id+colorChannels(dataBlock)-1) = dataVec;
%         end
%     end
    
      %tline = fgetl(fid);     % character return symbol
end
fclose(fid);

end