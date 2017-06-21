function menuImageColorCh_Callback(obj, parameter)
% function menuImageColorCh_Callback(obj, parameter)
% callback to Menu->Image->Color Channels do actions with individual color channels
%
% Parameters:
% parameter: a string that defines image source:
% - 'insert', insert an empty color channel to the specified position
% - 'copy', copy color channel to a new position
% - 'invert', invert color channel
% - 'rotate', rotate color channel
% - 'swap', swap two color channels
% - 'delete', delete color channel from the dataset

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

switch parameter
    case 'insert'
        obj.mibModel.I{obj.mibModel.Id}.insertEmptyColorChannel();
        obj.updateGuiWidgets();
    case 'copy'
        obj.mibModel.I{obj.mibModel.Id}.copyColorChannel();
        obj.updateGuiWidgets();
    case 'invert'
        if obj.mibModel.I{obj.mibModel.Id}.time < 2
            obj.mibModel.mibDoBackup('image', 1); 
        end;
        obj.mibModel.I{obj.mibModel.Id}.invertColorChannel();
    case 'rotate'
        if obj.mibModel.I{obj.mibModel.Id}.time < 2
            obj.mibModel.mibDoBackup('image', 1); 
        end;
        obj.mibModel.I{obj.mibModel.Id}.rotateColorChannel();        
    case 'swap'
        if obj.mibModel.I{obj.mibModel.Id}.time < 2
            obj.mibModel.mibDoBackup('image', 1); 
        end;
        obj.mibModel.I{obj.mibModel.Id}.swapColorChannels();
    case 'delete'
        obj.mibModel.I{obj.mibModel.Id}.deleteColorChannel();
        obj.updateGuiWidgets();
end    
obj.plotImage(1);
end