% getVerticesAndNormals     Return the ImodMesh vertices and normals
%
%   [vertices, normals] = getVerticesAndNormals(imodMesh)
%
%   vertices    An 3xN arrary of N model points
%
%   normals     An 3xN arrary of N normal vectors
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2020/01/02 23:33:44 $
%
%  $Revision: ce44cef00aca $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [vertices, normals] = getVerticesAndNormals(imodMesh)

% Check for new (-25) instead of old (-23) style mesh
if any(imodMesh.indices == -23)
  PEETError('Old style meshes are not supported. Please re-mesh!');
end
% All good. Now ignore indices (which define face triangles) and use only
% "vertices", which really alternate between vertices and their normals.
vertices = imodMesh.vertices(:, 1:2:(end-1));
normals = imodMesh.vertices(:, 2:2:end);


