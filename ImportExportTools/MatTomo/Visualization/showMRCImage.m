%showMRCImage   Display a MRC Image in the correct orientation
%
%  showMRCImage(im, xvalue, yvalue)
%
%  im             The MRC Image slice to display
%
%  xvalue         OPTIONAL: The values of the x and y pixels repsectively
%  yvalue         (default: 1:nElements for each dimension)
%
%  showMRCImage performs a rot90 then a flipud on the image data to orient it
%  correctly in an MATLAB graphics window.
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

function showMRCImage(im, xvalue, yvalue)

[nX, nY] = size(im);

if nargin < 3
  yvalue = 1:nY;
end

if nargin < 2
  xvalue = 1:nX;
end

%  Columns and rows need to be reversed,  MATLAB represents an
%  image as a  matrix with rows indexed the fastest.  MRC images
%  are stored in raster form
set(gcf, 'Renderer', 'openGL')
imagesc(xvalue, yvalue, flipud(rot90(im)))
set(gca, 'ydir', 'normal');
axis('image')
xlabel('X axis');
ylabel('Y axis');

