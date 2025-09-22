%ImodChunk    ImodChunk class definition and constructor
%
%   imodChunk = ImodChunk
%   imodChunk = ImodChunk(fid)
%   imodChunk = ImodChunk(imodChunk)
%
%   imodChunk   The ImodChunk object.
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD chunk object.
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

classdef ImodChunk
  properties (Access = private)
    ID = 0;
    nBytes = 0;
    bytes = [];
  end

  methods
    function imodChunk = ImodChunk(varargin)
      % Default constructor
      if length(varargin) < 1
        return;
      end

      % Single argument, if its a double it should be the file descriptor
      % of with the pointer at the start of an Imod Chunk object if is
      % another ImodChunk perform a copy construction
      if length(varargin) == 1
        if isa(varargin{1}, 'ImodChunk')
          imodChunk = varargin{1};
        else
          imodChunk = freadChunk(imodChunk, varargin{1});
        end
      end
    end
  end
  
end
