function result = setData(obj, type, dataset, orient, col_channel, options)
% result = setData(obj, type, dataset, orient, col_channel, options)
% Set dataset
%
% Parameters:
% type: type of the dataset to update, 'image', 'model','mask', 'selection', or 'everything' ('model','mask' and 'selection' for imageData.model_type==''uint6'' only)
% dataset: 4D or 5D stack. For the 'image' type: [1:height, 1:width, 1:colors, 1:depth, 1:time]; for all other types: [1:height, 1:width, 1:thickness, 1:time]
% orient: [@em optional], can be @em NaN
% @li when @b 0 (@b default) updates the dataset transposed from the current orientation (obj.orientation)
% @li when @b 1 updates transposed dataset from the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 updates transposed dataset from the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 updates original dataset from the yx configuration: [y,x,c,z,t]
% @li when @b 5 not used
% col_channel: [@em optional],
% @li when @b type is 'image', @b col_channel is a vector with color numbers to update, when @b NaN [@e default] take the colors
% selected in the imageData.slices{3} variable, when @b 0 - take all colors of the dataset.
% @li when @b type is 'model' @b col_channel may be @em NaN - to take all materials of the model or an integer to take specific material. In the later case the selected material will have index = 1.
% options: [@em optional], a structure with extra parameters
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose for level=1, when @b 0 takes 1:obj.height; can be a single number
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose for level=1, when @b 0 takes 1:obj.width; can be a single number
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, when @b 0 takes 1:obj.depth; can be a single number
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, when @b 0 takes 1:obj.time; can be a single number
% @li .level -> [@em optional], index of image level from the image pyramid
% @li .replaceDatasetSwitch -> [@em optional], force to replace dataset completely with a new dataset
% @li .keepModel -> [@em optional], do not resize the model/selection
% layers when type='image' and submitting complete dataset; as result the selection/model layers have to be
% modified manually layer. Used in mibResampleController. Default = 1;
%
% Return values:
% result: -> @b 1 - success, @b 0 - error

%|
% @b Examples:
% @code obj.setData('image', dataset);      // update the complete dataset in the shown orientation @endcode
% @code obj.setData('image', dataset, 4, 2); // update complete dataset in the XY orientation with only second color channel @endcode

% Copyright (C) 06.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

result = 0; %#ok<NASGU>
if isempty(dataset); return; end

% the virtual mode is not implemented yet
if obj.Virtual.virtual == 1;     return; end

if nargin < 6; options = struct(); end
if nargin < 5; col_channel = NaN; end
if nargin < 4; orient=obj.orientation; end

% setting default values for the orientation
if orient == 0 || isnan(orient); orient=obj.orientation; end

if ~isfield(options, 'level'); options.level = 1; end
level = 2^(options.level-1);    % resampling factor

if level ~= 1
    % resample dataset code
end

if ~isfield(options, 'replaceDatasetSwitch'); options.replaceDatasetSwitch = 0; end % defines whether the dataset should be replaced, in a situation when width/height mismatch
if ~isfield(options, 'keepModel'); options.keepModel = 1; end % defines whether the model/selection layers should not be resized to the size of the image

blockModeSwitchLocal = 0;
if isfield(options, 'y') || isfield(options, 'x') || isfield(options, 'z') || (isfield(options, 't') && obj.time > 1)
    blockModeSwitchLocal = 1;
elseif isfield(options, 't') && obj.time == 1     % override the blockmode switch for 4D datasets
    blockModeSwitchLocal = 0;
end

if strcmp(type,'image')
    if isnan(col_channel); col_channel=obj.slices{3}; end
    if col_channel(1) == 0; col_channel = 1:obj.colors; end
    
    if (size(dataset,1) ~= size(obj.img{1}, 1) ...
            || size(dataset,2) ~= size(obj.img{1},2) ...
            || size(dataset,4) ~= size(obj.img{1},4) || ...
            ~strcmp(class(dataset), obj.meta('imgClass'))) && blockModeSwitchLocal == 0
        options.replaceDatasetSwitch = 1;
    end
end

if islogical(dataset(1)); dataset = uint8(dataset); end

if blockModeSwitchLocal == 1
    % get coordinates of the shown block for the original dataset in
    % the yx dimension
    Xlim = [1 obj.width];
    Ylim = [1 obj.height];
    Zlim = [1 obj.depth];
    Tlim = [1 obj.time];
    
    % deal with cases when options.x/y/z == 0 
    if isfield(options, 'x') && options.x(1) == 0; options = rmfield(options, 'x'); end
    if isfield(options, 'y') && options.y(1) == 0; options = rmfield(options, 'y'); end
    if isfield(options, 'z') && options.z(1) == 0; options = rmfield(options, 'z'); end
    if isfield(options, 't') && options.t(1) == 0; options = rmfield(options, 't'); end
    
    if orient==1     % xz
        if isfield(options, 'x'); Zlim = [options.x(1) options.x(numel(options.x))]; end
        if isfield(options, 'z'); Ylim = [options.z(1) options.z(numel(options.z))]; end
        if isfield(options, 'y'); Xlim = [options.y(1) options.y(numel(options.y))]; end
    elseif orient==2 % yz
        if isfield(options, 'x'); Zlim = [options.x(1) options.x(numel(options.x))]; end
        if isfield(options, 'y'); Ylim = [options.y(1) options.y(numel(options.y))]; end
        if isfield(options, 'z'); Xlim = [options.z(1) options.z(numel(options.z))]; end
    elseif orient==4 % yx
        if isfield(options, 'x'); Xlim = [options.x(1) options.x(numel(options.x))]; end
        if isfield(options, 'y'); Ylim = [options.y(1) options.y(numel(options.y))]; end
        if isfield(options, 'z'); Zlim = [options.z(1) options.z(numel(options.z))]; end
    end
    if isfield(options, 't')
        if numel(options.t) == 1; options.t = [options.t options.t]; end
        Tlim = options.t; 
    end
    
    % make sure that the coordinates within the dimensions of the dataset
    Xlim = [max([Xlim(1) 1]) min([Xlim(2) obj.width])];
    Ylim = [max([Ylim(1) 1]) min([Ylim(2) obj.height])];
    Zlim = [max([Zlim(1) 1]) min([Zlim(2) obj.depth])];
    Tlim = [max([Tlim(1) 1]) min([Tlim(2) obj.time])];
end

if obj.modelType > 63  % uint8/int8 type of the model
    if blockModeSwitchLocal == 0     % set the full size dataset
        if strcmp(type,'image')
            if options.replaceDatasetSwitch
                if orient == 4 % yx
                    obj.img{1} = dataset;
                elseif orient==1    % xz; get permuted dataset
                    obj.img{1} = permute(dataset, [4 1 3 2 5]);
                elseif orient==2    % yz; get permuted dataset
                    obj.img{1} = permute(dataset, [1 4 3 2 5]);
                end
                
                % create a model layer for selection
                if obj.Virtual.virtual == 0
                    if obj.disableSelection == 0 && options.keepModel == 0
                        obj.selection{1} = zeros([size(obj.img{1},1), size(obj.img{1},2), size(obj.img{1},4), size(obj.img{1},5)], 'uint8');
                    end
                end
            else
                if orient == 4 % yx
                    obj.img{1}(:,:,col_channel,:,:) = dataset;
                elseif orient==1    % xz; get permuted dataset
                    obj.img{1}(:,:,col_channel,:,:) = permute(dataset ,[4 1 3 2 5]);
                elseif orient==2    % yz; get permuted dataset
                    obj.img{1}(:,:,col_channel,:,:) = permute(dataset,[1 4 3 2 5]);
                end
            end
        elseif strcmp(type,'model')
            if orient == 4 % yx
                if ~isnan(col_channel)     % take only specific object
                    obj.model{1}(obj.model{1} == col_channel) = 0;
                    obj.model{1}(dataset == 1) = col_channel;
                else
                    obj.model{1} = dataset;
                end
            elseif orient==1    % xz; get permuted dataset
                if ~isnan(col_channel)     % take only specific object
                    dataset = permute(dataset ,[3 1 2 4]);
                    obj.model{1}(obj.model{1} == col_channel) = 0;
                    obj.model{1}(dataset == 1) = col_channel;
                else
                    obj.model{1} = permute(dataset ,[3 1 2 4]);
                end
            elseif orient==2    % yz; get permuted dataset
                if ~isnan(col_channel)     % take only specific object
                    dataset = permute(dataset,[1 3 2 4]);
                    obj.model{1}(obj.model{1} == col_channel) = 0;
                    obj.model{1}(dataset == 1) = col_channel;
                else
                    obj.model{1} = permute(dataset,[1 3 2 4]);
                end
            end
            obj.modelExist = 1;
        elseif strcmp(type,'mask')
            if orient == 4 % yx
                obj.maskImg{1} = dataset;
            elseif orient==1    % xz; get permuted dataset
                obj.maskImg{1} = permute(dataset ,[3 1 2 4]);
            elseif orient==2    % yz; get permuted dataset
                obj.maskImg{1} = permute(dataset,[1 3 2 4]);
            end
            obj.maskExist = 1;
        elseif strcmp(type,'selection')
            if orient == 4 % yx
                obj.selection{1} = dataset;
            elseif orient==1    % xz; get permuted dataset
                obj.selection{1} = permute(dataset ,[3 1 2 4]);
            elseif orient==2    % yz; get permuted dataset
                obj.selection{1} = permute(dataset,[1 3 2 4]);
            end
        end
    else    % set the shown block
        if strcmp(type,'image')
            if orient==1     % xz
                dataset = permute(dataset,[4 1 3 2 5]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 4 3 2 5]);
            end
            obj.img{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),col_channel,Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = dataset;
        elseif strcmp(type,'model')
            if orient==1     % xz
                dataset = permute(dataset,[3 1 2 4]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 3 2 4]);
            end
            if ~isnan(col_channel)     % take only specific object
                currentDataset = obj.model{1}(Zlim(1):Zlim(2),max([Ylim(1) 1]):min([Ylim(2) obj.width]),max([Xlim(1) 1]):min([Xlim(2) obj.no_stacks]));
                currentDataset(currentDataset == col_channel) = 0;
                currentDataset(dataset == 1) = col_channel;
                dataset = currentDataset;
            end
            obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = dataset;
        elseif strcmp(type,'mask')
            if obj.maskExist == 0  % create maskImg
                obj.maskImg{1} = zeros(size(obj.img{1},1),size(obj.img{1},2),size(obj.img{1},4),size(obj.img{1},5),'uint8');
            end
            if orient==1     % xz
                dataset = permute(dataset,[3 1 2 4]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 3 2 4]);
            end
            obj.maskImg{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = dataset;
            obj.maskExist = 1;
        elseif strcmp(type,'selection')
            if orient==1     % xz
                dataset = permute(dataset,[3 1 2 4]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 3 2 4]);
            end
            obj.selection{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = dataset;
        end
    end
else        % ************ uint6 model type
    % the following part of the code is broken into two sections because it is faster
    if blockModeSwitchLocal == 0     % set the full size dataset
        if strcmp(type,'image')
            if options.replaceDatasetSwitch
                if orient == 4      % yx
                    obj.img{1} = dataset;
                elseif orient==1    % xz; get permuted dataset
                    obj.img{1} = permute(dataset, [4 1 3 2 5]);
                elseif orient==2    % yz; get permuted dataset
                    obj.img{1} = permute(dataset, [1 4 3 2 5]);
                end
                
                % create a model layer for selection
                if obj.Virtual.virtual == 0
                    if obj.disableSelection == 0 && options.keepModel == 0
                        obj.model{1} = zeros([size(obj.img{1},1), size(obj.img{1},2), size(obj.img{1},4), size(obj.img{1},5)], 'uint8');
                    end
                end
            else
                if orient == 4 % yx
                    obj.img{1}(:,:,col_channel,:,:) = dataset;
                elseif orient==1    % xz; get permuted dataset
                    obj.img{1}(:,:,col_channel,:,:) = permute(dataset ,[4 1 3 2 5]);
                elseif orient==2    % yz; get permuted dataset
                    obj.img{1}(:,:,col_channel,:,:) = permute(dataset,[1 4 3 2 5]);
                end
            end
        else    % set all other layers: model, mask, selection
            % permute dataset if needed
            if orient==1     % xz
                dataset = permute(dataset ,[3 1 2 4]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 3 2 4]);
            end
            
            switch type
                case 'model'
                    if ~isnan(col_channel)     % set only specific object
                        obj.model{1}(bitand(obj.model{1}, col_channel)==col_channel) = bitand(obj.model{1}(bitand(obj.model{1}, col_channel)==col_channel), 192);  % 192 = 11000000, remove Material from the model
                        obj.model{1}(dataset==1) = bitand(obj.model{1}(dataset==1), 192);    % empty positions for the new material
                        obj.model{1}(dataset==1) = bitor(obj.model{1}(dataset==1), col_channel);    % update new material
                    else
                        obj.model{1} = bitand(obj.model{1}, 192); % clear current model
                        obj.model{1} = bitor(obj.model{1}, dataset);
                    end
                case 'mask'
                    obj.model{1} = bitset(obj.model{1}, 7, 0);    % clear current mask
                    obj.model{1} = bitor(obj.model{1}, dataset*64);
                    obj.maskExist = 1;
                case 'selection'
                    obj.model{1} = bitset(obj.model{1}, 8, 0);    % clear existing selection
                    obj.model{1} = bitor(obj.model{1}, dataset*128);
                case 'everything'
                    obj.model{1} = dataset;
            end
        end
    else        % get the shown block
        if strcmp(type,'image')
            if orient==1     % permute from xz
                dataset = permute(dataset,[4 1 3 2 5]);
            elseif orient==2 % permute from yz
                dataset = permute(dataset,[1 4 3 2 5]);
            end
            obj.img{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),col_channel,Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = dataset;
        else
            if orient==1     % permute to xz
                dataset = permute(dataset,[3 1 2 4]);
            elseif orient==2 % permute to yz
                dataset = permute(dataset,[1 3 2 4]);
            end
            
            switch type
                case 'model'
                    if ~isnan(col_channel)     % take only specific object
                        currentDataset = obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
                        currentDataset(bitand(currentDataset, col_channel)==col_channel) = bitand(currentDataset(bitand(currentDataset, col_channel)==col_channel), 192);  % 192 = 11000000, remove Material from the model
                        currentDataset(dataset==1) = bitor(currentDataset(dataset==1), col_channel);
                        obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = currentDataset;
                    else
                        currentDataset = bitand(obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)), 192); % clear current model    
                        obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = bitor(currentDataset, dataset);
                    end
                case 'mask'
                    currentDataset = obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
                    currentDataset = bitset(currentDataset,7,0);    % clear mask
                    currentDataset = bitor(currentDataset, dataset*64);
                    obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = currentDataset;
                    obj.maskExist = 1;
                case 'selection'
                    currentDataset = obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
                    currentDataset = bitset(currentDataset,8,0);    % clear selection
                    currentDataset = bitor(currentDataset, dataset*128);
                    obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = currentDataset;
                case 'everything'
                    obj.model{1}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2)) = dataset;
            end
        end
    end
end

% update obj.height, obj.width, etc
if strcmp(type,'image') && (blockModeSwitchLocal == 0 || options.replaceDatasetSwitch)
    % update metadata  
    obj.meta('Height') = size(obj.img{1}, 1);
    obj.meta('Width') = size(obj.img{1}, 2);
    obj.meta('Colors') = size(obj.img{1}, 3);
    obj.meta('Depth') = size(obj.img{1}, 4);
    obj.meta('Time') = size(obj.img{1}, 5);
    
    % update things based on changed colors
    if obj.meta('Colors') ~= obj.colors
        if obj.meta('Colors') > 1
            obj.meta('ColorType') = 'truecolor';
        else
            obj.meta('ColorType') = 'grayscale';
        end
        obj.colors = size(obj.img{1}, 3);
        % add colors to the LUT color table and update it
        if obj.colors > size(obj.lutColors,1)
            for i=size(obj.lutColors,1)+1:obj.colors
                obj.lutColors(i,:) = [rand(1) rand(1) rand(1)];
            end
        end
        obj.updateDisplayParameters();
    end
    
    if ~strcmp(obj.meta('imgClass'), class(obj.img{1}(1)))
        obj.meta('imgClass') = class(obj.img{1}(1));    % get string with class name for images
        obj.meta('MaxInt') = double(intmax(obj.meta('imgClass')));
        obj.updateDisplayParameters();
    end
    
    % update class variables
    obj.height = size(obj.img{1}, 1);
    obj.width = size(obj.img{1}, 2);
    obj.depth = size(obj.img{1}, 4);
    obj.time = size(obj.img{1}, 5);   
    obj.dim_yxczt = [obj.height, obj.width, obj.colors, obj.depth, obj.time];
    
    % update obj.slices
    currSlices = obj.slices;
    obj.slices{1} = [1, obj.height];
    obj.slices{2} = [1, obj.width];
    obj.slices{3} = 1:obj.colors;
    obj.slices{4} = [1, obj.depth];
    obj.slices{5} = [1, 1];
    % update service metadata and class variables
    %obj.updateServiceMetadata(obj.meta);
    
    if currSlices{obj.orientation}(1) > obj.dim_yxczt(obj.orientation)
        obj.slices{obj.orientation} = [obj.dim_yxczt(obj.orientation), obj.dim_yxczt(obj.orientation)];
    else
        obj.slices{obj.orientation} = currSlices{obj.orientation};
    end
    
    obj.current_yxz(1) = min([obj.current_yxz(1) obj.height]);
    obj.current_yxz(2) = min([obj.current_yxz(2) obj.width]);
    obj.current_yxz(3) = min([obj.current_yxz(3) obj.depth]);
end
if strcmp(type, 'model'); obj.modelExist = 1; end
result = 1;