%sort           Sort the points of the specified object and contour
%
%   imodModel = sort(imodModel, idxObject, idxContour, idxStart)
%
%   imodModel   The ImodModel object.
%
%   idxObject   The index of the object and contour containing the points to
%   idxContour  sort.
%
%   idxStart    The index of the point in the specified object and contour to
%               used as the origin for the sort.
%
%   sort reorders points in the specified object and contour so that they are
%   indexed next to their nearest neighboor starting with the idxStart point.
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

function imodModel = sortPoints(imodModel, idxObject, idxContour, idxStart)
objectType = getObjectType(imodModel, idxObject);

points = getPoints(imodModel, idxObject, idxContour);
nPoints = size(points, 2);

refPoint = repmat(points(:, idxStart), 1, nPoints);
distsq = sum((points - refPoint).^2);
[v idxSort] = sort(distsq);
points = points(:, idxSort);
imodModel = setPoints(imodModel, idxObject, idxContour, points);
imodModel = setObjectType(imodModel, idxObject, objectType);
