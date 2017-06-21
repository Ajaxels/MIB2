% mRCImage = setStatisticsFromVolume(mRCImage)
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2012 The Regents of the University of Colorado & BLD3EMC:
%           The Boulder Laboratory For 3D Electron Microscopy of Cells.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2012/06/26 17:04:12 $
%
%  $Revision: 8ebca3b313c1 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mRCImage = setStatisticsFromVolume(mRCImage)
if isreal(mRCImage.volume)
  mRCImage.header.minDensity = double(min(mRCImage.volume(:)));
  mRCImage.header.maxDensity = double(max(mRCImage.volume(:)));
  temp = double(mean(mRCImage.volume(:)));
  mRCImage.header.meanDensity = temp;
  mRCImage.header.densityRMS =                                         ...
    sqrt(mean((double(mRCImage.volume(:)) - temp).^2));
else % Use magnitudes for complex values
  temp = (abs(double(mRCImage.volume)));
  mRCImage.header.minDensity = min(temp(:));
  mRCImage.header.maxDensity = max(temp(:));
  mRCImage.header.meanDensity = mean(temp(:));
  mRCImage.header.densityRMS =                                         ...
    sqrt(mean((mRCImage.volume(:) - mRCImage.header.meanDensity).^2));
end
