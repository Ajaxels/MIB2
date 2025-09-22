%ImodMINX    ImodMINX class definition and constructor
%
%   imodMINX = ImodMINX
%   imodMINX = ImodMINX(fid)
%   imodMINX = ImodMINX(imodMINX)
%
%   imodMINX The ImodMINX object.
%
%   fid         A file ID of an open file with the pointer at the start of 
%               an Imod MINX chunk.
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

classdef ImodMINX

  properties (Access = private)
    oldScale = zeros(1, 3, 'single');
    oldTrans = zeros(1, 3, 'single');
    oldRot = zeros(1, 3, 'single');
    scale = zeros(1, 3, 'single');
    trans = zeros(1, 3, 'single');
    rot = zeros(1, 3, 'single');
  end
    
  methods
    function imodMINX = ImodMINX(varargin)

      % Default constructor
      if length(varargin) < 1
        return;
      end

      % If the argument is a double it is either a set of points or a file
      % descriptor
      if isa(varargin{1}, 'ImodMINX')
        imodMINX = varargin{1};
      else
        imodMINX = freadMINx(imodMINX, varargin{1});
      end
    end
    
  end

end
