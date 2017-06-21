function invertColorChannel(obj, channel1)
% function invertColorChannel(obj, channel1)
% Invert color channel of the dataset
%
% The specified @em channel1 will be inverted
%
% Parameters:
% channel1: [@em optional] index of the color channel to invert
%
% Return values:

%| 
% @b Examples:
% @code handles = obj.mibModel.I{obj.mibModel.Id}.invertColorChannels(1);     // call from mibController; invert color channel 1 @endcode

% Copyright (C) 07.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 
global mibPath; % path to mib installation folder

if nargin < 2
    prompt = {sprintf('Which color channel to invert:')};
    answer = mibInputDlg({mibPath}, prompt, 'Invert color channel', {num2str(obj.slices{3}(1))});
    if size(answer) == 0; return; end;
    channel1 = str2double(answer{1});
end

wb = waitbar(0,sprintf('Inverting color channel: %d\n\nPlease wait...', channel1), 'Name', 'Invert color channel', 'WindowStyle', 'modal');

maxval = intmax(class(obj.img{1}));
waitbar(0.1, wb);
obj.img{1}(:,:,channel1,:,:) = maxval - obj.img{1}(:, :, channel1, :, :);
waitbar(0.95, wb);

% generate the log text
log_text = sprintf('Invert color channel %d', channel1);
obj.updateImgInfo(log_text);

waitbar(1, wb);
delete(wb);
end