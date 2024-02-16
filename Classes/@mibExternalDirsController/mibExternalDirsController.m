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
            
            externalPaths = [{'Fiji installation folder'}, {'Omero installation folder', 'Imaris installation folder'},...
                              {'BM3D filter'}, {'BM4D filter'}, {'BioFormats Memoizer temporary directory'}];
            obj.View.handles.externalToolPopup.String = externalPaths;
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            global Font;
            if obj.View.handles.text2.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.text2.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            %obj.View.gui.WindowStyle = 'modal';     % make window modal
            obj.externalToolPopup_Callback();
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
                    if strcmp(obj.View.handles.dirEdit.String, 'C:\Matlab\Scripts\BMxD\BM3D')
                        answer = questdlg(sprintf('!!! Warning !!!\n\nPlease note that any unauthorized use of BM3D and BM4D filters for industrial or profit-oriented activities is expressively prohibited!'), 'License warning', 'Acknowledge', 'Cancel', 'Cancel');
                        if strcmp(answer, 'Cancel')
                            obj.View.handles.dirEdit.String = '';
                            return;
                        end
                    end
                end
            end
            obj.updatePreferences();    % update local copy of preferences
        end
        
        function selectDirBtn_Callback(obj)
            % function selectDirBtn_Callback(obj)
            % select directory using uigetdir
            
            folder_name = uigetdir(obj.View.handles.dirEdit.String, 'Select directory');
            if folder_name==0; return; end
            
            if strcmp(obj.View.handles.externalToolPopup.String{obj.View.handles.externalToolPopup.Value}, 'BM3D filter')
                answer = questdlg(sprintf('!!! Warning !!!\n\nPlease note that any unauthorized use of BM3D and BM4D filters for industrial or profit-oriented activities is expressively prohibited!'), 'License warning', 'Acknowledge', 'Cancel', 'Cancel');
                if strcmp(answer, 'Cancel')
                    obj.View.handles.dirEdit.String = '';
                    return;
                end
            end
            
            obj.View.handles.dirEdit.String = folder_name;
            obj.dirEdit_Callback();
        end
        
        function updatePreferences(obj)
            % function updatePreferences(obj)
            % % update local copy of preferences
            
            switch obj.View.handles.externalToolPopup.String{obj.View.handles.externalToolPopup.Value}
                case 'Fiji installation folder'
                    obj.localPreferences.ExternalDirs.FijiInstallationPath = obj.View.handles.dirEdit.String;
                case 'Omero installation folder'
                    obj.localPreferences.ExternalDirs.OmeroInstallationPath = obj.View.handles.dirEdit.String;
                case 'Imaris installation folder'
                    obj.localPreferences.ExternalDirs.ImarisInstallationPath = obj.View.handles.dirEdit.String;
                case 'BM3D filter'
                    obj.localPreferences.ExternalDirs.bm3dInstallationPath = obj.View.handles.dirEdit.String;
                case 'BM4D filter'
                    obj.localPreferences.ExternalDirs.bm4dInstallationPath = obj.View.handles.dirEdit.String;                    
                case 'BioFormats Memoizer temporary directory'
                    obj.localPreferences.ExternalDirs.BioFormatsMemoizerMemoDir = obj.View.handles.dirEdit.String;                    
            end
        end
        
        function externalToolPopup_Callback(obj, name)
            % function externalToolPopup_Callback(obj, name)
            % callback for change of selected tool
            %
            % Parameters:
            % name: text of the radio button
            
            if nargin < 2; name = obj.View.handles.externalToolPopup.String{obj.View.handles.externalToolPopup.Value}; end
            
            switch name
                case 'Fiji installation folder'
                    obj.View.handles.dirEdit.String = obj.localPreferences.ExternalDirs.FijiInstallationPath;
                case 'Omero installation folder'
                    obj.View.handles.dirEdit.String = obj.localPreferences.ExternalDirs.OmeroInstallationPath;
                case 'Imaris installation folder'
                    obj.View.handles.dirEdit.String  = obj.localPreferences.ExternalDirs.ImarisInstallationPath;
                case 'BM3D filter'
                    obj.View.handles.dirEdit.String = obj.localPreferences.ExternalDirs.bm3dInstallationPath;
                case 'BM4D filter'
                    obj.View.handles.dirEdit.String = obj.localPreferences.ExternalDirs.bm4dInstallationPath;
                case 'BioFormats Memoizer temporary directory'
                    obj.View.handles.dirEdit.String = obj.mibModel.preferences.ExternalDirs.BioFormatsMemoizerMemoDir;
            end
            obj.dirEdit_Callback();
        end

        function acceptBtn_Callback(obj)
            % function acceptBtn_Callback(obj)
            % accept directories
            warndlg(sprintf('!!! Warning !!!\n\nYou may need to restart MIB to take the updated directories in use'), 'Attention', 'modal');
            obj.mibPreferencesController.preferences = obj.localPreferences;
            obj.closeWindow();
        end
        
    end
end