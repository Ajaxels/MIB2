% disp    Default display routine for ParticleStacks
%
%   display(particleStack)
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

function disp(stack)
  if stack.nParticles == -inf
    fprintf('Uninitialized ParticleStack\n');
  elseif stack.nParticles > 1
    fprintf('ParticleStack with %d %s particles of size %d^3\n',      ...
      stack.nParticles, stack.getModeString, stack.header.mX);
  else
    fprintf('ParticleStack with %d %s particle of size %d^3\n',       ...
      stack.nParticles, stack.getModeString, stack.header.mX);
  end
end
