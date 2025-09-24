% getPoints     Return the points of the specified contour
%
%   points = getPoints(imodObject, idxContour, indices)
%
%   points      The array of points contained in the specified object and
%               contour (3xN).
%
%   imodObject  The ImodObject containing the contour
%
%   idxContour  The index of the contour from which to extract the points.
%
%   indices     OPTIONAL: Selected indices of the countour (default: [ ]
%               which implies all points).
%
%   Return the points of the specified contour in the current object.
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


function points = getPoints(idxObject, idxContour, indices)

if nargin < 3 || isempty(indices)
  indices = [ ];
end

points = getPoints(idxObject.contour{idxContour}, indices);
