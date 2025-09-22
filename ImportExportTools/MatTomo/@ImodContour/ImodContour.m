%ImodContour    ImodContour class definition and constructor
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

classdef ImodContour
  properties (Access = private)
    nPoints = 0;
    flags = 0;
    time = 0;
    iSurface = 0;
    points = [];
    pointSizes = [];
  end
    
  methods
    function imodContour = ImodContour(varargin)

      % Default constructor
      if length(varargin) < 1
        return;
      end

      % If the argument is a double it is either a set of points or a file
      % descriptor
      if isa(varargin{1}, 'double')
        % Create the default object
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
    end
  end

end
