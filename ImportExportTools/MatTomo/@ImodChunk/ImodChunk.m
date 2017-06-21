%ImodChunk    ImodChunk constructor
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

function imodChunk = ImodChunk(varargin)

% Default constructor
if length(varargin) < 1
  imodChunk = genImodChunkStruct;
  imodChunk = class(imodChunk, 'ImodChunk');
  return;
end

% Single argument, if its a double it should be the file descriptor
% of with the pointer at the start of an Imod Chunk object if is
% another ImodChunk perform a copy construction
if length(varargin) == 1
  imodChunk = genImodChunkStruct;
  imodChunk = class(imodChunk, 'ImodChunk');
  if isa(varargin{1}, 'ImodChunk')
    imodChunk = varargin{1};
  else
    imodChunk = freadChunk(imodChunk, varargin{1});
  end
end
