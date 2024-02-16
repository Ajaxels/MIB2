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

function exitProgram(obj)
% function exitProgram()
% Executes when user attempts to close MIB

%| 
% @b Examples:
% @code handles.mibController.exitProgram();     // use this function in minGUI @endcode
 
% Updates
%

% close child controllers
for i=numel(obj.childControllers):-1:1
    if isvalid(obj.childControllers{i})
        obj.childControllers{i}.closeWindow();
    end
end

if isprop(obj, 'DragNDrop') && ~isempty(obj.DragNDrop)
    delete(obj.DragNDrop);  % delete class and make property empty
    obj.DragNDrop = [];
end

% unload OMERO
if ~isdeployed
    if exist('unloadOmero.m','file') == 2
        % preserve Omero path
        omeroPath = findOmero;
        warning('off','MATLAB:javaclasspath:jarAlreadySpecified');    % switch off warnings for latex
        unloadOmero;
        addpath(omeroPath);
        warning('on','MATLAB:javaclasspath:jarAlreadySpecified');    % switch off warnings for latex
    end
end

% define structure to store preferences
mib_pars = struct();
mib_pars.preferences = obj.mibModel.preferences; %#ok<STRNU>     % store preferences
mib_pars.preferences.System.Dirs.LastPath = obj.mibModel.myPath;    % store current path
mib_pars.mibVersion = obj.mibVersionNumeric;   % define version of MIB for which preferences generated

prefdir = getPrefDir();
try
    save(fullfile(prefdir, 'mib.mat'), 'mib_pars');
    % additionally save preferences.Users.Tiers
    Tiers = obj.mibModel.preferences.Users.Tiers;
    save(fullfile(prefdir, 'mib_user.mat'), 'Tiers');
catch err
    errordlg(sprintf('There is a problem with saving preferences to\n%s\n%s', fullfile(prefdir, 'mib.mat'), err.identifier), 'Error');
end
end