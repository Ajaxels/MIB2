%showMRCContour   Display a contour map of a single MRC Image 
%
%  showMRCContour(im, contourArgs)
%
%  im             The MRC Image slice to display
%
%  contourArgs    All remaining arguments are passed to the contour command
%
%  showMRCContour performs a rot90 then a flipud on the image data to orient it
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

function showMRCContour(im, varargin)

%  Columns and rows need to be reversed,  MATLAB represents an
%  image as a  matrix with rows indexed the fastest.  MRC images
%  are stored in raster form
set(gcf, 'Renderer', 'openGL')
contour(flipud(rot90(im)), varargin{:})
set(gca, 'ydir', 'normal');
axis('image')
xlabel('X axis');
ylabel('Y axis');

