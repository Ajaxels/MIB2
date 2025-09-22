% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 03.09.2025

function dataset = getDataZarr(obj, type, orient, col_channel, options)
% function dataset = getDataZarr(obj, type, orient, col_channel, options)
% Read subvolume from a Zarr dataset with optional slicing and type conversion.
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
% @li when @b type is 'model' @b col_channel may be @em NaN - to take all materials of the model or an integer to take specific material. 
% In the later case the selected material will have index = 1.
% options: [@em optional], a structure with extra parameters
% @li .y -> [@em optional], [ymin, ymax] coordinates of the dataset to take
% after transpose for magFactor=1, when @b 0 takes 1:obj.height; can be a single number
% @li .x -> [@em optional], [xmin, xmax] coordinates of the dataset to take
% after transpose for magFactor=1, when @b 0 takes 1:obj.width; can be a single number
% @li .z -> [@em optional], [zmin, zmax] coordinates of the dataset to take
% after transpose, when @b 0 takes 1:obj.depth; can be a single number
% @li .t -> [@em optional], [tmin, tmax] coordinates of the dataset to take after transpose, when @b 0 takes 1:obj.time; can be a single number
% @li .magFactor -> [@em optional], magnification factor for resizing the
% obtained imaged to disired magnification, defined as a ratio of image voxel size at 100% magnification / required voxel size
% @li .pyramidLevel -> [@em optional], level of the pyramid to take, when 1 take
% the full resolution, when 2 - take the second level, etc. This parameter
% has preference over the magFactor

% Return values:
% dataset: 4D or 5D stack. For the 'image' type: [1:height, 1:width, 1:colors, 1:depth, 1:time]; for all other types: [1:height, 1:width, 1:thickness, 1:time]

if nargin < 5; options = struct(); end
if nargin < 4; col_channel = NaN; end
if nargin < 3; orient = obj.orientation; end

% --- Default magnification factor ---
if isfield(options,'pyramidLevel') % get dataset of the desired level
    levelIdx = options.pyramidLevel;
else
    options.pyramidLevel = [];
    if ~isfield(options,'magFactor')
        options.magFactor = obj.magFactor;
    end
    
    % define level of the pyramid to obtain from scale factors at each level of the pyramid
    effectiveScales = obj.pyramid.levelScaleFactors(:, 1);
    differences = abs(effectiveScales - obj.magFactor);
    [~, levelIdx] = min(differences); % index of the downsample pyramid
end

% match desired dimension to the dimension of the dataset
switch orient
    case 1  % xz
        outDimYind = 3; % data Z axis -> Y
        outDimXind = 1; % data Y axis -> X
        outDimZind = 2; % data X axis -> Z
    case 2  % yz
        outDimYind = 1; % data Y axis -> Y
        outDimXind = 3; % data Z axis -> X
        outDimZind = 2; % data X axis -> Z
    case 4 % yx
        outDimYind = 1; % data Y axis -> Y
        outDimXind = 2; % data X axis -> X
        outDimZind = 3; % data Z axis -> Z
    otherwise
        error('Unsupported orientation');
end


% --- Metadata for this level ---
levelSize = obj.pyramid.levelImageSizes(levelIdx, :);   % [y, x, z] for this level
dtype = obj.meta('imgClass');            % e.g., 'uint8'

% --- Use full-resolution size for default ranges ---
fullSize = obj.pyramid.levelImageSizes(1,:);  % [y, x, z]

% --- Ensure slicing fields exist ---
if ~isfield(options,'x') || isempty(options.x)
    options.x = [1, fullSize(outDimXind)];
end
if ~isfield(options,'y') || isempty(options.y)
    options.y = [1, fullSize(outDimYind)];
end
if ~isfield(options,'z') || isempty(options.z)
    options.z = [1, fullSize(outDimZind)];
end
if ~isfield(options,'t') || isempty(options.t)
    options.t = [1, obj.time];
end

% --- Adjust coordinates for orientation ---
% --- Use scale factors to adjust full-resolution coordinates to level ---
sf = obj.pyramid.levelScaleFactors(levelIdx, :);  % [yScale, xScale, zScale]

% calculate coordinates to get for the requreid levelIdx
switch orient
    case 1 % xz
        Xidx = ceil(options.y ./ sf(outDimXind));  % Y axis -> X
        Yidx = ceil(options.z ./ sf(outDimYind));  % Z axis -> Y
        Zidx = ceil(options.x ./ sf(outDimZind));  % X axis -> Z
    case 2 % yz
        Xidx = ceil(options.z ./ sf(outDimXind));  % Z axis -> X
        Yidx = ceil(options.y ./ sf(outDimYind));  % Y axis -> Y
        Zidx = ceil(options.x ./ sf(outDimZind));  % X axis -> Z
    case 4 % yx
        Xidx = ceil(options.x ./ sf(outDimXind)); % X axis -> X
        Yidx = ceil(options.y ./ sf(outDimYind)); % Y axis -> Y
        Zidx = ceil(options.z ./ sf(outDimZind)); % Z axis -> X
end
Tidx = [options.t(1) options.t(2)];

% make sure that the coordinates within the dimensions of the dataset
Xidx = [max([Xidx(1) 1]) min([Xidx(2) obj.pyramid.levelImageSizes(levelIdx, outDimXind)])];
Yidx = [max([Yidx(1) 1]) min([Yidx(2) obj.pyramid.levelImageSizes(levelIdx, outDimYind)])];
Zidx = [max([Zidx(1) 1]) min([Zidx(2) obj.pyramid.levelImageSizes(levelIdx, outDimZind)])];
Tidx = [max([Tidx(1) 1]) min([Tidx(2) obj.time])];

% --- Convert to 0-based values for Python ---
Xlim = Xidx - 1;
Ylim = Yidx - 1;
Zlim = Zidx - 1;
Tlim = Tidx - 1;

% --- Color selection ---
if strcmp(type,'image')
    if isnan(col_channel) 
        Clim = obj.slices{3} - 1;
    elseif col_channel(1) == 0
        Clim = 1:obj.colors; 
    else
        Clim = col_channel;
    end
    Clim = Clim - 1; % convert to python 0-type values
end

% --- Prepare Zarr path ---
zarrPathLevel = sprintf('%s/%s', obj.img{1}, obj.pyramid.levelNames{levelIdx});

% --- Build Python slicing string ---
sliceStr = sprintf("%d:%d, %d:%d, %d:%d, %d:%d, %d:%d", ...
    Tlim(1), Tlim(end)+1, Clim(1), Clim(end)+1, ...
    Zlim(1), Zlim(end)+1, Ylim(1), Ylim(end)+1, Xlim(1), Xlim(end)+1);

% --- Read subvolume using Python ---
block = pyrun([ ...  % sprintf("import zarr, numpy as np"), ...
    sprintf("z = zarr.open('%s')", zarrPathLevel), ...
    sprintf("a = np.array(z[%s], dtype=z.dtype)", sliceStr) ...
    ], "a");

% --- Convert to MATLAB type ---
dataset = cast(block, dtype);
switch orient
    case 1 % xz
        dataset = permute(dataset, [5 3 2 4 1]); % convert to from [t c z y x] to [x,z,c,y,t]
    case 2 % yz
        dataset = permute(dataset, [4 3 2 5 1]); % convert to from [t c z y x] to [y,z,c,x,t]
    case 4 % yx
        dataset = permute(dataset, [4 5 2 3 1]); % convert to from [t c z y x] to [y,x,c,z,t]
end

% since the dataset was taken at the precomputed magnification downsampling value
% it needs to be resized to match the target magnification
if isempty(options.pyramidLevel) % options.pyramidLevel was not provided and magFactor was used instead
    if strcmp(type,'image')
        currentMag = obj.pyramid.levelScaleFactors(levelIdx, 1); % scale factor at current level
        resizeFactor = options.magFactor / currentMag;
    
        if abs(resizeFactor - 1) > 1e-3   % only resize if different
            newY = round(size(dataset,1) / resizeFactor);
            newX = round(size(dataset,2) / resizeFactor);
            resized = zeros(newY, newX, size(dataset,3), size(dataset,4), size(dataset,5), dtype);
    
            for t = 1:size(dataset,5)
                for z = 1:size(dataset,4)
                    for c = 1:size(dataset,3)
                        resized(:,:,c,z,t) = imresize(dataset(:,:,c,z,t), [newY newX], 'nearest');
                    end
                end
            end
            dataset = resized;
        end
    else
        % other types - to be implemented
    end
end
end
