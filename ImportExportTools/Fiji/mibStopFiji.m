function mibStopFiji()
% function mibStopFiji()
% Stop Fiji 
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
% 01.10.2021 - added automatic closing of all windows in Fiji

answer = questdlg(sprintf('!!! Warning !!!\n\nYou are going to close Fiji, all images opened there are going to be closed\n\nContinue?'), ...
	'Close Fiji', ...
	'Close Fiji and all images','Cancel','Cancel');
if strcmp(answer, 'Cancel'); return; end

try
    MIJ.closeAllWindows()   % close all windows in Fiji
    list = MIJ.getListImages;
catch err
    if isfield(err, 'ExceptionObject')
        if strcmp(err.ExceptionObject, 'java.lang.NullPointerException')
            MIJ.exit();
            return;
        end
    else    % needed at least in matlab 2011a
        if strfind(err.message, 'java.lang.NullPointerException') ~= 0
            MIJ.exit();
            return;
        end
    end
end
warndlg('Please close all opened in Fiji windows before stopping!','Close windows in Fiji');

%MIJ.exit();
end