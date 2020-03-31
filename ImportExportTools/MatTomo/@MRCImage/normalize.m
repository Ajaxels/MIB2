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

