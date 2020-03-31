function writeAsSigned = getWriteBytesAsSigned(mRCImage)

% getWriteBytesAsSigned  Determine whether to read a mode=0 file as signed 
%                        or unsigned bytes.
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2020/01/02 23:33:44 $
%
%  $Revision: ce44cef00aca $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

writeAsSigned = 0;  % Default to 0. TODO: Change to 1 in a couple releases
if mRCImage.header.mode ~= 0
  return;           % This flag is only relevant for files with mode = 0
end

forcedMode = getForceWriteByteMode(mRCImage);
if ~isempty(forcedMode)
  writeAsSigned = forcedMode;
else                                       % check environment variables
  writeBytesEnvVal = getenv('WRITE_MODE0_SIGNED');
  if ~isempty(writeBytesEnvVal)
    writeBytesEnvVal = str2double(writeBytesEnvVal);
    if writeBytesEnvVal == 0
      writeAsSigned = 0;
    elseif writeBytesEnvVal == 1
      writeAsSigned = 1;
    else
      PEETError('WRITE_MODE0_SIGNED environment variable must be 0 or 1');
    end
  end
end
