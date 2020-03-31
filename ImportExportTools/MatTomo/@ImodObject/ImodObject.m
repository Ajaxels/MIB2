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

