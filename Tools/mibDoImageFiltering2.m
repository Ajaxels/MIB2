function [img, logText] = mibDoImageFiltering2(img, BatchOpt)
% function [img, logText] = mibDoImageFiltering2(img, BatchOpt)
% Filter the image, alternative version of mibDoImageFiltering with more
% filters and BatchOpt compatible structure
%
% Parameters:
% img: -> a matrix [1:height, 1:width, 1:color, 1:layers]
% BatchOpt: -> a structure with parameters
%
%
% Return values:
% img: filtered dataset, [1:height, 1:width, 1:color, 1:no_stacks]
% logText: log text with parameters of the applied filter

% Copyright (C) 26.10.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

logText = NaN;
if nargin < 2; errordlg(sprintf('!!! Error !!!\n\nmibApplyImageFilter: the BatchOpt structure is required!'), 'Error'); return; end
if nargin < 1; errordlg(sprintf('!!! Error !!!\n\nmibApplyImageFilter: the img is required!'), 'Error'); return; end

if BatchOpt.showWaitbar; wb = waitbar(0,['Applying ' BatchOpt.FilterName{1} ' filter...'], 'Name', 'Filtering'); end

maxVal = double(intmax(class(img(1))));
if ~strcmp(BatchOpt.TargetLayer{1}, 'image')   % reshape image, for selection and mask
    img = reshape(img, [size(img,1), size(img,2), 1, size(img,3)]);
end

if BatchOpt.Mode3D  % perform the 3D filters
    if size(img, 4) < 3
        if BatchOpt.showWaitbar; delete(wb); end
        errordlg(sprintf('!!! Error !!!\n\n3D filters require more than 2 layers!'),'Error!');
        return;
    end
    logText = [BatchOpt.FilterName{1}, ' 3D ',BatchOpt.ActionToResult{1}, '(', BatchOpt.DatasetType{1}, '), ColCh:', BatchOpt.ColorChannel{1}, ''];
    for colCh=1:size(img,3)
        switch BatchOpt.FilterName{1}
            case 'Average'
                if colCh==1; h = fspecial3('average', str2num(BatchOpt.HSize)); end %#ok<*ST2NM>
                if strcmp(BatchOpt.Padding{1}, 'custom')
                    img(:,:,colCh,:) = imfilter(img(:,:,colCh,:), h, str2double(BatchOpt.PaddingValue), BatchOpt.FilteringMode{1});
                else
                    img(:,:,colCh,:) = imfilter(img(:,:,colCh,:), h, BatchOpt.Padding{1}, BatchOpt.FilteringMode{1});
                    %img1 = imfilter(squeeze(img(:,:,colCh,:)), h, BatchOpt.Padding{1}, BatchOpt.FilteringMode{1});
                    %img(:,:,colCh,:) = permute(img1, [1 2 4 3]);
                end
                logText = [logText ', HSize:' BatchOpt.HSize ', ' BatchOpt.Padding{1} ', PaddingValue:' BatchOpt.PaddingValue];
            case 'Gaussian'
                GaussXY =  fspecial('gaussian',[BatchOpt.hSize(1) 1],BatchOpt.sigma);
                GaussZ =  fspecial('gaussian',[z_kernel 1],BatchOpt.sigma);
                Hx=reshape(GaussXY,[length(GaussXY) 1 1 1]);
                Hy=reshape(GaussXY,[1 length(GaussXY) 1 1]);
                Hz=reshape(GaussZ,[1 1 1 length(GaussZ)]);
                img(:,:,color_ch,:) = imfilter(imfilter(imfilter(img(:,:,color_ch,:),Hx,'replicate'),Hy,'replicate'),Hz,'replicate');
        end
    end
else    % perform 2D filters
    
end

return;

matlabVersion = ver('Matlab');
matlabVersion = str2double(matlabVersion(1).Version);

if BatchOpt.filters3DCheck      % 3D filters
    switch BatchOpt.fitType
        case 'Gaussian'      % 3d gaussian filter
            for color_ch=color_start:color_end
                GaussXY =  fspecial('gaussian',[BatchOpt.hSize(1) 1],BatchOpt.sigma);
                GaussZ =  fspecial('gaussian',[z_kernel 1],BatchOpt.sigma);
                Hx=reshape(GaussXY,[length(GaussXY) 1 1 1]);
                Hy=reshape(GaussXY,[1 length(GaussXY) 1 1]);
                Hz=reshape(GaussZ,[1 1 1 length(GaussZ)]);
                img(:,:,color_ch,:) = imfilter(imfilter(imfilter(img(:,:,color_ch,:),Hx,'replicate'),Hy,'replicate'),Hz,'replicate');
            end
            if strcmp(BatchOpt.dataType, '3D')   % reshape image, for selection and mask
                img = squeeze(img);
            end
            logText = ['ImFilter: 3D ' BatchOpt.fitType ', HSize:' num2str(BatchOpt.hSize) ...
                ', ZSize:' num2str(z_kernel) ', Sigma: ' num2str(BatchOpt.sigma) ',ColCh:' num2str(BatchOpt.colorChannel)];
        case 'Gradient'     % 3d gradient filter
            if size(img,4) < 3
                delete(wb);
                msgbox('Gradient 3D filter requires more than 2 slices!','Error!','error');
                return;
            end
            for color_ch=color_start:color_end
                [Ix,Iy,Iz] = gradient(double(squeeze(img(:,:,color_ch,:))));
                img2 = sqrt(Ix.^2 + Iy.^2 + Iz.^2);
                img(:,:,color_ch,:) = img2/max(max(max(img2)))*maxVal;      % convert to data type
            end
            if strcmp(BatchOpt.dataType, '3D')   % reshape image, for selection and mask
                img = squeeze(img);
            end
            logText = ['ImFilter: 3D ' BatchOpt.fitType ', ColCh:' num2str(BatchOpt.colorChannel)];
        case 'External: BMxD'
            if size(img,4) < 3
                delete(wb);
                msgbox('BM4D filter requires more than 2 slices!', 'Error!', 'error');
                return;
            end
            distribution = BatchOpt.padding(5:strfind(BatchOpt.padding, ':')-1);
            profile = BatchOpt.padding(1:2);
            for color_ch=color_start:color_end
                if maxVal == 255
                    I = bm4d(squeeze(img(:,:,color_ch,:)), distribution, BatchOpt.sigma/100*255, profile);
                    img(:,:,color_ch,:) = I;
                else
                    I = bm4d(double(squeeze(img(:,:,color_ch,:)))/maxVal, distribution, BatchOpt.sigma/100, profile);
                    img(:,:,color_ch,:) = I*maxVal;
                end
            end
            logText = ['ImFilter: BM4D, ColCh:' num2str(BatchOpt.colorChannel), ' ,', distribution, '-' profile];
        case 'Frangi' % 3D Frangi filter
            FrangiOptions.FrangiScaleRange = BatchOpt.hSize;
            FrangiOptions.FrangiScaleRatio = BatchOpt.sigma;
            FrangiOptions.FrangiAlpha = BatchOpt.lambda;
            FrangiOptions.FrangiBeta = BatchOpt.beta2;
            FrangiOptions.FrangiC  = BatchOpt.beta3;
            FrangiOptions.BlackWhite = BatchOpt.BlackWhite;
            FrangiOptions.verbose = 0;
            
            J = FrangiFilter3D(squeeze(img), FrangiOptions);
            img = cast(J*25*maxVal, 'like', img);
            
            if strcmp(BatchOpt.dataType, '4D')   % reshape image, for selection and mask
                img = permute(img, [1 2 4 3]);
            end
            
            logText = ['ImFilter: 3D ' BatchOpt.fitType ', Range:' num2str(BatchOpt.hSize) ', Ratio: ' num2str(BatchOpt.sigma) ...
                ', beta1: ' num2str(BatchOpt.lambda) ', beta2: ' num2str(BatchOpt.beta2) ...
                ', beta3:' num2str(BatchOpt.beta3) ',ColCh:' num2str(BatchOpt.colorChannel)];
        case 'Median' % 3D Median
            if numel(BatchOpt.hSize) == 1
                z_kernel =  round(BatchOpt.hSize(1)*BatchOpt.pixSize.x/BatchOpt.pixSize.z);     % kernel dimensions for z-direction
            else
                z_kernel = BatchOpt.hSize(2);
            end
            
            for color_ch=color_start:color_end
                img2 = medfilt3(squeeze(img(:,:,color_ch,:)), [BatchOpt.hSize(1), BatchOpt.hSize(1), z_kernel], BatchOpt.padding);
                
                if strcmp(BatchOpt.dataType, '4D')   % reshape image, for selection and mask
                    img(:,:,color_ch,:) = permute(img2, [1 2 4 3]);
                end
            end
            logText = ['ImFilter: 3D ' BatchOpt.fitType ', ColCh:' num2str(BatchOpt.colorChannel) ', Kernel:' num2str(BatchOpt.hSize(1)) '/' num2str(z_kernel), ', Padding:' BatchOpt.padding];
    end
else    % 2D filters
    if strcmp(BatchOpt.fitType,'Disk') || strcmp(BatchOpt.fitType,'Motion') || strcmp(BatchOpt.fitType,'Unsharp')
        BatchOpt.hSize = BatchOpt.hSize(1);
    end
    
    max_layers = size(img, 4);
    
    % generate filter and log_text
    switch BatchOpt.fitType
        case {'DNN Denoise'}    % Denoise image using deep neural network
            log_text = ['ImFilter: ' BatchOpt.fitType];
            net = denoisingNetwork('DnCNN');
        case {'Median', 'Wiener'}
            log_text = ['ImFilter: ' BatchOpt.fitType ', HSize:' num2str(BatchOpt.hSize) ...
                ',Orient:' num2str(BatchOpt.orientation) ',ColCh:' num2str(BatchOpt.colorChannel)];
        case 'Unsharp'
            if matlabVersion >= 8.1
                log_text = ['ImFilter: ' BatchOpt.fitType ', Radius:' num2str(BatchOpt.hSize) ...
                    ',Amount:' num2str(BatchOpt.sigma) ',Thres:' num2str(BatchOpt.lambda) ...
                    ',Orient:' num2str(BatchOpt.orientation) ',ColCh:' num2str(BatchOpt.colorChannel)];
            else
                filter2d = fspecial(BatchOpt.fitType, BatchOpt.hSize);
                log_text = ['ImFilter: ' BatchOpt.fitType ', HSize:' num2str(BatchOpt.hSize) ...
                    ',Orient:' num2str(BatchOpt.orientation) ',ColCh:' num2str(BatchOpt.colorChannel)];
            end
        case 'Gradient'
            log_text = ['ImFilter: ' BatchOpt.fitType ',ColCh:' num2str(BatchOpt.colorChannel)];
        case 'External: BMxD'
            log_text = ['ImFilter: ' BatchOpt.fitType ',ColCh:' num2str(BatchOpt.colorChannel),',2D,','sigma=' num2str(BatchOpt.sigma), ',profile=', BatchOpt.padding(1:8)];
        case 'Frangi'
            FrangiOptions.FrangiScaleRange = BatchOpt.hSize;
            FrangiOptions.FrangiScaleRatio = BatchOpt.sigma;
            FrangiOptions.FrangiBetaOne = BatchOpt.lambda;
            FrangiOptions.FrangiBetaTwo = BatchOpt.beta2;
            FrangiOptions.BlackWhite = BatchOpt.BlackWhite;
            FrangiOptions.verbose = 0;
            log_text = ['ImFilter: ' BatchOpt.fitType ', Range:' num2str(BatchOpt.hSize) ', Ratio: ' num2str(BatchOpt.sigma) ...
                ', beta1: ' num2str(BatchOpt.lambda) ', beta2: ' num2str(BatchOpt.beta2) ...
                ',Orient:' num2str(BatchOpt.orientation) ',ColCh:' num2str(BatchOpt.colorChannel)];
        otherwise
            if isfield(BatchOpt, 'sigma') && isfield(BatchOpt, 'hSize')
                filter2d = fspecial(BatchOpt.fitType, BatchOpt.hSize, BatchOpt.sigma);
                log_text = ['ImFilter: ' BatchOpt.fitType ', HSize:' num2str(BatchOpt.hSize) ...
                    ', Sigma: ' num2str(BatchOpt.sigma) ',Orient:' num2str(BatchOpt.orientation) ',ColCh:' num2str(BatchOpt.colorChannel)];
            elseif isfield(BatchOpt, 'sigma')
                filter2d = fspecial(BatchOpt.fitType, BatchOpt.sigma);
                log_text = ['ImFilter: ' BatchOpt.fitType, ',Sigma: ' num2str(BatchOpt.sigma) ',Orient:' num2str(BatchOpt.orientation) ',ColCh:' num2str(BatchOpt.colorChannel)];
            else
                filter2d = fspecial(BatchOpt.fitType, BatchOpt.hSize);
                log_text = ['ImFilter: ' BatchOpt.fitType ', HSize:' num2str(BatchOpt.hSize) ...
                    ',Orient:' num2str(BatchOpt.orientation) ',ColCh:' num2str(BatchOpt.colorChannel)];
            end
    end
    
    for id = 1:size(img, 4)
        % each pixel in the result is a sum of neightbour pixels multiplied
        % with coefficients provided in filter2d
        for color_ch=color_start:color_end
            switch BatchOpt.fitType
                case {'DNN Denoise'}    % Denoise image using deep neural network
                    height = size(img, 1);
                    width = size(img, 2);
                    xStep = BatchOpt.hSize(1);
                    yStep = BatchOpt.hSize(2);
                    tilesY = 1;
                    tilesX = 1;
                    if height > yStep || width > xStep
                        tilesY = ceil(height/yStep);
                        tilesX = ceil(width/xStep);
                    end
                    xStep = ceil(width/tilesX);
                    yStep = ceil(height/tilesY);
                    
                    for x=1:tilesX
                        for y=1:tilesY
                            yMin = (y-1)*yStep+1;
                            yMax = min([(y-1)*yStep+yStep, height]);
                            xMin = (x-1)*xStep+1;
                            xMax = min([(x-1)*xStep+xStep, width]);
                            
                            img(yMin:yMax, xMin:xMax, color_ch, id) = denoiseImage(img(yMin:yMax, xMin:xMax, color_ch, id), net);
                        end
                    end
                case 'Median'
                    img(:,:,color_ch,id) = medfilt2(img(:,:,color_ch,id), BatchOpt.hSize, 'symmetric');
                case 'External: BMxD'
                    if maxVal == 255
                        [~, I] = BM3D(1, img(:,:,color_ch,id), BatchOpt.sigma/100*255, BatchOpt.padding(1:2));
                        img(:,:,color_ch,id) = uint8(I*maxVal);
                    else
                        I = double(img(:,:,color_ch,id))/maxVal;
                        [~, I] = BM3D(1, I, BatchOpt.sigma/100*255, BatchOpt.padding(1:2));
                        img(:,:,color_ch,id) = I*maxVal;
                    end
                case 'Wiener'
                    img(:,:,color_ch,id) = wiener2(img(:,:,color_ch,id),BatchOpt.hSize);
                case 'Gradient'
                    [Ix,Iy] = gradient(double(img(:,:,color_ch,id)));
                    img2 = sqrt(Ix.^2 + Iy.^2);
                    img(:,:,color_ch,id) = img2/max(max(max(img2)))*maxVal;
                case 'Frangi'
                    %img(:,:,color_ch,id) = FrangiFilter2D(img(:,:,color_ch,id), FrangiOptions);
                    imgOut = FrangiFilter2D(double(img(:,:,color_ch,id)), FrangiOptions);
                    img(:,:,color_ch,id) = imgOut*maxVal;
                case 'Unsharp'
                    if matlabVersion >= 8.1
                        img(:,:,color_ch,id) = imsharpen(img(:,:,color_ch,id),'Radius',BatchOpt.hSize,'Amount',BatchOpt.sigma, 'Threshold', BatchOpt.lambda);
                    else
                        img(:,:,color_ch,id) = imfilter(img(:,:,color_ch,id), filter2d, 'replicate');
                    end
                case 'Log'
                    %tempImg = imfilter(double(img(:,:,color_ch,id)), filter2d, 'replicate');
                    %minVal = min(min(tempImg));
                    %maxVal = max(max(tempImg));
                    %img(:,:,color_ch,id) = (tempImg-minVal)/(maxVal-minVal)*maxVal;
                    img(:,:,color_ch,id) = imfilter(img(:,:,color_ch,id), filter2d, 'replicate');
                otherwise
                    img(:,:,color_ch,id) = imfilter(img(:,:,color_ch,id), filter2d, 'replicate');
            end
        end
        if BatchOpt.showWaitbar && mod(id, 10)==0; waitbar(id/max_layers,wb); end
    end
    logText = log_text;
    
    if strcmp(BatchOpt.dataType, '3D')  % reshape image, for selection and mask
        img = squeeze(img);
    end
end
if BatchOpt.showWaitbar; delete(wb); end
end