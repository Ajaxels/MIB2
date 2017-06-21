function I = mibAddScaleBar(I, pixSize, scale, orientation, base, table)
% I = mibAddScaleBar(I, pixSize, scale, orientation, base, table)
% add a scale bar to the image
%
% Parameters:
% I:    RGB image that requires the scale bar
% pixSize:  a structure with pixel size of the image, .x, .y, .z
% scale: scaling factor   
% orientation:  orientation of the snapshot: 1, 2, 4
% base:     a matrix with bitmap letters that will be used for the scale bar text
% table:    a list of letters in the base matrix
%
% Fuse text into an image I
% based on original code by by Davide Di Gloria
% http://www.mathworks.com/matlabcentral/fileexchange/26940-render-rgb-text-over-rgb-or-grayscale-image
% I=renderText(I, text)
% text -> cell with text

%| 
% @b Examples:
% @code I = mibAddScaleBar(I, pixSize, scale, orientation);      // add scalebar @endcode

% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 


% load characters for the scale bar
if nargin < 5
    base=uint8(1 - logical(imread('chars.bmp')));
    table='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890''?!"?$%&/()=?^?+???,.-<\|;:_>????*@#[]{} ';
end

if orientation == 4
    pixelSize = pixSize.x/scale;
elseif orientation == 1
    pixelSize = pixSize.x/scale;
elseif orientation == 2
    pixelSize = pixSize.y/scale;
end

width = size(I,2);
height = size(I,1);

resizeFactor = ceil(min([width height])/1200);

%scaleBarText = sprintf('%.3f %s',width*pixelSize/10, pixSize.units);
%scaleBarLength = round(width/10);

targetStep = width*pixelSize/10;  % targeted length of the scale bar in units
mag = floor(log10(targetStep));     % magnitude of the scale bar
magPow = power(10, mag);
magDigit = floor(targetStep/magPow + 0.5);
roundStep = magDigit*magPow;    % rounded step
if mag < 0
    strText = ['scaleBarText = sprintf(''%.' num2str(abs(mag)) 'f %s'', roundStep, pixSize.units);'];
    eval(strText);
else
    scaleBarText = sprintf('%d %s', roundStep, pixSize.units);
end
scaleBarLength = round(roundStep/pixelSize);

text_str = scaleBarText;
n = numel(text_str);
ColorsNumber = size(I, 3);

coord(2,n)=0;
for i=1:n
    coord(:,i)= [0 find(table == text_str(i))-1];
end
m = floor(coord(2,:)/26);
coord(1,:) = m*20+1;
coord(2,:) = (coord(2,:)-m*26)*13+1;

model = zeros(22,size(I,2),size(I,3), class(I));
%model = zeros(22*resizeFactor,size(I,2),size(I,3), class(I));
total_index = 1;
max_int = double(intmax(class(I)));
shiftX = 5;     % shift of the scale bar from the left corner
%if scaleBarLength+shiftX*2+(numel(text_str)*12) > width
if scaleBarLength+shiftX*2+(numel(text_str)*12*resizeFactor) > width
    msgbox(sprintf('Image is too small to put the scale bar!\nSaving image without the scale bar...'),'Scale bar','warn');
    return;
end
for index = 1:numel(text_str)
    model(1:20, scaleBarLength+shiftX*2+(12*index-11):scaleBarLength+shiftX*2+(index*12), :) = repmat(double(imcrop(base,[coord(2,total_index) coord(1,total_index) 11 19]))*max_int, [1, 1, ColorsNumber]);
    total_index = total_index + 1;
end

% add scale
model(10:12, shiftX:shiftX+scaleBarLength-1,:) = repmat(max_int, [3, scaleBarLength, ColorsNumber]);
model(8:14, shiftX,:) = repmat(max_int, [7, 1, ColorsNumber]);
model(8:14, shiftX+scaleBarLength-1,:) = repmat(max_int, [7, 1, ColorsNumber]);

% resize the scale bar
if resizeFactor > 1
    model1 = model(:, 1:scaleBarLength+shiftX*2, :);    % crop the scale bar
    model1 = imresize(model1, [size(model1,1)*resizeFactor size(model1,2)], 'nearest');
    model2 = model(:,scaleBarLength+shiftX*2+1:scaleBarLength+shiftX*2+(index*12)+1,:);    % crop the label
    model2 = imresize(model2, resizeFactor, 'bicubic');
    
    if size(model1,2)+shiftX*resizeFactor+size(model2,2) > width
        msgbox(sprintf('Image is too small to put the scale bar!\nSaving image without the scale bar...'),'Scale bar','warn');
        return;
    end
    
    model = zeros(22*resizeFactor,size(I,2),size(I,3), class(I));
    model(:,shiftX*resizeFactor:shiftX*resizeFactor+size(model1,2)-1,:) = model1;
    model(:,size(model1,2)+shiftX*resizeFactor:size(model1,2)+shiftX*resizeFactor+size(model2,2)-1,:) = model2;
end
I = cat(1, I, model);
end