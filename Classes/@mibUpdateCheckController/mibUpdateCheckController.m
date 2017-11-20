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
            obj.mibVersion = obj.mibController.mibVersion;    % current version of MIB
            
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
                if ismac()
                    link = 'http://mib.helsinki.fi/web-update/mib2_mac.txt';
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
            
            index1 = strfind(obj.mibVersion, 'ver.');
            index2 = strfind(obj.mibVersion, '/');
            currentVersion = str2double(obj.mibVersion(index1+4:index2-1));
            
            jScrollPane = findjobj(obj.View.handles.informationEdit);
            jViewPort = jScrollPane.getViewport;
            obj.View.handles.jEditbox = jViewPort.getComponent(0);
            obj.View.handles.jEditbox.setContentType('text/html');
            obj.View.handles.jEditbox.setEditable(false);
            
            if availableVersion - currentVersion > 0
                obj.View.handles.informationText.String = sprintf('New version (%f) of Microscopy Image Browser is available!', availableVersion);
                obj.View.handles.jEditbox.setText(releaseComments);
            else
                obj.View.handles.informationText.String = 'You are running the latest version of Microscopy Image Browser!';
                obj.View.handles.jEditbox.setText(infoText);
                obj.View.handles.updateBtn.Enable = 'off';
                obj.View.handles.downloadBtn.Enable = 'off';
                obj.View.handles.listofchangesBtn.Enable = 'off';
            end
        end
    end
end