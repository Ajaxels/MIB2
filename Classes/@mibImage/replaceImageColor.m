function replaceImageColor(obj, type, color_id, channel_id, slice_id, time_pnt, options)
% function replaceImageColor(obj, type, color_id, channel_id, slice_id, time_pnt, options)
% Replace image intensities in the @em Masked or @em Selected areas with new intensity value
%
% Parameters:
% type: a string that specifies which layer to use for color replacement: ''mask'' or ''selection''
% color_id: a vector with intensity of the new color
% channel_id: indeces of the color channels to be replaced
% slice_id: index of the slice number, or @b 0 for all
% time_pnt: index of the time point, or @b 0 for all
% options: a structure with optional parameters
% @li .showWaitbar - logical, show or not the waitbar
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.replaceImageColor('mask', 0, 1, 0, 1);  // call from mibController; to replace the Masked areas with black color for all slices of time point 1 @endcode

% Copyright (C) 10.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 7; options = struct(); end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end

if strcmp(obj.meta('ColorType'),'indexed')
    msgbox('Not compatible with indexed images!');
    return;
end
tic
if options.showWaitbar; wb = waitbar(0,sprintf('Replacing color channels\nPlease wait...'), 'Name', 'Replace color', 'WindowStyle', 'modal'); end
if time_pnt == 0
    t1 = 1;
    t2 = obj.time;
else
    t1 = time_pnt(1);
    t2 = time_pnt(numel(time_pnt));
end
max_slice = obj.dim_yxczt(obj.orientation);
if slice_id == 0
    z1 = 1;
    z2 = max_slice;
else
    z1 = slice_id(1);
    z2 = slice_id(numel(slice_id));
end
if channel_id == 0
    colChannel = 1:obj.colors;
else
    colChannel = channel_id;
end

totalnumber = (z2-z1)*(t2-t1+1);
for t=t1:t2
    getDataOptions.t = [t t];
    for sliceNumber = z1:z2
        getDataOptions.z = [sliceNumber, sliceNumber];
        mask_img = obj.getData(type, NaN, 0, getDataOptions);
        if sum(sum(mask_img)) < 1; continue; end
        
        curr_img = obj.getData('image', NaN, 0, getDataOptions);
        colIndex = 1;
        for channel = colChannel
            img2 = curr_img(:,:,channel);
            img2(mask_img==1) = color_id(colIndex);
            curr_img(:,:,channel) = img2;
            colIndex = colIndex + 1;
        end
        obj.setData('image', curr_img, NaN, 0, getDataOptions);
        if options.showWaitbar;  if mod(sliceNumber, 10)==0; waitbar((sliceNumber-z1)/totalnumber,wb); end; end
    end
end

if options.showWaitbar; waitbar(1,wb); end
if size(colChannel,1) > 1; colChannel = colChannel'; end
if size(color_id,1) > 1; color_id = color_id'; end
log_text = ['Color channels: ' num2str(colChannel) ' were replaced with new intensity(s): ' num2str(color_id)];
obj.updateImgInfo(log_text);
disp(log_text);
if options.showWaitbar; delete(wb); end
toc
end