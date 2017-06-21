function menuHelpAbout_Callback(obj)
% function menuHelpAbout_Callback(obj)
% callback to Menu->Help->About
% show the About window
%

% Copyright (C) 28.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

obj.startController('mibAboutController', obj.mibView.gui.Name);
end