function toolbarBlockModeSwitch_ClickedCallback(obj)
% function toolbarBlockModeSwitch_ClickedCallback(obj)
% a callback for press of obj.mibView.toolbarBlockModeSwitch in the toolbar
% of MIB
%

% Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

if strcmp(obj.mibView.handles.toolbarBlockModeSwitch.State, 'off')   
    obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch = 0;
else
    obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch = 1;
end

