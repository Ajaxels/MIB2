%setPixelSize   Set the pixel size of the MRCImage
%
%   mRCImage = setPixelSize(mRCImage, szX, szY, szZ)
%   mRCImage = setPixelSize(mRCImage, [szX, szY, szZ])
%
%   mRCImage    The MRCImage object
%
%   szX, szY, szZ   The pixel (voxel) sizes in angstroms
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

function mRCImage = setPixelSize(mRCImage, szX, szY, szZ)

% Allow passing sizes as a single vector instead of 3 separate values
if nargin == 2 && length(szX) == 3
  szZ = szX(3);
  szY = szX(2);
  szX = szX(1);
end

mRCImage.header.cellDimensionX = mRCImage.header.mX * szX;
mRCImage.header.cellDimensionY = mRCImage.header.mY * szY;
mRCImage.header.cellDimensionZ = mRCImage.header.mZ * szZ;
