function result = bitmap2amiraLabels(filename, bitmap, format, voxel, color_list, modelMaterialNames, overwrite, showWaitbar, extraOptions)
% function result = bitmap2amiraLabels(filename, bitmap, format, voxel, color_list, modelMaterialNames, overwrite, showWaitbar, extraOptions)
% Convert matrix [1:height, 1:width, 1:no_stacks] to Amira Mesh Labels
%
% Parameters:
% filename: filename for Amira Mesh file
% bitmap: the dataset, [1:height, 1:width, 1:no_stacks] 
% format: [@em optional], saving format: ''binaryRLE'', ''ascii'', ''binary'' (@b default)
% voxel: [@em optional], a structure with voxel size: 
% - voxel.x - physical width of a voxel
% - voxel.y - physical height of a voxel
% - voxel.z - physical thickness of a voxel
% - voxel.minx - minimal X coordinate of the bounding box
% - voxel.miny - minimal Y coordinate of the bounding box
% - voxel.minz - minimal Z coordinate of the bounding box
% color_list: [@em optional], a matrix with colors for the materials as
% [materialId][Red, Green, Blue] from 0-1; can be empty
% modelMaterialNames: [@em optional], cell array with names of the
% materials, can be empty 
% overwrite: [@em optional], if @b 1 do not check whether file with provided filename already exists
% showWaitbar: [@em optional], if @b 1 - show the wait bar, if @b 0 - do not show
% extraOptions: [@em optional], a structure with additional paramters
% .TransformationMatrix - a string with the transformation matrix
%
% Return values:
% result: result of the function run, @b 1 - success, @b 0 - fail

% Copyright (C) 19.07.2010 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 10.08.2010 - added voxel size
% 02.09.2011 - added minimal coordinates of the bounding box
% 07.07.2016 - added possibility to have color_list and modelMaterialNames empty
% 15.03.2018 - added saving of models with more than 255 materials
% 04.06.2018 - save TransformationMatrix with AmiraMesh
% 11.12.2018 - added auto remove of spaces in material names

result = 0;
%warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 

minValRLE = 1;  % minimal value for using RLE compression
if nargin < 2
    error('Please provide filename, and bitmap matrix!');
end
if nargin < 9;    extraOptions = struct(); end
if nargin < 8   % add waitbar switch
    showWaitbar = 1;
end
if nargin < 7   % automatically overwrite files
    overwrite = 0;
end
if nargin < 6;   modelMaterialNames = []; end  
if nargin < 5;   color_list = []; end

if nargin < 4   % generate color_list
    voxel.x = 1;
    voxel.y = 1;
    voxel.z = 1;
    voxel.minx = 0;
    voxel.miny = 0;
    voxel.minz = 0;
end
if nargin < 3; format = 'binary'; end

useMaterialNames = 1;     % save material names and colors
if isa(bitmap, 'uint16') || isa(bitmap, 'uint32')
    useMaterialNames = 0;
end

if useMaterialNames
    if isempty(color_list)      % generate color_list
        maxColor = max(max(max(bitmap)));
        if maxColor == 1
            color_list = squeeze(label2rgb(1:maxColor))';
        else
            color_list = squeeze(label2rgb(1:maxColor));    
        end
        color_list = color_list/255;
    end

    if isempty(modelMaterialNames)  % generate material names
        maxColor = max(max(max(bitmap)));
        for color=1:maxColor
            modelMaterialNames(color) = cellstr(num2str(color));
        end
    else
        % remove spaces
        for i=1:numel(modelMaterialNames)
            matName = strtrim(modelMaterialNames{i});
            spaceIndices = ismember(matName, ' ');
            matName(spaceIndices) = [];     % remove spaces
            modelMaterialNames{i} = matName;
        end
    end

    if max(max(color_list)) > 1     % normalize to 0-1 range
        color_list = color_list/max(max(color_list));
    end
end

if overwrite == 0
    if exist(filename,'file') == 2
        button = questdlg(sprintf('!!! Warning !!!\n\nThe file\n%s already exists!\nOverwrite?', filename),'Overwrite?','Overwrite','Cancel','Cancel');
        if strcmp(button, 'Cancel'); return; end
    end
end
if showWaitbar
    wb = waitbar(0,sprintf('%s\nPlease wait...',filename),'Name',sprintf('Saving Amira Mesh [%s]...', format));
    set(findall(wb,'type','text'),'Interpreter','none');
    waitbar(0, wb);
end

fid = fopen(filename, 'w');

% saving the file type into header
if strcmp(format,'binary') || strcmp(format,'binaryRLE')
    fprintf(fid,'# AmiraMesh BINARY-LITTLE-ENDIAN 2.1\n\n\n');
elseif strcmp(format,'ascii')
    fprintf(fid,'# AmiraMesh 3D ASCII 2.0\n\n\n');
else
    fclose(fid);
    error('Wrong format!');
end

% saving the header
fprintf(fid,'define Lattice %d %d %d\n\n',size(bitmap,2),size(bitmap,1),size(bitmap,3));
fprintf(fid,'Parameters {\n');
if useMaterialNames
    fprintf(fid,'    Materials {\n');
    fprintf(fid,'        Exterior {\n');
    fprintf(fid,'        }\n');
    for contour=1:max(max(max(bitmap)))
        if isnan(str2double(modelMaterialNames{contour}))
            fprintf(fid,'        %s {\n', modelMaterialNames{contour});
        else
            fprintf(fid,'        Material_%s {\n', modelMaterialNames{contour});
        end
        fprintf(fid,'            Id %d,\n', contour);
        fprintf(fid,'            Color %f %f %f 0 \n', color_list(contour,1),color_list(contour,2),color_list(contour,3));
        fprintf(fid,'        }\n');
    end
    fprintf(fid,'    }\n');
end

classText = 'byte';
switch class(bitmap)
    case 'uint8'
        classText = 'byte';
    case 'uint16'
        classText = 'ushort';
    case 'uint32'
        classText = 'int';
end

fprintf(fid,'    Content "%dx%dx%d %s, uniform coordinates",\n',size(bitmap,2),size(bitmap,1),size(bitmap,3), classText);

fprintf(fid,'    BoundingBox %f %f %f %f %f %f,\n',...
    voxel.minx, voxel.minx+(size(bitmap,2)-1)*voxel.x,...
    voxel.miny, voxel.miny+(size(bitmap,1)-1)*voxel.y,...
    voxel.minz, voxel.minz+(size(bitmap,3)-1)*voxel.z);
fprintf(fid,'    CoordType "uniform"');

if isfield(extraOptions, 'TransformationMatrix')    % save transformation matrix
    fprintf(fid,'\tTransformationMatrix %s\n', extraOptions.TransformationMatrix);
else
    fprintf(fid,'\n');
end

fprintf(fid,'}\n\n');
% reshape the matrix into a vector
bitmap = reshape(permute(bitmap,[2 1 3]),1,[])';
if showWaitbar; waitbar(.1, wb); end
% saving the data
if strcmp(format,'binary')
    fprintf(fid,'Lattice { %s Labels } @1\n\n', classText);
    fprintf(fid,'# Data section follows\n');
    fprintf(fid,'@1\n');

    %fwrite(fid, bitmap, 'uint8', 0, 'ieee-le');
    fwrite(fid, bitmap, class(bitmap), 0, 'ieee-le');
elseif strcmp(format,'ascii')
    fprintf(fid,'Lattice { %s Labels } @1\n\n', classText);
    fprintf(fid,'# Data section follows\n');
    fprintf(fid,'@1\n');
    maxVal = numel(bitmap);
    waitbarScale = round(maxVal/10);
    for ind = 1:maxVal
        if showWaitbar && mod(ind, waitbarScale)==1; waitbar(ind/maxVal, wb); end
        fprintf(fid,'%d \n',bitmap(ind));
    end
elseif strcmp(format,'binaryRLE')
    maxVal = numel(bitmap)-1;
    indexBlockStart = 1;
    lastCharacter = NaN;    % take care of the last character in the sequence
    bytesCounter = 0;
    if showWaitbar;         waitbar(.2, wb); end
        
    while indexBlockStart < maxVal
        blockOut = zeros([127 1])*NaN;   % block of data to save at once
        commulativeIndex = 0;                       % number of similar values in a row
        
        for blockCounter=1:127
            if indexBlockStart + blockCounter == maxVal
                blockOut = blockOut(1:end);
                indexBlockStart = maxVal+2;
                lastCharacter = bitmap(end);
                break;
            end
            currId = indexBlockStart+blockCounter-1;
            nextId = indexBlockStart+blockCounter; 
            if bitmap(currId) ~= bitmap(nextId)
                if commulativeIndex < minValRLE
                    blockOut(blockCounter) = bitmap(currId);
                else
                    commulativeIndex = commulativeIndex + 1;
                    indexBlockStart = nextId;
                    break;
                end
            else % bitmap(indexBlockStart+blockCounter) == bitmap(indexBlockStart+blockCounter+1)
                commulativeIndex = commulativeIndex + 1;
                if commulativeIndex < minValRLE
                    blockOut(blockCounter) = bitmap(currId);
                else
                    if commulativeIndex < blockCounter   % save not compressed block, when comression is needed
                        blockOut = blockOut(1:blockCounter-commulativeIndex);
                        indexBlockStart = nextId-commulativeIndex;
                        commulativeIndex = 0;
                        break;
                    else
                        blockOut = bitmap(indexBlockStart);
                    end
                end
            end
            if commulativeIndex == 127
                indexBlockStart = indexBlockStart + 127;
            end
        end

        if numel(blockOut) == 1 && commulativeIndex ~= 0    % use compression
            %counter = bitset(uint8(commulativeIndex), 8, 0);
            counter = uint8(commulativeIndex);
            bitmap(bytesCounter+1) = counter;
            bitmap(bytesCounter+2) = blockOut;
            bytesCounter = bytesCounter + 2;
        else % do not use compression
            counter = bitset(uint8(numel(blockOut)), 8, 1);
            bitmap(bytesCounter+1) = counter;
            bitmap(bytesCounter+2:bytesCounter+1+numel(blockOut)) = blockOut;
            %sprintf('Number: %d Values: %s', numel(blockOut), num2str(blockOut))
            bytesCounter = bytesCounter + numel(blockOut) + 1;
        end
    end
    
    % last character
    if indexBlockStart == maxVal 
        lastCharacter = bitmap(end);
    end
    if ~isnan(lastCharacter) 
        %counter = bitset(uint8(1), 8, 0);
        bitmap(bytesCounter+1) = uint8(1);
        bitmap(bytesCounter+2) = lastCharacter;
        bytesCounter = bytesCounter + 2;
    end
    fprintf(fid,'Lattice { %s Labels } @1(HxByteRLE,%d)\n\n', classText, bytesCounter);
    fprintf(fid,'# Data section follows\n');
    fprintf(fid,'@1\n');
    if showWaitbar; waitbar(.8, wb); end
    switch class(bitmap)
        case 'uint8'
            fwrite(fid, bitmap(1:bytesCounter), '*uint8', 0, 'ieee-le');
        case 'uint16'
            fwrite(fid, bitmap(1:bytesCounter), '*uint16', 0, 'ieee-le');
        case 'uint32'
            fwrite(fid, bitmap(1:bytesCounter), '*uint32', 0, 'ieee-le');
    end
end
fprintf(fid,'\n');
fclose(fid);
if showWaitbar; delete(wb); end
set(0, 'DefaulttextInterpreter', curInt); 
disp(['bitmap2amiraLabels: ' filename ' was created!']);
result = 1;
end

