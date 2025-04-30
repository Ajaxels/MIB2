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

function mibFilesListbox_Callback(obj)
% function mibFilesListbox_Callback(obj)
% navigation in the file list, i.e. open file or change directory
%
% Parameters:
%

% Updates
% 

global mibPath; % path to mib installation folder

% Open the image after the double click
val = obj.mibView.handles.mibFilesListbox.Value;
list = obj.mibView.handles.mibFilesListbox.String;
filename = list(val);

switch obj.mibView.handles.mibGUI.SelectionType
    case 'normal'   % single click, do nothing
    case 'open'     % double click, open the image
        try
            if isempty(filename{1})
                0;
            end
        catch err
            err
        end
        if strcmp(filename{1},'[..]')     % go up in the directory tree
            [dirname, oldDir] = fileparts(obj.mibModel.myPath);
            if ~isequal(dirname, obj.mibModel.myPath)
                obj.mibModel.myPath = dirname;
                obj.updateFilelist(['[', oldDir, ']']);  % the squares are required because the directory is reported as [dirname] in obj.updateFilelist function
            end
        elseif strcmp(filename{1},'[.]')   % go up to the root directory listing
            if ispc()
                dirname = fileparts(obj.mibModel.myPath);
                obj.mibModel.myPath = dirname(1:3);
            else
                obj.mibModel.myPath = '/';
            end
            obj.updateFilelist();
        elseif filename{1}(1) == '[' && filename{1}(end) == ']'   % go into the selected directory
            dirname = fullfile(obj.mibModel.myPath, filename{1}(2:end-1));
            obj.mibModel.myPath = dirname;
            obj.updateFilelist();
        else        % open the selected file
            options.mibBioformatsCheck = obj.mibView.handles.mibBioformatsCheck.Value;  % use bioformat reader or not
            options.waitbar = 1;        % show progress dialog
            options.Font = obj.mibModel.preferences.System.Font;    % pass font settings
            options.mibPath = mibPath;      % path to MIB, an optional parameter to mibInputDlg.m 
            options.virtual = obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual;  % to use or not the virtual stacking
            options.id = obj.mibModel.Id;   % id of the current dataset
            options.BioFormatsMemoizerMemoDir = obj.mibModel.preferences.ExternalDirs.BioFormatsMemoizerMemoDir;  % path to temp folder for Bioformats

            if obj.mibModel.I{obj.mibModel.Id}.modelExist == 1
                button = questdlg(sprintf('!!! Warning !!!\nYou are going to load a new dataset!\nMeanwhile you have an open model; would you like to continue?\n'), 'Load dataset', 'Continue', 'Cancel', 'Cancel');
                if strcmp(button, 'Cancel'); return; end
            end

            %obj.mibModel.I{obj.mibModel.Id}.clearContents();  % remove the current dataset
            obj.mibModel.U.clearContents();  % clear Undo history
            
            % load a single image
            fn = fullfile(obj.mibModel.myPath, filename{1});
            [img, img_info, pixSize] = mibLoadImages(cellstr(fn), options);
            
            if ~isempty(img)
                obj.mibModel.I{obj.mibModel.Id}.clearContents(img, img_info, obj.mibModel.preferences.System.EnableSelection);
                obj.mibModel.I{obj.mibModel.Id}.pixSize = pixSize;
                notify(obj.mibModel, 'newDataset');   % notify mibController about a new dataset; see function obj.Listner2_Callback for details
                
                obj.mibModel.I{obj.mibModel.Id}.lastSegmSelection = [2 1];  % last selected contour for use with the 'e' button

                % count user's points
                obj.mibModel.preferences.Users.Tiers.numberOfLoadedDatasets = obj.mibModel.preferences.Users.Tiers.numberOfLoadedDatasets+1;
                notify(obj.mibModel, 'updateUserScore');     % update score using default obj.mibModel.preferences.Users.singleToolScores increase
            else
                %obj.mibView.handles = obj.mibView.handles.Img{obj.mibView.handles.Id}.I.updateAxesLimits(obj.mibView.handles, 'resize');
                %obj.mibView.handles.Img{obj.mibView.handles.Id}.I.updateDisplayParameters();
                %obj.mibView.handles = updateGuiWidgets(obj.mibView.handles);
                obj.updateFilelist();
            end
            %obj.mibView.handles = obj.mibView.handles.Img{obj.mibView.handles.Id}.I.plotImage(obj.mibView.handles.imageAxes, obj.mibView.handles, 1);
            obj.plotImage(1);
            unFocus(obj.mibView.handles.mibFilesListbox);   % remove focus from hObject);   % remove focus from hObject
            
            % update list of recent directories
            dirPos = ismember(obj.mibModel.preferences.System.Dirs.RecentDirs, fileparts(fn));
            if sum(dirPos) == 0
                obj.mibModel.preferences.System.Dirs.RecentDirs = [fileparts(fn) obj.mibModel.preferences.System.Dirs.RecentDirs];    % add the new folder to the list of folders
                if numel(obj.mibModel.preferences.System.Dirs.RecentDirs) > obj.mibModel.preferences.System.Dirs.RecentDirsNumber    % trim the list
                    obj.mibModel.preferences.System.Dirs.RecentDirs = obj.mibModel.preferences.System.Dirs.RecentDirs(1:obj.mibModel.preferences.System.Dirs.RecentDirsNumber);
                end
            else
                % re-sort the list and put the opened folder to the top of
                % the list
                obj.mibModel.preferences.System.Dirs.RecentDirs = [obj.mibModel.preferences.System.Dirs.RecentDirs(dirPos==1) obj.mibModel.preferences.System.Dirs.RecentDirs(dirPos==0)];
            end
            obj.mibView.handles.mibRecentDirsPopup.String = obj.mibModel.preferences.System.Dirs.RecentDirs;
        end
end
end