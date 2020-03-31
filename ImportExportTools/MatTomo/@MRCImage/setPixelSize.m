%setPixelSize   Set the pixel size of the MRCImage
%
%   mRCImage = setPixelSize(mRCImage, szX, szY, szZ)
%
%   mRCImage    The MRCImage object
%
%   szX, szY, szZ   The effective pixels sizes in angstroms
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

function mRCImage = setPixelSize(mRCImage, x, y, z)

mRCImage.header.cellDimensionX = mRCImage.header.mX * x;
mRCImage.header.cellDimensionY = mRCImage.header.mY * y;
mRCImage.header.cellDimensionZ = mRCImage.header.mZ * z;
