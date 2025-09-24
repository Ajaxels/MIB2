%open           Open a MRCImage file
%
%   mRCImage = open(mRCImage, filename, flgLoadVolume, debug)
%
%   mRCImage    The opened MRCImage object
%
%   filename    The file name of the MRCImage file to load
%
%   flgLoadVolume OPTIONAL: Load in the volume data (default: 1)
%
%   debug       OPTIONAL: Print out information as the header is loaded.
%
%
%   open loads the MRCImage header of the specified file and allows
%   the MRCImage object to be manipulated. 
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

function mRCImage = open(mRCImage, filename, flgLoadVolume, debug)

if nargin < 4
  debug = 0;
  if nargin < 3
    flgLoadVolume = 1;
  end
end

% Check to see a the file is already open
if ~ isempty(mRCImage.fid)
  PEETError('An MRC file is already open!');
end
% Open the file read-only, save the fid for future access and the filename
% if we need to reopen it r+ 
[fid, msg]= fopen(filename, 'r');
if fid ~= -1
  mRCImage.fid = fid;
  
  % Check for absolute or relative path, remembering Window's drive letters
  if filename(1) == '/' || (ispc && (filename(1) == '\' ||             ...
     filename(2) == ':' && (filename(3) == '/' || filename(3) == '\')))
    mRCImage.filename = filename;
  else
    mRCImage.filename = [pwd '/' filename];
  end
  [mRCImage] = readHeader(mRCImage, debug);
  
  if flgLoadVolume
    mRCImage = loadVolume(mRCImage);

    mRCImage.volume = reshape(mRCImage.volume,                         ...
                              mRCImage.header.nX,                      ...
                              mRCImage.header.nY,                      ...
                              mRCImage.header.nZ);
    mRCImage.flgVolume = 1;
    fclose(mRCImage.fid);
    mRCImage.fid = [];
  end
else
  PEETError('Unable to open file: %s.\nReason: %s', filename, msg);
end
