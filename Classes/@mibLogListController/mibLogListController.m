classdef mibLogListController < handle
    % classdef mibLogListController < handle
    % a controller class for the log of actions available via
    % the Log button of the Path panel
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.

    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)   % added in mibChildView
            switch evnt.EventName
                case {'updateImgInfo', 'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibLogListController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibLogListGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'updateImgInfo', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));
        end
        
        function closeWindow(obj)
            % closing mibLogListController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete mibLogListController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of the window
            logText = obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription');
            linefeeds = strfind(logText, sprintf('|'));
            if isempty(linefeeds)
                obj.View.handles.logList.String = logText;
                return;
            end;
            for linefeed = 1:numel(linefeeds)
                if linefeed == 1
                    logTextForm(linefeed) = cellstr(logText(1:linefeeds(1)-1)); %#ok<AGROW>
                else
                    logTextForm(linefeed) = cellstr(logText(linefeeds(linefeed-1)+1:linefeeds(linefeed)-1)); %#ok<AGROW>
                end
            end
            if numel(logText(linefeeds(end)+1:end)) > 1
                logTextForm(linefeed+1) = cellstr(logText(linefeeds(end)+1:end));
            end
            currPos = obj.View.handles.logList.Value;
            if currPos > numel(logTextForm)
                obj.View.handles.logList.Value = 1;
            end
            obj.View.handles.logList.String = logTextForm;
        end
        
        function deleteBtn_Callback(obj)
            % function deleteBtn_Callback(obj)
            % delete selected entry from the log list
            
            pos = obj.View.handles.logList.Value;
            if pos(1)==1
                msgbox('The BoundingBox information can not be deleted!', 'Error', 'error', 'modal') ;
                return;
            end
            button = questdlg(sprintf('You are goint to delete highlighted entry!\n\nAre you sure?'),'Delete entry','Delete','Cancel','Cancel');
            if strcmp(button,'Cancel'); return; end;
            obj.View.handles.logList.Value = 1;
            for i=numel(pos):-1:1
                obj.mibModel.getImageMethod('updateImgInfo', NaN, '', 'delete', pos(i));
            end
            obj.updateWidgets();
        end
        
        function insertBtn_Callback(obj)
            % function insertBtn_Callback(obj)
            % insert an entry to the log list
            global mibPath;
            
            pos = obj.View.handles.logList.Value + 1;
            pos = pos(end);
            
            answer = mibInputDlg({mibPath}, 'Please type here new entry text','Insert new entry', 'type here');
            if isempty(answer)
                return;
            elseif numel(answer{1}) == 0
                return;
            end
            obj.mibModel.getImageMethod('updateImgInfo', NaN, answer{1},'insert',pos);
            obj.updateWidgets();
            obj.View.handles.logList.Value = pos;
        end
        
        function modifyBtn_Callback(obj)
            % function modifyBtn_Callback(obj)
            % modify selected entry
            global mibPath;
            pos = obj.View.handles.logList.Value;
            currentList = obj.View.handles.logList.String;
            if pos==1
                warndlg(sprintf('!!! Warning !!!\n\nThe BoundingBox information should be modified from the menu!\n\nPlease use: \nMenu->Dataset->Bounding Box...\nMenu->Dataset->Parameters... '),'Warning','modal');
                return;
            end
            currEntry = currentList{pos};
            colon = strfind(currEntry,':');
            currEntry = currEntry(colon(1)+2:end);
            answer =mibInputDlg({mibPath}, 'Modify the text:', 'Modify the entry', currEntry);
            if isempty(answer); return;  end;
            obj.mibModel.getImageMethod('updateImgInfo', NaN, answer{1},'modify',pos);
            obj.updateWidgets();
        end
        
    end
end