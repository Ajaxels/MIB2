%freadContour   ImodContour file reader
%
%   imodContour = freadContour(imodContour, fid)
%
%   imodContour The ImodContour object.
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD contour object.
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

function imodContour = freadContour(imodContour, fid, debug)

%  Check to make sure we have a Imod Contour
ID = char(fread(fid, [1 4], 'uchar'));

if strncmp('CONT', ID, 4) ~= 1
  PEETError('This is not an IMOD Contour object!');
end

imodContour.nPoints = fread(fid, 1, 'int32');
imodContour.flags = fread(fid, 1, 'int32');
imodContour.type = fread(fid, 1, 'int32');
imodContour.iSurface = fread(fid, 1, 'int32');
imodContour.points = reshape(fread(fid, imodContour.nPoints * 3, ...
                                'float32'),  3, imodContour.nPoints);

if debug
  fprintf('    points: %d\n', imodContour.nPoints);
  fprintf('    flags:  %d\n', imodContour.flags);
  fprintf('    type:  %d\n', imodContour.type);
  fprintf('    surf:  %d\n', imodContour.iSurface);
end
