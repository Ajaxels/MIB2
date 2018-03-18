function mibBrushPanelInterpolationSettingsBtn_Callback(obj, hObject)
% mibBrushPanelInterpolationSettingsBtn_Callback(obj, hObject)
% callback for modification of superpixel mode settings of the brush tool
%
% Parameters:
% 

% Copyright (C) 11.03.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;

if strcmp(obj.mibModel.preferences.interpolationType, 'shape')
    typeVal = 1;
else
    typeVal = 2;
end

prompts = {'Interpolation type'; sprintf('Number of points\n(more points give smoother results\nbut longer to calculate):'); 'Line width (only for the line interpolation)'};
defAns = {{'Shape', 'Line', typeVal}; obj.mibModel.preferences.interpolationNoPoints; obj.mibModel.preferences.interpolationLineWidth};
dlgTitle = 'Interpolation settings';
options.WindowStyle = 'normal';       % [optional] style of the window
options.Focus = 1;      % [optional] define index of the widget to get focus
options.PromptLines = [1, 3, 1];   % [optional] number of lines for widget titles
[answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
if isempty(answer); return; end

noPoints = round(str2double(answer{2}));
if noPoints < 2
    errordlg(sprintf('!!! Error !!!\n\nNumber of points should be more than 1'), 'Wrong value');
    return;
end
lineWidth = round(str2double(answer{3}));
if lineWidth < 1
    errordlg(sprintf('!!! Error !!!\n\nLine width should be more than 0'), 'Wrong value');
    return;
end
    
obj.mibModel.preferences.interpolationType = lower(answer{1});
obj.mibModel.preferences.interpolationNoPoints = noPoints;
obj.mibModel.preferences.interpolationLineWidth = lineWidth;
obj.toolbarInterpolation_ClickedCallback('keepcurrent');     % update the interpolation button icon
unFocus(obj.mibView.handles.mibBrushPanelInterpolationSettingsBtn);
end