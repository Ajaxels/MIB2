function b = isSupportedPlatform()
% IceImarisConnector:  version (public static method)
% 
% DESCRIPTION
% 
% This method checks whether IceImarisConnector is running on a supported
% platform.
% 
% SYNOPSIS
% 
%   b = IceImarisConnector.isSupportedPlatform()
% 
% INPUT
% 
%   None
% 
% OUTPUT
% 
%   b : 1 if IceImarisConnector is running on a supported platform, 0
%       otherwise

% AUTHORS
%
% Author: Aaron Ponti

% LICENSE
%
% ImarisConnector is a simple commodity class that eases communication between 
% Imaris and MATLAB using the Imaris XT interface.
% Copyright (C) 2011  Aaron Ponti
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

b = ismac() || ispc();

end
