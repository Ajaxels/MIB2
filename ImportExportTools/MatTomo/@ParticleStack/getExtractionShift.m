% getExtractionShift  return the shift from requested to actual center that
%                     happened when a particle was originally extracted
%                     from the tomogram
%
%   shift] = getExtractionShift(particleStack, center, volSize)
%
%   particleStack    The MRCImage containing the volume
%
%   center      The coordinates (in Matlab indices) of the original center.
%
%   volSize     The size of the subvolume in voxels (1 or 3 integers)
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
function shift = getExtractionShift(~, center, volSize)

  if length(volSize) == 1
    volSize = repmat(volSize, 1, 3);
  end

  % Calculate the index range to extract; use floor(x + 0.5) because
  % round([-0.5 0.5]) = [-1 1]. Also use volSize with same shape as center.
  if any(size(volSize)  ~= size(center))
    volSizeT = volSize.';
  else
    volSizeT = volSize;
  end
  hi = floor(center + 0.5 * volSizeT);
  lo = hi - volSizeT + 1;
  shift = center - 0.5 * (lo + hi); % Shift from actual to requested center
  if abs(shift) > 0.5
    inc = sign(shift);
    %  lo = lo + inc;
    %  hi = hi + inc;
    shift = shift + inc;
  end
end