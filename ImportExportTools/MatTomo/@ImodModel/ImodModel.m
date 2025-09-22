%ImodModel      Imod model class definition and constructor
%
%   imodModel = ImodModel
%   imodModel = ImodModel(filename, flgVerbose)
%   imodModel = ImodModel(pointArray)
%
%   imodModel   The constructed ImodModel object.
%
%   filename    OPTIONAL: A string containing the name of the Imod model to
%               load.
%
%   pointArray  OPTIONAL: An array of 3D points to use for initializing the
%               model (3xN)
%
%
%   ImodModel instantiates a new ImodModel object.  If a filename is
%   supplied the ImodModel is initialized from that file.  If an array of points
%   is supplied then a model with one object and one contour containing those
%   points is constructed.
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

classdef ImodModel
  properties (Access = private)
    fid = [];
    filename = '';
    endianFormat = 'ieee-be';
    version = 'V1.2';

    name  = 'ImodModel';
    xMax = 0;
    yMax = 0;
    zMax = 0;
    nObjects = 0;
    flags = 0;
    drawMode = 1;
    mouseMode = 0;
    blackLevel = 0;
    whiteLevel = 255;
    xOffset = 0;
    yOffset = 0;
    zOffset = 0;
    xScale = 1.0;
    yScale = 1.0;
    zScale = 1.0;
    object = 0;
    contour = 0;
    point = 0;
    res = 3;
    thresh = 0;
    pixelSize = 1;
    units = 0;
    csum = 0;
    alpha = 0;
    beta = 0;
    gamma = 0;
    Objects = {};
    Views = {};
    MINX = [];
  end

  methods
    function imodModel = ImodModel(varargin)

      % Default constructor
      if length(varargin) < 1
        return;
      end
      flgDebug = 0;

      if ischar(varargin{1})
        % If its a string it should be the name of an IMOD model
        % file. If it is another ImodModel then do a copy
        if length(varargin) > 1
          flgDebug = varargin{2};
        end
        imodModel = open(imodModel, varargin{1}, flgDebug);
  
      elseif isnumeric(varargin{1})
        % If it is numeric it should be an 3xN array of points
  
        imodModel = appendObject(imodModel,                            ...
          appendContour(ImodObject, ImodContour(varargin{1})));
  
      elseif isa(varargin{1}, 'ImodModel')
        % Copy constructor
        imodModel = varargin{1};
      end
    end
  end
end
