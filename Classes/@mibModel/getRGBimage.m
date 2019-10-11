function [imgRGB, imgRAW] = getRGBimage(obj, options, sImgIn)
% function [imgRGB, imgRAW] =  getRGBimage(obj, options, sImgIn)
% Generate RGB image from all layers that have to be shown on the screen.
%
% Parameters:
% options: a structure with extra parameters:
% @li .blockModeSwitch -> @b 0 -> return RGB image of the whole slice [@b default]; @b 1 -> return RGB image of the shown area only
% @li .resize -> @b yes -> resize RGB image to the current magnification value [@b default]; @b no -> return the image in the original resolution
% @li .sliceNo [@em optional] -> index of a slice to show
% @li .markerType [@em optional] -> @em default NaN, type of annotations: when @b both show a label next to the position marker,
%                           when @b marker - show only the marker without the label, when
%                           @b text - show only text without marker
% @li .t -> [@em optional], [tmin, tmax] the time point of the dataset; default is the currently shown time point
% @li .y -> [@em optional], [ymin, ymax] of the part of the slice to take (sets .blockModeSwitch to 0)
% @li .x -> [@em optional], [xmin, xmax] of the part of the slice to take (sets .blockModeSwitch to 0)
% @li .useLut -> [@em optional], 0 or 1 to use or not LUT table
% sImgIn: a custom 3D stack to grab a single 2D slice from
%
% Return values:
% imgRGB: - RGB image with combined layers, [1:height, 1:width, 1:3]
% imgRAW: - RAW image, used only when mibImage.Virtual.virtual == 1, i.e.
% in the virtual stacking mode
%
%| @b Examples:
% @code options.blockModeSwitch = 1; @endcode
% @code imageData.Ishown = imageData.getRGBimage(handles, options);     // to get cropped 2D RGB image of the shown area @endcode
% @code imageData.Ishown = getRGBimage(obj, handles, options);// Call within the class; to get cropped 2D RGB image of the shown area @endcode

% Copyright (C) 08.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

if ~isfield(options, 'blockModeSwitch'); options.blockModeSwitch = 0; end
if ~isfield(options, 'resize'); options.resize = 'yes'; end
if ~isfield(options, 'markerType'); options.markerType = NaN; end
if ~isfield(options, 't'); options.t = [obj.I{obj.Id}.slices{5}(1) obj.I{obj.Id}.slices{5}(1)]; end
if ~isfield(options, 'useLut'); options.useLut = obj.I{obj.Id}.useLUT; end

options.roiId = -1; % do use show any ROIs in this mode

% get a copy of slices and orientation for easier code below
slices = obj.I{obj.Id}.slices;
orientation = obj.I{obj.Id}.orientation;
if strcmp(options.resize, 'no')
    magnificationFactor = 1;
else
    magnificationFactor = obj.getMagFactor();
end

if strcmp(obj.preferences.imageResizeMethod, 'auto')
    if magnificationFactor > 1
        imageResizeMethod = 'bicubic';
    else
        imageResizeMethod = 'nearest';
    end
else
    imageResizeMethod = obj.preferences.imageResizeMethod;
end

panModeException = 0; % otherwise in the pan mode the image may be huge
if options.blockModeSwitch == 0 && magnificationFactor < 1 % to use with the pan mode
    panModeException = 1;
end
if isfield(options, 'sliceNo')      % overwrite current slice number with the provided
    sliceToShowIdx = options.sliceNo;
else
    sliceToShowIdx = slices{orientation}(1);
end

% get image
if nargin < 3
    sImgIn = cell2mat(obj.getData2D('image', sliceToShowIdx, NaN, NaN, options));
    colortype = obj.I{obj.Id}.meta('ColorType');
    currViewPort = obj.I{obj.Id}.viewPort;    % copy view port information
    showModelSwitch = obj.mibModelShowCheck;  % whether or not show model above the image
    showMaskSwitch = obj.mibMaskShowCheck;  % whether or not show mask above the image
else
    if size(sImgIn, 3) > 1     % define color type for provided image
        colortype = 'truecolor';
    else
        colortype = 'grayscale';
    end
    currViewPort.min =  zeros([size(sImgIn, 3), 1]);    % generate viewPort information, needed for cases when sImgIn has different class from obj.img
    currViewPort.max =  zeros([size(sImgIn, 3), 1]) + double(intmax(class(sImgIn)));    % generate viewPort information
    currViewPort.gamma =  zeros([size(sImgIn, 3), 1]) + 1;    % generate viewPort information

    showModelSwitch = 0;    % do not show the model
    showMaskSwitch = 0;     % do not show the mask
end

% resize image to show, except the 'full' case with magFactor > 1
if panModeException == 1 % to use with the pan mode
    sImg = sImgIn;
else
    if magnificationFactor > 1  % do not upscale images until the end of procedure
        if strcmp(imageResizeMethod, 'nearest') || strcmp(colortype, 'indexed') % tweak to make resizing faster in the nearest mode, may result in different image sizes compared to imresize method
            sImg = sImgIn(round(.51:magnificationFactor:end+.49),round(.51:magnificationFactor:end+.49),:);     % NOTE! the image size may be different from the imresize method
        else
            for colCh = 1:size(sImgIn,3)
                if colCh==1
                    sImg = imresize(sImgIn(:,:,colCh), 1/magnificationFactor, imageResizeMethod); 
                else
                    sImg(:,:,colCh) = imresize(sImgIn(:,:,colCh), 1/magnificationFactor, imageResizeMethod);
                end
            end
        end
    else
        sImg = sImgIn;
    end
end
clear sImgIn;

% generate imgRAW dataset for the virtual stacking mode
imgRAW = [];
if obj.I{obj.Id}.Virtual.virtual == 1
    imgRAW = sImg;
end

% hide image
if obj.mibHideImageCheck == 1 % hide image
    sImg = zeros(size(sImg), class(sImg));
end

max_int = double(intmax(class(sImg)));

% stretch image for preview
if obj.mibLiveStretchCheck
    if ~isa(sImg, 'uint32')
        for i=1:size(sImg,3)
            sImg(:,:,i) = imadjust(sImg(:,:,i), stretchlim(sImg(:,:,i),[0 1]),[]);
        end
    else
        for i=1:size(sImg,3)
            minVal = min(min(sImg(:,:,i)));
            maxVal = max(max(sImg(:,:,i)));
            sImg(:,:,i) = double((sImg(:,:,i)-minVal))/double((maxVal-minVal))*255;
        end
        sImg = double(sImg);
    end
end

% get the segmentation model if neeeded
if showModelSwitch == 1 && obj.I{obj.Id}.modelExist % whether to show model
    sOver1 = cell2mat(obj.getData2D('model', sliceToShowIdx, NaN, NaN, options));
    
    if panModeException == 0 && magnificationFactor > 1
        if strcmp(imageResizeMethod,'nearest') || strcmp(colortype, 'indexed')    % because no matter of the resampling way, the indexed images are resampled via nearest
            sOver1 = sOver1(round(.51:magnificationFactor:end+.49), round(.51:magnificationFactor:end+.49));     % NOTE! the image size may be different from the imresize method
        else
            sOver1 = imresize(sOver1, 1/magnificationFactor, 'nearest');
        end
    end
else
    sOver1 = NaN;
end

% get the mask model if needed
if showMaskSwitch == 1 && obj.I{obj.Id}.maskExist % whether to show filter model
    sOver2 = cell2mat(obj.getData2D('mask', sliceToShowIdx, NaN, NaN, options));
    if panModeException == 0 && magnificationFactor > 1
        if strcmp(imageResizeMethod,'nearest') || strcmp(colortype, 'indexed')    % because no matter of the resampling way, the indexed images are resampled via nearest
            sOver2 = sOver2(round(.51:magnificationFactor:end+.49),round(.51:magnificationFactor:end+.49));     % NOTE! the image size may be different from the imresize method
        else
            sOver2 = imresize(sOver2, 1/magnificationFactor, 'nearest');    
        end
    end
else
    sOver2 = NaN;
end

% get the selection model
if obj.I{obj.Id}.disableSelection == 0
    selectionModel = cell2mat(obj.getData2D('selection', sliceToShowIdx, NaN, NaN, options));
    if panModeException == 0 && magnificationFactor > 1
        if strcmp(imageResizeMethod,'nearest')  || strcmp(colortype, 'indexed')   % because no matter of the resampling way, the indexed images are resampled via nearest
            selectionModel = selectionModel(round(.51:magnificationFactor:end+.49),round(.51:magnificationFactor:end+.49));     % NOTE! the image size may be different from the imresize method
        else
            selectionModel = imresize(selectionModel, 1/magnificationFactor, 'nearest');
        end
    end
else
    selectionModel = NaN;
end

colorScale = max_int; % coefficient for scaling the colors
selectedColorsLUT = obj.I{obj.Id}.lutColors(slices{3},:);     % take LUT colors for the selected color channels

switch colortype
    case 'grayscale'
        if currViewPort.min(1) ~= 0 || currViewPort.max(1) ~= max_int || currViewPort.gamma ~= 1
            % convert to the 8bit image
            if ~isa(sImg, 'uint32')
                sImg = imadjust(sImg,[currViewPort.min(1)/max_int currViewPort.max(1)/max_int],[0 1],currViewPort.gamma(1));    
            else
                sImg = uint8(double((sImg-currViewPort.min))/double((currViewPort.max-currViewPort.min))*255);
                colorScale = 255;
            end
        elseif isa(sImg, 'double')  
            sImg = uint8(sImg);
            colorScale = 255;
        end
        if options.useLut     % use LUT for colors
            R = sImg*selectedColorsLUT(1,1);
            G = sImg*selectedColorsLUT(1,2);
            B = sImg*selectedColorsLUT(1,3);
        else
            R = sImg;
            G = sImg;
            B = sImg;
        end
    case 'indexed'
        cmap = obj.I{obj.Id}.meta('Colormap');
        sImg = uint8(ind2rgb(sImg, cmap)*255);
        R = sImg(:,:,1);
        G = sImg(:,:,2);
        B = sImg(:,:,3);
    otherwise
        if options.useLut     % use LUT for colors
            adjImg = imadjust(sImg(:,:,1),...
                [currViewPort.min(slices{3}(1))/max_int currViewPort.max(slices{3}(1))/max_int],...
                [0 1],currViewPort.gamma(slices{3}(1)));
            R = adjImg*selectedColorsLUT(1,1);
            G = adjImg*selectedColorsLUT(1,2);
            B = adjImg*selectedColorsLUT(1,3);
            
            if numel(slices{3} > 1)
                for i=2:numel(slices{3})
                    adjImg = imadjust(sImg(:,:,i),...
                        [currViewPort.min(slices{3}(i))/max_int currViewPort.max(slices{3}(i))/max_int],...
                        [0 1],currViewPort.gamma(slices{3}(i)));
                    R = R + adjImg*selectedColorsLUT(i, 1);
                    G = G + adjImg*selectedColorsLUT(i, 2);
                    B = B + adjImg*selectedColorsLUT(i, 3);
                end
            end
        else
            if numel(slices{3}) > 3
                R = imadjust(sImg(:,:,1),[currViewPort.min(1)/max_int currViewPort.max(1)/max_int],[0 1],currViewPort.gamma(1));
                G = imadjust(sImg(:,:,2),[currViewPort.min(2)/max_int currViewPort.max(2)/max_int],[0 1],currViewPort.gamma(2));
                B = imadjust(sImg(:,:,3),[currViewPort.min(3)/max_int currViewPort.max(3)/max_int],[0 1],currViewPort.gamma(3));
            elseif numel(slices{3}) == 3
                R = imadjust(sImg(:,:,1),...
                    [currViewPort.min(slices{3}(1))/max_int currViewPort.max(slices{3}(1))/max_int],...
                    [0 1],currViewPort.gamma(slices{3}(1)));
                G = imadjust(sImg(:,:,2),...
                    [currViewPort.min(slices{3}(2))/max_int currViewPort.max(slices{3}(2))/max_int],...
                    [0 1],currViewPort.gamma(slices{3}(2)));
                B = imadjust(sImg(:,:,3),...
                    [currViewPort.min(slices{3}(3))/max_int currViewPort.max(slices{3}(3))/max_int],...
                    [0 1],currViewPort.gamma(slices{3}(3)));
            elseif numel(slices{3}) == 2
                if obj.I{obj.Id}.colors == 3 || slices{3}(end) < 4
                    if slices{3}(1) ~= 1
                        R = zeros(size(sImg,1),size(sImg,2),class(sImg));
                        G = imadjust(sImg(:,:,1),...
                            [currViewPort.min(slices{3}(1))/max_int currViewPort.max(slices{3}(1))/max_int],...
                            [0 1],currViewPort.gamma(slices{3}(1)));
                        B = imadjust(sImg(:,:,2),...
                            [currViewPort.min(slices{3}(2))/max_int currViewPort.max(slices{3}(2))/max_int],...
                            [0 1],currViewPort.gamma(slices{3}(2)));
                    elseif slices{3}(2) ~= 2
                        R = imadjust(sImg(:,:,1),...
                            [currViewPort.min(slices{3}(1))/max_int currViewPort.max(slices{3}(1))/max_int],...
                            [0 1],currViewPort.gamma(slices{3}(1)));
                        G = zeros(size(sImg,1),size(sImg,2),class(sImg));
                        B = imadjust(sImg(:,:,2),...
                            [currViewPort.min(slices{3}(2))/max_int currViewPort.max(slices{3}(2))/max_int],...
                            [0 1],currViewPort.gamma(slices{3}(2)));
                    else
                        R = imadjust(sImg(:,:,1),...
                            [currViewPort.min(slices{3}(1))/max_int currViewPort.max(slices{3}(1))/max_int],...
                            [0 1],currViewPort.gamma(slices{3}(1)));
                        G = imadjust(sImg(:,:,2),...
                            [currViewPort.min(slices{3}(2))/max_int currViewPort.max(slices{3}(2))/max_int],...
                            [0 1],currViewPort.gamma(slices{3}(1)));
                        B = zeros(size(sImg,1),size(sImg,2),class(sImg));
                    end
                else
                    R = imadjust(sImg(:,:,1),...
                    [currViewPort.min(slices{3}(1))/max_int currViewPort.max(slices{3}(1))/max_int],...
                            [0 1],currViewPort.gamma(slices{3}(1)));
                    G = imadjust(sImg(:,:,2),...
                        [currViewPort.min(slices{3}(2))/max_int currViewPort.max(slices{3}(2))/max_int],...
                        [0 1],currViewPort.gamma(slices{3}(2)));
                    B = zeros(size(sImg,1),size(sImg,2),class(sImg));
                end
            elseif numel(slices{3}) == 1  % show in greyscale
                    R = imadjust(sImg(:,:,1),...
                        [currViewPort.min(slices{3}(1))/max_int currViewPort.max(slices{3}(1))/max_int],...
                        [0 1],currViewPort.gamma(slices{3}(1)));
                    G = R;
                    B = R;
            end
        end
end

if isnan(sOver1(1,1,1)) == 0   % segmentation model
    sList = obj.I{obj.Id}.modelMaterialNames;
    T = obj.preferences.mibModelTransparencySlider; % transparency for the segmentation model
    if obj.I{obj.Id}.modelType ~= 127 && obj.I{obj.Id}.modelType ~= 32767
        over_type = obj.mibSegmShowTypePopup;  % if 1=filled, 2=contour
        M = sOver1;   % Model
        selectedObject = obj.I{obj.Id}.getSelectedMaterialIndex;  % selected model object
        
        if over_type == 2       % see model as a countour
            if obj.showAllMaterials == 1 % show all materials
                M2 = zeros(size(M),'uint8');
                for ind = 1:numel(sList)
                    M3 = zeros(size(M2),'uint8');
                    M3(M==ind) = 1;
                    M3 = bwperim(M3);
                    M2(M3==1) = ind;
                end
                M = M2;
            elseif selectedObject > 0
                ind = selectedObject;    % only selected
                M2 = zeros(size(M),'uint8');
                M2(M==ind) = 1;
                M = bwperim(M2)*ind;
            end
        end
        
        if obj.showAllMaterials == 1 % show all materials
             % simple example of the following code
%             A = ones(3);
%             B = randi(3, 3);
%             C = [2 4 6];
%             
%             % fast option
%             D1 = A(:,:) .* C(B(:,:));
%             
%             % slow option
%             for i=1:size(A,1)
%                 for j=1:size(A,2)
%                     D2(i,j) = A(i,j)*C(B(i,j));
%                 end
%             end
            
            modIndeces = find(M~=0);  % generate list of points that have elements of the model
            if numel(modIndeces) > 0
                switch class(R)     % generate list of colors for the materials of the model
                    case 'uint8';   modColors = uint8(obj.I{obj.Id}.modelMaterialColors*colorScale);
                    case 'uint16';  modColors = uint16(obj.I{obj.Id}.modelMaterialColors*colorScale);
                    case 'uint32';  modColors = uint32(obj.I{obj.Id}.modelMaterialColors*colorScale);
                end
                if obj.I{obj.Id}.modelType <= 65535
                    R(modIndeces) = R(modIndeces)*T + modColors(M(modIndeces),1) * (1-T);
                    G(modIndeces) = G(modIndeces)*T + modColors(M(modIndeces),2) * (1-T);
                    B(modIndeces) = B(modIndeces)*T + modColors(M(modIndeces),3) * (1-T);
                else
                    colorId = mod(M(modIndeces)-1, 65535)+1;
                    R(modIndeces) = R(modIndeces)*T + modColors(colorId, 1) * (1-T);
                    G(modIndeces) = G(modIndeces)*T + modColors(colorId, 2) * (1-T);
                    B(modIndeces) = B(modIndeces)*T + modColors(colorId, 3) * (1-T);
                end
            end
        elseif selectedObject > 0
            i = selectedObject;
            pntlist = find(M==i);
            if obj.I{obj.Id}.modelType > 65535
                i = mod(i-1, 65535)+1;  % modify color index
            end
            if ~isempty(pntlist)
                R(pntlist) = R(pntlist)*T+obj.I{obj.Id}.modelMaterialColors(i,1)*colorScale*(1-T);
                G(pntlist) = G(pntlist)*T+obj.I{obj.Id}.modelMaterialColors(i,2)*colorScale*(1-T);
                B(pntlist) = B(pntlist)*T+obj.I{obj.Id}.modelMaterialColors(i,3)*colorScale*(1-T);
            end
        end
    elseif obj.I{obj.Id}.modelType ~= 127 || obj.I{obj.Id}.modelType ~= 32767
        maximum = max(max(sOver1));
        coef = double(1 + 255/maximum*(1-T));
        R = zeros(size(R), 'uint8');
        R(sOver1 < 0) = uint8(abs(sOver1(sOver1 < 0)))*coef; %*T+255*(1-T));
        B = zeros(size(B), 'uint8');
        B(sOver1 > 0) = uint8(sOver1(sOver1 > 0))*coef; %*T+255*(1-T));
    end
end


T1 = obj.preferences.mibSelectionTransparencySlider; % transparency for selection

% add the mask layer
if isnan(sOver2(1,1,1)) == 0
    T2 = obj.preferences.mibMaskTransparencySlider; % transparency for mask
    over_type = 2; %get(handles.segmShowTypePopup,'Value');  % if 1=filled, 2=contour
    %T1 = 0.65;    % transparency for mask model
    
    ind = 1;    % index
    if over_type == 2       % see model as a countour
        M = bwperim(sOver2); % mask
    else
        M = sOver2;   % mask
    end
    
    pntlist = find(M==ind);
    if ~isempty(pntlist)
        R(pntlist) = R(pntlist)*T2+obj.preferences.maskcolor(1)*colorScale*(1-T2);
        G(pntlist) = G(pntlist)*T2+obj.preferences.maskcolor(2)*colorScale*(1-T2);
        B(pntlist) = B(pntlist)*T2+obj.preferences.maskcolor(3)*colorScale*(1-T2);
    end
end

% put a selection area on a top
if ~isnan(selectionModel(1))
    pnt_list = find(selectionModel==1);
    R(pnt_list) = R(pnt_list)*T1+obj.preferences.selectioncolor(1)*colorScale*(1-T1);
    G(pnt_list) = G(pnt_list)*T1+obj.preferences.selectioncolor(2)*colorScale*(1-T1);
    B(pnt_list) = B(pnt_list)*T1+obj.preferences.selectioncolor(3)*colorScale*(1-T1);
end
imgRGB = cat(3, R, G, B);

% upscale image now for magnificationFactor < 1
if magnificationFactor < 1 && panModeException == 0
    if strcmp(imageResizeMethod,'nearest') ||  strcmp(colortype, 'indexed') % tweak to make resizing faster in the nearest mode, may result in different image sizes compared to imresize method
        imgRGB = imgRGB(round(.51:magnificationFactor:end+.49),round(.51:magnificationFactor:end+.49),:);     % NOTE! the image size may be different from the imresize method
    else
        imgRGB = imresize(imgRGB, 1/magnificationFactor, imageResizeMethod);
    end
end

% % add Lines3D to the figure
if obj.mibShowLines3DCheck && obj.I{obj.Id}.hLines3D.noTrees > 0
    pixBox(5:6) = [sliceToShowIdx sliceToShowIdx];            % [xmin xmax ymin ymax zmin zmax]
    if options.blockModeSwitch == 1
        [pixBox(3), pixBox(4), pixBox(1), pixBox(2)] = obj.I{obj.Id}.getCoordinatesOfShownImage();    % [yMin, yMax, xMin, xMax]
    else
        [datasetHeight, datasetWidth] = obj.I{obj.Id}.getDatasetDimensions('image', NaN, NaN, options);
        pixBox(1) = 1;
        pixBox(2) = datasetWidth;
        pixBox(3) = 1;
        pixBox(4) = datasetHeight;
    end
    
    bb = obj.I{obj.Id}.getBoundingBox();
    BoxOut = pixBox;
    if obj.I{obj.Id}.orientation == 4   % xy
        BoxOut(1:2) = pixBox(1:2)*obj.I{obj.Id}.pixSize.x + bb(1) - obj.I{obj.Id}.pixSize.x;
        BoxOut(3:4) = pixBox(3:4)*obj.I{obj.Id}.pixSize.y + bb(3) - obj.I{obj.Id}.pixSize.y;
        BoxOut(5:6) = pixBox(5:6)*obj.I{obj.Id}.pixSize.z + bb(5) - obj.I{obj.Id}.pixSize.z;
    elseif obj.I{obj.Id}.orientation == 1   % zx
        BoxOut(1:2) = pixBox(1:2)*obj.I{obj.Id}.pixSize.z + bb(5) - obj.I{obj.Id}.pixSize.z;
        BoxOut(3:4) = pixBox(3:4)*obj.I{obj.Id}.pixSize.x + bb(1) - obj.I{obj.Id}.pixSize.x;
        BoxOut(5:6) = pixBox(5:6)*obj.I{obj.Id}.pixSize.y + bb(3) - obj.I{obj.Id}.pixSize.y;
    elseif obj.I{obj.Id}.orientation == 2   % xy
        BoxOut(1:2) = pixBox(1:2)*obj.I{obj.Id}.pixSize.z + bb(5) - obj.I{obj.Id}.pixSize.z;
        BoxOut(3:4) = pixBox(3:4)*obj.I{obj.Id}.pixSize.y + bb(3) - obj.I{obj.Id}.pixSize.y;
        BoxOut(5:6) = pixBox(5:6)*obj.I{obj.Id}.pixSize.x + bb(1) - obj.I{obj.Id}.pixSize.x;
    end
    
    addLinesOptions.orientation = obj.I{obj.Id}.orientation;
    imgRGB = obj.I{obj.Id}.hLines3D.addLinesToImage(imgRGB, BoxOut, addLinesOptions);
end

% show annotations
if obj.mibShowAnnotationsCheck %% && obj.orientation == 4
    if obj.I{obj.Id}.hLabels.getLabelsNumber() >= 1
        % labelPos(index, z x y)
        if ~isfield(options, 'sliceNo')
            options.sliceNo = obj.I{obj.Id}.slices{obj.I{obj.Id}.orientation}(1);
        end
        [labelsList, labelValues, labelPos] = obj.I{obj.Id}.getSliceLabels(options.sliceNo);
        if isempty(labelsList); return; end
        if orientation == 4     % get ids of the correct vectors in the matrix, depending on orientation
            xId = 2;
            yId = 3;
        elseif orientation == 1
            xId = 1;
            yId = 2;        
        elseif orientation == 2
            xId = 1;
            yId = 3;
        end
        if options.blockModeSwitch == 0 % full image
            if strcmp(options.resize, 'no') % this needed for snapshots
                pos(:,1) = ceil(labelPos(:,xId));
                pos(:,2) = ceil(labelPos(:,yId));
            else
                pos(:,1) = ceil(labelPos(:,xId)/max([magnificationFactor 1]));
                pos(:,2) = ceil(labelPos(:,yId)/max([magnificationFactor 1]));
            end
            if isnan(options.markerType)
                addTextOptions.markerText = 'marker';
            else
                addTextOptions.markerText = options.markerType;
            end
        else
            [axesX, axesY] = obj.getAxesLimits();
            if strcmp(options.resize, 'no')     % this needed for snapshots
                pos(:,1) = ceil((labelPos(:,xId) - max([0 floor(axesX(1))])) );     % - .999/obj.magFactor subtract 1 pixel to put a marker to the left-upper corner of the pixel
                pos(:,2) = ceil((labelPos(:,yId) - max([0 floor(axesY(1))])) );
            else
                pos(:,1) = ceil((labelPos(:,xId) - max([0 floor(axesX(1))])) / magnificationFactor);% - .999/obj.magFactor);     % - .999/obj.magFactor subtract 1 pixel to put a marker to the left-upper corner of the pixel
                pos(:,2) = ceil((labelPos(:,yId) - max([0 floor(axesY(1))])) / magnificationFactor);% - .999/obj.magFactor);
            end
            if strcmp(obj.mibAnnMarkerEdit, 'marker')  % show only a marker
                addTextOptions.markerText = 'marker';
            else
                addTextOptions.markerText = 'both';
            end
        end
        addTextOptions.color = obj.preferences.annotationColor;
        addTextOptions.fontSize = obj.preferences.annotationFontSize;
        
        switch obj.mibAnnMarkerEdit
            case 'value'
                modString = sprintf('%c.%df', '%', obj.mibAnnValuePrecision);
                labelsList = arrayfun(@(a) sprintf(modString, a), labelValues, 'UniformOutput', 0);
            case 'label + value'
                if obj.mibAnnValueEccentricCheck == 0
                    modString = sprintf('%cs: %c.%df', '%', '%', obj.mibAnnValuePrecision);
                    labelsList = cellfun(@(a, b) sprintf(modString, a, b), labelsList, num2cell(labelValues), 'UniformOutput', 0);
                else
                    modString = sprintf('%c.%df: %cs', '%', obj.mibAnnValuePrecision, '%');
                    labelsList = cellfun(@(a, b) sprintf(modString, a, b), num2cell(labelValues), labelsList, 'UniformOutput', 0);
                end
        end
        imgRGB = mibAddText2Img(imgRGB, labelsList, pos, addTextOptions);
    end
end
end