function menuMaskSaveAs_Callback(obj)
% function menuMaskSaveAs_Callback(obj)
% callback to Menu->Mask->Save As; save the Mask layer to a file
%
% Parameters:
% 

% Copyright (C) 02.08.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

filename = obj.mibModel.saveMask();
obj.updateFilelist(filename);
