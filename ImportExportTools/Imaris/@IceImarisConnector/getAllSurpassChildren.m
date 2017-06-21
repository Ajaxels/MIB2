function children = getAllSurpassChildren(this, recursive, filter)
% IceImarisConnector:  getAllSurpassChildren (public method)
%
% DESCRIPTION
% 
%   This method returns all children of the surpass scene recursively.
%   Folders (i.e. IDataContainer objects) may be scanned (recursively)
%   but are not returned. Optionally, the returned objects may be filtered
%   by type.
% 
% SYNOPSIS
% 
%   children = conn.getAllSurpassChildren(recursive, filter)
% 
% INPUT
% 
%   recursive: {0 | 1} If 1, folders will be scanned recursively;
%                      if 0, only objects at root level will be inspected.
%
%   filter   : (optional) Filters the children by type. Only the 
%                         surpass children of the specified type are
%                         returned; filter is one of:
%
%                           'Cells'
%                           'ClippingPlane'
%                           'Dataset'
%                           'Filaments'
%                           'Frame'
%                           'LightSource'
%                           'MeasurementPoints'
%                           'Spots'
%                           'Surfaces'
%                           'SurpassCamera'
%                           'Volume'
% 
% OUTPUT
% 
%   children : cell array of objects

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
if nargin < 2 || nargin > 3
    error('1 or 2 input parameters expected.');
end

if nargin == 2
    filter = [];
end

if ~ismember(recursive, [0 1])
    error('Bad value for input parameter ''recursive''.');
end

% Initialize children
children = {};

% Check whether we have children in the surpass scene at all
if isempty(this.mImarisApplication.GetSurpassScene())
    return
end

nChildren = this.mImarisApplication.GetSurpassScene().GetNumberOfChildren();
if nChildren == 0
    return
end

% Here we keep track of the number of children we store
currentChildNumber = 0;

% Scan the children recursively. For performance reasons, we use a 
% separate function for the case where filtering is requested.
if isempty(filter)
    getChildrenAtLevel(this.mImarisApplication.GetSurpassScene(), ...
        recursive);
else
    getFilteredChildrenAtLevel(...
        this.mImarisApplication.GetSurpassScene(), recursive, filter);
end

% =========================================================================

    % Recursive function to scan children of a given container
    function getChildrenAtLevel(container, recursive)
        
        % This function scans the children recursively
        for i = 1 : container.GetNumberOfChildren()
   
            % Get current child
            child = container.GetChild(i - 1);
    
            % Is this a folder? If it is, call this function recursively
            if this.mImarisApplication.GetFactory().IsDataContainer(child)
                if recursive == 1
                    getChildrenAtLevel(this.autocast(child), recursive);
                end
            else
                currentChildNumber = currentChildNumber + 1;
                children{currentChildNumber} = this.autocast(child);
            end
            
        end

    end

% =========================================================================

    % Recursive function to scan children of a given container
    function getFilteredChildrenAtLevel(container, recursive, filter)
        
        % This function scans the children recursively
        for i = 1 : container.GetNumberOfChildren()
   
            % Get current child
            child = container.GetChild(i - 1);
    
            % Is this a folder? If it is, call this function recursively
            if this.mImarisApplication.GetFactory().IsDataContainer(child)
                if recursive == 1
                    getFilteredChildrenAtLevel(this.autocast(child), ...
                        recursive, filter);
                end
            else
                currentChild = this.autocast(child);
                if this.isOfType(currentChild, filter)
                    currentChildNumber = currentChildNumber + 1;
                    children{currentChildNumber} = currentChild;
                end
            end
            
        end

    end

end
