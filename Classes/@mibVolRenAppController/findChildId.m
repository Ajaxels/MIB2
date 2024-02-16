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

function id = findChildId(obj, childName)
% function id = findChildId(childName)
% find id of a child controller
%
% the child controllers of MIB are stored in obj.childControllersIds cell
% array. This function look for index that matches with childName string.
% If it is in the list the function returns its index, otherwise it adds it
% to the list as a new element
%
% Parameters:
% childName: name of a child controller
%
% Return values:
% id: index of the requested child controller or empty if it is not open
%

%| 
% @b Examples:
% @code id = obj.findChildId('mibImageAdjController');     // find an index of mibImageAdjController @endcode
 
% Updates
%

if ismember(childName, obj.childControllersIds) == 0    % not in the list of controllers
    %id = numel(obj.childControllersIds) + 1;
    %obj.childControllersIds{id} = childName;
    id = [];
else                % already in the list
    id = find(ismember(obj.childControllersIds, childName)==1);
end
end