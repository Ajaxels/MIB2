%cntShow        Show a inverted, smoothed, countour slice view of a volume

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
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cntShow(volume)
clf
set(gcf, 'Renderer', 'OpenGL')
% invert the volume since we are negatively stained
volInv = double(max(volume(:))) - double(volume);

% smooth the volume
volInvSm = smooth3(volInv);

cntVol = volInvSm;

maxVal = max(cntVol(:));
nX = size(cntVol,1);
nY = size(cntVol,2);
nZ = size(cntVol,3);


%subplot(2,1,1)
contourslice(cntVol, 1:nX, 1:nY, 1:nZ, 0.75 * [maxVal maxVal]);
grid on
view([45 45])

xlabel('X Axis');
ylabel('Y Axis');
zlabel('Z Axis');

%
%subplot(2,1,2)
%contourslice(cntVol, [], [1:9], [], [maxVal*0.5 maxVal*0.75]);
%grid on

