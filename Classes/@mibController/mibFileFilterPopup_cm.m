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

function mibFileFilterPopup_cm(obj, parameter)
% function mibFileFilterPopup_cm(obj, parameter)
% a context menu to the to the handles.mibFileFilterPopup, the menu is called
% with the right mouse button
%
% Parameters:
% parameter: a string with parameters for the function
% @li 'register' - register extensions for file filters

% Updates
% 

global mibPath; % path to mib installation folder

switch parameter
    case {'register'}
        prompts = {'Standard file reader:'; ...
                   'Standard file reader, virtual mode:'; ...
                   'Bioformats file reader:'; ...
                   'Bioformats file reader, virtual mode:'};
        defAns = {'', '', '',''};
        options.PromptLines = [1, 1, 1, 1];
        dlgtitle = 'Register file extension';
        options.Title = sprintf('Add file extension to the list of filters.\nMultiple extensions should be separated with semicolor, for example:\n"tif; png; jpg"');
        options.TitleLines = 5;
        output = mibInputMultiDlg({mibPath}, prompts, defAns, dlgtitle, options);
        if isempty(output); return; end
        
        %ismember(obj.mibModel.preferences.System.Files.StdExt, output{4})
        if ~isempty(output{1})
            newExt = strsplit(strrep(output{1}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.System.Files.StdExt)) = [];
            obj.mibModel.preferences.System.Files.StdExt = sort([obj.mibModel.preferences.System.Files.StdExt, newExt]);
        end
        if ~isempty(output{2})
            newExt = strsplit(strrep(output{2}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.System.Files.StdVirtExt)) = [];
            obj.mibModel.preferences.System.Files.StdVirtExt = sort([obj.mibModel.preferences.System.Files.StdVirtExt, newExt]);
        end
        if ~isempty(output{3})
            newExt = strsplit(strrep(output{3}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.System.Files.BioFormatsExt)) = [];
            obj.mibModel.preferences.System.Files.BioFormatsExt = sort([obj.mibModel.preferences.System.Files.BioFormatsExt, newExt]);
        end
        if ~isempty(output{4})
            newExt = strsplit(strrep(output{4}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.System.Files.BioFormatsVirtExt)) = [];
            obj.mibModel.preferences.System.Files.BioFormatsVirtExt = sort([obj.mibModel.preferences.System.Files.BioFormatsVirtExt, newExt]);
        end
    case {'remove'}
        selVal = obj.mibView.handles.mibFileFilterPopup.Value;
        extList = obj.mibView.handles.mibFileFilterPopup.String;
        if strcmp(extList{selVal}, 'all known')
            errordlg(sprintf('The extension was not selected,\nplease select an extension and try again!'), 'Wrong selection');
            return
        end
        answer = questdlg(sprintf('!!! Warning !!!\n\nYou are going to remove "%s" from the list of extensions\nContinue?', extList{selVal}), 'Remove extension', 'Continue', 'Cancel', 'Cancel');
        if strcmp(answer, 'Cancel'); return; end
        
        if obj.mibView.handles.mibBioformatsCheck.Value == 1     % use bioformats reader
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                obj.mibModel.preferences.System.Files.BioFormatsVirtExt(ismember(obj.mibModel.preferences.System.Files.BioFormatsVirtExt, extList{selVal})) = [];
            else
                obj.mibModel.preferences.System.Files.BioFormatsExt(ismember(obj.mibModel.preferences.System.Files.BioFormatsExt, extList{selVal})) = [];
            end
        else
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                obj.mibModel.preferences.System.Files.StdVirtExt(ismember(obj.mibModel.preferences.System.Files.StdVirtExt, extList{selVal})) = [];
            else
                obj.mibModel.preferences.System.Files.StdExt(ismember(obj.mibModel.preferences.System.Files.StdExt, extList{selVal})) = [];
            end
        end
        
end
obj.mibBioformatsCheck_Callback();
end