function mibFileFilterPopup_cm(obj, parameter)
% function mibFileFilterPopup_cm(obj, parameter)
% a context menu to the to the handles.mibFileFilterPopup, the menu is called
% with the right mouse button
%
% Parameters:
% parameter: a string with parameters for the function
% @li 'register' - register extensions for file filters

% Copyright (C) 22.11.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
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
        
        %ismember(obj.mibModel.preferences.Filefilter.stdExt, output{4})
        if ~isempty(output{1})
            newExt = strsplit(strrep(output{1}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.Filefilter.stdExt)) = [];
            obj.mibModel.preferences.Filefilter.stdExt = sort([obj.mibModel.preferences.Filefilter.stdExt, newExt]);
        end
        if ~isempty(output{2})
            newExt = strsplit(strrep(output{2}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.Filefilter.stdVirtExt)) = [];
            obj.mibModel.preferences.Filefilter.stdVirtExt = sort([obj.mibModel.preferences.Filefilter.stdVirtExt, newExt]);
        end
        if ~isempty(output{3})
            newExt = strsplit(strrep(output{3}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.Filefilter.bioExt)) = [];
            obj.mibModel.preferences.Filefilter.bioExt = sort([obj.mibModel.preferences.Filefilter.bioExt, newExt]);
        end
        if ~isempty(output{4})
            newExt = strsplit(strrep(output{4}, ' ', ''), ';');
            newExt(ismember(newExt, obj.mibModel.preferences.Filefilter.bioVirtExt)) = [];
            obj.mibModel.preferences.Filefilter.bioVirtExt = sort([obj.mibModel.preferences.Filefilter.bioVirtExt, newExt]);
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
                obj.mibModel.preferences.Filefilter.bioVirtExt(ismember(obj.mibModel.preferences.Filefilter.bioVirtExt, extList{selVal})) = [];
            else
                obj.mibModel.preferences.Filefilter.bioExt(ismember(obj.mibModel.preferences.Filefilter.bioExt, extList{selVal})) = [];
            end
        else
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                obj.mibModel.preferences.Filefilter.stdVirtExt(ismember(obj.mibModel.preferences.Filefilter.stdVirtExt, extList{selVal})) = [];
            else
                obj.mibModel.preferences.Filefilter.stdExt(ismember(obj.mibModel.preferences.Filefilter.stdExt, extList{selVal})) = [];
            end
        end
        
end
obj.mibBioformatsCheck_Callback();
end