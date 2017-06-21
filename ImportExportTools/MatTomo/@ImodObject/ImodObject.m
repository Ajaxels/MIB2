%ImodObject    ImodObject constructor
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

function imodObject = ImodObject(varargin)

% Default constructor
if length(varargin) < 1
  imodObject = genImodObjectStruct;
  imodObject = class(imodObject, 'ImodObject');
  return;
end

% Single argument, if its a double it should be the file descriptor
% of with the pointer at the start of an Imod Contour object if is
% another ImodObject perform a copy construction
if length(varargin) == 1
  imodObject = genImodObjectStruct;
  imodObject = class(imodObject, 'ImodObject');
  if isa(varargin{1}, 'ImodObject')
    imodObject = varargin{1};
  else
    imodObject = freadObject(imodObject, fdes);
  end
end

