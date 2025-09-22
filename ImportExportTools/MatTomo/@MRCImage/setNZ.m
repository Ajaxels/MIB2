%setNZ          Resize the data by changing the number of sections (z planes)
%
%   mRCImage = setNZ(mRCImage, nZ)
%
%   mRCImage    The MRCImage object
%
%   nZ          The number of sections (z planes)
%
%   setNZ will set the number of sections (z planes) in the MRCImage object by
%   either truncating or expanding the data volume (or file, if the volume is
%   not loaded).  The nZ header value will also be correctly set.
%
%   Calls: relies on the external command truncate.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mRCImage = setNZ(mRCImage, nZ)

if mRCImage.flgVolume
  % In memory
  if nZ < mRCImage.header.mZ
    % Truncate
    mRCImage.volume = mRCImage.volume(:,:,1:nZ);
  else
    % Zero pad - retains type of existing volume
    mRCImage.volume = cat(3, mRCImage.volume, zeros(mRCImage.header.mX, ...
      mRCImage.header.mY, nZ - mRCImage.header.mZ));
  end
  mRCImage.header.nZ = nZ;
else 
  % Not in memory
  % Calculate the total header size in bytes
  nHeaderBytes = 1024 + mRCImage.header.nBytesExtended;
  
  % Calculate the size of each section
  nBytesPerImage =  mRCImage.header.nX * mRCImage.header.nY *          ...
      getModeBytes(mRCImage);
  nFileBytes = nHeaderBytes + nZ * nBytesPerImage;
  truncateCmd = ['truncate -s  ' int2str(nFileBytes) ' ' mRCImage.filename];
  [status, result] = system(truncateCmd);
  disp(truncateCmd)
  if status
    PEETError(result);
  end
  
  % Adjust the header and write it out to disk
  mRCImage.header.nZ = nZ;
  mRCImage = writeHeader(mRCImage);
end

