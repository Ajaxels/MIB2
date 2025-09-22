%getPixelSize   Get the pixel size of the MRCImage
%
%   function [szX, szY, szZ] = getPixelSize(mRCImage)
%
%   mRCImage          The MRCImage object
%
%   [szX, szY, szZ]   Pixel sizes in Angstroms
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

function [szX, szY, szZ] = getPixelSize(mRCImage)

szX = mRCImage.header.cellDimensionX / mRCImage.header.mX;
szY = mRCImage.header.cellDimensionY / mRCImage.header.mY;
szZ = mRCImage.header.cellDimensionZ / mRCImage.header.mZ;
