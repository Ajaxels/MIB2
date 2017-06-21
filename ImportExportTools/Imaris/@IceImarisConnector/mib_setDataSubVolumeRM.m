function mib_setDataSubVolumeRM(this, stack, x0, y0, z0, channel, timepoint, dx, dy, dz)
% Imaris Connector:  mib_setDataSubVolumeRM (public method)
% 
% DESCRIPTION
% 
%   This method sends the data subvolume to Imaris in row-major order.
%   Practically, this means that each plane of a 3D stack from MATLAB
%   is transposed before it is pushed back into Imaris to maintain the 
%   same geometry and orientation.
% 
% SYNOPSIS
% 
%   conn.mib_setDataSubVolumeRM(stack, x0, y0, z0, channel, timepoint, dx, dy, dz)
% 
% INPUT
%
%   stack      : 3D array of type uint8, uint16 or single
%   x0, y0, z0 : coordinates (0/1-based depending on indexing start) of
%                the top-left vertex of the subvolume to be sent.
%   channel    : channel number (0/1-based depending on indexing start)
%   timepoint  : timepoint number (0/1-based depending on indexing start)
%   dX, dY, dZ : extension of the subvolume to be sent
% 
% OUTPUT
% 
%   None
%
% REMARK
%
%   The dataset should be present in Imaris. Use this command before using this function,
%   iDataSet = conn.createDataset(class(stack), sz(1), sz(2), sz(3), 1, 1);

% Author: Ilya Belevich, based on setDataVolumeRM by Aaron Ponti

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

if nargin < 10
    % The this parameter is hidden
    error('9 input parameters expected.');
end

if this.isAlive() == 0
    return
end

% We first permute the stack
stack = permute(stack, [2 1 3]);

% We let setDataSubVolume do the parameter checking
this.mib_setDataSubVolume(stack, x0, y0, z0, channel, timepoint, dx, dy, dz);

end