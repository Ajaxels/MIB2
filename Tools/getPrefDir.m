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

function prefdir = getPrefDir()
% function prefdir = getPrefDir()
% get directory where MIB preferences are stored
% on Windows it is C:\Users\Username\Matlab
% on Mac it is /Users/username/Matlab
% on Linux it is /home/username/Matlab

% Updates
% 

if ispc
    userDir = getenv('USERPROFILE');
else    % Mac and Linux
    userDir = getenv('HOME');
end
prefdir = fullfile(userDir, 'Matlab');
if exist(prefdir, 'dir') == 0
    try
        mkdir(prefdir);
    catch err
        warndlg(sprintf('!!! Warning !!!\n\nThe directory for storing the preferences (%s) can not be created,\nsystem TEMP directory (%s) will be used instead!', prefdir, tempdir), 'Preference dir warning');
        prefdir = tempdir;
    end
end
