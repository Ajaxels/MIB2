classdef mibExternalDirsController < handle
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        mibPreferencesController
        % handle to mibPreferencesController class
        localPreferences
        % local copy of preferences
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibExternalDirsController(mibModel, mibPreferencesController)
            obj.mibModel = mibModel;    % assign model
            obj.mibPreferencesController = mibPreferencesController;
            obj.localPreferences = obj.mibPreferencesController.preferences;
            
            guiName = 'mibExternalDirsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            global Font;
            if obj.View.handles.fijiRadio.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.fijiRadio.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            obj.View.gui.WindowStyle = 'modal';     % make window modal
            obj.radioButtons_SelectionChangedFcn();
        end
        
        function closeWindow(obj)
            % closing mibExternalDirsController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function dirEdit_Callback(obj)
            % function dirEdit_Callback(obj)
            % callback for modification of directory edit box
            
            if ~isempty(obj.View.handles.dirEdit.String)
                if isdir(obj.View.handles.dirEdit.String) == 0
                    warndlg(sprintf('!!! Warning !!!\n\nThe directory %s is missing', obj.View.handles.dirEdit.String), 'modal');
                    obj.View.handles.dirEdit.BackgroundColor = 'r';
                else
                    obj.View.handles.dirEdit.BackgroundColor = 'w';
                end
            end
            obj.updatePreferences();    % update local copy of preferences
        end
        
        function selectDirBtn_Callback(obj)
            % function selectDirBtn_Callback(obj)
            % select directory using uigetdir
            
            folder_name = uigetdir(obj.View.handles.dirEdit.String, 'Select directory');
            if folder_name==0; return; end;
            obj.View.handles.dirEdit.String = folder_name;
            obj.dirEdit_Callback();
        end
        
        function updatePreferences(obj)
            % function updatePreferences(obj)
            % % update local copy of preferences
            
            switch obj.View.handles.radioButtons.SelectedObject.String
                case 'Fiji installation folder'
                    obj.localPreferences.dirs.fijiInstallationPath = obj.View.handles.dirEdit.String;
                case 'Omero installation folder'
                    obj.localPreferences.dirs.omeroInstallationPath = obj.View.handles.dirEdit.String;
            end
        end
        
        function radioButtons_SelectionChangedFcn(obj, name)
            % function radioButtons_SelectionChangedFcn(obj, name)
            % callback for change of selected radio button
            %
            % Parameters:
            % name: text of the radio button
            
            if nargin < 2; name = obj.View.handles.radioButtons.SelectedObject.String; end;
            
            switch name
                case 'Fiji installation folder'
                    obj.View.handles.dirEdit.String = obj.localPreferences.dirs.fijiInstallationPath;
                case 'Omero installation folder'
                    obj.View.handles.dirEdit.String = obj.localPreferences.dirs.omeroInstallationPath;
            end
            obj.dirEdit_Callback();
        end

        function acceptBtn_Callback(obj)
            % function acceptBtn_Callback(obj)
            % accept directories
            warndlg(sprintf('!!! Warning !!!\n\nYou need to restart MIB to take the updated directories in use'), 'Attention', 'modal');
            obj.mibPreferencesController.preferences = obj.localPreferences;
            obj.closeWindow();
        end
        
    end
end