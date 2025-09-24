%getModeString  Return the correct string for the specified mode (data type)
%
%   modeString = getModeString(mRCImage)
%
%   modeString  A string describing the data type stored on the MRCIMage:
%               'uint8', 'int16', 'float32'
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

function modeString = getModeString(mRCImage)

switch  mRCImage.header.mode
  case 0
    modeString = 'uint8';
  case 1
    modeString = 'int16';
  case 2
    modeString = 'float32';
  case 3
    modeString = 'int16*2';   % used for complex short ints
  case 4
    modeString = 'float32*2'; % used for complex floating point
  otherwise
    PEETError('Unsupported MRCImage mode %d!', mRCImage.header.mode);
end
