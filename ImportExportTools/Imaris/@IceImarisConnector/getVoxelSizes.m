function varargout = getVoxelSizes(this)
% IceImarisConnector:  getVoxelSizes (public method)
%
% DESCRIPTION
% 
%   This method returns the X, Y, and Z voxel sizes of the dataset.
% 
% SYNOPSIS
%
%   (1)                         voxelSizes = conn.getVoxelSizes()
%   (2) [voxelSizeX voxelSizeY voxelSizeZ] = conn.getVoxelSizes()   
% 
% INPUT
% 
%   None
% 
% OUTPUT
%
%   (1) voxelSizes : vector of voxel sizes, [voxelSizeX voxelSizeY voxelSizeZ]  
% 
%   (2) voxelSizeX : voxel size in X direction
%       voxelSizeY : voxel size in Y direction
%       voxelSizeZ : voxel size in Z direction
%

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

% Is Imaris running?
if this.isAlive() == 0
    return
end

% Check whether we have a dataset at all
if isempty(this.mImarisApplication.GetDataSet())
    return;
end

% Voxel size X
vX = ...
    (this.mImarisApplication.GetDataSet().GetExtendMaxX() - ...
    this.mImarisApplication.GetDataSet().GetExtendMinX()) / ...
    this.mImarisApplication.GetDataSet().GetSizeX();

% Voxel size Y
vY = ...
    (this.mImarisApplication.GetDataSet().GetExtendMaxY() - ...
    this.mImarisApplication.GetDataSet().GetExtendMinY()) / ...
    this.mImarisApplication.GetDataSet().GetSizeY();

% Voxel size Z
vZ = ...
    (this.mImarisApplication.GetDataSet().GetExtendMaxZ() - ...
    this.mImarisApplication.GetDataSet().GetExtendMinZ()) / ...
    this.mImarisApplication.GetDataSet().GetSizeZ();

% Return the voxels sizes
if nargout <= 1
    
    % We return all voxel sizes as one vector in the first output parameter 
    varargout{1} = [vX vY vZ];
    
else
    
    % Independent voxel sizes
    varargout{1} = vX;
    varargout{2} = vY;
    varargout{3} = vZ;
    
end
