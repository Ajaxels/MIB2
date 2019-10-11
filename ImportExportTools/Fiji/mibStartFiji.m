function mibStartFiji()
% function mibStartFiji
% Start Fiji 
%
% @note requires Fiji to be installed (http://fiji.sc/Fiji).
%
% Parameters:
%
% Return values:

% Copyright (C) 02.03.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


% First, we launch Miji. Here we use the launcher in non-interactive mode.
% The only thing that this will do is actually to set the path so that the
% subsequent commands and classes can be found by Matlab.
% We launched it with a 'false' in argument, to specify that we do not want
% to diplay the ImageJ toolbar. Indeed, this example is a command line
% example, so we choose not to display the GUI. Feel free to experiment.

% check for installed Miji
if ~isdeployed
    if isempty(which('Miji'))
        msgbox(sprintf('Miji was not found!\n\nTo fix:\n1. Install Fiji (http://fiji.sc/Fiji)\n2. Add Fiji.app/Scripts to Matlab path'),...
            'Missing Miji!','error');
        return;
    end
end
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

end