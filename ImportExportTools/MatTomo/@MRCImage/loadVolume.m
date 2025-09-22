%loadVolume     Attempt to load the complete data volume into memory
%
%   [mRCImage, vol] = loadVolume(mRCImage, debug)
%
%   mRCImage    The opened MRCImage object
%
%   vol         The complete volume
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2025 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2025/01/02 17:09:20 $
%
%  $Revision: 03a2974f77e3 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mRCImage, vol] = loadVolume(mRCImage)

% Move the file pointer to the start of the volume data
if fseek(mRCImage.fid, mRCImage.dataIndex, 'bof')
  PEETError(['Failed seeking to start of file\n  ' ferror(mRCImage.fid)]);
end

nVoxels = mRCImage.header.nX * mRCImage.header.nY * mRCImage.header.nZ;
modeStr = getModeString(mRCImage);
% Matlab doesn't currently allow half (float*2) in compiled exes. To permit
% reading mode 12 files, read as uint16 and convert to single later
if strcmp(modeStr, 'half')
  modeStr = 'uint16';
end
if strcmp(modeStr, 'int16*2') || strcmp(modeStr, 'float32*2')
  % handle reading complex volume
  modeStr = modeStr(1 : end - 2);
  precision = [modeStr '=>' modeStr];
  nEff = 2 * nVoxels;
  [temp, count] = fread(mRCImage.fid, nEff, precision);
  if count ~= nEff
    PEETError(['Could not read complete volume\n  ' ferror(mRCImage.fid)]);
  end
  mRCImage.volume = complex(temp(1:2:end-1), temp(2:2:end));
else % normal (not complex) volume
  precision = [modeStr '=>' modeStr];
  [mRCImage.volume, count] = fread(mRCImage.fid, nVoxels, precision);
  if count ~= nVoxels
    PEETError(['Could not read complete volume\n  ' ferror(mRCImage.fid)]);
  end
end

if mRCImage.header.mode == 0 && getReadBytesAsSigned(mRCImage)
  % We just read a byte volume as unsigned (which was the pre 1.8.0
  % convention), but signed bytes appear to be what was intended. Remap
  % values accordingly to preserve the correct ordering. In either case,
  % the volume will be represented internally as unsigned bytes 0..255.
  topHalf = mRCImage.volume >= 0 & mRCImage.volume <= 127;
  mRCImage.volume(topHalf) = mRCImage.volume(topHalf) + 128;
  mRCImage.volume(~topHalf) = mRCImage.volume(~topHalf) - 128;
  mRCImage = setStatisticsFromVolume(mRCImage);
end
  
mRCImage.flgVolume = 1;

if mRCImage.header.mode == 12
  % Have read float*2 as uint16. Convert to single (float*4).
  mRCImage.volume = asIEEEHalf(mRCImage.volume);
end
mRCImage.volume = reshape(mRCImage.volume,                             ...
                          mRCImage.header.nX,                          ...
                          mRCImage.header.nY,                          ...
                          mRCImage.header.nZ);

if nargout > 1
  vol = mRCImage.volume;
end
                        