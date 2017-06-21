function menuModelsConvertModel(obj, modelType)
% function menuModelsConvertModel(obj, modelType)
% callback to Menu->Models->Convert, convert the model to a different modelType
%
% Parameters:
% modelType: a double that specifies new type of the model
% @li 63 - model with 63 materials, the fastest to use, utilize less memory
% @li 255 - model with 255 materials, the slower to use, utilize x2 more memory than 63-material type

% Copyright (C) 03.04.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if modelType == obj.mibModel.I{obj.mibModel.Id}.modelType
    % nothing to change
    return;
end
obj.mibModel.I{obj.mibModel.Id}.convertModel(modelType);
obj.updateGuiWidgets();
end