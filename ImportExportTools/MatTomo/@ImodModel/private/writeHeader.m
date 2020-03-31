%writeHeader    Write the header of an ImodModel
%
%   writeHeader(imodModel)
%
%   imodModel   The ImodModel object
%
%   Write out the ImodModel header to the current fid.
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

function writeHeader(imodModel)

if isempty(imodModel.fid)
  PEETError('ImodModel fid is empty!')
end

tag = ['IMOD' imodModel.version];
writeAndCheck(imodModel.fid, tag, 'uchar');

nChar = length(imodModel.name);
nameStr = [imodModel.name zeros(1, 128-nChar)];
writeAndCheck(imodModel.fid, nameStr, 'uchar');

% Write out the header data
writeAndCheck(imodModel.fid, imodModel.xMax, 'int32');
 
writeAndCheck(imodModel.fid, imodModel.yMax, 'int32');
writeAndCheck(imodModel.fid, imodModel.zMax, 'int32');
writeAndCheck(imodModel.fid, imodModel.nObjects, 'int32');
writeAndCheck(imodModel.fid, imodModel.flags, 'uint32');
writeAndCheck(imodModel.fid, imodModel.drawMode, 'int32');
writeAndCheck(imodModel.fid, imodModel.mouseMode, 'int32');
writeAndCheck(imodModel.fid, imodModel.blackLevel, 'int32');
writeAndCheck(imodModel.fid, imodModel.whiteLevel, 'int32');
writeAndCheck(imodModel.fid, imodModel.xOffset, 'float32');
writeAndCheck(imodModel.fid, imodModel.yOffset, 'float32');
writeAndCheck(imodModel.fid, imodModel.zOffset, 'float32');
writeAndCheck(imodModel.fid, imodModel.xScale, 'float32');
writeAndCheck(imodModel.fid, imodModel.yScale, 'float32');
writeAndCheck(imodModel.fid, imodModel.zScale, 'float32');
writeAndCheck(imodModel.fid, imodModel.object, 'int32');
writeAndCheck(imodModel.fid, imodModel.contour, 'int32');
writeAndCheck(imodModel.fid, imodModel.point, 'int32');
writeAndCheck(imodModel.fid, imodModel.res, 'int32');
writeAndCheck(imodModel.fid, imodModel.thresh, 'int32');
writeAndCheck(imodModel.fid, imodModel.pixelSize, 'float32');
writeAndCheck(imodModel.fid, imodModel.units, 'int32');
writeAndCheck(imodModel.fid, imodModel.csum, 'int32');
writeAndCheck(imodModel.fid, imodModel.alpha, 'int32');
writeAndCheck(imodModel.fid, imodModel.beta, 'int32');
writeAndCheck(imodModel.fid, imodModel.gamma, 'int32');
