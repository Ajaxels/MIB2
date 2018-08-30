function menuImageIntensity_Callback(obj, parameter)
% function menuImageIntensity_Callback(obj, parameter)
% callback to the Menu->Image->Intensity profile; get the image intensity
% profile
%
% Parameters:
% parameter: a string that specify the mode of the image intensity profile
% @li 'line' - a linear profile between two points
% @li 'arbitrary' - an arbitrary profile
%
% Return values:
%

% Copyright (C) 06.20.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 22.08.2018, switched the color channel selection to the currently shown
% colors; added coloring of plots based on
% obj.mibModel.displayedLutColors added visualization of the analyzed slice

% % the commended section below was before 2.4 and the color channel was
% % selected based on the selection of the Color Channel combo box
% if numel(obj.mibModel.I{obj.mibModel.Id}.slices{3}) ~= 1    % get color channel from the selected in the Selection panel
%     colorChannel = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
% else    % when only one color channel is shown, take it
%     colorChannel = obj.mibModel.I{obj.mibModel.Id}.slices{3};
% end

% get visible color channels
colorChannel = obj.mibModel.I{obj.mibModel.Id}.slices{3};

obj.mibView.gui.WindowButtonDownFcn = [];
getDataOptions.blockModeSwitch = 1;

switch parameter
    case 'line'
        roi = imline(obj.mibView.handles.mibImageAxes);
        pos = round(roi.getPosition());
        delete(roi);
        % restore mibGUI_WindowButtonDownFcn
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        
        [pos(:,1), pos(:,2)] = obj.mibModel.convertMouseToDataCoordinates(pos(:,1), pos(:,2), 'blockmode');
        
        if abs(ceil(pos(2,1)-pos(1,1))) > abs(ceil(pos(2,2)-pos(1,2)))
            noPoints = abs(ceil(pos(2,1)-pos(1,1)));
        else
            noPoints = abs(ceil(pos(2,2)-pos(1,2)));
        end
        posX = linspace(pos(1,1), pos(2,1), noPoints);
        posY = linspace(pos(1,2), pos(2,2), noPoints);
        
    case 'arbitrary'
        roi = imfreehand(obj.mibView.handles.mibImageAxes, 'Closed', 0);
        pos = round(roi.getPosition());
        delete(roi);
        
        
        [pos(:,1), pos(:,2)] = obj.mibModel.convertMouseToDataCoordinates(pos(:,1), pos(:,2), 'blockmode');
        
        % restore mibGUI_WindowButtonDownFcn
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        
        posX = pos(:,1);
        posY = pos(:,2);
end

img = cell2mat(obj.mibModel.getData2D('image', obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber, ...
    obj.mibModel.I{obj.mibModel.Id}.orientation, colorChannel, getDataOptions));

for i=1:size(img, 3)
    c1(:,i) = improfile(img(:,:,i), posX, posY);
    legendStr(i) = cellstr(sprintf('Channel: %d', colorChannel(i)));
end
if size(img,3) == 1;     legendStr = sprintf('Channel: %d', colorChannel);  end

%c1 = improfile(img, pos(:,1), pos(:,2));
figure(15214);
clf
subplot(2,1,1);
%colorList = get(gca,'colororder');
for i=1:size(img, 3)
    improfile(img(:,:,i), posX, posY);
    hold on;
end
objH = findobj(gca, 'type', 'line');
for i=1:numel(objH)
    objH(numel(objH)-i+1).Color = obj.mibModel.displayedLutColors(colorChannel(i), :);
end

getDataOpt.blockModeSwitch = 1;
getDataOpt.resize = 'no';
img = obj.mibModel.getRGBimage(getDataOpt);

ax = gca;
ax.YLim = [1 size(img, 1)];
ax.XLim = [1 size(img, 2)];

yValue = 1:size(img, 1);
xValue = 1:size(img, 2);
[xValue, yValue] = meshgrid(xValue, yValue);
zLimits = zlim();
surf(ax, xValue, yValue, zLimits(1)+zeros([size(img, 1) size(img, 2)]), ...
    img,  'EdgeColor', 'none');
colormap('gray');

hold off;
title(sprintf('Image profile for color channel(s): %s', num2str(colorChannel)));
set(gca,'DataAspectRatio',[1 1 max(max(c1))/size(img,1)*5]);
grid;
subplot(2,1,2);
p1 = plot(1:size(c1,1),c1);
% update colors of the lines
for i=1:numel(p1)
    p1(i).Color = obj.mibModel.displayedLutColors(colorChannel(i), :);
end

legend(legendStr);
xlabel('Point in the profile');
ylabel('Intensity');
grid;


end