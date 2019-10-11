function output = addColorChannel(obj, img, channelId, lutColors)
% function output = addColorChannel(obj, img, channelId, lutColors)
% Add a new color channel to the existing dataset
%
% Parameters:
% img: new 2D/3D image stack to add
% channelId: @b [optional] number (single) of the channel to add, if NaN a new color channel is created
% lutColors: @b [optional] a matrix (channelNumber, R G B) for the colors. The colors should be in range between 0 and 1
%
% Return values:
% output: result of the function; 1 -success; 0 -fail

%|
% @b Example
% @code mibImage.addColorChannel(img, channelId);     // replace the color channel (channelId) with new img  @endcode
% @code obj.mibModel.getImageMethod('addColorChannel', NaN, img, channelId); // call from mibController via a wrapper function getImageMethod; to clear the class @endcode

% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich -at- helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

output = 0;
if nargin < 4; lutColors = NaN; end
if nargin < 3; channelId = NaN; end

if size(obj.img{1},1) ~= size(img, 1) || size(obj.img{1},2) ~= size(img, 2) || size(obj.img{1},4) ~= size(img, 4)
    button = questdlg(sprintf('Warning!\nSome of the image dimensions mismatch.\nContinue anyway?'),'Dimensions mismatch!','Continue','Cancel','Continue');
    if strcmp(button,'Cancel'); return; end
end
wb = waitbar(0,'Please wait...','Name','Add color...','WindowStyle','modal');
tMax = min([size(obj.img{1},5) size(img,5)]);
zMax = min([size(obj.img{1},4) size(img,4)]);
xMax = min([size(obj.img{1},2) size(img,2)]);
yMax = min([size(obj.img{1},1) size(img,1)]);

noExistingColors = size(obj.img{1},3);
noExtraColors = size(img,3);

if isnan(channelId)     % add img as a new channel
    waitbar(0.1, wb);
    obj.img{1}(1:yMax,1:xMax,noExistingColors+1:noExistingColors+noExtraColors,1:zMax, 1:tMax) = img(1:yMax,1:xMax,:,1:zMax, 1:tMax);
    waitbar(0.9, wb);
    obj.colors = noExistingColors+noExtraColors;
    obj.meta('ColorType') = 'truecolor';
    obj.viewPort.min(noExistingColors+1:noExistingColors+noExtraColors) = 0;
    obj.viewPort.max(noExistingColors+1:noExistingColors+noExtraColors) = double(intmax(class(img)));
    obj.viewPort.gamma(noExistingColors+1:noExistingColors+noExtraColors) = 1;
    obj.slices{3} = [obj.slices{3} numel(obj.slices{3})+1];
else
    waitbar(0.1, wb);
    obj.img{1}(1:yMax,1:xMax,channelId,1:zMax,1:tMax) = img(1:yMax,1:xMax,1,1:zMax,1:tMax);
    waitbar(0.9, wb);
    obj.viewPort.min(channelId) = 0;
    obj.viewPort.max(channelId) = double(intmax(class(img)));
    obj.viewPort.gamma(channelId) = 1;
end

if ~isnan(lutColors(1))
    currLutColors = obj.lutColors;
    currLutColors = currLutColors(1:noExistingColors, :);
    currLutColors(noExistingColors+1:noExistingColors+noExtraColors,:) = lutColors(1:noExtraColors,:);
    obj.meta('lutColors') = currLutColors;
    obj.lutColors = currLutColors;
else
    if size(obj.lutColors,1) < size(obj.img{1}, 3)
        obj.lutColors = [obj.lutColors; rand(1) rand(1) rand(1)];
    end
end

% fix orientation of .min .max and .gamma fields
if size(obj.viewPort.min, 1) < size(obj.viewPort.min, 2); obj.viewPort.min = obj.viewPort.min'; end
if size(obj.viewPort.max, 1) < size(obj.viewPort.max, 2); obj.viewPort.max = obj.viewPort.max'; end
if size(obj.viewPort.gamma, 1) < size(obj.viewPort.gamma, 2); obj.viewPort.gamma = obj.viewPort.gamma'; end

waitbar(1, wb);
delete(wb);
output = 1;
end