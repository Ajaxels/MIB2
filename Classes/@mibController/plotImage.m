function plotImage(obj, resize, sImgIn)
% function plotImage(obj, resize, sImgIn)
% Plot image to mibImageAxes. The main drawing function
%
% Parameters:
% resize: [@em optional]
% - when @b 0 [@em default] keep the current vieweing settings 
% - when @b 1 resize image to fit the screen
% sImgIn: a custom 2D image to show in the axes that should be targeted to
% the axes. Use resize=0 to show 'sImgIn' in the same scale/position as the
% currently shown dataset, or resize=1 to show 'sImgIn' in full resolution
%
% Return values:
% handles: - handles of im_browser.m

%| 
% @b Examples:
% @code obj.plotImage(1);     // call from mibController: plot image resize it @endcode

% Copyright (C) 08.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

if nargin < 2; resize = 0; end
rgbOptions.blockModeSwitch = 1;
rgbOptions.roiId = -1;
if nargin < 3   % generate Ishown from the dataset
    if obj.mibModel.I{obj.mibModel.Id}.volren.show == 0
        [obj.mibView.Ishown, obj.mibView.Iraw] = obj.mibModel.getRGBimage(rgbOptions);  % obj.mibView.Iraw is used only in the virtual stacking mode
    else
        imPanPos = obj.mibView.handles.mibImageAxes.Position;
        options.Mview = obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix;
        options.ImageSize = [floor(imPanPos(4)), floor(imPanPos(3))];
        options.ShearInterp = 'nearest';
        %options.AlphaTable = [1 0 0 0 1];

        timePoint = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1);
        if obj.mibModel.I{obj.mibModel.Id}.volren.showFullRes == 1
            obj.mibView.Ishown =  obj.mibModel.getRGBvolume(obj.mibModel.I{obj.mibModel.Id}.img{1}(:,:,:,:,timePoint), options);
        else
            obj.mibView.Ishown = obj.mibModel.getRGBvolume(obj.mibModel.I{obj.mibModel.Id}.volren.previewImg, options);
        end
                
        if isempty(obj.mibView.imh.CData) 
            obj.mibView.imh = image(obj.mibView.Ishown, 'parent', obj.mibView.handles.mibImageAxes);
        else
           set(obj.mibView.imh, 'CData',[],'CData', obj.mibView.Ishown);
        end
        
        obj.mibView.handles.mibImageAxes.DataAspectRatioMode = 'manual';
        obj.mibView.handles.mibImageAxes.PlotBoxAspectRatioMode = 'manual';
        obj.mibView.handles.mibImageAxes.DataAspectRatio = [1 1 1];
        obj.mibView.handles.mibImageAxes.PlotBoxAspectRatio = [imPanPos(3)/imPanPos(4) 1 1];
        
        obj.mibView.handles.mibImageAxes.Box = 'on';
        obj.mibView.handles.mibImageAxes.XTick = [];
        obj.mibView.handles.mibImageAxes.YTick = [];
        obj.mibView.handles.mibImageAxes.Interruptible = 'off';
        obj.mibView.handles.mibImageAxes.BusyAction = 'queue';
        obj.mibView.handles.mibImageAxes.HandleVisibility = 'callback';
        
        if obj.matlabVersion > 9.6;  drawnow nocallbacks limitrate; end     % needs to be here, otherwise in R2019b drawing lags
        return;
    end
else    % use for Ishown the image provided in the sImgIn
    if resize == 1
        rgbOptions.resize = 'no';   % show the provided image in full resolution 
    else
        rgbOptions.resize = 'yes';  % resize the provided image, to fit the current settings of the vieweing panel  
    end
    obj.mibView.Ishown = obj.mibModel.getRGBimage(rgbOptions, sImgIn);
end

if obj.mibModel.I{obj.mibModel.Id}.orientation == 4
    coef_z = obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.y;
elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1
    coef_z = obj.mibModel.I{obj.mibModel.Id}.pixSize.z/obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2
    coef_z = obj.mibModel.I{obj.mibModel.Id}.pixSize.z/obj.mibModel.I{obj.mibModel.Id}.pixSize.y;
end

if isempty(obj.mibView.imh.CData)
    obj.mibView.imh = image(obj.mibView.Ishown, 'parent', obj.mibView.handles.mibImageAxes);
else
   obj.mibView.imh.CData = [];
   obj.mibView.imh.CData = obj.mibView.Ishown;
   % delete measurements & roi
   lineObj = findobj(obj.mibView.handles.mibImageAxes, 'tag', 'measurements', '-or', 'tag', 'roi');
   if ~isempty(lineObj); delete(lineObj); end     % keep it within if, because it is faster
end

% update size of the cursor
obj.mibView.updateCursor(); 

%return
obj.mibView.imh.HitTest = 'off'; % If HitTest is off, clicking this object selects the object below it (which is usually the axes containing it)

%obj.mibView.gui.WindowButtonMotionFcn = {@im_browser_winMouseMotionFcn, handles};
%obj.mibView.gui.WindowButtonMotionFcn = obj.mibView.mibWinMouseMotionFcn();
%obj.mibView.gui.WindowScrollWheelFcn = {@im_browser_scrollWheelFcn, handles};

% obj.mibView.gui.WindowScrollWheelFcn = {@mibGUI_ScrollWheelFcn, obj};   % moved to updateGuiWidgets
% obj.mibView.gui.WindowButtonMotionFcn = {@mibGUI_mibWinMouseMotionFcn, obj};   % moved to updateGuiWidgets

obj.mibView.handles.mibImageAxes.Box = 'on';
obj.mibView.handles.mibImageAxes.XTick = [];
obj.mibView.handles.mibImageAxes.YTick = [];
obj.mibView.handles.mibImageAxes.Interruptible = 'off';
obj.mibView.handles.mibImageAxes.BusyAction = 'queue';
obj.mibView.handles.mibImageAxes.HandleVisibility = 'callback';

if exist('sImgIn', 'var') && resize == 1  % deal with case when the image is provided with the plotImage function
    obj.mibView.handles.mibImageAxes.DataAspectRatioMode = 'manual';
    obj.mibView.handles.mibImageAxes.PlotBoxAspectRatioMode = ' manual';
    obj.mibView.handles.mibImageAxes.DataAspectRatio = [1 coef_z 1];
    
    imPanPos = obj.mibView.handles.mibViewPanel.Position;  % size of the image panel
    obj.mibView.handles.mibImageAxes.PlotBoxAspectRatio = [imPanPos(3)/imPanPos(4)  1    1];
    obj.mibView.handles.mibImageAxes.YLim = [1 size(obj.mibView.Ishown,1)];
    obj.mibView.handles.mibImageAxes.XLim = [1 size(obj.mibView.Ishown,2)]; 
else
    magFactor = obj.mibModel.getMagFactor();
    [axesX, axesY] = obj.mibModel.getAxesLimits();    
    if resize == 1
        % set aspect ratio
        obj.mibView.handles.mibImageAxes.DataAspectRatioMode = 'manual';
        obj.mibView.handles.mibImageAxes.PlotBoxAspectRatioMode = 'manual';
        obj.mibView.handles.mibImageAxes.DataAspectRatio = [1 coef_z 1];
        imPanPos = obj.mibView.handles.mibViewPanel.Position;  % size of the image panel
        obj.mibView.handles.mibImageAxes.PlotBoxAspectRatio = [imPanPos(3)/imPanPos(4) 1 1];
        obj.mibView.handles.mibZoomEdit.String = sprintf('%d %%',round(1/magFactor*100));
        obj.mibView.handles.mibImageAxes.YLim = [axesY(1)/magFactor axesY(2)/magFactor];
        obj.mibView.handles.mibImageAxes.XLim = [axesX(1)/magFactor axesX(2)/magFactor];
    else
        obj.mibView.handles.mibImageAxes.Units = 'pixels';
        obj.mibView.handles.mibZoomEdit.String = sprintf('%d %%',round(1/magFactor*100));
        xl(1) = min([axesX(1)/magFactor 0]);
        
        if axesX(2) > size(obj.mibView.Ishown,2)*magFactor
            if axesX(1) < 0
                xl(2) = axesX(2)/magFactor;
            else
                xl(2) = axesX(2)/magFactor - axesX(1)/magFactor;
            end
        else
            xl(2) = size(obj.mibView.Ishown, 2);
        end
        
        yl(1) = min([axesY(1)/magFactor 0]);
        if axesY(2) > size(obj.mibView.Ishown, 1)*magFactor
            if axesY(1) < 0
                yl(2) = axesY(2)/magFactor;
            else
                yl(2) = axesY(2)/magFactor - axesY(1)/magFactor;
            end
        else
            yl(2) = size(obj.mibView.Ishown, 1);
        end

        obj.mibView.handles.mibImageAxes.YLim = yl;
        obj.mibView.handles.mibImageAxes.XLim = [xl(1) xl(2)];
    end
    
    % display a point that marks the center of the image axes
    if obj.mibView.centerSpotHandle.enable
        if isempty(obj.mibView.centerSpotHandle.handle) || isvalid(obj.mibView.centerSpotHandle.handle) == 0
            % because it gets removed after
            % obj.mibView.imh = image(obj.mibView.Ishown, 'parent', obj.mibView.handles.mibImageAxes);
            obj.mibView.centerSpotHandle.handle = drawpoint('Position', [mean(obj.mibView.handles.mibImageAxes.XLim) mean(obj.mibView.handles.mibImageAxes.YLim)], ...
                'Deletable', false,...
                'parent', obj.mibView.handles.mibImageAxes,...
                'Color', 'y');
        end
        obj.mibView.centerSpotHandle.handle.Position = [mean(obj.mibView.handles.mibImageAxes.XLim) mean(obj.mibView.handles.mibImageAxes.YLim)];
    end
   
    % show ROIs
    if obj.mibView.handles.mibRoiShowCheck.Value
        obj.mibModel.I{obj.mibModel.Id}.hROI.addROIsToPlot(obj, 'shown');
    end
    
    % show measurements
    if obj.mibModel.mibShowAnnotationsCheck
        obj.mibView.handles.mibShowAnnotationsCheck.Value = 1;
        obj.mibModel.I{obj.mibModel.Id}.hMeasure.addMeasurementsToPlot(obj.mibModel, 'shown', obj.mibView.handles.mibImageAxes);
    end
    if obj.matlabVersion > 9.6 
        drawnow nocallbacks limitrate; 
    end     % needs to be here, otherwise in R2019b drawing lags
end
end