%write         Write the ImodMINX
%
%   write(imodMINX, fid)
%
%   imodMINX The ImodMINX object.
%
%   fid         A file ID of an open file with the pointer the desired
%               location of the MINX chunk,
%
%   Write out the ImodMINX to the specified fid.
%   
%   Calls: none
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

function write(imodMINX, fid)

  writeAndCheck(fid, 'MINX', 'uchar');
  writeAndCheck(fid, 72, 'int32');
  writeAndCheck(fid, imodMINX.oldScale, 'float32');
  writeAndCheck(fid, imodMINX.oldTrans, 'float32');
  writeAndCheck(fid, imodMINX.oldRot, 'float32');
  writeAndCheck(fid, imodMINX.scale, 'float32');
  writeAndCheck(fid, imodMINX.trans, 'float32');
  writeAndCheck(fid, imodMINX.rot, 'float32');
    
end
