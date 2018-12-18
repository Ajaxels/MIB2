function varargout = mibRandomDatasetGUI(varargin)
% MIBRANDOMDATASETGUI MATLAB code for mibRandomDatasetGUI.fig
%      MIBRANDOMDATASETGUI, by itself, creates a new MIBRANDOMDATASETGUI or raises the existing
%      singleton*.
%
%      H = MIBRANDOMDATASETGUI returns the handle to a new MIBRANDOMDATASETGUI or the handle to
%      the existing singleton*.
%
%      MIBRANDOMDATASETGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBRANDOMDATASETGUI.M with the given input arguments.
%
%      MIBRANDOMDATASETGUI('Property','Value',...) creates a new MIBRANDOMDATASETGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibRandomDatasetGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibRandomDatasetGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help mibRandomDatasetGUI

% Last Modified by GUIDE v2.5 14-Dec-2018 14:07:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibRandomDatasetGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibRandomDatasetGUI_OutputFcn, ...
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

% --- Executes just before mibRandomDatasetGUI is made visible.
function mibRandomDatasetGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibRandomDatasetGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.infoText.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.infoText.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibRandomDatasetGUI, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibRandomDatasetGUI);

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibRandomDatasetGUI wait for user response (see UIRESUME)
% uiwait(handles.mibRandomDatasetGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibRandomDatasetGUI_OutputFcn(hObject, eventdata, handles)
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

% --- Executes when user attempts to close mibRandomDatasetGUI.
function mibRandomDatasetGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibRandomDatasetGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in selectDirBtn.
function selectDirBtn_Callback(hObject, eventdata, handles)
handles.winController.selectDirBtn_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_file_rename_and_shuffle.html'), '-helpbrowser');
end

% --- Executes on button press in randomBtn.
function randomBtn_Callback(hObject, eventdata, handles)
handles.winController.randomBtn_Callback();
end


% --- Executes on button press in removeDirBtn.
function removeDirBtn_Callback(hObject, eventdata, handles)
handles.winController.removeDirBtn_Callback();
end

% --- Executes on button press in addDirBtn.
function addDirBtn_Callback(hObject, eventdata, handles)
handles.winController.addDirBtn_Callback();
end

% --- Executes on button press in includeModelCheck.
function includeModelCheck_Callback(hObject, eventdata, handles)
if handles.includeModelCheck.Value == 1
    warndlg(sprintf('!!! Warning !!!\n\nPlease make sure:\n1. Each folder has only one model file in the *.model format\n2. Material names should be the same in all models\n3. The width/height deminsions of images should be the same for all files'));
end
end

% --- Executes on button press in includeMaskCheck.
function includeMaskCheck_Callback(hObject, eventdata, handles)
if handles.includeMaskCheck.Value == 1
    warndlg(sprintf('!!! Warning !!!\n\nPlease make sure:\n1. Each folder has only one mask file in the *.mask format\n2. The width/height deminsions of images should be the same for all files'));
end
end


% --- Executes on button press in includeAnnotationsCheck.
function includeAnnotationsCheck_Callback(hObject, eventdata, handles)
if handles.includeAnnotationsCheck.Value == 1
    warndlg(sprintf('!!! Warning !!!\n\nPlease make sure:\n1. Each folder has only one annotation file in the *.ann format'));
end
end
