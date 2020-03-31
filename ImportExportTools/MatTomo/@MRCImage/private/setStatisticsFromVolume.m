% mRCImage = setStatisticsFromVolume(mRCImage)
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

function mRCImage = setStatisticsFromVolume(mRCImage)

% Calculation of mean must be done in double-precision to avoid bad
% roundoff errors for large volumes
dVol = double(mRCImage.volume);

% Use magnitudes for complex volumes
if ~isreal(mRCImage.volume)
  dVol = abs(dVol);
end

mRCImage.header.minDensity = min(dVol(:));
mRCImage.header.maxDensity = max(dVol(:));
mRCImage.header.meanDensity = mean(dVol(:));
mRCImage.header.densityRMS =                                         ...
  sqrt(mean((dVol(:) - mRCImage.header.meanDensity).^2));
