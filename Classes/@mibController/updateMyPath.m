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

function updateMyPath(obj, myPath)
% function updateMyPath(obj, myPath)
% update mibModel.myPath, which is the current working directory
%
% Parameters:
% myPath: a new path to use as the working directory

%| 
% @b Examples:
% @code mibController.updateMyPath('c:\temp');     // set c:\temp as a new working directory @endcode
 
% Updates
%


if isdir(myPath)
    obj.mibModel.myPath = myPath;
    obj.updateFilelist();
    drives = obj.mibView.handles.mibDrivePopup.String;
    if isa(drives, 'char'); drives = cellstr(drives); end
    
    if ispc()
        for i = 1:numel(drives)
            driveLetter = drives{i};
            if strcmpi(driveLetter(1), myPath(1))
                obj.mibView.handles.mibDrivePopup.Value = i;
            end
        end
    end
end
obj.mibView.handles.mibPathEdit.String = obj.mibModel.myPath;
end