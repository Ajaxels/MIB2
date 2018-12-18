function result = cropDataset(obj, cropF)
% function result = cropDataset(obj, cropF)
% Crop image and all corresponding layers of the opened dataset
%
% Parameters:
% cropF: a vector [x1, y1, dx, dy, z1, dz, t1, dt] with parameters of the crop. @b Note! The units are pixels!
%
% Return values:
% result: status of the operation, 1-success, 0-cancel

%| 
% @b Examples:
% @code cropF = [100 512 200 512 5 20];  // define parameters of the crop  @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.cropDataset(cropF);  // call from mibController; do the crop @endcode

% Copyright (C) 01.02.2017, Ilya Belevich (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 12.12.2018 - fix of cropping of the selection layer for models with more than 63 materials


result = 0;
wb = waitbar(0,'Please wait...', 'Name', 'Cropping...');

% define time points
if numel(cropF) < 7; cropF(7:8) = [1, obj.time]; end
waitbar(.05, wb);

%viewPort = obj.viewPort;    % store viewport information, to keep the contrast after the crop

if obj.Virtual.virtual == 0
    %newI = zeros([cropF(4),cropF(3),size(obj.img,3),cropF(6) cropF(8)],class(obj.img));
    %[x1, y1, dx, dy, z1, dz, t1, dt]
    obj.img{1} = obj.img{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, :, ...
                cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
    waitbar(.4, wb);
    clear newI;
    if obj.modelType ~= 63
        if obj.modelExist % crop model
            obj.model{1} = obj.model{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
                cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
        end
        waitbar(.7, wb);
        if obj.maskExist     % crop mask
            obj.maskImg{1} = obj.maskImg{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
                cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
        end
        if  ~isnan(obj.selection{1}(1))
            obj.selection{1} = obj.selection{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
                cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
        end
    elseif ~isnan(obj.model{1}(1))     % crop model/selectio/mask layer
        obj.model{1} = obj.model{1}(cropF(2):cropF(2)+cropF(4)-1, cropF(1):cropF(1)+cropF(3)-1, ...
                cropF(5):cropF(5)+cropF(6)-1, cropF(7):cropF(7)+cropF(8)-1);
    end
else    % virtual stacking mode
    options.y = [cropF(2), cropF(2)+cropF(4)-1];
    options.x = [cropF(1), cropF(1)+cropF(3)-1];
    options.z = [cropF(5), cropF(5)+cropF(6)-1];
    options.t = [cropF(7), cropF(7)+cropF(8)-1];
    options.replaceDatasetSwitch = 1;
    
    img = obj.getDataVirt('image', 4, 0, options);
    %obj.Virtual.virtual = 0;    % turn off virtual mode
    %obj.closeVirtualDataset();    % close open virtual datasets
    newMode = obj.switchVirtualStackingMode(0);   % switch to the memory resident mode
    if isempty(newMode); delete(wb); return; end
    
    % to preserve meta data do not use mibImage.switchVirtualStackingMode
    % function
    obj.setData('image', img);
    
    % allocate memory for service layers
    if obj.disableSelection == 0
        if obj.modelType == 255
            obj.maskImg{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8'); % bw filter data
            obj.selection{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8'); % selection mask image
            obj.model{1} = NaN; % model image
        elseif obj.modelType == 63
            obj.model{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8');
            obj.maskImg{1} = NaN;
            obj.selection{1} = NaN;
        elseif obj.modelType == 128
            obj.maskImg{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'int8'); %
            obj.selection{1} = zeros([size(obj.img{1},1) size(obj.img{1},2) size(obj.img{1},4) size(obj.img{1},5)], 'uint8'); % selection mask image
            obj.model{1} = NaN; % model image
        end
    else
        obj.selection{1} = NaN;
        obj.model{1} = NaN;
        obj.maskImg{1} = NaN;
    end
end
waitbar(.9, wb);
% restore view port
%obj.viewPort = viewPort;

obj.height = cropF(4);
obj.width = cropF(3);
obj.depth = cropF(6);
obj.time = cropF(8);

if obj.height < obj.current_yxz(1); obj.current_yxz(1) = obj.height; end
if obj.width < obj.current_yxz(2); obj.current_yxz(2) = obj.width; end
if obj.depth < obj.current_yxz(3); obj.current_yxz(3) = obj.depth; end

obj.meta('Height') = cropF(4);
obj.meta('Width') = cropF(3);
obj.meta('Depth') = obj.depth;
obj.meta('Time') = obj.time;

obj.dim_yxczt = [obj.meta('Height'), obj.meta('Width'), obj.dim_yxczt(3), obj.meta('Depth'), obj.meta('Time')];

% update obj.slices
current_layer = obj.slices{obj.orientation}(1);
obj.slices{1} = [1, obj.height];
obj.slices{2} = [1, obj.width];
obj.slices{4} = [1, obj.depth];
obj.slices{5} = [min([obj.slices{5} obj.time]) min([obj.slices{5} obj.time])];
obj.slices{obj.orientation} = [min([obj.dim_yxczt(obj.orientation) current_layer]), min([obj.dim_yxczt(obj.orientation) current_layer])];

% update name of slices if present
if isKey(obj.meta, 'SliceName')
    sliceNames = obj.meta('SliceName');
    if numel(obj.meta('SliceName')) > 1
        obj.meta('SliceName') = sliceNames(cropF(5):cropF(5)+cropF(6)-1);
    end
end

xyzShift = [(cropF(1)-1)*obj.pixSize.x (cropF(2)-1)*obj.pixSize.y (cropF(5)-1)*obj.pixSize.z];
% update BoundingBox Coordinates
obj.updateBoundingBox(NaN, xyzShift);
waitbar(1, wb);
delete(wb);
result = 1;
end