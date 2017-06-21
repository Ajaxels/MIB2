function mibUpdateDrives(handles, start_path)
% function mibUpdateDrives(handles,start_path,firsttime)
% updates list of available logical disk drives and updates
% handles.mibDrivePopup with that list
%
% Parameters:
% handles: structure with handles of im_browser.m
% start_path: a string that defines the starting letter, for example 'c:' for Windows, or '/' for Unix

% Copyright (C) 04.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2
    start_path = ''; 
else
    start_path = lower(start_path);
end;

% function gets available disk drives from C: to Z:
os = getenv('OS');
if strcmp(os,'Windows_NT')
    ret = {};
    index=1;
    
    startletter = 'c';
    for i = startletter:'z'
        if exist([i ':\'], 'dir') == 7
            ret{end+1} = [i ':']; %#ok<AGROW>
            if strcmp(ret{end}, start_path); index = length(ret); end;
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