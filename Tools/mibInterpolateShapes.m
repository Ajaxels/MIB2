function [img, boundingBox] = mibInterpolateShapes(img, max_pnts)
% function [img, boundingBox] = mibInterpolateShapes(img, max_pnts)
% Interpolate the shapes between the slices
%
% One of two interpolation methods. The interpolation method can be
% selected in @em MIB->File->Preferences. 
% @note This method can interpolate only the @b filled shapes.
%
% Parameters:
% img: -> binary image dataset, for example the 'Selection' layer [1:height, 1:width, 1:z]
% max_pnts: -> maximal number of points used for interpolation. 
%
% Return values:
% img: -> binary image dataset, for example the 'Selection' layer [1:height, 1:width, 1:z]
% boundingBox: -> a bounding box of the area that was used to calculate interpolation, [xMin, xMax, yMin, yMax, zMin, zMax]
% @see ib_interpolateLines

% Copyright (C) 15.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

%O = load('interp_test.mat');
%img = O.Amira_SemImage_cell_labels_pure_mat;  % frames 1 & 8

width = size(img,2);
height = size(img,1);

if nargin < 2;     max_pnts = 140; end
boundingBox = [];

bb = nan([size(img,3), 4]);     % allocate space for slices
cent = nan([size(img,3), 2]);     % allocate space for slices
slices = [];    % indices of slices that have shapes

for i=1:size(img,3)
    STATS = regionprops(img(:,:,i),'Centroid', 'BoundingBox');
    if ~isempty(STATS)
        bb(i, :) = STATS.BoundingBox;
        cent(i, :) = STATS.Centroid;
        slices = [slices i];
    end
end

if isempty(slices) || numel(slices) == 1; return; end

% find borders for the bounding box
minX = ceil(min(bb(slices, 1)));
minY = ceil(min(bb(slices, 2)));
maxX = floor(max(bb(slices, 3)+bb(slices, 1)));
maxY = floor(max(bb(slices, 4)+bb(slices, 2)));
% shift centroids
cent(:,1) = cent(:,1)-minX;
cent(:,2) = cent(:,2)-minY;

for ind = 2:numel(slices)
    sl_id1 = slices(ind-1);     % number of the 1st slice with shape
    sl_id2 = slices(ind);       % number of the 2nd slice with shape
    if sl_id1 == sl_id2 - 1; continue; end;     % do not consider consecutive slices
    bw1 = bwperim(img(minY:maxY, minX:maxX, sl_id1));  % get first shape
    bw2 = bwperim(img(minY:maxY, minX:maxX, sl_id2));    % get second shape
    
    
    % get centroids to estimate starting point for perimeter trace
    Cent1 = round(cent(sl_id1, :));
    Cent2 = round(cent(sl_id2, :));

    if ~isempty(find(bw1(1:Cent1(2),Cent1(1))==1,1)) && ~isempty(find(bw2(1:Cent2(2),Cent2(1))==1,1)) % take northern points from centroids on both shapes
        start_pnt1 = [find(bw1(1:Cent1(2),Cent1(1))==1,1), Cent1(1)];
        start_pnt2 = [find(bw2(1:Cent2(2),Cent2(1))==1,1), Cent2(1)];
    elseif ~isempty(find(bw1(Cent1(2):end,Cent1(1))==1,1)) && ~isempty(find(bw2(Cent2(2):end,Cent2(1))==1,1)) % take southern  points from centroids on both shapes
        start_pnt1 = [find(bw1(Cent1(2):end,Cent1(1))==1,1)+Cent1(2)-1, Cent1(1)];
        start_pnt2 = [find(bw2(Cent2(2):end,Cent2(1))==1,1)+Cent2(2)-1, Cent2(1)];
    elseif ~isempty(find(bw1(1:Cent1(2),Cent1(1))==1,1)) && ~isempty(find(bw2(Cent2(2):end,Cent2(1))==1,1))  % take northern points
        start_pnt1 = [find(bw1(1:Cent1(2),Cent1(1))==1,1), Cent1(1)];
        start_pnt2 = [find(bw2(Cent2(2):end,Cent2(1))==1,1)+Cent2(2)-1, Cent2(1)];
    elseif ~isempty(find(bw1(Cent1(2):end,Cent1(1))==1,1)) && ~isempty(find(bw2(1:Cent2(2),Cent2(1))==1,1))  % take southern points
        start_pnt1 = [find(bw1(Cent1(2):end,Cent1(1))==1,1)+Cent1(2)-1, Cent1(1)];
        start_pnt2 = [find(bw2(1:Cent2(2),Cent2(1))==1,1), Cent2(1)];
    end
    
    % %pixel_id = min(find(bw1==1));    % find a point on a first shape
    %pixel_id = find(bw1==1,1);        % find a point on a first shape
    %[start_pnt1(1), start_pnt1(2)] = ind2sub([height width],pixel_id);    % convert it to Y,X
    
    %STATS_2 = regionprops(bw2, 'PixelList');    % get pixel info of the second perimeter
    %[~,sorted_dist_id] = sort(sqrt((STATS_2.PixelList(:,1)-start_pnt1(2)).^2+(STATS_2.PixelList(:,2)-start_pnt1(1)).^2)); % get the closest point
    %start_pnt2(1) = STATS_2.PixelList(sorted_dist_id(1),2); % get Y
    %start_pnt2(2) = STATS_2.PixelList(sorted_dist_id(1),1); % get X
    
    %contour1 = bwtraceboundary(bw1, start_pnt1, 'E', 8, Inf, 'clockwise');
    %contour2 = bwtraceboundary(bw2, start_pnt2, 'E', 8, Inf, 'clockwise');
    
    contour1 = bwtraceboundary(bw1, start_pnt1,'NE');
    contour2 = bwtraceboundary(bw2, start_pnt2,'NE');
    
    step1 = size(contour1,1)/max_pnts;   % step for the 1st perimeter
    step2 = size(contour2,1)/max_pnts;   % step for the 2nd perimeter
    if step1 < 1 || step2 < 1
        max_pnts_current = min([size(contour1,1) size(contour2,1)]);
        indeces1 = round(linspace(1,size(contour1,1),max_pnts_current));    % generate indeces of the vertices to interpolate for contour1
        indeces2 = round(linspace(1,size(contour2,1),max_pnts_current));    % generate indeces of the vertices to interpolate for contour2
    else
        indeces1 = round(linspace(1,size(contour1,1),max_pnts));    % generate indeces of the vertices to interpolate for contour1
        indeces2 = round(linspace(1,size(contour2,1),max_pnts));    % generate indeces of the vertices to interpolate for contour2
    end
    
    contour1 = contour1(indeces1,:);
    contour2 = contour2(indeces2,:);
    min_pnt_number = min([size(contour1,1) size(contour2,1)]);  % find minimal number of points on contours
    contour1 = contour1(1:min_pnt_number,:);     % trim the contour
    contour2 = contour2(1:min_pnt_number,:);     % trim the contour
    
    if size(contour1,1) ~= size(contour2,1)     % some check for wrong number of points on countours
        continue;
    end
%     if(~isempty(contour1))
%         figure(1)
%         imshow(img(:,:,slices(ind-1)),[]);
%         hold on;
%         %plot(contour(1:5:end,2),contour(1:5:end,1),'g.');
%         plot(contour1(:,2),contour1(:,1),'g.',start_pnt1(2),start_pnt1(1),'.r');
%         hold off;
%         figure(2)
%         imshow(img(:,:,slices(ind)),[]);
%         hold on;
%         %plot(contour(1:5:end,2),contour(1:5:end,1),'g.');
%         plot(contour2(:,2),contour2(:,1),'g.',start_pnt2(2),start_pnt2(1),'.r');
%         hold off;
%     end
    
    contour = interp_points(contour1, contour2, sl_id1, sl_id2);
    % connect points in the intermediate slices
    for interm_slice = sl_id1+1:sl_id2-1
        img(minY:maxY, minX:maxX, interm_slice) = draw_2d_lines(img(minY:maxY, minX:maxX, interm_slice), contour(:, :, interm_slice-sl_id1+1));
    end
end
boundingBox = [minX, maxX, minY, maxY, min(slices), max(slices)];
end

function contour = interp_points(contour1, contour2, slice_id1, slice_id2)
% get interpolated points between two contours
% contour = interp_points(contour1, contour2, slice_id1, slice_id2)
% OUT: 
% contour -> coordinates of interpolated points between two known contours (point_id, [y x], slice)
% IN:
% contour1 -> first contour coordinates (point_id, [y x])
% contour2 -> second contour coordinates (point_id, [y x])
% slice_id1 -> number of the first slice
% slice_id2 -> number of the second slice

z_num = slice_id2 - slice_id1;

pointsNumber = size(contour1,1);

% calculate corresponding points on both contours
dispSum = zeros(pointsNumber,1);  % vector with total distance between all points
for pntNo=1:pointsNumber
    if pntNo==1
        contour2Tmp = contour2;
    else
        contour2Tmp = [contour2(pntNo:end,:); contour2(1:pntNo-1,:)];    
    end
    for pntNo2=1:pointsNumber
        dispSum(pntNo) = dispSum(pntNo)+(contour1(pntNo2,1)-contour2Tmp(pntNo2,1))^2+(contour1(pntNo2,2)-contour2Tmp(pntNo2,2))^2;
    end
end
[~, pos] = min(dispSum);   % find a global minimum for possible configurations of points
if pos~=1
    contour2 = [contour2(pos:end,:); contour2(1:pos-1,:)];
end


contour = zeros(pointsNumber, 2, z_num);
contour(:,1:2,slice_id1) = contour1;
contour(:,1:2,slice_id2) = contour2;

for pnt=1:size(contour1,1)
    p1 = contour1(pnt,:);
    p2 = contour2(pnt,:);
    
    dx = p2(2)-p1(2);
    dy = p2(1)-p1(1);
    step_x = dx/z_num;
    step_y = dy/z_num;
    for z_id = slice_id1+1:slice_id2-1
        x = p1(2) + step_x*(z_id-slice_id1);
        y = p1(1) + step_y*(z_id-slice_id1);
        contour(pnt,:, z_id-slice_id1+1) = [round(y); round(x)];
    end
end    
end

function img = draw_2d_lines(img,snake)
img_tmp = zeros(size(img),'uint8');
for pnt=1:size(snake,1)
    if pnt==1
        p1 = snake(size(snake,1),:);
        p2 = snake(pnt,:);
    else
        p1 = snake(pnt-1,:);
        p2 = snake(pnt,:);
    end
%     if p1(1) == 1499;
%         0
%     end
%     dv = p2 - p1;
%     nPnts = max(abs(dv));
%     linSpacing = linspace(0, 1, nPnts);
%     for i=1:nPnts
%         round(linSpacing(i)*dv(1))
%         img_tmp(p1(1) + round(linSpacing(i)*dv(1)), p1(2)+round(linSpacing(i)*dv(2))) = 1;
%     end
    
    if abs(p1(2)-p2(2)) > abs(p1(1)-p2(1))     % horizontal movement
        if p1(2) < p2(2)    % sorting by x
            X = [p1(2) p2(2)];
            Y = [p1(1) p2(1)];
        else
            X = [p2(2) p1(2)];
            Y = [p2(1) p1(1)];
        end
        dY = (Y(2)-Y(1))/(X(2)-X(1)+1);
        for x=X(1):X(2)
            y = ceil(Y(1) + (x-X(1))*dY);
            img_tmp(y,x) = 1;
        end
    else    % vertical movement
        if p1(1) < p2(1)
            X = [p1(2) p2(2)];
            Y = [p1(1) p2(1)];
        else
            X = [p2(2) p1(2)];
            Y = [p2(1) p1(1)];
        end
        dX = (X(2)-X(1))/(Y(2)-Y(1)+1);
        for y=Y(1):Y(2)
            x = ceil(X(1) + (y-Y(1))*dX);
            img_tmp(y,x) = 1;
        end
    end
%     figure(1)
%     imshow(img_tmp,[]);
%     p1
%     p2
%     waitforbuttonpress
end
img_tmp = imfill(img_tmp,'holes');
img = img_tmp | img;
end
