% getPoints     Return the points of the specified object and contour
%
%   points = getPoints(imodModel, idxObject, idxContour, indices)
%
%   points      The array of points contained in the specified object and
%               contour (3xN).
%
%   imodModel   The ImodModel object.
%
%   idxObject   The indices of the object and contour in the model.
%   idxContour 
%
%   indices     OPTIONAL: Selected indices of the countour (default: [ ] 
%               which implies all points).
%
%   Return the points of the specified object and contour.
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
       points = [points getPoints(obj, contour, indices)]; %#ok<AGROW>
    end
else
    points = getPoints(imodModel.Objects{idxObject}, idxContour, indices);
end
