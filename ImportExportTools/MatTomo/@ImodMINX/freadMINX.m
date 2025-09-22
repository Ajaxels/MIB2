%freadMINX   ImodMINX file reader
%
%   imodMINX = freadMINX(imodMINX, fid)
%
%   imodMINX The ImodMINX object.
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD contour object.
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

function imodMINX = freadMINX(imodMINX, fid, debug)

%  Check to make sure we have a Imod MINX
ID = char(fread(fid, [1 4], 'uchar'));
if strncmp('MINX', ID, 4) ~= 1
  PEETError('This is not an IMOD MINX object!');
end
size = uint32(fread(fid, 1, 'uint32'));
if size ~= 72
  PEETError('MINX record has incorrect size %d!', size);
end

imodMINX.oldScale = fread(fid, 3, 'float32');
imodMINX.oldTrans = fread(fid, 3, 'float32');
imodMINX.oldRot = fread(fid, 3, 'float32');
imodMINX.scale = fread(fid, 3, 'float32');
imodMINX.trans = fread(fid, 3, 'float32');
imodMINX.rot = fread(fid, 3, 'float32');

if debug
  %fprintf('    oldScale: %f %f %f\n', imodMINX.oldScale);
  fprintf('    oldTrans: %f %f %f\n', imodMINX.oldTrans);
  %fprintf('    oldRot: %f %f %f\n', imodMINX.oldRot);
  fprintf('    Scale: %f %f %f\n', imodMINX.scale);
  fprintf('    Trans: %f %f %f\n', imodMINX.trans);
  fprintf('    Rot: %f %f %f\n', imodMINX.rot);
end
