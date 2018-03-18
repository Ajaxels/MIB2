function varargout = mibChopDatasetGUI(varargin)
% MIBCHOPDATASETGUI MATLAB code for mibChopDatasetGUI.fig
%      MIBCHOPDATASETGUI, by itself, creates a new MIBCHOPDATASETGUI or raises the existing
%      singleton*.
%
%      H = MIBCHOPDATASETGUI returns the handle to a new MIBCHOPDATASETGUI or the handle to
%      the existing singleton*.
%
%      MIBCHOPDATASETGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBCHOPDATASETGUI.M with the given input arguments.
%
%      MIBCHOPDATASETGUI('Property','Value',...) creates a new MIBCHOPDATASETGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibChopDatasetGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibChopDatasetGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help mibChopDatasetGUI

% Last Modified by GUIDE v2.5 17-Jan-2017 22:39:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibChopDatasetGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibChopDatasetGUI_OutputFcn, ...
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

% --- Executes just before mibChopDatasetGUI is made visible.
function mibChopDatasetGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibChopDatasetGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.textInfo.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.textInfo.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibChopDatasetGUI, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibChopDatasetGUI);

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'left');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibChopDatasetGUI wait for user response (see UIRESUME)
% uiwait(handles.mibChopDatasetGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = mibChopDatasetGUI_OutputFcn(hObject, eventdata, handles)
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

% --- Executes when user attempts to close mibChopDatasetGUI.
function mibChopDatasetGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibChopDatasetGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in selectDirBtn.
function selectDirBtn_Callback(hObject, eventdata, handles)
handles.winController.selectDirBtn_Callback();
end

function dirEdit_Callback(hObject, eventdata, handles)
handles.winController.dirEdit_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_file_chop.html'), '-helpbrowser');
end

% --- Executes on button press in chopBtn.
function chopBtn_Callback(hObject, eventdata, handles)
handles.winController.chopBtn_Callback();
end
