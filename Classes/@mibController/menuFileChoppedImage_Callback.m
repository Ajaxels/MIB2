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

function menuFileChoppedImage_Callback(obj, parameter)
% function menuFileChoppedImage_Callback(obj, parameter)
% a callback to Menu->File->Chopped images, chop/rechop dataset to/from
% smaller subsets
%
% Parameters:
% parameter: [@em optional] a string that defines image source:
% - 'import', [default] import multiple datasets and assemble them in one big dataset
% - 'export', chop the currently opened dataset to a set of smaller ones

% Updates
%

if nargin < 2;     parameter = 'import'; end

switch parameter
    case 'import'
        % check for the virtual stacking mode and disable it
        if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
            result = obj.toolbarVirtualMode_ClickedCallback(0);  % switch to the memory-resident mode
            if isempty(result) || result == 1; return; end
        end
        
        obj.startController('mibRechopDatasetController');
        obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection = [2 1];  % last selected contour for use with the 'e' button
    case 'export'
        obj.startController('mibChopDatasetController');
end