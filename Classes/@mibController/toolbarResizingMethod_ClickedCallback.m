function toolbarResizingMethod_ClickedCallback(obj, options)
% function toolbarResizingMethod_ClickedCallback(obj, options)
% Function to set type of image interpolation for the visualization
%
% When the ''options'' variable is omitted the function works as a standard
% callback and changes the type of image interpolation: ''bicubic'' or ''nearest''.
% However, when ''options'' are specified the function sets the state of
% the button to the currently selected type.
%
% Parameters:
% options: [@em optional], 
% @li when @b ''keepcurrent'' set the state of the button to the currently
% selected type of the interpolation: @em
% obj.mibModel.preferences.imageResizeMethod
%
% Return values:
% 

%| @b Examples:
% @code obj.toolbarResizingMethod('keepcurrent');     // call from mibController; update the image interpolation button icon @endcode

% Copyright (C) 13.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin == 2  % when options are available
    if strcmp(options, 'keepcurrent')
        0;
    end
else
    if strcmp(obj.mibModel.preferences.imageResizeMethod, 'bicubic')
        obj.mibModel.preferences.imageResizeMethod = 'nearest';
    elseif strcmp(obj.mibModel.preferences.imageResizeMethod, 'nearest')
        obj.mibModel.preferences.imageResizeMethod = 'auto';
    else
        obj.mibModel.preferences.imageResizeMethod = 'bicubic';
    end
end

if strcmp(obj.mibModel.preferences.imageResizeMethod, 'auto')
    filename = 'image_auto.res';
    obj.mibView.handles.toolbarResizingMethod.TooltipString = 'automatic interpolation: bicubic for magnification < 100% and nearest for >=100%';
elseif strcmp(obj.mibModel.preferences.imageResizeMethod, 'bicubic')
    filename = 'image_bicubic.res';
    obj.mibView.handles.toolbarResizingMethod.TooltipString = 'bicubic interpolation for the visualization, press for neareast';
else
    filename = 'image_nearest.res';
    obj.mibView.handles.toolbarResizingMethod.TooltipString = 'nearest interpolation for the visualization, press for bicubic';
end

img = load(fullfile(obj.mibPath, 'Resources', filename), '-mat');  % load icon
obj.mibView.handles.toolbarResizingMethod.CData = img.image;

if nargin < 2
    obj.plotImage();
end

%if isfield(handles, 'Img')
%    handles.Img{handles.Id}.I.plotImage(handles.imageAxes, handles, 0);     % redraw the image
%else
%    guidata(handles.mibGUI, handles);       % during init of MIB from im_browser_getDefaultParameters
%end
end
