% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function menuFilePreference_Callback(obj)
% function menuFilePreference_Callback(obj)
% a callback to MIB->Menu->File->Preferences...
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