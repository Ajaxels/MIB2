function stack = getDataSubVolume(this, x0, y0, z0, channel, timepoint, dX, dY, dZ, iDataSet)
% IceImarisConnector:  getDataSubVolume (public method)
% 
% DESCRIPTION
% 
%   This method returns a data subvolume from Imaris.
% 
% SYNOPSIS
% 
%   (1) stack = conn.getDataSubVolume(x0, y0, z0, channel, timepoint, ...
%                                         dX, dY, dZ)
%   (2) stack = conn.getDataSubVolume(x0, y0, z0, channel, timepoint, ...
%                                         dX, dY, dZ, iDataSet)
% 
% INPUT
% 
%   x0, y0, z0: coordinates (0/1-based depending on indexing start) of
%               the top-left vertex of the subvolume to be returned.
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
%       subA = conn.getDataSubVolume(x0, y0, z0, 0, 0, dX, dY, dZ);
%       A = conn.getDataVolume(0, 0);
%       A(x0 + 1 : x0 + dX, y0 + 1 : y0 + dY, z0 + 1 : z0 + dZ) === subA 
%       
%
%   if conn.indexingStart == 1:
%   
%       subA = conn.getDataSubVolume(x0, y0, z0, 1, 1, dX, dY, dZ);
%       A = conn.getDataVolume(1, 1);
%       A(x0 : x0 + dX - 1, y0 : y0 + dY - 1, z0 : z0 + dZ - 1) === subA 
%
% OUTPUT
% 
%   stack    : data subvolume (3D matrix)
%
% REMARK
%
%   This function gets the volume as a 1D array and reshapes it in place.
%   It also performs a type cast to take care of the signed/unsigned int
%   mismatch when transferring data over Ice. The speed-up compared to
%   calling the ImarisXT GetDataVolumeBytes() or GetDataVolumeWords() 
%   methods is of the order of 20x.

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

if nargin < 9 || nargin > 10
    % The this parameter is hidden
    error('8 or 9 input parameters expected.');
end
 
% Initialize stack
stack = [];

if this.isAlive() == 0
    return
end

if nargin == 9
    iDataSet = this.mImarisApplication.GetDataSet();
else
    % Is the passed dataset a valid DataSet?
    if ~this.mImarisApplication.GetFactory().IsDataSet(iDataSet)
        error('Invalid IDataset object.');
    end
end

% Check whether we have some voxels in the dataset
if isempty(iDataSet) || iDataSet.GetSizeX() == 0
    return
end

% Convert all dimensions to 0-based indexing
x0 = x0 - this.mIndexingStart;
if x0 < 0 || x0 > iDataSet.GetSizeX() - 1
   error('The requested starting position x0 is out of bounds.');
end
x0 = uint32(x0);

y0 = y0 - this.mIndexingStart;
if y0 < 0 || y0 > iDataSet.GetSizeY() - 1
   error('The requested starting position y0 is out of bounds.');
end
y0 = uint32(y0);

z0 = z0 - this.mIndexingStart;
if z0 < 0 || z0 > iDataSet.GetSizeZ() - 1
   error('The requested starting position z0 is out of bounds.');
end
z0 = uint32(z0);

channel = channel - this.mIndexingStart;
if channel < 0 || channel > iDataSet.GetSizeC() - 1
   error('The requested channel index is out of bounds.');
end
channel = uint32(channel);

timepoint = timepoint - this.mIndexingStart;
if timepoint < 0 || timepoint > iDataSet.GetSizeT() - 1
   error('The requested timepoint index is out of bounds.');
end
timepoint = uint32(timepoint);

% Check that we are within bounds
if x0 + dX > iDataSet.GetSizeX()
    error('The requested x range dimension is out of bounds.');
end

if y0 + dY > iDataSet.GetSizeY()
    error('The requested x range dimension is out of bounds.');
end

if z0 + dZ > iDataSet.GetSizeZ()
    error('The requested x range dimension is out of bounds.');
end

% Get the dataset class
switch char(iDataSet.GetType())
    case 'eTypeUInt8',   datatype = 'uint8';
    case 'eTypeUInt16',  datatype = 'uint16';
    case 'eTypeFloat',   datatype = 'single';
    otherwise,
        error('Bad value for IDataSet::GetType().');
end

% Allocate memory
stack = zeros([dX, dY, dZ], datatype);

% Get the stack
switch char(iDataSet.GetType())
    case 'eTypeUInt8',   
        % Java does not have unsigned ints
        arr = iDataSet.GetDataSubVolumeAs1DArrayBytes(x0, y0, z0, ...
            channel, timepoint, dX, dY, dZ);
        stack(:) = typecast(arr, 'uint8');
    case 'eTypeUInt16',
        % Java does not have unsigned ints
        arr = iDataSet.GetDataSubVolumeAs1DArrayShorts(x0, y0, z0, ...
            channel, timepoint, dX, dY, dZ);
        stack(:) = typecast(arr, 'uint16');
    case 'eTypeFloat',
        stack(:) = ...
            iDataSet.GetDataSubVolumeAs1DArrayFloats(x0, y0, z0, ...
            channel, timepoint, dX, dY, dZ);
    otherwise,
        error('Bad value for iDataSet.GetType().');
end

end
