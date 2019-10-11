function menuModelsSaveAs_Callback(obj, parameter)
% function menuModelsSaveAs_Callback(obj, parameter)
% callback to Menu->Models->Save as
% save model to a file
%
% Parameters:
% parameter: a string
% @li ''saveas'' -> [@em default] start a dialog to select saving format and the filename 
% @li ''save'' -> save using existing filename

% Copyright (C) 06.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 04.06.2018 save TransformationMatrix with AmiraMesh

if nargin < 2; parameter = 'saveas'; end

if obj.mibModel.showAllMaterials == 1
    BatchOpt.MaterialIndex = '0';
else
    BatchOpt.MaterialIndex = num2str(obj.mibModel.I{obj.mibModel.Id}.selectedMaterial - 2);
end
switch parameter
    case 'save'
        filename = obj.mibModel.saveModel(obj.mibModel.I{obj.mibModel.Id}.modelFilename, BatchOpt);
    case 'saveas'
        filename = obj.mibModel.saveModel([], BatchOpt);
end

obj.updateFilelist(filename);
obj.plotImage();
end
