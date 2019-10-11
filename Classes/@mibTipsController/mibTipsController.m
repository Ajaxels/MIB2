classdef mibTipsController < handle
    % This is controller class for showing tips of the day
    
    % Copyright (C) 13.03.2019 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    %
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        hMainPanel
        % handle to Java main panel
        webBrowser
        % a Java browser
        
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        %         function ViewListner_Callback(obj, src, evnt)
        %             switch src.Name
        %                 case {'Id', 'newDatasetSwitch'}     % added in mibChildView
        %                     obj.updateWidgets();
        %                     %                 case 'slices'     % replaced with
        %                     %                 'changeSlice', 'changeTime' events because slice is changed too often
        %                     %                     if obj.listener{3}.Enabled
        %                     %                         disp(toc)
        %                     %                         obj.updateHist();
        %                     %                     end
        %             end
        %         end
        
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibTipsController(mibModel)
            % function obj = mibTipsController(mibModel)
            % constructor
            
            global mibPath
            
            obj.mibModel = mibModel;    % assign model
            % these are the preferences related to the tips
            %obj.mibModel.preferences.tips.currentTip = 1;   % index of the next tip to show
            %obj.mibModel.preferences.tips.showTips = 1;     % show or not the tips during startup
            %obj.mibModel.preferences.tips.files
            
            % do not show the tips
            if obj.mibModel.preferences.tips.showTips == 0
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'mibTipsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            obj.View.handles.showTipsCheck.Value = obj.mibModel.preferences.tips.showTips;
            
            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'center', 'center');
            obj.View.gui.Visible = 'on';    % make the window visible
            
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            panelPos = obj.View.handles.mainPanel.Position;
            jObject = com.mathworks.mlwidgets.html.HTMLBrowserPanel;
            [obj.webBrowser, obj.hMainPanel] = javacomponent(jObject, [], obj.View.handles.mibTipsGUI);
            set(obj.hMainPanel, 'Units', 'points', 'Position', panelPos);
            
            
            % % update font and size
            % % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            % global Font;
            % if ~isempty(Font)
            %   if obj.View.handles.text1.FontSize ~= Font.FontSize ...
            %         || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
            %       mibUpdateFontSize(obj.View.gui, Font);
            %   end
            % end
            
            obj.updateWidgets();
            
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % function closeWindow(obj)
            % close this window
            
            obj.mibModel.preferences.tips.showTips = obj.View.handles.showTipsCheck.Value;
            obj.mibModel.preferences.tips.currentTip = obj.mibModel.preferences.tips.currentTip + 1;
            if obj.mibModel.preferences.tips.currentTip > numel(obj.mibModel.preferences.tips.files)
                obj.mibModel.preferences.tips.currentTip = 1;
            end
            
            % closing mibTipsController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
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
            % update widgets of this window
            
            fnIndex = max([1, obj.mibModel.preferences.tips.currentTip]);
            
            % on PC path is file://c:/... or //ad.xxxxx.xxx.xx
            % on Mac file:///Volumes/Transcend/...
            if ispc
                if obj.mibModel.preferences.tips.files{fnIndex}(1) == '\'
                    fileText = 'file:'; 
                else
                    fileText = 'file:/'; 
                end    % check for a installation in the network path \\ad.xxxx
            else
                fileText = 'file://';
            end
            filename = obj.mibModel.preferences.tips.files{fnIndex};
            linkURL = strrep([fileText filename],'\','/');
            obj.webBrowser.setCurrentLocation(linkURL);
        end
        
        function nextTipBtn_Callback(obj)
            % function nextTipBtn_Callback(obj)
            % display the next tip
            
            obj.mibModel.preferences.tips.currentTip = obj.mibModel.preferences.tips.currentTip + 1;
            if obj.mibModel.preferences.tips.currentTip > numel(obj.mibModel.preferences.tips.files)
                obj.mibModel.preferences.tips.currentTip = 1;
            end
            obj.updateWidgets();
        end
        
        function previousTipBtn_Callback(obj)
            % function previousTipBtn_Callback(obj)
            % display the previous tip
            
            obj.mibModel.preferences.tips.currentTip = obj.mibModel.preferences.tips.currentTip - 1;
            if obj.mibModel.preferences.tips.currentTip == 0
                obj.mibModel.preferences.tips.currentTip = numel(obj.mibModel.preferences.tips.files);
            end
            obj.updateWidgets();
        end
    end
end