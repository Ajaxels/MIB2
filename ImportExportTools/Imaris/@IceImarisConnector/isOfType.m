function b = isOfType(this, object, type)
% IceImarisConnector:  isOfType (private method)
%
% DESCRIPTION
% 
%   This method checks that a passed object is of a given type.
% 
% SYNOPSIS
% 
%   b = conn.isOfType(object, type)
% 
% INPUT
% 
%   object : any surpass scene object
%
%   type   : one of:
%
%               'Cells'
%               'ClippingPlane'
%               'Dataset'
%               'Filaments'
%               'Frame'
%               'LightSource'
%               'MeasurementPoints'
%               'Spots'
%               'Surfaces'
%               'SurpassCamera'
%               'Volume'
% 
% OUTPUT
% 
%   b : 1 if the object is of the type specified, 0 otherwise

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

% Check input parameters number and values
if nargin ~= 3
    error('2 input parameters expected.');
end

% Check type
typeValues = {'Cells', 'ClippingPlane', 'Dataset', 'Filaments', ...
    'Frame', 'LightSource', 'MeasurementPoints', 'Spots', ...
    'Surfaces', 'SurpassCamera', 'Volume'};
if ~ismember(type, typeValues)
    error('Bad value for input parameter ''type''.');
end

% Test the object
switch type
    case 'Cells',
        b = this.mImarisApplication.GetFactory().IsCells(object);
    case 'ClippingPlane',
        b = this.mImarisApplication.GetFactory().IsClippingPlane(object);
    case 'Dataset',
        b = this.mImarisApplication.GetFactory().IsDataset(object);
    case 'Filaments',
        b = this.mImarisApplication.GetFactory().IsFilaments(object);
    case 'Frame',
        b = this.mImarisApplication.GetFactory().IsFrame(object);
    case 'LightSource',
        b = this.mImarisApplication.GetFactory().IsLightSource(object);
    case 'MeasurementPoints',
        b = this.mImarisApplication.GetFactory().IsMeasurementPoints(object);
    case 'Spots',
        b = this.mImarisApplication.GetFactory().IsSpots(object);
    case 'Surfaces',
        b = this.mImarisApplication.GetFactory().IsSurfaces(object);
    case 'SurpassCamera',
        b = this.mImarisApplication.GetFactory().IsSurpassCamera(object);
    case 'Volume',
        b = this.mImarisApplication.GetFactory().IsVolume(object);
    otherwise,
        error('Bad value for ''type''.');
end

end
