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
% 04.05.2021, added a new Preferences window for R2020a or newer

obj.mibModel.preferences.Colors.ModelMaterialColors = obj.mibModel.getImageProperty('modelMaterialColors');
obj.mibModel.preferences.Colors.LUTColors = obj.mibModel.getImageProperty('lutColors');
if verLessThan('matlab','9.8')
    obj.startController('mibPreferencesController', obj); % an old guide version
else
    
    obj.startController('mibPreferencesAppController', obj);  % a new appdesigner version
end

end