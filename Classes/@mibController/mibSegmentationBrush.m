function mibSegmentationBrush(obj, y, x, modifier)
% mibSegmentation_Brush(obj, y, x, modifier)
% Do segmentation using the brush tool
%
% Parameters:
% y: y-coordinate of the mouse cursor at the starting point
% x: x-coordinate of the mouse cursor at the starting point
% modifier: a string, to specify what to do with the generated selection
% - @em empty - add selection
% - @em ''control'' - remove selection from the existing one
%
% Return values:
% 

%| @b Examples:
% @code obj.mibSegmentation_Brush(50, 75, '');  // start the brush tool from position [y,x]=50,75,10 @endcode

% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% if strcmp(obj.mibView.cursor.Visible, 'off'); 
%     return; 
% end;

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

% do backup
options.blockModeSwitch = 0;
[blockHeight, blockWidth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', NaN, NaN, options);
[axesX, axesY] = obj.mibModel.getAxesLimits();
backupOptions.x(1) = max([1 ceil(axesX(1))]);
backupOptions.x(2) = min([ceil(axesX(2)), blockWidth]);
backupOptions.y(1) = max([1 ceil(axesY(1))]);
backupOptions.y(2) = min([ceil(axesY(2)), blockHeight]);
obj.mibModel.mibDoBackup('selection', 0, backupOptions);  % do backup

radius = str2double(obj.mibView.handles.mibSegmSpotSizeEdit.String);
if radius == 0; return; end
obj.mibView.brushPrevXY = [x, y];

if strcmp(modifier, 'control')    % subtracts selections
    brush_switch = 'subtract';
else
    brush_switch = 'add';  % combines selections
end

selection_layer = 'image';
obj.mibView.brushSelection = {};
obj.mibView.brushSelection{1} = logical(zeros([size(obj.mibView.Ishown,1) size(obj.mibView.Ishown,2)], 'uint8')); %#ok<LOGL>

% generate the structural element for the brush
radius = radius - 1;
if radius < 1; radius = 0.5; end
magFactor = obj.mibModel.getMagFactor();
se_size = round(radius/magFactor);

% if handles.Img{handles.Id}.I.orientation == 4
%     se_size(2) = se_size(1);
% else
%     se_size(2) = round(se_size(1)/(handles.Img{handles.Id}.I.pixSize.x/handles.Img{handles.Id}.I.pixSize.z));
% end

structElement = zeros(se_size*2+1, se_size*2+1);
[xx,yy] = meshgrid(-se_size:se_size, -se_size:se_size);

ball = sqrt(((xx/se_size).^2) + (yy/se_size).^2);
structElement(ball<=1) = 1;

obj.mibView.brushSelection{1}(y,x) = 1;

% when the brush is large use bwdist function instead of imdilate
% update! in some cases imdilate becomes terribly slow
if size(structElement,2) < 10
    obj.mibView.brushSelection{1} = imdilate(obj.mibView.brushSelection{1}, structElement);
else
    obj.mibView.brushSelection{1} = bwdist(obj.mibView.brushSelection{1})<=size(structElement,1)/2; 
end

% enable superpixels mode, not for eraser
if (obj.mibView.handles.mibBrushSuperpixelsCheck.Value == 1 || ...
        obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value == 1) && isempty(modifier)
    col_channel = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;   %
    if col_channel == 0; col_channel = NaN; end
    if isnan(col_channel) && (obj.mibModel.I{obj.mibModel.Id}.colors ~= 3 && obj.mibModel.I{obj.mibModel.Id}.colors ~= 1)
        msgbox(sprintf('Please select the color channel!\n\nSelection panel->Color channel'),'Error!','error','modal');
        
        obj.mibView.gui.Pointer = 'crosshair';
        obj.mibView.gui.WindowButtonUpFcn = [];
        obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
        obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(eventdata));   % turn ON callback for the keys
        obj.plotImage(0);
        obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());   % moved from plotImage
        return;
    end
    getDataOptions.blockModeSwitch = 1;
    sImage = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, col_channel,getDataOptions));
    sImage = imresize(sImage, size(obj.mibView.brushSelection{1}));
    noLables = str2double(obj.mibView.handles.mibSuperpixelsNumberEdit.String);
    compactFactor = str2double(obj.mibView.handles.mibSuperpixelsCompactEdit.String);
    
    % stretch image for preview
    if obj.mibModel.mibLiveStretchCheck
        for i=1:size(sImage,3)
            sImage(:,:,i) = imadjust(sImage(:,:,i) ,stretchlim(sImage(:,:,i),[0 1]),[]);
        end
    end
    
    currViewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;
    if isnan(col_channel)
        selectedColChannels = obj.mibModel.I{obj.mibModel.Id}.slices{3};
    else
        selectedColChannels = col_channel;
    end
    max_int = double(intmax(class(sImage)));
    if isa(sImage, 'uint16') % convert to 8bit
        for colCh=1:numel(selectedColChannels)
            sImage(:,:,colCh) = imadjust(sImage(:,:,colCh),[currViewPort.min(selectedColChannels(colCh))/max_int currViewPort.max(selectedColChannels(colCh))/max_int],[0 1],currViewPort.gamma(selectedColChannels(colCh)));
        end
        sImage = uint8(sImage/255);
    elseif isa(sImage, 'uint8')     % stretch contrast if needed
        for colCh=1:numel(selectedColChannels)
            if currViewPort.min(selectedColChannels(colCh)) ~= 0 || ...
                currViewPort.max(selectedColChannels(colCh)) ~= max_int || ...
                currViewPort.gamma(selectedColChannels(colCh)) ~= 1
                        sImage(:,:,colCh) = imadjust(sImage(:,:,colCh),[currViewPort.min(selectedColChannels(colCh))/max_int currViewPort.max(selectedColChannels(colCh))/max_int],[0 1],currViewPort.gamma(selectedColChannels(colCh)));
            end
        end
    end
    
    if obj.mibView.handles.mibBrushSuperpixelsCheck.Value  % calculate SLIC superpixels
        [slicImage, noLabels] = slicmex(sImage, noLables, compactFactor);
        slicImage = slicImage+1;    % remove superpixel with 0 - value
    else                                            % calculate Watershed superpixels
        if compactFactor > 0     % invert image
            slicImage = imcomplement(sImage);    % convert image that the ridges are white
        else
            slicImage = sImage;    
        end
        mask = imextendedmin(slicImage, noLables);
        mask = imimposemin(slicImage, mask);
        slicImageB = watershed(mask);       % generate superpixels
        slicImage = imdilate(slicImageB, ones(3));
        noLabels = max(max(slicImage));
    end
    
    if noLabels < 255
        obj.mibView.brushSelection{2}.slic = uint8(slicImage);
    else
        obj.mibView.brushSelection{2}.slic = uint16(slicImage);
    end
    
    % indeces of boundaries for preview
    if obj.mibView.handles.mibBrushSuperpixelsCheck.Value  % calculate SLIC superpixels
        %boundaries = imdilate(obj.mibView.brushSelection{2}.slic,ones(3)) > imerode(obj.mibView.brushSelection{2}.slic,ones(3));
        boundaries = drawregionboundaries(obj.mibView.brushSelection{2}.slic);
        %boundaries = find(boundaries==1);
    else
        boundaries = slicImageB==0;   % for watershed
    end
    
    CData = obj.mibView.imh.CData;
    T2 = obj.mibModel.preferences.mibMaskTransparencySlider; % transparency for mask
    for ch=1:3
        img = CData(:,:,ch);
        img(boundaries) =  img(boundaries)*T2+obj.mibModel.preferences.maskcolor(ch)*intmax(class(img))*(1-T2);
        CData(:,:,ch) = img;
    end
    obj.mibView.imh.CData = CData;
    
    if obj.mibView.handles.mibAdaptiveDilateCheck.Value == 1
        if isnan(col_channel) && obj.mibModel.I{obj.mibModel.Id}.colors == 3
            obj.mibView.gui.Pointer = 'crosshair';
            obj.mibView.gui.WindowButtonUpFcn = [];
            obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
            obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(eventdata)); % turn ON callback for the keys
            obj.plotImage(0);
            obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());   % moved from plotImage
            msgbox(sprintf('The adaptive mode is not implemented for RGB images!\n\nPlease select a single channel in the Selection panel:\nSelection panel->Color channel'),'Error!','error','modal');
            return;
        end
        
        STATS = regionprops(obj.mibView.brushSelection{2}.slic, sImage, 'MeanIntensity');
        obj.mibView.brushSelection{3}.meanVals = [STATS.MeanIntensity];
        obj.mibView.brushSelection{3}.mean = mean(sImage(obj.mibView.brushSelection{1}==1));
        obj.mibView.brushSelection{3}.std = std(double(sImage(obj.mibView.brushSelection{1}==1)));
        obj.mibView.brushSelection{3}.factor = str2double(obj.mibView.handles.mibDilateAdaptCoefEdit.String);
        obj.mibView.brushSelection{3}.CData = obj.mibView.imh.CData;
        obj.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) obj.mibGUI_Brush_scrollWheelFcn(eventdata)); 
    end
    obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn_BrushSuperpixel(eventdata));   % turn ON callback for the keys
    
    selectedSlicIndices = unique(obj.mibView.brushSelection{2}.slic(obj.mibView.brushSelection{1}));
    obj.mibView.brushSelection{2}.selectedSlic = ismember(obj.mibView.brushSelection{2}.slic, selectedSlicIndices);   % SLIC based image
    obj.mibView.brushSelection{2}.selectedSlicIndices = selectedSlicIndices;     % list of indices of the currently selected superpixels
    obj.mibView.brushSelection{2}.CData = CData;     % store original CData with Boundaries of the superpixels
end

obj.mibView.updateCursor('solid');   % set the brush cursor in the drawing mode
obj.mibView.gui.WindowButtonDownFcn = [];

obj.mibView.gui.Pointer = 'custom';
obj.mibView.gui.PointerShapeCData = nan(16);
obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowBrushMotionFcn(selection_layer, structElement));
obj.mibView.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonUpFcn(brush_switch));

