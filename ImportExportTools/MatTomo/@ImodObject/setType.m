%setType        Set the object type
%
%   imodObject = setType(imodObject, type)
%
%   imodObject  The ImodObject
%
%   type        A case insensitive string specifying the object type: either
%               'closed', 'open', 'scattered'
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

function imodObject = setType(imodObject, type)
switch lower(type)
  case 'closed'
    imodObject.flags = bitset(bitset(imodObject.flags, 10, 0), 4, 0);
  case 'open'
    imodObject.flags = bitset(bitset(imodObject.flags, 10, 0), 4, 1);
  case 'scattered'
    imodObject.flags = bitset(bitset(imodObject.flags, 10, 1), 4, 1);
  otherwise
    PEETError('Unknown object type: %s!', type);
end
