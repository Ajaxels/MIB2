%appendObject  Append the specified ImodObject to the ImodModel
%
%   imodModel = appendObject(imodModel, imodObject)
%
%   imodModel  The ImodModel object.
%
%   imodObject The ImodObject to append to the end of the ImodModel
%
%   ImodModel.appendObject adds the specified imodObject to the list of objects
%   for this model.  If the color of the object is unset (black) then it is set
%   to the next color in the color list as specified by
%   ImodModel.getDefaultColor
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

function imodModel = appendObject(imodModel, imodObject)

imodModel.nObjects = imodModel.nObjects + 1;

% If the color is unset (black) set it
color = getColor(imodObject);
if all(color == 0.0)
  color = getDefaultColor(imodModel, imodModel.nObjects);
  imodObject = setColor(imodObject, color);
end 
  
imodModel.Objects{imodModel.nObjects}  = imodObject;
