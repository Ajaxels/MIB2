% setParticle    set the nth particle (1-based) in the stack
%
%   particleStack = setParticle(particleStack, n, particle)
%
%   Bugs: (Not really a bug). We could automatically grow the particle
%         stack if n is too large. MRCImage.setSubvolume would have to be 
%         modified to support this.
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2025 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2025/01/02 17:09:20 $
%
%  $Revision: 03a2974f77e3 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function stack = setParticle(stack, n, particle)
  if n < 1 || n > stack.nParticles
    PEETError('Requested particle number is out of range!');
  end
  szParticle = size(particle);
  if (szParticle(1) ~= stack.header.mX ||                              ...
      szParticle(2) ~= stack.header.mY ||                              ...
      szParticle(3) ~= stack.header.mZ)  
    PEETError('Incorrect particle size for this ParticleStack!');
  end
  startIndices = [1, 1, (n-1) * stack.header.mZ + 1];
  center = startIndices + floor(szParticle / 2);
  stack = setSubvolume(stack, particle, center, 1);
end
