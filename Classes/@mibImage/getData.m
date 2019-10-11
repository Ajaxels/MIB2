function dataset = getData(obj, type, orient, col_channel, options, custom_img) % get complete 4D dataset
% function dataset = getData(obj, type, orient, col_channel, options, custom_img)
% Get dataset from mibImage class
%
% Parameters:
% type: type of the dataset to retrieve, 'image', 'model','mask', 'selection', or 'everything' ('model','mask' and 'selection' for imageData.model_type==''uint6'' only)
% orient: [@em optional], can be @em NaN
% @li when @b 0 (@b default) returns the dataset transposed to the current orientation (obj.orientation)
% @li when @b 1 returns transposed dataset to the zx configuration: [y,x,c,z,t] -> [x,z,c,y,t]
% @li when @b 2 returns transposed dataset to the zy configuration: [y,x,c,z,t] -> [y,z,c,y,t]
% @li when @b 3 not used
% @li when @b 4 returns original dataset to the yx configuration: [y,x,c,z,t]
% @li when @b 5 not used
% col_channel: [@em optional],
% @li when @b type is 'image', @b col_channel is a vector with color numbers to take, when @b NaN [@e default] take the colors
% selected in the imageData.slices{3} variable, when @b 0 - take all colors of the dataset.
% @li when @b type is 'model' @b col_channel may be @em NaN - to take all materials of the model or an integer to take specific material. In the later case the selected material will have index = 1.
% options: [@em optional], a structure with extra parameters
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take
% after transpose for level=1, when @b 0 takes 1:obj.height; can be a single number
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take
% after transpose for level=1, when @b 0 takes 1:obj.width; can be a single number
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take
% after transpose, when @b 0 takes 1:obj.depth; can be a single number
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, when @b 0 takes 1:obj.time; can be a single number
% @li .level -> [@em optional], index of image level from the image pyramid
% custom_img: get dataset from a provided custom image stack, not implemented
%
% Return values:
% dataset: 4D or 5D stack. For the 'image' type: [1:height, 1:width, 1:colors, 1:depth, 1:time]; for all other types: [1:height, 1:width, 1:thickness, 1:time]

%|
% @b Examples:
% @code dataset = obj.getData('image');      // get the complete dataset in the shown orientation @endcode
% @code dataset = obj.getData('image', 4, 2); // get complete dataset in the XY orientation with only second color channel @endcode

% Copyright (C) 06.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 6; custom_img = NaN; end
if nargin < 5; options=struct(); end
if nargin < 4; col_channel = NaN; end
if nargin < 3; orient=obj.orientation; end

% setting default values for the orientation
if orient == 0 || isnan(orient); orient=obj.orientation; end

if ~isfield(options, 'level'); options.level = 1; end
level = 2^(options.level-1);    % resampling factor

if obj.Virtual.virtual == 1
    % get virtual dataset
    dataset = obj.getDataVirt(type, orient, col_channel, options);
    return;
end

blockModeSwitchLocal = 0;
if isfield(options, 'y') || isfield(options, 'x') || isfield(options, 'z') || (isfield(options, 't') && obj.time > 1)
    blockModeSwitchLocal = 1;
elseif isfield(options, 't') && obj.time == 1     % override the blockmode switch for 3D datasets
    blockModeSwitchLocal = 0;
end

if strcmp(type,'image')
    if isnan(col_channel); col_channel=obj.slices{3}; end
    if col_channel(1) == 0;  col_channel = 1:obj.colors; end
end

if blockModeSwitchLocal == 1
    % get coordinates of the shown block for the original dataset in
    % the yx dimension
    Xlim = [1 floor(obj.width/level)];
    Ylim = [1 floor(obj.height/level)];
    Zlim = [1 obj.depth];
    Tlim = [1 obj.time];
    
    % deal with cases when options.x/y/z == 0 
    if isfield(options, 'x') && options.x(1) == 0; options = rmfield(options, 'x'); end
    if isfield(options, 'y') && options.y(1) == 0; options = rmfield(options, 'y'); end
    if isfield(options, 'z') && options.z(1) == 0; options = rmfield(options, 'z'); end
    if isfield(options, 't') && options.t(1) == 0; options = rmfield(options, 't'); end
    
    if orient==1     % xz
        if isfield(options, 'x'); Zlim = [options.x(1) options.x(numel(options.x))]; end
        if isfield(options, 'z'); Ylim = floor([options.z(1) options.z(numel(options.z))]/level); end
        if isfield(options, 'y'); Xlim = floor([options.y(1) options.y(numel(options.y))]/level); end
    elseif orient==2 % yz
        if isfield(options, 'x'); Zlim = [options.x(1) options.x(numel(options.x))]; end
        if isfield(options, 'y'); Ylim = floor([options.y(1) options.y(numel(options.y))]/level); end
        if isfield(options, 'z'); Xlim = floor([options.z(1) options.z(numel(options.z))]/level); end
    elseif orient==4 % yx
        if isfield(options, 'x'); Xlim = floor([options.x(1) options.x(numel(options.x))]/level); end
        if isfield(options, 'y'); Ylim = floor([options.y(1) options.y(numel(options.y))]/level); end
        if isfield(options, 'z'); Zlim = [options.z(1) options.z(numel(options.z))]; end
    end
    if isfield(options, 't')
        if numel(options.t) == 1; options.t = [options.t options.t]; end
        Tlim = options.t; 
    end
    
    % make sure that the coordinates within the dimensions of the dataset
    Xlim = [max([Xlim(1) 1]) min([Xlim(2) floor(obj.width/level)])];
    Ylim = [max([Ylim(1) 1]) min([Ylim(2) floor(obj.height/level)])];
    Zlim = [max([Zlim(1) 1]) min([Zlim(2) obj.depth])];
    Tlim = [max([Tlim(1) 1]) min([Tlim(2) obj.time])];
end

if obj.modelType > 63
    if blockModeSwitchLocal == 0     % get the full size dataset
        if strcmp(type,'image')
            if orient == 4 % yx
                dataset = obj.img{level}(:,:,col_channel,:,:);
            elseif orient==1    % xz; get permuted dataset
                dataset = permute(obj.img{level}(:,:,col_channel,:),[2 4 3 1 5]);
            elseif orient==2    % yz; get permuted dataset
                dataset = permute(obj.img{level}(:,:,col_channel,:),[1 4 3 2 5]);
            end
        elseif strcmp(type,'model')
            if ~isnan(col_channel)     % take only specific object
                %dataset = zeros(size(obj.model{level}), class(obj.model{level}));   %#ok<*ZEROLIKE>
                dataset = zeros(size(obj.model{level}), 'uint8');   % need to have this in uint8, otherwise bitand operations won't work %#ok<*ZEROLIKE>
                dataset(obj.model{level} == col_channel) = 1;
            else
                dataset = obj.model{level};
            end
            if orient==1    % xz; get permuted dataset
                dataset = permute(dataset{level},[2 3 1 4]);
            elseif orient==2    % yz; get permuted dataset
                dataset = permute(dataset{level},[1 3 2 4]);
            end
        elseif strcmp(type,'mask')
            if orient == 4 % yx
                dataset = obj.maskImg{level};
            elseif orient==1    % xz; get permuted dataset
                dataset = permute(obj.maskImg{level},[2 3 1 4]);
            elseif orient==2    % yz; get permuted dataset
                dataset = permute(obj.maskImg{level},[1 3 2 4]);
            end
        elseif strcmp(type,'selection')
            if orient == 4 % yx
                dataset = obj.selection{level};
            elseif orient==1    % xz; get permuted dataset
                dataset = permute(obj.selection{level},[2 3 1 4]);
            elseif orient==2    % yz; get permuted dataset
                dataset = permute(obj.selection{level},[1 3 2 4]);
            end
        end
    else    % get sub block
        if strcmp(type,'image')
            
            dataset = obj.img{level}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),col_channel,Zlim(1):Zlim(2),Tlim(1):Tlim(2));
            if orient==1     % permute to xz
                dataset = permute(dataset,[2 4 3 1 5]);
            elseif orient==2 % permute to yz
                dataset = permute(dataset,[1 4 3 2 5]);
            end
            
        elseif strcmp(type,'model')
            dataset = obj.model{level}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
            if orient==1     % xz
                dataset = permute(dataset,[2 3 1 4]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 3 2 4]);
            end
            if ~isnan(col_channel)     % take only specific object
                dataset2 = zeros(size(dataset), class(dataset));
                dataset2(dataset == col_channel) = 1;
                dataset = dataset2;
                clear dataset2;
            end
        elseif strcmp(type,'mask')
            dataset = obj.maskImg{level}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
            if orient==1     % xz
                dataset = permute(dataset,[2 3 1 4]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 3 2 4]);
            end
        elseif strcmp(type,'selection')
            dataset = obj.selection{level}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
            if orient==1     % xz
                dataset = permute(dataset,[2 3 1 4]);
            elseif orient==2 % yz
                dataset = permute(dataset,[1 3 2 4]);
            end
        end
    end
else            % ************ uint6 model type with 63 materials
    % the following part of the code is broken into two sections because it is faster
    if blockModeSwitchLocal == 0     % get the full size dataset
        if strcmp(type,'image')
            
            dataset = obj.img{level}(:,:,col_channel,:,:);
            if orient==1    % xz; get permuted dataset
                dataset = permute(dataset,[2 4 3 1 5]);
            elseif orient==2    % yz; get permuted dataset
                dataset = permute(dataset,[1 4 3 2 5]);
            end
            
        else
            if orient == 4 % yx
                dataset = obj.model{level};
            elseif orient==1     % xz
                dataset = permute(obj.model{level},[2 3 1 4]);
            elseif orient==2 % yz
                dataset = permute(obj.model{level},[1 3 2 4]);
            end
            switch type
                case 'model'
                    if ~isnan(col_channel)     % take only specific object
                        dataset = uint8(bitand(dataset, 63)==col_channel(1));
                    else
                        dataset = bitand(dataset, 63);     % get all model objects
                    end
                case 'mask'
                    dataset = bitand(dataset, 64)/64;  % 64 = 01000000
                case 'selection'
                    dataset = bitand(dataset, 128)/128;  % 128 = 10000000
                case 'everything'
                    % do nothing
            end
        end
    else        % get the shown block
        if strcmp(type,'image')
            
            dataset = obj.img{level}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),col_channel,Zlim(1):Zlim(2),Tlim(1):Tlim(2));
            if orient==1     % permute to xz
                dataset = permute(dataset,[2 4 3 1 5]);
            elseif orient==2 % permute to yz
                dataset = permute(dataset,[1 4 3 2 5]);
            end
            
        else
            dataset = obj.model{level}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
            if orient==1     % permute to xz
                dataset = permute(dataset,[2 3 1 4]);
            elseif orient==2 % permute to yz
                dataset = permute(dataset,[1 3 2 4]);
            end
            
            switch type
                case 'model'
                    if ~isnan(col_channel)     % take only specific object
                        dataset = uint8(bitand(dataset, 63)==col_channel(1));
                    else
                        dataset = bitand(dataset, 63);     % get all model objects
                    end
                case 'mask'
                    dataset = bitand(dataset, 64)/64;  % 64 = 01000000
                case 'selection'
                    dataset = bitand(dataset, 128)/128;  % 128 = 10000000
                case 'everything'
                    % do nothing
            end
        end
    end
end
end