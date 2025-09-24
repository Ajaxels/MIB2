% getVolume      Extract a volume from the MRC image
%
%   vol = getVolume(mRCImage, iRange, jRange, kRange)
%
%   vol         The extracted volume
%
%   mRCImage    The opened MRCImage object
%
%   iRange      The indices of the i (x, first, columns) dimension to be
%               extracted as [iMin iMax], an empty array specifies all.
%
%   jRange      The indices of the j (y, second, rows) dimension to be
%               extracted as [jMin jMax], an empty array specifies all.
%
%   kRange      The indices of the k (z, third, planes) dimension to be
%               extracted as [kMin kMax], an empty array specifies all.
%
%   MRCImage.getVolume extracts a three dimensional region from an MRCImage
%   object.
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

function vol = getVolume(mRCImage, iRange, jRange, kRange)

nX = mRCImage.header.nX;
nY = mRCImage.header.nY;
nZ = mRCImage.header.nZ;

if nargin < 2 || isempty(iRange)
  iIndex = 1:nX;
else
  if length(iRange) == 1
    iIndex = iRange;
  else
    iIndex = iRange(1):iRange(2);
  end
  if iIndex(1) < 1 || iIndex(end) > nX
    PEETError('Image x index out of range!');
  end
end

if nargin < 3 || isempty(jRange)
  jIndex = 1:nY;
else
  if length(jRange) == 1
    jIndex = jRange;
  else
    jIndex = jRange(1):jRange(2);
  end
  if jIndex(1) < 1 || jIndex(end) > nY
    PEETError('Image y index out of range!');
  end
end

if nargin < 4 || isempty(kRange)
  kIndex = 1:nZ;
else
  if length(kRange) == 1
    kIndex = kRange;
  else
    kIndex = kRange(1):kRange(2);
  end
  if kIndex(1) < 1 || kIndex(end) > nZ
    PEETError('Image z index out of range!');
  end
end

fullVol = length(iIndex) == nX && length(jIndex) == nY &&              ...
           length(kIndex) == nZ;
          
% If the volume is already loaded, just return the selected indices.
% If the volume is not loaded, but the entire volume is requested, call
% loadVolume; this is faster and will cache the result.
if mRCImage.flgVolume
  % The following really should be equivalent, but the 1st form is
  % currently faster, probably because MATLAB's delayed copy logic doesn't
  % recognize the 2nd as a copy of the full array.
  if fullVol
    vol = mRCImage.volume;
  else
    vol = mRCImage.volume(iIndex, jIndex, kIndex);
  end
  return
elseif fullVol
  [~, vol] = loadVolume(mRCImage);
  return 
end

modeStr = getModeString(mRCImage);

%  Allocate the output matrix
if strcmp(modeStr, 'int16*2') || strcmp(modeStr, 'float32*2')
  flgComplex = true;
  modeStr = modeStr(1 : end - 2);
else
  flgComplex = false;
end 
if strcmp(modeStr, 'float32')
  matlabModeStr = 'single';
else
  matlabModeStr = modeStr;
end
cFactor = 1 + flgComplex;   % 1 for real, 2 for complex
volSize = [cFactor * length(iIndex), length(jIndex), length(kIndex)];
vol = zeros(volSize, matlabModeStr);

% Walk through the sections reading XY subimages. This was suggested by
% Benjamin Himes, and is much faster than the previous by-column method.
nXElements = length(iIndex);
nRealXElements = cFactor * nXElements;
nYElements = length(jIndex);
nZElements = length(kIndex);
nRealXYElements = [nRealXElements, nYElements];
nExpected = nRealXElements * nYElements;
nModeBytes = getModeBytes(mRCImage);   % Already includes 2X for complex!
nXYModeBytes = nX * nY * nModeBytes;
precision = [int2str(nRealXElements) '*' modeStr '=>' modeStr];
skipPerCol = (nX - nXElements) * nModeBytes;
mode =  mRCImage.header.mode;
readBytesAsSigned = getReadBytesAsSigned(mRCImage);

outputSlice = 1;
idxDataStart = mRCImage.dataIndex + (kIndex(1) - 1) * nXYModeBytes +   ...
  ((jIndex(1) - 1) * nX + iIndex(1) - 1) * nModeBytes;
for k = kIndex
  if k < 1 || k > nZ
    PEETError('Image slice index out of range');
  end
    
  fseek(mRCImage.fid, idxDataStart, 'bof');
  % Read the XY data from this section from the MRC file
  [img, count] = fread(mRCImage.fid, nRealXYElements, precision, skipPerCol);
  if count ~= nExpected
    PEETError(['Expected ' int2str(nXYElements) ' elements, '          ...
          'read ' int2str(count) '!']);
  end
  vol(:, :, outputSlice) = img;
  outputSlice = outputSlice + 1;
  idxDataStart = idxDataStart + nXYModeBytes;
end
    
if mode == 0 && readBytesAsSigned
  % We just read a byte image as unsigned (which was the pre 1.8.0
  % convention), but signed bytes appear to be what was intended. Remap
  % values accordingly to preserve the correct ordering. In each case,
  % img will be represented internally as unsigned bytes 0..255.
  topHalf = (vol >= 0) & (vol < 127);
  vol(topHalf) = vol(topHalf) + 128;
  vol(~topHalf) = vol(~topHalf) - 128;
end
  
if flgComplex
  vol = complex(reshape(vol(1:2:(end-1), :, :), nXElements, nYElements,...
                        nZElements),                                   ...
                reshape(vol(2:2:end, :, :), nXElements, nYElements,    ...
                        nZElements));
end
