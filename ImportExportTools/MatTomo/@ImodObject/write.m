%write          Write the ImodObject to a file
%
%   write(imodObject, fid)
%
%   imodObject  The ImodObject
%
%   fid         A file descriptor of an open file with the pointer set at the
%               location to write this object.
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

function write(imodObject, fid)

if imodObject.nMeshes > 0
  PEETWarning('Writing out meshes is not yet implemented!');
end

imodObject.nMeshes=0;
% Write out the model header
writeHeader(imodObject, fid);

% Loop over each contour writting it out to the file
if imodObject.nContours > 0
  for idxContour = 1:imodObject.nContours
    write(imodObject.contour{idxContour}, fid);
  end
end

%write out IMAT 
writeAndCheck(fid, 'IMAT', 'uchar');
writeAndCheck(fid, 16, 'int32');
writeAndCheck(fid, imodObject.ambient, 'uchar');
writeAndCheck(fid, imodObject.diffuse, 'uchar');
writeAndCheck(fid, imodObject.specular, 'uchar');
writeAndCheck(fid, imodObject.shininess, 'uchar');
writeAndCheck(fid, imodObject.fillred, 'uchar');
writeAndCheck(fid, imodObject.fillgreen, 'uchar');
writeAndCheck(fid, imodObject.fillblue, 'uchar');
writeAndCheck(fid, imodObject.quality, 'uchar');
writeAndCheck(fid, imodObject.mat2, 'int32');
writeAndCheck(fid, imodObject.valblack, 'uchar');
writeAndCheck(fid, imodObject.valwhite, 'uchar');
writeAndCheck(fid, imodObject.matflags2, 'uchar');
writeAndCheck(fid, imodObject.mat3b3, 'uchar');
