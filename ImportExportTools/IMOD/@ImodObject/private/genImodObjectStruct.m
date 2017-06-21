%genImodObject       Generate a default ImodObject structure
%
%   imodObject = genImodObjectStruct
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
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imodObject = genImodObjectStruct

imodObject.name  = '';

imodObject.nContours = 0;
imodObject.flags = 0;
imodObject.axis = 0;
imodObject.drawMode = 1;
imodObject.red = 0.0;
imodObject.green = 0.0;
imodObject.blue = 0.0;
imodObject.pdrawsize = 0.0;
imodObject.symbol = 1;
imodObject.symbolSize = 3;
imodObject.lineWidth2D = 1;
imodObject.lineWidth3D = 1;
imodObject.lineStyle = 0;
imodObject.symbolFlags = 0;
imodObject.sympad = 0;
imodObject.transparency = 0;
imodObject.nMeshes = 0;
imodObject.nSurfaces = 0;

imodObject.contour = {};
imodObject.mesh = {};
imodObject.surface = {};

imodObject.ambient=0;
imodObject.diffuse=0;
imodObject.specular=0;
imodObject.shininess=0;
imodObject.fillred=0;
imodObject.fillgreen=0;
imodObject.fillblue=0;
imodObject.quality=0;
imodObject.mat2=0;
imodObject.valblack=0;
imodObject.valwhite=0;
imodObject.matflags2=0;
imodObject.mat3b3=0;
