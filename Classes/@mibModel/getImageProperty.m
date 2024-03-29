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

function propertyValue = getImageProperty(obj, propertyName, id)
% function propertyValue = getImageProperty(obj, propertyName, id)
% get desired property for the currently shown or id dataset
%
% Parameters:
% propertyName: a string with property name for mibImage class
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% propertyValue: a value for the desired property, or empty

%|
% @b Examples:
% @code orientation = obj.mibModel.getImageProperty('orientation');     // call from mibController: get orientation for the current dataset @endcode
% @code orientation = obj.mibModel.getImageProperty('orientation', 2);     // call from mibController: get orientation for dataset 2 @endcode

% Updates
% 
propertyValue = [];

if nargin < 3; id = obj.Id; end
if isprop(obj.I{id}, propertyName) == 0
    errordlg(sprintf('Error in mibModel: getImageProperty!\n\nWrong property name'), 'Wrong property');
    return;
end
propertyValue = obj.I{id}.(propertyName);
end


