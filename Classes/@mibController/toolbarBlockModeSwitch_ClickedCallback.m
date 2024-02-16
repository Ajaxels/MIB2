% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function toolbarBlockModeSwitch_ClickedCallback(obj)
% function toolbarBlockModeSwitch_ClickedCallback(obj)
% a callback for press of obj.mibView.toolbarBlockModeSwitch in the toolbar
% of MIB
%

% Updates
% 

if strcmp(obj.mibView.handles.toolbarBlockModeSwitch.State, 'off')   
    obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch = 0;
else
    obj.mibModel.I{obj.mibModel.Id}.blockModeSwitch = 1;
end

