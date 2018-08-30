function transposeZ2T(obj)
% function transposeZ2T(obj)
% transpose Z to T dimension
%
% Copyright (C) 02.02.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

wb = waitbar(0,sprintf('Transposing the image\nPlease wait...'), ...
    'Name', 'Transpose dataset [Z->T]', 'WindowStyle', 'modal');
options.blockModeSwitch = 0;    % overwrite blockmode switch
img = cell2mat(obj.getData4D('image', 4, 0, options));   % get dataset (image)
img = permute(img,[1, 2, 3, 5, 4]);
obj.setData4D('image', img, 4, 0, options);   % get dataset (image)
% transpose other layers
if obj.I{obj.Id}.modelType == 63 && obj.I{obj.Id}.disableSelection == 0
    waitbar(0.5, wb, sprintf('Transposing other layers\nPlease wait...'));
    img = obj.I{obj.Id}.model{1};   % get dataset (image)
    obj.I{obj.Id}.model{1} = zeros([size(img, 1), size(img, 2), size(img, 4), size(img, 3)], 'uint8');
    img = permute(img,[1, 2, 4, 3]);
    obj.setData4D('everything', img, 4, 0, options);   % get dataset (image)
elseif obj.I{obj.Id}.disableSelection == 0
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