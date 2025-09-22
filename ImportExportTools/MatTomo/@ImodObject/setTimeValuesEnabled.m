%setTimeValuesEnabled     Enable or disable time values
%
%   imodObject = setTimeValuesEnabled(imodObject, state)
%
%   imodObject   The ImodObject
%
%   state        desired state [0 / false or 1 / true]
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

function imodObject = setTimeValuesEnabled(imodObject, state)
  % Note that Matlab bit-positions are 1-based rather than 0-based!
  if state
    imodObject.flags = bitset(imodObject.flags, 19, 1);
  else
    imodObject.flags = bitset(imodObject.flags, 19, 0);
  end
end

