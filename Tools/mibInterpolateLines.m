function img = mibInterpolateLines(img, max_pnts, lineWidth)
% function img = mibInterpolateLines(img, max_pnts, lineWidth)
% Interpolate lines between the slices
%
% One of two interpolation methods. The interpolation method can be
% selected in @em im_browser->File->Preferences. 
% @note This method can interpolate only the @b not closed lines.
%
% Parameters:
% img: -> binary image dataset, for example the 'Selection' layer [1:height, 1:width, 1:z]
% max_pnts: -> maximal number of points used for interpolation. 
% lineWidth: -> width of the line in pixels. 
%
% Return values:
% img: -> binary image dataset, for example the 'Selection' layer [1:height, 1:width, 1:z]
% @see ib_interpolateShapes

% Copyright (C) 16.08.2012 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% v1.01 06.03.2014, fixed the interpolation for the last slice in sequence
% and added removal of consecutive slices from interpolation
tic

if nargin < 3;     lineWidth = 4; end;
if nargin < 2;     max_pnts = 140; end;
SE = strel('disk', lineWidth-1, 0);

slices = []; % find slices with selection
for i=1:size(img,3);
    if find(img(:,:,i),1,'first')>0; % find slices with selection
        slices = [slices i]; %#ok<AGROW>
    end;
end;

for ind = 2:numel(slices)
    sl_id1 = slices(ind-1);     % number of the 1st slice with shape
    sl_id2 = slices(ind);       % number of the 2nd slice with shape
    if sl_id1 == sl_id2 - 1; continue; end;     % do not consider consecutive slices
    bw1 = img(:,:,sl_id1);      % get first shape
    bw2 = img(:,:,sl_id2);      % get second shape
    bw1 = bwmorph(bw1,'thin',Inf);  % convert to line
    bw2 = bwmorph(bw2,'thin',Inf);  % convert to line
    ends1 = bwmorph(bw1,'endpoints',Inf);  % find end points
    ends2 = bwmorph(bw2,'endpoints',Inf);  % find end points

    [r1, c1] = find(ends1 == 1, 2);
    [r2, c2] = find(ends2 == 1, 2);
    if size(r1,1) ~= 2 & size(r2,1) ~= 2
        msgbox('Wrong shape for the line interpolator!','Wrong shape','error');
        return;
    end;
    diff1 = (r1(1)-r2(1))^2 + (c1(1)-c2(1))^2;
    diff2 = (r1(1)-r2(2))^2 + (c1(1)-c2(2))^2;
    if diff1 <= diff2
        start_pnt1 = [r1(1) c1(1)];
        start_pnt2 = [r2(1) c2(1)];
    else
        start_pnt1 = [r1(1) c1(1)];
        start_pnt2 = [r2(2) c2(2)];
    end
    
    % trace contour
    contour1 = bwtraceboundary(bw1, start_pnt1, 'NE');
    contour2 = bwtraceboundary(bw2, start_pnt2, 'NE');  
    % since contour is closed shape, take only 1/2 of it
    contour1 = contour1(1:ceil(end/2),:);
    contour2 = contour2(1:ceil(end/2),:);
    
    step1 = size(contour1,1)/max_pnts;   % step for the 1st perimeter
    step2 = size(contour2,1)/max_pnts;   % step for the 2nd perimeter
    if step1 < 1 || step2 < 1
        max_pnts_current = min([size(contour1,1) size(contour2,1)]);
        step1 = size(contour1,1)/max_pnts_current;   % recalculate 1st step
        step2 = size(contour2,1)/max_pnts_current;   % recalculate 2nd step
        max_pnts = max_pnts_current - 1;
    end
    contour1out = zeros(max_pnts, 2);
    contour2out = zeros(max_pnts, 2);
    
    for i=1:max_pnts-1
        idx1 = round(step1*i);
        idx2 = round(step2*i);
        contour1out(i+1,:) = contour1(idx1,:);
        contour2out(i+1,:) = contour2(idx2,:);
    end
    %contour1out = contour1(1:step1:end-step1,:);
    %contour2out = contour2(1:step2:end-step2,:);
    
    min_pnt_number = min([size(contour1out,1) size(contour2out,1)]);  % find minimal number of points on contours
    contour1out = contour1out(1:min_pnt_number,:);     % trim the contour
    contour1out = contour1out(1:min_pnt_number,:);     % trim the contour
    
    % add first point
    contour1out(1,:) = contour1(1, :); %#ok<AGROW>
    contour2out(1,:) = contour2(1, :); %#ok<AGROW>
    
    % add last point
    contour1out(end+1,:) = contour1(end, :); %#ok<AGROW>
    contour2out(end+1,:) = contour2(end, :); %#ok<AGROW>
    
    contour = interp_points(contour1out, contour2out, sl_id1, sl_id2);
    % connect points in the intermediate slices
    for interm_slice = sl_id1+1:sl_id2-1
        img(:,:,interm_slice) = draw_2d_lines(img(:,:,interm_slice), contour(:,:,interm_slice-sl_id1+1));
        img(:,:,interm_slice) = imdilate(img(:,:,interm_slice), SE);
    end
end
toc
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

function img = draw_2d_lines(img, snake)
img_tmp = zeros(size(img),'uint8');
for pnt=2:size(snake,1)
    %if pnt==1
    %    p1 = snake(size(snake,1),:);
    %    p2 = snake(pnt,:);
    %else
        p1 = snake(pnt-1,:);
        p2 = snake(pnt,:);
    %end
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
            y = round(Y(1) + (x-X(1))*dY);
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
            x = round(X(1) + (y-Y(1))*dX);
            img_tmp(y,x) = 1;
        end
    end
end
%img_tmp = imfill(img_tmp,'holes');
img = img_tmp | img;
end

