%showMovie      Display a movie of the planes in a volume or MRCImage object
%
%   [et fps] = showMovie(volume, nCycle)
%
%   et          The total time to execute the movie
%
%   fps         The frames per second the movie was displayed at.
%
%   volume      The volume to display, either a 3D array or an MRCImage object.
%   
%
%   Bugs: need to find the best most efficient way to render the images
%         is the image oriented correctly
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

function [et fps] = showMovie(volume, nCycle)

if nargin < 2
  nCycle = 1;
end 
set(gcf, 'Renderer', 'opengl')
if isa(volume, 'double')
  %nz = size(volume, 3);
  vMax = max(volume(:));
  vMin = min(volume(:));
  cidx = uint8((volume - vMin) ./ (vMax - vMin) * 255);
else
  hdr = getHeader(volume);
  vMin = hdr.minDensity;
  vMax = hdr.maxDensity;
  
  cidx = uint8((getVolume(volume, [], [], []) - vMin) ./ (vMax - vMin) * 255);
end 
hImage = image(flipud(rot90(cidx(:, :, 1))), 'EraseMode','none');
set(gca, 'ydir', 'normal');

set(gca, 'units', 'pixels')
axis('image')

st = clock;
for iCylce = 1:nCycle
  for iz = 1:10
    set(hImage, 'CData', flipud(rot90(cidx(:, :, iz))))
    drawnow
  end 
end
et = etime(clock, st);
fps = 10 * nCycle / et;

