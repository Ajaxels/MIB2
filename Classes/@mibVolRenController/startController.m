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

function startController(obj, controllerName, varargin)
% function startController(obj, controllerName, varargin)
% start a child controller using provided name
%
% Parameters:
% controllerName: a string with name of a child controller, for example, 'mibImageAdjController'
% varargin: additional optional controllers or parameters
% 

%| 
% @b Examples:
% @code handles.mibController.startController('mibImageAdjController');     // start a child controller from a callback for handles.mibDisplayBtn press  @endcode

% Updates
%

id = obj.findChildId(controllerName);        % define/find index for this child controller window
if ~isempty(id)
    try
        figure(obj.childControllers{id}.View.gui);
        obj.childControllers{id}.updateWidgets();   % update widgets of the controller when restarting it
        return; 
    catch err
        obj.childControllersIds(id) = [];
        obj.childControllersIds = obj.childControllersIds(~cellfun('isempty', obj.childControllersIds));
    end
end   % return if controller is already opened

% assign id and populate obj.childControllersIds for a new controller
id = numel(obj.childControllersIds) + 1;    
obj.childControllersIds{id} = controllerName;

fh = str2func(controllerName);               %  Construct function handle from character vector
if nargin > 2 
    obj.childControllers{id} = fh(obj.mibModel, varargin{1:numel(varargin)});    % initialize child controller with additional parameters
else
    obj.childControllers{id} = fh(obj.mibModel);    % initialize child controller
end

% add listener to the closeEvent of the child controller
addlistener(obj.childControllers{id}, 'closeEvent', @(src, evnt) mibController.purgeControllers(obj, src, evnt));   % static
%addlistener(obj.childControllers{id}, 'closeEvent', @(src, evnt) obj.purgeControllers(src, evnt)); % dynamic

p = fieldnames(obj.childControllers{id});
if ismember('noGui', p)
    notify(obj.childControllers{id}, 'closeEvent');
end

end