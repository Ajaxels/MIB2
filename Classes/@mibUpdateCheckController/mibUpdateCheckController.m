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

classdef mibUpdateCheckController < handle
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        mibController
        % MIB controller
        mibVersion
        % version of MIB
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibUpdateCheckController(mibModel, mibController)
            obj.mibModel = mibModel;    % assign model
            obj.mibController = mibController;    % current version of MIB
            obj.mibVersion = obj.mibController.mibVersionNumeric;    % current version of MIB in numerical format
            
            guiName = 'mibUpdateCheckGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % % update font and size
            global Font;
            if ~isempty(Font)
                if obj.View.handles.dummyText.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.dummyText.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            
			obj.updateWidgets();
			
			obj.View.gui.WindowStyle = 'modal';     % make window modal
        end
        
        function closeWindow(obj)
            % closing mibUpdateCheckController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            if isdeployed
                obj.View.handles.updateBtn.Enable = 'off';
                if ismac
                    link = 'http://mib.helsinki.fi/web-update/mib2_mac.txt';
                elseif isunix   
                    link = 'http://mib.helsinki.fi/web-update/mib2_linux.txt';
                else
                    link = 'http://mib.helsinki.fi/web-update/mib2_win.txt';
                end
                try
                    urlText = urlread(link, 'Timeout', 4);
                catch err
                    urlText = sprintf('0.305\n<html>\ntest\n</html>\n---Info---\n<html>\n<div style="font-family: arial;">\n<b>The update file has not been detected...</b>\n</html>');
                end
            else
                %urlText = sprintf('2.305\n<html>\ntest\n</html>\n---Info---\n<html>\ninfo text\n</html>');
                try
                    urlText = urlread('http://mib.helsinki.fi/web-update/mib2_matlab.txt', 'Timeout', 4);
                catch err
                    %urlText = sprintf('2.305\n<html>\ntest\n</html>\n---Info---\n<html>\ninfo text\n</html>');
                    urlText = sprintf('0.305\n<html>\ntest\n</html>\n---Info---\n<html>\n<div style="font-family: arial;">\n<b>The update file has not been detected...</b>\n</html>');
                end
            end
            
            spacesPos = strfind(urlText, '<html>');
            infoPos = strfind(urlText, '---Info---');
            if ~isempty(strfind(urlText, ' '))
                availableVersion = str2double(urlText(1:spacesPos(1)-1));
                releaseComments = urlText(spacesPos(1):infoPos(1)-2);
                infoText = urlText(spacesPos(2):end);
            else
                availableVersion = str2double(urlText);
                releaseComments = '';
                infoText = '';
            end
            
            jScrollPane = findjobj(obj.View.handles.informationEdit);
            jViewPort = jScrollPane.getViewport;
            obj.View.handles.jEditbox = jViewPort.getComponent(0);
            obj.View.handles.jEditbox.setContentType('text/html');
            obj.View.handles.jEditbox.setEditable(false);
            
            if availableVersion - obj.mibVersion > 0
                obj.View.handles.informationText.String = sprintf('New version (%f) of Microscopy Image Browser is available!', availableVersion);
                obj.View.handles.jEditbox.setText(releaseComments);
            else
                obj.View.handles.informationText.String = 'You are running the latest version of Microscopy Image Browser!';
                obj.View.handles.jEditbox.setText(infoText);
                %obj.View.handles.updateBtn.Enable = 'off';
                %obj.View.handles.downloadBtn.Enable = 'off';
                %obj.View.handles.listofchangesBtn.Enable = 'off';
            end
        end
    end
end