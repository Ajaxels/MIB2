function menuModelsImport_Callback(obj)
% function menuModelsImport_Callback(obj)
% callback to Menu->Models->Import;
% import the Model layer from the main Matlab workspace
%
% Parameters:
% 

% Copyright (C) 06.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;

% do nothing is selection is disabled
if obj.mibModel.preferences.disableSelection == 1
    warndlg(sprintf('The model layer is switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),...
        'The models are disabled', 'modal');
    return;
end

prompt = sprintf('Enter the name of the model variable.\nIt may be a matrix (1:height,1:width,1:z,1:t)\nor a structure with "model" and "materials" fields');
title = 'Import from Matlab';
%answer = inputdlg(prompt,title,1,{'O'},'on');
answer = mibInputDlg({mibPath}, prompt, title, 'O');
if size(answer) == 0; return; end

if (~isempty(answer{1}))
    try
        varIn = evalin('base',answer{1});
    catch exception
        errordlg(sprintf('The variable was not found in the Matlab base workspace:\n\n%s', exception.message), 'Misssing variable!', 'modal');
        return;
    end
    
    options = struct();
    if isstruct(varIn)
        if isfield(varIn, 'modelVariable')
            options.modelVariable = varIn.modelVariable; 
        else
            options.modelVariable = 'model';
        end
        model = varIn.(options.modelVariable);
        if isfield(varIn, 'modelMaterialNames')
            options.modelMaterialNames = varIn.modelMaterialNames; 
        end
        if isfield(varIn, 'modelMaterialColors')
            %material_colors = varIn.colors;
            options.modelMaterialColors = varIn.modelMaterialColors;
        end
        if isfield(varIn, 'labelText')
            options.labelText = varIn.labelText;
            options.labelPosition = varIn.labelPosition;
        end
        
        if isfield(varIn, 'modelType')
            options.modelType = varIn.modelType;
        else
            maxModelValue = max(max(max(max(model))));
            if maxModelValue < 64
                options.modelType = 63;
            else
                options.modelType = 255;
            end
        end
    else
        model = varIn;
    end
    obj.mibLoadModelBtn_Callback(model, options);
end
