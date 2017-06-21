function copyColorChannel(obj, channel1, channel2)
% function copyColorChannel(obj, channel1, channel2)
% Copy intensity from the first color channel (@em channel1) to the position of the second color channel (@em channel2)
%
% The first color channel will be copied to the position of the second color channel
%
% Parameters:
% channel1: [@em optional] index of the first color channel
% channel2: [@em optional] index of the second color channel
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.copyColorChannel(1, 3);     // call from mibController; copy intensities from channel 1 to channel 3 @endcode
% @code obj.mibModel.getImageMethod('copyColorChannel', NaN, 1, 3); // call from mibController via a wrapper function getImageMethod @endcode

% Copyright (C) 07.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 

if strcmp(obj.meta('ColorType'), 'indexed')
    errordlg(sprintf('!!! Error !!!\n\nThe copy color operation is not supported for the indexed images.\nPlease convert image to grayscale and try again:\nMenu->Image->Mode->Grayscale'),'Wrong format','modal');
    return;
end
    
if nargin < 3
    if nargin < 2;         channel1 = 1; end;
    prompt = {sprintf('Copy color channel:\nthe first color channel will be copied to the position of the second color channel\n\nEnter number of the first color channel:'),'Enter number of the second color channel:'};
    answer = inputdlg(prompt,'Copy color channel', 1, {num2str(channel1), num2str(obj.colors+1)});
    if size(answer) == 0; return; end;
    channel1 = str2double(answer{1});
    channel2 = str2double(answer{2});
    channel2 = min([channel2, obj.colors+1]);
end

wb = waitbar(0,sprintf('Copy intensities from color channel %d to %d\n\nPlease wait...', channel1, channel2),'Name','Copy color channel','WindowStyle','modal');
if channel2 > obj.colors
    obj.img{1}(:,:,channel2,:,:) = obj.img{1}(:,:,channel1,:,:);
    obj.colors = obj.colors + 1;
    obj.viewPort.min(obj.colors) = 0;
    obj.viewPort.max(obj.colors) = double(intmax(class(obj.img{1})));
    obj.viewPort.gamma(obj.colors) = 1;
    obj.meta('ColorType') = 'truecolor';
else
    button = questdlg(sprintf('You are going to overwrite color intensities in the channel %d\nAre you sure?', channel2),'!! Warning !!','Overwrite','Cancel','Cancel'); 
    if strcmp(button, 'Cancel'); delete(wb); return; end;
    obj.img{1}(:,:,channel2,:,:) = obj.img{1}(:,:,channel1,:,:);
    
    obj.viewPort.min(channel2) = obj.viewPort.min(channel1);
    obj.viewPort.max(channel2) = obj.viewPort.max(channel1);
    obj.viewPort.gamma(channel2) = obj.viewPort.gamma(channel1);
end
obj.lutColors(channel2, :) = obj.lutColors(channel1, :);
waitbar(0.99, wb);
% generate the log text
log_text = sprintf('Copy color channel %d to %d', channel1, channel2);
obj.updateImgInfo(log_text);

delete(wb);
end