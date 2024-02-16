% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function foundNode = findNode(nodeName, node)
% function foundNode = findNode(nodeName, node)
% find a node in the uitree which has nodeName text in it, used by mibDatasetInfoController
%
% Paramters: 
% nodeName: a string to find
% node: a handle to the current node (DefaultMutableTreeNode Java class)
%
% Return values:
% foundNode: a handle to the node if it is found, or empty

% Updates
% 

if ~isempty(node)
    name = char(node.getName);
    if strfind(lower(name), lower(nodeName))
        foundNode = node;
    else
        foundNode = findNode(nodeName, node.getNextNode);
    end
else
    foundNode = [];
end
end