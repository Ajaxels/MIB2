%ImodModel      Imod model constructor
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

function imodModel = ImodModel(varargin)

% Default constructor
if length(varargin) < 1
  imodModel = genImodModelStruct;
  imodModel = class(imodModel, 'ImodModel');
  return;
end
flgDebug = 0;

if ischar(varargin{1})
  % If its a string it should be the name of the
  % MRCImage file, if it is another MRCImage then do a copy
  if nargin > 1
    flgDebug = varargin{2};
  end
  imodModel = genImodModelStruct;
  imodModel = class(imodModel, 'ImodModel');
  imodModel = open(imodModel, varargin{1}, flgDebug);
  
elseif isnumeric(varargin{1})
  % If it is numeric it should be an 3xN array of points
  imodModel = genImodModelStruct;
  imodModel = class(imodModel, 'ImodModel');
  imodModel = appendObject(imodModel, appendContour(ImodObject, ImodContour(varargin{1})));
  
elseif isa(varargin{1}, 'ImodModel');
  % Copy constructor
  imodModel = varargin{1};
end
