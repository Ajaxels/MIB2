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

