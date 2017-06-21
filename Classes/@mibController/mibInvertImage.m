function mibInvertImage(obj, col_channel, sel_switch)
% function mibInvertImage(obj, col_channel, sel_switch)
% Invert image
%
% Parameters:
% col_channel: [@em optional] a list of color channels to invert; @b 0 to
% invert all color channels, @b NaN to invert shown color channels
% sel_switch: a string that defines part of the dataset to be inverted
% @li when @b '2D' dilate for the currently shown slice
% @li when @b '3D' dilate for the currently shown z-stack
% @li when @b '4D' dilate for the whole dataset
%
% Return values:
% 

% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 3; sel_switch = '4D'; end;
if nargin < 2; col_channel = NaN; end;
if isnan(col_channel)
    if numel(obj.mibView.handles.mibColChannelCombo.String)-1 > numel(obj.mibModel.I{obj.mibModel.Id}.slices{3})
        strText = sprintf('Would you like to invert shown or all channels?');
        button = questdlg(strText, 'Invert Image', 'Shown channels', 'All channels', 'Cancel', 'Shown channels');
        if strcmp(button, 'Cancel'); return; end;
        if strcmp(button, 'All channels')
            col_channel = 0;
        end
    end
end
        
maxval = intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1}));

% tweak when only one time point
if strcmp(sel_switch, '4D') && obj.mibModel.I{obj.mibModel.Id}.time == 1
    sel_switch = '3D';
end

% do backup
if strcmp(sel_switch, '3D')
    obj.mibModel.mibDoBackup('image', 1);
elseif strcmp(sel_switch, '2D')
    obj.mibModel.mibDoBackup('image', 0);
end

% define the time points
if strcmp(sel_switch, '4D')
    t1 = 1;
    t2 = obj.mibModel.I{obj.mibModel.Id}.time;
else    % 2D, 3D
    t1 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
    t2 = obj.mibModel.I{obj.mibModel.Id}.slices{5}(2);
end

showWaitbar = 0;
if ~strcmp(sel_switch,'2D')
    wb = waitbar(0,sprintf('Inverting image...\nPlease wait...'),'Name','Invert...','WindowStyle','modal');
    start_no=1;
    end_no=size(obj.mibModel.I{obj.mibModel.Id}.img{1}, obj.mibModel.I{obj.mibModel.Id}.orientation);
    showWaitbar = 1;
    max_size2 = (end_no-start_no+1)*(t2-t1+1);
end

index = 1;
getDataOptions.blockModeSwitch = obj.mibModel.getImageProperty('blockModeSwitch');
getDataOptions.roiId = obj.mibView.getRoiSwitch() - 1;     % when less than 0, do not use ROI mode, if 0 use currently selected ROI(s)

for t=t1:t2     % loop across time points
    if ~strcmp(sel_switch, '2D')
        img = obj.mibModel.getData3D('image', t, 4, col_channel, getDataOptions);
    else
        img = obj.mibModel.getData2D('image', NaN, 4, col_channel, getDataOptions);
    end
    
    for roi = 1:numel(img)  % loop across ROIs
        img{roi} = maxval - img{roi};
    end
    
    if ~strcmp(sel_switch, '2D')
        obj.mibModel.setData3D('image', img, t, 4, col_channel, getDataOptions);
    else
        obj.mibModel.setData2D('image', img, NaN, 4, col_channel, getDataOptions);
    end
    if showWaitbar==1; waitbar(index/max_size2, wb); end;
end

if isnan(col_channel); col_channel = obj.mibModel.I{obj.mibModel.Id}.slices{3}; end;
log_text = sprintf('Invert, ColCh: %s', num2str(col_channel));
obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
obj.plotImage();
if showWaitbar==1; delete(wb); end;
end