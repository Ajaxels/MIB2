function mibBrushSuperpixelsEdit_Callback(obj, hObject)
% mibBrushSuperpixelsEdit_Callback(obj, hObject)
% callback for modification of superpixel mode settings of the brush tool
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

val = round(str2double(hObject.String));

if obj.mibView.handles.mibBrushSuperpixelsCheck.Value == 1  % slic mode
    switch hObject.Tag
        case 'mibSuperpixelsNumberEdit'
            if val < 1 
                errordlg(sprintf('!!! Error !!!\nthe value should be positive integer!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.superpixels.slic_n);
                return;
            end
            obj.mibModel.preferences.superpixels.slic_n = val;
        case 'mibSuperpixelsCompactEdit'
            if val < 0 
                errordlg(sprintf('!!! Error !!!\nthe value should be positive integer!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.superpixels.slic_compact);
                return;
            end
            obj.mibModel.preferences.superpixels.slic_compact = val;
    end
elseif obj.mibView.handles.mibBrushSuperpixelsWatershedCheck.Value == 1     % watershed mode
    switch hObject.Tag
        case 'mibSuperpixelsNumberEdit'
            if val < 0 
                errordlg(sprintf('!!! Error !!!\nthe value should be positive integer or 0!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.superpixels.watershed_n);
                return;
            end
            obj.mibModel.preferences.superpixels.watershed_n = val;
        case 'mibSuperpixelsCompactEdit'
            if ~ismember(val, [0 1]) 
                errordlg(sprintf('!!! Error !!!\nthe value should be 0 or 1!'), 'Wrong value', 'modal');
                obj.mibView.handles.mibSuperpixelsCompactEdit.String = num2str(obj.mibModel.preferences.superpixels.watershed_invert);
                return;
            end
            obj.mibModel.preferences.superpixels.watershed_invert = val;
    end
end

end