function toolbarInterpolation_ClickedCallback(obj, options)
% function toolbarInterpolation_ClickedCallback(obj, options)
% Function to set the state of the interpolation button in the toolbar.
%
% When the ''options'' variable is omitted the function works as a standard
% callback and changes the type of interpolation: ''shape'' or ''line''.
% However, when ''options'' are specified the function sets the state of
% the button to the currently selected type.
%
% Parameters:
% options: [@em optional], 
% @li when @b ''keepcurrent'' set the state of the button to the currently
% selected type of the interpolation.
%
% Return values:
% 
%| @b Examples:
% @code obj.toolbarInterpolation_ClickedCallback('keepcurrent');     // call from mibController; update the interpolation button icon @endcode

% Copyright (C) 13.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 
global mibPath;

if nargin == 2  % when options are available
    if strcmp(options, 'keepcurrent')
        0;
    end
else
    if strcmp(obj.mibModel.preferences.interpolationType, 'shape')
        obj.mibModel.preferences.interpolationType = 'line';
    else
        obj.mibModel.preferences.interpolationType = 'shape';
    end
end
if strcmp(obj.mibModel.preferences.interpolationType, 'line')
    filename = 'line_interpolation.res';
    obj.mibView.handles.toolbarInterpolation.TooltipString = 'Use LINE interpolation';
    obj.mibView.handles.menuSelectionInterpolate.Label = 'Interpolate as Line (I)';
else
    filename = 'shape_interpolation.res';
    obj.mibView.handles.toolbarInterpolation.TooltipString = 'Use SHAPE interpolation';
    obj.mibView.handles.menuSelectionInterpolate.Label = 'Interpolate as Shape (I)';
end

img = load(fullfile(mibPath, 'Resources', filename), '-mat');  % load icon
obj.mibView.handles.toolbarInterpolation.CData = img.image;
end

