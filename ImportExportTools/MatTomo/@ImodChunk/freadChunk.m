%freadChunk     ImodChunk file reader
%
%   imodChunk = freadChunk(imodChunk, fid)
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

function imodChunk = freadChunk(imodChunk, fid)

%  Read in the tag since we may need to write it out again
imodChunk.ID = char(fread(fid, [1 4], 'uchar')); %#ok<*FREAD>
%fprintf('ID: %s\n', imodChunk.ID);
imodChunk.nBytes = fread(fid, 1, 'int32');
%fprintf('# bytes: %d\n', imodChunk.nBytes);
imodChunk.bytes = fread(fid, imodChunk.nBytes, 'uchar=>uchar');
