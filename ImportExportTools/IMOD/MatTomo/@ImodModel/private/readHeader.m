%readHeader     Read in the header of the ImodModel
%
%   imodModel = readHeader(imodModel, debug)
%
%   imodModel   The ImodModel object
%
%   debug       OPTIONAL: Print out debugging info (default: 0)
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2020/01/02 23:33:44 $
%
%  $Revision: ce44cef00aca $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imodModel = readHeader(imodModel, debug)

if nargin < 2
  debug = 0;
end
debugFD = 2;

if debug
  fprintf(debugFD, 'Reading ID tag and parsing version nubmer\n');
end

%JMH 11/9/11: If you do as Matlab suggests and change the following freads
%to *uchar and remove the cast, the header is read incorrectly.
tag = char(fread(imodModel.fid, [1 8], 'uchar')); %#ok<FREAD>
if ~ strncmp(tag, 'IMOD', 4)
  imodModel = close(imodModel);
  PEETError('This is not an imod model file!');
end
imodModel.name = char(fread(imodModel.fid, [1 128], 'uchar')); %#ok<FREAD>
% Find the zero terminator for the name
terms = find(imodModel.name == 0);
if ~ isempty(terms)
  nChar = terms(1);
  imodModel.name  = imodModel.name(1:nChar-1);
end
if debug
  disp(imodModel.name);
end

imodModel.xMax = fread(imodModel.fid, 1, 'int32');
imodModel.yMax = fread(imodModel.fid, 1, 'int32');
imodModel.zMax = fread(imodModel.fid, 1, 'int32');
imodModel.nObjects = fread(imodModel.fid, 1, 'int32');
imodModel.flags = fread(imodModel.fid, 1, 'int32');
imodModel.drawMode = fread(imodModel.fid, 1, 'int32');
imodModel.mouseMode = fread(imodModel.fid, 1, 'int32');
imodModel.blackLevel = fread(imodModel.fid, 1, 'int32');
imodModel.whiteLevel = fread(imodModel.fid, 1, 'int32');
imodModel.xOffset = fread(imodModel.fid, 1, 'float32');
imodModel.yOffset = fread(imodModel.fid, 1, 'float32');
imodModel.zOffset = fread(imodModel.fid, 1, 'float32');
imodModel.xScale = fread(imodModel.fid, 1, 'float32');
imodModel.yScale = fread(imodModel.fid, 1, 'float32');
imodModel.zScale = fread(imodModel.fid, 1, 'float32');
imodModel.object = fread(imodModel.fid, 1, 'int32');
imodModel.contour = fread(imodModel.fid, 1, 'int32');
imodModel.point = fread(imodModel.fid, 1, 'int32');
imodModel.res = fread(imodModel.fid, 1, 'int32');
imodModel.thresh = fread(imodModel.fid, 1, 'int32');
imodModel.pixelSize = fread(imodModel.fid, 1, 'float32');
imodModel.units = fread(imodModel.fid, 1, 'int32');
imodModel.csum = fread(imodModel.fid, 1, 'int32');
imodModel.alpha = fread(imodModel.fid, 1, 'int32');
imodModel.beta = fread(imodModel.fid, 1, 'int32');
imodModel.gamma = fread(imodModel.fid, 1, 'int32');

if debug
  fprintf('x max: %d\n', imodModel.xMax);
  fprintf('y max: %d\n', imodModel.yMax);
  fprintf('z max: %d\n', imodModel.zMax);
  fprintf('# objects: %d\n', imodModel.nObjects);
  fprintf('flags: 0x%08X\n', imodModel.flags);
  fprintf('draw mode: %d\n', imodModel.drawMode);
end

% FIXME need to add the ability to read global data chunks
[buffer, nRead] = fread(imodModel.fid, [1 4], 'uchar');
iObj = 0;
while nRead > 0
  tag = char(buffer);
  if debug
    fprintf('TAG: %s\n', tag);
  end
  if strcmp(tag, 'OBJT')
    fseek(imodModel.fid, -4, 'cof');
    iObj = iObj + 1;    
    imodModel.Objects{iObj} = ImodObject;
    imodModel.Objects{iObj} = freadObject(imodModel.Objects{iObj}, imodModel.fid, debug);
    
  elseif strcmp(tag, 'IMAT')
    fseek(imodModel.fid, -4, 'cof');
    imodModel.Objects{iObj}=freadObjectMat(imodModel.Objects{iObj}, imodModel.fid, debug);
    
  elseif strcmp(tag, 'MINX')
    length = fread(imodModel.fid, 1, 'int32');
    [imodModel.MINX, nRead] = fread(imodModel.fid, 18, 'float32');
    if length ~= 72 || nRead ~= 18
      PEETError('Error reading MINX chunk!');
    end
    
  elseif strcmp(tag, 'IEOF')
    break;
  elseif strcmp(tag, 'VIEW')
      break;
  else
    fseek(imodModel.fid, -4, 'cof');
    imodChunk = ImodChunk;
    imodChunk = freadChunk(imodChunk, imodModel.fid); %#ok<NASGU>
    %imodObject.chunk{iChunk} = imodChunk;
    %iChunk = iChunk + 1;
    %PEETWarning(['Ignoring unknown object type: ' tag]);
    %break;
  end
  [buffer, nRead] = fread(imodModel.fid, [1 4], 'uchar');
end
imodModel = close(imodModel);
