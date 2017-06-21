function mibSegmentation3dBall(obj, y, x, z, modifier)
% function mibSegmentation3dBall(obj, y, x, z, modifier)
% Do segmentation using the 3D ball tool
%
% Parameters:
% y: y-coordinate of the 3D ball center
% x: x-coordinate of the 3D ball center
% z: z-coordinate of the 3D ball center
% modifier: a string, to specify what to do with the generated selection
% - @em empty - add to 3D ball to the selection layer
% - @em ''control'' - remove 3D ball from the selection layer
%
% Return values:
% 

%| @b Examples:
% @code obj.mibSegmentation3dBall(50, 75, 10, '');  // call from mibController; add a 3D ball to position [y,x,z]=50,75,10 @endcode

% Copyright (C) 16.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

radius = str2double(obj.mibView.handles.mibSegmSpotSizeEdit.String) - 1;
pixSize = obj.mibModel.getImageProperty('pixSize');
minVox = min([pixSize.x pixSize.y pixSize.z]);
ratioX = pixSize.x/minVox;
ratioY = pixSize.y/minVox;
ratioZ = pixSize.z/minVox;
radius = [radius/ratioX radius/ratioX;radius/ratioY radius/ratioY;radius/ratioZ radius/ratioZ];
radius = round(radius);
rad_vec = radius; % vector of radii [-dy +dy;-dx +dx; -dz +dz] for detection out of image border cases
y_max = obj.mibModel.getImageProperty('height'); 
x_max = obj.mibModel.getImageProperty('width');
z_max = obj.mibModel.getImageProperty('depth'); 
if y-radius(1,1)<=0; rad_vec(1,1) = y-1; end
if y+radius(1,2)>y_max; rad_vec(1,2) = y_max-y; end
if x-radius(2,1)<=0; rad_vec(2,1) = x-1; end
if x+radius(2,2)>x_max; rad_vec(2,2) = x_max-x; end
if z-radius(3,1)<=0; rad_vec(3,1) = z-1; end
if z+radius(3,2)>z_max; rad_vec(3,2) = z_max-z; end
max_rad = max(max(radius));
selarea = zeros(max_rad*2+1,max_rad*2+1,max_rad*2+1);    % do strel ball type in volume
[x1,y1,z1] = meshgrid(-max_rad:max_rad,-max_rad:max_rad,-max_rad:max_rad);
ball = sqrt((x1/radius(1,1)).^2+(y1/radius(2,1)).^2+(z1/radius(3,1)).^2);
selarea(ball<=1) = 1;
selarea = selarea(max_rad-rad_vec(1,1)+1:max_rad+rad_vec(1,2)+1,max_rad-rad_vec(2,1)+1:max_rad+rad_vec(2,2)+1,max_rad-rad_vec(3,1)+1:max_rad+rad_vec(3,2)+1);
options.y = [y-rad_vec(1,1) y+rad_vec(1,2)];
options.x = [x-rad_vec(2,1) x+rad_vec(2,2)];
options.z = [z-rad_vec(3,1) z+rad_vec(3,2)];

% do backup
obj.mibModel.mibDoBackup('selection', 1, options);

% limit selection to material of the model
if obj.mibView.handles.mibSegmSelectedOnlyCheck.Value
    selcontour = obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2;  % get selected contour
    model = cell2mat(obj.mibModel.getData3D('model', NaN, 4, selcontour, options));
    selarea = selarea & model;
end

% limit selection to the masked area
if obj.mibView.handles.mibMaskedAreaCheck.Value && obj.mibModel.getImageProperty('maskExist')   % do selection only in the masked areas
    model = cell2mat(obj.mibModel.getData3D('mask', NaN, 4, NaN, options));
    selarea = selarea & model;
end

if isempty(modifier) || strcmp(modifier, 'shift')  % combines selections
    selarea = cell2mat(obj.mibModel.getData3D('selection', NaN, 4, NaN, options)) | selarea;
    obj.mibModel.setData3D('selection', {selarea}, NaN, 4, NaN, options);
elseif strcmp(modifier, 'control')  % subtracts selections
    sel = cell2mat(obj.mibModel.getData3D('selection', NaN, 4, NaN, options));
    sel(selarea==1) = 0;
    obj.mibModel.setData3D('selection', {sel}, NaN, 4, NaN, options);
end
