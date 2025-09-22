% disp    Default display routine for MRCImages
%
%   disp(mRCImage)
%
%   mRCImage    The MRCImage object.
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2025 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2025/01/02 17:09:20 $
%
%  $Revision: 03a2974f77e3 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function disp(mRCImage)
  if mRCImage.header.mode == -inf
    fprintf('Uninitialized MRCImage\n');
  else
    if mRCImage.header.mZ == mRCImage.header.nZ
      fprintf('MRCImage with %s volume of size [%d, %d, %d]\n',         ...
        getModeString(mRCImage), mRCImage.header.mX, mRCImage.header.mY,...
        mRCImage.header.mZ);
    elseif mRCImage.header.mZ == 1
      fprintf('MRCImage with %d slices of size %dx%d\n',                ...
        mRCImage.header.nZ, mRCImage.header.mX, mRCImage.header.mY);
    else
      n = mRCImage.header.nZ / mRCImage.header.mZ;
      if n == round(n)
        fprintf('MRCImage stack of %d subvolumes of size %dx%dx%d\n',   ...
          n, mRCImage.header.mX, mRCImage.header.mY, mRCImage.header.mZ)
      else
        fprintf('MRCImage stack of %.1f? subvolumes of size %dx%dx%d\n',...
          n, mRCImage.header.mX, mRCImage.header.mY, mRCImage.header.mZ)
      end
    end
  end
end
