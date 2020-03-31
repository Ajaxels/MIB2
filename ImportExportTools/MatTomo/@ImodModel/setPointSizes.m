% setPointSizes    Sets point sizes for the specified object and contour
%
%   imodModel = setPoints(imodModel, idxObject, idxContour, pointSizes)
%
%   imodModel   The ImodModel object.
%
%   idxObject   The index of the object in the model
%
%   idxContour  The index of the countour in the specified object
%
%   pointSizes  The array of points to set the countour to (3xN).
%               Must match the number of points.
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

function imodModel = setPointSizes(imodModel, idxObject, idxContour,   ...
                                   pointSizes)
imodObject = imodModel.Objects{idxObject};
imodContour = getContour(imodObject, idxContour);
% Check that the numbers of points and point sizes match.
% This generally requires setting the points first, then the sizes.
if getNPoints(imodContour) ~= length(pointSizes)
  PEETError('Numbers of points and point sizes do not match!\n');
end
imodContour = setPointSizes(imodContour, pointSizes);
imodObject = setContour(imodObject, imodContour, idxContour);
imodModel.Objects{idxObject} = imodObject;
