function connImaris = mibSetImarisSpots(spots, connImaris, options)
% function connImaris = mibSetImarisSpots(spots, connImaris, options)
% Send a spots from MIB to Imaris
%
% Parameters:
% spots: a matrix [x, y, z, t] with coordinates of the spots (n x 4)
% connImaris: [@em optional] a handle to Imaris connection
% options: an optional structure with additional settings 
% @li .radii -> [@em optional] a vector with radii of the spots (n x 1)
% @li .color [@em optional] a vector with color for spots: (1x4), (0..1) vector of [R G B A] values
% @li .name -> a char with the name of the object
%
% Return values:
% connImaris:  a handle to Imaris connection

% @note
% uses IceImarisConnector bindings
% @b Requires:
% 1. set system environment variable IMARISPATH to the installation
% directory, for example "c:\tools\science\imaris"
% 2. restart Matlab

%|
% @b Examples:
% @code options.lutColors = obj.mibModel.displayedLutColors;   // call from mibController; get colors for the color channels @endcode
% @code spots = [1, 1, 1, 1];   // add a single spot to position 1,1,1,1
% @code obj.connImaris = mibSetImarisSpots(spots, obj.connImaris);     // call from mibController; send spots from matlab to imaris @endcode

% Copyright (C) 20.09.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 25.09.2017 IB updated connection to Imaris

if nargin < 3;     options = struct(); end
if nargin < 2;     connImaris = []; end

if ~isfield(options, 'color'); options.color = [1, 0, 0, 1]; end    % use red color by default
if ~isfield(options, 'name'); options.name = 'mibSpots'; end        % use mibSpots name by default
if ~isfield(options, 'radii')   % use radii as 1/150th of width
    minX = min(spots);
    maxX = max(spots);
    options.radii = zeros([size(spots, 1) 1]) + (maxX(1)-minX(1))/150; 
end          
if ~isfield(options, 'dt')   % time step
    options.dt = 1;
end


% establish connection to Imaris
connImaris = mibConnectToImaris(connImaris);
if isempty(connImaris); return; end

wb = waitbar(0, 'Please wait...', 'Name', 'Export spots to Imaris');

% reformat spots matrix to extract time
if size(spots, 2) == 4  % [x,y,z,t xn] matrix
    timeVec = spots(:,4)-1;
    spots = spots(:,1:3);
elseif size(spots, 2) == 3 % [x,y,z xn] matrix
    timeVec = zeros([size(spots, 1) 1])+1;
end

connImaris.createAndSetSpots(spots, timeVec, options.radii, options.name, options.color);

delete(wb);
end
