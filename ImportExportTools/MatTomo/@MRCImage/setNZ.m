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
% Copyright 2000-2012 The Regents of the University of Colorado & BLD3EMC:
%           The Boulder Laboratory For 3D Electron Microscopy of Cells.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2012/01/12 17:22:51 $
%
%  $Revision: 04b6cb6df697 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mRCImage = setNZ(mRCImage, nZ)

if mRCImage.flgVolume
  mRCImage.volume = mRCImage.volume(:,:,1:nZ);
  mRCImage.header.nZ = nZ;
else
  % Calculate the total header size in bytes
  nHeaderBytes = 1024 + mRCImage.header.nBytesExtended;
  
  % Calculate the size of each section
  nBytesPerImage =  mRCImage.header.nX * mRCImage.header.nY * ...
      getModeBytes(mRCImage);
  nFileBytes = nHeaderBytes + nZ * nBytesPerImage;

  truncateCmd = ['truncate ' mRCImage.filename ' ' int2str(nFileBytes) ];
  [status result] = system(truncateCmd);
  disp(truncateCmd)
  if status
    PEETError(result);
  end
  
  % Adjust the header and write it out to disk
  mRCImage.header.nZ = nZ;
  mRCImage = writeHeader(mRCImage);
end

