function STATS = mibCalcCurveLength(slice, pixSize, CC)
% function STATS = mibCalcCurveLength(slice, pixSize, CC)
% Calculate length of the curve objects in the slice.
%
% It is possible to measure the length of both closed and non-closed curves. The images are subject to thinning, so that the
% curves have width of 1 pixel.
%
% Parameters:
% slice: a 2D slice [1:height, 1:width], class uint8 with drawn curves or a structure with detected labels, returned by @em regionprops function
% pixSize: [@em optional] a structure with pixel sizes. The required fields @b .x and @b .y; can be @em empty
% CC: [@em optional] a structure with detected labels, returned by @em regionprops function
%
% Return values:
% STATS: a structure with @b CurveLengthInPixels or @b CurveLengthInUnits field that has the length of the curve segment and the @b PixelIdxList field with
% indeces of pixels in each segment.
%

% Copyright (C) 22.08.2013 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 20.09.2017 IB updated to include smoothing of points
% 18.01.2019 IB first argument can be CC structure

% fill default pixel size
fieldName = 'CurveLengthInUnits';
if nargin < 3
    if isstruct(slice)
        CC = slice;
    else
        CC = bwconncomp(slice, 8);
    end
end
if nargin < 2
    pixSize.x = 1;
    pixSize.y = 1;
    fieldName = 'CurveLengthInPixels';
end
if isstruct(pixSize) == 0
    pixSize.x = 1;
    pixSize.y = 1;
    fieldName = 'CurveLengthInPixels';    
end

%slice = bwmorph(slice,'thin','Inf');    % thin the curve as much as possible

STATS = regionprops(CC, 'PixelList','PixelIdxList','FilledArea','Centroid','BoundingBox');
L = labelmatrix(CC);
for objId = 1:CC.NumObjects
    bb = ceil(STATS(objId).BoundingBox);    % [x,y,z,w,h,d]
    % crop L to the object's bounding box
    M2 = L(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1);
    % keep only the selected object
    M1 = zeros(size(M2), 'uint8');
    M1(M2==objId) = 1;
    
    if numel(STATS(objId).PixelIdxList) == STATS(objId).FilledArea  % non-closed line
        % find the ending points of the thinned line
        endPoints = bwmorph(M1, 'endpoints');    % get endpoints
        % find coordinates of the ending points
        [ePntsY, ePntsX] = find(endPoints);
        if numel(ePntsY) > 2
            msgbox(sprintf('Object %d has more that two end points, please make sure that each line has only two end points!\nCoordinates X=%d Y=%d\nPlease fix it and try again!', objId, ePntsX(1), ePntsY(1)), 'Too many end points','error');
            STATS = NaN;
            return;
        end
        % trace the boundary starting from the 1st end point
        noPix = sum(sum(M1));
        if noPix > 1
            B = bwtraceboundary(M1, [ePntsY(1), ePntsX(1)], 'N', 8, sum(sum(M1)));
        else
            [y, x] = find(M1);
            B = [y, x];
        end
        
%         % % test the points
%         figure(115);
%         imshow(M1, []);
%         hold on;
%         plot(B(:,2), B(:,1), 'r+');
%         hold off;
        
        % % smoothing 
        % use windv instead of smooth, because smooth
        % is only available in the curve fitting toolbox
        %B(:,1) =  smooth(B(:,1), 3);
        %B(:,2) =  smooth(B(:,2), 3);
        B(:,1) =  windv(B(:,1), 1, 1);
        B(:,2) =  windv(B(:,2), 1, 1);
        
        B(:,1) = (B(:,1)+bb(2)-1)*pixSize.y;  % y coordinate
        B(:,2) = (B(:,2)+bb(1)-1)*pixSize.x;  % x coordinate
        
        length = 0;
        for pointId = 1:size(B,1)-1
            length = length + ...
                sqrt( (B(pointId+1,1)-B(pointId,1))^2 + (B(pointId+1,2)-B(pointId,2))^2 );
        end
        STATS(objId).(fieldName) = length;
    else
        [y,x] = find(M1==1,1);  % find a starting point
        B = bwtraceboundary(M1, [y,x], 'N', 8, Inf);
        % % smoothing 
        % use windv instead of smooth, because smooth
        % is only available in the curve fitting toolbox
        %B(:,1) =  smooth(B(:,1), 3);
        %B(:,2) =  smooth(B(:,2), 3);
        B(:,1) =  windv(B(:,1), 1, 1);
        B(:,2) =  windv(B(:,2), 1, 1);
        
        B(:,1) = (B(:,1)+bb(2)-1)*pixSize.y;  % y coordinate
        B(:,2) = (B(:,2)+bb(1)-1)*pixSize.x;  % x coordinate
        length = 0;
        for pointId = 1:size(B,1)-1
            length = length + ...
                sqrt( (B(pointId+1,1)-B(pointId,1))^2 + (B(pointId+1,2)-B(pointId,2))^2 );
        end
        STATS(objId).(fieldName) = length;
    end
end

% % below is an older code without smoothing

% for objId = 1:CC.NumObjects
%     if numel(STATS(objId).PixelIdxList) == STATS(objId).FilledArea  % non-closed line
%         % find a starting point
%         endPointsOnly = bwmorph(slice, 'endpoints');    % get endpoints
%         for i=1:size(STATS(objId).PixelList,1)
%             if endPointsOnly(STATS(objId).PixelList(i,2), STATS(objId).PixelList(i,1)) > 0
%                 currentPoint = i;
%                 break;
%             end
%         end
%         
%         length = 0;
%         currCoordinates = STATS(objId).PixelList(currentPoint,:);
%         for pointId = 1:size(STATS(objId).PixelList,1)-1
%             STATS(objId).PixelList(currentPoint,1) = 0;
%             STATS(objId).PixelList(currentPoint,2) = 0;
%             
%             % find next possible point in the X coordinate
%             nextPnt = find(abs(STATS(objId).PixelList(1:end,1)-currCoordinates(1))<=1);
%             if numel(nextPnt) > 1   % find next point in the Y coordinate
%                 nextPnt = nextPnt(abs(STATS(objId).PixelList(nextPnt,2)-currCoordinates(2))<=1);
%             end
%             
%             if numel(nextPnt) > 1
%                 msgbox(sprintf('Branch point are detected at coordinates X=%d Y=%d\nPlease fix it and try again!', currCoordinates(1), currCoordinates(2)), 'Branch point detected','error');
%                 STATS = NaN;
%                 return;
%             end
%             
%             length = length + sqrt(...
%                 ((currCoordinates(1) - STATS(objId).PixelList(nextPnt,1))*pixSize.x)^2 + ...
%                 ((currCoordinates(2) - STATS(objId).PixelList(nextPnt,2))*pixSize.y)^2 ...
%                 );
%             % clear current point
%             currCoordinates(1) = STATS(objId).PixelList(nextPnt,1);
%             currCoordinates(2) = STATS(objId).PixelList(nextPnt,2);
%             currentPoint = nextPnt;
%         end
%         STATS(objId).(fieldName) = length;
%     else    % closed line
%         %slice = bwmorph(slice,'spur','Inf');    % spur image to remove branch points
%         %slice = bwmorph(slice,'thin','Inf');    % thin again the curve as much as possible
%         %CC = bwconncomp(slice, 8);
%         %STATS = regionprops(CC, 'PixelList','PixelIdxList','FilledArea');
%         currentPoint = 1;
%         length = 0;
%         currCoordinates = STATS(objId).PixelList(currentPoint,:);
%         startCoordinates = STATS(objId).PixelList(currentPoint,:);  % store the start coordinates to use to close the curve
%         for pointId = 1:size(STATS(objId).PixelList,1)-1
%             STATS(objId).PixelList(currentPoint,1) = 0;
%             STATS(objId).PixelList(currentPoint,2) = 0;
%             
%             % find next possible point in the X coordinate
%             nextPnt = find(abs(STATS(objId).PixelList(1:end,1)-currCoordinates(1))<=1);
%             if numel(nextPnt) > 1   % find next point in the Y coordinate
%                 nextPnt = nextPnt(abs(STATS(objId).PixelList(nextPnt,2)-currCoordinates(2))<=1);
%             end
%             if pointId == 1      % for the 1st point
%                 nextPnt = nextPnt(1);
%             end
%             if numel(nextPnt) > 1
%                 msgbox(sprintf('Branch point are detected at coordinates X=%d Y=%d\nPlease fix it and try again!', currCoordinates(1), currCoordinates(2)), 'Branch point detected','error');
%                 STATS = NaN;
%                 return;
%             end
%                 
%             length = length + sqrt(...
%                 ((currCoordinates(1) - STATS(objId).PixelList(nextPnt,1))*pixSize.x)^2 + ...
%                 ((currCoordinates(2) - STATS(objId).PixelList(nextPnt,2))*pixSize.y)^2 ...
%                 );
%             % clear current point
%             currCoordinates(1) = STATS(objId).PixelList(nextPnt,1);
%             currCoordinates(2) = STATS(objId).PixelList(nextPnt,2);
%             currentPoint = nextPnt;
%         end
%         % close the curve
%         length = length + sqrt(...
%             ((currCoordinates(1) - startCoordinates(1))*pixSize.x)^2 + ...
%             ((currCoordinates(2) - startCoordinates(2))*pixSize.y)^2 ...
%             );
%         
%         STATS(objId).(fieldName) = length;
%     end
% end

STATS = rmfield(STATS, 'PixelList');
STATS = rmfield(STATS, 'FilledArea');
STATS = rmfield(STATS, 'BoundingBox');
end