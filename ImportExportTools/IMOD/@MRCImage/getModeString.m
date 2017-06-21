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
% Copyright 2000-2012 The Regents of the University of Colorado & BLD3EMC:
%           The Boulder Laboratory For 3D Electron Microscopy of Cells.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2012/01/12 17:22:51 $
%
%  $Revision: 04b6cb6df697 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 22.09.2014, Ilya Belevich ilya.belevich @ helsinki.fi Added uint16 class,


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
 case 6
  modeString = 'uint16'; % used for uint16
 otherwise
  modeString = 'unknown';
end
