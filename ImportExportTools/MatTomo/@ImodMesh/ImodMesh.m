%ImodMesh    ImodMesh constructor
%
%   imodMesh = ImodMesh
%   imodMesh = ImodMesh(fid)
%   imodMesh = ImodMesh(imodMesh)
%
%   imodMesh    The ImodMesh object.
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD mesh object.
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

function imodMesh = ImodMesh(varargin)

% Default constructor
if length(varargin) < 1
  imodMesh = genImodMeshStruct;
  imodMesh = class(imodMesh, 'ImodMesh');
  return;
end

% Single argument, if its a double it should be the file descriptor
% of with the pointer at the start of an Imod Mesh object if is
% another ImodMesh perform a copy construction
if length(varargin) == 1
  imodMesh = genImodMeshStruct;
  imodMesh = class(imodMesh, 'ImodMesh');
  if isa(varargin{1}, 'ImodMesh')
    imodMesh = varargin{1};
  else
    imodMesh = freadMesh(imodMesh, varargin{1});
  end
end
