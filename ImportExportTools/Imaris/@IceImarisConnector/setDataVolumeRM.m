function setDataVolumeRM(this, stack, channel, timepoint)
% Imaris Connector:  setDataVolumeRM (public method)
% 
% DESCRIPTION
% 
%   This method sends the data volume to Imaris in row-major order.
%   Practically, this means that each plane of a 3D stack from MATLAB
%   is transposed before it is pushed back into Imaris to maintain the 
%   same geometry and orientation.
% 
% SYNOPSIS
% 
%   conn.setDataVolumeRM(stack, channel, timepoint)
% 
% INPUT
%
%   stack    : 3D array of type uint8, uint16 or single
%   channel  : channel number (0/1-based depending on indexing start)
%   timepoint: timepoint number (0/1-based depending on indexing start)
% 
% OUTPUT
% 
%   None
%
% REMARK
%
%   If a dataset exists, the X, Y, and Z dimensions must match the ones of 
%   the stack being copied in. If no dataset exists, one will be created
%   to fit it with default other values.

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

if nargin < 3
    % The this parameter is hidden
    error('2 input parameters expected.');
end

if this.isAlive() == 0
    return
end

% We first permute the stack
stack = permute(stack, [2 1 3]);

% We let setDataVolume do the parameter checking
this.setDataVolume(stack, channel, timepoint);

end
