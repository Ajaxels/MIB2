% getParticle    Return the nth particle (1-based) in the stack
%
%   particle = getParticle(particleStack, n)
%
%   Bugs: none known
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

function particle = getParticle(stack, n)
  if n < 1 || n > stack.nParticles
    PEETError('Requested particle number is out of range!');
  end
  zStart = 1 + (n - 1) * stack.header.mZ;
  zEnd = zStart + stack.header.mZ - 1;
  particle = getVolume(stack, [1, stack.header.mX],                    ...
                       [1, stack.header.mY], [zStart, zEnd]);
end
