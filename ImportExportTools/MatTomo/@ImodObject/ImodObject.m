%ImodObject    ImodObject class definition and constructor
%
%   imodObject = ImodObject
%   imodObject = ImodObject(fid)
%   imodObject = ImodObject(imodObject)
%
%   imodObject  The ImodObject
%
%   fid         A file descriptor of an open file with the pointer
%               at the start of an IMOD Object object.
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

classdef ImodObject
  properties (Access = private)
    name  = '';

    nContours = 0;
    flags = 0;
    axis = 0;
    drawMode = 1;
    red = 0.0;
    green = 0.0;
    blue = 0.0;
    pdrawsize = 0.0;
    symbol = 1;
    symbolSize = 3;
    lineWidth2D = 1;
    lineWidth3D = 1;
    lineStyle = 0;
    symbolFlags = 0;
    sympad = 0;
    transparency = 0;
    nMeshes = 0;
    nSurfaces = 0;

    contour = {};
    mesh = {};
    surface = {};

    ambient=0;
    diffuse=0;
    specular=0;
    shininess=0;
    fillred=0;
    fillgreen=0;
    fillblue=0;
    quality=0;
    mat2=0;
    valblack=0;
    valwhite=0;
    matflags2=0;
    mat3b3=0;
  end

  methods
    function imodObject = ImodObject(varargin)

      % Default constructor
      if length(varargin) < 1
        return;
      end

      % Single argument, if its a double it should be the file descriptor
      % of with the pointer at the start of an Imod Contour object if is
      % another ImodObject perform a copy construction
      if length(varargin) == 1
        if isa(varargin{1}, 'ImodObject')
          imodObject = varargin{1};
        else
          imodObject = freadObject(imodObject, fdes);
        end
      end
    end
  end
end
