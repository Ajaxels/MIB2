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

function [file, path, indx] = mib_uigetfile(filter, title, defname, mode)
% function [file, path, indx] = mib_uigetfile(filter, title, defname, mode)
% a wrapper function to provide a modified uigetfile dialog for MacOS
% Catalina. The general syntax is the same as for uigetfile, except missing
% 'MultiSelect' key
% 
% 
% Parameters:
% filter: file filter, specified as a character vector, cell array of character vectors, or a string array
% For example:
% {'*.fig','Figures (*.fig)'; ...
%  '*.mat','MAT-files (*.mat)'; ...
%  '*.png; *.jpg','Images (*.png, *.jpg)'; ...
%  '*.*',  'All Files (*.*)'}
% title: string, dialog box title
% defname: default file name field value, specified as a character vector or a string scalar. The defname value can specify a path, or a path and a file name
% mode: multiselect mode, ''off'' (default) or ''on''
%
% Return values:
% file: file name that the user specified in the dialog box, returned as a cell array
% path: path to the specified file or files, returned as a character vector
% indx: selected filter index, returned as an integer

%| 
% @b Examples:
% @code
% fileFilter = {'*.mat','MAT-files (*.mat)'; ...
%               '*.*',  'All Files (*.*)'};
% [file, path, indx] = mib_uigetfile(fileFilter, 'Select files', 'c:\', 'on');
% if isequal(file, 0); return; end
% @endcode

if nargin < 4; mode = 'off'; end
if nargin < 3; defname = ''; end
if nargin < 2; title = 'Select a File'; end
if nargin < 1; filter = ''; end

if ~ismac
    [file, path, indx] = uigetfile(filter, title, defname, 'MultiSelect', mode);
else
    try
        % versions: https://support.apple.com/en-us/HT201260
        [~, OSver] = system('sw_vers -productVersion');
        OSver = str2double(strtrim(OSver));
    catch err
        OSver = 1;
    end
    if OSver < 10.15
        [file, path, indx] = uigetfile(filter, title, defname, 'MultiSelect', mode);
    else    % Catalina
        if iscell(filter)
            % replace individual filters with *.*
            filter(:,1) = repmat({'*.*'}, [size(filter, 1), 1]);
        end
        [file, path, indx] = uigetfile(filter, title, defname, 'MultiSelect', mode);
    end
end
if ischar(file); file = {file}; end
end