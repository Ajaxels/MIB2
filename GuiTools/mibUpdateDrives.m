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

function mibUpdateDrives(handles, start_path)
% function mibUpdateDrives(handles,start_path,firsttime)
% updates list of available logical disk drives and updates
% handles.mibDrivePopup with that list
%
% Parameters:
% handles: structure with handles of im_browser.m
% start_path: a string that defines the starting letter, for example 'c:' for Windows, or '/' for Unix

% Updates
% 

if nargin < 2
    start_path = ''; 
else
    start_path = lower(start_path);
end

% function gets available disk drives from C: to Z:
os = getenv('OS');
if strcmp(os,'Windows_NT')
    ret = {};
    index=1;
    
    startletter = 'c';
    for i = startletter:'z'
        if exist([i ':\'], 'dir') == 7
            ret{end+1} = [i ':']; %#ok<AGROW>
            if strcmp(ret{end}, start_path); index = length(ret); end
        end
    end
    handles.mibDrivePopup.String = ret;
    handles.mibDrivePopup.Value = index;
else        % unix system type
    start_path = '/';
    handles.mibDrivePopup.String = start_path;
    handles.mibDrivePopup.String = 1;
end
end