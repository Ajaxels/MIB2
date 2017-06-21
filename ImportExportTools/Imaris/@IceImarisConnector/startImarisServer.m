function [success, errorMessage] = startImarisServer(this)
% IceImarisConnector:  startImarisServer (private method)
%
% DESCRIPTION
%
%   This method starts an instance of ImarisServerIce and waits until it
%     is ready to accept connections.
%
%
% SYNOPSIS
%
%   success = conn.startImarisServer()
%
% INPUT
%
%   None
%
% OUTPUT
%
%   success : 1 if starting Imaris was successful, 0 otherwise

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

% Initialize errorMessage
errorMessage = '';

% Imaris only runs on Windows and Mac OS X
success = 0;
if ~this.isSupportedPlatform()
    disp('IceImarisConnector can only work on Windows and Mac OS X');
    return
end

% Check whether an instance of ImarisServerIce is already running. If this
% is the case, we can return success
if isImarisServerIceRunning() == 1
    success = 1;
    return;
end

% We start an instance and wait until it is running before returning
% success. We set a 10s time out limit
try
    % Launch ImarisServer
    [status, result] = system(...
        ['"', this.mImarisServerExePath, '" &']);
    
    if status == 1
        errorMessage = result;
        success = 0;
        return
    end
    
    % Now wait until ImarisIceServer is running (or we time out)
    tic;
    t = 0;
    timeout = 10;
    while t < timeout
        
        if isImarisServerIceRunning() == 1
            success = 1;
            return;
        end
        
        % Update the elapsed time
        t = toc;
        
    end
    
catch ex
    
    errorMessage = ex.message;
    success = 0;
    
end

% Checks whether an instance of ImarisServerIce is already running and
% can be reused
    function isRunning = isImarisServerIceRunning()
        
        % Initialize isRunning to false
        isRunning = 0;
        
        % The check will be different on Windows and on Mac OS X
        if ispc()
            
            [~, result] = system(...
                'tasklist /NH /FI "IMAGENAME eq ImarisServerIce.exe"');
            if strfind(result, 'ImarisServerIce.exe')
                isRunning = 1;
                return;
            end
            
        elseif ismac()
            
            [~, result] = system('ps aux | grep ImarisServerIce');
            if strfind(result, this.mImarisServerExePath)
                isRunning = 1;
                return;
            end
        else
            error('Unsupported platform.');
        end
        
    end

end
