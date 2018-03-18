function [result] = bfopen3(r, seriesNumber, sliceNo, options)
% A script for opening microscopy images in MATLAB using Bio-Formats.
% modified from the original bfopen.m by Ilya Belevich
% 
% The function returns selected dataset.
% [result] = bfopen3(r, seriesNumber)
% IN:
%   r - handle to a dataset opened with
%      r = loci.formats.ChannelFiller();
%      r = loci.formats.ChannelSeparator(r);
%      r = loci.formats.gui.BufferedImageReader(r);
%      r.setId(handles.filename);
%   seriesNumber - number of selected serie starting from 1
%   sliceNo - [optional] desired slice number from the series
%   options - [optional] a structure with a subset of the image to obtain.
%   Warning! not yet completely tested
%       .x1 - starting x position
%       .y1 - starting y position
%       .dx - width
%       .dy - height
% OUT:
%   result -> Structure with the selected serie
%       .img -> Image with [heigh width color z-stack] dimensions
%       .ColorType -> 'grayscale', 'truecolor', 'indexed'
%       .ColorMap -> color map for the indexed image
% Portions of this code were adapted from:
% http://www.mathworks.com/support/solutions/en/data/1-2WPAYR/
%
% This method is ~1.5x-2.5x slower than Bio-Formats's command line
% showinf tool (MATLAB 7.0.4.365 R14 SP2 vs. java 1.6.0_20),
% due to overhead from copying arrays.
%
% Thanks to all who offered suggestions and improvements:
%     * Ville Rantanen
%     * Brett Shoelson
%     * Martin Offterdinger
%     * Tony Collins
%     * Cris Luengo
%     * Arnon Lieber
%     * Jimmy Fong
%
% NB: Internet Explorer sometimes erroneously renames the Bio-Formats library
%     to loci_tools.zip. If this happens, rename it back to loci_tools.jar.
%
% 05.09.2013 Ilya Belevich, added sliceNo to load only a single slice

if nargin < 4;     options = struct;   end
if nargin < 3;     sliceNo = NaN;   end

% check MATLAB version, since typecast function requires MATLAB 7.1+
canTypecast = versionCheck(version, 7, 1);

% check Bio-Formats version, since makeDataArray2D function requires trunk
bioFormatsVersion = char(loci.formats.FormatTools.VERSION);
isBioFormatsTrunk = versionCheck(bioFormatsVersion, 5, 0);

r.setSeries(seriesNumber - 1);
if ~isfield(options, 'x1')
    Width = r.getSizeX();
    Height = r.getSizeY();
else
    Width = options.dx;
    Height = options.dy;
end
Colors = r.getSizeC();
Time = 1;

if isnan(sliceNo)
    if r.getSizeZ() == 1 && r.getSizeT() > 1
        ZStacks = r.getSizeT();
    else
        ZStacks = r.getSizeZ();
        Time = r.getSizeT();
    end
    %ZStacks = max([r.getSizeZ() r.getSizeT()]);
else
    ZStacks = 1;
end

bpp = r.getBitsPerPixel();
if bpp <= 8
    ImageClassType = 'uint8';
elseif bpp <= 16
    ImageClassType = 'uint16';
elseif bpp <= 32
    ImageClassType = 'uint32';
else
    ImageClassType = 'double';
end

result.img = zeros([Height, Width, Colors, ZStacks, Time], ImageClassType);

if ~isfield(options, 'x1')
    fprintf('Reading series #%d', seriesNumber);
end

pixelType = r.getPixelType();
bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
fp = loci.formats.FormatTools.isFloatingPoint(pixelType);
sgn = loci.formats.FormatTools.isSigned(pixelType);
bppMax = power(2, bpp * 8);
little = r.isLittleEndian();
if isnan(sliceNo)
    numImages = r.getImageCount();
    startSlice = 1;
    endSlice = r.getImageCount();
else
    numImages = Colors;
    startSlice = sliceNo*Colors-(Colors-1);
    endSlice = sliceNo*Colors;
    if endSlice > r.getImageCount()
        sprintf('bfopen3: Wrong slice number!\nCancelling!')
        return;
    end
end
colorMaps = cell(numImages);

colorID = 1;
sliceID = 1;
timeID = 1;

result.ColorType = NaN;
index = 1;
for i = startSlice:endSlice
    % different color channels loaded as a list, so thay have to be
    % assigned to the proper z-slices
    if ~isfield(options, 'x1')
        if mod(index+1, 72) == 1
            fprintf('\n    ');
        end
        if i>1;         fprintf('.');     end
    end
%     s = 1;    
%
%     plane = r.openBytes(i - 1);
%     
%     % retrieve color map data
%     if bpp == 1
%         colorMaps{s, index} = r.get8BitLookupTable()';
%     else
%         colorMaps{s, index} = r.get16BitLookupTable()';
%     end
%     warning off
%     if ~isempty(colorMaps{s, index})
%         newMap = colorMaps{s, index};
%         m = newMap < 0;
%         newMap(m) = newMap(m) + bppMax;
%         colorMaps{s, index} = newMap / (bppMax - 1);
%         if max(max(colorMaps{s, index})) > 0
%             result.ColorType = 'indexed';
%             result.ColorMap{index} = colorMaps{s, index};
%         end
%     end
%     warning on
%     
%     % convert byte array to MATLAB image
%     if isBioFormatsTrunk && (sgn || ~canTypecast)
%         % can get the data directly to a matrix
%         arr = loci.common.DataTools.makeDataArray2D(plane, ...
%             bpp, fp, little, Height);
%     else
%         % get the data as a vector, either because makeDataArray2D
%         % is not available, or we need a vector for typecast
%         arr = loci.common.DataTools.makeDataArray(plane, ...
%             bpp, fp, little);
%     end
%     
%     % Java does not have explicitly unsigned data types;
%     % hence, we must inform MATLAB when the data is unsigned
%     if ~sgn
%         if canTypecast
%             % TYPECAST requires at least MATLAB 7.1
%             % NB: arr will always be a vector here
%             switch class(arr)
%                 case 'int8'
%                     arr = typecast(arr, 'uint8');
%                 case 'int16'
%                     arr = typecast(arr, 'uint16');
%                 case 'int32'
%                     arr = typecast(arr, 'uint32');
%                 case 'int64'
%                     arr = typecast(arr, 'uint64');
%             end
%         else
%             % adjust apparent negative values to actual positive ones
%             % NB: arr might be either a vector or a matrix here
%             mask = arr < 0;
%             adjusted = arr(mask) + bppMax / 2;
%             switch class(arr)
%                 case 'int8'
%                     arr = uint8(arr);
%                     adjusted = uint8(adjusted);
%                 case 'int16'
%                     arr = uint16(arr);
%                     adjusted = uint16(adjusted);
%                 case 'int32'
%                     arr = uint32(arr);
%                     adjusted = uint32(adjusted);
%                 case 'int64'
%                     arr = uint64(arr);
%                     adjusted = uint64(adjusted);
%             end
%             adjusted = adjusted + bppMax / 2;
%             arr(mask) = adjusted;
%         end
%     end
%     
%     if isvector(arr)
%         % convert results from vector to matrix
%         shape = [Width Height];
%         arr = reshape(arr, shape)';
%     end
    if ~isfield(options, 'x1')
        arr = bfGetPlane(r, i);    
    else
        arr = bfGetPlane(r, i, options.x1, options.y1, options.dx, options.dy);
    end
    
    % save image plane and label into the list
    result.img(:, :, colorID, sliceID, timeID) = arr;
    colorID = colorID + 1;
    index = index + 1;
    
    if colorID > Colors
        colorID = 1; 
        sliceID = sliceID + 1;
    end 
    if sliceID > ZStacks
        sliceID = 1; 
        timeID = timeID + 1;
    end 
end

if isnan(result.ColorType)
    result.ColorMap = NaN;
    if Colors == 1
        result.ColorType = 'grayscale';
    else
        result.ColorType = 'truecolor';
    end
else
    msgbox('Indexed color type, Not really tested!','Warning!','warn');
end
% % extract metadata table for this series
%metadataList = r.getMetadata(); % for old bio-formats
% metadataList = r.getSeriesMetadata(); % for new bio-formats

% % save images and metadata into our master series list
% result{s, 1} = imageList;
% result{s, 2} = metadataList;
% result{s, 3} = colorMaps;
% result{s, 4} = r.getMetadataStore();
if ~isfield(options, 'x1');     fprintf('\n');  end
end


% -- Helper functions --
function [result] = versionCheck(v, maj, min)

tokens = regexp(v, '[^\d]*(\d+)[^\d]+(\d+).*', 'tokens');
majToken = tokens{1}(1);
minToken = tokens{1}(2);
major = str2num(majToken{1});
minor = str2num(minToken{1});
result = major > maj || (major == maj && minor >= min);
end