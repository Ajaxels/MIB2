function [mask, status] = mibTraceCurve(img, options, mask)
% function [mask, status] = mibTraceCurve(img, options, mask)
% Connect points with search for a minimum gradients.
% 
% This function is called from Membrane Click Tracer tool of im_browser.m. It is based on Accurate Fast Marching function by Dirk-Jan Kroon
% http://www.mathworks.se/matlabcentral/fileexchange/24531-accurate-fast-marching
%
% Parameters:
% img: -> original image to probe gradients
% options: -> a structure with parameters
%   .p1             - coordinates of the starting point, (y;x)
%   .p2             - coordinates of the target point, (y;x)
%   .scaleFactor    - scale factor for amplifiying intensities
%   .segmTrackBlackChk  - switch to define whether the signal is black (1) or white (0)
%   .colorId - index of the color channel to follow
% mask: [@em optional] - an existing mask/selection layer
%
% Return values:
% mask: -> a bitmap image with a connecting line, to be used as the 'Selection' layer
% status: -> result of the function run:
% - @b 0 - fail
% - @b 1 - success

% Copyright (C) 15.08.2012 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

status = 0;         % result of the run
test_run_sw = 0;
if nargin == 0  % test run
    img = imread('cameraman.tif');
    options.p1 = [202; 180];
    options.p2 = [88; 152];
    options.scaleFactor = .1;
    options.segmTrackBlackChk = 1;
    test_run_sw = 1;
end
if nargin < 3   % if mask is not provided generate a new one
    mask = zeros([size(img,1) size(img,2)],'uint8');
end
if nargin < 2 && test_run_sw == 0; error('not enough parameters'); end
if ~isfield(options, 'colorId'); options.colorId = 1; end
if ~isfield(options, 'segmTrackBlackChk'); options.segmTrackBlackChk = 1; end
if ~isfield(options, 'scaleFactor'); options.scaleFactor = 1; end

maxIntensity = double(intmax(class(img)));
if size(img,3) > 1; img = img(:,:,options.colorId); end
if options.segmTrackBlackChk % invert image
    img = maxIntensity - img;   
end
val1 = double(img(options.p1(1),options.p1(2)));
val2 = double(img(options.p2(1),options.p2(2)));
pointsVec =  img > min([val1 val2])-abs(val1-val2)*options.scaleFactor & img <= max([val1 val2])+abs(val1-val2)*options.scaleFactor;
img = img/50;
img(pointsVec) = maxIntensity;

%img(img > min([val1 val2])-abs(val1-val2)*options.scaleFactor & img < max([val1 val2])+abs(val1-val2)*options.scaleFactor) = maxIntensity;
%img(img~=maxIntensity) = img(img~=maxIntensity)/50;

DistanceMap = msfm(double(img)*1000+1, options.p2);
ShortestLine=round(shortestpath(DistanceMap,options.p1,options.p2));
for i=1:size(ShortestLine,1)
    mask(ShortestLine(i,1),ShortestLine(i,2)) = 1;
end

status = 1;

if test_run_sw
    figure(512);
    img = imread('cameraman.tif');
    imshow(img);
    hold on, plot(ShortestLine(:,2),ShortestLine(:,1),'r');
end
end
