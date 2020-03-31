%freadMesh  ImodMesh file reader
%
%   imodMesh = freadMesh(imodMesh, fid)
%
%   imodMesh    The ImodMesh object.
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD mesh object.
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

function imodMesh = freadMesh(imodMesh, fid, debug)

%  Check to make sure we have a Imod Mesh
ID = char(fread(fid, [1 4], 'uchar')); %#ok<FREAD>

if strncmp('MESH', ID, 4) ~= 1
  PEETError('This is not an IMOD Mesh object!');
end

imodMesh.nVertices = fread(fid, 1, 'int32');
imodMesh.nIndices = fread(fid, 1, 'int32');
imodMesh.flag = fread(fid, 1, 'int32');
imodMesh.type = fread(fid, 1, 'int16');
imodMesh.pad = fread(fid, 1, 'int16');
imodMesh.vertices = reshape(fread(fid, imodMesh.nVertices * 3, ...
                                'float32'),  3, imodMesh.nVertices);
imodMesh.indices = fread(fid, imodMesh.nIndices, 'int32');

if debug
  fprintf('    nVertices: %d\n', imodMesh.nVertices);
  fprintf('    nIndices: %d\n', imodMesh.nIndices);
  fprintf('    flag:  %d\n', imodMesh.flag);
  fprintf('    type:  %d\n', imodMesh.type);
  fprintf('    pad:  %d\n', imodMesh.pad);
end
