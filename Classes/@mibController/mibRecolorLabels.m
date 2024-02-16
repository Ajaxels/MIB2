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

function mibRecolorLabels(obj)       
% function mibRecolorLabels(obj)       
% recolor color map for 65535+ models
%
%
% Parameters:
%
% Return values:
% 

% Updates
%

obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors = rand(65535,3);    % generate vector for colors
obj.updateSegmentationTable();
obj.plotImage();