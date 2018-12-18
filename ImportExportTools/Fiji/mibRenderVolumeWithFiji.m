function result = mibRenderVolumeWithFiji(Volume, pixSize)
% function result = mibRenderVolumeWithFiji(Volume, pixSize)
% Render 3D volume with Fiji
%
% @note requires Fiji to be installed (http://fiji.sc/Fiji).
%
% Parameters:
% Volume: -> a 3D volume to visualize, [1:height, 1:width, 1:color, 1:z]
% pixSize: structure with physical dimensions of voxels
%   - .x - physical width
%   - .y - physical height
%   - .z - physical thickness
%   - .units - physical units
%
% Return values:
% result: -> @b 0 - fail, @b 1 - success 

% Copyright (C) 21.11.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% based on Matlab3DViewerDemo_1.m by Jean-Yves Tinevez \<jeanyves.tinevez at gmail.com\>

result = 0;

if ~isa(Volume, 'uint8')
    msgbox(sprintf('Volume Renderer is implemented for uint8 type!\nCurrent image type is %s', class(Volume)),...
        'Volume data class error!','error');
    return;
end

% check for installed Miji
if ~isdeployed
    if isempty(which('Miji'))
         msgbox(sprintf('Miji was not found!\n\nTo fix:\n1. Install Fiji (http://fiji.sc/Fiji)\n2. Add Fiji.app/Scripts to Matlab path'),...
            'Missing Miji!','error');
        return;
    end
end

%% Make sure Java3D is installed
% If not, try to install it

if ~IsJava3DInstalled(true)
     msgbox(sprintf('Java3D is not installed'),...
        'Java error!','error');
    return;
end

prompt = {'Reduce the volume down to, max width pixels [no volume reduction when 0]?',...
          'Smoothing 3d kernel, width (no smoothing when 0):',...
          'invert the volume (recommended for EM)',...
          'Transparency threshold, use several comma-separated numbers for RGB:'};
defAns = {'512','0', true, 'NaN'};

mibInputMultiDlgOpt.PromptLines = [2, 1, 1, 2];
answer = mibInputMultiDlg([], prompt, defAns, 'Volume parameters', mibInputMultiDlgOpt);
if isempty(answer); return; end

tic

maxVolumeWidth = str2double(answer{1});
if maxVolumeWidth ~= 0
    factorX=ceil(size(Volume,2)/maxVolumeWidth);
    factorY=ceil(factorX*pixSize.x/pixSize.y-.001);
    factorZ=ceil(factorX*pixSize.x/pixSize.z);
else
    factorX=1;
    factorY=1;
    factorZ=1;
end

kernelX = str2double(answer{2});
kernelY = round(kernelX*pixSize.x/pixSize.y) + abs(mod(round(kernelX*pixSize.x/pixSize.y),2)-1);
kernelZ = round(kernelX*pixSize.x/pixSize.z) + abs(mod(round(kernelX*pixSize.x/pixSize.z),2)-1);

wb = waitbar(0, 'Smoothing the volume...','Name','Volume');
if kernelX > 0
        options.fitType = 'Gaussian';
        options.dataType = '4D';
        options.hSize = [kernelX kernelY kernelZ];
        options.sigma = kernelX/5;
        options.pixSize = pixSize;
        options.filters3DCheck = 1;
        Volume = ib_doImageFiltering(Volume, options);
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
end
width = ceil(size(Volume,2)/factorX);
height = ceil(size(Volume,1)/factorY);
thick = ceil(size(Volume,4)/factorZ);

waitbar(0.3, wb, ...
    sprintf('Reducing the volume to %d x %d x %d px ...', height, width, thick));
if factorX ~= 1 || factorY ~= 1 || factorZ ~=1
    binVolume = zeros(height,width,size(Volume,3),thick,class(Volume));
    for color = 1:size(Volume,3)
        [~,~,~,binVolume(:,:,color,:)] = reducevolume(squeeze(Volume(:,:,color,:)),[factorY,factorX,factorZ]);
    end
    Volume = binVolume;
    clear binVolume;
end

% Invert image intensities, Ctrl+I shortcut
invertSwitch = answer{3};
if invertSwitch ==1
    waitbar(0.5, wb,  'Inverting the volume...');
    maxval = intmax(class(Volume));
    for index = 1:size(Volume,4)
        for color=1:size(Volume,3)
        	Volume(:,:,color,index) = maxval - Volume(:,:,color,index);
        end
    end
end

transparencyThresholds = str2num(answer{4}); %#ok<ST2NM>
if invertSwitch && ~isnan(transparencyThresholds)
    transparencyThresholds = double(intmax(class(Volume))) - transparencyThresholds;
end
waitbar(0.5, wb,  'Adding transparency...');
if ~isnan(transparencyThresholds)
    for color = numel(transparencyThresholds)
        Vol = Volume(:,:,color,:);
        Vol(Vol < transparencyThresholds(color)) = 0;
        Volume(:,:,color,:) = Vol;
        clear Vol;
    end
end

waitbar(0.6, wb,  'Preparing the volume...');
if size(Volume, 3) == 1 % grayscale
    %[R G B] = deal(squeeze(Volume));
    R = 1;
    G = 1;
    B = 1;
elseif size(Volume, 3) == 2
    R = squeeze(Volume(:,:,1,:));
    G = squeeze(Volume(:,:,2,:));
    B = zeros(size(squeeze(Volume(:,:,1,:))),class(Volume));
else    
    R = squeeze(Volume(:,:,1,:));
    G = squeeze(Volume(:,:,2,:));
    B = squeeze(Volume(:,:,3,:));  
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
if size(Volume,3) == 1 % grayscale
    waitbar(0.7, wb,  'Creating the grayscale data...');
    imp = MIJ.createImage('im_browser data', squeeze(Volume), false);
else
    waitbar(0.7, wb,  'Creating the color data...');
    imp = MIJ.createColor('im_browser data', J, false);    
end

%%
% Since we had a color volume (4D data), we used the createColor method. If
% we had only a grayscale volume (3D data), we could have used the
% createImage method instead, which works the same.

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
toc
result = 1;
end