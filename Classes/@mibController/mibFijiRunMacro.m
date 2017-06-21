function mibFijiRunMacro(obj)
% function mibFijiRunMacro(obj)
% run command or macro on Fiji
%
% Parameters:
% 
% Return values
%

% Copyright (C) 02.03.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% check for MIJ
if exist('MIJ','class') == 8
    if ~isempty(ij.gui.Toolbar.getInstance)
        ij_instance = char(ij.gui.Toolbar.getInstance.toString);
        % -> ij.gui.Toolbar[canvas1,3,41,548x27,invalid]
        if numel(strfind(ij_instance, 'invalid')) > 0    % instance already exist, but not shown
            Miji_wrapper(true);     % wrapper to Miji.m file
        end
    else
        Miji_wrapper(true);     % wrapper to Miji.m file
    end
else
   Miji_wrapper(true);     % wrapper to Miji.m file
end

command = obj.mibView.handles.mibFijiMacroEdit.String;
if isempty(command); return; end;

if exist(command, 'file') == 2  % load list of commands from a file
    fid = fopen(command);
    tline = fgetl(fid);
    while ischar(tline)
        runFijiCommand(tline);
        tline = fgetl(fid);
    end
    fclose(fid);
else
    runFijiCommand(command)
end
end


function runFijiCommand(command)
command = strrep(command, '"','''');   % replace " with '
if ~isempty(strfind(command, 'run')) % run command already present
    command = ['MIJ.' command];
    try
        eval(command);
    catch err
        err
    end
else
    if command(1) ~= ''''; command = ['''' command]; end;
    if command(end) ~= ''''; command = [command '''']; end;
    try
        eval(sprintf('MIJ.run(%s);', command));
    catch err
        err
    end
end
end
