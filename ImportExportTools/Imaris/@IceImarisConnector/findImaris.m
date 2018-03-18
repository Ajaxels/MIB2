function [status, errorMessage] = findImaris(this)
% IceImarisConnector:  findImaris (private method)
%
% DESCRIPTION
%
%   This methods gets the Imaris path to the Imaris executable and
%   to the ImarisLib.jar library from the environment variable IMARISPATH
%
% SYNOPSIS
%
%   [status, errorMessage] = conn.findImaris()
%
% INPUT
%
%   None
%
% OUTPUT
%
%   status       : 1 if the paths could be set successfully, 0 otherwise
%   errorMessage : if the paths could not be found, a message is returned
%                  in errorMessage

% AUTHORS
%
% Author: Aaron Ponti
% Contributor: Igor Beati

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

% Initialize the status to failure
status = 0;

% Initialize the error messgae
errorMessage = '';

% Try to get the path from the environment variable IMARISPATH
imarisPath = getenv('IMARISPATH');

% Set the paths
this.mImarisPath = '';
this.mImarisExePath = '';
this.mImarisServerExePath = '';
this.mImarisLibPath = '';

% Is the variable defined?
if isempty(imarisPath)
    % jonas - 4/2012 be a little more robust
    % installation defaults to C: on Windows, /Applications on Mac
    if ispc
        tmp = 'C:\Program Files\Bitplane\';
    elseif ismac
        tmp = '/Applications';
    else
        errorMessage = ...
            'IceImarisConnector can only work on Windows and Mac OS X';
        return
    end
    
    if exist(tmp,'dir')
        % Pick the directory name with highest version number
        % Aaron - 09/12. Use highest version number instead of
        %                latest modification date to choose.
        d = dir(fullfile(tmp,'Imaris*'));
        newestVersionDir = findNewestVersion(d);
        if isempty(newestVersionDir)
            errorMessage = sprintf(...
                ['No Imaris installation found in %s.',...
                ' Please define an environment variable ', ...
                'IMARISPATH'],...
                tmp);
            return;
        else
            imarisPath = fullfile(tmp, newestVersionDir);
        end
    else
        errorMessage = sprintf(...
            ['No Imaris installation found in %s.',...
            ' Please define an environment variable IMARISPATH'],...
            tmp);
        return;
    end
    
else

    % Does it point to an existing directory?
    if ~exist(imarisPath, 'dir')
        errorMessage = ['The content of the IMARISPATH environment ', ...
            'variable does not point to a valid directory.'];
        return;
   end
    
end

% Now store imarisPath and proceed with setting all required executables
% and libraries
this.mImarisPath = imarisPath;

% Set the path to the Imaris and ImarisServer executables, and to the 
% ImarisLib library
if ispc()
    exePath = fullfile(imarisPath, 'Imaris.exe');
    serverExePath = fullfile(imarisPath, 'ImarisServerIce.exe'); 
    libPath = fullfile(imarisPath, 'XT', 'matlab', 'ImarisLib.jar');
elseif ismac()
    exePath = fullfile(imarisPath, 'Contents', 'MacOS', 'Imaris');
    serverExePath = fullfile(imarisPath, 'Contents', 'MacOS', 'ImarisServerIce');
    libPath = fullfile(imarisPath, 'Contents', 'SharedSupport', ...
        'XT', 'matlab', 'ImarisLib.jar');
else
    errorMessage = ['IceImarisConnector can only be used on Windows ', ...
        'and Mac OS X.'];
    return
end

% Check whether the executable Imaris file exists
if ~exist(exePath, 'file')
    errorMessage = 'Could not find the Imaris executable.';
    return;
end

% Check whether the executable ImarisServer file exists
if ~exist(serverExePath, 'file')
    errorMessage = 'Could not find the ImarisServer executable.';
    return;
end

% Check whether the ImarisLib jar package exists
if ~exist(libPath, 'file')
    errorMessage = 'Could not find the ImarisLib jar file.';
    return;
end

% Now we can store the information and return success
this.mImarisExePath = exePath;
this.mImarisServerExePath = serverExePath;
this.mImarisLibPath = libPath;

status = 1;

% In case of multiple Imaris installations, return the most recent
    function newestVersionDir = findNewestVersion(allDirs)
        
        % If found, this will be the (relative) ImarisPath
        newestVersionDir = [];
        
        % Newest version. Initially set to one since valid versions will
        % be larger, invalid versions might be zero.
        newestVersion = 1;
        
        % Make sure to ignore the Scene Viewer, the File Converter and 
        % the 32bit version on 64 bit machines
        allDirs(~cellfun(@isempty, ....
            strfind({allDirs.name}, 'ImarisSceneViewer'))) = [];
        allDirs(~cellfun(@isempty, ....
            strfind({allDirs.name}, 'FileConverter'))) = [];
        allDirs(~cellfun(@isempty, ....
            strfind({allDirs.name}, '32bit'))) = [];
        
        for i = 1 : numel(allDirs)
            
            % Extract version from directory name
            tokens = regexp(allDirs(i).name, ...
                '(\d)+\.(\d)+\.+(\d)?', 'tokens');
            
            if isempty(tokens) || numel(tokens{1}) ~= 3
                continue;
            end
            
            % Get the major, minor and patch versions
            major = str2double(tokens{1}{1});
            if isnan(major)
                % Must be defined
                continue;
            end
            
            minor = str2double(tokens{1}{2});
            if isnan(minor)
                % Must be defined
                continue;
            end
            
            patch = str2double(tokens{1}{3});
            if isnan(patch)
                % In case the patch version is not set we assume 0 is meant
                patch = 0;
            end
            
            % Compute version as integer
            version = 1e6 * major + 1e4 * minor + 1e2 * patch;
            
            % Is it the newest yet?
            if version > newestVersion
                newestVersionDir = allDirs(i).name;
                newestVersion = version;
            end
        end

    end
end
