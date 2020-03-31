%setObject     Set the specified ImodObject in the ImodModel
%
%   imodModel = setObject(imodModel, imodObject, idxObject)
%
%   imodModel  The ImodModel containing the object.
%
%   imodObject The ImodObject extracted from the model.
%
%   idxObject  The idxObject of the requested object in the model.
%
%   Bugs: allows objects to be non-contiguous.
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2020/01/02 23:33:44 $
%
%  $Revision: ce44cef00aca $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imodModel = setObject(imodModel, imodObject, idxObject)
imodModel.Objects{idxObject} = imodObject;
imodModel.nObjects = length(imodModel.Objects);
