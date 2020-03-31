%write          Write the Imod model to a file
%
%   imodModel = write(imodModel, filename, verbose)
%
%   imodModel   The ImodModel object to write out.
%
%   filename    OPTIONAL: A new filename to write the object to (default:
%               the current ImodModel.filename
%
%   verbose     OPTIONAL: The amount of verbosity (default: 0).
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

function imodModel = write(imodModel, filename, verbose)

if nargin < 3
  verbose = 0;
end
if nargin > 1
  if verbose
    fprintf('Setting model filename to %s\n', filename);
  end
  imodModel = setFilename(imodModel, filename);
end

% Open the specified model file writable
if verbose
  fprintf('Switching the model file to writable\n');
end
imodModel.fid = openWritable(imodModel);

% Write out the model header
if verbose
  fprintf('Writing the header\n');
end
writeHeader(imodModel);

% Loop over each object writting it out to the file
for idxObject = 1:imodModel.nObjects
  if verbose
    fprintf('Writing object %d\n', idxObject);
  end
  write(imodModel.Objects{idxObject}, imodModel.fid);
end

% Optionally write a MINX record. Last since it applies to the whole model.
if ~isempty(imodModel.MINX)
  writeAndCheck(imodModel.fid, 'MINX', 'uchar');
  writeAndCheck(imodModel.fid, 72, 'int32');
  writeAndCheck(imodModel.fid, imodModel.MINX, 'float32');
end

writeAndCheck(imodModel.fid, 'IEOF', 'uchar');
 
if verbose
  fprintf('Closing the model\n');
end
imodModel = close(imodModel);
