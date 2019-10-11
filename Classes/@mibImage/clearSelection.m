function clearSelection(obj, y, x, z, t, blockModeSwitch)
% function clearSelection(obj, y, x, z, t, blockModeSwitch)
% Clear the 'Selection' layer. It is also possible to specify the area where the Selection layer should be cleared.
%
% Parameters:
% y: [@em optional], can be @b NaN, a vector of Y for example [1:mibImage.height] or [minY, maxY]; or a string with the mode ('2D', '3D', '4D') 
% x: [@em optional], can be @b NaN, a vector of X, for example [1:mibImage.width] or [minX, maxX]
% z: [@em optional] a vector of z-values, for example [1:mibImage.depth] or [minZ, maxZ]
% t: [@em optional] a vector of t-values, for example [1:mibImage.time] or [minT, maxT]
% blockModeSwitch: [@em optional] a switch use (1) or not (0) the blockMode
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.clearSelection(); // call from mibController, clear the Selection layer completely @endcode
% @code obj.mibModel.I{obj.mibModel.Id}.clearSelection(1:imageData.y, 1:imageData.x, 1:3); //  call from mibController, clear the Selection layer only in 3 first slices  @endcode

% Copyright (C) 18.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

if nargin < 6; blockModeSwitch = 0; end
if nargin < 5; t = NaN; end
if nargin < 4; z = NaN; end
if nargin < 3; x = NaN; end
if nargin < 2; y = NaN; end

if isnan(t(1))
    t = 1:obj.time; 
elseif numel(t) == 2   % t = [minT, maxT] format
    t = max([1 t(1)]):min([t(2) obj.time]); 
end
if isnan(z(1))
    z = 1:obj.depth; 
elseif numel(z) == 2    % z = [minZ, maxZ] format
    z = max([1 z(1)]):min([z(2) obj.depth]); 
end
if isnan(x(1))
    x = 1:obj.width; 
elseif numel(x) == 2    % x = [minX, maxX] format
    x = max([1 x(1)]):min([x(2) obj.width]); 
end
if isnan(y(1))
    y = 1:obj.height; 
elseif numel(y) == 2  && ~ischar(y)   % y = [minY, maxY] format
    y = max([1 y(1)]):min([y(2) obj.height]); 
end

if ischar(y)
    getDataOptions.blockModeSwitch = blockModeSwitch;
    [h, w, ~, d, t] = obj.getDatasetDimensions('image', NaN, NaN, getDataOptions);
    if blockModeSwitch == 1
        getDataOptions.x = ceil(obj.axesX);
        getDataOptions.y = ceil(obj.axesY);
    end
    switch y
        case '2D'
            img = zeros([h, w], 'uint8');
            getDataOptions.z = [obj.slices{obj.orientation}(1) obj.slices{obj.orientation}(1)];
            getDataOptions.t = [obj.slices{5}(1) obj.slices{5}(1)];
            obj.setData('selection', img, NaN, NaN, getDataOptions);
        case '3D'
            img = zeros([h, w, d], 'uint8');
            getDataOptions.t = [obj.slices{5}(1) obj.slices{5}(1)];
            obj.setData('selection', img, NaN, NaN, getDataOptions);
        case '4D'
            img = zeros([h,w,d,t], 'uint8');
            obj.setData('selection', img);
    end
else
    if obj.modelType ~= 63
        if nargin < 2
            obj.selection{1} = NaN;
            obj.selection{1} = zeros([obj.height, obj.width, obj.depth, obj.time], 'uint8');
        else
            obj.selection{1}(y, x, z, t) = 0;
        end
    else
        if isnan(obj.model{1}(1)); return; end    % selection is disabled
        if nargin < 2
            obj.model{1} = bitset(obj.model{1}, 8, 0);
        else
            obj.model{1}(y, x, z, t) = bitset(obj.model{1}(y, x, z, t), 8, 0);
        end
    end
end
end