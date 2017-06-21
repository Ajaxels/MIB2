%genImodModelStruct     Generate a default ImodModel structure
%
%   imodModel = genImodModelStruct
%
%   imodModel   The ImodModel object.
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

function imodModel = genImodModelStruct

imodModel.fid = [];
imodModel.filename = '';
imodModel.endianFormat = 'ieee-be';
imodModel.version = 'V1.2';

imodModel.name  = 'ImodModel';
imodModel.xMax = 0;
imodModel.yMax = 0;
imodModel.zMax = 0;
imodModel.nObjects = 0;
imodModel.flags = 0;
imodModel.drawMode = 1;
imodModel.mouseMode = 0;
imodModel.blackLevel = 0;
imodModel.whiteLevel = 255;
imodModel.xOffset = 0;
imodModel.yOffset = 0;
imodModel.zOffset = 0;
imodModel.xScale = 1.0;
imodModel.yScale = 1.0;
imodModel.zScale = 1.0;
imodModel.object = 0;
imodModel.contour = 0;
imodModel.point = 0;
imodModel.res = 3;
imodModel.thresh = 0;
imodModel.pixelSize = 1;
imodModel.units = 0;
imodModel.csum = 0;
imodModel.alpha = 0;
imodModel.beta = 0;
imodModel.gamma = 0;
imodModel.Objects = {};
