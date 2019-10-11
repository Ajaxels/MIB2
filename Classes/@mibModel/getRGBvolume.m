function imgRGB = getRGBvolume(obj, img, options)
% function imgRGB = getRGBvolume(obj, img, options)
% Generate RGB volume rendering image of the stack
%
% Parameters:
% img: 3D/4D stack [y,x,c,z]
% options: a structure with extra parameters:
% @li .RenderType -> maximum intensitity projections (default) 'mip', 
%                   greyscale volume rendering 'bw', color volume rendering
%                   'color' and volume rendering with shading 'shaded'
% @li .Mview -> this 4x4 matrix is the viewing matrix
%                   defaults to [1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1]
% @li .ImageSize -> size of the rendered image, defaults to [400 400]
% @li .ShearInterp -> interpolation method used in the Shear steps
%                   of the shearwarp algoritm, nearest or (default) bilinear
% @li .WarpInterp -> interpolation method used in the warp step
%                   of the shearwarp algoritm, nearest or (default)
%                   bilinear
% @li .AlphaTable -> This Nx1 table is linear interpolated such that every
%                   voxel intensity gets a specific alpha (transparency)
%                   [0 0.01 0.05 0.1 0.2 1 1 1 1 1] 
% @li .ColorTable -> this Nx3 table is linear interpolated such that
%                   every voxel intensity gets a specific color. 
%                   defaults to [1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0] 
% @li .LightVector -> Light Direction defaults to [0.67 0.33 -0.67]
% @li .ViewerVector -> View vector X,Y,Z defaults to [0 0 1]
% @li .ShadingMaterial -> The type of material shading : dull, shiny(default) or metal.
%
% Return values:
% imgRGB: - RGB image with combined layers, [1:height, 1:width, 1:3]
%

% Copyright (C) 24.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if ~isfield(options, 'ImageSize')
    options.ImageSize = [400, 400];
end

currViewPort = obj.I{obj.Id}.viewPort;
colorIndices = obj.I{obj.Id}.slices{3};
if obj.I{obj.Id}.useLUT     % use LUT for colors
    selectedColorsLUT = obj.I{obj.Id}.lutColors(colorIndices,:);
else
    selectedColorsLUT = [1 0 0; 0 1 0; 0 0 1];  % RGB
end

R = zeros([options.ImageSize(1), options.ImageSize(2)]);
G = zeros([options.ImageSize(1), options.ImageSize(2)]);
B = zeros([options.ImageSize(1), options.ImageSize(2)]);

% force to change ShearInterp for a single slice
if size(img, 4) == 1
    options.ShearInterp = 'bilinear';
end

for colCh = 1:numel(colorIndices)
    options.imin = currViewPort.min(colorIndices(colCh));
    options.imax = currViewPort.max(colorIndices(colCh));
    imgOut = render(squeeze(img(:,:,colorIndices(colCh),:)), options);
    
    %if currViewPort.min(colorIndices(colCh)) ~= 0 || currViewPort.max(colorIndices(colCh)) ~= max_int || currViewPort.gamma(colorIndices(colCh)) ~= 1
    %    imgOut = imadjust(imgOut, [currViewPort.min(colorIndices(colCh))/max_int ...
    %        currViewPort.max(colorIndices(colCh))/max_int], [0 1], currViewPort.gamma(colorIndices(colCh)));
    %end    
    if obj.I{obj.Id}.useLUT == 0 && numel(colorIndices) == 1    % render in grayscale
        R = imgOut*255;
        G = R;
        B = R;
    else
        R = R + imgOut*255*selectedColorsLUT(colCh, 1);
        G = G + imgOut*255*selectedColorsLUT(colCh, 2);
        B = B + imgOut*255*selectedColorsLUT(colCh, 3);
    end
end
imgRGB = cat(3,uint8(R), uint8(G), uint8(B));
end