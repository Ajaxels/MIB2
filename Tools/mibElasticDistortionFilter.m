function [img, DisplacementField, randomSeed] = mibElasticDistortionFilter(img, BatchOpt, randomSeed, DisplacementField)
% function img = mibElasticDistortionFilter(img, BatchOpt, randomSeed)
% apply elastic deformations to img, the code is based on Best Practices for Convolutional Neural Networks
% Applied to Visual Document Analysis by Patrice Y. Simard, Dave Steinkraus, John C. Platt
% http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.160.8494&rep=rep1&type=pdf
% and codes available at
% - https://stackoverflow.com/questions/39308301/expand-mnist-elastic-deformations-matlab
% - https://se.mathworks.com/matlabcentral/fileexchange/66663-elastic-distortion-transformation-on-an-image
%
% 
% Parameters:
% img: image as [height, width, colors, depth]
% BatchOpt: structure with parameters
% @li .ScalingFactor{1} - [number] defines extension length for deformations
% @li .HSize - [char] strel element size for the Gaussian filter
% @li .Sigma{1} - [number] sigma value for the Gaussian filter
% @li .SourceLayer{1} - [string], type of the dataset, 'image', 'model'... when not 'image' use nearest interpolation
% @li .Mode3D - [logical] distort img in 3D (not yet implemented)
% @li .showWaitbar - logical, show or not the waitbar
% @li .UseParallelComputing - logical, use or not the parallel computing
% randomSeed: [optional], [number], seed to init the random generator
% DisplacementField: [optional], a displacement field to use, a structure, should match img [height, width, depth]
% .fdx
% .fdy
% .fdz
%
% Return values:
% img: image filtered with  elastic distortions
% DisplacementField: displacement field used in the filter
% randomSeed:  random seed used to init the field, [] if the field was provided

% Copyright (C) 06.06.2020 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 4; DisplacementField = struct(); end
if nargin < 3; randomSeed = 0; end
if nargin < 2; BatchOpt = struct; end

if ~isfield(BatchOpt, 'HSize'); BatchOpt.HSize = '7'; end
if ~isfield(BatchOpt, 'ScalingFactor'); BatchOpt.ScalingFactor{1} = 30; end
if ~isfield(BatchOpt, 'Sigma'); BatchOpt.Sigma{1} = 4; end
if ~isfield(BatchOpt, 'Mode3D'); BatchOpt.Mode3D = false; end
if ~isfield(BatchOpt, 'SourceLayer'); BatchOpt.SourceLayer{1} = 'image'; end
if ~isfield(BatchOpt, 'showWaitbar'); BatchOpt.showWaitbar = true; end
if ~isfield(BatchOpt, 'UseParallelComputing'); BatchOpt.UseParallelComputing = false; end

HSize = str2num(BatchOpt.HSize); %#ok<ST2NM>
HSize = HSize - mod(HSize,2) + 1; % should be an odd number
if numel(HSize) == 1; HSize = repmat(HSize, [3,1]); end

% init random generator
rng(randomSeed);

interpolationType = 'natural';
if ~strcmp(BatchOpt.SourceLayer{1}, 'image')
    interpolationType = 'nearest';  % for model, selection, mask
end

% generate displacement field
if ~isfield(DisplacementField, 'fdx')
    if BatchOpt.Mode3D == 0
        % Compute a random displacement field
        dx = -1+2*rand([size(img, 1), size(img, 2)]);
        dy = -1+2*rand([size(img, 1), size(img, 2)]);
        
        % Normalizing the field
        nx = norm(dx);
        ny = norm(dy);
        dx = dx./nx; % Normalization: norm(dx) = 1
        dy = dy./ny; % Normalization: norm(dy) = 1
        
        % Smoothing the field
        DisplacementField.fdx = imgaussfilt(dx, BatchOpt.Sigma{1}, 'FilterSize', HSize(1)); % 2-D Gaussian filtering of dx
        DisplacementField.fdy = imgaussfilt(dy, BatchOpt.Sigma{1}, 'FilterSize', HSize(2)); % 2-D Gaussian filtering of dy
        
        % scale the field
        DisplacementField.fdx = BatchOpt.ScalingFactor{1} * DisplacementField.fdx; 
        DisplacementField.fdy = BatchOpt.ScalingFactor{1} * DisplacementField.fdy; 
        
%         % preview
%         [y, x] = ndgrid(1:size(img,1), 1:size(img,2));
%         figure;
%         imagesc(img(:,:,1,:)); colormap gray; axis image; axis tight;
%         hold on;
%         quiver(x,y,DisplacementField.fdx, DisplacementField.fdy, 0, 'r');
    else
%         % Compute a random displacement field
%         dx = -1+2*rand([size(img, 1), size(img, 2), size(img, 4)]);
%         dy = -1+2*rand([size(img, 1), size(img, 2), size(img, 4)]);
%         dz = -1+2*rand([size(img, 1), size(img, 2), size(img, 4)]);
%         
%         % Smoothing the field
%         DisplacementField.fdx = imgaussfilt(dx, BatchOpt.Sigma{1}, 'FilterSize', HSize(1)); % 2-D Gaussian filtering of dx
%         DisplacementField.fdy = imgaussfilt(dy, BatchOpt.Sigma{1}, 'FilterSize', HSize(2)); % 2-D Gaussian filtering of dy
%         DisplacementField.fdz = imgaussfilt(dz, BatchOpt.Sigma{1}, 'FilterSize', HSize(3)); % 2-D Gaussian filtering of dz
%         
%         n=sum((DisplacementField.fdx(:).^2 + DisplacementField.fdy(:).^2 + DisplacementField.fdz(:).^2));
%         
%         % scale the field
%         DisplacementField.fdx = BatchOpt.ScalingFactor{1} * DisplacementField.fdx./n; 
%         DisplacementField.fdy = BatchOpt.ScalingFactor{1} * DisplacementField.fdy./n; 
%         DisplacementField.fdz = BatchOpt.ScalingFactor{1} * DisplacementField.fdz./n; 
    end
end

if BatchOpt.Mode3D == 0     % 2D
    [y, x] = ndgrid(1:size(img,1), 1:size(img,2));
    for colCh=1:size(img, 3)
        %currImg = double(img(:,:,colCh));
        %filteredImage = griddata(x-DisplacementField.fdx, y-DisplacementField.fdy, currImg, x, y, interpolationType);
        %filteredImage(isnan(filteredImage)) = currImg(isnan(filteredImage));
        
        filteredImage = griddata(x-DisplacementField.fdx, y-DisplacementField.fdy, double(img(:,:,colCh)), x, y, interpolationType);
        filteredImage(isnan(filteredImage)) = 0;
        img(:,:,colCh) = filteredImage;
    end    
else
%     [y, x, z] = ndgrid(1:size(img,1), 1:size(img,2), 1:size(img,4));
%     for colCh=1:size(img, 3)
%         filteredImage = griddata(x-DisplacementField.fdx, y-DisplacementField.fdy, z-DisplacementField.fdz,...
%             double(squeeze(img(:,:,colCh,:))), x, y, z, interpolationType);
%         filteredImage(isnan(filteredImage)) = 0;
%         img(:,:,colCh,:) = permute(filteredImage, [1 2 4 3]);
%     end
end




end

            
