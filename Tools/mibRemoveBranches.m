function imgOut = mibRemoveBranches(img)
% function imgOut = mibRemoveBranches(img)
% remove branches from thinned bitmap image _img_
% the line can be thinned using _img = bwmorph(img, 'thin', Inf)_ command
% somewhat based on "Exploring shortest paths – part 5" by Steve Eddins 
% (https://blogs.mathworks.com/steve/2011/12/13/exploring-shortest-paths-part-5/)
%
% Parameters:
% img: a bitmap image with thinned curves
%
% Return values:
% imgOut: image without branches

% Copyright (C) 31.07.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
%
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

%figure(1)
%imshow(img, []);

% thin the object
%M1 = bwmorph(img, 'thin', Inf);
%figure(2)
%imshow(img, []);

% find connected components
CC = bwconncomp(img, 8);
% detect bounding boxes for cropping
STATS = regionprops(CC, 'BoundingBox');
% generate the label matrix
L = labelmatrix(CC);

imgOut = zeros(size(img), 'uint8');

% loop across the objects
for objId = 1:CC.NumObjects
    bb = ceil(STATS(objId).BoundingBox);
    % crop L to the object's bounding box
    M2 = L(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1);
    % keep only the selected object
    M1 = zeros(size(M2), 'logical');
    M1(M2==objId) = 1;

    E = bwmorph(M1, 'endpoints');
    EndPoints = find(E);
    if numel(EndPoints) > 2     % if more than 2 end points look for the longest path
        LongestDistIndex = zeros([numel(EndPoints), 3]);    % [EndPointIndex][LongestDistance, endpoint1, endpoint2]
        for pnt=1:numel(EndPoints)
            D1 = bwdistgeodesic(M1, EndPoints(pnt), 'quasi-euclidean');
            [D1sorted, ind] = sort(D1(EndPoints));  % find the longest distance
            LongestDistIndex(pnt, :) = [D1sorted(end), pnt, ind(end)];
        end
        % find the longest distance for all end points
        [~, ind] = sort(LongestDistIndex(:,1));
        LongestDist = LongestDistIndex(ind(end), :);
        
        % keep only the longest path
        D1 = bwdistgeodesic(M1, EndPoints(LongestDist(2)), 'quasi-euclidean');
        D2 = bwdistgeodesic(M1, EndPoints(LongestDist(3)), 'quasi-euclidean');
        D = D1 + D2;
        
        D = -D + min(D(:))+.9;
        M1 = zeros(size(M1), 'uint8');
        M1(D>0) = 1;
        
        % this code gives sometimes short profiles
        %D = round(D * 8) / 8;
        %D(isnan(D)) = Inf;
        %M1 = imregionalmin(D);
                
        %figure(3);
        %P = imoverlay(img, M1, [1 0 0]);
        %imshow(P, 'InitialMagnification', 200);
    end
    imgOut(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1) = imgOut(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1) + uint8(M1);
end




