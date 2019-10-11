function updateMyPath(obj, myPath)
% function exitProgram(obj)
% update mibModel.myPath, which is the current working directory
%
% Parameters:
% myPath: a new path to use as the working directory

%| 
% @b Examples:
% @code mibController.updateMyPath('c:\temp');     // set c:\temp as a new working directory @endcode
 
% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
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