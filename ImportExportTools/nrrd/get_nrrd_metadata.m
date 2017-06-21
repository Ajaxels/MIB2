function [meta, datatype] = get_nrrd_metadata(filename)
% function [meta, datatype] = get_nrrd_metadata(filename)
% Get metadata for a NRRD dataset
%
%   See the format specification online:
%   http://teem.sourceforge.net/nrrd/format.html
%
% Parameters:
% filename: filename for NRRD file
%
% Return values:
% meta: a stucture with meta data
% - meta.type:      a string with data type, 'unsigned char'
% - meta.dimension: a string with number of dimensions, '3'
% - meta.space:     a string that describe the orientation of the raster grid relative to some surrounding "space", 'left-posterior-superior'
% - meta.sizes:     a string with width x height x thickness information, '521 372 75'
% - meta.spacedirections:   a string that encode a matrix 3x3 with voxel sizes, '(12.999999999999998,0,0) (0,12.999999999999998,0) (0,0,30)' 
% - meta.kinds:     a string with kinds, 'domain domain domain' 
% - meta.encoding:  a string with encoding, 'raw', 'gzip'
% - meta.spaceorigin:   a string with a shift of the bounding box, '(0,0,0)'
% datatype: a string with a datatype, 'uint8', 'uint16'

% modification of nrrdread written by Jeff Mather 
% http://www.mathworks.com/matlabcentral/fileexchange/34653-nrrd-format-file-reader/content/nrrdread.m
% 
% Modified by Ilya Belevich
% http://www.biocenter.helsinki.fi/~ibelev
% ver 1.00 - 19.02.2014

% Open file.
fid = fopen(filename, 'rb');
assert(fid > 0, 'Could not open file.');
cleaner = onCleanup(@() fclose(fid));

% Magic line.
theLine = fgetl(fid);
assert(numel(theLine) >= 4, 'Bad signature in file.')
assert(isequal(theLine(1:4), 'NRRD'), 'Bad signature in file.')

% The general format of a NRRD file (with attached header) is:
% 
%     NRRD000X
%     <field>: <desc>
%     <field>: <desc>
%     # <comment>
%     ...
%     <field>: <desc>
%     <key>:=<value>
%     <key>:=<value>
%     <key>:=<value>
%     # <comment>
% 
%     <data><data><data><data><data><data>...

meta = struct([]);

% Parse the file a line at a time.
while (true)

  theLine = fgetl(fid);
  
  if (isempty(theLine) || feof(fid))
    % End of the header.
    break;
  end
  
  if (isequal(theLine(1), '#'))
      % Comment line.
      continue;
  end
  
  % "fieldname:= value" or "fieldname: value" or "fieldname:value"
  parsedLine = regexp(theLine, ':=?\s*', 'split','once');
  
  assert(numel(parsedLine) == 2, 'Parsing error')
  
  field = lower(parsedLine{1});
  value = parsedLine{2};
  
  field(isspace(field)) = '';
  meta(1).(field) = value;
  
end

datatype = getDatatype(meta.type);

% Get the size of the data.
assert(isfield(meta, 'sizes') && ...
       isfield(meta, 'dimension') && ...
       isfield(meta, 'encoding'), ...
       'Missing required metadata fields.')

dims = sscanf(meta.sizes, '%d');
ndims = sscanf(meta.dimension, '%d');
assert(numel(dims) == ndims);

%data = readData(fid, meta, datatype);

%if isfield(meta, 'endian')
%    data = adjustEndian(data, meta);
%end

% Reshape and get into MATLAB's order.
%X = reshape(data, dims');
%X = permute(X, [2 1 3]);


function datatype = getDatatype(metaType)

% Determine the datatype
switch (metaType)
 case {'signed char', 'int8', 'int8_t'}
  datatype = 'int8';
  
 case {'uchar', 'unsigned char', 'uint8', 'uint8_t'}
  datatype = 'uint8';

 case {'short', 'short int', 'signed short', 'signed short int', ...
       'int16', 'int16_t'}
  datatype = 'int16';
  
 case {'ushort', 'unsigned short', 'unsigned short int', 'uint16', ...
       'uint16_t'}
  datatype = 'uint16';
  
 case {'int', 'signed int', 'int32', 'int32_t'}
  datatype = 'int32';
  
 case {'uint', 'unsigned int', 'uint32', 'uint32_t'}
  datatype = 'uint32';
  
 case {'longlong', 'long long', 'long long int', 'signed long long', ...
       'signed long long int', 'int64', 'int64_t'}
  datatype = 'int64';
  
 case {'ulonglong', 'unsigned long long', 'unsigned long long int', ...
       'uint64', 'uint64_t'}
  datatype = 'uint64';
  
 case {'float'}
  datatype = 'single';
  
 case {'double'}
  datatype = 'double';
  
 otherwise
  assert(false, 'Unknown datatype')
end



function data = readData(fidIn, meta, datatype)

switch (meta.encoding)
 case {'raw'}
  
  data = fread(fidIn, inf, [datatype '=>' datatype]);
  
 case {'gzip', 'gz'}

  tmpBase = tempname();
  tmpFile = [tmpBase '.gz'];
  fidTmp = fopen(tmpFile, 'wb');
  assert(fidTmp > 3, 'Could not open temporary file for GZIP decompression')
  
  tmp = fread(fidIn, inf, 'uint8=>uint8');
  fwrite(fidTmp, tmp, 'uint8');
  fclose(fidTmp);
  
  gunzip(tmpFile)
  
  fidTmp = fopen(tmpBase, 'rb');
  cleaner = onCleanup(@() fclose(fidTmp));
  
  meta.encoding = 'raw';
  data = readData(fidTmp, meta, datatype);
  
 case {'txt', 'text', 'ascii'}
  
  data = fscanf(fidIn, '%f');
  data = cast(data, datatype);
  
 otherwise
  assert(false, 'Unsupported encoding')
end

function data = adjustEndian(data, meta)

[~,~,endian] = computer();

needToSwap = (isequal(endian, 'B') && isequal(lower(meta.endian), 'little')) || ...
             (isequal(endian, 'L') && isequal(lower(meta.endian), 'big'));
         
if (needToSwap)
    data = swapbytes(data);
end