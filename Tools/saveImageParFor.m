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

function saveImageParFor(fn, imgOut, compressImage, options)
% saveImageParFor(fn, imgOut, compressImage)
% saving image from parfor loop
% as it is not possible to use save directly inside parfor
% this function is used in mibDeepController to preprocess images
%
% Parameters:
% fn:   string with the full filename
% imgOut:    matrix to be saved
% compressionImage:  logical switch to use of not compression for images
% options: a structure with additional parameters
% .dimOrder - a string with definition of axes, for example 'yxzct' -
% defines it as [height, width, depth, color, time]
% .modelType - double, type of the model: 63, 255, 65636, 
% .modelMaterialNames - cell array with classNames
% .modelMaterialColors - matrix with class colors [colorId, R G B]

if nargin < 4; options = struct(); end
if ~isfield(options, 'dimOrder'); options.dimOrder = 'yxzct'; end

imgVariable = 'imgOut';     % defines name of the variable in the file with the image

if compressImage     % saving images
    save(fn, 'imgOut', 'imgVariable', 'options', '-mat', '-v7.3');   % save image file
else
    save(fn, 'imgOut', 'imgVariable', 'options', '-nocompression', '-mat', '-v7.3');
end
end