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

function [result, options] = mibImage2ometiff(filename, imageS, options)
% function [result, options] = mibImage2ometiff(filename, imageS, options)
% Save image in OME.TIF format, 2D slices or 5D stacks
%
% Parameters:
% filename: filename for the output file
% imageS: dataset to save [1:height, 1:width, 1:color_channels, 1:no_stacks, 1:time] or [1:height, 1:width, 1:no_stacks, 1:time]
% options: a structure with optional parameters
%  .pixSize - a MIB structure with pixel size (.x, .y, .z, .t, .units, .tunints)
%  .lutColors - a matrix with LUT colors
%  .ImageDescription - a cell string with description of the dataset
%  .DatasetType - a string with type of the dataset ('image' or 'model')
%  .Saving3d: ''5D'' - save all stacks into a single file
%              ''2D'' - generate a sequence of files
%              @em NaN -> type will be asked
%  .overwrite, if @b 1 do not check whether file with provided filename already exists
%  .Compression: ''none'', ''lzw'', ''packbits''
%  .showWaitbar: show a progress bar, @b 1 - on, @b 0 - off
%  .SliceName -  [@em optional] a cell array with filenames without path
%  .DimensionOrder - order of dimensions in the dataset, default = 'XYCZT';  
%
% Return values:
% result: result of the function: @b 1 - success, @b 0 - fail
% options: structure with used options

% use SCIFIO to open ome-tiff in Fiji
% https://imagej.net/SCIFIO

% Updates
% 

% example:
%   mibImage2ometiff(file_name, image_var, options);

result = 0;
if nargin < 3; options = struct(); end
if nargin < 2; msgbox('Please provide filename and image!', 'Error!', 'error', 'modal'); return; end

if ~isfield(options, 'pixSize')
    options.pixSize = struct();
    options.pixSize.x = 1;
    options.pixSize.y = 1;
    options.pixSize.z = 1;
    options.pixSize.t = 1;
    options.pixSize.units = 'um';
    options.pixSize.tnits = 's';
end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end
if ~isfield(options, 'ImageDescription'); options.ImageDescription = {''}; end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'DatasetType'); options.DatasetType = 'image'; end
if ~isfield(options, 'Saving3d'); options.Saving3d = '5D'; end
if ~isfield(options, 'Compression'); options.Compression = 'none'; end
if ~isfield(options, 'DimensionOrder'); options.DimensionOrder = 'XYZCT'; end

% define time units for the output
switch options.pixSize.tunits
    case {'sec', 's'}
        tunits = ome.units.UNITS.SECOND;
    case {'min', 'm'}
        tunits = ome.units.UNITS.MINUTE;
    case {'hour', 'h'}
        tunits = ome.units.UNITS.HOUR;
end

if options.overwrite == 0
    if exist(filename, 'file') == 2
        reply = questdlg(sprintf('!!! Warning !!!\n\n The file alreadt exists! Overwrite?'),'Overwrite', 'Overwrite', 'Cancel', 'Cancel');
        if strcmp(reply, 'Cancel'); return; end
    end
end
curInt = get(0, 'DefaulttextInterpreter'); 
set(0, 'DefaulttextInterpreter', 'none'); 

files_no = size(imageS, 4);
if options.showWaitbar
    wb = waitbar(0, sprintf('%s\nPlease wait...',filename), 'Name', 'Saving images', 'WindowStyle', 'modal');
    set(findall(wb,'type','text'), 'Interpreter', 'none');
    waitbar(0, wb);
end

% scale pixel size to um
switch options.pixSize.units
    case 'm'
        scaleFactor = 1e6;
    case 'cm'
        scaleFactor = 1e4;
    case 'mm'
        scaleFactor = 1e3;
    case 'um'
        scaleFactor = 1;
    case 'nm'
        scaleFactor = .001;
end
options.pixSize.x = options.pixSize.x * scaleFactor;
options.pixSize.y = options.pixSize.y * scaleFactor;
options.pixSize.z = options.pixSize.z * scaleFactor;

if strcmp(options.Saving3d, '5D')
    % permute image from y,x,c,z,t to y,x,z,c,t
    % imageS = permute(imageS, [1 2 4 3 5]);
    
    metadata = createMinimalOMEXMLMetadata(imageS, options.DimensionOrder);
    pixelSize = ome.units.quantity.Length(java.lang.Double(options.pixSize.x), ome.units.UNITS.MICROMETER);
    metadata.setPixelsPhysicalSizeX(pixelSize, 0);
    pixelSize = ome.units.quantity.Length(java.lang.Double(options.pixSize.y), ome.units.UNITS.MICROMETER);
    metadata.setPixelsPhysicalSizeY(pixelSize, 0);
    pixelSize = ome.units.quantity.Length(java.lang.Double(options.pixSize.z), ome.units.UNITS.MICROMETER);
    metadata.setPixelsPhysicalSizeZ(pixelSize, 0);
    pixelSize = ome.units.quantity.Time(java.lang.Double(options.pixSize.t), tunits);
    metadata.setPixelsTimeIncrement(pixelSize, 0);
    
    % delete old file
    if exist(filename, 'file') == 2; delete(filename); end

    if strcmp(options.Compression, 'none')
        bfsave(imageS, filename, 'metadata', metadata);        
    else
        bfsave(imageS, filename, 'metadata', metadata, 'Compression', options.Compression);
    end
    
%     imwrite(squeeze(imageS(:,:,:,1)),filename,'tif','WriteMode','overwrite','Description',cell2mat(ImageDescription(1)),'Resolution',options.Resolution,'Compression',options.Compression);
%     for num = 2:files_no
%             imwrite(squeeze(imageS(:,:,:,num)),filename,'tif','WriteMode','append','Description',cell2mat(ImageDescription(num)),'Resolution',options.Resolution,'Compression',options.Compression);
%             if options.showWaitbar; waitbar(num/files_no,wb); end
%         end
    options.SliceName{1} = filename;
elseif strcmp(options.Saving3d, '2D')
    sequentialFn = 1;
    if isfield(options, 'SliceName') && numel(options.SliceName) > 1
        choice = questdlg('Would you like to use original or sequential filenaming?','Save as TIF...','Original','Sequential','Cancel','Sequential');
        switch choice
            case 'Cancel'
                disp('Cancelled!')
                if options.showWaitbar; delete(wb); end
                return;
            case 'Original'
                sequentialFn = 0;
            case 'Sequential'
                sequentialFn = 1;
        end
    end
    
    [pathstr, name] = fileparts(filename);
    if sequentialFn     % generate sequential filenames
        for i = 1:files_no
            options.SliceName{i} = fullfile(pathstr, generateSequentialFilename(name, i, files_no));
        end
    else                % use original filenames
        % remove existing extension
        for i=1:numel(options.SliceName)
            [~, options.SliceName{i}] = fileparts(options.SliceName{i});
        end
        
        % find duplicates in the filenames
        %for i=1:numel(options.SliceName)
        i=1;
        while i <= numel(options.SliceName)
            duplicatesNo = sum(cell2mat((strfind(options.SliceName(:), options.SliceName{i}))));
            if duplicatesNo > 1   % unique filename is found
                for j=i:i+duplicatesNo-1
                    options.SliceName{j} = generateSequentialFilename(options.SliceName{j}, j-i+1, duplicatesNo);
                end
                i = i + duplicatesNo;
            else
                options.SliceName{i} = [options.SliceName{i} '.tif'];
                i = i + 1;
            end
        end
        
        % generate full path
        for i=1:files_no
            options.SliceName{i} = fullfile(pathstr, options.SliceName{i});
        end
    end
    
    
    for num = 1:files_no
        if isnan(options.cmap)  % grayscale or rgb image
            imwrite(imageS(:,:,:,num),options.SliceName{num},'tif','Compression',options.Compression,'Description',cell2mat(ImageDescription(num)),'Resolution',options.Resolution);
        else            % indexed image
            imwrite(imageS(:,:,:,num),options.cmap,options.SliceName{num},'tif','Compression',options.Compression,'Description',cell2mat(ImageDescription(num)),'Resolution',options.Resolution);
        end
        if options.showWaitbar; waitbar(num/files_no,wb); end
    end
else
    error('Error: wrong saving type, use ''5D'' or ''2D''');
end

if options.showWaitbar; waitbar(1); end
disp(['image2tiff: ' options.SliceName{1} ' was/were created!']);
if options.showWaitbar; delete(wb); end
set(0, 'DefaulttextInterpreter', curInt); 
result = 1;
end

% supporting function to generate sequential filenames
function fn = generateSequentialFilename(name, num, files_no)
% name - a filename template
% num - sequential number to generate
% files_no - total number of files in sequence
if files_no == 1
    fn = [name '.ome.tiff'];
elseif files_no < 100
    fn = [name '_' sprintf('%02i',num) '.ome.tiff'];
elseif files_no < 1000
    fn = [name '_' sprintf('%03i',num) '.ome.tiff'];
elseif files_no < 10000
    fn = [name '_' sprintf('%04i',num) '.ome.tiff'];
elseif files_no < 100000
    fn = [name '_' sprintf('%05i',num) '.ome.tiff'];
elseif files_no < 1000000
    fn = [name '_' sprintf('%06i',num) '.ome.tiff'];
elseif files_no < 10000000
    fn = [name '_' sprintf('%07i',num) '.ome.tiff'];    
end
end