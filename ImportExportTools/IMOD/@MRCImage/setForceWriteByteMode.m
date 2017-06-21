function mRCImage = setForceWriteByteMode(mRCImage, mode)

% setForceWriteByteMode  Override writing of mode 0 (byte)files
%
%   mode: [] => no forcing, 0 => write as unsigned, 1 => write as signed
%
%   As of 1.8.0, PEET follows new IMOD conventions and can store byte files
%   (mode 0) as signed. This behavior can be modifed by envronment variable
%   WRITE_MODE0_SIGNED. See "man imodenv" for details. Here, we provide a 
%   local way to force writing as unsigned. Behavior set here takes
%   precedence over the environment variables. Note that PEET's internal
%   representation will always be as unsigned (0..255).
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

if ~isempty(mode) && mode ~= 0 && mode ~= 1
  PEETError('Mode must be one of empty ([ ]), 0, or 1');
end
mRCImage.forceWriteByteMode = mode;
