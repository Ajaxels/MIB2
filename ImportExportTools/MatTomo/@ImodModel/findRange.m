%findRange     Return the range of the contours in the model
%
%   dim = findRange(imodModel)
%
%   dim        The X,Y, and Z max for the model in the format
%              [xmax ymax zmax]
%
%   imodModel  The ImodModel containing the object.
%
%   Bugs: none known.
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.


function dim = findRange(imodModel)
xMax = 0;
yMax = 0;
zMax = 0;

nObjects = length(imodModel.Objects);
for iObject = 1:nObjects
  imodObject = getObject(imodModel, iObject);
  nContours = getNContours(imodObject);
  for iContour = 1:nContours
    imodContour = getContour(imodObject, iContour);
    pts = getPoints(imodContour);
    tmp = max(pts, [], 2);
    if tmp(1) > xMax
      xMax = tmp(1);
    end
    if tmp(2) > yMax
      yMax = tmp(2);
    end
    if tmp(3) > zMax
      zMax = tmp(3);
    end
  end
end

dim = [xMax yMax zMax];

