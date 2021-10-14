function [img, logText] = mibDoImageFiltering2(img, BatchOpt, cpuParallelLimit)
% function [img, logText] = mibDoImageFiltering2(img, BatchOpt)
% Filter the image, alternative version of mibDoImageFiltering with more
% filters and BatchOpt compatible structure
%
% Parameters:
% img: -> a matrix [1:height, 1:width, 1:color, 1:layers]
% BatchOpt: -> a structure with parameters
% cpuParallelLimit -> max CPU number available for parallel processing
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

logText = [];
if nargin < 3; cpuParallelLimit = 0; end
if nargin < 2; errordlg(sprintf('!!! Error !!!\n\nmibApplyImageFilter: the BatchOpt structure is required!'), 'Error'); return; end
if nargin < 1; errordlg(sprintf('!!! Error !!!\n\nmibApplyImageFilter: the img is required!'), 'Error'); return; end

if ~isfield(BatchOpt, 'ActionToResult'); BatchOpt.ActionToResult = {'Fitler image'}; end
if ~isfield(BatchOpt, 'UseParallelComputing'); BatchOpt.UseParallelComputing = false; end

maxVal = double(intmax(class(img(1))));
if ~strcmp(BatchOpt.SourceLayer{1}, 'image')   % reshape image, for selection and mask
    img = reshape(img, [size(img,1), size(img,2), 1, size(img,3)]);
end

if size(img, 4) == 1; BatchOpt.showWaitbar = 0; BatchOpt.UseParallelComputing = false; end     % turn off the waitbar and parallel computing for single images
showWaitbar = BatchOpt.showWaitbar;

if BatchOpt.Mode3D  % perform the 3D filters
    if size(img, 4) < 3
        errordlg(sprintf('!!! Error !!!\n\n3D filters require more than 2 layers!'),'Error!');
        return;
    end
    
    % create waitbar
    if showWaitbar
        pwb = PoolWaitbar(size(img,3), ['Applying ' BatchOpt.FilterName{1} ' filter...'], [], 'Filtering'); 
    else
        pwb = [];   % have to init it for parfor loops
    end
    
    if nargout == 2; logText = sprintf('%s 3D, %s (%s), ColCh: %s', BatchOpt.FilterName{1}, BatchOpt.ActionToResult{1}, BatchOpt.DatasetType{1}, BatchOpt.ColorChannel{1}); end
    
    for colCh=1:size(img,3)
        switch BatchOpt.FilterName{1}
            case 'Average'
                if colCh==1
                    h = fspecial3('average', str2num(BatchOpt.HSize));
                    logText = sprintf('%s, HSize: %s', logText, BatchOpt.HSize);
                    
                    if strcmp(BatchOpt.Padding{1}, 'custom')
                        Padding = BatchOpt.PaddingValue{1};
                    else
                        Padding = BatchOpt.Padding{1};
                    end
                    logText = sprintf('%s, %s, PadValue:%d, ', logText, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
                end
                img(:,:,colCh,:) = permute(imfilter(squeeze(img(:,:,colCh,:)), h, Padding, BatchOpt.FilteringMode{1}), [1 2 4 3]);
            case {'Prewitt', 'Sobel'}
                if colCh==1
                    h = fspecial3(lower(BatchOpt.FilterName{1}), BatchOpt.Direction{1});
                    logText = sprintf('%s, Direction:%s; Part:%s, NormF:%.3f', logText, BatchOpt.Direction{1},BatchOpt.ReturnPart{1}, BatchOpt.NormalizationFactor{1});
                    if strcmp(BatchOpt.Padding{1}, 'custom')
                        Padding = BatchOpt.PaddingValue{1};
                    else
                        Padding = BatchOpt.Padding{1};
                    end
                    logText = sprintf('%s, %s, PadValue:%d, ', logText, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
                end
                switch BatchOpt.ReturnPart{1}
                    case 'both'
                        img(:,:,colCh,:) = permute(abs(imfilter(double(squeeze(img(:,:,colCh,:))), h, Padding, BatchOpt.FilteringMode{1}))*BatchOpt.NormalizationFactor{1}, [1 2 4 3]);
                    case 'negative'
                        img(:,:,colCh,:) = permute(imfilter(imcomplement(squeeze(img(:,:,colCh,:))), h, Padding, BatchOpt.FilteringMode{1})*BatchOpt.NormalizationFactor{1}, [1 2 4 3]);
                    case 'positive'
                        img(:,:,colCh,:) = permute(imfilter(squeeze(img(:,:,colCh,:)), h, Padding, BatchOpt.FilteringMode{1})*BatchOpt.NormalizationFactor{1}, [1 2 4 3]);
                end
            case 'Frangi'
                if colCh==1
                    logText = sprintf('%s, Thickness:%s, Sens:%.3f, Polarity:%s, NormF:%.3f', logText, BatchOpt.ThicknessRange, BatchOpt.StructureSensitivity{1}, BatchOpt.ObjectPolarity{1}, BatchOpt.NormalizationFactor{1});
                    ThicknessRange = str2num(BatchOpt.ThicknessRange); %#ok<*ST2NM>
                end
                img(:,:,colCh,:) = permute(fibermetric(squeeze(img(:,:,colCh,:)), ThicknessRange, ...
                    'StructureSensitivity', BatchOpt.StructureSensitivity{1}, 'ObjectPolarity', ...
                    BatchOpt.ObjectPolarity{1})*BatchOpt.NormalizationFactor{1}, [1 2 4 3]);
            case 'Gradient'
                if colCh==1
                    logText = sprintf('%s, SpacingXYZ: %s, NormF:%.3f', logText, BatchOpt.SpacingXYZ, BatchOpt.NormalizationFactor{1});
                    SpacingXYZ = str2num(BatchOpt.SpacingXYZ);
                    if numel(SpacingXYZ) < 3; SpacingXYZ = [SpacingXYZ(1), SpacingXYZ(1), SpacingXYZ(1)]; end
                end
                [Ix, Iy, Iz] = gradient(double(squeeze(img(:,:,colCh,:))), SpacingXYZ(1), SpacingXYZ(2), SpacingXYZ(3));
                img(:,:,colCh,:) = permute(sqrt(Ix.^2 + Iy.^2 + Iz.^2)*BatchOpt.NormalizationFactor{1}, [1 2 4 3]);      % convert to data type
            case 'LoG'
                if colCh==1
                    h = fspecial3('log', str2num(BatchOpt.HSize), str2double(BatchOpt.Sigma));
                    logText = sprintf('%s, HSize:%s, Sigma:%s, NormFac:%.3f', logText, BatchOpt.HSize, BatchOpt.Sigma, BatchOpt.NormalizationFactor{1});
                    logText = sprintf('%s, %s, PadValue:%d, ', logText, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
                    halfClassIntensity = double(round(intmax(class(img(1)))/2));     % intensity for shifting the resuting image
                    if strcmp(BatchOpt.Padding{1}, 'custom')
                        Padding = BatchOpt.PaddingValue{1};
                    else
                        Padding = BatchOpt.Padding{1};
                    end
                end
                img_dummy = imfilter(double(squeeze(img(:,:,colCh,:))), h, Padding, BatchOpt.FilteringMode{1});
                img(:,:,colCh,:) = permute(img_dummy, [1 2 4 3])*BatchOpt.NormalizationFactor{1} + halfClassIntensity;
            case 'Median'
                if colCh==1
                    NeighborhoodSize = str2num(BatchOpt.NeighborhoodSize);
                    if isempty('NeighborhoodSize'); errordlg('NeighborhoodSize should contain one or two numbers!'); return; end
                    if numel(NeighborhoodSize)==1; NeighborhoodSize = [NeighborhoodSize, NeighborhoodSize, NeighborhoodSize]; end %#ok<AGROW>
                    logText = sprintf('%s, NSize: %s, Padding:%s', logText, BatchOpt.NeighborhoodSize, BatchOpt.Padding{1});
                end
                img(:,:,colCh,:) = permute(medfilt3(squeeze(img(:,:,colCh,:)), NeighborhoodSize, BatchOpt.Padding{1}),[1 2 4 3]);
            case 'Mode'
                if colCh==1
                    FiltSize = str2num(BatchOpt.FiltSize);
                    Padding = BatchOpt.Padding{1};
                
                    logText = sprintf('%s, FiltSize: %s, Padding: %s', logText, ...
                        BatchOpt.FiltSize, BatchOpt.Padding{1});
                end
                img(:,:,colCh,:) = permute(modefilt(squeeze(img(:,:,colCh,:)), FiltSize, Padding), [1 2 4 3]);
            case 'Gaussian'
                if colCh==1
                    HSize = str2num(BatchOpt.HSize);
                    HSize = HSize - mod(HSize,2) + 1; % should be an odd number
                    if strcmp(BatchOpt.Padding{1}, 'custom')
                        Padding = BatchOpt.PaddingValue{1};
                    else
                        Padding = BatchOpt.Padding{1};
                    end
                    logText = sprintf('%s, HSize:%s, Sigma:%.3f, NormFac:%s', logText, BatchOpt.HSize, BatchOpt.Sigma{1});
                    logText = sprintf('%s, %s, PadValue:%d, ', logText, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
                end
                img(:,:,colCh,:) = permute(...
                    imgaussfilt3(squeeze(img(:,:,colCh,:)), BatchOpt.Sigma{1}, 'FilterSize', HSize, 'Padding', Padding, 'FilterDomain', BatchOpt.FilterDomain{1}),...
                    [1 2 4 3]);
            case 'SlicClustering'
                img = squeeze(img);
                dims = size(img);
                noPix = ceil(dims(1)*dims(2)*dims(3)/BatchOpt.ClusterSize{1});
                loopId = 1;
                if BatchOpt.ChopX{1} > 1 || BatchOpt.ChopY{1} > 1
                    model = zeros([dims(1), dims(2), dims(3)]);
                    noPixCount = 0;
                    xStep = ceil(dims(2)/BatchOpt.ChopX{1});
                    yStep = ceil(dims(1)/BatchOpt.ChopY{1});
                    for x=1:BatchOpt.ChopX{1}
                        for y=1:BatchOpt.ChopY{1}
                            yMin = (y-1)*yStep+1;
                            yMax = min([(y-1)*yStep+yStep, dims(1)]);
                            xMin = (x-1)*xStep+1;
                            xMax = min([(x-1)*xStep+xStep, dims(2)]);
                            
                            [slicChop, noPixChop] = slicsupervoxelmex_byte(img(yMin:yMax, xMin:xMax, :), round(noPix/(BatchOpt.ChopX{1}*BatchOpt.ChopY{1})), BatchOpt.Compactness{1});
                            model(yMin:yMax, xMin:xMax, :) = slicChop + noPix + 1;   % +1 to remove zero supervoxels
                            noPixCount = noPixChop + noPixCount;
                            
                            if showWaitbar; waitbar(loopId/(BatchOpt.ChopX{1}*BatchOpt.ChopY{1}), wb); end
                            loopId = loopId + 1;
                        end
                    end
                    noPix = noPixCount;
                    img = model;
                    clear model;
                else
                    [img, noPix] = slicsupervoxelmex_byte(img, noPix, BatchOpt.Compactness{1});
                end
                
                if max(noPix) < 65535
                    img = uint16(img)+1; % remove superpixel with 0-index
                else
                    img = uint32(img)+1; % remove superpixel with 0-index
                end
            case 'WatershedClustering'
                img = squeeze(img);
                if strcmp(BatchOpt.TypeOfSignal{1}, 'black-on-white')
                    img = imcomplement(img);    % convert image that the ridges are white
                end
                
                if BatchOpt.ClusterSize{1} > 0
                    mask = imextendedmin(img, BatchOpt.ClusterSize{1});
                    mask = imimposemin(img, mask);
                    img = watershed(mask);
                else
                    img = watershed(img);
                end
                
                if strcmp(BatchOpt.GapPolicy{1}, 'remove gaps') % remove gaps
                    img = imdilate(img, ones([3 3 3]));
                end
                
                if strcmp(BatchOpt.ResultingShape{1}, 'clusters')
                    if ~strcmp(BatchOpt.DestinationLayer{1}, 'model')
                        img = uint8(img);
                        img(img>1) = 1;
                    end
                else
                    ridges = find(img==0);
                    img = zeros(size(img), 'uint8');
                    img(ridges) = 1; %#ok<FNDSB>
                end
            case 'ElasticDistortion'
                if colCh==1
                    logText = sprintf('%s 3D, ScalingFactor: %d, HSize: %s, Sigma: %.1f', logText, BatchOpt.ScalingFactor{1}, BatchOpt.HSize, BatchOpt.Sigma{1});
                    randomSeed = 0;     % define random seed
                    [img(:,:,colCh,:), DisplacementField] = mibElasticDistortionFilter(img(:,:,colCh,:), BatchOpt, randomSeed);
                else
                    img(:,:,colCh,:) = mibElasticDistortionFilter(img(:,:,:,z), BatchOpt, randomSeed, DisplacementField);
                end
                
        end
        if showWaitbar; pwb.increment(); end
    end
else    % perform 2D filters
    if nargout == 2; logText = sprintf('%s 2D, %s (%s), ColCh: %s', BatchOpt.FilterName{1}, BatchOpt.ActionToResult{1}, BatchOpt.DatasetType{1}, BatchOpt.ColorChannel{1}); end
    maxCount = size(img, 3)*size(img, 4);
    
    % create waitbar
    if showWaitbar
        pwb = PoolWaitbar(maxCount, ['Applying ' BatchOpt.FilterName{1} ' filter...'], [], 'Filtering'); 
    else
        pwb = [];   % have to init it for parfor loops
    end
        
    %%
    
    % define usage of parallel computing
    if BatchOpt.UseParallelComputing
        parforArg = cpuParallelLimit;
    else
        parforArg = 0;
    end
    
    switch BatchOpt.FilterName{1}
        case 'AddNoise'
            logText = sprintf('%s, Mean: %s, Iter: %d, Var: %s, Density: %.3f', logText, ...
                BatchOpt.Mode{1}, BatchOpt.Mean, BatchOpt.Variance, BatchOpt.Density{1});
            Mean = str2double(BatchOpt.Mean);
            Variance = str2double(BatchOpt.Variance);
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    switch BatchOpt.Mode{1}
                        case 'gaussian'
                            img(:,:,colCh,z) = imnoise(img(:,:,colCh,z), BatchOpt.Mode{1}, Mean, Variance);
                        case 'speckle'
                            img(:,:,colCh,z) = imnoise(img(:,:,colCh,z), BatchOpt.Mode{1}, Variance);
                        case 'poisson'
                            img(:,:,colCh,z) = imnoise(img(:,:,colCh,z), BatchOpt.Mode{1});
                        case 'salt & pepper'
                            img(:,:,colCh,z) = imnoise(img(:,:,colCh,z), BatchOpt.Mode{1}, BatchOpt.Density{1});
                    end
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'AnisotropicDiffusion'
            logText = sprintf('%s, Grad: %d, Iter: %d, Conn: %s, Conduction: %s', logText, ...
                BatchOpt.GradientThreshold{1}, BatchOpt.NumberOfIterations{1}, BatchOpt.Connectivity{1}, BatchOpt.ConductionMethod{1});
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = imdiffusefilt(img(:,:,colCh,z), 'GradientThreshold', BatchOpt.GradientThreshold{1}, ...
                        'NumberOfIterations', BatchOpt.NumberOfIterations{1}, 'Connectivity', BatchOpt.Connectivity{1},...
                        'ConductionMethod', BatchOpt.ConductionMethod{1});
                    if showWaitbar; pwb.increment(); end
                end
            end
        case {'Average', 'Disk', 'Motion'}
            switch BatchOpt.FilterName{1}
                case 'Average'
                    h = fspecial(lower(BatchOpt.FilterName{1}), str2num(BatchOpt.HSize));
                    logText = sprintf('%s, HSize: %s', logText, BatchOpt.HSize);
                case 'Disk'
                    h = fspecial(lower(BatchOpt.FilterName{1}), BatchOpt.Radius{1});
                    logText = sprintf('%s, Radius: %d', logText, BatchOpt.Radius{1});
                case 'Motion'
                    h = fspecial('motion', BatchOpt.Length{1}, BatchOpt.Angle{1});
                    logText = sprintf('%s, Length:%d, Angle:%d', logText, BatchOpt.Length{1}, BatchOpt.Angle{1});
                    
            end
            logText = sprintf('%s, %s, PadValue:%d, ', logText, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
            if strcmp(BatchOpt.Padding{1}, 'custom')
                Padding = BatchOpt.PaddingValue{1};
            else
                Padding = BatchOpt.Padding{1};
            end
            
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = imfilter(img(:,:,colCh,z), h, Padding, BatchOpt.FilteringMode{1});
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'Bilateral'
            degreeOfSmoothing = str2double(BatchOpt.degreeOfSmoothing);
            NeighborhoodSize = str2double(BatchOpt.NeighborhoodSize);
            if ismember(BatchOpt.Padding{1}, {'replicate', 'symmetric'})
                Padding = BatchOpt.Padding{1};
            else
                Padding = BatchOpt.PaddingValue{1};
            end
            logText = sprintf('%s, Smooth: %s, Sigma: %.3f, Nhood: %s, Padding: %s(%d)', logText, ...
                BatchOpt.degreeOfSmoothing, BatchOpt.spatialSigma{1}, BatchOpt.NeighborhoodSize, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = imbilatfilt(img(:,:,colCh,z), degreeOfSmoothing, BatchOpt.spatialSigma{1}, ...
                        'NeighborhoodSize', NeighborhoodSize, 'Padding', Padding);
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'BMxD'
            logText = sprintf('%s, Sigma:%.3f, Profile:%s', logText, BatchOpt.Sigma{1}, BatchOpt.Profile{1});
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    if maxVal == 255
                        [~, I] = BM3D(1, img(:,:,colCh,z), BatchOpt.Sigma{1}/100*255, BatchOpt.Profile{1});
                        img(:,:,colCh,z) = uint8(I*maxVal);
                    else
                        I = double(img(:,:,colCh,z))/maxVal;
                        [~, I] = BM3D(1, I, BatchOpt.Sigma{1}/100*255, BatchOpt.Profile{1});
                        img(:,:,colCh,z) = I*maxVal;
                    end
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'DNNdenoise'
            net = denoisingNetwork(BatchOpt.NetworkName{1});
            logText = sprintf('%s, Net: %s', logText, BatchOpt.NetworkName{1});
            height = size(img, 1);
            width = size(img, 2);
            xStep = BatchOpt.GPUblock{1};
            yStep = BatchOpt.GPUblock{1};
            tilesY = 1;
            tilesX = 1;
            if height > yStep || width > xStep
                tilesY = ceil(height/yStep);
                tilesX = ceil(width/xStep);
            end
            xStep = ceil(width/tilesX);
            yStep = ceil(height/tilesY);
            
            for colCh=1:size(img, 3)
                for z = 1:size(img, 4)
                    for x=1:tilesX
                        for y=1:tilesY
                            yMin = (y-1)*yStep+1;
                            yMax = min([(y-1)*yStep+yStep, height]);
                            xMin = (x-1)*xStep+1;
                            xMax = min([(x-1)*xStep+xStep, width]);
                            
                            img(yMin:yMax, xMin:xMax, colCh, z) = denoiseImage(img(yMin:yMax, xMin:xMax, colCh, z), net);
                        end
                    end
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'Edge'
            Threshold = str2num(BatchOpt.Threshold);
            Sigma = str2num(BatchOpt.Sigma);
            switch BatchOpt.Method{1}
                case {'Sobel', 'Prewitt', 'Roberts'}
                    if numel(Threshold) > 1; Threshold = Threshold(1); end
                case {'LaplacianOfGaussian', 'Canny','approxcanny','zerocross'}
                    
            end
            parfor (z = 1:size(img, 4), parforArg)  % binarization filter, only one color channel
                switch BatchOpt.Method{1}
                    case {'Sobel', 'Prewitt', 'Roberts'}
                        img(:,:,1,z) = edge(img(:,:,1,z), BatchOpt.Method{1}, Threshold, BatchOpt.Direction{1});
                    case 'Canny'
                        img(:,:,1,z) = edge(img(:,:,1,z), BatchOpt.Method{1}, Threshold, Sigma);
                    case 'LaplacianOfGaussian'
                        img(:,:,1,z) = edge(img(:,:,1,z), 'log', Threshold, Sigma);
                    case 'approxcanny'
                        img(:,:,1,z) = edge(img(:,:,1,z), BatchOpt.Method{1}, Threshold);
                end
                if showWaitbar; pwb.increment(); end
            end
            img = squeeze(img);     % make it 3D from 4D
        case {'Entropy', 'Range', 'Std'}
            NeighborhoodSize = str2num(BatchOpt.NeighborhoodSize);
            if isempty('NeighborhoodSize'); errordlg('NeighborhoodSize should contain one or two numbers!'); return; end
            if numel(NeighborhoodSize)==1; NeighborhoodSize = [NeighborhoodSize, NeighborhoodSize]; end %#ok<AGROW>
            switch BatchOpt.StrelShape{1}
                case 'rectangle'
                    SE = strel('rectangle',[NeighborhoodSize(1) NeighborhoodSize(2)]);
                case 'disk'
                    SE = strel('disk', NeighborhoodSize(1), 0);
            end
            logText = sprintf('%s, NSize: %s (%s); NormF:%.3f', logText, BatchOpt.NeighborhoodSize, BatchOpt.StrelShape{1}, BatchOpt.NormalizationFactor{1});
            if strcmp(BatchOpt.FilterName{1}, 'Std')
                filterWith = 1;     % Std
            elseif strcmp(BatchOpt.FilterName{1}, 'Range')
                filterWith = 2;     % Range
            else
                filterWith = 3;     % Entropy
            end
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    if filterWith == 1
                        img(:,:,colCh,z) = stdfilt(img(:,:,colCh,z), SE.Neighborhood)*BatchOpt.NormalizationFactor{1};
                    elseif filterWith == 2
                        img(:,:,colCh,z) = rangefilt(img(:,:,colCh,z), SE.Neighborhood)*BatchOpt.NormalizationFactor{1};
                    else
                        img(:,:,colCh,z) = entropyfilt(img(:,:,colCh,z), SE.Neighborhood)*BatchOpt.NormalizationFactor{1};
                    end
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'FastLocalLaplacian'
            logText = sprintf('%s, EdgeAmp:%.3f, Smooth:%.3f, DynamicRange:%.2f, ColorMode:%s, NumIntLvls:%s, useRGB:%d', ...
                logText, BatchOpt.EdgeAmplitude{1}, BatchOpt.Smoothing{1}, BatchOpt.DynamicRange{1},...
                BatchOpt.ColorMode{1}, BatchOpt.NumIntensityLevels, BatchOpt.useRGB);
            NumIntensityLevels = str2double(BatchOpt.NumIntensityLevels);
            if isnan(NumIntensityLevels); NumIntensityLevels = 'auto'; end
            
            if BatchOpt.useRGB
                if size(img, 3) ~= 3
                    if showWaitbar; delete(pwb); end
                    errordlg(sprintf('!!! Error !!!\n\nThe image should have 3 color channels!\nThis image has %d color channels', size(img, 3))); 
                    return; 
                end
                if showWaitbar; pwb.setIncrement(3); end   % set increment for RGB images
                
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,:,z) = locallapfilt(img(:,:,:,z), BatchOpt.EdgeAmplitude{1}, BatchOpt.Smoothing{1}, BatchOpt.DynamicRange{1},...
                        'ColorMode', BatchOpt.ColorMode{1}, 'NumIntensityLevels', NumIntensityLevels);
                    if showWaitbar; pwb.increment(); end
                end
            else    % grayscale image
                for colCh=1:size(img, 3)
                    parfor (z = 1:size(img, 4), parforArg)
                        img(:,:,colCh,z) = locallapfilt(img(:,:,colCh,z), BatchOpt.EdgeAmplitude{1}, BatchOpt.Smoothing{1}, BatchOpt.DynamicRange{1},...
                            'ColorMode', BatchOpt.ColorMode{1}, 'NumIntensityLevels', NumIntensityLevels);
                        if showWaitbar; pwb.increment(); end
                    end
                end
            end
        case 'FlatfieldCorrection'
            logText = sprintf('%s, Sigma:%s, HalfSize:%s, useRGB:%d', logText, BatchOpt.Sigma, BatchOpt.FilterHalfSize, BatchOpt.useRGB);
            Sigma = str2num(BatchOpt.Sigma);
            filterSize = str2num(BatchOpt.FilterHalfSize);
            if isempty(filterSize)
                filterSize = 2*ceil(Sigma*2)+1;
            else
                filterSize = filterSize.* 2 + 1;
            end
            
            if BatchOpt.useRGB
                if size(img, 3) ~= 3
                    if showWaitbar; delete(pwb); end
                    errordlg(sprintf('!!! Error !!!\n\nThe image should have 3 color channels!\nThis image has %d color channels', size(img, 3))); 
                    return; 
                end
                if showWaitbar; pwb.setIncrement(3); end   % set increment for RGB images
                
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,:,z) = imflatfield(img(:,:,:,z), Sigma, 'filterSize', filterSize);
                    if showWaitbar; pwb.increment(); end
                end
            else    % grayscale image
                for colCh=1:size(img, 3)
                    parfor (z = 1:size(img, 4), parforArg)
                        img(:,:,colCh,z) = imflatfield(img(:,:,colCh,z), Sigma, 'filterSize', filterSize);
                        if showWaitbar; pwb.increment(); end
                    end
                end
            end
        case 'Frangi'
            logText = sprintf('%s, Thickness:%s, Sens:%.3f, Polarity:%s, NormF:%.3f', logText, BatchOpt.ThicknessRange, BatchOpt.StructureSensitivity{1}, BatchOpt.ObjectPolarity{1}, BatchOpt.NormalizationFactor{1});
            ThicknessRange = str2num(BatchOpt.ThicknessRange); %#ok<*ST2NM>
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = fibermetric(img(:,:,colCh,z), ThicknessRange, ...
                        'StructureSensitivity', BatchOpt.StructureSensitivity{1}, 'ObjectPolarity', BatchOpt.ObjectPolarity{1})*BatchOpt.NormalizationFactor{1};
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'ElasticDistortion'
            % not implemented, this version is very slow
            logText = sprintf('%s, ScalingFactor: %d, HSize: %s, Sigma: %.1f', logText, BatchOpt.ScalingFactor{1}, BatchOpt.HSize, BatchOpt.Sigma{1});
            %for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    randomSeed = z;     % define random
                    img(:,:,:,z) = mibElasticDistortionFilter(img(:,:,:,z), BatchOpt, randomSeed);
                    if showWaitbar; pwb.increment(); end
                end
            %end
        case 'Gaussian'
            HSize = str2num(BatchOpt.HSize);
            HSize = HSize - mod(HSize,2) + 1; % should be an odd number
            if numel(HSize) > 2; HSize = HSize(1:2); end
            
            if ismember(BatchOpt.Padding{1}, {'replicate', 'symmetric', 'circular'})
                Padding = BatchOpt.Padding{1};
            else
                Padding = BatchOpt.PaddingValue{1};
            end
            logText = sprintf('%s, HSize: %s, Sigma: %.3f, %s, PadValue:%d', logText, BatchOpt.HSize, BatchOpt.Sigma{1}, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = imgaussfilt(img(:,:,colCh,z), BatchOpt.Sigma{1}, 'FilterSize', HSize, ...
                        'Padding', Padding, 'FilterDomain', BatchOpt.FilterDomain{1});
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'Gradient'
            logText = sprintf('%s, SpacingXYZ: %s, NormF:%.3f', logText, BatchOpt.SpacingXYZ, BatchOpt.NormalizationFactor{1});
            SpacingXYZ = str2num(BatchOpt.SpacingXYZ);
            if numel(SpacingXYZ) == 1; SpacingXYZ = [SpacingXYZ, SpacingXYZ]; end
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    [Ix, Iy] = gradient(double(img(:,:,colCh,z)), SpacingXYZ(1), SpacingXYZ(2));
                    img(:,:,colCh,z) = sqrt(Ix.^2 + Iy.^2)*BatchOpt.NormalizationFactor{1};
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'LocalBrighten'
            logText = sprintf('%s, Amount:%.3f, AlphaBlend:%d, useRGB:%d', logText, BatchOpt.Amount{1}, BatchOpt.AlphaBlend, BatchOpt.useRGB);
            
            if BatchOpt.useRGB
                if size(img, 3) ~= 3
                    if showWaitbar; delete(pwb); end
                    errordlg(sprintf('!!! Error !!!\n\nThe image should have 3 color channels!\nThis image has %d color channels', size(img, 3))); 
                    return; 
                end
                if showWaitbar; pwb.setIncrement(3); end   % set increment for RGB images
                
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,:,z) = imlocalbrighten(img(:,:,:,z), BatchOpt.Amount{1}, 'AlphaBlend', BatchOpt.AlphaBlend);
                    if showWaitbar; pwb.increment(); end
                end
            else    % grayscale image
                for colCh=1:size(img, 3)
                    parfor (z = 1:size(img, 4), parforArg)
                        img(:,:,colCh,z) = imlocalbrighten(img(:,:,colCh,z), BatchOpt.Amount{1}, 'AlphaBlend', BatchOpt.AlphaBlend);
                        if showWaitbar; pwb.increment(); end
                    end
                end
            end
        case 'LocalContrast'
            logText = sprintf('%s, EdgeThreshold:%.2f, Amount:%.2f, useRGB:%d', logText, BatchOpt.EdgeThreshold{1}, BatchOpt.Amount{1}, BatchOpt.useRGB);
            
            if BatchOpt.useRGB
                if size(img, 3) ~= 3
                    if showWaitbar; delete(pwb); end
                    errordlg(sprintf('!!! Error !!!\n\nThe image should have 3 color channels!\nThis image has %d color channels', size(img, 3))); 
                    return; 
                end
                if showWaitbar; pwb.setIncrement(3); end   % set increment for RGB images
                
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,:,z) = localcontrast(img(:,:,:,z), BatchOpt.EdgeThreshold{1}, BatchOpt.Amount{1});
                    if showWaitbar; pwb.increment(); end
                end
            else    % grayscale image
                for colCh=1:size(img, 3)
                    parfor (z = 1:size(img, 4), parforArg)
                        img(:,:,colCh,z) = localcontrast(img(:,:,colCh,z), BatchOpt.EdgeThreshold{1}, BatchOpt.Amount{1});
                        if showWaitbar; pwb.increment(); end
                    end
                end
            end
        case 'LoG'
            h = fspecial(lower(BatchOpt.FilterName{1}), str2num(BatchOpt.HSize), BatchOpt.Sigma{1});
            logText = sprintf('%s, HSize:%s, Sigma:%f; NormFac:%.3f', logText, BatchOpt.HSize, BatchOpt.Sigma{1}, BatchOpt.NormalizationFactor{1});
            logText = sprintf('%s, %s, PadValue:%d, ', logText, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
            halfClassIntensity = double(round(intmax(class(img(1)))/2));     % intensity for shifting the resuting image
            if strcmp(BatchOpt.Padding{1}, 'custom')
                Padding = BatchOpt.PaddingValue{1};
            else
                Padding = BatchOpt.Padding{1};
            end
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img_dummy = imfilter(double(img(:,:,colCh,z)), h, Padding, BatchOpt.FilteringMode{1});
                    img(:,:,colCh,z) = img_dummy*BatchOpt.NormalizationFactor{1} + halfClassIntensity;
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'Median'
            NeighborhoodSize = str2num(BatchOpt.NeighborhoodSize);
            if isempty('NeighborhoodSize'); errordlg('NeighborhoodSize should contain one or two numbers!'); return; end
            if numel(NeighborhoodSize)==1; NeighborhoodSize = [NeighborhoodSize, NeighborhoodSize]; end %#ok<AGROW>
            logText = sprintf('%s, NSize: %s, Padding:%s', logText, BatchOpt.NeighborhoodSize, BatchOpt.Padding{1});
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = medfilt2(img(:,:,colCh,z), NeighborhoodSize, BatchOpt.Padding{1});
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'Mode'
            FiltSize = str2num(BatchOpt.FiltSize);
            FiltSize = FiltSize(1:2);
            Padding = BatchOpt.Padding{1};
            
            logText = sprintf('%s, FiltSize: %s, Padding: %s', logText, ...
                BatchOpt.FiltSize, BatchOpt.Padding{1});
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = modefilt(img(:,:,colCh,z), FiltSize, Padding);
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'NonLocalMeans'
            DegreeOfSmoothing = str2double(BatchOpt.DegreeOfSmoothing);
            SearchWindowSize = str2double(BatchOpt.SearchWindowSize);
            ComparisonWindowSize = str2double(BatchOpt.ComparisonWindowSize);
            logText = sprintf('%s, SmoothDeg:%s, SWin:%s; CompWin:%s', logText, BatchOpt.DegreeOfSmoothing, BatchOpt.SearchWindowSize, BatchOpt.ComparisonWindowSize);
            SearchWindowSize = SearchWindowSize - mod(SearchWindowSize,2) + 1;
            ComparisonWindowSize = ComparisonWindowSize - mod(ComparisonWindowSize,2) + 1;
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    if ~isnan(DegreeOfSmoothing)
                        img(:,:,colCh,z) = imnlmfilt(img(:,:,colCh,z), 'DegreeOfSmoothing', DegreeOfSmoothing, ...
                            'SearchWindowSize', SearchWindowSize, 'ComparisonWindowSize', ComparisonWindowSize);
                    else
                        img(:,:,colCh,z) = imnlmfilt(img(:,:,colCh,z), ...
                            'SearchWindowSize', SearchWindowSize, 'ComparisonWindowSize', ComparisonWindowSize);
                    end
                    if showWaitbar; pwb.increment(); end
                end
            end
        case {'Prewitt', 'Sobel'}
            h = fspecial(lower(BatchOpt.FilterName{1}));
            if strcmp(BatchOpt.Direction{1}, 'Y'); h = h'; end
            logText = sprintf('%s, Direction:%s; Part:%s, NormF:%.3f', logText, BatchOpt.Direction{1},BatchOpt.ReturnPart{1}, BatchOpt.NormalizationFactor{1});
            logText = sprintf('%s, %s, PadValue:%d, ', logText, BatchOpt.Padding{1}, BatchOpt.PaddingValue{1});
            if strcmp(BatchOpt.Padding{1}, 'custom')
                Padding = BatchOpt.PaddingValue{1};
            else
                Padding = BatchOpt.Padding{1};
            end
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    switch BatchOpt.ReturnPart{1}
                        case 'both'
                            img(:,:,colCh,z) = abs(imfilter(double(img(:,:,colCh,z)), h, Padding, BatchOpt.FilteringMode{1}))*BatchOpt.NormalizationFactor{1};
                        case 'negative'
                            img(:,:,colCh,z) = imfilter(imcomplement(img(:,:,colCh,z)), h, Padding, BatchOpt.FilteringMode{1})*BatchOpt.NormalizationFactor{1};
                        case 'positive'
                            img(:,:,colCh,z) = imfilter(img(:,:,colCh,z), h, Padding, BatchOpt.FilteringMode{1})*BatchOpt.NormalizationFactor{1};
                    end
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'ReduceHaze'
            logText = sprintf('%s, Amount:%.3f, Method:%s, AtmLight:%s, ContEnh:%s, useRGB:%d', ....
                logText, BatchOpt.Amount{1}, BatchOpt.Method{1}, BatchOpt.AtmosphericLight, ...
                BatchOpt.ContrastEnhancement{1}, BatchOpt.useRGB);
            AtmosphericLight = str2num(BatchOpt.AtmosphericLight);
            if BatchOpt.useRGB
                if size(img, 3) ~= 3
                    if showWaitbar; delete(pwb); end
                    errordlg(sprintf('!!! Error !!!\n\nThe image should have 3 color channels!\nThis image has %d color channels', size(img, 3))); 
                    return; 
                end
                if showWaitbar; pwb.setIncrement(3); end   % set increment for RGB images
                
                if numel(AtmosphericLight) == 1; AtmosphericLight = [AtmosphericLight(1), AtmosphericLight(1), AtmosphericLight(1)]; end
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,:,z) = imreducehaze(img(:,:,:,z), ...
                        BatchOpt.Amount{1}, 'method', BatchOpt.Method{1}, 'AtmosphericLight', AtmosphericLight, 'ContrastEnhancement', BatchOpt.ContrastEnhancement{1});
                    if showWaitbar; pwb.increment(); end
                end
            else    % grayscale image
                for colCh=1:size(img, 3)
                    parfor (z = 1:size(img, 4), parforArg)
                        img(:,:,colCh,z) = imreducehaze(img(:,:,colCh,z), ...
                            BatchOpt.Amount{1}, 'method', BatchOpt.Method{1}, 'AtmosphericLight', AtmosphericLight(1), 'ContrastEnhancement', BatchOpt.ContrastEnhancement{1});
                        if showWaitbar; pwb.increment(); end
                    end
                end
            end
        case 'SaltAndPepper'
            logText = sprintf('%s, HSize:%s, Threshold:%d, NoiseType:%s', ....
                logText, BatchOpt.HSize, BatchOpt.IntensityThreshold{1}, BatchOpt.NoiseType{1});
            img = mibRemoveSaltAndPepperNoise(img, BatchOpt, cpuParallelLimit);
        case 'SlicClustering'
            % calculate number of superpixels
            dims = size(img);
            noPix = ceil(dims(1)*dims(2)/BatchOpt.ClusterSize{1});
            model = zeros([dims(1), dims(2), size(img, 4)]);
            pixNoArray = zeros([size(img, 4), 1]);
            parfor (z = 1:size(img, 4), parforArg)  % binarization filter, only one color channel
                [model(:,:,z), pixNoArray(z)] = slicmex(img(:,:,1,z), noPix, BatchOpt.Compactness{1});
                if showWaitbar; pwb.increment(); end
            end
            if max(pixNoArray) < 65535
                img = uint16(model)+1;
            else
                img = uint32(model)+1;
            end
        case 'UnsharpMask'
            logText = sprintf('%s, Radius:%.1f, Amount:%.1f, Threshold:%.2f, useRGB:%d', ....
                logText, BatchOpt.Radius{1}, BatchOpt.Amount{1}, BatchOpt.Threshold{1}, BatchOpt.useRGB);
            if BatchOpt.useRGB
                if size(img, 3) ~= 3
                    if showWaitbar; delete(pwb); end
                    errordlg(sprintf('!!! Error !!!\n\nThe image should have 3 color channels!\nThis image has %d color channels', size(img, 3))); 
                    return; 
                end
                if showWaitbar; pwb.setIncrement(3); end   % set increment for RGB images
                
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,:,z) = imsharpen(img(:,:,:,z), ...
                        'Radius', BatchOpt.Radius{1}, 'Amount', BatchOpt.Amount{1}, 'Threshold', BatchOpt.Threshold{1});
                    if showWaitbar; pwb.increment(); end
                end
            else    % grayscale image
                for colCh=1:size(img, 3)
                    parfor (z = 1:size(img, 4), parforArg)
                        img(:,:,colCh,z) = imsharpen(img(:,:,colCh,z), ...
                            'Radius', BatchOpt.Radius{1}, 'Amount', BatchOpt.Amount{1}, 'Threshold', BatchOpt.Threshold{1});
                        if showWaitbar; pwb.increment(); end
                    end
                end
            end
        case 'Wiener'
            NeighborhoodSize = str2num(BatchOpt.NeighborhoodSize);
            AdditiveNoise = str2num(BatchOpt.AdditiveNoise);
            if isempty('NeighborhoodSize'); errordlg('NeighborhoodSize should contain two numbers!'); return; end
            if numel(NeighborhoodSize)==1; NeighborhoodSize = [NeighborhoodSize, NeighborhoodSize]; end %#ok<AGROW>
            logText = sprintf('%s, NSize: %s, AddNoise:%s', logText, BatchOpt.NeighborhoodSize, BatchOpt.AdditiveNoise);
            for colCh=1:size(img, 3)
                parfor (z = 1:size(img, 4), parforArg)
                    img(:,:,colCh,z) = wiener2(img(:,:,colCh,z), NeighborhoodSize, AdditiveNoise);
                    if showWaitbar; pwb.increment(); end
                end
            end
        case 'WatershedClustering'
            if strcmp(BatchOpt.TypeOfSignal{1}, 'black-on-white')
                img = imcomplement(img);    % convert image that the ridges are white
            end
            % calculate number of superpixels
            dims = size(img);
            model = zeros([dims(1), dims(2), size(img, 4)]);
            gaps = 1;
            if strcmp(BatchOpt.GapPolicy{1}, 'remove gaps'); gaps = 0; end
            getClusters = 1;
            if strcmp(BatchOpt.ResultingShape{1}, 'ridges'); getClusters = 0; gaps = 1; end
            maxInt = zeros([size(img, 4), 1])+255;  % allocate space for max number of clusters per slice
            
            parfor (z = 1:size(img, 4), parforArg)  % binarization filter, only one color channel
                currImg = img(:,:,1,z);
                if BatchOpt.ClusterSize{1} > 0
                    mask = imextendedmin(currImg, BatchOpt.ClusterSize{1});
                    mask = imimposemin(currImg, mask);
                    mask = watershed(mask);
                else
                    mask = watershed(img);
                end
                
                if gaps == 0    % remove gaps
                    mask = imdilate(mask, ones(3));
                end
                
                if strcmp(BatchOpt.DestinationLayer{1}, 'model') && getClusters == 1
                    maxVal = double(intmax(class(mask(1))));
                    if maxInt(z) < maxVal; maxInt(z) = maxVal; end
                end
                
                model(:,:,z) = mask;
                if showWaitbar; pwb.increment(); end
            end
            maxInt = max(maxInt);   % get max number of clusters
            
            if getClusters
                if strcmp(BatchOpt.DestinationLayer{1}, 'model')
                    if maxInt < 65536
                        img = uint16(model) ;
                    else
                        img = uint32(model);
                    end
                else
                    img = uint8(model);
                    img(img>1) = 1;
                end
            else
                img = zeros(size(model),'uint8');
                img(model==0) = 1;
            end
    end
end
if showWaitbar; delete(pwb); end