function generateModelColors(obj)
% function generateModelColors(obj)
% Generate list of colors for materials of a model. 
%
% When a new material is added to a model, this function generates a random color for it.
%
% Parameters:
% 
% Return values:
% status: result of the function: 0-fail/1-success

%| 
% @b Examples:
% @code obj.mibModel.I{obj.mibModel.Id}.generateModelColors();  // call from mibController, generate colors @endcode
% @code obj.mibModel.getImageMethod('generateModelColors'); // call from mibController via a wrapper function getImageMethod @endcode

% Copyright (C) 20.11.2016, Ilya Belevich (ilya.belevich @ helsinki.fi)
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% Updates
% 
status = 0;
if size(obj.modelMaterialColors,1) < numel(obj.modelMaterialNames)
    for i=size(obj.modelMaterialColors,1)+1:numel(obj.modelMaterialNames)
        obj.modelMaterialColors(i,:) = [rand(1) rand(1) rand(1)];
    end
end
status = 1;
end