function replaceImageColor(obj, type, color_id, channel_id, slice_id, time_pnt)
% function replaceImageColor(obj, type, color_id, channel_id, slice_id, time_pnt)
% Replace image intensities in the @em Masked or @em Selected areas with new intensity value
%
% Parameters:
% type: a string that specifies which layer to use for color replacement: ''mask'' or ''selection''
% color_id: a vector with intensity of the new color
% channel_id: indeces of the color channels to be replaced
% slice_id: index of the slice number, or @b 0 for all
% time_pnt: index of the time point, or @b 0 for all
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

if strcmp(obj.meta('ColorType'),'indexed')
    msgbox('Not compatible with indexed images!');
    return;
end
tic
wb = waitbar(0,sprintf('Replacing color channels\nPlease wait...'), 'Name', 'Replace color', 'WindowStyle', 'modal');
if time_pnt == 0
    t1 = 1;
    t2 = obj.time;
else
    t1 = time_pnt;
    t2 = time_pnt;
end
max_slice = size(obj.img{1}, obj.orientation);
if slice_id == 0
    start_no = 1;
    end_no = max_slice;
else
    start_no = slice_id;
    end_no = slice_id;
end
if channel_id == 0
    start_ch = 1;
    end_ch = obj.colors;
else
    start_ch = channel_id;
    end_ch = channel_id;
end

totalnumber = (end_no-start_no)*(t2-t1+1);
for t=t1:t2
    getDataOptions.t = [t t];
    for sliceNumber = start_no:end_no
        getDataOptions.z = [sliceNumber, sliceNumber];
        mask_img = obj.getData(type, NaN, 0, getDataOptions);
        if sum(sum(mask_img)) < 1; continue; end;
        
        curr_img = obj.getData('image', NaN, 0, getDataOptions);
        for channel = start_ch:end_ch
            img2 = curr_img(:,:,channel);
            img2(mask_img==1) = color_id(channel);
            curr_img(:,:,channel) = img2;
        end
        obj.setData('image', curr_img, NaN, 0, getDataOptions);
        if mod(sliceNumber, 10)==0; waitbar((sliceNumber-start_no)/totalnumber,wb); end;
    end
end

waitbar(1,wb);
log_text = ['Color channels: ' num2str(start_ch) ':' num2str(end_ch) ' were replaced with new intensity(s): ' num2str(color_id(start_ch:end_ch)')];
obj.updateImgInfo(log_text);
disp(log_text);
delete(wb);
toc
end