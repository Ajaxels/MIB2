function startPlugin(obj, pluginName)
% function startPlugin(obj, pluginName)
% start plugin from MIB menu
%
% Parameters:
% pluginName: name of the plugin (same as name of directory where it is stored)
%
% Return values
%

% Copyright (C) 01.03.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.startController([pluginName 'Controller']);
end
