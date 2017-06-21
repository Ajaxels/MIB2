function alive = isAlive(this)
% IceImarisConnector:  isAlive (public method)
%
% DESCRIPTION
% 
%   This method checks whether the (stored) connection to Imaris is 
%   still alive.
% 
% SYNOPSIS
% 
%   alive = conn.isAlive()
% 
% INPUT
% 
%   None
% 
% OUTPUT
% 
%   alive : 1 if the connection is still alive, 0 otherwise

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

alive = false;
if isempty(this.mImarisApplication)
    return
end
try
    this.mImarisApplication.GetVersion();
    alive = true;
catch ex %#ok<NASGU>
    % Silent exception
    this.mImarisApplication = [];
    alive = false;
end

end
