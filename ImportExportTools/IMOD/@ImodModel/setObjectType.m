%setObjectType  Set the object type of the specified object
%
%   imodModel = setObjectType(imodModel, idxObject, type)
%
%   imodModel   The ImodModel object.
%
%   idxObject   The index of the object whos type to change.
%
%   type      A case insensitive string specifying the object type: either
%             'closed', 'open', 'scattered'
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

function imodModel = setObjectType(imodModel, idxObject, type)
if idxObject > length(imodModel.Objects)
  PEETError('Object %d does not exist', idxObject);
end
iObject = getObject(imodModel, idxObject);
imodModel.Objects{idxObject} = setType(iObject, type);
