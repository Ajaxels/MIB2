function menuImageToolsContentAware_Callback(obj)
% function menuImageToolsContentAware_Callback(obj)
% callback to the Menu->Image->Tools->Content-aware fill, fill the selected
% area using content aware algorithms
%
% Parameters:
% 

% Copyright (C) 16.04.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.mibModel.contentAwareFill();

end