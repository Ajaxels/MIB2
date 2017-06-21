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
%

if numel(obj.mibModel.I{obj.mibModel.Id}.slices{3}) ~= 1    % get color channel from the selected in the Selection panel
    colorChannel = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
else    % when only one color channel is shown, take it
    colorChannel = obj.mibModel.I{obj.mibModel.Id}.slices{3};
end
obj.mibView.gui.WindowButtonDownFcn = [];
getDataOptions.blockModeSwitch = 0;

switch parameter
    case 'line'
        roi = imline(obj.mibView.handles.mibImageAxes);
        pos = round(roi.getPosition());
        delete(roi);
        % restore mibGUI_WindowButtonDownFcn
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        
        pos(:,1) = pos(:,1)*obj.mibModel.I{obj.mibModel.Id}.magFactor + max([0 floor(obj.mibModel.I{obj.mibModel.Id}.axesX(1))]);
        pos(:,2) = pos(:,2)*obj.mibModel.I{obj.mibModel.Id}.magFactor + max([0 floor(obj.mibModel.I{obj.mibModel.Id}.axesY(1))]);
        
        figure(15214);
        clf;
        img = cell2mat(obj.mibModel.getData2D('image', obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber, ...
            obj.mibModel.I{obj.mibModel.Id}.orientation, colorChannel, getDataOptions));
        for i=1:size(img, 3)
            c1(:,i) = improfile(img(:,:,i), pos(:,1),pos(:,2));
            legendStr(i) = cellstr(sprintf('Channel: %d', i));
        end
        plot(1:size(c1,1), c1);
        if size(img, 3) == 1;     legendStr = sprintf('Channel: %d', colorChannel);  end;
        legend(legendStr);
        xlabel('Point in the drawn profile');
        ylabel('Intensity');
        grid;
        title(sprintf('Image profile for color channel: %d', colorChannel));
    case 'arbitrary'
        roi = imfreehand(obj.mibView.handles.mibImageAxes, 'Closed', 0);
        pos = round(roi.getPosition());
        delete(roi);
        pos(:,1) = pos(:,1)*obj.mibModel.I{obj.mibModel.Id}.magFactor + max([0 floor(obj.mibModel.I{obj.mibModel.Id}.axesX(1))]);
        pos(:,2) = pos(:,2)*obj.mibModel.I{obj.mibModel.Id}.magFactor + max([0 floor(obj.mibModel.I{obj.mibModel.Id}.axesY(1))]);
        
       % restore mibGUI_WindowButtonDownFcn
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        
        img = cell2mat(obj.mibModel.getData2D('image', obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber, ...
            obj.mibModel.I{obj.mibModel.Id}.orientation, colorChannel));
        
        for i=1:size(img, 3)
            c1(:,i) = improfile(img(:,:,i), pos(:,1),pos(:,2));
            legendStr(i) = cellstr(sprintf('Channel: %d', i));
        end
        if size(img,3) == 1;     legendStr = sprintf('Channel: %d', colorChannel);  end;
        
        %c1 = improfile(img, pos(:,1), pos(:,2));
        figure(15214);
        clf
        subplot(2,1,1);
        %colorList = get(gca,'colororder');
        for i=1:size(img, 3)
            improfile(img(:,:,i), pos(:,1), pos(:,2));
            hold on;
        end
        hold off;
        title(sprintf('Image profile for color channel: %d', colorChannel));
        set(gca,'DataAspectRatio',[1 1 max(max(c1))/size(img,1)*5]);
        set(gca,'xlim',[1 size(img, 2)]);
        set(gca,'ylim',[1 size(img, 1)]);
        grid;
        subplot(2,1,2);
        plot(1:size(c1,1),c1);
        legend(legendStr);
        xlabel('Point in the drawn profile');
        ylabel('Intensity');
        grid;
end

end