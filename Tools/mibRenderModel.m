function p = mibRenderModel(Volume, Index, pixSize, boundingBox, color_list, Image, Options)
% function p = mibRenderModel(Volume, Index, pixSize, color_list, Image)
% Render a model using isosurfaces
%
% Parameters:
% Volume: a model, [1:height, 1:width, 1:thickness] with materials
% Index: iso value, if @b 0 or @b NaN generate isosurfaces of all materials
% pixSize: structure with physical dimensions of voxels
%   - .x - physical width
%   - .y - physical height
%   - .z - physical thickness
%   - .units - physical units
% boundingBox: information of the bounding box of the dataset [xMin, xMax, yMin, yMax, zMin, zMax]
% color_list: [@em optional] -> list of colors for models (0-1), [materialIndex][Red, Green, Blue]
% Image: the image layer that is used to place an orthoslice
% Options: [@em optional] - a structure with parameters that are also asked inside the function
% @li .reduce - reduce the volume down to, width pixels [no volume reduction when 0]
% @li .smooth - smoothing 3d kernel, width (no smoothing when 0)
% @li .maxFaces - maximal number of faces (no limit when 0)
% @li .slice - show orthoslice (enter a number slice number, or NaN)
% @li .exportToImaris - an optional switch to export the model to Imaris
% @li .modelMaterialNames - a cell array for material names
%
% Return values:
% p: triangulated patch defined by FV (a structure with fields 'vertices'
% and 'faces')

% Copyright (C) 29.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 7
    prompt = {'Reduce the volume down to, width pixels [no volume reduction when 0]?',...
        'Smoothing 3d kernel, width (no smoothing when 0):',...
        'Maximal number of faces (no limit when 0):',...
        'Show orthoslice (enter a number slice number, or NaN, or 0):'};
    dlg_title = 'Isosurface parameters';
    
    if size(Volume,2) > 500
        resizeText = '500';
    else
        resizeText = '0';
    end
    
    if isnan(Image(1))
        def = {resizeText,'5','300000','NaN'};
    else
        def = {resizeText,'5','300000','1'};
    end
    answer = inputdlg(prompt,dlg_title,1,def);
    if isempty(answer); return;  end
    
    Options.reduce = str2double(answer{1});
    Options.smooth = str2double(answer{2});
    Options.maxFaces = str2double(answer{3});
    Options.slice = str2double(answer{4});
    Options.modelMaterialNames = repmat(cellstr('Material'), [max(max(max(Volume))), 1]);
    Options.exportToImaris = 0;
    if isnan(Options.slice); Options.slice = 0; end
end
if ~isfield(Options, 'exportToImaris'); Options.exportToImaris = 0; end
if ~isfield(Options, 'modelMaterialNames'); Options.modelMaterialNames = repmat(cellstr('Material'), [max(max(max(Volume))), 1]); end

if nargin < 6   % initialize Image
    Image = NaN;
end
    
if nargin < 5   % generate random color list
    for i=1:255
        color_list(i,:) = [rand(1) rand(1) rand(1)];
    end
end

wb = waitbar(0, 'Smoothing the volume...','Name','Isosurface');
if isnan(Index); Index = 0; end
if Index==0
    Index = 1:numel(Options.modelMaterialNames);
end

bb = boundingBox;

if Options.reduce ~= 0
    factorX=ceil(size(Volume,2)/Options.reduce);
    factorY=ceil(factorX*pixSize.x/pixSize.y-.001);
    factorZ=ceil(factorX*pixSize.x/pixSize.z);
else
    factorX=1;
    factorY=1;
    factorZ=1;
end

kernelX = Options.smooth;
kernelY = round(kernelX*pixSize.x/pixSize.y) + abs(mod(round(kernelX*pixSize.x/pixSize.y),2)-1);
kernelZ = round(kernelX*pixSize.x/pixSize.z) + abs(mod(round(kernelX*pixSize.x/pixSize.z),2)-1);

fig = figure(12347);
set(gcf, 'Renderer', 'opengl');
clf;
%daspect([pixSize.x/pixSize.x/factorX pixSize.x/pixSize.y/factorY pixSize.x/pixSize.z/factorZ]);
daspect([1 1 1]);
maxIndex = numel(Index);

for contIndex = Index
    subVolume = Volume==contIndex;

    % smooth the volume
    if kernelX ~= 0
        waitbar(0.2*contIndex/maxIndex, wb,  sprintf('Material %d: Smoothing the surface...', contIndex));
        subVolume = uint8(smooth3(subVolume, 'box', [kernelX kernelY kernelZ]));
    end
    waitbar(0.4*contIndex/maxIndex, wb,  sprintf('Material %d: Reducing the volume...', contIndex));
    [~,~,~,subVolume] = reducevolume(subVolume,[factorX,factorY,factorZ]);
    waitbar(0.6*contIndex/maxIndex, wb,  sprintf('Material %d: Generating isosurface...', contIndex));
    [faces, verts] = isosurface(subVolume,0.5);
    if isempty(verts); continue; end
    
    verts(:,1) = verts(:,1)*pixSize.x*factorX + bb(1) - pixSize.x*factorX;
    verts(:,2) = verts(:,2)*pixSize.y*factorY + bb(3) - pixSize.y*factorY;
    verts(:,3) = verts(:,3)*pixSize.z*factorZ + bb(5) - pixSize.z*factorZ;
    
    disp(['Object ' num2str(contIndex) ' (before reduction of faces): N faces=' num2str(size(faces,1)) ', N vertices=' num2str(size(verts,1))]);
    waitbar(0.8*contIndex/maxIndex, wb,  sprintf('Material %d: Rendering...', contIndex));
    p(contIndex) = patch('Faces',faces, 'Vertices', verts, ...
        'FaceColor', color_list(contIndex,:), 'EdgeColor', 'none');
    if Options.maxFaces ~= 0
        waitbar(0.9*contIndex/maxIndex, wb,  sprintf('Material %d: Reducing number of faces...', contIndex));
        reducepatch(p(contIndex), Options.maxFaces);
    end
    set(p(contIndex),'AmbientStrength',.3);
    
    if Options.exportToImaris == 1
        surface.faces = p(contIndex).Faces;
        surface.vertices = p(contIndex).Vertices;
        options.color = color_list(contIndex,:);
        if isfield(Options, 'modelMaterialNames')
            options.name = Options.modelMaterialNames{contIndex};
        end
        mibSetImarisSurface(surface, [], options);
    end
    
end

% calculate ticks
% see more on placing grid values:
% http://stackoverflow.com/questions/361681/algorithm-for-nice-grid-line-intervals-on-a-graph
% xlim = get(gca, 'xlim');
% %minVal = xlim(1) * pixSize.x*factorX;
% %maxVal = xlim(2) * pixSize.x*factorX;
% %range = maxVal-minVal;
% exponent = floor(log10(range));
% gridStep = power(10, exponent);
% noGridsAxes = gridStep/(pixSize.x*factorX);
% labels = xlim(1):noGridsAxes:xlim(2);
% labelsUnits = labels * pixSize.x*factorX;
% set(gca,'XTickLabel',num2str(labelsUnits'));
% set(gca,'XTick',labels);

% ylim = get(gca, 'ylim');
% %minVal = ylim(1) * pixSize.y*factorY;
% %maxVal = ylim(2) * pixSize.y*factorY;
% %range = maxVal-minVal;
% exponent = floor(log10(range));
% gridStep = power(10, exponent);
% noGridsAxes = gridStep/(pixSize.y*factorY);
% labels = ylim(1):noGridsAxes:ylim(2);
% labelsUnits = labels * pixSize.y*factorY;
% set(gca,'YTickLabel',num2str(labelsUnits'));
% set(gca,'YTick',labels);

% zlim = get(gca, 'zlim');
% %minVal = zlim(1) * pixSize.z*factorZ;
% %maxVal = zlim(2) * pixSize.z*factorZ;
% %range = maxVal-minVal;
% exponent = floor(log10(range));
% gridStep = power(10, exponent);
% noGridsAxes = gridStep/(pixSize.z*factorZ);
% labels = zlim(1):noGridsAxes:zlim(2);
% labelsUnits = labels * pixSize.z*factorZ;
% set(gca,'ZTickLabel',num2str(labelsUnits'));
% set(gca,'ZTick',labels);

set(gca,'projection','perspective');
lighting gouraud;
camlight('headlight');
axis tight;
grid;
view3d(fig, 'rot');

% add an orthoslice
if Options.slice ~= 0
    Options.slice = max([Options.slice 1]);     % remove negatives and 0s
    hold on;
    img = zeros([size(subVolume,1), size(subVolume,2), size(Image, 3)], class(Image)); %#ok<ZEROLIKE>
    % tweak for a situation, when Image-> is not a Z-stack
    if size(Image, 4) > 1
        zIndex = Options.slice;
    else
        zIndex = 1;
    end
    for c=1:size(Image, 3)
        img(:,:,c) = imresize(Image(:, :, c, zIndex), [size(subVolume,1) size(subVolume,2)], 'bicubic');
    end
    
    if size(Image, 3) == 2
        img(:,:,3) = zeros([size(img, 1) size(img, 2)], class(Image)); %#ok<ZEROLIKE>
    elseif size(Image, 3) > 3
        img = img(:,:,1:3);
    end
    
    %img = imadjust(img,[0 1], [0.3 1]);
    xValue = deal(bb(1):(bb(2)-bb(1))/size(img,2):bb(2));
    xValue = xValue(1:end-1);
    yValue = deal(bb(3):(bb(4)-bb(3))/size(img,1):bb(4));
    yValue = yValue(1:end-1);
    [xValue, yValue] = meshgrid(xValue, yValue);
    
    zValue = Options.slice*pixSize.z+bb(5);
    surf(xValue, yValue, zValue+zeros([size(img, 1) size(img, 2)]), img, 'EdgeColor', 'none')
    colormap('gray');   
    hold off;
    % update the z-limits
    %zlim = get(gca, 'zlim');
    %set(gca, 'zlim', [1 zlim(2)]);
    %set(gca, 'zlim', [1 zlim(2)]);
end

set(gca,'GridAlpha',.5);    % set alpha value for the grid
set(gca,'color',[1 1 1 0]); % turn off background color for the grid
disp('Hint: render image to file with the following command:')
disp('print(''MIB-snapshot.tif'', ''-dtiff'', ''-r600'',''-opengl'');');
delete(wb);
end