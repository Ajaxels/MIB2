%getDefaultColor   Return the default color in the object color sequence 
%
%   color = getDefaultColor(imodModel, idxObject)
%
%   color       The color of the object
%
%   imodModel   The ImodModel object
%
%   idxObject   The index of the object
%
%   getDefaultColor returns the color for the given object index that cycles
%   around the red-yellow-green-cyan-blue-magenta color sequence.
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

function color = getDefaultColor(imodModel, idxObject) %#ok<INUSL>

% Default Colors for Objects 
 listColor = [ ... 
    0.0, 1.0, 0.0    % Green       
    0.0, 1.0, 1.0    % Cyan       
    1.0, 0.0, 1.0    % Magenta    
    1.0, 1.0, 0.0    % Yellow      
    0.0, 0.0, 1.0    % Blue       
    1.0, 0.0, 0.0    % Red        
    0.0, 1.0, 0.5
    0.2, 0.2, 0.8
    0.8, 0.2, 0.2
    0.9, 0.6, 0.4
    0.6, 0.4, 0.9
    0.1, 0.6, 0.4
    0.6, 0.1, 0.4
    0.2, 0.6, 0.8
    1.0, 0.5, 0.0
    0.4, 0.6, 0.1
    0.1, 0.1, 0.6
    0.9, 0.9, 0.4
    0.9, 0.4, 0.6
    0.4, 0.9, 0.9
    0.6, 0.2, 0.2
    0.2, 0.8, 0.6
    0.4, 0.6, 0.9
    0.1, 0.6, 0.1
    0.8, 0.5, 0.2
    1.0, 0.0, 0.5
    0.0, 0.5, 1.0
    0.6, 0.2, 0.8
    0.5, 1.0, 0.0
    0.1, 0.4, 0.6
    0.6, 0.4, 0.1
    0.8, 0.2, 0.6
    0.4, 0.1, 0.6
    0.2, 0.8, 0.2
    0.9, 0.4, 0.9
  ];
nColors = size(listColor, 1);

idxColor = rem(idxObject - 1, nColors) + 1;
color = listColor(idxColor, :);
