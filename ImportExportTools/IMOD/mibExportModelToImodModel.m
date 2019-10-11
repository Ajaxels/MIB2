function [Model, selection] = mibExportModelToImodModel(O, Options)
% function [Model, selection] = mibExportModelToImodModel(O, Options)
% Export model to Imod model type
%
% @note Requires matTomo function sets
% 
% Parameters:
% O: -> a model [1:height,1:width,1:thickness]
% Options: -> options structure:
%  - .modelFilename - filename to save the model, use 'mod' extension.
%  - .pixSize.x - physical width of the voxels
%  - .pixSize.y - physical height of the voxels
%  - .pixSize.z - physical thickness of the voxels
%  - .xyScaleFactor - a number to indicate a step when picking voxels from the contours of materials, when 5 - take each 5th point
%  - .zScaleFactor - a number to indicate a Z step when picking voxels from the contours of materials, when 1 - take each z-section
%  - .colorList -  a matrix with colors for the materials as [materialId][Red, Green, Blue], (0-1)
%  - .ModelMaterialNames - a cell array with names of materials
%  - .generateSelectionSw - when @b 1 generate the 'Selection layer' with the used for the model points
%  - .showWaitbar - if @b 1 - show the wait bar, if @b 0 - do not show
%
% Return values:
% Model: -> IMOD model object
% selection: -> selection layer for im_browser [1:height,1:width,1:thickness]

% Copyright (C) 23.05.2011 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 11.04.2016, IB, added showWaitbar option

if ~isfield(Options, 'showWaitbar'); Options.showWaitbar = 1; end

% create IMOD model
modelFilename = Options.modelFilename;

O = permute(O, [2 1 3]);
width = size(O,1);
height = size(O,2);
thickness = size(O,3);

selection = zeros(size(O),'uint8');

Model = ImodModel();
Model = setFilename(Model, modelFilename);
Model = setMax(Model, [width, height, thickness]);
Model = setPixelSize(Model, Options.pixSize.x);
Model = setYScale(Model, Options.pixSize.y/Options.pixSize.x);
Model = setZScale(Model, Options.pixSize.z/Options.pixSize.x);

% O - is an model
Objects = unique(O);
Objects(Objects==0) = [];
noObjects = numel(Objects);
if Options.showWaitbar
    curInt = get(0, 'DefaulttextInterpreter'); 
    set(0, 'DefaulttextInterpreter', 'none'); 
    wb = waitbar(0,sprintf('%s\nPlease wait...',modelFilename),'Name','Saving contours to IMOD model...','WindowStyle','modal');
    set(findall(wb,'type','text'),'Interpreter','none');
    waitbar(0, wb);
end

for objectLoop=1:noObjects  % first loop for number of objects in the model
    object = Objects(objectLoop);

    imodObject = ImodObject;
    imodObject = setColor(imodObject, Options.colorList(objectLoop,:));
    imodObject = setType(imodObject, 'closed');
    imodObject = setName(imodObject, Options.ModelMaterialNames{objectLoop});
    
    BW = zeros(size(O),'uint8');
    BW(O==object) = 1;
    CC = bwconncomp(BW, 6);
    
    for subobject = 1:CC.NumObjects     % loop within individual 3d objects within the object
        BWtemp = zeros(size(BW),'uint8'); 
        BWtemp(CC.PixelIdxList{subobject}) = 1;
        
        for z=1:Options.zScaleFactor:thickness   % calclulate contours
            if isempty(find(BWtemp(:,:,z)==1,1)); continue; end;    % there is no object on the current layer
            
            img = BWtemp(:,:,z);
            img = bwperim(img);     % get perimeter
            
            CC2 = bwconncomp(img,8);
            for contourId=1:CC2.NumObjects
                [start_pnt1(1), start_pnt1(2)] = ind2sub([width height],CC2.PixelIdxList{contourId}(1));    % convert it to Y,X
                contour = bwtraceboundary(img, start_pnt1,'NE');
                if size(contour,1) < Options.xyScaleFactor; continue; end;  % contour is too small
                contour = contour([1:Options.xyScaleFactor:end end], :);   % scale contour in XY
                %contour = contour(1:Options.xyScaleFactor:end, :);   % scale contour in XY
                contourOut = ones(size(contour,1),1)*(z-1);     % generate z index
                contourOut = [contour contourOut]';          % generate [x y z] type of coordinates

%                 bb = [4.24892 6.73643 0.88742 3.77827 0.00000 2.22000];
%                 contourOut(:,1) = contourOut(:,1)+bb(1)/Options.pixSize.x;
%                 contourOut(:,2) = contourOut(:,2)+bb(3)/Options.pixSize.y;
%                 contourOut(:,3) = contourOut(:,3)+bb(5)/Options.pixSize.z;
                
                if Options.generateSelectionSw
                    for ind=1:size(contour,1)
                        selection(contour(ind,1),contour(ind,2),z)=1;
                    end
                end;
                imodContour = ImodContour(contourOut);      % create new contour from points
                imodContour = setSurfaceIdx(imodContour, subobject);    % set surface index
                imodObject = appendContour(imodObject, imodContour);     % add contour to the object
                %imodObject = setContour(imodObject, imodContour, contourIndex);     % add contour to the object
                %contourIndex = contourIndex + 1;    % increase counter index
            end
        end
    end
    Model = appendObject(Model, imodObject);
    if Options.showWaitbar;     waitbar(objectLoop/noObjects,wb); end;
end
write(Model, Options.modelFilename);
selection = permute(selection, [2 1 3]);
if Options.showWaitbar; 
    delete(wb);
    set(0, 'DefaulttextInterpreter', curInt);
end
end