function menuMaskLoad_Callback(obj)
% function menuMaskLoad_Callback(obj)
% callback to Menu->Mask->Load Mask; load the Mask layer to MIB from a file
%
% Parameters:
% 

% Copyright (C) 08.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 12.12.2018 added loading of masks that are smaller or larger than the depth of the dataset

obj.mibModel.loadMask();
