function contrastNormalizationMemoryOptimized(obj, type_switch, colorChannel)
% function contrastNormalizationMemoryOptimized(obj, type_switch, colorChannel)
% Normalize contrast between the layers of the dataset
%
% This function requires @em handles structure of im_browser to get slices/datasets directly. It may work in two modes: the
% whole dataset or slice-by-slice. After some tests the slice-by-slice mode seems to be faster and more memory friendly for
% most cases. So it is fixed now in that mode. To change that the useFullDatasetSwitch = 0; should be commented in the
% following section of the code.
% @code
% // use the slice-by-slice mode, because it seems to be faster for most cases
% // the whole dataset mode make sense for the datasets with a very many sections
% useFullDatasetSwitch = 0;
% @endcode
%
% Parameters:
% type_switch: a type of the normalization: 
%   - ''normalZ'' - normalize in the Z-dimension contrast using intensities of each complete slice
%   - ''normalT'' - normalize in the Time-dimension contrast using intensities of each complete slice
%   - ''mask'' - normalize contrast using intensities of only masked area at each slice
%   - ''bgMean'' - shift intensities of each image based on background
%   intensity that is marked as the mask
% colorChannel: index of the color channel to use for normalization
%
% Return values:
% 

%| For @em normal type:
% - calculate mean intensity and its std for the whole dataset
% - calculate mean intensities and std for each layer
% - shift each layer based on difference between mean values of each
% layer and the whole dataset, plus stretch based on ratio between std of
% the whole dataset and current layer
%
% For @em mask type:
% - calculate mean intensity for the masked or selected area for the whole dataset
% - calculate mean intensities for the masked or selected area for each layer
% - shift each layer based on difference between mean values of each
% layer and the whole dataset
%
% For @em bgMean type:
% - calculate mean intensity for the masked or selected area for the whole dataset
% - shift each slice by the mean intensity of the masked or selected areas

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3; colorChannel = 1; end

if strcmp(obj.I{obj.Id}.meta('ColorType'), 'indexed')
    msgbox(sprintf('Please convert to grayscale or truecolor data format first!\nMenu->Image->Mode->'),...
        'Change format!', 'error', 'modal');
    return;
end

[maxH, maxW, maxC, maxZ, maxT] = obj.I{obj.Id}.getDatasetDimensions('image', NaN);

% define time points
t1 = obj.I{obj.Id}.getCurrentTimePoint;
t2 = t1;
z1 = 1;
z2 = maxZ;
if strcmp(type_switch, 'normalZ') && obj.I{obj.Id}.time > 1
    button =  questdlg(sprintf('Would you like to normalize the shown stack or all stacks?'),...
        'Normalize', 'Current Z-stack', 'All Z-stacks', 'Cancel', 'Current Z-stack');
    if strcmp(button, 'Cancel'); return; end
    if strcmp(button, 'All Z-stacks')
        t1 = 1;
        t2 = maxT;
    end
end

if strcmp(type_switch, 'normalT') && obj.I{obj.Id}.time > 1
    normalTmode =  questdlg(sprintf('Would you like to do normalization based on selected 2D slice (faster) or using information from complete 3D stack?'),...
        'Normalize', '2D slice', '3D stack', 'Cancel', '2D slice');
    if strcmp(normalTmode, 'Cancel'); return; end
    if strcmp(normalTmode, '2D slice')
        z1 = obj.I{obj.Id}.getCurrentSliceNumber();
        z2 = z1;
    end
    t1 = 1;
    t2 = maxT;
end

% define layer for normalization
if strcmp(type_switch, 'mask') || strcmp(type_switch, 'bgMean')
    button =  questdlg(sprintf('Define layer for normalization:'),...
        'Selection or Mask', 'Selection', 'Mask', 'Cancel', 'Selection');
    switch button
        case 'Cancel'
            return;
        case 'Selection'
            layer_id = 'selection';
        case 'Mask'
            layer_id = 'mask';
    end
end

if t1 == t2
    obj.mibDoBackup('image', 1);
end

% % detect whether it is possible to work with full dataset
% useFullDatasetSwitch = 0;
% if ispc   % memory is only available for windows
%     [userview, systemview] = memory;
%     datasetMemory = obj.I{obj.Id}.getDatasetSizeInBytes();   % get physical size of datasets
%     if (systemview.PhysicalMemory.Available - userview.MemUsedMATLAB) / datasetMemory > 1
%         useFullDatasetSwitch = 1;
%     end
% end


%% --------------------
% use the slice-by-slice mode, because it seems to be faster for most cases
% the whole dataset mode make sense for the datasets with a very many sections

tic;
wb = waitbar(0, sprintf('Normalizing dataset slice by slice\nPlease wait...'), 'Name', 'Normalizing layers...');

counter = 1;

waitbar(0.01, wb);

% check need for the mask
useMask = 0;     
if strcmp(type_switch, 'mask') || strcmp(type_switch, 'bgMean')
    useMask = 1;
    if strcmp(layer_id, 'mask')
        if obj.I{obj.Id}.maskExist == 0
            msgbox(sprintf('Cancelled!\nNo mask information found!\n\nPlease draw Mask for each slice of the dataset and try again'),...
                'Missing the Mask!', 'error', 'modal');
            delete(wb);
            return;
        end
    end
end

outliers = [];
if strcmp(type_switch, 'normalZ')
    button =  questdlg(sprintf('Please define intensities to use\n\nWhole range: use all intensities\nExclude blacks: do not consider pixels with intensity 0\nExclude whites: do not consider pixels with intensity 255'), 'Outliers', ...
        'Whole range', 'Exclude blacks', 'Exclude whites', 'Whole range');
    switch button
        case 'Whole range'
            outliers = [];
        case 'Exclude blacks'
            outliers = 0;
        case 'Exclude whites'
            options.t = [1 1];
            curr_img = cell2mat(obj.getData2D('image', 1, NaN, colorChannel, options));
            outliers = intmax(class(curr_img));
    end
end

if ~strcmp(type_switch, 'normalT')
    mean_val = zeros(maxZ, 1);
    std_val = zeros(maxZ, 1);
    
    for t=t1:t2
        options.t = [t t];
        % calculate sdt and mean
        for z=z1:z2
            curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel, options));
            
            if useMask == 0
                if isempty(outliers)
                    mean_val(z) = mean2(curr_img);
                    std_val(z) = std2(curr_img);
                else
                    if outliers == 0
                        mean_val(z) = mean(curr_img(curr_img>0));
                        std_val(z) = std(double(curr_img(curr_img>0)));
                    else
                        mean_val(z) = mean(curr_img(curr_img<outliers));
                        std_val(z) = std(double(curr_img(curr_img<outliers)));
                    end
                end
            else
                mask = cell2mat(obj.getData2D(layer_id, z, NaN, colorChannel, options));
                if max(mask(:)) == 0
                    mean_val(z) = NaN;
                    std_val(z) = NaN;
                    continue;
                end
                mean_val(z) = mean2(curr_img(mask==1));
                std_val(z) = std2(curr_img(mask==1));
            end
        end
        
        % find nan indices
        nanIds = find(isnan(mean_val));
        valIds = find(~isnan(mean_val));
        
        imgMean = mean(mean_val(valIds));
        imgStd = mean(std_val(valIds));
        
        % fill gaps in the vectors
        for i=1:numel(nanIds)
            valIndex = find(valIds > nanIds(i), 1);
            if isempty(valIndex)
                valIndex = find(valIds < nanIds(i), 1, 'last');
            end
            mean_val(nanIds(i)) = mean_val(valIds(valIndex));
            std_val(nanIds(i)) = std_val(valIds(valIndex));
        end
        
        if strcmp(type_switch, 'bgMean')    % intensities based on mean background value in the mask area
            for z=z1:z2
                curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel, options));
                curr_img = double(curr_img) - mean_val(z) + imgMean;
                obj.setData2D('image', curr_img, z, NaN, colorChannel, options);
                if mod(counter,10)==0; waitbar(counter/maxZ*maxT,wb); end
                counter = counter + 1;
            end
        else
            for z=z1:z2
                ratio = imgStd/std_val(z);
                curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel, options));
                I1 = double(curr_img) - mean_val(z);
                I1 = I1 * ratio;
                
                if isempty(outliers)
                    curr_img = I1 + imgMean;
                else
                    if outliers == 0
                        curr_img(curr_img>0) = I1(curr_img>0) + imgMean;
                    else
                        curr_img(curr_img<outliers) = I1(curr_img<outliers) + imgMean;
                    end
                end
                obj.setData2D('image', curr_img, z, NaN, colorChannel, options);
                if mod(counter,10)==0; waitbar(counter/maxZ*maxT,wb); end
                counter = counter + 1;
            end
        end
    end
else
    mean_val = zeros(maxT, 1);
    std_val = zeros(maxT, 1);
    for t=t1:t2
        options.t = [t t];
        if strcmp(normalTmode, '2D slice')
            curr_img = double(cell2mat(obj.getData2D('image', z1, NaN, colorChannel, options)));
        else
            curr_img = double(cell2mat(obj.getData3D('image', t, colorChannel)));
        end
        mean_val(t) = mean(curr_img(:));
        std_val(t) = std(curr_img(:));
        waitbar(t/t2,wb);
    end
    imgMean = mean(mean_val);
    imgStd = mean(std_val);
        
    for t=t1:t2
        options.t = [t t];
        ratio = imgStd/std_val(t);
        for z=1:maxZ
            curr_img = cell2mat(obj.getData2D('image', z, NaN, colorChannel, options));
            I1 = double(curr_img) - mean_val(t);
            I1 = I1 * ratio;
            curr_img = I1 + imgMean;
            obj.setData2D('image', curr_img, z, NaN, colorChannel, options);
        end
        waitbar(t/t2,wb);
    end
end

% update the log
log_text = sprintf('Normalize contrast, mode: %s, Ch: %d', type_switch, colorChannel);
obj.I{obj.Id}.updateImgInfo(log_text);

delete(wb);
toc
end