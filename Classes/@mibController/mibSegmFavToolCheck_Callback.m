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

function mibSegmFavToolCheck_Callback(obj)
% function mibSegmFavToolCheck_Callback(obj)
% callback to the obj.mibView.handles.mibSegmFavToolCheck, to add the
% selected tool to the list of favourites
%
% Parameters:
%
% Return values:
% 

% Updates
%

toolId = obj.mibView.handles.mibSegmentationToolPopup.Value;
favId = obj.mibView.handles.mibSegmFavToolCheck.Value;

if favId == 1 % add the selected tool to the list of fast access tools
    obj.mibModel.preferences.SegmTools.PreviousTool(end+1) = toolId;
    obj.mibView.handles.mibSegmentationToolPopup.BackgroundColor = [1 .69 .39];
else    % remove the selected tool to the list of fast access tools
    pos = obj.mibModel.preferences.SegmTools.PreviousTool(find(obj.mibModel.preferences.SegmTools.PreviousTool == toolId, 1));
    obj.mibModel.preferences.SegmTools.PreviousTool = obj.mibModel.preferences.SegmTools.PreviousTool(obj.mibModel.preferences.SegmTools.PreviousTool ~= pos);
    obj.mibView.handles.mibSegmentationToolPopup.BackgroundColor = [1 1 1];
end
obj.mibModel.preferences.SegmTools.PreviousTool = sort(obj.mibModel.preferences.SegmTools.PreviousTool);
end