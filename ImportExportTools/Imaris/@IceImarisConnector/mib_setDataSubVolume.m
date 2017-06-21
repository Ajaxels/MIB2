function mib_setDataSubVolume(this, stack, x0, y0, z0, channel, timepoint, dx, dy, dz)
% IceImarisConnector:  mib_setDataSubVolume (public method)
% 
% DESCRIPTION
% 
%   This method sets the data subvolume to Imaris.
% 
% SYNOPSIS
% 
%   conn.mib_setDataSubVolume(stack, x0, y0, z0, channel, timepoint, dx, dy, dz)
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
%   none
%
% REMARK
%
%   The dataset should be present in Imaris. Use this command before using this function,
%   iDataSet = conn.createDataset(class(stack), sz(1), sz(2), sz(3), 1, 1);

% AUTHORS
%
% Author: Ilya Belevich, based on setDataVolume by Aaron Ponti and Jonas Dorn

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

if nargin ~= 10
    % The this parameter is hidden
    error('9 input parameters expected.');
end

% Make sure that there is no mismatch with indexingStart
if channel < 1 && this.mIndexingStart == 1
    error('Channel cannot be < 1 if indexingStart is 1.');
end
if timepoint < 1 && this.mIndexingStart == 1
    error('Timepoint cannot be < 1 if indexingStart is 1.');
end

if this.isAlive() == 0
    return
end

% Create an alias
iDataSet = this.mImarisApplication.GetDataSet();

% Check whether we have some voxels in the dataset
if isempty(iDataSet)
    error(sprintf('Please create a dataset first!\nUse:\niDataSet = conn.createDataset(class(stack), sz(1), sz(2), sz(3), 1, 1);'));
    % Create and store a new dataset
    % sz = size(stack);
    % if numel(sz) == 2
    %     sz = [sz 1];
    % end
    % iDataSet = this.createDataset(class(stack), sz(1), sz(2), sz(3), 1, 1);

end

% Convert channel and timepoint to 0-based indexing
channel = channel - this.mIndexingStart;
timepoint = timepoint - this.mIndexingStart;

% Check that the requested channel and timepoint exist
if channel > (iDataSet.GetSizeC() - 1)
    error('The requested channel index is out of bounds.');
end
if timepoint > (iDataSet.GetSizeT() - 1)
    error('The requested time index is out of bounds.');
end

% Get the dataset class
switch char(iDataSet.GetType())
    case 'eTypeUInt8',  outDatatype = 'uint8';
    case 'eTypeUInt16', outDatatype = 'uint16';
    case 'eTypeFloat',  outDatatype = 'single';
    otherwise,
        error('Bad value for iDataSet.GetType().');
end

% Check that the input and output datatypes match
if ~isa(stack, outDatatype)
    error('Data type mismatch.');
end

% Check that the size matches
outSizes = this.getSizes();
if x0+dx > outSizes(1) || y0+dy > outSizes(2) || z0+dz > outSizes(3)
    error('Sub volume is out of borders of the existing volume');
end

% Set the stack
switch char(iDataSet.GetType())
    case 'eTypeUInt8',   
        iDataSet.SetDataSubVolumeAs1DArrayBytes(stack(:), ...
            x0, y0, z0, channel, timepoint, dx, dy, dz);
    case 'eTypeUInt16',
        iDataSet.SetDataSubVolumeAs1DArrayShorts(stack(:), ...
            x0, y0, z0, channel, timepoint, dx, dy, dz);
    case 'eTypeFloat',
        iDataSet.SetDataSubVolumeAs1DArrayFloats(stack(:), ...
            x0, y0, z0, channel, timepoint, dx, dy, dz);
    otherwise,
        error('Bad value for iDataSet.GetType().');
end

end
