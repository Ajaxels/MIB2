function exitProgram(obj)
% function exitProgram()
% Executes when user attempts to close MIB

%| 
% @b Examples:
% @code handles.mibController.exitProgram();     // use this function in minGUI @endcode
 
% Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

global mibPath;

% close child controllers
for i=numel(obj.childControllers):-1:1
    if isvalid(obj.childControllers{i})
        obj.childControllers{i}.closeWindow();
    end
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
mib_pars.lastpath = obj.mibModel.myPath;    % store current path
mib_pars.preferences = obj.mibModel.preferences; %#ok<STRNU>     % store preferences

os = getenv('OS');
if strcmp(os,'Windows_NT')
    if isdir(['c:' filesep 'temp']) == 0; [~, ~, messageid] = mkdir(['c:' filesep 'temp']);        end;    % create a tmp directory for storing im_browser parameters
    try
        save(['c:' filesep 'temp' filesep 'mib.mat'],'mib_pars');
    catch err
        try     % try to save it into windows temp folder (C:\Users\User-name\AppData\Local\Temp\)
            fn = fullfile(tempdir, 'mib.mat');
            save(fn, 'mib_pars');
        catch err
            msgbox(sprintf('There is a problem with saving settings\n%s', err.identifier),'Error','error','modal');
        end
    end
else        % linux
    try
        save([mibPath filesep 'mib.mat'], 'mib_pars');
    catch err
        try     % try to save it into linux temp folder
            fn = fullfile(tempdir, 'mib.mat');
            save(fn, 'mib_pars');
        catch err
            msgbox(sprintf('There is a problem with saving settings\n%s', err.identifier),'Error','error','modal');
        end
    end
end
end