%write         Write the ImodContour
%
%   write(imodContour, fid)
%
%   imodContour The ImodContour object.
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD contour object.
%
%   Write out the ImodContour to the specified fid.
%   
%   Calls: none
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

function write(imodContour, fid)

  writeAndCheck(fid, 'CONT', 'uchar');
  writeAndCheck(fid, imodContour.nPoints, 'int32');
  writeAndCheck(fid, imodContour.flags, 'int32');
  writeAndCheck(fid, imodContour.type, 'int32');
  writeAndCheck(fid, imodContour.iSurface, 'int32');
  writeAndCheck(fid, imodContour.points, 'float32');
  % Write optional SIZE record if point sizes have been specified
  if ~isempty(imodContour.pointSizes)
    if length(imodContour.pointSizes) ~= imodContour.nPoints
      PEETError('Number of point sizes must match number of points!');
    end
    writeAndCheck(fid, 'SIZE', 'uchar');
    writeAndCheck(fid, 4 * imodContour.nPoints, 'int32');
    writeAndCheck(fid, imodContour.pointSizes, 'float32');
  end
  
end
