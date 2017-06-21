function type = getMatlabDatatype(this)
% IceImarisConnector:  getMatlabDatatype (public method)
%
% DESCRIPTION
% 
%   This method returns the datatype of the dataset as a MATLAB type 
%   (e.g. one of 'uint8', 'uint16', 'single').
% 
% SYNOPSIS
% 
%   type = conn.getMatlabDatatype()
% 
% INPUT
% 
%   None
% 
% OUTPUT
% 
%   type : datatype of the dataset as a MATLAB type: one of one of 'uint8',
%          'uint16', 'single', or '' if the type is unknown in Imaris.

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

type = '';

% Is Imaris running?
if this.isAlive() == 0
    return
end

% Which datatype?
switch char(this.mImarisApplication.GetDataSet().GetType())
    case 'eTypeUInt8',
        type  = 'uint8';
    case 'eTypeUInt16',
        type  = 'uint16';
    case 'eTypeFloat',
        type  = 'single';
    case 'eTypeUnknown',
        type = '';
    otherwise,
        type = '';
end

end
