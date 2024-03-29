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

function connImaris = mibConnectToImaris(connImaris)
% function connImaris = mibConnectToImaris(connImaris)
% Connect to Imaris from Matlab
%
% Parameters:
% connImaris: [@em optional] a handle to Imaris connection
%
% Return values:
% connImaris:  a handle to Imaris connection

% @note
% uses IceImarisConnector bindings
% @b Requires:
% 1. set system environment variable IMARISPATH to the installation
% directory, for example "c:\tools\science\imaris"
% 2. restart Matlab

% Updates
% 

if nargin < 1;     connImaris = []; end

% establish connection to Imaris
wb = waitbar(0, 'Please wait...', 'Name', 'Connecting to Imaris');
if isempty(connImaris)
    try
        connImaris = IceImarisConnector(0);
        waitbar(0.3, wb);
    catch exception
        %if strcmp(exception.message, 'Could not connect to Imaris Server.')
        errordlg(sprintf('Could not connect to Imaris Server;\nPlease start Imaris and try again!\n\n%s', exception.message), ...
            'Missing Imaris');
        delete(wb);
        connImaris = [];
        return;
    end
    waitbar(0.7, wb);
    if connImaris.isAlive == 0
        % start Imaris
        connImaris.startImaris()
        waitbar(0.95, wb);
    end
else
    vImarisLib = ImarisLib;
    vServer = vImarisLib.GetServer();
    if isempty(vServer)
        errordlg(sprintf('Could not connect to Imaris Server;\nPlease start Imaris and try again!'), ...
            'Missing Imaris');
        delete(wb);
        connImaris = [];
        return;
    end
    vNumberOfObjects = vServer.GetNumberOfObjects();
    if vNumberOfObjects == 0
        connImaris.startImaris();
    else
        notAlive = 1;
        vIndex = 0;
        while notAlive
            vObjectId = vServer.GetObjectID(vIndex);
            connImaris = IceImarisConnector(vObjectId);
            if connImaris.isAlive
                notAlive = 0;
            end
            vIndex = vIndex + 1;
        end
    end
    
end
delete(wb);
end
