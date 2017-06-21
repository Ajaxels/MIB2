function stack = getDataSubVolumeRM(this, x0, y0, z0, channel, timepoint, dX, dY, dZ, iDataSet)
% Imaris Connector:  getDataSubVolumeRM (public method)
% 
% DESCRIPTION
% 
%   This method returns the data subvolume from Imaris in row-major order.
%   Practically, this means that each plane of a 3D stack is transposed
%   and will display in a plot in MATLAB with the same geometry and
%   orientation as in Imaris.
% 
% SYNOPSIS
% 
%   (1) stack = conn.getDataSubVolumeRM(x0, y0, z0, channel, timepoint, ...
%                                         dX, dY, dZ)
%   (2) stack = conn.getDataSubVolumeRM(x0, y0, z0, channel, timepoint, ...
%                                         dX, dY, dZ, iDataSet)
%
%   Please notice that the coordinates (x0, y0, z0) and the extension
%   (dX, dY, dZ) point to the same subvolume in the Imaris dataset. What
%   changes is the order by which it is returned to MATLAB.
% 
% INPUT
% 
%   x0, y0, z0: coordinates (0/1-based depending on indexing start) of
%               the top-left vertex of the subvolume to be returned
%   channel   : channel number (0/1-based depending on indexing start)
%   timepoint : timepoint number (0/1-based depending on indexing start)
%   dX, dY, dZ: extension of the subvolume to be returned
%   dataset   : (optional) get the data volume from the passed IDataset
%               object instead of current one; if omitted, current dataset
%               (i.e. this.mImarisApplication.GetDataSet()) will be used.
%               This is useful for instance when masking channels.
% 
%   Coordinates and extension are in voxels and not in units!
%
%   The following holds:
%
%   if conn.indexingStart == 0:
%   
%       subA = conn.getDataSubVolumeRM(x0, y0, z0, 0, 0, dX, dY, dZ);
%       A = conn.getDataVolumeRM(0, 0);
%       A(y0 + 1 : y0 + dY, x0 + 1 : x0 + dX, z0 + 1 : z0 + dZ) === subA 
%     
%       Please notice the x - y dimension swap.
%
%   if conn.indexingStart == 1:
%   
%       subA = conn.getDataSubVolumeRM(x0, y0, z0, 1, 1, dX, dY, dZ);
%       A = conn.getDataVolumeRM(1, 1);
%       A(y0 : y0 + dY - 1, x0 : x0 + dX - 1, z0 : z0 + dZ - 1) === subA 
%
%       Please notice the x - y dimension swap.
%
% OUTPUT
% 
%   stack    : data subvolume (3D matrix)

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

if nargin < 9 || nargin > 10
    % The this parameter is hidden
    error('8 or 9 input parameters expected.');
end

% Initialize stack
stack = [];

if this.isAlive() == 0
    return
end

% We let getDataSubVolume do the parameter checking
if nargin == 9
    stack = this.getDataSubVolume(x0, y0, z0, channel, timepoint, ...
        dX, dY, dZ);
else
    stack = this.getDataSubVolume(x0, y0, z0, channel, timepoint, ...
        dX, dY, dZ, iDataSet);
end

% Now we permute the stack
stack = permute(stack, [2 1 3]);

end
