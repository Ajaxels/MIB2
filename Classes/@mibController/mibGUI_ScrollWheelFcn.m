function mibGUI_ScrollWheelFcn(obj, eventdata) 
% function mibGUI_ScrollWheelFcn(obj, eventdata) 
% Control callbacks from mouse scroll wheel 
%
% This function takes care of the mouse wheel. Depending on a key modifier and
% @em handles.mouseWheelToolbarSw it can:
% @li Ctrl+mouse wheel, change size of the brush and some other tools. The
% value of the new size value is displayed next to the cursor during the mouse
% wheel rotation.
% @li when @em handles.mouseWheelToolbarSw is not pressed, the mouse wheel
% is used for zoom in/zoom out actions.
% @li when @em handles.mouseWheelToolbarSw is pressed, the mouse wheel is
% used to change slices of the shown 3D dataset.
%
% Parameters:
% eventdata: additinal parameters

% Copyright (C) 10.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

modifier = obj.mibView.gui.CurrentModifier;    % detect control to change size of the brush tool

if strcmp(modifier, 'control') | strcmp(cell2mat(modifier), 'shiftcontrol') | strcmp(cell2mat(modifier), 'controlalt') | strcmp(cell2mat(modifier), 'shiftcontrolalt') %#ok<OR2>
    step = 1;   % step of the brush size change
    if strcmp(cell2mat(modifier), 'shiftcontrol') || strcmp(cell2mat(modifier), 'shiftcontrolalt')
        step = 5;
    end
    toolList = obj.mibView.handles.mibSegmentationToolPopup.String;
    toolName = strtrim(toolList{obj.mibView.handles.mibSegmentationToolPopup.Value});
    switch toolName
        case '3D ball'
            h1 = obj.mibView.handles.mibSegmSpotSizeEdit;
        case {'Brush'}
            if strcmp(cell2mat(modifier), 'controlalt') || strcmp(cell2mat(modifier), 'shiftcontrolalt')
                h1 = obj.mibView.handles.mibSuperpixelsNumberEdit;
            else
                h1 = obj.mibView.handles.mibSegmSpotSizeEdit;
            end
        case 'Object Picker'
            h1 = obj.mibView.handles.mibMaskBrushSizeEdit;
        case 'Membrane ClickTracker'
            h1 = obj.mibView.handles.mibSegmTrackWidthEdit;
        case 'Spot'
            h1 = obj.mibView.handles.mibSegmSpotSizeEdit;
        case 'MagicWand-RegionGrowing'
            h1 = obj.mibView.handles.mibSelectionToolEdit;
        otherwise
            return;
    end
    text = obj.mibView.handles.mibPixelInfoTxt2.String;
    colon = strfind(text,':');
    text = str2double(text(strfind(text,'(')+1:colon(2)-1));
    colorText = 1;
    if text < obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt')/2
        colorText = 2;
    end
    
    val = str2double(h1.String);
    
    % modification to release increase of the brush radius for the eraser
    if obj.mibView.ctrlPressed > 0 && h1 == obj.mibView.handles.mibSegmSpotSizeEdit
        val = val - obj.mibView.ctrlPressed;
        obj.mibView.ctrlPressed = -1;
        h1.String = num2str(val);
        obj.mibView.updateCursor();
    end
    
    if eventdata.VerticalScrollCount < 0
        val = val + step;
    else
        val = val - step;
        if val < 1; val = 1; end
    end
    
    % add cursor text
    %base = 1-imread('numbers.png');   % height=16, pixel size = 7, +1 pixel border
    table='1234567890';
    if val < 100
        text_str = num2str(val);
    else
        text_str = '99';
    end
    
    try
        for i=1:numel(text_str)
            coord(i) = (find(table == text_str(i))-1)*8 + 1; %#ok<AGROW>
        end
    catch err
        err
    end
    valuePointer = zeros([16 16]);
    for index = 1:numel(text_str)
        valuePointer(1:16, index*8-7:index*8) = obj.brushSizeNumbers(1:16,coord(index):coord(index)+7)*colorText;
    end
    valuePointer(valuePointer==0) = NaN;
    valuePointer(1:5,3) = colorText;
    valuePointer(3,1:5) = colorText;
    obj.mibView.gui.Pointer = 'custom';
    obj.mibView.gui.PointerShapeCData = valuePointer;
    h1.String = num2str(val);
    obj.mibView.updateCursor();
    return;
end

% check whether the mouse cursor within the axes.
position = obj.mibView.handles.mibImageAxes.CurrentPoint;
axXLim = obj.mibView.handles.mibImageAxes.XLim;
axYLim = obj.mibView.handles.mibImageAxes.YLim;
x = round(position(1,1));
y = round(position(1,2));
if x<axXLim(1) || x>axXLim(2) || y<axYLim(1) || y>axYLim(2)
    return;
end

if strcmp(obj.mibView.handles.mouseWheelToolbarSw.State,'on') & ...
        (strcmp(modifier, 'alt') | strcmp(cell2mat(modifier), 'shiftalt'))               %#ok<OR2,AND2> % change time point with Alt
    if strcmp(cell2mat(modifier), 'shiftalt')
        shift = obj.mibView.handles.mibChangeTimeSlider.UserData.sliderShiftStep;
    else
        shift = 1;
    end

    new_index = obj.mibModel.I{obj.mibModel.Id}.slices{5}(1) - eventdata.VerticalScrollCount*shift;
    if new_index < 1;  new_index = 1; end
    if new_index > obj.mibModel.I{obj.mibModel.Id}.time; new_index = obj.mibModel.I{obj.mibModel.Id}.time; end
    obj.mibView.handles.mibChangeTimeSlider.Value = new_index;     % update slider value
    obj.mibChangeTimeSlider_Callback();
elseif strcmp(obj.mibView.handles.mouseWheelToolbarSw.State,'off')                % zoom in/zoom out with the mouse wheel
    % Power law allows for the inverse to work:
    %      C^(x) * C^(-x) = 1
    % Choose C to get "appropriate" zoom factor
    C = 1.10;
    %             ch = get(handles.im_browser, 'CurrentCharacter');
    %             if ch == '`'    % change size of the brush
    %                 brush = str2double(get(handles.segmSpotSizeEdit,'String'));
    %                 brush = max([1 brush+eventdata.VerticalScrollCount]);
    %                 set(handles.segmSpotSizeEdit,'String',num2str(brush));
    %                 set(handles.im_browser, 'CurrentCharacter', '1');
    %                 return;
    %             end
    
    curPt  = mean(obj.mibView.handles.mibImageAxes.CurrentPoint);
    curPt = curPt(1:2);  % mouse coordinates
    
    % modify curPt with shifts that come from handles.Img{handles.Id}.I.axesX/handles.Img{handles.Id}.I.axesY and magnification factor
    magFactor = obj.mibModel.getMagFactor();
    [axesX, axesY] = obj.mibModel.getAxesLimits();
    curPt(1) = curPt(1)*magFactor + max([0 axesX(1)]);
    curPt(2) = curPt(2)*magFactor + max([0 axesY(1)]);
    xl = axesX;
    yl = axesY;
    % zoom will work only when the mouse is above the image
    if curPt(1)<xl(1) || curPt(1)>xl(2); return; end
    if curPt(2)<yl(1) || curPt(2)>yl(2); return; end
    
    midX = mean(xl);
    rngXhalf = diff(xl) / 2; % half-width of the shown image
    midY = mean(yl);
    rngYhalf = diff(yl) / 2; % half-height of the shown image
    
    curPt2 = (curPt-[midX, midY]) ./ [rngXhalf, rngYhalf];  % image shift in %%
    curPt  = [curPt; curPt];
    curPt2 = [-(1+curPt2).*[rngXhalf, rngYhalf];...
        (1-curPt2).*[rngXhalf, rngYhalf]];           % new image half-sizes without zooming
    
    r = C^(eventdata.VerticalScrollCount*eventdata.VerticalScrollAmount);
    newLimSpan = r * curPt2;
    
    % Determine new limits based on r
    lims = curPt + newLimSpan;
    
    % check out of image bounds conditions
    if lims(1,1) < 0 && lims(2,1) < 0; return; end
    if lims(1,2) < 0 && lims(2,2) < 0; return; end
    if lims(1,1) > obj.mibModel.I{obj.mibModel.Id}.width && lims(2,1) > obj.mibModel.I{obj.mibModel.Id}.width; return; end
    if lims(1,2) > obj.mibModel.I{obj.mibModel.Id}.height && lims(2,2) > obj.mibModel.I{obj.mibModel.Id}.height; return; end
    
    obj.mibModel.setMagFactor(magFactor*r);    % update magFactor
    obj.mibModel.setAxesLimits(lims(:,1)', lims(:,2)');    % update axes limits
    obj.plotImage(0);
else    % slice change with the mouse wheel
    if strcmp(modifier,'shift')
        shift = obj.mibView.handles.mibChangeLayerSlider.UserData.sliderShiftStep;
    else
        shift = 1;
    end
    new_index = obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation}(1) - eventdata.VerticalScrollCount*shift;
    if new_index < 1;  new_index = 1; end
    if new_index > obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation); new_index = obj.mibModel.I{obj.mibModel.Id}.dim_yxczt(obj.mibModel.I{obj.mibModel.Id}.orientation); end
    
    obj.mibView.handles.mibChangeLayerSlider.Value = new_index;     % update slider value
    obj.mibChangeLayerSlider_Callback();
end
end