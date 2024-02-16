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

function magFactor = getMagFactor(obj, id)
% function mag = getMagFactor(obj, id)
% get magnification for the currently shown or id dataset
%
% Parameters:
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% magFactor: magnification factor

%| 
% @b Examples:
% @code magFactor = obj.mibModel.getMagFactor();     // call from mibController: get current magFactor @endcode
% @code magFactor = obj.mibModel.getMagFactor(2);     // call from mibController: get magFactor for dataset 2 @endcode

% Updates
% 

if nargin < 2; id = obj.Id; end
magFactor = obj.I{id}.magFactor;

end


