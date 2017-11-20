function imgOut = mibResize3d(img, scale, options)
% function imgOut = mibResize3d(img, scale, options)
% Resize 3D dataset
%
% Parameters:
% img: a 3D (y,x,z) or 4D (y,x,c,z) dataset for resize
% scale: a number or a vector [scaleY, scaleX, scaleZ] for each dimension with resizing scaling
% factor, could be empty when options.width, options.height, options.depth
% fields are used
% options: [@em optional], additional options
% @li .algorithm - a string with resizing algorithm: 'imresize', 'interpn', 'tformarray', see below for notes
% @li .width - a new width value, overrides the scale parameter
% @li .height - a new height value, overrides the scale parameter
% @li .depth - a new depth value, overrides the scale parameter
% @li .method - interpolation method, specified as a string that identifies
% a general method or a named interpolation kernel: @b imresize: 'nearest',
% 'bilinear', 'bicubic', 'box', 'triangle', 'cubic', 'lanczos2',
% 'lanczos3'; @b interpn: 'linear', 'nearest', 'pchip', 'cubic', 'spline';
% @b tformarray - 'nearest', 'linear','cubic'
% @li .imgType - a string with type of the dataset '4D' or '3D'
% @li .showWaitbar -> [@em optional], when 1-default, show the wait bar, when 0 - do not show the waitbar
%
% Return values:
% imgOut: resampled dataset
%
% @note Resizing algorithms:
% @li 'imresize' - [@em default] (fastest) for R2017a and later uses imresize3 function, otherwise use imresize to resize XY dimension after resize the Z-dimension, gives somewhat softer images than other methods;
% @li 'interpn' - interpolation for 1-D, 2-D, 3-D, and N-D gridded data in
% ndgrid format, quite fast but requires more memory that other methods
% @li 'tformarray' - resize using a spatial transformation to N-D array,
% quite slow but more memory friendly comparing to 'interpn'

% Copyright (C) 25.04.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 11.04.2017, IB added imresize3 if it is available

imgOut = [];
if nargin < 3; options = struct(); end
if nargin < 2; errordlg(sprintf('!!! Error !!!\n\nPlease provide the scaling factor'),'Missing parameters'); return; end;

if ~isfield(options, 'imgType')
    if ndims(img) == 4
        options.imgType = '4D';
    else
        options.imgType = '3D';
    end
end
if strcmp(options.imgType, '3D'); img = permute(img, [1 2 4 3]); end

[height, width, colors, depth] = size(img);

if ~isempty(scale) && numel(scale) == 1
    scale = [scale, scale, scale];
end

if ~isfield(options, 'algorithm'); options.algorithm = 'imresize'; end
if ~isfield(options, 'height'); options.height = round(height*scale(1)); end
if ~isfield(options, 'width'); options.width = round(width*scale(2)); end
if ~isfield(options, 'depth'); options.depth = round(depth*scale(3)); end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end

if ~isfield(options, 'method')
    switch options.algorithm
        case 'imresize'
            options.method = 'bicubic';
        case 'interpn'
            options.method = 'cubic';
        case 'tformarray'
            options.method = 'cubic';
    end
end

switch options.algorithm
    case 'imresize'
        methodsList = {'nearest', 'bilinear', 'bicubic', 'box', 'triangle', 'cubic', 'lanczos2', 'lanczos3'};
    case 'interpn'
        methodsList = {'linear', 'nearest', 'pchip', 'cubic', 'spline'};
    case 'tformarray'
        methodsList = {'nearest', 'linear','cubic'};
end
errorMethod = ismember(options.method, methodsList);
if errorMethod==0
    errordlg(sprintf('!!! Error !!!\n\nWrong combination of resizing algorithm and resizing method. Please use one of the following: %s', cell2mat(arrayfun(@(x) sprintf(' %s', cell2mat(x)), methodsList,'Uniform', false))),'Wrong method');
    return;
end

newH = options.height;
newW = options.width;
newZ = options.depth;

if options.showWaitbar
    wb = waitbar(0, sprintf('Resizing the image:\n[%d %d %d %d] -> [%d %d %d %d]\nusing %s algorithm...',...
        height, width, colors, depth, newH, newW, colors, newZ, options.algorithm), ...
        'Name', 'Resize image');
end

if strcmp(options.algorithm, 'imresize')
    imgOut = zeros([newH, newW, colors, newZ], class(img));   %#ok<ZEROLIKE> % allocate space
    
    if ~isempty(which('imresize3')) && ndims(img)>3     % use imresize3 if it exist, introduced in R2017a, seems to be 30% faster
        if strcmp(options.method, 'bicubic'); options.method = 'cubic'; end
        for colId=1:colors
            imgOut(:,:,colId,:) = permute(imresize3(squeeze(img(:,:,colId,:)), [newH, newW, newZ], options.method), [1 2 4 3]);
        end 
    else    % use older implementation via imresize
        if newW ~= width || newH ~= height  % resize xy dimension
            imgOut2 = zeros(newH, newW, colors, depth, class(img)); %#ok<ZEROLIKE>
            modVal = round(depth/10);
            for zIndex = 1:depth
                imgOut2(:,:,:,zIndex) = imresize(img(:, :, :, zIndex), [newH newW], options.method);
                if mod(zIndex, modVal) == 0 && options.showWaitbar; waitbar(zIndex/depth,wb); end
            end
        end
        if newZ ~= depth
            if exist('imgOut2','var') == 0; imgOut2 = img; end
            if size(imgOut2, 1)*1.82 < size(imgOut2, 2)
                modVal = round(newH/10);
                for hIndex = 1:newH
                    tempImg = imresize(permute(imgOut2(hIndex, :, :, :), [4 2 3 1]), [newZ, newW], options.method);
                    imgOut(hIndex,:,:,:) = permute(tempImg, [4 2 3 1]);
                    if mod(hIndex,modVal) == 0 && options.showWaitbar; waitbar(hIndex/newH,wb); end
                end
            else
                modVal = round(newW/10);
                for wIndex = 1:newW
                    tempImg = imresize(permute(imgOut2(:, wIndex, :, :), [1 4 3 2]), [newH newZ], options.method);
                    imgOut(:,wIndex,:,:) = permute(tempImg, [1 4 3 2]);
                    if mod(wIndex,modVal) == 0 && options.showWaitbar; waitbar(wIndex/newW,wb); end
                end
            end
        else
            imgOut = imgOut2;
        end
    end
elseif strcmp(options.algorithm, 'interpn')
    imgOut = zeros([newH, newW, colors, newZ], class(img));   %#ok<ZEROLIKE> % allocate space
    [xi,yi,zi] = ndgrid(linspace(1, height, newH), linspace(1, width, newW), linspace(1, depth, newZ));
    if options.showWaitbar; waitbar(0.1, wb); end
    for colId=1:colors
        if strcmp(options.method,'nearest')
            imgOut(:,:,colId,:) = permute(interpn(squeeze(img(:,:,colId,:)), xi, yi, zi, options.method),[1 2 4 3]);
        else
            if isa(img,'uint8')
                imgOut(:,:,colId,:) = permute(uint8(interpn(single(squeeze(img(:,:,colId,:))), xi, yi, zi, options.method)),[1 2 4 3]);
            elseif isa(img,'uint16')
                imgOut(:,:,colId,:) = permute(uint16(interpn(single(squeeze(img(:,:,colId,:))), xi, yi, zi, options.method)),[1 2 4 3]);
            end
        end
        if options.showWaitbar; waitbar(colId/colors, wb); end
    end
    if options.showWaitbar; waitbar(0.9, wb); end
else
    imgOut = zeros([newH, newW, colors, newZ], class(img));   %#ok<ZEROLIKE> % allocate space
    hgtForm = makehgtform('scale',[newW/width, newH/height, newZ/depth]);
    tForm = maketform('affine', hgtForm);
    R = makeresampler(options.method, 'replicate');
    
    for colId=1:colors
        imgOut(:,:,colId,:) = permute(tformarray(squeeze(img(:,:,colId,:)), tForm, R, [1 2 3], [1 2 3], [newH, newW, newZ], [], 0), [1 2 4 3]);
    end
end


if strcmp(options.imgType, '3D')
    imgOut = permute(imgOut, [1 2 4 3]);
end

if options.showWaitbar; delete(wb); end

