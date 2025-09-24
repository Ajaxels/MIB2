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

function imodModel = sortPoints(imodModel, idxObject, idxContour, idxStart)
objectType = getObjectType(imodModel, idxObject);

points = getPoints(imodModel, idxObject, idxContour);
nPoints = size(points, 2);

refPoint = repmat(points(:, idxStart), 1, nPoints);
distsq = sum((points - refPoint).^2);
[~, idxSort] = sort(distsq);
points = points(:, idxSort);
imodModel = setPoints(imodModel, idxObject, idxContour, points);
imodModel = setObjectType(imodModel, idxObject, objectType);
