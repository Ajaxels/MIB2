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

