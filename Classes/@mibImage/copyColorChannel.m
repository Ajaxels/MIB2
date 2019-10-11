function copyColorChannel(obj, channel1, channel2, options)
% function copyColorChannel(obj, channel1, channel2, options)
% Copy intensity from the first color channel (@em channel1) to the position of the second color channel (@em channel2)
%
% The first color channel will be copied to the position of the second color channel
%
% Parameters:
% channel1: [@em optional] index of the first color channel
% channel2: [@em optional] index of the second color channel
% options: structure with additional parameters
% .showWaitbar - logical, @b 1 [@em default] - show the waitbar, @b 0 - do not show
% .autoOverwrite - logical, @b 1 [@em default] - overwrite one existing color channel without a question prompt, 0 - ask for permission
%
% Return values:
% 26.05.2019, added options

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

global mibPath; % path to mib installation folder

if nargin < 4; options = struct; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = true; end
if ~isfield(options, 'autoOverwrite'); options.autoOverwrite = true; end

if strcmp(obj.meta('ColorType'), 'indexed')
    errordlg(sprintf('!!! Error !!!\n\nThe copy color operation is not supported for the indexed images.\nPlease convert image to grayscale and try again:\nMenu->Image->Mode->Grayscale'),'Wrong format','modal');
    return;
end
   
if nargin < 3; channel2 = []; end
if nargin < 2; channel2 = []; end

if isempty(channel1) || isempty(channel2)
    if isempty(channel1); channel1 = max([1 obj.selectedColorChannel]); end
    if isempty(channel2); channel1 = obj.colors; end

    prompt = {'Source color channel:'; 'Destination color channel:'};
    mibInputMultiDlgOptions.PromptLines = [1, 1];
    mibInputMultiDlgOptions.Title = sprintf('Copy color channel:\nthe first color channel will be copied to the position of the second color channel');
    mibInputMultiDlgOptions.TitleLines = 4;
    PossibleColChannels1 = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.colors, 'UniformOutput', false);
    PossibleColChannels1{end+1} = channel1;
    PossibleColChannels2 = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.colors, 'UniformOutput', false);
    PossibleColChannels2{end+1} = channel2;
    defAns = {PossibleColChannels1, PossibleColChannels2};
    [answer, selIndices] = mibInputMultiDlg({mibPath}, prompt, defAns, 'Copy color channel', mibInputMultiDlgOptions);
    if isempty(answer); return; end
    channel1 = selIndices(1);
    channel2 = selIndices(2);
end

if options.showWaitbar; wb = waitbar(0,sprintf('Copy intensities from color channel %d to %d\n\nPlease wait...', channel1, channel2),'Name','Copy color channel','WindowStyle','modal'); end
if channel2 > obj.colors
    obj.img{1}(:,:,channel2,:,:) = obj.img{1}(:,:,channel1,:,:);
    obj.colors = obj.colors + 1;
    obj.dim_yxczt(3) = obj.colors;
    obj.viewPort.min(obj.colors) = 0;
    obj.viewPort.max(obj.colors) = obj.meta('MaxInt');
    obj.viewPort.gamma(obj.colors) = 1;
    obj.meta('ColorType') = 'truecolor';
else
    if options.autoOverwrite == 0
        button = questdlg(sprintf('You are going to overwrite color intensities in the channel %d\nAre you sure?', channel2),'!! Warning !!','Overwrite','Cancel','Cancel'); 
        if strcmp(button, 'Cancel'); if options.showWaitbar; delete(wb); end; return; end
    end
    obj.img{1}(:,:,channel2,:,:) = obj.img{1}(:,:,channel1,:,:);
    
    obj.viewPort.min(channel2) = obj.viewPort.min(channel1);
    obj.viewPort.max(channel2) = obj.viewPort.max(channel1);
    obj.viewPort.gamma(channel2) = obj.viewPort.gamma(channel1);
end
obj.lutColors(channel2, :) = obj.lutColors(channel1, :);
if options.showWaitbar; waitbar(0.99, wb); end
% generate the log text
log_text = sprintf('Copy color channel %d to %d', channel1, channel2);
obj.updateImgInfo(log_text);
if options.showWaitbar
    waitbar(1, wb);
    delete(wb);
end
end