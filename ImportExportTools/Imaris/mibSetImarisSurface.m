function connImaris = mibSetImarisSurface(surface, connImaris, options)
% function connImaris = mibSetImarisSurface(surface, connImaris, options)
% Send a surface from MIB to Imaris
%
% Parameters:
% surface: a structure with fields:
%   .vertices - coordinates of vertices [Nx3]
%   .faces    - indeces of vertices for each face/triangle
%   .normals  - matrix with normals [Nx3]
% connImaris: [@em optional] a handle to Imaris connection
% options: an optional structure with additional settings 
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
% 3. The function is using patchnormals function written by by Dirk-Jan Kroon
% https://se.mathworks.com/matlabcentral/fileexchange/24330-patch-normals

%|
% @b Examples:
% @code 
% surface.vertices = [28 40 0; 29 40 0; 27 40 1; 28 40 1];
% surface.faces = [1 3 4; 1 4 2];
% options.color = [1 0 0];
% obj.connImaris = mibSetImarisSurface(surface, obj.connImaris, options);     // call from mibController; send surface from Matlab to Imaris
% @endcode

% Copyright (C) 19.02.2018 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3;     options = struct(); end
if nargin < 2;     connImaris = []; end

% calculate normals using patchnormals function by Dirk-Jan Kroon
% https://se.mathworks.com/matlabcentral/fileexchange/24330-patch-normals
if ~isfield(surface, 'normals')
    if ~isempty(which('patchnormals'))
        %surface.normals = patchnormals(surface);
        
        % the code below is a simplified version by Serge from comments for
        % https://se.mathworks.com/matlabcentral/fileexchange/24330-patch-normals
        A = surface.faces(:,1);
        B = surface.faces(:,2);
        C = surface.faces(:,3);
        
        %face normals
        n = cross(surface.vertices(A,:)-surface.vertices(B,:),surface.vertices(C,:)-surface.vertices(A,:)); %area weighted
        
        %vertice normals
        N = zeros(size(surface.vertices)); %init vertix normals
        for i = 1:size(surface.faces,1) %step through faces (a vertex can be reference any number of times)
            N(A(i),:) = N(A(i),:)+n(i,:); %sum face normals
            N(B(i),:) = N(B(i),:)+n(i,:);
            N(C(i),:) = N(C(i),:)+n(i,:);
        end
        surface.normals = -N;
    else
        % alternative method to calculate normals to make a smooth surface
        vMean = mean(surface.vertices, 1);
        surface.normals = -[surface.vertices(:, 1) - vMean(1), ...
            surface.vertices(:, 2) - vMean(2), ...
            surface.vertices(:, 3) - vMean(3)];
    end
end

if ~isfield(options, 'color'); options.color = [1, 0, 0, 0]; end    % use red color by default
if ~isfield(options, 'name'); options.name = 'mibSurface'; end        % use mibSpots name by default

if ~isfield(options, 'dt')   % time step
    options.dt = 1;
end

% when sending to Imaris the index of the first vertice should be 0, not 1
% as in Matlab
if min(surface.faces) ~= 0; surface.faces = surface.faces - 1; end
% check for transparency in the colors
if size(options.color, 2) == 3
    options.color(:,4) = 0;
end


% % Imaris tests
% connImaris = IceImarisConnector(0);
% 
% vImarisApplication = connImaris.mImarisApplication;
% vSurpass = vImarisApplication.GetSurpassScene;
% vFactory = vImarisApplication.GetFactory;
% 
% vChild = vSurpass.GetChild(4);
% vChild.GetName()
% vSurface = vImarisApplication.GetFactory.ToSurfaces(vChild);
% 
% vSurfaceData = vSurface.GetSurfaceData(0);
% 
% newSurface = vFactory.CreateSurfaces;
% newSurface.SetName('New surface');
% newSurface.AddSurface(vSurfaceData, 0);
% imarisScene.AddChild(newSurface, -1);



% establish connection to Imaris
connImaris = mibConnectToImaris(connImaris);
if isempty(connImaris); return; end

vImarisApplication = connImaris.mImarisApplication;
imarisScene = vImarisApplication.GetSurpassScene;
if isempty(imarisScene)
    errordlg(sprintf('!!! Error !!!\n\nThe Imaris scene is empty!\nPlease open/export a dataset (Volume) in Imaris and try again!'),'No volume');
    return;
end

vFactory = vImarisApplication.GetFactory;

% Create a new Surface object
newSurface = vFactory.CreateSurfaces;

newSurface.SetName(options.name);
% set color
newSurface.SetColorRGBA(connImaris.mapRgbaVectorToScalar(options.color))
newSurface.AddSurface(surface.vertices, surface.faces, surface.normals, 0);
imarisScene.AddChild(newSurface, -1);

wb = waitbar(0, 'Please wait...', 'Name', 'Export surface to Imaris');

% % reformat spots matrix to extract time
% if size(spots, 2) == 4  % [x,y,z,t xn] matrix
%     timeVec = spots(:,4)-1;
%     spots = spots(:,1:3);
% elseif size(spots, 2) == 3 % [x,y,z xn] matrix
%     timeVec = zeros([size(spots, 1) 1])+1;
% end

%connImaris.createAndSetSpots(spots, timeVec, options.radii, options.name, options.color);

delete(wb);
end
