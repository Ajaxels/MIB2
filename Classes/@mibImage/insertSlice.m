function insertSlice(obj, img, insertPosition, meta)
% function insertSlice(obj, img, insertPosition, meta)
% Insert a slice or a dataset into the existing volume
%
% Parameters:
% img: new 2D-4D image stack to insert
% insertPosition: @b [optional] position where to insert the new slice/volume
% starting from @b 1. When omitted or @em NaN add img to the end of the dataset
% img_info: @b [optional] containers Map with parameters of the dataset to insert
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, 1);     // call from mibController class; insert img to the beginning of the opened dataset @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.insertSlice(img, insertPosition, img_info); // call from mibController class @endcode

% Copyright (C) 10.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
global mibPath; % path to mib installation folder

if nargin < 4; meta = containers.Map; end;
if nargin < 3; insertPosition = NaN; end;

bgColor = 0;
if size(obj.img{1}, 1) ~= size(img, 1) || size(obj.img{1},2) ~= size(img, 2) || size(obj.img{1},3) ~= size(img, 3)
    answer = mibInputDlg({mibPath}, sprintf('Warning!\nSome of the image dimensions mismatch.\nContinue anyway?\n\nBackground color (a single number between: [0-%d])', intmax(class(img))),'Wrong dimensions','0');
    if isempty(answer); return; end;
    bgColor = str2double(answer{1});
end
if isnan(insertPosition) || insertPosition > obj.depth    % define start position at the end of the opened dataset
    insertPosition = obj.depth + 1;
end
wb = waitbar(0,sprintf('Insert dataset to position: %d\nPlease wait...', insertPosition),'Name','Insert dataset...','WindowStyle','modal');

% store dimensions of the existing datasets
D1_y = size(obj.img{1},1);
D1_x = size(obj.img{1},2);
D1_c = size(obj.img{1},3);
D1_z = size(obj.img{1},4);

% store dimensions of the inserted datasets
D2_y = size(img,1);
D2_x = size(img,2);
D2_c = size(img,3);
D2_z = size(img,4);


cMax = max([D1_c D2_c]);
xMax = max([D1_x D2_x]);
yMax = max([D1_y D2_y]);

if bgColor ~= 0
    imgOut = zeros([yMax, xMax, cMax, D1_z+D2_z], class(obj.img{1})) + bgColor;
else
    imgOut = zeros([yMax, xMax, cMax, D1_z+D2_z], class(obj.img{1}));
end
waitbar(.05, wb);
if insertPosition == 1  % insert dataset in the beginning of the opened dataset
    Z1_part2 = [D2_z+1 D2_z+D1_z];
    Z2_part1 = [1 D2_z];
    imgOut(1:D1_y, 1:D1_x, 1:D1_c, Z1_part2(1):Z1_part2(2)) = obj.img{1};
    imgOut(1:D2_y, 1:D2_x, 1:D2_c, Z2_part1(1):Z2_part1(2)) = img;
    obj.img{1} = imgOut;
    waitbar(.4, wb);
    % resize model
    if obj.modelType == 63 && ~isnan(obj.model{1}(1))     % resize uint6 type of the model
        imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
        imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.model{1};
        obj.model{1} = imgOut;
        waitbar(.9, wb);
    else        % resize other types of models
        if obj.modelExist == 1       % resize model layer
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.model{1};
            obj.model{1} = imgOut;
        end
        waitbar(.6, wb);
        if obj.maskExist == 1      % resize mask layer
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.maskImg{1};
            obj.maskImg{1} = imgOut;
        end
        waitbar(.8, wb);
        if ~isnan(obj.selection{1}(1))    % resize selection
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.selection{1};
            obj.selection{1} = imgOut;
        end
        waitbar(.9, wb);
    end
elseif insertPosition == D1_z+1 % add dataset to the end of the existing dataset
    Z1_part1 = [1 D1_z];
    Z2_part2 = [D1_z+1 D1_z+D2_z];
    imgOut(1:D1_y, 1:D1_x, 1:D1_c, Z1_part1(1):Z1_part1(2)) = obj.img{1};
    imgOut(1:D2_y, 1:D2_x, 1:D2_c, Z2_part2(1):Z2_part2(2)) = img;
    obj.img{1} = imgOut;
    waitbar(.4, wb);
    % resize model
    if obj.modelType == 63 && ~isnan(obj.model{1}(1))     % resize uint6 type of the model
        imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
        imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.model{1};
        obj.model{1} = imgOut;
        waitbar(.9, wb);
    else        % resize other types of models
        if obj.modelExist       % resize model layer
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.model{1};
            obj.model{1} = imgOut;
        end
        waitbar(0.6, wb);
        if obj.maskExist       % resize mask layer
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.maskImg{1};
            obj.maskImg{1} = imgOut;
        end
        waitbar(.7, wb);
        if ~isnan(obj.selection{1}(1))    % resize selection
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.selection{1};
            obj.selection{1} = imgOut;
        end
        waitbar(.9, wb);
    end
else        % insert dataset inside the existing dataset
    Z1_part1 = [1 insertPosition-1];
    Z1_part2 = [insertPosition+D2_z D2_z+D1_z];
    Z2_part1 = [insertPosition insertPosition+D2_z-1];
    imgOut(1:D1_y, 1:D1_x, 1:D1_c, Z1_part1(1):Z1_part1(2)) = obj.img{1}(:,:,:,1:Z1_part1(2));
    imgOut(1:D2_y, 1:D2_x, 1:D2_c, Z2_part1(1):Z2_part1(2)) = img;
    imgOut(1:D1_y, 1:D1_x, 1:D1_c, Z1_part2(1):Z1_part2(2)) = obj.img{1}(:,:,:,Z1_part1(2)+1:end);
    obj.img{1} = imgOut;
    waitbar(.4, wb);
    % resize model
    if obj.modelType == 63 && ~isnan(obj.model{1}(1))     % resize uint6 type of the model
        imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
        imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.model{1}(:,:,1:Z1_part1(2));
        imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.model{1}(:,:,Z1_part1(2)+1:end);
        obj.model{1} = imgOut;
        waitbar(.9, wb);
    else        % resize other types of models
        if obj.modelExist       % resize model layer
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.model{1}(:,:,1:Z1_part1(2));
            imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.model{1}(:,:,Z1_part1(2)+1:end);
            obj.model{1} = imgOut;
        end
        waitbar(.6, wb);
        if obj.maskExist       % resize mask layer
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.maskImg{1}(:,:,1:Z1_part1(2));
            imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.maskImg{1}(:,:,Z1_part1(2)+1:end);
            obj.maskImg{1} = imgOut;
        end
        waitbar(.7, wb);
        if ~isnan(obj.selection{1}(1))    % resize selection
            imgOut = zeros([yMax, xMax, D1_z+D2_z], 'uint8');
            imgOut(1:D1_y, 1:D1_x, Z1_part1(1):Z1_part1(2)) = obj.selection{1}(:,:,1:Z1_part1(2));
            imgOut(1:D1_y, 1:D1_x, Z1_part2(1):Z1_part2(2)) = obj.selection{1}(:,:,Z1_part1(2)+1:end);
            obj.selection{1} = imgOut;
        end
        waitbar(.9, wb);
    end
     
end
clear imgOut;

obj.colors = cMax;
obj.width = xMax;
obj.height = yMax;
obj.depth = size(obj.img{1}, 4);
obj.time = size(obj.img{1}, 5);

obj.meta('Height') = yMax;
obj.meta('Width') = xMax;
obj.meta('Depth') = obj.depth;
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
    if numel(sliceNames) == 1; sliceNames = repmat(sliceNames,[D1_z 1]);   end;
    
    if isempty(meta)
        sliceNamesNew = {''};
    else
        sliceNamesNew = meta('SliceName');
    end
    if numel(sliceNamesNew) == 1; sliceNamesNew = repmat(sliceNamesNew,[D2_z 1]);   end;
    
    if insertPosition == D1_z+1     % end of the dataset
        sliceNames = [sliceNames; sliceNamesNew];
    elseif insertPosition == 1
        sliceNames = [sliceNamesNew; sliceNames];
    else
        sliceNames = [sliceNames(1:insertPosition-1); sliceNamesNew; sliceNames(insertPosition:end)];
    end
    obj.meta('SliceName') = sliceNames;
end
obj.updateImgInfo(sprintf('Insert dataset [%dx%dx%dx%d] at position %d', D2_y, D2_x, D2_c, D2_z, insertPosition));  % update log
waitbar(1, wb);
delete(wb);
end