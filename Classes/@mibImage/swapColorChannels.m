function swapColorChannels(obj, channel1, channel2)
% function swapColorChannels(obj, channel1, channel2)
% Swap two color channels of the dataset
%
% The first color channel will be moved to the position of the second color channel, and the second color channel to the position of the first one
%
% Parameters:
% channel1: [@em optional] index of the first color channel
% channel2: [@em optional] index of the second color channel
%
% Return values:

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.swapColorChannels(1, 3);     // call from mibController; swap color channel 1 and 3 @endcode


% Copyright (C) 07.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 

if obj.colors < 2; errordlg(sprintf('Error!\nThere is only one color available!\nCancelling...'), 'Now enough colors', 'modal'); return; end

if nargin < 3
    if nargin < 2
        channel1 = 1;
    end
    prompt = {sprintf('Swap color channels:\nthe first color channel will be moved to the position of the second color channel, and the second color channel to the position of the first one.\n\nEnter number of the first color channel:'),'Enter number of the second color channel:'};
    answer = inputdlg(prompt,'Swap color channels',1,{num2str(channel1),'2'});
    if size(answer) == 0; return; end;
    channel1 = str2double(answer{1});
    channel2 = str2double(answer{2});
    if channel1 < 1 || channel1 > obj.colors || channel2 < 1 || channel2 > obj.colors
        errordlg(sprintf('!!! Error !!!\n\nWrong channel number!\nThe channel numbers should be between 1 and %d', obj.colors),'Error');
        return;
    end
end

wb = waitbar(0,sprintf('Swap color channels %d and %d\n\nPlease wait...', channel1, channel2), ...
    'Name', 'Swap color channels','WindowStyle','modal');
dummy = obj.img{1}(:,:,channel1,:,:);
waitbar(0.33, wb);
obj.img{1}(:,:,channel1,:,:) = obj.img{1}(:,:,channel2,:,:);
waitbar(0.66, wb);
obj.img{1}(:,:,channel2,:,:) = dummy;

% generate the log text
log_text = sprintf('Swap color channels %d and %d', channel1, channel2);
obj.updateImgInfo(log_text);

waitbar(1, wb);
delete(wb);
end