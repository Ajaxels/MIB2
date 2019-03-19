function mask = mibGetMorphMask(img, Options)
% function mask = mibGetMorphMask(img, Options)
% Return result of BW Morphological filters generated from img
%
% Parameters:
% img: -> input image, [1:height, 1:width, 1:color, 1:layers]
% Options: -> a structure with Parameters
%  - .type -> a string with the function ('Extended-maxima transform', 'Extended-minima transform',
%   'Regional maxima', 'Regional minima')
%  - .threeD -> 3d switch (1-3d space, 0-2d space)
%  - .all_sw -> indicates full stack or single layer
%  - .orientation -> indicates dimension for 2d iterations, 1-for XZ, 2 - YZ, 4  -XY
%  - .currentIndex -> index of the current slice
%
% Return values:
% mask: generated mask image [1:height,1:width,1:no_stacks], (0/1);

% Copyright (C) 12.03.2015, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

max_layers = size(img, Options.orientation);  % maximal index for 2d iteration
xmax = size(img,2);
ymax = size(img,1);
zmax = size(img,4);
mask = zeros(size(img,1), size(img,2), size(img,4), 'uint8');

% get current parallel pool object
try
    poolobj = gcp('nocreate');
    if isempty(poolobj)
        noCores = 0; 
    else
        noCores = poolobj.NumWorkers;
    end
catch
    noCores = 0;
end

if Options.all_sw == 1
    start_no = 1;
    end_no = max_layers;
else
    start_no = Options.currentIndex;
    end_no = start_no;
end

if Options.threeD       % apply filter in 3d space
    wb = waitbar(0,sprintf('Generating %s 3D mask...\nPlease wait...', Options.type), 'Name',Options.type, 'WindowStyle', 'modal');
    waitbar(0.1, wb);
    switch Options.type
        case 'Extended-maxima transform'
            mask = imextendedmax(squeeze(img), Options.h, Options.conn);
        case 'Extended-minima transform'
            mask = imextendedmin(squeeze(img), Options.h, Options.conn);
        case 'H-maxima transform'
            mask = imhmax(squeeze(img), Options.h, Options.conn);
        case 'H-minima transform'
            mask = imhmin(squeeze(img), Options.h, Options.conn);
        case 'Regional maxima'
            mask = imregionalmax(squeeze(img),Options.conn);
        case 'Regional minima'
            mask = imregionalmin(squeeze(img),Options.conn);
        otherwise
            delete(wb);
            errordlg(sprintf('!!! ERROR !!!\nWrong type, please use one of the following:\n"Extended-maxima transform","Extended-minima transform","Regional maxima", "Regional minima"'),'Error');
            return;
    end
    waitbar(1, wb);
else    % apply filter slice by slice in 2D
    wb = waitbar(0,sprintf('Generating %s 2D mask...\nPlease wait...', Options.type),'Name',Options.type,'WindowStyle','modal');
    type = Options.type;
    if Options.orientation == 4     % xy plane
        tic
        parfor (layer=start_no:end_no, noCores)
        %for layer=start_no:end_no
        %parfor layer=start_no:end_no
            switch type
                case 'Extended-maxima transform'
                    bw = imextendedmax(img(:,:,:,layer), Options.h, Options.conn);
                case 'Extended-minima transform'
                    bw = imextendedmin(img(:,:,:,layer), Options.h, Options.conn);
                case 'H-maxima transform'
                    bw = imhmax(img(:,:,:,layer), Options.h, Options.conn);
                case 'H-minima transform'
                    bw = imhmin(img(:,:,:,layer), Options.h, Options.conn);
                case 'Regional maxima'
                    bw = imregionalmax(img(:,:,:,layer), Options.conn);
                case 'Regional minima'
                    bw = imregionalmin(img(:,:,:,layer), Options.conn);
            end
            mask(:,:,layer) = bw;
        end
        toc
    elseif Options.orientation == 1     % xz plane
        parfor (layer=start_no:end_no, noCores)
            switch type
                case 'Extended-maxima transform'
                    bw = imextendedmax(squeeze(img(layer,:,:,:)), Options.h, Options.conn);
                case 'Extended-minima transform'
                    bw = imextendedmin(squeeze(img(layer,:,:,:)), Options.h, Options.conn);
                case 'H-maxima transform'
                    bw = imhmax(squeeze(img(layer,:,:,:)), Options.h, Options.conn);
                case 'H-minima transform'
                    bw = imhmin(squeeze(img(layer,:,:,:)), Options.h, Options.conn);
                case 'Regional maxima'
                    bw = imregionalmax(squeeze(img(layer,:,:,:)), Options.conn);
                case 'Regional minima'
                    bw = imregionalmin(squeeze(img(layer,:,:,:)), Options.conn);
            end
            mask(layer,:,:) = bw;
        end
    elseif Options.orientation == 2     % yz plane
        parfor (layer=start_no:end_no, noCores)
            switch type
                case 'Extended-maxima transform'
                    bw = imextendedmax(squeeze(img(:,layer,:,:)), Options.h, Options.conn);
                case 'Extended-minima transform'
                    bw = imextendedmin(squeeze(img(:,layer,:,:)), Options.h, Options.conn);
                case 'H-maxima transform'
                    bw = imhmax(squeeze(img(:,layer,:,:)), Options.h, Options.conn);
                case 'H-minima transform'
                    bw = imhmin(squeeze(img(:,layer,:,:)), Options.h, Options.conn);
                case 'Regional maxima'
                    bw = imregionalmax(squeeze(img(:,layer,:,:)), Options.conn);
                case 'Regional minima'
                    bw = imregionalmin(squeeze(img(:,layer,:,:)), Options.conn);
            end
            mask(:,layer,:) = bw;
        end
    else
        error('[Error] Morphological Mask Filter: unsupported dimention/orientation!');
    end
end
% do additional thresholding for H-max H-min transforms
if ismember(type, {'H-maxima transform', 'H-minima transform'})
    mask(mask < Options.Hthres) = 0;
    mask(mask >= Options.Hthres) = 1;
end
delete(wb);
end