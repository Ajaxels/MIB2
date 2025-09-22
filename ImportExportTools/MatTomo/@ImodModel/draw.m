%draw           Draw the IMOD model on the current display
%
%   draw(imodModel)
%
%   imodModel  The ImodModel
%
%   ImodModel.draw draws the complete model on the current figure and axis.
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
function draw(imodModel)

for iObject = 1:imodModel.nObjects
  imodObject = getObject(imodModel, iObject);
  
  % Set the color order to match the specified color of the object,
  % save the old color order to reset when we are done
  oldColorOrder = get(gca, 'ColorOrder');
  set(gca, 'ColorOrder', getColor(imodObject));
  for iContour = 1:getNContours(imodObject)
    imodContour = getContour(imodObject, iContour);
    points = getPoints(imodContour);
    plot3(points(1,:), points(2,:), points(3,:), '+')
  end
  set(gca, 'ColorOrder', oldColorOrder);
end

