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
% Date: 08.05.2024

function saveInstanceLabelsParFor(fn, imageFilename, instanceBoxes, instanceNames, instanceMasks, compressModels)
% saveInstanceLabelsParFor(fn, imageFilename, instanceBoxes, instanceNames, instanceMasks, compressModels)
% saving from parfor loop converted labels for training of 2D instance segmentation
% as it is not possible to use save directly inside parfor.
% This function is used in
% mibDeepController.processImagesForInstanceSegmentation to preprocess
% instance labels
%
% Parameters:
% fn:   string with the full output filename
% imageFilename: string with the corresponding image filename
% instanceBoxes: matrix  [N×4 double] containing bounding box coordinates of objects, where N is a number of objects on the image
% instanceNames: array [N×1 categorical] containing names of objects,
% currently the same name should be used for all objects, can be any string
% converted to categorical.
% instanceMasks: matrix [720×1280×N logical] binary masks where each slice
% represents individual object that should match the corresponding entry in
% instanceBoxes and instanceNames
% compressModels:  logical switch to use of not compression for images

if nargin < 6; compressModels = true; end

if compressModels     % saving images
    save(fn, 'imageFilename', 'instanceBoxes', 'instanceNames', 'instanceMasks', '-mat', '-v7.3');   % save image file
else
    save(fn, 'imageFilename', 'instanceBoxes', 'instanceNames', 'instanceMasks', '-nocompression', '-mat', '-v7.3');
end
end