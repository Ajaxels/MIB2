%openWritable   (Re)open the file to be writable creating it if necessary.
%
%   fid = openWritable(imodModel)
%
%   fid         The file ID of the opened file.
%
%   imodModel   The ImodModel object.
%
%   openWritable open or reopens the file as writable, creating the file if
%   it does not exist yet.  The file ID of the opened file is returned.  The
%   file is specified in the ImodModel.filename field.
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

function fid = openWritable(imodModel)

% Check to see if the file exists
result = dir(imodModel.filename);
if size(result, 1) > 0
  % file does exist (re)open it r+, we don't want to open it w+ because that
  % will truncate it
  format = 'r+';
else 
  % The file doesn't exist open it w+
  format = 'w+';
  
  % Failsafe, this shouldn't happen
  if ~ isempty(imodModel.fid)
    disp('Found an FID in an ImodModel object that did not have a filename');
    PEETWarning('Closing stale FID; this may close the wrong object!');
    close(imodModel);
  end
end

% Check to see if the file is already open
if isempty(imodModel.fid)
  [fid msg]= fopen(imodModel.filename, format, imodModel.endianFormat);
  if fid == -1
    disp(msg)
    PEETError(['Unable to open ' imodModel.filename ' as ' format]);
  end
else
  [~, permission] = fopen(imodModel.fid);
  switch permission
   case {'r', 'a', 'a+'}
    % Close and reopen the file to get a writable mode
    fclose(imodModel.fid);
    [fid msg]= fopen(imodModel.filename, format, imodModel.endianFormat);
    if fid == -1
      disp(msg)
      PEETError(['Unable to reopen ' imodModel.filename ' as ' format]);
    end
   
   otherwise
    % The file is already open for writing, just return the current fid
    fid = imodModel.fid;
  end
end

