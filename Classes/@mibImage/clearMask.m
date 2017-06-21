function clearMask(obj, height, width, z, t)
% function clearMask(obj, height, width, z)
% Clear the 'Mask' layer. It is also possible to specify
% the area where the 'Mask' layer should be cleared.
%
% Parameters:
% height: [@em optional] vector of heights, for example [1:imageData.height] or 0 - to initialize space for the new Mask
% width: [@em optional] vector of width, for example [1:imageData.width]
% z: [@em optional] vector of z-values, for example [1:imageData.no_stacks]
% t: [@em optional] vector of t-values, for example [1:imageData.time]
%
% Return values:
%

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.clearMask();  // call from mibController; clear the mask layer @endcode


% Copyright (C) 18.01.2017, Ilya Belevich (ilya.belevich @ helsinki.fi)
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 5; t = 1:obj.time; end;
if nargin < 4; z = 1:obj.depth; end;
if nargin < 3; width = 1:obj.width; end;

if obj.modelType == 63  % 63 materials model type
    if isnan(obj.model{1}(1)); return; end;    % selection is disabled
    if nargin < 2  % clear whole Mask
        obj.model{1} = bitset(obj.model{1}, 7, 0);
    else % clear part of the Mask
        if height == 0
            obj.model{1} = bitset(obj.model{1}, 7, 0);
            obj.maskExist = 1;
        else
            obj.model{1}(height,width,z,:) = bitset(obj.model{1}(height,width,z,t), 7, 0);
        end
    end
else                                % 255 materials model type
    if nargin < 2 % clear whole Mask
        obj.maskImg{1} = NaN;
        %obj.maskImg = zeros(size(obj.img,1),size(obj.img,2),size(obj.img,4),'uint8');
    else    % clear part of the Mask
        if height == 0
            obj.maskImg{1} = zeros(size(obj.selection{1}),'uint8');
            obj.maskExist = 1;
        else
            obj.maskImg{1}(height, width, z, t) = 0;
        end
    end
end

if nargin < 2  % extra things after clearing the whole Mask
    obj.maskExist = 0;
    [pathstr, fileName] = fileparts(obj.meta('Filename'));
    obj.maskImgFilename = fullfile(pathstr, ['Mask_' fileName '.mask']);
end

end