function rotateColorChannel(obj, channel1)
% function rotateColorChannel(obj, channel1)
% Rotate color channel of the dataset
%
% The specified @em channel1 will be rotated
%
% Parameters:
% channel1: [@em optional] index of the color channel to invert
%
% Return values:

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.rotateColorChannel(1);     // call from mibController; rotate color channel 1 @endcode

% Copyright (C) 07.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
global mibPath; % path to mib installation folder

if obj.width ~= obj.height; errordlg(sprintf('!!! Error !!!\n\nThe rotation of a channel is only possible for a square-shaped images'),'Wrong image dimensions'); return; end;
if nargin < 2
    prompt = {sprintf('Which color channel to rotate:')};
    answer = mibInputDlg({mibPath}, prompt, 'Invert color channel', {num2str(obj.slices{3}(1))});
    if size(answer) == 0; return; end;
    channel1 = str2double(answer{1});
end

answer = mibInputDlg({mibPath}, sprintf('Define rotation angle:\n90 or -90'), 'Rotation angle', '90');
if ~isempty(answer)
    RotationAngle = str2double(answer{1});
    if RotationAngle ~= 90 && RotationAngle ~= -90
        errordlg(sprintf('!!! Error !!!\n\nWrong rotation angle (%s)!\nThe rotation angle should be 90 or -90', answer{1}),'Wrong rotation angle');
        return;
    else
        % rotate color channel
        wb = waitbar(0,sprintf('Rotating (%s) color channel %d\nPlease wait...', answer{1}, channel1), 'Name', 'Rotate color channel', 'WindowStyle','modal');
        if RotationAngle == 90
            RotationAngle = 3;
        else
            RotationAngle = 1;
        end
    end
else
    return;
end

for t=1:obj.time
    for slice = 1:obj.depth
        obj.img{1}(:, :, channel1, slice, t) = rot90(obj.img{1}(:, :, channel1, slice, t), RotationAngle);
    end
    waitbar(t/obj.time, wb);
end
waitbar(1, wb);
log_text = sprintf('Rotate color channel %d by %s degrees', channel1, answer{1});
obj.updateImgInfo(log_text);
delete(wb);

end