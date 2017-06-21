%EM2MRC         Convert and EM file or structure to MRCImage file or object
%
%   em2mrc(emFilename, MRCFilename)
%   em2mrc(emStruct, MRCFilename)
%   mRCImage = em2mrc(emFilename);
%   mRCImage = em2mrc(emStruct);
%
%   mRCImage    OPTIONAL: MRCImage object
%
%   emFilename  A string containing the name of the EM file.
%
%   emSruct     An EM structure as defined by the TOM toolbox
%
%   MRCFilename A string containing the name of the MRC file to write out
%
%   em2mrc will convert an EM file or structure to an MRCImage file or
%   object.  If no output argument is specified two arguments need to be
%   specified.
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

function mRCImage = em2mrc(varargin)

% Get the data volume from the EM object
if isa(varargin{1}, 'char')
  em = tom_emread(varargin{1});
  volume = em.Value;
elseif isa(varargin{1}, 'struct')
  volume = varargin{1}.Value;
else
  PEETError('The first argument must be either a filename or a struct!');
end

% TODO force the volume to a specific data type
mRCImage = MRCImage(volume);
if nargin > 1
  save(mRCImage, varargin{2});
end

