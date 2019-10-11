function insertSlice(obj, img, insertPosition, meta, options)
% function insertSlice(obj, img, insertPosition, meta, options)
% Insert a slice or a dataset into the existing volume
%
% Parameters:
% img: new 2D-4D image stack to insert
% insertPosition: @b [optional] position where to insert the new slice/volume
% starting from @b 1. When omitted or @em NaN or @em 0 - add img to the end of the dataset
% meta: @b [optional] containers Map with parameters of the dataset to insert, can be empty
% options: an optional structure with additional paramters
% .dim - a string that defines dimension 'depth' (default), 'time'
% .BackgroundColorIntensity  - a number with background color
% .silentMode - logical, a silent mode, when no questions be asked
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, 1);     // call from mibController class; insert img to the beginning of the opened dataset @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, insertPosition, img_info); // call from mibController class @endcode
% @code 
% options.dim = 'time';     // define add a dataset as a new time point
% obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, insertPosition, img_info, options); // call from mibController class; add img as a new time point
% @endcode

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 30.10.2017, IB updated for 5D datasets: fixed insert in Z and added insert in T
% 25.08.2018, updated for virtual stacks for the z-dimension
% 09.05.2019, added extra options

global mibPath; % path to mib installation folder

if nargin < 5; options = struct; end
if nargin < 4; meta = containers.Map; end
if nargin < 3; insertPosition = NaN; end
if insertPosition == 0; insertPosition = NaN; end

if isempty(meta); meta = containers.Map; end
if ~isfield(options, 'dim'); options.dim = 'depth'; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end
if ~isfield(options, 'BackgroundColorIntensity'); options.BackgroundColorIntensity = 0; end
if ~isfield(options, 'silentMode'); options.silentMode = false; end

if ~isKey(meta, 'Height'); meta('Height') = size(img, 1); end
if ~isKey(meta, 'Width'); meta('Width') = size(img, 2); end
if ~isKey(meta, 'Colors'); meta('Colors') = size(img, 3); end
if ~isKey(meta, 'Depth'); meta('Depth') = size(img, 4); end
if ~isKey(meta, 'Time'); meta('Time') = size(img, 5); end

BackgroundColorIntensity = options.BackgroundColorIntensity;
if obj.meta('Height') ~= meta('Height') || obj.meta('Width') ~= meta('Width') || obj.meta('Colors') ~= meta('Colors')
    if obj.Virtual.virtual == 0
        if options.silentMode == 0
            answer = mibInputDlg({mibPath}, sprintf('Warning!\nSome of the image dimensions mismatch.\nContinue anyway?\n\nBackground color (a single number between: [0-%d])', intmax(class(img))),'Wrong dimensions', num2str(intmax(class(img))));
            if isempty(answer); return; end
            BackgroundColorIntensity = str2double(answer{1});
        end
    else
        errordlg(sprintf('!!! Error !!!\n\nImage dimensions mismatch'));
        return;
    end
end
if strcmp(options.dim, 'depth')
    if isnan(insertPosition) || insertPosition > obj.depth    % define start position at the end of the opened dataset
        insertPosition = obj.depth + 1;
    end
else
    if isnan(insertPosition) || insertPosition > obj.time    % define start position at the end of the opened dataset
        insertPosition = obj.time + 1;
    end
end
if options.showWaitbar; wb = waitbar(0,sprintf('Insert dataset to position: %d\nPlease wait...', insertPosition),'Name','Insert dataset...','WindowStyle','modal'); end

% store dimensions of the existing datasets
D1_y = obj.meta('Height');
D1_x = obj.meta('Width');
D1_c = obj.meta('Colors');
D1_z = obj.meta('Depth');
D1_t = obj.meta('Time');

% store dimensions of the inserted datasets
D2_y = meta('Height');
D2_x = meta('Width');
D2_c = meta('Colors');
D2_z = meta('Depth');
D2_t = meta('Time');

cMax = max([D1_c D2_c]);
xMax = max([D1_x D2_x]);
yMax = max([D1_y D2_y]);
zMax = max([D1_z D2_z]);
tMax = max([D1_t D2_t]);

if strcmp(options.dim, 'depth')
    if obj.Virtual.virtual == 0
        if BackgroundColorIntensity ~= 0
            imgOut = zeros([yMax, xMax, cMax, D1_z+D2_z, tMax], obj.meta('imgClass')) + BackgroundColorIntensity;
        else
            imgOut = zeros([yMax, xMax, cMax, D1_z+D2_z, tMax], obj.meta('imgClass'));
        end
        if options.showWaitbar; waitbar(.05, wb); end
        if insertPosition == 1  % insert dataset in the beginning of the opened dataset
            Z1_part1 = [D2_z+1 D2_z+D1_z];
            Z1_part2 = [];
            Z2_part1 = [1 D2_z];
        elseif insertPosition == D1_z+1 % add dataset to the end of the existing dataset
            Z1_part1 = [1 D1_z];
            Z1_part2 = [];
            Z2_part1 = [D1_z+1 D1_z+D2_z];
        else        % insert dataset inside the existing dataset
            Z1_part1 = [1 insertPosition-1];
            Z1_part2 = [insertPosition+D2_z D2_z+D1_z];
            Z2_part1 = [insertPosition insertPosition+D2_z-1];
        end

        % adding to the image
        imgOut(1:D1_y, 1:D1_x, 1:D1_c, Z1_part1(1):Z1_part1(2), 1:D1_t) = obj.img{1}(:, :, :, 1:Z1_part1(2)-Z1_part1(1)+1, :);
        imgOut(1:D2_y, 1:D2_x, 1:D2_c, Z2_part1(1):Z2_part1(2), 1:D2_t) = img;
        if ~isempty(Z1_part2)
            imgOut(1:D1_y, 1:D1_x, 1:D1_c, Z1_part2(1):Z1_part2(2), 1:D1_t) = obj.img{1}(:, :, :, Z1_part1(2)+1:end, :);
        end
        obj.img{1} = imgOut;
        if options.showWaitbar; waitbar(.4, wb); end

        % adding to the model
        if obj.modelType == 63 && ~isnan(obj.model{1}(1))     % resize uint6 type of the model
            imgOut = zeros([yMax, xMax, D1_z+D2_z, tMax], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2), 1:D1_t) = obj.model{1}(:, :, 1:Z1_part1(2)-Z1_part1(1)+1, :);
            if ~isempty(Z1_part2)
                imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2), 1:D1_t) = obj.model{1}(:, :, Z1_part1(2)+1:end, :);
            end
            obj.model{1} = imgOut;
            if options.showWaitbar; waitbar(.9, wb); end
        else        % resize other types of models
            if obj.modelExist == 1       % resize model layer
                imgOut = zeros([yMax, xMax, D1_z+D2_z, tMax], 'uint8');
                imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2), 1:D1_t) = obj.model{1}(:, :, 1:Z1_part1(2)-Z1_part1(1)+1, :);
                if ~isempty(Z1_part2)
                    imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2), 1:D1_t) = obj.model{1}(:, :, Z1_part1(2)+1:end, :);
                end
                obj.model{1} = imgOut;
            end
            if options.showWaitbar; waitbar(.6, wb); end
            if obj.maskExist == 1      % resize mask layer
                imgOut = zeros([yMax, xMax, D1_z+D2_z, tMax], 'uint8');
                imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2), 1:D1_t) = obj.maskImg{1}(:, :, 1:Z1_part1(2)-Z1_part1(1)+1, :);
                if ~isempty(Z1_part2)
                    imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2), 1:D1_t) = obj.maskImg{1}(:, :, Z1_part1(2)+1:end, :);
                end
                obj.maskImg{1} = imgOut;
            end
            if options.showWaitbar; waitbar(.8, wb); end
            if ~isnan(obj.selection{1}(1))    % resize selection
                imgOut = zeros([yMax, xMax, D1_z+D2_z, tMax], 'uint8');
                imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2), 1:D1_t) = obj.selection{1}(:, :, 1:Z1_part1(2)-Z1_part1(1)+1, :);
                if ~isempty(Z1_part2)
                    imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2), 1:D1_t) = obj.selection{1}(:, :, Z1_part1(2)+1:end, :);
                end
                obj.selection{1} = imgOut;
            end
            if options.showWaitbar; waitbar(.9, wb); end
        end
    else
        if insertPosition == 1  % insert dataset in the beginning of the opened dataset
            obj.img = [img; obj.img];
            obj.Virtual.filenames = [meta('Virtual_filenames'); obj.Virtual.filenames];     % update filenames
            obj.Virtual.objectType = [meta('Virtual_objectType'); obj.Virtual.objectType]; 
            obj.Virtual.readerId = [meta('Virtual_readerId'); obj.Virtual.readerId+max(meta('Virtual_readerId'))];
            obj.Virtual.seriesName = [meta('Virtual_seriesName'); obj.Virtual.seriesName]; 
            obj.Virtual.slicesPerFile = [meta('Virtual_slicesPerFile'); obj.Virtual.slicesPerFile]; 
        elseif insertPosition == D1_z+1 % add dataset to the end of the existing dataset
            obj.img = [obj.img; img];
            obj.Virtual.filenames = [obj.Virtual.filenames; meta('Virtual_filenames')];     % update filenames
            obj.Virtual.objectType = [obj.Virtual.objectType; meta('Virtual_objectType')]; 
            obj.Virtual.readerId = [obj.Virtual.readerId; meta('Virtual_readerId')+max(obj.Virtual.readerId)];
            obj.Virtual.seriesName = [obj.Virtual.seriesName; meta('Virtual_seriesName')]; 
            obj.Virtual.slicesPerFile = [obj.Virtual.slicesPerFile; meta('Virtual_slicesPerFile')]; 
            
        else        % insert dataset inside the existing dataset
            obj.img = [obj.img(1:insertPosition-1); img; obj.img(insertPosition:end)];
            obj.Virtual.filenames = [obj.Virtual.filenames(1:insertPosition-1); meta('Virtual_filenames'); obj.Virtual.filenames(insertPosition:end) ];     % update filenames
            obj.Virtual.objectType = [obj.Virtual.objectType(1:insertPosition-1); meta('Virtual_objectType'); obj.Virtual.objectType(insertPosition:end)]; 
            obj.Virtual.readerId = [obj.Virtual.readerId(1:insertPosition-1); ...
                meta('Virtual_readerId')+max(obj.Virtual.readerId(1:insertPosition-1));...
                obj.Virtual.readerId(insertPosition:end)+max(meta('Virtual_readerId'))];
            obj.Virtual.seriesName = [obj.Virtual.seriesName(1:insertPosition-1); meta('Virtual_seriesName'); obj.Virtual.seriesName(insertPosition:end)]; 
            obj.Virtual.slicesPerFile = [obj.Virtual.slicesPerFile(1:insertPosition-1); meta('Virtual_slicesPerFile'); obj.Virtual.slicesPerFile(insertPosition:end)]; 
        end
    end
    
    % shift labels
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels();
    if numel(labelsList) > 0
        labelPositions(labelPositions(:,1)>=insertPosition,1) = labelPositions(labelPositions(:,1)>=insertPosition,1)+1;
        obj.hLabels.replaceLabels(labelsList, labelPositions, labelValues);
    end
    
    clear imgOut;
else        % insert a new time point
%     if D2_c > D1_c || D2_x > D1_x || D2_y > D1_y || D2_z > D1_z
%         % resize the opened image
%         obj.img{1} = padarray(obj.img{1}, [D2_y-D1_y, D2_x-D1_x, D2_c-D1_c, D2_z-D1_z], BackgroundColorIntensity, 'post');
%     end
    
    if BackgroundColorIntensity ~= 0
        imgOut = zeros([yMax, xMax, cMax, zMax, D1_t+D2_t], obj.meta('imgClass')) + BackgroundColorIntensity;
    else
        imgOut = zeros([yMax, xMax, cMax, zMax, D1_t+D2_t], obj.meta('imgClass'));
    end
    if options.showWaitbar; waitbar(.05, wb); end
    
    if insertPosition == 1  % insert dataset in the beginning of the opened dataset
        T1_part1 = [D2_t+1 D2_t+D1_t];
        T1_part2 = [];
        T2_part1 = [1 D2_t];
    elseif insertPosition == D1_t+1 % add dataset to the end of the existing dataset
        T1_part1 = [1 D1_t];
        T1_part2 = [];
        T2_part1 = [D1_t+1 D1_t+D2_t];
    else        % insert dataset inside the existing dataset
        T1_part1 = [1 insertPosition-1];
        T1_part2 = [insertPosition+D2_t D2_t+D1_t];
        T2_part1 = [insertPosition insertPosition+D2_t-1];
    end
    
    % adding to the image
    imgOut(1:D1_y, 1:D1_x, 1:D1_c, 1:D1_z, T1_part1(1):T1_part1(2)) = obj.img{1}(:, :, :, :, 1:T1_part1(2)-T1_part1(1)+1);
    imgOut(1:D2_y, 1:D2_x, 1:D2_c, 1:D2_z, T2_part1(1):T2_part1(2)) = img;
    if ~isempty(T1_part2)
        imgOut(1:D1_y, 1:D1_x, 1:D1_c, 1:D1_z, T1_part2(1):T1_part2(2)) = obj.img{1}(:, :, :, :, T1_part1(2)+1:end);
    end
    obj.img{1} = imgOut;
    if options.showWaitbar; waitbar(.4, wb); end
    
    % adding to the model
    if obj.modelType == 63 && ~isnan(obj.model{1}(1))     % resize uint6 type of the model
        imgOut = zeros([yMax, xMax, zMax, D1_t+D2_t], 'uint8');
        imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part1(1):T1_part1(2)) = obj.model{1}(:, :, :, 1:T1_part1(2)-T1_part1(1)+1);
        if ~isempty(T1_part2)
            imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part2(1):T1_part2(2)) = obj.model{1}(:, :, :, T1_part1(2)+1:end);
        end
        obj.model{1} = imgOut;
        if options.showWaitbar; waitbar(.9, wb); end
    else        % resize other types of models
        if obj.modelExist == 1       % resize model layer
            imgOut = zeros([yMax, xMax, zMax, D1_t+D2_t], 'uint8');
            imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part1(1):T1_part1(2)) = obj.model{1}(:, :, :, 1:T1_part1(2)-T1_part1(1)+1);
            if ~isempty(T1_part2)
                imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part2(1):T1_part2(2)) = obj.model{1}(:, :, :, T1_part1(2)+1:end);
            end
            obj.model{1} = imgOut;
        end
        if options.showWaitbar; waitbar(.6, wb); end
        if obj.maskExist == 1      % resize mask layer
            imgOut = zeros([yMax, xMax, zMax, D1_t+D2_t], 'uint8');
            imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part1(1):T1_part1(2)) = obj.maskImg{1}(:, :, :, 1:T1_part1(2)-T1_part1(1)+1);
            if ~isempty(T1_part2)
                imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part2(1):T1_part2(2)) = obj.maskImg{1}(:, :, :, T1_part1(2)+1:end);
            end
            obj.maskImg{1} = imgOut;
        end
        if options.showWaitbar; waitbar(.8, wb); end
        if ~isnan(obj.selection{1}(1))    % resize selection
            imgOut = zeros([yMax, xMax, zMax, D1_t+D2_t], 'uint8');
            imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part1(1):T1_part1(2)) = obj.selection{1}(:, :, :, 1:T1_part1(2)-T1_part1(1)+1);
            if ~isempty(T1_part2)
                imgOut(1:D1_y, 1:D1_x, 1:D1_z, T1_part2(1):T1_part2(2)) = obj.selection{1}(:, :, :, T1_part1(2)+1:end);
            end
            obj.selection{1} = imgOut;
        end
        if options.showWaitbar; waitbar(.9, wb); end
    end
    % shift labels
    [labelsList, labelValues, labelPositions, indices] = obj.hLabels.getLabels();   % [labelIndex, z x y t]
    if numel(labelsList) > 0
        labelPositions(labelPositions(:,4)>=insertPosition,4) = labelPositions(labelPositions(:,4)>=insertPosition,4)+1;
        obj.hLabels.replaceLabels(labelsList, labelPositions, labelValues);
    end
    
    clear imgOut;
end

obj.colors = cMax;
obj.width = xMax;
obj.height = yMax;
if strcmp(options.dim, 'depth')
    obj.depth = obj.meta('Depth')+meta('Depth');
else
    obj.time = obj.meta('Time')+meta('Time');
end
obj.dim_yxczt = [obj.height, obj.width, obj.colors, obj.depth, obj.time];

obj.meta('Height') = yMax;
obj.meta('Width') = xMax;
obj.meta('Colors') = cMax;
obj.meta('Depth') = obj.depth;
obj.meta('Time') = obj.time;
obj.updateBoundingBox();

% update obj.slices
if obj.orientation == 4
    obj.slices{1} = [1, obj.height];
    obj.slices{2} = [1, obj.width];
elseif obj.orientation == 1
    obj.slices{2} = [1, obj.width];
    obj.slices{4} = [1, obj.depth];
elseif obj.orientation == 2
    obj.slices{1} = [1, obj.height];
    obj.slices{4} = [1, obj.depth];
end

if isKey(obj.meta, 'SliceName')
    sliceNames = obj.meta('SliceName');
    % generate vector of slice names
    if numel(sliceNames) == 1; sliceNames = repmat(sliceNames,[D1_z 1]);   end
    
    if isKey(meta, 'SliceName') == 0
        sliceNamesNew = {''};
    else
        sliceNamesNew = meta('SliceName');
    end
    if numel(sliceNamesNew) == 1; sliceNamesNew = repmat(sliceNamesNew,[D2_z 1]);   end
    
    if insertPosition == D1_z+1     % end of the dataset
        sliceNames = [sliceNames; sliceNamesNew];
    elseif insertPosition == 1
        sliceNames = [sliceNamesNew; sliceNames];
    else
        sliceNames = [sliceNames(1:insertPosition-1); sliceNamesNew; sliceNames(insertPosition:end)];
    end
    obj.meta('SliceName') = sliceNames;
end
obj.updateImgInfo(sprintf('Insert dataset [%dx%dx%dx%dx%d] at position %s=%d', D2_y, D2_x, D2_c, D2_z, D2_t, options.dim, insertPosition));  % update log
if options.showWaitbar; waitbar(1, wb); delete(wb); end

end