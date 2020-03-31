% setPoints     Sets the points of the specified object and contour
%
%   imodModel = setPoints(imodModel, idxObject, idxContour, points)
%
%   imodModel   The ImodModel object.
%
%   idxObject   The index of the object in the model
%
%   idxContour  The index of the countour in the specified object
%
%   points      The array of points to set the countour to (3xN)
%
%   Bugs: none known
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

function imodModel = setPoints(imodModel, idxObject, idxContour, points)
imodObject = imodModel.Objects{idxObject};
imodContour = getContour(imodObject, idxContour);
imodContour = setPoints(imodContour, points);
imodObject = setContour(imodObject, imodContour, idxContour);
imodModel.Objects{idxObject} = imodObject;
