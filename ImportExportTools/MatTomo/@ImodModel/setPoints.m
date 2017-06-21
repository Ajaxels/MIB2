%setPoints      Sets the points of the specified object and contour
%
%   imodModel = setPoints(imodModel, idxObject, idxContour, points)
%
%   imodModel   The ImodModel object.
%
%   idxObject   The index of the object in the model to set.
%
%   idxContour  The index of the countour to set in the specified object to set.
%
%   points      The array of points to set the countour to (3xN).
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

function imodModel = setPoints(imodModel, idxObject, idxContour, points)
imodObject = imodModel.Objects{idxObject};
imodContour = getContour(imodObject, idxContour);
imodContour = setPoints(imodContour, points);
imodObject = setContour(imodObject, imodContour, idxContour);
imodModel.Objects{idxObject} = imodObject;
