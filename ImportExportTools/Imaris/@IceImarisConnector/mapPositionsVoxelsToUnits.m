function varargout = mapPositionsVoxelsToUnits(this, varargin)
% IceImarisConnector:  mapPositionsVoxelsToUnits (public method)
%
% DESCRIPTION
% 
%   This method maps voxel indices in dataset units to unit coordinates.
% 
% SYNOPSIS
% 
%   (1) pos = conn.mapPositionsVoxelsToUnits(vPos)
% 
%   (2) pos = ...
%          conn.mapPositionsVoxelsToUnits(vPosX, vPosY, vPosZ)
% 
%   (3) [posX, posY, posZ] = ...
%                         conn.mapPositionsVoxelsToUnits(vPos)
% 
%   (4) [posX, posY, posZ] = ...
%          conn.mapPositionsVoxelsToUnits(vPosX, vPosY, vPosZ)
% 
% INPUT
% 
%   (1) and (3):
% 
%   vPos  : (N x 3) matrix containing the X, Y, Z unit coordinates
%            mapped onto a voxel grid
% 
%   (2) and (4):
% 
%   vPosX : (M x 1) vector containing the X coordinates mapped onto a
%           voxel grid
%   vPosY : (N x 1) vector containing the Y coordinates mapped onto a
%           voxel grid
%   vPosZ : (O x 1) vector containing the Z coordinates mapped onto a
%           voxel grid
% 
%   M, N, a O will most likely be the same (and must be the same for 
%   synopsis 2).
% 
% OUTPUT
% 
%   (1) and (2):
% 
%   pos   : (N x 3) matrix containing the X, Y, Z coordinates in
%           dataset units
% 
%   (3) and (4):
% 
%   posX  : (M x 1) vector containing the X coordinates in dataset units
%   posY  : (N x 1) vector containing the Y coordinates in dataset units
%   posZ  : (O x 1) vector containing the Z coordinates in dataset units
% 
%   M, N, a O will most likely be the same.

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
    varargout{1} = [];
    return
end

% Number of inputs (without the IceImarisConnector object)
nInputs = numel(varargin);
if ~ismember(nInputs, [1 3])
    error('Bad number of input arguments.');
end

% Check and get the inputs
if nInputs == 1
    if size(varargin{1}, 2) ~= 3
        error('The input is expected to be an (N x 3) matrix.');
    end
    vPosX = varargin{1}(:, 1);
    vPosY = varargin{1}(:, 2);
    vPosZ = varargin{1}(:, 3);
end

if nInputs == 3
    if all([size(varargin{1}, 1) > 1 size(varargin{1}, 2) > 1])
        error('The input is expected to be a vector.');
    end
    if all([size(varargin{2}, 1) > 1 size(varargin{2}, 2) > 1])
        error('The input is expected to be a vector.');
    end
    if all([size(varargin{3}, 1) > 1 size(varargin{3}, 2) > 1])
        error('The input is expected to be a vector.');
    end
    vPosX = varargin{1};
    vPosY = varargin{2};
    vPosZ = varargin{3};
end

% Get voxel sizes
voxelSizes = this.getVoxelSizes();
if isempty(voxelSizes)
    if nargout == 0 || nargout == 1
        varargout{1} = [];
    elseif nargout == 2
        varargout{1} = [];
        varargout{2} = [];
    elseif nargout == 3
        varargout{1} = [];
        varargout{2} = [];
        varargout{3} = [];
    else
        error('Bad number of output arguments.');
    end
    return
end

% Unit positions X
posX = (vPosX - 0.5) .* ...
    voxelSizes(1) + this.mImarisApplication.GetDataSet().GetExtendMinX();

% Unit positions Y
posY = (vPosY - 0.5) .* ...
    voxelSizes(2) + this.mImarisApplication.GetDataSet().GetExtendMinY();

% Unit positions Z
posZ = (vPosZ - 0.5) .* ...
    voxelSizes(3) + this.mImarisApplication.GetDataSet().GetExtendMinZ();

if nargout == 0 || nargout == 1
    varargout{1} = [posX(:) posY(:) posZ(:)];
elseif nargout == 2
    varargout{1} = posX;
    varargout{2} = posY;
elseif nargout == 3
    varargout{1} = posX;
    varargout{2} = posY;
    varargout{3} = posZ;
else
    error('Bad number of output arguments.');
end

end
