function bbShiftXY = addStack(obj, I2, shiftX, shiftY, options)
% bbShiftXY = addStack(obj, I2, shiftX, shiftY, options)
% Add I2 to mibImage and shift stacks according to shiftX, shiftY
% translation coefficients
%
% Parameters:
% I2: a stack to add [1:height, 1:width, 1:color, 1:depth]
% shiftX: a value for the X-shift
% shiftY: a value for the Y-shift
% options: an optional structure with options
%  - .backgroundColor -> background color: 'black', 'white', 'mean', or a number
%  - .SliceName -> cell array with slice names for the second dataset
%  - .waitbar -> [optional] a handle to existing waitbar
%
% Return values:
% bbShiftXY: a vector [xMin, yMin] with shift of the reference dataset, or
% empty in case of problems

% Copyright (C) 30.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
%
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 20.09.2019 updated from mibCrossShiftStacks to mibImage class for memory
% performance

bbShiftXY = [0, 0];
if nargin < 4; options = struct; end

if ~isfield(options, 'backgroundColor'); options.backgroundColor='black'; end

if nargin < 3
    errordlg(sprintf('!!! Error !!!\n\nThis function requires 3 parameters: image, shiftX and shiftY'));
    bbShiftXY = [];
    return;
end

% detect type of the inpuit data
if ndims(obj.img{1}) ~= ndims(I2) && ndims(obj.img{1}) ~= 2 && ndims(I2) ~= 2 %#ok<ISMAT>
    msgbox('Datasets dimensions mismatch!', 'Error', 'err');
    bbShiftXY = [];
    return;
end

if isfield(options, 'waitbar')
    wb = options.waitbar;
else
    wb = waitbar(0, sprintf('Adding a stack\nPlease wait'), 'Name', 'Align and drift correction', 'WindowStyle','modal');
end

[height1, width1, color1, depth1] = size(obj.img{1});
[height2, width2, color2, depth2] = size(I2);
depth = depth1 + depth2;
color = max([color1, color2]);

% allocate space for the output
if isnumeric(options.backgroundColor)
    backgroundColor = options.backgroundColor;
else
    if strcmp(options.backgroundColor,'black')
        backgroundColor = 0;
    elseif strcmp(options.backgroundColor,'white')
        backgroundColor = obj.meta('MaxInt');
    else
        backgroundColor = round(mean(mean(mean(mean(obj.img{1})))));
    end
end

if shiftX <= 0
    bbShiftXY(1) = shiftX;
    pad1_x1 = abs(shiftX);
    pad1_x2 = max([width2 - (pad1_x1+width1) 0]);
    pad2_x1 = 0;
    pad2_x2 = max([(pad1_x1+width1) - width2 0]);
    
    if shiftY >= 0     % the second dataset is shifted to towards the lower left corner
       pad1_y2 = 0;        % Y-shifts are coming from the top of the dataset
       pad1_y1 = max([(shiftY+height2) - height1 0]);
       pad2_y2 = shiftY;
       pad2_y1 = max([height1 - (shiftY+height2) 0]); 
    else            % the second dataset is shifted to towards the upper left corner, !!! not checked
        bbShiftXY(2) = shiftY;
        pad1_y2 = abs(shiftY);     % bottom   % Y-shifts are coming from the top of the dataset
        pad1_y1 = max([height2 - (pad1_y2+height1) 0]);  % top
        pad2_y2 = 0;
        pad2_y1 = max([(pad1_y2+height1) - height2 0]);
    end
else
    % padding of the main dataset
    pad1_x1 = 0;
    pad1_x2 = max([(shiftX+width2) - width1 0]);
    pad2_x1 = shiftX;
    pad2_x2 = max([width1 - (shiftX+width2) 0]);
    
    if shiftY >= 0     % the second dataset is shifted to towards the lower right corner
        pad1_y2 = 0;        % Y-shifts are coming from the top of the dataset
        pad1_y1 = max([(shiftY+height2) - height1 0]);
        pad2_y2 = shiftY;
        pad2_y1 = max([height1 - (shiftY+height2) 0]);
    else            % the second dataset is shifted to towards the upper right corner, !!! not checked
        bbShiftXY(2) = shiftY;
        pad1_y2 = abs(shiftY);     % bottom   % Y-shifts are coming from the top of the dataset
        pad1_y1 = max([height2 - (pad1_y2+height1) 0]);  % top
        pad2_y2 = 0;
        pad2_y1 = max([(pad1_y2+height1) - height2 0]);
    end
end

% resize width/height of the main dataset
waitbar(0.1, wb, sprintf('Resizing original dataset\nPlease wait'));
if pad1_x1 ~= 0 || pad1_y2 ~= 0
    obj.img{1} = padarray(obj.img{1}, [pad1_y2 pad1_x1], backgroundColor, 'pre');
    if ~isnan(obj.selection{1}(1))
        waitbar(0.2, wb, sprintf('Resizing original selection\nPlease wait'));
        obj.selection{1} = padarray(obj.selection{1}, [pad1_y2 pad1_x1], 0, 'pre');
    end
    if ~isnan(obj.model{1}(1))
        obj.model{1} = padarray(obj.model{1}, [pad1_y2 pad1_x1], 0, 'pre');
    end
    if ~isnan(obj.maskImg{1}(1))
        obj.maskImg{1} = padarray(obj.maskImg{1}, [pad1_y2 pad1_x1], 0, 'pre');
    end
end
waitbar(0.4, wb);
if pad1_x2 ~= 0 || pad1_y1 ~= 0
    obj.img{1} = padarray(obj.img{1}, [pad1_y1 pad1_x2], backgroundColor, 'post');
    if ~isnan(obj.selection{1}(1))
        obj.selection{1} = padarray(obj.selection{1}, [pad1_y1 pad1_x2], 0, 'post');
    end
    if ~isnan(obj.model{1}(1))
        obj.model{1} = padarray(obj.model{1}, [pad1_y1 pad1_x2], 0, 'post');
    end
    if ~isnan(obj.maskImg{1}(1))
        obj.maskImg{1} = padarray(obj.maskImg{1}, [pad1_y1 pad1_x2], 0, 'post');
    end
end

% resize width/height of the second dataset
waitbar(0.6, wb, sprintf('Resizing the added stack\nPlease wait'));
if pad2_x1 ~= 0 || pad2_y2 ~= 0
    I2 = padarray(I2, [pad2_y2 pad2_x1], backgroundColor, 'pre');
end
if pad2_x2 ~= 0 || pad2_y1 ~= 0
    I2 = padarray(I2, [pad2_y1 pad2_x2], backgroundColor, 'post');
end
% Concatenate datasets
waitbar(0.8, wb, sprintf('Concatenating datasets\nPlease wait'));
obj.img{1} = cat(4, obj.img{1}, I2);

% resize service layers
waitbar(0.9, wb, sprintf('Resizing the service layers\nPlease wait'));
newDimsI2 = [size(I2,1) size(I2,2) size(I2,4)];
clear I2;
if ~isnan(obj.selection{1}(1))
    %obj.selection{1} = cat(3, obj.selection{1}, zeros(newDimsI2, 'uint8'));
    obj.selection{1} = padarray(obj.selection{1}, [0 0 newDimsI2(3)], 0, 'post');   % faster, less memory
end
if ~isnan(obj.model{1}(1))
    %obj.model{1} = cat(3, obj.model{1}, zeros(newDimsI2, class(obj.model{1})));
    obj.model{1} = padarray(obj.model{1}, [0 0 newDimsI2(3)], 0, 'post');
end
if ~isnan(obj.maskImg{1}(1))
    %obj.maskImg{1} = cat(3, obj.maskImg{1}, zeros(newDimsI2, 'uint8'));
    obj.maskImg{1} = padarray(obj.maskImg{1}, [0 0 newDimsI2(3)], 0, 'post');
end

obj.depth = size(obj.img{1}, 4);
obj.meta('Depth') = obj.depth;
obj.dim_yxczt(4) = obj.depth;

% calculate shift of the bounding box
maxXshift = bbShiftXY(1)*obj.pixSize.x;  % X shift in units vs the first slice
maxYshift = bbShiftXY(2)*obj.pixSize.y;  % Y shift in units vs the first slice
bb = obj.getBoundingBox();
bb(1:2) = bb(1:2)-maxXshift;
bb(3:4) = bb(3:4)-maxYshift;
bb(6) = bb(6)+depth2*obj.pixSize.z;
obj.updateBoundingBox(bb);

obj.updateImgInfo(sprintf('Added Stack, bbShifts = %d, %d', bbShiftXY(1), bbShiftXY(2)));

% combine SliceNames
if isKey(obj.meta, 'SliceName')
    if numel(obj.meta('SliceName')) > 1
        SN = cell([size(obj.img{1}, 4), 1]);
        SN(1:numel(obj.meta('SliceName'))) = obj.meta('SliceName');
    
        if isfield(options, 'SliceName')
            SN(numel(obj.meta('SliceName'))+1:end) = options.SliceName;
        else
            SN(numel(obj.meta('SliceName'))+1:end) = {'added_stack'};
        end
        obj.meta('SliceName') = SN;
    end
end
obj.width = size(obj.img{1}, 2);
obj.height = size(obj.img{1}, 1);
obj.colors = size(obj.img{1}, 3);
obj.meta('Height') = obj.height;
obj.meta('Width') = obj.width;
waitbar(1, wb, sprintf('Finished adding the stack'));
if ~isfield(options, 'waitbar'); delete(wb); end
end

