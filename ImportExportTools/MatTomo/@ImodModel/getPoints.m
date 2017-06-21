%getPoints      Return the points of the specified object and contour
%
%   points = getPoints(imodModel, idxObject, idxContour)
%
%   points      The array of points contained in the specified object and
%               contour (3xN).
%
%   imodModel   The ImodModel object.
%
%   idxObject   The index of the object and contour from which to extract the
%   idxContour  points.
%
%   indices     OPTIONAL: Selected indices of the countour (default: [ ] which
%               implies all points).
%
%   Return the points of the specified object and contour.
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

function points = getPoints(imodModel, idxObject, idxContour, indices)

if nargin < 4 || isempty(indices)
  indices = [ ];
end

%Only object is specified, return all points of all contours of that object.
if nargin<3
    obj=getObject(imodModel, idxObject);
    numOfContours=getNContours(obj);
    points=[];
    for contour=1:numOfContours
       points =[points getPoints(obj, contour, indices)];
    end
else
    points = getPoints(imodModel.Objects{idxObject}, idxContour, indices);
end
