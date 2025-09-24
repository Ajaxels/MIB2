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
