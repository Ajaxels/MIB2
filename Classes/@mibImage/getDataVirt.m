function dataset = getDataVirt(obj, type, orient, col_channel, options, custom_img) % get complete 4D dataset
% function dataset = getDataVirt(obj, type, orient, col_channel, options, custom_img)
% Get virtual dataset from mibImage class
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
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take after transpose for level=1, height
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take after transpose for level=1, width
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take after transpose, depth
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, time
% @li .level -> [@em optional], index of image level from the image pyramid
% @li .showWaitbar -> [@em optional], show or not the waitbar, default show the waitbar for Z-stacks and T-series
% custom_img: get dataset from a provided custom image stack, not implemented
%
% Return values:
% dataset: 4D or 5D stack. For the 'image' type: [1:height, 1:width, 1:colors, 1:depth, 1:time]; for all other types: [1:height, 1:width, 1:thickness, 1:time]

%|
% @b Examples:
% @code dataset = obj.getDataVirt('image');      // get the complete dataset in the shown orientation @endcode
% @code dataset = obj.getDataVirt('image', 4, 2); // get complete dataset in the XY orientation with only second color channel @endcode

% Copyright (C) 16.06.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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

showWaitbar = 0;    % do not show the waitbar, modified below

% setting default values for the orientation
if orient == 0 || isnan(orient); orient=obj.orientation; end

if ~isfield(options, 'level'); options.level = 1; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = []; end

level = 2^(options.level-1);    % resampling factor

if strcmp(type,'image')
    if isnan(col_channel); col_channel=obj.slices{3}; end
    if col_channel(1) == 0;  col_channel = 1:obj.colors; end
end

% get coordinates of the shown block for the original dataset in
% the yx dimension
Xlim = [1 floor(obj.width/level)];
Ylim = [1 floor(obj.height/level)];
Zlim = [1 obj.depth];
Tlim = [1 obj.time];

if orient==1     % xz
    if isfield(options, 'x'); Zlim = options.x(1,:); end
    if isfield(options, 'z'); Ylim = floor(options.z(1,:)/level); end
    if isfield(options, 'y'); Xlim = floor(options.y(1,:)/level); end
elseif orient==2 % yz
    if isfield(options, 'x'); Zlim = options.x(1,:); end
    if isfield(options, 'y'); Ylim = floor(options.y(1,:)/level); end
    if isfield(options, 'z'); Xlim = floor(options.z(1,:)/level); end
elseif orient==4 % yx
    if isfield(options, 'x'); Xlim = floor(options.x(1,:)/level); end
    if isfield(options, 'y'); Ylim = floor(options.y(1,:)/level); end
    if isfield(options, 'z'); Zlim = options.z(1,:); end
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

if isempty(options.showWaitbar)
    if Tlim(2)-Tlim(1) > 0 || Zlim(2)-Zlim(1) > 0
        wb = waitbar(0, sprintf('Loading the dataset\nPlease wait...'));
        showWaitbar = 1;
    end
elseif options.showWaitbar == 1
    wb = waitbar(0, sprintf('Loading the dataset\nPlease wait...'));
    showWaitbar = 1;
end

if strcmp(type,'image')
    readerId = obj.Virtual.readerId(Zlim(1):Zlim(2));
    
    % won't get stacks of images, when the images were picked using
    % different readers: for example, 'bioformats' + 'matlab.hdf5'
    if numel(readerId) > 1
        if numel(unique(obj.Virtual.objectType(readerId))) > 1
            errordlg('Image files were selected using multiple readers, it is not yet possible to combine such files', 'Multiple readers');
            return;
        end
    end
    
    %         planeId = zeros([numel(readerId), 1]);
    %         for i=1:numel(readerId)
    %             planeId(i) = Zlim(1) + i - 1 - sum(obj.Virtual.slicesPerFile(1:readerId(i)-1));
    %         end
    
    switch obj.Virtual.objectType{readerId(1)}
        %             case 'amiramesh'
        %                 AmiraOptions = struct;
        %                 AmiraOptions.classType = {obj.meta('imgClass')};
        %                 AmiraOptions.width = obj.width;
        %                 AmiraOptions.height = obj.height;
        %                 AmiraOptions.depth = obj.depth;
        %                 AmiraOptions.colors = obj.colors;
        %
        %                 for colCh = col_channel
        %                     dataset(:,:,colCh) = amiraMeshSlice2bitmap(obj.img{readerId}, planeId, Xlim(1), Ylim(1), Xlim(2), Ylim(2), AmiraOptions);
        %                 end
        case {'matlab.hdf5', 'hdf5_image'}
            dataset = zeros([Ylim(2)-Ylim(1)+1, Xlim(2)-Xlim(1)+1, obj.colors, Zlim(2)-Zlim(1)+1, Tlim(2)-Tlim(1)+1], obj.meta('imgClass'));
            [uniqueVal, uniquePos, ~] = unique(readerId);
            uniquePos(end+1) = Zlim(2)-Zlim(1)+2;
            readerId = uniqueVal;
            
            for indexVal = 1:numel(uniqueVal)
                z2Out = uniquePos(indexVal+1) - 1;  % get z2 index of the output dataset
                z1Out = z2Out - (uniquePos(indexVal+1) - uniquePos(indexVal)) + 1;  % get z1 index of the output dataset
                
                if indexVal == 1
                    z1In = Zlim(1) - sum(obj.Virtual.slicesPerFile(1:readerId(indexVal)-1));  % find index of the element from which to take pixels
                else
                    z1In = 1;   % take from the 1st element
                end
                zIn_noPoints = z2Out-z1Out+1;   % get number of points to take
                
                dataset(:,:,:,z1Out:z2Out, :) = h5read(obj.img{readerId(indexVal)}, obj.Virtual.seriesName{readerId(indexVal)}, ...
                    [Ylim(1)            Xlim(1)            1           z1In         Tlim(1)], ...
                    [Ylim(2)-Ylim(1)+1, Xlim(2)-Xlim(1)+1, obj.colors, zIn_noPoints, Tlim(2)-Tlim(1)+1]);
            end
            dataset = dataset(:,:,col_channel,:,:);     % this looks quicker than doing a loop as for bioformats
            
            %                 %h5disp(obj.img{readerId}, obj.Virtual.seriesName{readerId})
            %                 dataset = h5read(obj.img{readerId(1)}, obj.Virtual.seriesName{readerId(1)}, ...
            %                     [Ylim(1) Xlim(1) 1 planeId(1)  Tlim(1)], ...
            %                     [Ylim(2)-Ylim(1)+1, Xlim(2)-Xlim(1)+1, obj.colors, Zlim(2)-Zlim(1)+1, 1]);
            %                 dataset = dataset(:,:,col_channel,:);     % this looks quicker than doing a loop as for bioformats
        case 'bioformats'
            dataset = zeros([Ylim(2)-Ylim(1)+1, Xlim(2)-Xlim(1)+1, numel(col_channel), Zlim(2)-Zlim(1)+1, Tlim(2)-Tlim(1)+1], obj.meta('imgClass'));
            maxT = Tlim(2)-Tlim(1)+1;
            for t=1:maxT
                timepoint = Tlim(1)+t-2;
                for z=1:Zlim(2)-Zlim(1)+1
                    %obj.img{readerId(z)} = loci.formats.Memoizer(bfGetReader(), 0);
                    % obj.img{readerId(z)}.setId(obj.Virtual.filenames{readerId});
                    % obj.img{readerId(z)}.setSeries(obj.Virtual.seriesName{readerId}-1);
                    r = loci.formats.Memoizer(bfGetReader(), 0, java.io.File(obj.BioFormatsMemoizerMemoDir));
                    r.setId(obj.img{readerId(z)});
                    r.setSeries(obj.Virtual.seriesName{readerId(z)}-1);
                    
                    planeId = Zlim(1) + z - 1 - sum(obj.Virtual.slicesPerFile(1:readerId(z)-1));
%                     % update setSeries, for some reasons it does not fixed
%                     % during init of readers
%                     if numel(obj.Virtual.seriesName(readerId)) > 1
%                         obj.img{readerId(z)}.setSeries(obj.Virtual.seriesName{Zlim(1)}-1);
%                     end
                    
                    for colCh = 1:numel(col_channel)
                        iPlane = r.getIndex(planeId - 1, col_channel(colCh) - 1, timepoint) + 1;
                        cPlane = bfGetPlane(r, iPlane, Xlim(1), Ylim(1), Xlim(2)-Xlim(1)+1, Ylim(2)-Ylim(1)+1);
                        if isa(cPlane(1), 'int8')
                            cPlane = int16(cPlane);
                            cPlane(cPlane<0) = cPlane(cPlane<0) + 256;
                            dataset(:,:,colCh,z,t) = cPlane;
                        else
                            dataset(:,:,colCh,z,t) = cPlane;
                        end
                    end
                end
                if showWaitbar; waitbar(t/maxT, wb); end
                r.close();
            end
    end
%     if orient==1     % permute to xz
%         dataset = permute(dataset,[2 3 1 4]);
%     elseif orient==2 % permute to yz
%         dataset = permute(dataset,[1 3 2 4]);
%     end
    
else
    dataset = zeros([Ylim(2)-Ylim(1)+1, Xlim(2)-Xlim(1)+1, numel(col_channel), Zlim(2)-Zlim(1)+1], 'uint8');
    
    %         dataset = obj.model{level}(Ylim(1):Ylim(2),Xlim(1):Xlim(2),Zlim(1):Zlim(2),Tlim(1):Tlim(2));
    %         if orient==1     % permute to xz
    %             dataset = permute(dataset,[2 3 1 4]);
    %         elseif orient==2 % permute to yz
    %             dataset = permute(dataset,[1 3 2 4]);
    %         end
    %
    %         switch type
    %             case 'model'
    %                 if ~isnan(col_channel)     % take only specific object
    %                     dataset = uint8(bitand(dataset, 63)==col_channel(1));
    %                 else
    %                     dataset = bitand(dataset, 63);     % get all model objects
    %                 end
    %             case 'mask'
    %                 dataset = bitand(dataset, 64)/64;  % 64 = 01000000
    %             case 'selection'
    %                 dataset = bitand(dataset, 128)/128;  % 128 = 10000000
    %             case 'everything'
    %                 % do nothing
    %         end
end
if showWaitbar; delete(wb); end

end