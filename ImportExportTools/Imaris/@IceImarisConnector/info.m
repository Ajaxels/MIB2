function info(this)
% IceImarisConnector:  info (public method)
%
% DESCRIPTION
%
%   This methods displays the full paths to the Imaris and ImarisServer
%   executables and the ImarisLib jar archive.
%
% SYNOPSIS
%
%   conn.info()
%
% INPUT
%
%   None
%
% OUTPUT
%
%   None
%
% REMARK
%
% A summary of the object properties is output to console.

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

% Display info
disp(['IceImarisConnector version ', this.version(), ' using:']);
disp(['- Imaris path: ', this.mImarisPath]); 
disp(['- Imaris executable: ', this.mImarisExePath]); 
disp(['- ImarisServer executable: ', this.mImarisServerExePath]); 
disp(['- ImarisLib.jar archive: ', this.mImarisLibPath]); 
