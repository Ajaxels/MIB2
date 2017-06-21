function mibRenderModelFiji(Volume, Index, pixSize, color_list)
% function mibRenderModelFiji(Volume, Index, pixSize, color_list)
% Render a model with Fiji engine.
%
% @note requires Fiji to be installed (http://fiji.sc/Fiji)
%
% Parameters:
% Volume: a model, [1:height, 1:width, 1:thickness] with materials
% Index: iso value, if @b 0 generate isosurfaces of all materials
% pixSize: structure with physical dimensions of voxels
%   - .x - physical width
%   - .y - physical height
%   - .z - physical thickness
%   - .units - physical units
% color_list: [@em optional] -> list of colors for models (0-1), [materialIndex][Red, Green, Blue]

% Copyright (C) 23.11.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% based on Matlab3DViewerDemo_1.m by Jean-Yves Tinevez \<jeanyves.tinevez at gmail.com\>

global mibPath;

% check for installed Miji
if ~isdeployed
    if isempty(which('Miji'))
        msgbox(sprintf('Miji was not found!\n\nTo fix:\n1. Install Fiji (http://fiji.sc/Fiji)\n2. Add Fiji.app/Scripts to Matlab path'),...
            'Missing Miji!','error');
        return;
    end
end

% Make sure Java3D is installed
% If not, try to install it
if ~IsJava3DInstalled(true)
    msgbox(sprintf('Java3D is not installed'),...
        'Java error!','error');
    return;
end

% generate random color list
if nargin < 4
    for i=1:255
        color_list(i,:) = [rand(1) rand(1) rand(1)];
    end;
end;

prompt = {'Reduce the volume down to, width pixels [no volume reduction when 0]?'};
%answer = inputdlg(prompt, 'Parameters',1,{'512'});
answer = mibInputDlg({mibPath}, prompt, 'Parameters','512');
if isempty(answer); return;  end;

wb = waitbar(0, 'Starting...','Name','Fiji rendering');
if Index==0
    minIndex = 1;
    maxIndex = max(max(max(Volume)));
else
    minIndex = Index;
    maxIndex = Index;
end

maxVolumeWidth = str2double(answer{1});
if maxVolumeWidth ~= 0
    factorX=ceil(size(Volume,2)/maxVolumeWidth);
    factorY=ceil(factorX*pixSize.x/pixSize.y-.001);
    factorZ=ceil(factorX*pixSize.x/pixSize.z);
else
    factorX=1;
    factorY=1;
    factorZ=1;
end;
width = ceil(size(Volume,2)/factorX);
height = ceil(size(Volume,1)/factorY);
thick = ceil(size(Volume,3)/factorZ);

if minIndex ~= maxIndex     % do color visualization, which is slower and requires larger Jave heap size
    R = zeros(height, width, thick, class(Volume));
    G = zeros(height, width, thick, class(Volume));
    B = zeros(height, width, thick, class(Volume));
    for contIndex=minIndex:maxIndex
        subVolume = Volume==contIndex;
        
        waitbar(0.2*contIndex/maxIndex, wb,  ...
            sprintf('Reducing the volume to %d x %d x %d px ...',height, width, thick));
        [~,~,~,subVolume] = reducevolume(subVolume,[factorY,factorX,factorZ]);
        
        R(subVolume==1) = color_list(contIndex,1)*255;
        G(subVolume==1) = color_list(contIndex,2)*255;
        B(subVolume==1) = color_list(contIndex,3)*255;
    end
    
    % We now put them together into one 3D color image (that is, with 4D). To
    % do so, we simply concatenate them along the 3th dimension.
    % A note here: MIJ expects the dimensions of a 3D color image to be the
    % following: [ x y z color ]; this is why we did this 'cat' operation just
    % above. However, if you want to display the data in MATLAB's native
    % implay, they must be in the following order: [ x y color z ]. In the
    % latter case, 'permute' is your friend.
    J = cat(4, R,G,B);
    
    % First, we launch Miji. Here we use the launcher in non-interactive mode.
    % The only thing that this will do is actually to set the path so that the
    % subsequent commands and classes can be found by Matlab.
    % We launched it with a 'false' in argument, to specify that we do not want
    % to diplay the ImageJ toolbar. Indeed, this example is a command line
    % example, so we choose not to display the GUI. Feel free to experiment.
    if exist('MIJ','class') == 8
        if ~isempty(ij.gui.Toolbar.getInstance)
            ij_instance = char(ij.gui.Toolbar.getInstance.toString);
            % -> ij.gui.Toolbar[canvas1,3,41,548x27,invalid]
            if numel(strfind(ij_instance, 'invalid')) > 0    % instance already exist, but not shown
                Miji_wrapper(true);     % wrapper to Miji.m file
            end
        else
            Miji_wrapper(true);     % wrapper to Miji.m file
        end
    else
        Miji_wrapper(true);     % wrapper to Miji.m file
    end
    
    % The 3D viewer can only display ImagePlus. ImagePlus is the way ImageJ
    % represent images. We can't feed it directly MATLAB data. Fortunately,
    % that is where MIJ comes into handy. It has a function that can create an
    % ImagePlus from a Matlab object.
    % 1. The first argument is the name we will give to the image.
    % 2. The second argument is the Matlab data
    % 3. The last argument is a boolean. If true, the ImagePlus will be
    % displayed as an image sequence. You might find this useful as well.
    waitbar(0.5, wb,  'Creating the color data...');
    imp = MIJ.createColor('im_browser data', J, false);
else    % do grayscale rendering, faster and requires smaller Java heap size
    subVolume = Volume==minIndex;
    waitbar(0.2, wb,  ...
        sprintf('Reducing the volume to %d x %d x %d px ...',height, width, thick));
    [~,~,~,subVolume] = reducevolume(subVolume,[factorY,factorX,factorZ]);
    subVolume = uint8(subVolume)*254;
    
    if exist('MIJ','class') == 8
        if ~isempty(ij.gui.Toolbar.getInstance)
            ij_instance = char(ij.gui.Toolbar.getInstance.toString);
            % -> ij.gui.Toolbar[canvas1,3,41,548x27,invalid]
            if numel(strfind(ij_instance, 'invalid')) > 0    % instance already exist, but not shown
                Miji_wrapper(true);     % wrapper to Miji.m file
            end
        else
            Miji_wrapper(true);     % wrapper to Miji.m file
        end
    else
        Miji_wrapper(true);     % wrapper to Miji.m file
    end
    
    waitbar(0.5, wb,  'Creating the grayscale data...');
    imp = MIJ.createImage('im_browser data', subVolume, false);
end
%%
% Now comes a little non-mandatory tricky bit.
% By default, the 3D viewer will assume that the image voxel is square,
% that is, every voxel has a size of 1 in the X, Y and Z direction.
% However, for the MRI data we are playing with, this is incorrect, as a
% voxel is 2.5 times larger in the Z direction that in the X and Y
% direction.
% If we do not correct that, the head we are trying to display will look
% flat.
% A way to tell this to the 3D viewer is to create a Calibration object and
% set its public field pixelDepth to 2.5. Then we set this object to be the
% calibration of the ImagePlus, and the 3D viewer will be able to deal with
% it.
waitbar(0.9, wb,  'Set voxel scaling...');
calibration = ij.measure.Calibration();
calibration.pixelWidth = pixSize.x*factorX;
calibration.pixelHeight = pixSize.y*factorY;
calibration.pixelDepth = pixSize.z*factorZ;
%calibration.setUnits = pixSize.units;
%calibration.pixelDepth = (pixSize.z/pixSize.x)/factorZ;
imp.setCalibration(calibration);

%% Display the data in ImageJ 3D viewer
% Now for the display itself.
%
% We create an empty 3D viewer to start with. We do not show it yet.
waitbar(0.95, wb,  'Creating 3D Universe...');
universe = ij3d.Image3DUniverse();

%%
% Now we show the 3D viewer window.
universe.show();

%%
% Then we send it the data, and ask it to be displayed as a volumetric
% rendering.
c = universe.addVoltex(imp);

delete(wb);
end