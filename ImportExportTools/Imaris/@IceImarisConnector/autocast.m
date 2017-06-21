function derivedType = autocast(this, IDataItem)
% IceImarisConnector:  autocast (public method)
% 
% DESCRIPTION
% 
%   This method casts IDataItems to their derived types
% 
% SYNOPSIS
% 
%   derivedType = conn.autocast(IDataItem)
% 
% INPUT
% 
%   IDataItem: an Imaris::IDataItem object
% 
% OUTPUT
% 
%   derivedType : one of the Imaris::IDataItem subclasses:
%                                 - Imaris::IClippingPlane
%                                 - Imaris::IDataContainer
%                                 - Imaris::IFilaments
%                                 - Imaris::IFrame
%                                 - Imaris::IDataSet
%                                 - Imaris::IICells
%                                 - Imaris::ILightSource
%                                 - Imaris::IMeasurementPoints
%                                 - Imaris::ISpots
%                                 - Imaris::ISurfaces
%                                 - Imaris::IVolume
%                                 - Imaris::ISurpassCamera
%                                 - Imaris::IImageProcessing
%                                 - Imaris::IFactory

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

% Check for type and cast (types expected to be used more frequently are
% checked first)

derivedType = [];

if isempty(IDataItem)
	return;

elseif this.mImarisApplication.GetFactory().IsLightSource(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToLightSource(IDataItem);

elseif this.mImarisApplication.GetFactory().IsFrame(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToFrame(IDataItem);

elseif this.mImarisApplication.GetFactory().IsVolume(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToVolume(IDataItem);
    
elseif this.mImarisApplication.GetFactory().IsSpots(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToSpots(IDataItem);
   
elseif this.mImarisApplication.GetFactory().IsSurfaces(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToSurfaces(IDataItem);

elseif this.mImarisApplication.GetFactory().IsDataSet(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToDataSet(IDataItem);

elseif this.mImarisApplication.GetFactory().IsSurpassCamera(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToSurpassCamera(IDataItem);

elseif this.mImarisApplication.GetFactory().IsFilaments(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToFilaments(IDataItem);

elseif this.mImarisApplication.GetFactory().IsClippingPlane(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToClippingPlane(IDataItem);

elseif this.mImarisApplication.GetFactory().IsApplication(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToApplication(IDataItem);

elseif this.mImarisApplication.GetFactory().IsMeasurementPoints(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToMeasurementPoints(IDataItem);

elseif this.mImarisApplication.GetFactory().IsDataContainer(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToDataContainer(IDataItem);

elseif this.mImarisApplication.GetFactory().IsCells(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToCells(IDataItem);

elseif this.mImarisApplication.GetFactory().IsFactory(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToFactory(IDataItem);

elseif this.mImarisApplication.GetFactory().IsImageProcessing(IDataItem)
    derivedType = this.mImarisApplication.GetFactory().ToImageProcessing(IDataItem);
    
else
    derivedType = IDataItem;

end
