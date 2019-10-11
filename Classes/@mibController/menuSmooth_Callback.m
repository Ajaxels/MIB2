function menuSmooth_Callback(obj, type)
% function menuSmooth_Callback(obj, type)
% callback to the smooth mask, selection or model layer
%
% Parameters:
% type: a string with type of the layer for the smoothing
% - ''selection'' - run size exclusion on the Selection layer
% - ''model'' - - run size exclusion on the Model layer
% - ''mask'' - - run size exclusion on the Mask layer

% Copyright (C) 10.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1
    warndlg(sprintf('The selection layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The selection layer is disabled', 'modal');
    return; 
end

% Smooth Mask, Selection or Model layers
obj.mibModel.smoothImage(type);
obj.plotImage();

end