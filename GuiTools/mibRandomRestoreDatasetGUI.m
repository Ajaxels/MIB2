function varargout = mibRandomRestoreDatasetGUI(varargin)
% MIBRANDOMRESTOREDATASETGUI MATLAB code for mibRandomRestoreDatasetGUI.fig
%      MIBRANDOMRESTOREDATASETGUI, by itself, creates a new MIBRANDOMRESTOREDATASETGUI or raises the existing
%      singleton*.
%
%      H = MIBRANDOMRESTOREDATASETGUI returns the handle to a new MIBRANDOMRESTOREDATASETGUI or the handle to
%      the existing singleton*.
%
%      MIBRANDOMRESTOREDATASETGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBRANDOMRESTOREDATASETGUI.M with the given input arguments.
%
%      MIBRANDOMRESTOREDATASETGUI('Property','Value',...) creates a new MIBRANDOMRESTOREDATASETGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibRandomRestoreDatasetGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibRandomRestoreDatasetGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 16.05.2015 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 25.01.2016, updated for 4D

% Edit the above text to modify the response to help mibRandomRestoreDatasetGUI

% Last Modified by GUIDE v2.5 11-Feb-2019 16:03:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibRandomRestoreDatasetGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibRandomRestoreDatasetGUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before mibRandomRestoreDatasetGUI is made visible.
function mibRandomRestoreDatasetGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibRandomRestoreDatasetGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.infoText.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.infoText.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibRandomRestoreDatasetGUI, Font);
    end
end

handles.randomDirsList_cm = uicontextmenu('Parent', handles.mibRandomRestoreDatasetGUI);
uimenu(handles.randomDirsList_cm, 'Label', 'Update directory', 'Callback', {@randomDirsList_cm_Callback, 'updatedir'});
handles.randomDirsList.UIContextMenu = handles.randomDirsList_cm;

handles.destinationDirsList_cm = uicontextmenu('Parent', handles.mibRandomRestoreDatasetGUI);
uimenu(handles.destinationDirsList_cm, 'Label', 'Update directory', 'Callback', {@destinationDirsList_cm_Callback, 'updatedir'});
handles.destinationDirsList.UIContextMenu = handles.destinationDirsList_cm;

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibRandomRestoreDatasetGUI);

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibRandomRestoreDatasetGUI wait for user response (see UIRESUME)
% uiwait(handles.mibRandomRestoreDatasetGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibRandomRestoreDatasetGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in closeBtn.
function closeBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes when user attempts to close mibRandomRestoreDatasetGUI.
function mibRandomRestoreDatasetGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibRandomRestoreDatasetGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in selectSettingsFileBtn.
function selectSettingsFileBtn_Callback(hObject, eventdata, handles)
handles.winController.selectSettingsFileBtn_Callback();
end

function projectFilenameEdit_Callback(hObject, eventdata, handles)
handles.winController.projectFilenameEdit_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_file_rename_and_shuffle.html'), '-helpbrowser');
end

function randomDirsList_cm_Callback(hObject, ~, parameter)
handles = guidata(hObject);
switch parameter
    case 'updatedir'
        handles.winController.updateDir('randomDirsList');
end
end

function destinationDirsList_cm_Callback(hObject, ~, parameter)
handles = guidata(hObject);
switch parameter
    case 'updatedir'
        handles.winController.updateDir('destinationDirsList');
end
end

% --- Executes on button press in includeMaskCheck.
function includeMaskCheck_Callback(hObject, eventdata, handles)
if handles.includeMaskCheck.Value == 1
    warndlg(sprintf('!!! Warning !!!\n\nPlease make sure:\n1. Each folder has only one mask file in the *.mask format\n2. The width/height deminsions of images should be the same for all files'));
end
end


% --- Executes on button press in restoreBtn.
function restoreBtn_Callback(hObject, eventdata, handles)
handles.winController.restoreBtn_Callback();
end


% --- Executes on button press in includeAnnotationsCheck.
function includeAnnotationsCheck_Callback(hObject, eventdata, handles)
if handles.includeAnnotationsCheck.Value == 1
    warndlg(sprintf('!!! Warning !!!\n\nPlease make sure:\n1. Each folder has only one annotation file in the *.ann format'));
end
end


% --- Executes when mibRandomRestoreDatasetGUI is resized.
function mibRandomRestoreDatasetGUI_SizeChangedFcn(hObject, eventdata, handles)
figW = handles.mibRandomRestoreDatasetGUI.Position(3);
figH = handles.mibRandomRestoreDatasetGUI.Position(4);

buttonH = handles.optionsPanel.Position(2);

handles.optionsPanel.Position(4) = figH - handles.datasetInfoPanel.Position(4) - handles.optionsPanel.Position(2) - handles.helpBtn.Position(4)/12;
handles.optionsPanel.Position(3) = figW - handles.helpBtn.Position(4)/2;
handles.datasetInfoPanel.Position(2) = handles.optionsPanel.Position(2) + handles.optionsPanel.Position(4) + handles.helpBtn.Position(4)/12;
handles.datasetInfoPanel.Position(3) = figW - handles.helpBtn.Position(4)/2;

optW = handles.optionsPanel.Position(3);
optH = handles.optionsPanel.Position(4);
handles.lowerSubPanel.Position(4) = (optH - handles.upperSubPanel.Position(4) - handles.helpBtn.Position(4)*2);
handles.lowerSubPanel.Position(3) = (optW - handles.helpBtn.Position(4)/2);
handles.upperSubPanel.Position(2) = handles.lowerSubPanel.Position(2) + handles.lowerSubPanel.Position(4);
handles.upperSubPanel.Position(3) = (optW - handles.helpBtn.Position(4)/2);
handles.projectFilenameEdit.Position(3) = handles.upperSubPanel.Position(3) - handles.projectFilenameEdit.Position(1)*2;

end
