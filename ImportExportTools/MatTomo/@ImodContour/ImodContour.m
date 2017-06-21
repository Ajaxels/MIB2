%ImodContour    ImodContour constructor
%
%   imodContour = ImodContour
%   imodContour = ImodContour(fid)
%   imodContour = ImodContour(imodContour)
%   imodContour = ImodContour(points)
%
%   imodContour The ImodContour object.
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD contour object.
%
%   points      The points of the contour in a 3 x N array.
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

function imodContour = ImodContour(varargin)

% Default constructor
if length(varargin) < 1
  imodContour = genImodContourStruct;
  imodContour = class(imodContour, 'ImodContour');
  return;
end


% If the argument is a double it is either a set of points or a file
% descriptor
if isa(varargin{1}, 'double')
  % Create the default object
  imodContour = genImodContourStruct;
  imodContour = class(imodContour, 'ImodContour');
  if numel(varargin{1}) == 1
    imodContour = freadContour(imodContour, varargin{1});
  else
    imodContour.points = varargin{1};
    imodContour.nPoints = size(varargin{1}, 2);
  end
elseif isa(varargin{1}, 'ImodContour')
  imodContour = varargin{1};
else
    PEETError(['Unknown constructor argument ' class(varargin{1})]);
end

