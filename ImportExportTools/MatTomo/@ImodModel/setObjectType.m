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

function imodModel = setObjectType(imodModel, idxObject, type)
if idxObject > length(imodModel.Objects)
  PEETError('Object %d does not exist', idxObject);
end
iObject = getObject(imodModel, idxObject);
imodModel.Objects{idxObject} = setType(iObject, type);
