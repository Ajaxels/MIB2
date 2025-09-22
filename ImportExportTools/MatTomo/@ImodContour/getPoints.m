%getPoints      Return the points of the contour
%
%   points = getPoints(imodContour, indices)
%
%   points      The selected points of the contour in a 3 x N array
%
%   imodContour The ImodContour object.
%
%   indices     OPTIONAL: Selected indices of the countour (default: [ ] 
%               which implies all points).
%
%   ImodContour.getPoints return the points of the contour.
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2025 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2025/01/02 17:09:20 $
%
%  $Revision: 03a2974f77e3 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function points = getPoints(imodContour, indices)

if nargin < 2 || isempty(indices)
  points = imodContour.points;
else
  points = imodContour.points(:, indices);
end
