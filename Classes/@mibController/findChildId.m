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
 
% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
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