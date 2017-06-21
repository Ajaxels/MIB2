%setName       Sets the name of the ImodObject
%
%   imodObject = setName(imodObject, name)
%
%   imodObject  The ImodObject
%
%   name       The name of the object (127 characters max)
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2015 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2015/02/06 18:23:34 $
%
%  $Revision: c2aaa56be709 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imodObject = setName(imodObject, name)

n = length(name);
if n > 127
  PEETWarning(['Requested object name is longer than 127 characters\n' ...
    '         Only the 1st 127 characters will be used.']);
  n = 127;
end
imodObject.name = [ name(1:n) ];