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

function pixSize = getPixSize(obj, id)
% function pixSize = getPixSize(obj, id)
% get pixSize structure for the currently shown or id dataset
%
% Parameters:
% id: [@b optional], id of the dataset, otherwise the currently shown
% dataset (obj.Id)
%
% Return values:
% pixSize: a structure with diminsions of voxels, @code .x .y .z .t .tunits .units @endcode
% the fields are
% @li .x - physical width of a pixel
% @li .y - physical height of a pixel
% @li .z - physical thickness of a pixel
% @li .t - time between the frames for 2D movies
% @li .tunits - time units
% @li .units - physical units for x, y, z. Possible values: [m, cm, mm, um, nm]

%|
% @b Examples:
% @code pixSize = obj.mibModel.getPixSize();     // call from mibController: get current pixSize @endcode
% @code pixSize = obj.mibModel.getPixSize(2);     // call from mibController: get pixSize for dataset 2 @endcode

% Updates
% 

if nargin < 2; id = obj.Id; end;
pixSize = obj.I{id}.pixSize;

end


