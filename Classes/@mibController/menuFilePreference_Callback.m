function menuFilePreference_Callback(obj)
% function menuFilePreference_Callback(obj)
% a callback to MIB->Menu->File->Preferences...
%

% Copyright (C) 12.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

obj.mibModel.preferences.modelMaterialColors = obj.mibModel.getImageProperty('modelMaterialColors');
obj.mibModel.preferences.lutColors = obj.mibModel.getImageProperty('lutColors');
obj.startController('mibPreferencesController', obj);
end