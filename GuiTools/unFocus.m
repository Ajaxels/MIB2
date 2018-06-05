function unFocus(hObject)
% function unFocus(hObject)
% move focus to the main window

% Copyright (C) 22.04.2014, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

hObject.Enable = 'off';
drawnow;
hObject.Enable = 'on';
end
