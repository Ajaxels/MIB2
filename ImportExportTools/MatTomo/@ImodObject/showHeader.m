%showHeader     Display the ImodObject header
%
%   showHeader(imodObject)
%
%   imodObject  The ImodObject
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2025 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2025/01/02 17:09:20 $
%
%  $Revision: 03a2974f77e3 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function showHeader(imodObject, preString)

if nargin < 2
  preString = '';
end

fprintf('%sName: "%s"\n', preString, imodObject.name);
fprintf('%scontours: %d\n', preString, imodObject.nContours);
fprintf('%sflags: %d\n', preString, imodObject.flags);
fprintf('%saxis: %d\n', preString, imodObject.axis);
fprintf('%sdrawmode: %d\n', preString, imodObject.drawMode);
fprintf('%sred: %f\n', preString, imodObject.red);
fprintf('%sgreen: %f\n', preString, imodObject.green);
fprintf('%sblue: %f\n', preString, imodObject.blue);
fprintf('%spdrawsize: %d\n', preString, imodObject.pdrawsize);
fprintf('%ssymbol: %d\n', preString, imodObject.symbol);
fprintf('%ssymsize: %d\n', preString, imodObject.symbolSize);
fprintf('%slinewidth2: %d\n', preString, imodObject.lineWidth2D);
fprintf('%slinewidth: %d\n', preString, imodObject.lineWidth3D);
fprintf('%slinesty: %d\n', preString, imodObject.lineStyle);
fprintf('%ssymflags: %d\n', preString, imodObject.symbolFlags);
fprintf('%ssympad: %d\n', preString, imodObject.sympad);
fprintf('%strans: %d\n', preString, imodObject.transparency);
fprintf('%smeshsize: %d\n', preString, imodObject.nMeshes);
fprintf('%ssurfsize: %d\n', preString, imodObject.nSurfaces);
