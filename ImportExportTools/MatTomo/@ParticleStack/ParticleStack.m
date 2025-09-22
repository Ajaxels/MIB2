classdef ParticleStack < MRCImage
% ParticleStack - an MRCImage containing >1 cubical subvolumes (particles)
%  It provides more efficient input from disk
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

  properties (Access = protected)
    nParticles = -Inf;
  end

  methods
    function stack = ParticleStack(varargin)
      % Supported constructors:
      %
      %   ParticleStack()
      %   ParticleStack(fname)
      %   ParticleStack(fname, flgLoad)
      %     open an existing ParticleStack; flgLoad defaults to false
      %
      %   ParticleStack(volume)
      %     create an in-memory ParticleStack from an in-memory volume
      %
      %   ParticleStack(particleStack)
      %   ParticleStack(particleStack, fname)
      %     copy constructor with optional file duplication
      %
      %   ParticleStack(MRCImage)
      %   ParticleStack(MRCImage, filename)
      %     Initialize from existing MRCImage with optional duplication
      %
      %   ParticleStack(particle1, nParticles, voxelSizes);
      %   ParticleStack(particle1, nParticles, voxelSizes, fname);
      %     create an on-disk ParticleStack from the 1st particle
      %
      % Unlike MRCImage, ParticleStack does not allow construction from a 
      % a header only.
      
      % Disallow  construction from a header
      if nargin >= 1 && isa(varargin{1}, 'struct')
        PEETError('Illegal argument to ParticleStack');
      end

      % Matlab does not dispatch on signatures and does not allow 
      % conditional calls to parent class constructors. Fortunately, 
      % the MRCImage constructor ignores unexpected extra arguments.

      if nargin >= 1
        % Sanity checks for initialization from volume or particle
        if isnumeric(varargin{1}) || islogical(varargin{1})
          if nargin == 3 || nargin == 4  % varargin{1} is a particle
            szParticle = size(varargin{1});
            if length(szParticle) ~= 3 ||                              ...
                any(szParticle(1) ~= szParticle(2:3))
              PEETError('Particles must be cubical!');
            end
          else             % varargin{1} is a volume
            szVol = size(varargin{1});
            valid = (length(szVol) == 3) && (szVol(1) == szVol(2));
            n = floor(szVol(3) / szVol(1));
            valid = valid && (n * szVol(1) == szVol(3));
            if ~valid
              PEETError('Volume must contain cubical particles!');
            end
          end
        end
      end

      % Call the parent  constructor
      stack = stack@MRCImage(varargin{:});
      stack.header.spaceGroup = 401;

      % Default constructor (no arguments)
      if nargin < 1
        return;
      end

      % Finish processing for initialization from a particle
      if nargin == 3 || nargin == 4
        % If the user passed just a single pixel / voxel size, assume they
        % mean for it to apply to all 3 dimensions
        if length(varargin{3}) == 1
          varargin{3} = varargin{3} * ones(1, 3);
        end
        stack = stack.setPixelSize(varargin{3});
        stack = stack.setNZ(varargin{2} * stack.header.mZ);
        stack.nParticles = varargin{2};
        stack.header.minDensity = -Inf;
        stack.header.meanDensity = -Inf;
        stack.header.maxDensity = -Inf;
        stack.header.densityRMS = -Inf;
        if nargin == 4
          stack = save(stack, varargin{4}, 0);
        end
        return
      end

      % Final sanity checks and set nParticles for other cases
      n = stack.header.nZ / stack.header.mZ;
      if n > 1             % nZ already set for particle stack              
        if floor(n) ~= n
          PEETError('Stack must contain cubical particles!');
        end
      else                 % nZ not yet set
        valid = (stack.header.mX == stack.header.mY);
        n = floor(stack.header.mZ / stack.header.mX);
        valid = valid && (n * stack.header.mX == stack.header.mZ);
        if ~valid
            PEETError('Volume must contain cubical particles!');
        end
        stack.header.mZ = stack.header.mX;
      end
      stack.nParticles = n;
    end
  end
end
