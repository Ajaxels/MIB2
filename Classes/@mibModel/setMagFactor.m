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

function setMagFactor(obj, magFactor, id)
% function setMagFactor(obj, magFactor, id)
% set magnification for the currently shown or id dataset
%
% Parameters:
% magFactor: magnification factor
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% 

%| 
% @b Examples:
% @code obj.mibModel.setMagFactor(2);     // call from mibController: set current magFactor to 2 @endcode
% @code obj.mibModel.setMagFactor(2, 4);     // call from mibController: set current magFactor to 2 for dataset 4 @endcode

% Updates
% 
if nargin < 3; id = obj.Id; end 
if nargin < 2
    errordlg(sprintf('!!! Error !!!\n\nthe magFactor parameter is missing'),'mibModel.setMagFactor');
    return;
end
obj.I{id}.magFactor = magFactor;
end


