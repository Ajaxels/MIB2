%showHeader     Display the model header
%
%   showHeader(imodModel)
%
%   imodModel   The ImodModel object.
%
%   ImodModel.showHeader will display the header of supplied ImodModel object.
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

function showHeader(imodModel)

fprintf('Name: %s\n', imodModel.name);
fprintf('xMax %d\n', imodModel.xMax);
fprintf('yMax %d\n', imodModel.yMax);
fprintf('zMax %d\n', imodModel.zMax);
fprintf('nObjects %d\n', imodModel.nObjects);
fprintf('flags %d\n', imodModel.flags);
fprintf('drawMode %d\n', imodModel.drawMode);
fprintf('mouseMode %d\n', imodModel.mouseMode);
fprintf('blackLevel %d\n', imodModel.blackLevel);
fprintf('whiteLevel %d\n', imodModel.whiteLevel);
fprintf('xOffset %f\n', imodModel.xOffset);
fprintf('yOffset %f\n', imodModel.yOffset);
fprintf('zOffset %f\n', imodModel.zOffset);
fprintf('xScale %f\n', imodModel.xScale);
fprintf('yScale %f\n', imodModel.yScale);
fprintf('zScale %f\n', imodModel.zScale);
fprintf('object %d\n', imodModel.object);
fprintf('contour %d\n', imodModel.contour);
fprintf('point %d\n', imodModel.point);
fprintf('res %d\n', imodModel.res);
fprintf('thresh %d\n', imodModel.thresh);
fprintf('pixelSize %f\n', imodModel.pixelSize);
fprintf('units %d\n', imodModel.units);
fprintf('csum %d\n', imodModel.csum);
fprintf('alpha %d\n', imodModel.alpha);
fprintf('beta %d\n', imodModel.beta);
fprintf('gamma %d\n', imodModel.gamma);
