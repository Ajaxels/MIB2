%normalize      Normalize each projection to unity integrated density
%
%   mRCImage = normalize(mRCImage)
%
%   mRCImage    The MRCImage object.
%
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

function mRCImage = normalize(mRCImage)

%  Load the volume if it is not already loaded
if ~ mRCImage.flgVolume
  mRCImage = loadVolume(mRCImage);
end


% Normalize each projection to unity integral

for iProj = 1:mRCImage.header.nZ
  totalSum = sum(sum(mRCImage.volume(:, :, iProj)));
  mRCImage.volume(:, :, iProj) = mRCImage.volume(:, :, iProj) ./ totalSum;
end

