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

function updateShownId(obj, Id)
% function updateShownId(Id)
% update index of the displayed dataset, after, for example press of the
% handles.mibBufferToggle buttons in mibGUI
%
% Parameters:
% Id: index of the dataset
%

%| 
% @b Examples:
% @code obj.updateShownId(str2double(Id));     // a call from obj.mibBufferToggle_Callback  @endcode

% Updates
%

mibPrevId = obj.mibModel.Id;
obj.mibModel.mibPrevId = num2str(obj.mibModel.Id);   % update previously shown id
obj.mibModel.Id = Id;               % update Id

pressedButtonStr = num2str(Id);
pressedButtonHandle = sprintf('mibBufferToggle%i', obj.mibModel.Id);
prevButtonHandle = ['mibBufferToggle' obj.mibModel.mibPrevId];

% check for coming from a linked view
if obj.mibView.handles.(pressedButtonHandle).ContextMenu.Children(3).Text(10) == pressedButtonStr && ...
        obj.mibView.handles.(pressedButtonHandle).ContextMenu.Children(3).Text(16) == obj.mibModel.mibPrevId
    if sum(obj.mibModel.I{obj.mibModel.Id}.dim_yxczt([1,2,4])) ~= sum(obj.mibModel.I{mibPrevId}.dim_yxczt([1,2,4]))
        warndlg(sprintf('!!! Error !!!\n\nDimensions of the datasets most likely mismatch!\nThe link mode is desabled!'),'Dimensions mismatch!');

        obj.mibView.handles.(pressedButtonHandle).ContextMenu.Children(3).Text = 'Link view with... [Unlinked]';
        obj.mibView.handles.(prevButtonHandle).ContextMenu.Children(3).Text = 'Link view with... [Unlinked]';
        notify(obj.mibModel, 'stopProtocol');
    else
        obj.mibModel.I{obj.mibModel.Id}.slices = obj.mibModel.I{mibPrevId}.slices;
        obj.mibModel.I{obj.mibModel.Id}.axesX = obj.mibModel.I{mibPrevId}.axesX;
        obj.mibModel.I{obj.mibModel.Id}.axesY = obj.mibModel.I{mibPrevId}.axesY;
        obj.mibModel.I{obj.mibModel.Id}.magFactor = obj.mibModel.I{mibPrevId}.magFactor;
    end
end

notify(obj.mibModel, 'updateId');   % notify the controller about updated Id
obj.plotImage(0);                   % plot image
end