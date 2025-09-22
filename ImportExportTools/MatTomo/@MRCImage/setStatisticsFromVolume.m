% mRCImage = setStatisticsFromVolume(mRCImage)
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
