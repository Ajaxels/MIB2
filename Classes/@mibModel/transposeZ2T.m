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

function transposeZ2T(obj)
% function transposeZ2T(obj)
% transpose Z to T dimension

% Updates
% 

wb = waitbar(0,sprintf('Transposing the image\nPlease wait...'), ...
    'Name', 'Transpose dataset [Z->T]', 'WindowStyle', 'modal');
options.blockModeSwitch = 0;    % overwrite blockmode switch
img = cell2mat(obj.getData4D('image', 4, 0, options));   % get dataset (image)
img = permute(img,[1, 2, 3, 5, 4]);
obj.setData4D('image', img, 4, 0, options);   % get dataset (image)
% transpose other layers
if obj.I{obj.Id}.modelType == 63 && obj.I{obj.Id}.enableSelection == 1
    waitbar(0.5, wb, sprintf('Transposing other layers\nPlease wait...'));
    img = obj.I{obj.Id}.model{1};   % get dataset (image)
    obj.I{obj.Id}.model{1} = zeros([size(img, 1), size(img, 2), size(img, 4), size(img, 3)], 'uint8');
    img = permute(img,[1, 2, 4, 3]);
    obj.setData4D('everything', img, 4, 0, options);   % get dataset (image)
elseif obj.I{obj.Id}.enableSelection == 1
    waitbar(0.25, wb, sprintf('Transposing the selection layer\nPlease wait...'));
    img = obj.I{obj.Id}.selection{1};   % get dataset (image)
    obj.I{obj.Id}.selection{1} = zeros([size(img, 1), size(img, 2), size(img, 4), size(img, 3)], 'uint8');
    img = permute(img, [1, 2, 4, 3]);
    obj.setData4D('selection', img, 4, 0, options);   % get dataset (image)
    
    if obj.I{obj.Id}.maskExist
        waitbar(0.5, wb, sprintf('Transposing the mask layer\nPlease wait...'));
        img = obj.I{obj.Id}.maskImg{1};   % get dataset (image)
        obj.I{obj.Id}.maskImg{1} = zeros([size(img, 1), size(img, 2), size(img, 4), size(img, 3)], 'uint8');
        img = permute(img,[1, 2, 4, 3]);
        obj.setData4D('mask', img, 4, 0, options);   % get dataset (image)
    end
    
    if obj.I{obj.Id}.modelExist
        waitbar(0.75, wb, sprintf('Transposing the model layer\nPlease wait...'));
        img = obj.I{obj.Id}.model{1};   % get dataset (image)
        obj.I{obj.Id}.model{1} = zeros([size(img, 1), size(img, 2), size(img, 4), size(img, 3)], 'uint8');
        img = permute(img,[1, 2, 4, 3]);
        obj.setData4D('model', img, 4, 0, options);   % get dataset (image)
    end
end
waitbar(1, wb, sprintf('Finishing...'));
clear img;
delete(wb);

end