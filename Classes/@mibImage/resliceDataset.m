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
% Date: 25.03.2023

function result = resliceDataset(obj, sliceNumbers, orient, options)
% function result = resliceDataset(obj, sliceNumbers, orient, options)
% stride reslicing the dataset so that the selected slices are kept and all others are removed 
%
% Parameters:
% sliceNumbers: array of slice numbers to keep, can be a range in MATLAB
% format as 1:10:end to keep each 10th slice
% orient: [@em optional], can be @em NaN (current orientation)
% @li when @b 0 (@b default) reslice the the current orientation (obj.orientation)
% @li when @b 1 reslice the zx configuration: [x,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 2 reslice the zy configuration: [y,z,c,y,t] -> [y,x,c,z,t]
% @li when @b 3 not used
% @li when @b 4 reslice the yx configuration: [y,x,c,z,t]
% @li when @b 5 not implemented
% options: an optional structure with additional paramters
%   .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
% Return values:
% result: result of the function, @b 0 fail, @b 1 success

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.resliceDataset('1:10:end', 0); // call from mibController; keep each 10th slice of the dataset @endcode

% Updates
% 

if nargin < 4; options = struct; end
if nargin < 3; orient = obj.orientation; end
if isnan(orient); orient = obj.orientation; end
if orient==0; orient = obj.orientation; end

if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

result = 0;
maxSliceNumber = size(obj.img{1}, orient);

if sum(sliceNumbers > maxSliceNumber)
    msgbox(sprintf('The maximal slice number is %d!', maxSliceNumber), 'Wrong slice number', 'error', 'modal');
    return;
end

if options.showWaitbar; wb = waitbar(0, sprintf('Reslicing the dataset\nPlease wait...'), 'Name', 'Reslicing...'); end
maxT = size(obj.img{1},5);
maxZ = size(obj.img{1},4);
maxH = size(obj.img{1},1);
maxW = size(obj.img{1},2);

% reslice obj.img
if orient == 4     % xy orientation
    obj.img{1}=obj.img{1}(:, :, :, sliceNumbers, :);
elseif orient == 1     % zx orientation
    obj.img{1}=obj.img{1}(sliceNumbers, :, :, :, :);
elseif orient == 2     % zy orientation
    obj.img{1}=obj.img{1}(:, sliceNumbers, :, :, :);
elseif orient == 5     % t orientation
    obj.img{1}=obj.img{1}(:, :, :, :, sliceNumbers);
end
if options.showWaitbar; waitbar(0.3, wb); end

% reslice selection
if ~isnan(obj.selection{1}(1))
    if orient == 4     % xy orientation
        obj.selection{1} = obj.selection{1}(:, :, sliceNumbers, :);
    elseif orient == 1     % zx orientation
        obj.selection{1} = obj.selection{1}(sliceNumbers, :, :, :);
    elseif orient == 2     % zy orientation
        obj.selection{1} = obj.selection{1}(:, sliceNumbers, :, :);
    elseif orient == 5     % t orientation
        obj.selection{1}=obj.selection{1}(:, :, :, sliceNumbers);
    end
end
if options.showWaitbar; waitbar(0.5, wb); end

% reslice model
if ~isnan(obj.model{1}(1))
    if orient == 4     % xy orientation
        obj.model{1} = obj.model{1}(:,:,sliceNumbers,:);
    elseif orient == 1     % zx orientation
        obj.model{1} = obj.model{1}(sliceNumbers,:,:,:);
    elseif orient == 2     % zy orientation
        obj.model{1} = obj.model{1}(:,sliceNumbers,:,:);
    elseif orient == 5     % t orientation
        obj.model{1}=obj.model{1}(:,:,:,sliceNumbers);        
    end
end

% % shift labels
% [labelsList, labelValue, labelPositions, indices] = obj.hLabels.getLabels();   % [labelIndex, z x y t]
% if numel(labelsList) > 0 
%     for sliceId = numel(sliceNumbers):-1:1
%         currSlice = sliceNumbers(sliceId);
%         if orient == 4     % xy orientation
%             labelPositions(labelPositions(:,1)>=currSlice,1) = labelPositions(labelPositions(:,1)>=currSlice,1)-1;
%         elseif orient == 1     % zx orientation
%             labelPositions(labelPositions(:,3)>=currSlice,3) = labelPositions(labelPositions(:,3)>=currSlice,3)-1;
%         elseif orient == 2     % zy orientation
%             labelPositions(labelPositions(:,2)>=currSlice,2) = labelPositions(labelPositions(:,2)>=currSlice,2)-1;
%         elseif orient == 5     % t orientation
%             labelPositions(labelPositions(:,4)>=currSlice,4) = labelPositions(labelPositions(:,4)>=currSlice,4)-1;       
%         end
%     end
%     obj.hLabels.replaceLabels(labelsList, labelPositions, labelValue);
% end
if options.showWaitbar; waitbar(0.7, wb); end

% reslice mask
if ~isnan(obj.maskImg{1}(1))
    if orient == 4     % xy orientation
        obj.maskImg{1} = obj.maskImg{1}(:,:,sliceNumbers,:);
    elseif orient == 1     % zx orientation
        obj.maskImg{1} = obj.maskImg{1}(sliceNumbers,:,:,:);
    elseif orient == 2     % zy orientation
        obj.maskImg{1} = obj.maskImg{1}(:,sliceNumbers,:,:);
    elseif orient == 5     % t orientation
        obj.maskImg{1} = obj.maskImg{1}(:,:,:,sliceNumbers); 
    end
end
if options.showWaitbar; waitbar(0.9, wb); end
% update obj.height, obj.width, etc
obj.height = size(obj.img{1}, 1);
obj.width = size(obj.img{1}, 2);
obj.depth = size(obj.img{1}, 4);
obj.time = size(obj.img{1}, 5);
obj.dim_yxczt = [obj.height, obj.width, obj.colors, obj.depth, obj.time];

obj.meta('Height') = size(obj.img{1}, 1);
obj.meta('Width') = size(obj.img{1}, 2);
obj.meta('Depth') = size(obj.img{1}, 4);
obj.meta('Time') = size(obj.img{1}, 5);

% update I.slices
currSlices = obj.slices;

if orient < 5
    % update I.slices
    obj.slices{1} = [1, obj.height];
    obj.slices{2} = [1, obj.width];
    obj.slices{3} = obj.slices{3};
    obj.slices{4} = [1, size(obj.depth,4)];
    obj.slices{5} = [min([obj.slices{5}(1) obj.time]) min([obj.slices{5}(2) obj.time])];
    
    if currSlices{orient}(1) > size(obj.img{1}, orient)
        obj.slices{orient} = [size(obj.img{1}, orient) size(obj.img{1}, orient)];
    else
        obj.slices{orient} = currSlices{orient};
    end
    
    obj.current_yxz(1) = min([obj.current_yxz(1) obj.height]);
    obj.current_yxz(2) = min([obj.current_yxz(2) obj.width]);
    obj.current_yxz(3) = min([obj.current_yxz(3) obj.depth]);
    
    % update bounding box
    obj.updateBoundingBox();
    
    % update SliceName key in the img_info
    if isKey(obj.meta, 'SliceName')
        sliceNames = obj.meta('SliceName');
        if numel(obj.meta('SliceName')) > 1
            sliceNames = sliceNames(sliceNumbers);
            obj.meta('SliceName') = sliceNames;
        end
    end
else
    obj.slices{5} = [min([obj.slices{5}(1) obj.time]) min([obj.slices{5}(2) obj.time])];
end
% update the log list
if isfield(options, 'sliceNumbers')
    log_text = sprintf('Reslicing the dataset: %s, Orient: %d', options.sliceNumbers, orient);
else
    log_text = sprintf('Reslicing the dataset: %s, Orient: %d', num2str(sliceNumbers), orient);
end
obj.updateImgInfo(log_text);

if options.showWaitbar 
    waitbar(1, wb);
    delete(wb);
end
result = 1;
end