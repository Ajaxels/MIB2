%setFilename    Set the filename associated with this Imod model
%
%   imodModel = setFilename(imodModel, filename)
%
%   imodModel   The ImodModel object.
%
%   filename    A string containing the name of the Imod model to load.
%
%   Set the filename associated with this ImodModel object.
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

function imodModel = setFilename(imodModel, filename)

imodModel = close(imodModel);
imodModel.filename = filename;
