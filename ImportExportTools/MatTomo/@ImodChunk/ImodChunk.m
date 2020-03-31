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
