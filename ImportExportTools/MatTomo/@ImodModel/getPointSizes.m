% getPointSizes    Gets point sizes for the specified object and contour
%
%   pointSizes = getPointSizes(imodModel, idxObject, idxContour)
%
%   imodModel   The ImodModel object.
%
%   idxObject   The index of the object in the model
%
%   idxContour  The index of the countour in the specified object
%
%   pointSizes  The array of point sizes (1xN)
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

function pointSizes = getPointSizes(imodModel, idxObject, idxContour)

imodObject = imodModel.Objects{idxObject};
imodContour = getContour(imodObject, idxContour);
pointSizes = getPointSizes(imodContour);


