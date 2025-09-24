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

function imodModel = appendObject(imodModel, imodObject)

imodModel.nObjects = imodModel.nObjects + 1;

% If the color is unset (black) set it
color = getColor(imodObject);
if all(color == 0.0)
  color = getDefaultColor(imodModel, imodModel.nObjects);
  imodObject = setColor(imodObject, color);
end 
  
imodModel.Objects{imodModel.nObjects}  = imodObject;
