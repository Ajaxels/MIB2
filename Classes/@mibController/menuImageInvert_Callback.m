function menuImageInvert_Callback(obj, mode)
% function menuImageInvert_Callback(obj, mode)
% callback for Menu->Image->Invert image; start invert image 
%
% Parameters:
% mode: a string that defines part of the dataset to be inverted
% @li when @b '2D' invert the currently shown slice
% @li when @b '3D' invert the currently shown z-stack
% @li when @b '4D' invert the whole dataset
%
% Return values:
% 

% Copyright (C) 03.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; mode = '4D'; end;
colChannel = NaN;
if numel(obj.mibView.handles.mibColChannelCombo.String)-1 > numel(obj.mibModel.I{obj.mibModel.Id}.slices{3})
    strText = sprintf('Would you like to invert shown or all channels?');
    button = questdlg(strText, 'Invert Image', 'Shown channels', 'All channels', 'Cancel', 'Shown channels');
    if strcmp(button, 'Cancel'); return; end;
    if strcmp(button, 'All channels')
        colChannel = 0;
    end
end

obj.mibModel.invertImage(mode, colChannel);
end