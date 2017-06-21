function version = getImarisVersionAsInteger(this)
% IceImarisConnector:  getImarisVersionAsInteger (public method)
% 
% DESCRIPTION
% 
% This static method returns the version number of Imaris as integer: 
% 
%    v = 100000 * Major + 10000 * Minor + 100 * Patch
% 
% SYNOPSIS
% 
%   version = IceImarisConnector.getVersionAsInteger()
% 
% INPUT
% 
%   None
% 
% OUTPUT
% 
%   version : Imaris version as integer

% AUTHORS
%
% Author: Aaron Ponti

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

version = 0;

% Is Imaris running?
if this.isAlive() == 0
    return
end

% Get the version string and extract the major, minor and patch versions
% The version must be in the form M.N.P

tokens = regexp(char(this.mImarisApplication.GetVersion()), ...
    '(\d)+\.(\d)+\.+(\d)?', 'tokens');
if isempty(tokens)
    disp('Could not get version number!');
    return
end
if numel(tokens{1}) ~= 3
    disp('Could not get version number!');
    return
end
    
% Get the major, minor and patch versions
major = str2double(tokens{1}{1});
if isnan(major)
    disp(['Could not get major version number! Error message was: ', ...
        e.message, '\n']);
    major = 0;
end

minor = str2double(tokens{1}{2});
if isnan(minor)
    disp(['Could not get minor version number! Error message was: ', ...
        e.message, '\n']);
    minor = 0;
end

patch = str2double(tokens{1}{3});
if isnan(patch)
    % In case the patch version is not set we assume 0 is meant
    patch = 0;
end

% Compute version as integer
version = 1e6 * major + 1e4 * minor + 1e2 * patch;

end
