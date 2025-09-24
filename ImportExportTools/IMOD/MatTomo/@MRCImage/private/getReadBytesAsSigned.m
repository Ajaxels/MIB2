function readAsSigned = getReadBytesAsSigned(mRCImage)

% getReadBytesAsSigned  Determine whether to read a mode=0 file as signed 
%                       or unsigned bytes.
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

readAsSigned = 0;
if mRCImage.header.mode ~= 0
  return;    % This flag is only relevant for files with mode = 0
end

readBytesEnvVal = getenv('READ_MODE0_SIGNED');
if ~isempty(readBytesEnvVal)
  readBytesEnvVal = str2double(readBytesEnvVal);
else
  readBytesEnvVal = 0;
end

if mRCImage.header.imodStamp == defaultIMODStamp()
  readAsSigned = bitand(mRCImage.header.imodFlags, 1);
  if readBytesEnvVal < -1
    readAsSigned = 0;
  elseif readBytesEnvVal > 1
    readAsSigned = 1;
  end
else
  % Try to choose type based on min / max density
  dmin = mRCImage.header.minDensity;
  dmax = mRCImage.header.maxDensity;
  if dmin < 0.0 && dmax < 128.0
    readAsSigned = 1;
  elseif dmin >= 0.0 && dmax >= 128.0
    readAsSigned = 0;
  elseif dmin < 0.0 && dmax > 128.0
    if -dmin > dmax - 128.0
      readAsSigned = 1;
    else
      readAsSigned = 0;
    end
  else
    readAsSigned = 0;  % Ambiguous... could be either signed or unsigned
  end
  % Let the environment variable over-ride automatic selection
  if readBytesEnvVal < 0
    readAsSigned = 0;
  elseif readBytesEnvVal > 0
    readAsSigned = 1;
  end
end
