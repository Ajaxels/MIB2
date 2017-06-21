function mask = mibGetStrelMask(img, Options)
% function mask = mibGetStrelMask(img, Options)
% Return Strel mask (imtophat/imbothat) generated from the img
%
% Parameters:
% img: -> input image, [1:height, 1:width, 1:color, 1:layers]
% Options: -> a structure with Parameters
%  - .se_size -> size of the structural element, vector (xy, z)
%  - .bwthreshold -> threshold value for mask generation
%  - .sizefilter -> size exclusion limit, the objects that are smaller than this number will be removed.
%  - .strelfill -> fill the holes in the resulted image
%  - .blackwhite -> switch that defines that the background is white (1), or black (0)
%  - .threeD -> 3d switch (1-3d space, 0-2d space)
%  - .all_sw -> indicates full stack or single layer
%  - .orientation -> indicates dimension for 2d iterations, 1-for XZ, 2 - YZ, 4  -XY
%  - .currentIndex -> index of the current slice
%
% Return values:
% mask: generated mask image [1:height,1:width,1:no_stacks], (0/1);

% Copyright (C) 21.11.2013, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

max_layers = size(img, Options.orientation);  % maximal index for 2d iteration
xmax = size(img, 2);
ymax = size(img, 1);
zmax = size(img, 4);
mask = zeros(size(img,1), size(img,2), size(img,4), 'uint8'); 

if Options.all_sw == 1
    start_no = 1;
    end_no = max_layers;
else
    start_no = Options.currentIndex;
    end_no = start_no;
end

blackwhite = Options.blackwhite;
strelfill = Options.strelfill;
bwthreshold = Options.bwthreshold;
sizefilter = Options.sizefilter;

if Options.threeD       % apply filter in 3d space
    se_size = Options.se_size;
    wb = waitbar(0,sprintf('Generating Strel 3d filtered mask...\nStrel width: [XxYxZ]=%dx%dx%d',se_size(1)*2+1,se_size(1)*2+1,se_size(2)*2+1),'Name','Strel filter','WindowStyle','modal');
    se = zeros(se_size(1)*2+1,se_size(1)*2+1,se_size(2)*2+1);    % do strel ball type in volume
    [x,y,z] = meshgrid(-se_size(1):se_size(1),-se_size(1):se_size(1),-se_size(2):se_size(2));
    ball = sqrt((x/se_size(1)).^2+(y/se_size(1)).^2+(z/se_size(2)).^2);
    se(ball<=1) = 1;
    waitbar(0.1, wb);
    if Options.threeD && start_no==end_no   % do 3d filter for a single slice
        % trim the image
        if Options.orientation == 4     % xy plane
            img_trim = img(:,:,:,max([1 start_no-se_size(2)]):min([end_no+se_size(2) zmax]));
        elseif Options.orientation == 1     % xz plane
            img_trim = img(max([1 start_no-se_size(1)]):min([end_no+se_size(1) ymax]),:,:,:);
        elseif Options.orientation == 2     % yz plane
            img_trim = img(:,max([1 start_no-se_size(1)]):min([end_no+se_size(1) xmax]),:,:);
        else
            error('[Error] Strel Mask Filter: unsupported dimention/orientation!');
        end
        
        if blackwhite   % white background
            result = imbothat(squeeze(img_trim),se);
        else            % black background
            result = imtophat(squeeze(img_trim),se);
        end
        waitbar(0.5, wb);
        
        mask_trim = zeros([size(img_trim,1) size(img_trim,2) size(img_trim,4)],'uint8');
        max_trim_layers = size(mask_trim,3);
        for layer=1:max_trim_layers   % convert to bitmap image
            mask_trim(:,:,layer) = im2bw(result(:,:,layer), bwthreshold);
        end
        if strelfill    % fill holes
            mask_trim = imfill(mask_trim,'holes');
        end
        if Options.orientation == 4     % xy plane
            mask(:,:,Options.currentIndex) =  mask_trim(:,:,round(size(mask_trim,3)/2));
        elseif Options.orientation == 1     % xz plane
            mask(Options.currentIndex,:,:) = squeeze(mask_trim(round(size(mask_trim,1)/2),:,:));
        elseif Options.orientation == 2     % yz plane
            mask(:,Options.currentIndex,:) = squeeze(mask_trim(:,round(size(mask_trim,2)/2),:));
        end
    else    % do 3d filter for a whole dataset
        if blackwhite
            result = imbothat(squeeze(img),se);
        else
            result = imtophat(squeeze(img),se);
        end
        waitbar(0.5, wb);
        for layer=1:zmax
            mask(:,:,layer) = im2bw(result(:,:,layer), bwthreshold);
        end
        waitbar(0.75, wb);
        if strelfill
            mask = imfill(mask,'holes');
        end
    end
    waitbar(1, wb);
else    % apply filter slice by slice in 2d
    wb = waitbar(0,'Generating Strel 2d filtered mask...','WindowStyle','modal');
    se = strel('disk',Options.se_size(1), 0); % create a structural element
    if Options.orientation == 4     % xy plane
        parfor layer=start_no:end_no
            if blackwhite       % background is white
                result = imbothat(img(:,:,:,layer),se);
            else                % background is black
                result = imtophat(img(:,:,:,layer),se);
            end
            result = im2bw(result, bwthreshold);
            if strelfill    % fill holes
                result = imfill(result,'holes');
            end
            bw = bwareaopen(result, sizefilter);    % remove small objects
            mask(:,:,layer) = bw;
        end
    elseif Options.orientation == 1     % xz plane
        parfor layer=start_no:end_no
            if blackwhite       % background is white
                result = im2bw(imbothat(squeeze(img(layer,:,:,:)),se),bwthreshold);
            else                % background is black
                result = im2bw(imtophat(squeeze(img(layer,:,:,:)),se),bwthreshold);
            end
            if strelfill    % fill holes
                result = imfill(result,'holes');
            end
            bw = bwareaopen(result, sizefilter);    % remove small objects
            mask(layer,:,:) = bw;
        end
    elseif Options.orientation == 2     % yz plane
        parfor layer=start_no:end_no
            if blackwhite       % background is white
                result = im2bw(imbothat(squeeze(img(:,layer,:,:)),se),bwthreshold);
            else                % background is black
                result = im2bw(imtophat(squeeze(img(:,layer,:,:)),se),bwthreshold);
            end
            if strelfill    % fill holes
                result = imfill(result,'holes');
            end
            bw = bwareaopen(result, sizefilter);    % remove small objects
            mask(:,layer,:) = bw;
        end
    else
         error('[Error] Strel Mask Filter: unsupported dimention/orientation!');
    end
end
delete(wb);
end