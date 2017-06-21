function iDataset = createDataset(this, datatype, sizeX, sizeY, ...
     sizeZ, sizeC, sizeT, voxelSizeX, voxelSizeY, voxelSizeZ, deltaTime)
% IceImarisConnector:  createDataset (public method)
% 
% DESCRIPTION
% 
%   This method creates an Imaris dataset and replaces current one.
% 
% SYNOPSIS
%
%   (1) iDataset = createDataset(datatype, sizeX, sizeY, sizeZ, sizeC, sizeT)
%   (2) iDataset = createDataset(datatype, sizeX, sizeY, sizeZ, sizeC, sizeT, ...
%                                voxelSizeX, voxelsSizeY, voxelSizeZ, deltaTime)
% 
% INPUT
% 
%   datatype  : one of 'uint8', 'uint16', 'single', Imaris.tType.eTypeUInt8,
%               Imaris.tType.eTypeUInt16, Imaris.tType.eTypeFloat
%   sizeX     : dataset width
%   sizeY     : dataset height
%   sizeZ     : number of planes
%   sizeC     : number of channels
%   sizeT     : number of timepoints
%   voxelSizeX: (optional, default = 1) voxel size in X direction
%   voxelSizeY: (optional, default = 1) voxel size in Y direction
%   voxelSizeZ: (optional, default = 1) voxel size in Z direction
%   deltaTime : (optional, default = 1) time difference between consecutive
%               time points
% 
% OUTPUT
% 
%   iDataset  : created DataSet
%
% EXAMPLE
%
%    % Create a 2-by-3-by-2 stack
%    data(:, :, 1) = [ 11 12 13; 14 15 16 ];
%    data(:, :, 2) = [ 17 18 19; 20 21 22];
%    data = uint8(data);
%
%    % Create a dataset with sizeX = 3, sizeY = 2 and sizeZ = 2
%    conn.createDataset('uint8', 3, 2, 2, 1, 1);
%
%    % Copy data into the Imaris dataset
%    conn.setDataVolumeRM(data, 0, 0);
%
% REMARK
%
%   If you plan to set data volumes in column-major form, swap sizeX and
%   sizeY.

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

if nargin ~= 7 && nargin ~= 11
    % The this parameter is hidden
    error('6 or 10 input parameters expected.');
end

% Default voxel sizes
if nargin == 7
    voxelSizeX = 1;
    voxelSizeY = 1;
    voxelSizeZ = 1;
    deltaTime  = 1;
end

% Check inputs
if this.isAlive() == 0
    iDataset = [];
    return
end

% Imaris datatype
switch char(datatype)
    case {'uint8', 'eTypeUInt8'},
        classDataSet = Imaris.tType.eTypeUInt8;
    case {'uint16', 'eTypeUInt16'},
        classDataSet=Imaris.tType.eTypeUInt16;
    case {'single', 'eTypeFloat'},
        classDataSet=Imaris.tType.eTypeFloat;
    otherwise,
        error('Bad data type.');
end

% Create the dataset
iDataset = this.mImarisApplication.GetFactory().CreateDataSet();
iDataset.Create(classDataSet, sizeX, sizeY, sizeZ, sizeC, sizeT);

% Apply the spatial calibration
iDataset.SetExtendMinX(0);
iDataset.SetExtendMinY(0);
iDataset.SetExtendMinZ(0);
iDataset.SetExtendMaxX(sizeX * voxelSizeX);
iDataset.SetExtendMaxY(sizeY * voxelSizeY);
iDataset.SetExtendMaxZ(sizeZ * voxelSizeZ);

% Apply the temporal calibration
iDataset.SetTimePointsDelta(deltaTime);

% Set the dataset in Imaris
this.mImarisApplication.SetDataSet(iDataset);

end
