%openWritable   (Re)open the file to be writable creating it if necessary.
%
%   fid = openWritable(mRCImage)
%
%   fid         The file ID of the opened filed.
%
%   mRCImage    The MRCImage object.
%
%   openWritable open or reopens the file as writable, creating the file if
%   it does not exist yet.  The file ID of the opened file is returned.  The
%   file is specified in the MRCImage.filename field.
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

function fid = openWritable(mRCImage)

% Check to see if the file exists
result = dir(mRCImage.filename);
if size(result, 1) > 0
  % file does exist (re)open it r+, we don't want to open it w+ because that
  % will truncate it
  format = 'r+';
else 
  % The file doesn't exist open it w+
  format = 'w+';
  
  % Failsafe, this shouldn't happen
  if ~ isempty(mRCImage.fid)
    disp('Found an FID in a MRCImage object that did not have a filename');
    PEETWarning('Closing stale FID! This may close the wrong object!');
    close(mRCImage);
  end
end

% Check to see if the file is already open
if isempty(mRCImage.fid)
  [fid msg]= fopen(mRCImage.filename, format, mRCImage.endianFormat);
  if fid == -1
    disp(msg)
    PEETError(['Unable to open ' mRCImage.filename ' as ' format]);
  end

else
  [name permission] = fopen(mRCImage.fid);
  switch permission
   case {'r', 'a', 'a+'}
    % Close and reopen the file to get a writable mode
    fclose(mRCImage.fid);
    [fid msg]= fopen(mRCImage.filename, format, mRCImage.endianFormat);
    if fid == -1
      disp(msg)
      PEETError(['Unable to reopen ' mRCImage.filename ' as ' format]);
    end
   
   otherwise
    % The file is already open for writing, just return the current fid
    fid = mRCImage.fid;
  end
end
