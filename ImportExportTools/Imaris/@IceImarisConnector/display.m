function display(this)
% IceImarisConnector:  display (public method)
%
% DESCRIPTION
%
%   This method overloads standard display functionality.
%
% SYNOPSIS
%
%   conn.display()
%
% INPUT
%
%   None
%
% OUTPUT
% 
%   None

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

if isempty(this.mImarisApplication)
    disp('IceImarisConnector: not connected to an Imaris instance yet.');
else
    disp('IceImarisConnector: connected to Imaris.');
end

end
