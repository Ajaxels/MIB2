function result = invertImage(obj, mode, colChannel, Options)
% function result = invertImage(obj, mode, colChannel, Options)
% invert image
% 
% Parameters:
% mode: a string that defines part of the dataset to be inverted
% @li when @b '2D' dilate for the currently shown slice
% @li when @b '3D' dilate for the currently shown z-stack
% @li when @b '4D' dilate for the whole dataset
% colChannel: [@em optional] a list of color channels to invert; @b 0 to
% invert all color channels, @b NaN to invert shown color channels
% Options: a structure with additional parameters
% .t - a vector with time points to take [t1 t2]
% .z - a vector with slice numbers to take [z1 z2]
% .showWaitbar - logical, show or not the waitbar
% @li .id -> [@em optional], an index dataset from 1 to 9, defalt = currently shown dataset
%
% Return values:
% result: [logical], result of the operation 1-success, 0-fail

% Copyright (C) 03.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
result = 0; %#ok<NASGU>
if nargin < 4; Options = struct(); end
if nargin < 3; colChannel = 0; end

if ~isfield(Options, 'showWaitbar'); Options.showWaitbar = 1; end
if ~isfield(Options, 'id'); Options.id = obj.Id; end
maxval = obj.I{Options.id}.meta('MaxInt');

% tweak when only one time point
if strcmp(mode, '4D') && obj.I{Options.id}.time == 1
    mode = '3D';
end
% do backup
backupOptions.id = Options.id;
if strcmp(mode, '3D')
    obj.mibDoBackup('image', 1, backupOptions);
elseif strcmp(mode, '2D')
    if isfield(Options, 'z')
        backupOptions.z = Options.z;
    end
    obj.mibDoBackup('image', 0, backupOptions);
end

% define the time points
if strcmp(mode, '4D')
    t1 = 1;
    t2 = obj.I{Options.id}.time;
else    % 2D, 3D
    if isfield(Options, 't')
        t1 = Options.t(1);
        t2 = Options.t(max([numel(Options.t) 1]));
    else
        t1 = obj.I{Options.id}.slices{5}(1);
        t2 = obj.I{Options.id}.slices{5}(2);    
    end
    if strcmp(mode, '2D')
        if isfield(Options, 'z')
            sliceNo = Options.z(1);
        else
            sliceNo = obj.I{Options.id}.getCurrentSliceNumber();
        end
    end
        
end
if ~strcmp(mode,'2D')
    if Options.showWaitbar; wb = waitbar(0,sprintf('Inverting image...\nPlease wait...'), 'Name', 'Invert...', 'WindowStyle', 'modal'); end
    start_no=1;
    end_no=size(obj.I{Options.id}.img{1}, obj.I{Options.id}.orientation);
    max_size2 = (end_no-start_no+1)*(t2-t1+1);
else
    Options.showWaitbar = 0;
end

index = 1;
getDataOptions.roiId = [];  % enable use of the ROI mode
getDataOptions.id = Options.id;  % enable use of the ROI mode
for t=t1:t2     % loop across time points
    if ~strcmp(mode, '2D')
        img = obj.getData3D('image', t, 4, colChannel, getDataOptions);
    else
        getDataOptions.t = [t t];
        img = obj.getData2D('image', sliceNo, NaN, colChannel, getDataOptions);
    end
    
    for roi = 1:numel(img)  % loop across ROIs
        img{roi} = maxval - img{roi};
    end
    
    if ~strcmp(mode, '2D')
        obj.setData3D('image', img, t, 4, colChannel, getDataOptions);
    else
        getDataOptions.t = [t t];
        obj.setData2D('image', img, sliceNo, NaN, colChannel, getDataOptions);
    end
    if Options.showWaitbar; waitbar(index/max_size2, wb); end
end

if isnan(colChannel); colChannel = obj.I{Options.id}.slices{3}; end
log_text = sprintf('Invert, ColCh: %s', num2str(colChannel));
obj.I{Options.id}.updateImgInfo(log_text);
if Options.showWaitbar; delete(wb); end
notify(obj, 'plotImage');

result = 1;
end
