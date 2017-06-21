function selection = getSurpassSelection(this, type)
% IceImarisConnector:  getSurpassSelection (public method)
%
% DESCRIPTION
% 
%   This method returns the auto-casted current surpass selection. If
%   the 'type' parameter is specified, the object class is checked
%   against it and [] is returned instead of the object if the type
%   does not match.
% 
% SYNOPSIS
% 
%   (1) selection = conn.getSurpassSelection()
%   (2) selection = conn.getSurpassSelection(type)
% 
% INPUT
% 
%   type : (optional) Specify the expected object class. If the selected
%          object is not of the specified type, the function will return
%          [] instead. Type is one of:
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
%   selection : autocasted, currently selected surpass object; if nothing
%               is selected, or if the object class does not match the
%               passed type, selection will be [] instead.

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

selection = [];

% Is Imaris running?
if this.isAlive() == 0
    return
end

% Get current selection
selection = this.autocast(this.mImarisApplication.GetSurpassSelection());
if isempty(selection)
    return
end

% Check type?
if nargin == 2
    if ~this.isOfType(selection, type)
        selection = [];
    end
end

end
