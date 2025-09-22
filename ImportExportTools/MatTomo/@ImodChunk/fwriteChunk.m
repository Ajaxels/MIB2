%fwriteChunk     ImodChunk file write
%
%   imodChunk = writeChunk(imodChunk, fid)
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

function imodChunk = fwriteChunk(imodChunk, fid)

% Write the chunk tag
n = fwrite(fid, imodChunk.ID, 'uchar');
if n ~= length(imodChunk.ID)
  PEETError('Error writing tag %s!', imodChunk.tag);
end

% Write the chunk data length
n = fwrite(fid, imodChunk.nBytes, 'int32');
if n ~= 1
  PEETError('Error writing chunk length!');
end

% Write the chunk data
n = fwrite(fid, imodChunk.bytes, 'uchar');
if n ~= imodChunk.nBytes
  PEETError('Error writing chunk data!');
end
