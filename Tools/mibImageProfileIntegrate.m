function [ProfileOut, profileLength] = mibImageProfileIntegrate(img, x1, y1, x2, y2, profileWidth, debug)
% function [ProfileOut, profileLength] = mibImageProfileIntegrate(img, x1, y1, x2, y2, profileWidth, debug)
% calculate image intensity profile for line ROI
% based on code by Damien in comments of
% http://se.mathworks.com/matlabcentral/fileexchange/11568-extract-integrated-intensity-profiles-from-image
%
% Parameters: 
% img: an image to be used for intensity calculations ([height, width, colors])
% x1: x1 coordinate for the line
% y1: y1 coordinate for the line
% x2: x2 coordinate for the line
% y2: y2 coordinate for the line
% profileWidth: a number that defines the width of the intensity profile
% debug: [@em optional] - a switch to show debug plots
%
% Return values:
% ProfileOut: matrix with intensity profiles for all color channels [colChannel, 1:points]
% profileLength: length of the intensity profile in pixels

% Copyright (C) 28.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 7; debug = 0; end;

if debug
    figure(1)
    ax = axes;
    hI = image(ax, img);
    hI.CDataMapping = 'scaled';
    colormap('gray');
end

%linescan along the dots (x1,y1) and (x2,y2) 
%width of the linsecan is the variable 'profileWidth', which is also the width of
%the rectangle to be rotated

%get the length of the line, length of the rectangle
profileLength = sqrt((x2-x1).^2 + (y2-y1).^2);

%calculate the rotation angle

if y2 < y1
    rotationAngle = acos((x2-x1)/profileLength);
elseif y2 > y1
    rotationAngle = -acos((x2-x1)/profileLength);
else
    rotationAngle = 0.000001;
end

%building the rotation matrix
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];

%get the rotation center
centerx = (x2 - x1)/2; 
centery = (y2 - y1)/2;

if debug
    %draw the rectangle for quantification before rotation
    rectangle('position',[x1 + centerx - profileLength/2, y1+ centery - profileWidth/2, profileLength, profileWidth],'LineStyle','-','LineWidth',2,'EdgeColor','b')
end

%coordinates of the rectangle in the centered referential
vertices2 = cat(1, [-profileLength/2,-profileWidth/2],[profileLength/2,-profileWidth/2],...
                   [-profileLength/2,profileWidth/2],[profileLength/2,profileWidth/2]);

%New coordinates once rotated
rotrect2 = vertices2 * rotationArray;

%Put the rectangle in the old referential
rotrect2(:,1) = rotrect2(:,1) + x1 + centerx; 
rotrect2(:,2) = rotrect2(:,2)+ y1 + centery;

if debug
    %this is to draw the rotated rectangle
    line([rotrect2(1,1),rotrect2(2,1)],[rotrect2(1,2),rotrect2(2,2)],'LineStyle','-','Color','w','LineWidth',2) 
    line([rotrect2(1,1),rotrect2(3,1)],[rotrect2(1,2),rotrect2(3,2)],'LineStyle','-','Color','w','LineWidth',2) 
    line([rotrect2(2,1),rotrect2(4,1)],[rotrect2(2,2),rotrect2(4,2)],'LineStyle','-','Color','w','LineWidth',2) 
    line([rotrect2(3,1),rotrect2(4,1)],[rotrect2(3,2),rotrect2(4,2)],'LineStyle','-','Color','w','LineWidth',2)
end

%get the equation of the lines forming the side of the rotated rectangle
pente = (rotrect2(3,2) - rotrect2(1,2))/(rotrect2(3,1) - rotrect2(1,1));

b1 = rotrect2(1,2) - pente * rotrect2(1,1); 
b2 = rotrect2(2,2) - pente * rotrect2(2,1);

%running improfile along the paralell lines
for j = 0:profileWidth-1
    xj1 = rotrect2(1,1) + ((rotrect2(3,1) - rotrect2(1,1))/(profileWidth-1))*j;
    xj2 = rotrect2(2,1) + ((rotrect2(4,1) - rotrect2(2,1))/(profileWidth-1))*j;
    
    yj1 = pente * xj1 + b1;
    yj2 = pente * xj2 + b2;
    
    if debug == 1 && j == 0
        % draw the dots for the linescans
        line(xj1, yj1, 'lineStyle', 'none', 'marker', '*', 'markerEdgeColor', 'r');
        line(xj2, yj2, 'lineStyle', 'none', 'marker', '*', 'markerEdgeColor', 'r');
    end
    
    %quantification along the line
    for colCh = 1:size(img, 3)
        Profile(colCh, :) = improfile(img(:, :, colCh), [xj1, xj2], [yj1, yj2]);
    end
    
    if j == 0
        ProfileOut = zeros([profileWidth, size(Profile, 1), size(Profile, 2)]);
    end
    
    ProfileOut(j+1, 1:size(Profile,1), 1:size(Profile,2)) = Profile;
end

if debug
    figure(5)
    plot(mean(ProfileOut));
end

% average output
ProfileOut = shiftdim(mean(ProfileOut, 1),1);

end