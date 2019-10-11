function swapColorChannels(obj, channel1, channel2, options)
% function swapColorChannels(obj, channel1, channel2, options)
% Swap two color channels of the dataset
%
% The first color channel will be moved to the position of the second color channel, and the second color channel to the position of the first one
%
% Parameters:
% channel1: [@em optional] index of the first color channel
% channel2: [@em optional] index of the second color channel
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
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
% 26.05.2019, added options

global mibPath; % path to mib installation folder

if nargin < 4; options = struct; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end
if nargin < 3; channel2 = []; end
if nargin < 2; channel2 = []; end

if obj.colors < 2; errordlg(sprintf('Error!\nThere is only one color available!\nCancelling...'), 'Now enough colors', 'modal'); return; end

if isempty(channel1) || isempty(channel2)
    if isempty(channel1); channel1 = max([1 obj.selectedColorChannel]); end
    if isempty(channel2); channel1 = obj.colors; end
    prompt = {'First color channel:'; 'Second color channel:'};
    PossibleColChannels1 = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.colors, 'UniformOutput', false);
    PossibleColChannels1{end+1} = channel1;
    PossibleColChannels2 = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.colors, 'UniformOutput', false);
    PossibleColChannels2{end+1} = channel2;
    defAns = {PossibleColChannels1, PossibleColChannels2};
    
    mibInputMultiDlgOptions.Title = sprintf('Swap color channels:\nthe first color channel will be moved to the position of the second color channel, and the second color channel to the position of the first one');
    mibInputMultiDlgOptions.TitleLines = 5;
    [answer, selIndices] = mibInputMultiDlg([], prompt, defAns, 'Swap color channels', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    
    channel1 = selIndices(1);
    channel2 = selIndices(2);
end

if options.showWaitbar; wb = waitbar(0,sprintf('Swap color channels %d and %d\n\nPlease wait...', channel1, channel2), ...
    'Name', 'Swap color channels','WindowStyle','modal'); end
dummy = obj.img{1}(:,:,channel1,:,:);
if options.showWaitbar; waitbar(0.33, wb); end
obj.img{1}(:,:,channel1,:,:) = obj.img{1}(:,:,channel2,:,:);
if options.showWaitbar; waitbar(0.66, wb); end
obj.img{1}(:,:,channel2,:,:) = dummy;

% generate the log text
log_text = sprintf('Swap color channels %d and %d', channel1, channel2);
obj.updateImgInfo(log_text);
if options.showWaitbar
    waitbar(1, wb);
    delete(wb);
end
end