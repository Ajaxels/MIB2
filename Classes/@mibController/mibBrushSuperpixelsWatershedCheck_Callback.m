function mibBrushSuperpixelsWatershedCheck_Callback(obj, hObject)
% mibBrushSuperpixelsWatershedCheck_Callback(obj, hObject)
% callback for selection of superpixel mode for the brush tool
%
% Parameters:
% 

% Copyright (C) 04.03.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if hObject.Value == 0
    obj.mibView.handles.mibSuperpixelsNumberEdit.Enable = 'off';
    obj.mibView.handles.mibSuperpixelsCompactEdit.Enable = 'off';
else
    obj.mibView.handles.mibSuperpixelsNumberEdit.Enable = 'on';
    obj.mibView.handles.mibSuperpixelsCompactEdit.Enable = 'on';
    switch hObject.Tag
        case 'mibBrushSuperpixelsCheck'                % SLIC superpixels
            obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value = 0;
            obj.mibView.handles.mibBrushPanelNText.TooltipString = 'number of superpixels, larger number gives more precision, but slower';
            obj.mibView.handles.mibSuperpixelsNumberEdit.TooltipString = 'number of superpixels, larger number gives more precision, but slower';
            obj.mibView.handles.mibBrushPanelCompactText.String = 'Compact';
            obj.mibView.handles.mibBrushPanelCompactText.TooltipString = 'compactness factor, the larger the number more square resulting superpixels';
            obj.mibView.handles.mibSuperpixelsCompactEdit.TooltipString = 'compactness factor, the larger the number more square resulting superpixels';
            %obj.mibView.handles.mibSuperpixelsCompactEdit.Callback = {@editbox_Callback, guidata(hObject), 'posint', '0', [0,200]};
            obj.mibView.handles.mibSuperpixelsNumberEdit.String = num2str(obj.mibModel.preferences.superpixels.slic_n);
            obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.superpixels.slic_compact);
        case 'mibBrushSuperpixelsWatershedCheck'       % Watershed superpixels
            obj.mibView.handles.mibBrushSuperpixelsCheck.Value = 0;
            obj.mibView.handles.mibBushPanelNText.TooltipString = 'factor to modify size of superpixels, the larger number gives bigger superpixels';
            obj.mibView.handles.mibSuperpixelsNumberEdit.TooltipString = 'factor to modify size of superpixels, the larger number gives bigger superpixels';
            obj.mibView.handles.mibBrushPanelCompactText.String ='Invert';
            obj.mibView.handles.mibBrushPanelCompactText.TooltipString = 'put 0 if objects have bright boundaries or 1 if objects have dark boundaries';
            obj.mibView.handles.mibSuperpixelsCompactEdit.TooltipString = 'put 0 if objects have bright boundaries or 1 if objects have dark boundaries';
            %obj.mibView.handles.mibSuperpixelsCompactEdit.Callback = {@editbox_Callback, guidata(hObject), 'posint', '1', [0,1]};
            obj.mibView.handles.mibSuperpixelsNumberEdit.String = num2str(obj.mibModel.preferences.superpixels.watershed_n);
            obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.superpixels.watershed_invert);
    end
end
end