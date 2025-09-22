%ImodMesh    ImodMesh class definition and constructor
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

classdef ImodMesh
  properties(Access = private)
    nVertices = 0;         % # of triples
    nIndices = 0;
    flag = 0;
    type = 0;
    pad = 0;
    vertices = [];
    indices = [];
  end

  methods
    function imodMesh = ImodMesh(varargin)

      % Default constructor
      if length(varargin) < 1
        return;
      end

      % Single argument, if its a double it should be the file descriptor
      % of with the pointer at the start of an Imod Mesh object if is
      % another ImodMesh perform a copy construction
      if length(varargin) == 1
        if isa(varargin{1}, 'ImodMesh')
          imodMesh = varargin{1};
        else
          imodMesh = freadMesh(imodMesh, varargin{1});
        end
      end
    end
  end
end
