function [img, logText] = mibDoImageFiltering(img, options)
% function [img, logText] = ib_doImageFiltering(img, options)
% Filter image with basic Matlab filters
%
% Parameters:
% img: -> image stack, [1:height, 1:width, 1:color, 1:layers]
% options: -> a structure with parameters
% - .dataType - type of the dataset, ''4D'' - [height, width, color, z], ''3D'' - [height, width, z]
% - .fitType - type of the filter to use: ''Gaussian 3d'', ''Gaussian'', ''Disk'', ''Motion'', ''Unsharp'',''Median
% 2D'', ''Median 3D'', ''Wiener 2D'', ''Average'', ''Motion''
% - .colorChannel - color channel to filter, when @b 0 filter all channels
% - .hSize - size of the Kernel to use, or Ratio for the Frangi filter
% - .sigma - sigma for the filters, or Ratio for the Frangi filter (if required)
% - .lambda - lambda for the filters, or beta1 for Frangi (if required)
% - .beta2 - beta2 value for Frangi filter (if required)
% - .beta3 - beta3 value for Frangi 3D filter (if required)
% - .BlackWhite - BlackWhite switch indicating black ridges over white background for Frangi filter (if required)
% - .pixSize - voxel sizes for 3D gaussian (imageData.pixSize.x imageData.pixSize.y imageData.pixSize.z)
% - .orientation - orientation of the dataset for 2D filters,  1-for XZ, 2 - YZ, 4  - XY
% - .padding - a string with a padding value: 'symmetric' - pad array with
% mirror reflections of itself, 'replicate' - pad array by repeating border
% elements, 'zeros' - pad array with 0s
% - .showWaitbar - [@em optional], when 1-default, show the wait bar, when 0 - do not show the waitbar
%
% Return values:
% img: filtered dataset, [1:height, 1:width, 1:color, 1:no_stacks]
% logText: log text with parameters of the applied filter

% Copyright (C) 13.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 19.04.2017, IB added median 3D filter

logText = NaN;

if isfield(options,'sigma') && options.sigma <= 0; error('ib_doImageFiltering: Sigma should be above zero!'); end
if ~isfield(options, 'pixSize') && strcmp(options.fitType, 'Gaussian 3D')
    error('ib_doImageFiltering: such call requires specification of pixSize!');
end
if ~isfield(options, 'colorChannel'); options.colorChannel = 0; end
if ~isfield(options,'showWaitbar'); options.showWaitbar=1; end

if options.showWaitbar
    wb = waitbar(0,['Applying ' options.fitType ' filter...'],'Name','Filtering','WindowStyle','modal');
end

if strcmp(options.dataType, '3D')   % reshape image, for selection and mask
    img = reshape(img,[size(img,1), size(img,2), 1, size(img,3)]);
end

if options.colorChannel == 0
    color_start = 1;
    color_end = size(img,3);
else
    if size(img,3) == 1
        color_start = 1;
        color_end = 1;
    else
        color_start = options.colorChannel;
        color_end = options.colorChannel;
    end
end
matlabVersion = ver('Matlab');
matlabVersion = str2double(matlabVersion(1).Version);

if strcmp(options.fitType,'Gaussian 3D')       % 3d gaussian filter
    if size(img,4) < 3
        delete(wb);
        msgbox('Gaussian 3D filter requires more than 2 layers!','Error!','error');
        return;
    end
    if numel(options.hSize) == 1
        z_kernel =  round(options.hSize(1)*options.pixSize.x/options.pixSize.z);     % kernel dimensions for z-direction
    else
        z_kernel = options.hSize(2);
    end
    for color_ch=color_start:color_end
        GaussXY =  fspecial('gaussian',[options.hSize(1) 1],options.sigma);
        GaussZ =  fspecial('gaussian',[z_kernel 1],options.sigma);
        Hx=reshape(GaussXY,[length(GaussXY) 1 1 1]);
        Hy=reshape(GaussXY,[1 length(GaussXY) 1 1]);
        Hz=reshape(GaussZ,[1 1 1 length(GaussZ)]);
        img(:,:,color_ch,:) = imfilter(imfilter(imfilter(img(:,:,color_ch,:),Hx,'replicate'),Hy,'replicate'),Hz,'replicate');
    end
    if strcmp(options.dataType, '3D')   % reshape image, for selection and mask
        img = squeeze(img);
    end
    logText = ['ImFilter: ' options.fitType ', HSize:' num2str(options.hSize) ...
        ', ZSize:' num2str(z_kernel) ', Sigma: ' num2str(options.sigma) ',ColCh:' num2str(options.colorChannel)];
elseif strcmp(options.fitType,'Gradient 3D')       % 3d gradient filter
    if size(img,4) < 3
        delete(wb);
        msgbox('Gradient 3D filter requires more than 2 layers!','Error!','error');
        return;
    end
    for color_ch=color_start:color_end
        [Ix,Iy,Iz] = gradient(double(squeeze(img(:,:,color_ch,:))));
        img2 = sqrt(Ix.^2 + Iy.^2 + Iz.^2);
        img(:,:,color_ch,:) = img2/max(max(max(img2)))*double(intmax(class(img)));      % convert to data type
    end
    if strcmp(options.dataType, '3D')   % reshape image, for selection and mask
        img = squeeze(img);
    end
    logText = ['ImFilter: ' options.fitType ', ColCh:' num2str(options.colorChannel)];
elseif strcmp(options.fitType,'Frangi 3D')       % 3D Frangi filter
    FrangiOptions.FrangiScaleRange = options.hSize;
    FrangiOptions.FrangiScaleRatio = options.sigma;
    FrangiOptions.FrangiAlpha = options.lambda;
    FrangiOptions.FrangiBeta = options.beta2;
    FrangiOptions.FrangiC  = options.beta3;
    FrangiOptions.BlackWhite = options.BlackWhite;
    FrangiOptions.verbose = 0;
    
    J = FrangiFilter3D(squeeze(img), FrangiOptions);
    img = cast(J*25*double(intmax(class(img))), 'like', img);
    
    if strcmp(options.dataType, '4D')   % reshape image, for selection and mask
        img = permute(img, [1 2 4 3]);
    end
    
    logText = ['ImFilter: ' options.fitType ', Range:' num2str(options.hSize) ', Ratio: ' num2str(options.sigma) ...
               ', beta1: ' num2str(options.lambda) ', beta2: ' num2str(options.beta2) ...
               ', beta3:' num2str(options.beta3) ',ColCh:' num2str(options.colorChannel)];
elseif strcmp(options.fitType,'Median 3D')       % 3D Median
    if numel(options.hSize) == 1
        z_kernel =  round(options.hSize(1)*options.pixSize.x/options.pixSize.z);     % kernel dimensions for z-direction
    else
        z_kernel = options.hSize(2);
    end
    
    for color_ch=color_start:color_end
        img2 = medfilt3(squeeze(img(:,:,color_ch,:)), [options.hSize(1), options.hSize(1), z_kernel], options.padding);
        
        if strcmp(options.dataType, '4D')   % reshape image, for selection and mask
            img(:,:,color_ch,:) = permute(img2, [1 2 4 3]);
        end
    end
    logText = ['ImFilter: ' options.fitType ', ColCh:' num2str(options.colorChannel) ', Kernel:' num2str(options.hSize(1)) '/' num2str(z_kernel), ', Padding:' options.padding];
else    % 2D filters
    if strcmp(options.fitType,'Disk') || strcmp(options.fitType,'Motion') || strcmp(options.fitType,'Unsharp')
        options.hSize = options.hSize(1);
    end
    
    max_layers = size(img, 4);
    
    % generate filter and log_text
    switch options.fitType
        case {'Median 2D', 'Wiener 2D'}
            log_text = ['ImFilter: ' options.fitType ', HSize:' num2str(options.hSize) ...
                ',Orient:' num2str(options.orientation) ',ColCh:' num2str(options.colorChannel)];
        case 'Unsharp'
            if matlabVersion >= 8.1
                log_text = ['ImFilter: ' options.fitType ', Radius:' num2str(options.hSize) ...
                    ',Amount:' num2str(options.sigma) ',Thres:' num2str(options.lambda) ...
                    ',Orient:' num2str(options.orientation) ',ColCh:' num2str(options.colorChannel)];
            else
                filter2d = fspecial(options.fitType, options.hSize);
                log_text = ['ImFilter: ' options.fitType ', HSize:' num2str(options.hSize) ...
                    ',Orient:' num2str(options.orientation) ',ColCh:' num2str(options.colorChannel)];
            end
        case 'Gradient 2D'
            log_text = ['ImFilter: ' options.fitType ',ColCh:' num2str(options.colorChannel)];
        case 'Frangi 2D'
            FrangiOptions.FrangiScaleRange = options.hSize;
            FrangiOptions.FrangiScaleRatio = options.sigma;
            FrangiOptions.FrangiBetaOne = options.lambda;
            FrangiOptions.FrangiBetaTwo = options.beta2;
            FrangiOptions.BlackWhite = options.BlackWhite;
            FrangiOptions.verbose = 0;
            log_text = ['ImFilter: ' options.fitType ', Range:' num2str(options.hSize) ', Ratio: ' num2str(options.sigma) ...
                ', beta1: ' num2str(options.lambda) ', beta2: ' num2str(options.beta2) ...
                    ',Orient:' num2str(options.orientation) ',ColCh:' num2str(options.colorChannel)];
        otherwise
            if isfield(options, 'sigma') && isfield(options, 'hSize')
                filter2d = fspecial(options.fitType, options.hSize, options.sigma);
                log_text = ['ImFilter: ' options.fitType ', HSize:' num2str(options.hSize) ...
                    ', Sigma: ' num2str(options.sigma) ',Orient:' num2str(options.orientation) ',ColCh:' num2str(options.colorChannel)];
            elseif isfield(options, 'sigma')
                filter2d = fspecial(options.fitType, options.sigma);
                log_text = ['ImFilter: ' options.fitType, ',Sigma: ' num2str(options.sigma) ',Orient:' num2str(options.orientation) ',ColCh:' num2str(options.colorChannel)];
            else
                filter2d = fspecial(options.fitType, options.hSize);
                log_text = ['ImFilter: ' options.fitType ', HSize:' num2str(options.hSize) ...
                    ',Orient:' num2str(options.orientation) ',ColCh:' num2str(options.colorChannel)];
            end
    end
    
    for id = 1:size(img, 4)
        % each pixel in the result is a sum of neightbour pixels multiplied
        % with coefficients provided in filter2d
        for color_ch=color_start:color_end
            switch options.fitType
                case 'Median 2D'
                    img(:,:,color_ch,id) = medfilt2(img(:,:,color_ch,id), options.hSize, 'symmetric');
                case 'Wiener 2D'
                    img(:,:,color_ch,id) = wiener2(img(:,:,color_ch,id),options.hSize);
                case 'Gradient 2D'
                    [Ix,Iy] = gradient(double(img(:,:,color_ch,id)));
                    img2 = sqrt(Ix.^2 + Iy.^2);
                    img(:,:,color_ch,id) = img2/max(max(max(img2)))*double(intmax(class(img)));
                case 'Frangi 2D'
                    %img(:,:,color_ch,id) = FrangiFilter2D(img(:,:,color_ch,id), FrangiOptions);
                    imgOut = FrangiFilter2D(double(img(:,:,color_ch,id)), FrangiOptions);
                    img(:,:,color_ch,id) = imgOut*double(intmax(class(img)));
                case 'Unsharp'
                    if matlabVersion >= 8.1
                        img(:,:,color_ch,id) = imsharpen(img(:,:,color_ch,id),'Radius',options.hSize,'Amount',options.sigma, 'Threshold', options.lambda);
                    else
                        img(:,:,color_ch,id) = imfilter(img(:,:,color_ch,id), filter2d, 'replicate');
                    end
                case 'Log'
                    %tempImg = imfilter(double(img(:,:,color_ch,id)), filter2d, 'replicate');
                    %minVal = min(min(tempImg));
                    %maxVal = max(max(tempImg));
                    %img(:,:,color_ch,id) = (tempImg-minVal)/(maxVal-minVal)*double(intmax(class(img)));
                    img(:,:,color_ch,id) = imfilter(img(:,:,color_ch,id), filter2d, 'replicate');
                otherwise
                    img(:,:,color_ch,id) = imfilter(img(:,:,color_ch,id), filter2d, 'replicate');
            end
        end
        if options.showWaitbar && mod(id, 10)==0; waitbar(id/max_layers,wb); end;
    end
    logText = log_text;
    
    
    if strcmp(options.dataType, '3D')  % reshape image, for selection and mask
        img = squeeze(img);
    end
    
end
if options.showWaitbar; delete(wb); end
end