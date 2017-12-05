function output = mibSegmentationMembraneClickTraker(obj, yxzCoordinate, yx, modifier)
% output = mibSegmentationMembraneClickTraker(obj, yxzCoordinate, yx, modifier)
% Trace membranes and draw a straight lines in 2d and 3d
%
% Parameters:
% yxzCoordinate: a vector with [y,x,z] coodrinates of the starting point (match voxel coordinates of the dataset)
% yx: a vector [y,x] with coordinates of the clicked point
% modifier: a string, to specify what to do with the generated selection
% - @em empty - trace membrane from the starting to the selected point
% - @em ''shift'' - defines the starting point of a membrane
%
% Return values:
% output:  a string that defines what next to do in the im_browser_WindowButtonDown function
% - @em ''continue'' - continue with the script
% - @em ''return'' - stop execution and return

% Copyright (C) 22.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

switch3d = obj.mibView.handles.mibActions3dCheck.Value;     % use tool in 3d
output = 'continue';
if obj.mibModel.getImageProperty('blockModeSwitch')
    msgbox('Please switch off the BlockMode using the button in the toolbar','Not compatible with the BlockMode','error'); return;
end
if switch3d && obj.mibView.handles.mibSegmTrackStraightChk.Value ==0
    msgbox(sprintf('!!! Warning !!!\n\nThe automatic line tracking is only available for the 2D mode; please switch off the 3D mode in the Selection panel\n\nNote: the 3D mode can be used to generate straight line segments when the the "Straight line" option of the Membrane ClickTracker tool is selected'),'Error','error');
    return;
end

line_width = str2double(obj.mibView.handles.mibSegmTrackWidthEdit.String);
orient = 4;

magFactor = obj.mibModel.getMagFactor();
if switch3d
    h = yxzCoordinate(1);
    w = yxzCoordinate(2);
    z = yxzCoordinate(3);
    if strcmp(modifier, 'shift')    % defines first point for the tracer, with the Shift button
        obj.mibModel.mibDoBackup('selection', 0);
        
        obj.mibView.trackerYXZ = [h; w; z];
        options.blockModeSwitch = 1;
        currentSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, orient, NaN, options));
        selarea = zeros(size(currentSelection), 'uint8');
        selarea(ceil(yx(1)*magFactor), ceil(yx(2)*magFactor)) = 1;
        obj.mibModel.setData2D('selection', bitor(selarea, currentSelection), NaN, orient, NaN, options);
    else
        if isnan(obj.mibView.trackerYXZ(1))
            msgbox('Please use Shift+Mouse click to define the starting point!','Missing the starting point');
            return;
        end;
        
        obj.mibView.trackerYXZ = obj.mibView.trackerYXZ(:,end);
        [height, width, ~, thick] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', 4);
        p1 = obj.mibView.trackerYXZ;
        %p2 = [y; x; z];
        p2 = [h; w; z];
        dv = p2 - p1;
        
        % generate structural element for dilation
        orientation = obj.mibModel.getImageProperty('orientation');
        pixSize = obj.mibModel.getImageProperty('pixSize');
        if orientation == 1
            se_size(1) = line_width; % x
            se_size(2) = round(se_size(1)*pixSize.x/pixSize.z); % y
            se_size(3) = line_width; % for z
        elseif orientation == 2
            se_size(2) = line_width; % y
            se_size(3) = line_width; % for z
            se_size(1) = round(line_width*pixSize.x/pixSize.z); % x
        elseif orientation == 4
            se_size(1) = line_width; % for x
            se_size(2) = line_width; % for y
            se_size(3) = round(se_size(1)*pixSize.x/pixSize.z); % for z
        end
        se = zeros(se_size(1)*2+1,se_size(2)*2+1,se_size(3)*2+1);    % do strel ball type in volume
        [xMesh,yMesh,zMesh] = meshgrid(-se_size(1):se_size(1),-se_size(2):se_size(2),-se_size(3):se_size(3));
        ball = sqrt((xMesh/se_size(1)).^2+(yMesh/se_size(2)).^2+(zMesh/se_size(3)).^2);
        se(ball<=1) = 1;
        
        minY = min([p1(1) p2(1)]);
        maxY = max([p1(1) p2(1)]);
        minX = min([p1(2) p2(2)]);
        maxX = max([p1(2) p2(2)]);
        minZ = min([p1(3) p2(3)]);
        maxZ = max([p1(3) p2(3)]);
        
        shiftY1 = se_size(2);
        shiftY2 = se_size(2);
        shiftX1 = se_size(1);
        shiftX2 = se_size(1);
        shiftZ1 = se_size(3);
        shiftZ2 = se_size(3);
        
        if minY-se_size(2) <=0; shiftY1 = minY-1; end
        if minX-se_size(1) <=0; shiftX1 = minX-1; end
        if minZ-se_size(3) <=0; shiftZ1 = minZ-1; end
        if maxY+se_size(2) > height; shiftY2 = height-maxY; end
        if maxX+se_size(1) > width; shiftX2 = width-maxX; end
        if maxZ+se_size(2) > thick; shiftZ2 = thick-maxZ; end
        
        p1shift = p1 - [minY-shiftY1-1; minX-shiftX1-1; minZ-shiftZ1-1];
        
        options.x = [minX-shiftX1 maxX+shiftX2];
        options.y = [minY-shiftY1 maxY+shiftY2];
        options.z = [minZ-shiftZ1 maxZ+shiftZ2];
        
        % do backup
        obj.mibModel.mibDoBackup('selection', switch3d, options);
        
        currSelection = cell2mat(obj.mibModel.getData3D('selection', NaN, orient, 0, options));
        selareaCrop = zeros(size(currSelection), 'uint8');
        
        nPnts = max(abs(dv))+1;
        linSpacing = linspace(0, 1, nPnts);
        for i=1:nPnts
            selareaCrop(round(p1shift(1)+linSpacing(i)*dv(1)), round(p1shift(2)+linSpacing(i)*dv(2)),round(p1shift(3)+linSpacing(i)*dv(3))) = 1;
        end
        if isempty(find(se_size==0, 1))    % dilate to make line thicker, do not dilate when line is 1 pix wide
            selareaCrop = imdilate(selareaCrop, se);
        end
        obj.mibView.trackerYXZ(:,2) = [h; w; z];
        % combines selections
        obj.mibModel.setData3D('selection', bitor(currSelection, selareaCrop), NaN, orient, 0, options); % combines selections
        obj.plotImage();
        output = 'return';
        return;
    end
else
    obj.mibModel.mibDoBackup('selection', 0);
    yCrop = yxzCoordinate(1);
    xCrop = yxzCoordinate(2);
    z = yxzCoordinate(3); 
    options.blockModeSwitch = 1;
    if strcmp(modifier, 'shift')    % defines first point for the tracer
        obj.mibView.trackerYXZ = [yCrop; xCrop; z];
        currentSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        selarea = zeros(size(currentSelection), 'uint8');
        selarea(ceil(yx(1)*magFactor),ceil(yx(2)*magFactor)) = 1;
    else    % start tracing
        if isnan(obj.mibView.trackerYXZ(1))
            msgbox('Please use Shift+Mouse click to define the starting point!', 'Missing the starting point');
            return;
        end
        obj.mibView.trackerYXZ = obj.mibView.trackerYXZ(:,end);
        [axesX, axesY] = obj.mibModel.getAxesLimits();
        pointY = obj.mibView.trackerYXZ(1)-max([0 floor(axesY(1))]);
        pointX = obj.mibView.trackerYXZ(2)-max([0 floor(axesX(1))]);
        if pointY < 1 || pointX < 1 || pointX > axesX(2) || pointY > axesY(2)
            msgbox('Please shift the window to see both the starting and the ending points!','Wrong view!','error');
            return;
        end
        currentSelection = cell2mat(obj.mibModel.getData2D('selection', NaN, NaN, NaN, options));
        if obj.mibView.handles.mibSegmTrackStraightChk.Value   % connect points using a straight line
            pnts(1,:) = [pointX, pointY];
            pnts(2,:) = [ceil(yx(2)*magFactor); ceil(yx(1)*magFactor)];
            selarea = zeros(size(currentSelection), 'uint8');
            selarea = mibConnectPoints(selarea, pnts);
            obj.mibView.trackerYXZ(:,2) = [yCrop; xCrop; z];
        else            % connect points using accurate fast marching function
            colorId = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
            if colorId == 0
                if obj.mibModel.getImageProperty('colors') > 1
                    msgbox('Please select the color channel in the Selection panel!','Wrong color channel!','error');
                    return;
                else
                    colorId = 1;
                end
            end
            options.p1 = [pointY; pointX];
            options.p2 = [min([ceil(yx(1)*magFactor), size(currentSelection,1)]); ...
                min([ceil(yx(2)*magFactor) size(currentSelection,2)])];
            options.scaleFactor = str2double(obj.mibView.handles.mibSegmTracScaleEdit.String);
            options.segmTrackBlackChk = obj.mibView.handles.mibSegmTrackBlackChk.Value;
            options.colorId = colorId;
            currImage = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, NaN, options));
            
            [selarea, status] = mibTraceCurve(currImage, options);
            if status == 1; obj.mibView.trackerYXZ(:,2) = [yCrop; xCrop; z]; end;
        end
    end
    if line_width > 0
        selarea = imdilate(selarea, strel('disk', line_width-1, 0));
    end
    obj.mibModel.setData2D('selection', bitor(currentSelection, selarea), NaN, NaN, NaN, options);
end