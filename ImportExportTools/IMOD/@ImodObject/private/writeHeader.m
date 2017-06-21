%writeHeader    Write the header of an ImodObject
%
%   writeHeader(imodObject, fid)
%
%   imodObject  The ImodObject
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD Object object.
%
%   Write out the ImodObject header to the specified fid.
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

function writeHeader(imodObject, fid)

writeAndCheck(fid, 'OBJT', 'uchar');

nChar = length(imodObject.name);
nameStr = [imodObject.name zeros(1, 128-nChar)];
writeAndCheck(fid, nameStr, 'uchar');

writeAndCheck(fid, imodObject.nContours, 'int32');
writeAndCheck(fid, imodObject.flags, 'int32');
writeAndCheck(fid, imodObject.axis, 'int32');
writeAndCheck(fid, imodObject.drawMode, 'int32');
writeAndCheck(fid, imodObject.red, 'float32');
writeAndCheck(fid, imodObject.green, 'float32');
writeAndCheck(fid, imodObject.blue, 'float32');
writeAndCheck(fid, imodObject.pdrawsize, 'int32');

writeAndCheck(fid, imodObject.symbol, 'uchar');
writeAndCheck(fid, imodObject.symbolSize, 'uchar');
writeAndCheck(fid, imodObject.lineWidth2D, 'uchar');
writeAndCheck(fid, imodObject.lineWidth3D, 'uchar');
writeAndCheck(fid, imodObject.lineStyle, 'uchar');
writeAndCheck(fid, imodObject.symbolFlags, 'uchar');
writeAndCheck(fid, imodObject.sympad, 'uchar');
writeAndCheck(fid, imodObject.transparency, 'uchar');

writeAndCheck(fid, imodObject.nMeshes, 'int32');
writeAndCheck(fid, imodObject.nSurfaces, 'int32');
