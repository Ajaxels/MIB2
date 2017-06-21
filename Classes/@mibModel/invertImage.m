function invertImage(obj, mode, colChannel)
% function invertImage(obj, mode, colChannel)
% invert image
% 
% Parameters:
% mode: a string that defines part of the dataset to be inverted
% @li when @b '2D' dilate for the currently shown slice
% @li when @b '3D' dilate for the currently shown z-stack
% @li when @b '4D' dilate for the whole dataset
% colChannel: [@em optional] a list of color channels to invert; @b 0 to
% invert all color channels, @b NaN to invert shown color channels
%

% Copyright (C) 03.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 3; colChannel = 0; end;

maxval = intmax(class(obj.I{obj.Id}.img{1}));

% tweak when only one time point
if strcmp(mode, '4D') && obj.I{obj.Id}.time == 1
    mode = '3D';
end
% do backup
if strcmp(mode, '3D')
    obj.mibDoBackup('image', 1);
elseif strcmp(mode, '2D')
    obj.mibDoBackup('image', 0);
end

% define the time points
if strcmp(mode, '4D')
    t1 = 1;
    t2 = obj.I{obj.Id}.time;
else    % 2D, 3D
    t1 = obj.I{obj.Id}.slices{5}(1);
    t2 = obj.I{obj.Id}.slices{5}(2);
end
showWaitbar = 0;
if ~strcmp(mode,'2D')
    wb = waitbar(0,sprintf('Inverting image...\nPlease wait...'), 'Name', 'Invert...', 'WindowStyle', 'modal');
    start_no=1;
    end_no=size(obj.I{obj.Id}.img{1}, obj.I{obj.Id}.orientation);
    showWaitbar = 1;
    max_size2 = (end_no-start_no+1)*(t2-t1+1);
end

index = 1;
getDataOptions.roiId = [];  % enable use of the ROI mode
for t=t1:t2     % loop across time points
    if ~strcmp(mode, '2D')
        img = obj.getData3D('image', t, 4, colChannel, getDataOptions);
    else
        getDataOptions.t = [t t];
        img = obj.getData2D('image', obj.I{obj.Id}.getCurrentSliceNumber(), NaN, colChannel, getDataOptions);
    end
    
    for roi = 1:numel(img)  % loop across ROIs
        img{roi} = maxval - img{roi};
    end
    
    if ~strcmp(mode, '2D')
        obj.setData3D('image', img, t, 4, colChannel, getDataOptions);
    else
        getDataOptions.t = [t t];
        obj.setData2D('image', img, obj.I{obj.Id}.getCurrentSliceNumber(), NaN, colChannel, getDataOptions);
    end
    if showWaitbar==1; waitbar(index/max_size2, wb); end;
end

if isnan(colChannel); colChannel = obj.I{obj.Id}.slices{3}; end;
log_text = sprintf('Invert, ColCh: %s', num2str(colChannel));
obj.I{obj.Id}.updateImgInfo(log_text);
if showWaitbar==1; delete(wb); end;
notify(obj, 'plotImage');
end
