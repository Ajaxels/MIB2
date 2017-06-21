function newSpots = createAndSetSpots(this, coords, timeIndices, radii, name, color, container)
% Imaris Connector:  createAndSetSpots (public method)
% 
% DESCRIPTION
% 
%   This method creates Spots and adds them to the Surpass Scene.
% 
% SYNOPSIS
% 
%   (1) newSpots = createAndSetSpots(coords, timeIndices, radii, ...
%                      name, color)
%   (2) newSpots = createAndSetSpots(coords, timeIndices, radii, ...
%                      name, color, container)
% 
% INPUT
% 
%   coords      : (nx3) [x y z]n coordinate matrix in dataset units
%   timeIndices : (nx1) vector of spots time indices
%   radii       : (nx1) vector of spots radii
%   name        : name of the Spots object
%   color       : (1x4), (0..1) vector of [R G B A] values
%   container   : (optional) if not set, the Spots object is added at the
%                 root of the Surpass Scene.
%                 Please note that it is the user's responsibility to
%                 attach the container to the surpass scene!
% 
% OUTPUT
% 
%   newSpots    : the generated Spots object.

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

if nargin < 6 || nargin > 7
    % The this parameter is hidden
    error('5 or 6 input parameters expected.');
end

% Container
if nargin == 6
    container = this.mImarisApplication.GetSurpassScene();
else
    % Make sure the container is valid
    if ~this.mImarisApplication.GetFactory().IsDataContainer(container)
        error('Invalid data container!');
    end
end

% Check the coordinates
if size(coords, 2) ~= 3
    error('''coords'' must be an (nx3) matrix of coordinates.');
end

% Check whether coords is of type single. If not try the conversion.
if ~isa(coords, 'single')
    coords = single(coords);
end

% Check timeIndices and radii
timeIndices = timeIndices(:);
radii = radii(:);
nSpots = size(coords, 1);
if numel(timeIndices) ~= nSpots
    error('Wrong number of time indices.');
end
if numel(radii) ~= nSpots
    error('Wrong number of radii.');
end

% Check the name
if ~isa(name, 'char')
    error('The name must be of class ''char''.');
end

% Check the color vector
color = color(:);
if numel(color) ~= 4 || any(color < 0) || any(color > 1)
    error([ '''color'' must be an (1x4) vector [R G B A] with values ', ...
        'between 0 and 1.']);
end

% Check if the connection is alive
if this.isAlive() == 0
    return
end

% Create a new Spots bject
newSpots = this.mImarisApplication.GetFactory().CreateSpots();

% Set coordinates, time indices and radii
newSpots.Set(coords, timeIndices, radii);

% Set the name
newSpots.SetName(name);

% Set the color
newSpots.SetColorRGBA(this.mapRgbaVectorToScalar(color));

% Add the new Spots object to the container
container.AddChild(newSpots, -1);

end
