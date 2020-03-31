%open           Read the Imod model specified in the file
%
%   imodModel = open(imodModel, filename, verbose)
%
%   imodModel   The ImodModel object.
%
%   filename    A string containing the name of the Imod model to load.
%
%   verbose     OPTIONAL: The amount of verbosity (default: 0).
%
%
%   ImodModel.open will load in the Imod model specified by the supplied file
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

function imodModel = open(imodModel, filename, verbose)

if nargin < 3
  verbose = 0;
end

% Check to see a the file is already open
if ~ isempty(imodModel.fid)
  PEETError('An IMOD model file is already open.');
end

% Open the file read-only, save the fid for future access
% IMOD models are always big endian!
imodModel.endianFormat = 'ieee-be';
[fid, msg]= fopen(filename, 'r', imodModel.endianFormat);
if fid ~= -1
  imodModel.fid = fid;
  imodModel.filename = filename;
  [imodModel] = readHeader(imodModel, verbose);
else
  PEETError('Unable to open file: %s\nReason: %s', filename, msg);
end
