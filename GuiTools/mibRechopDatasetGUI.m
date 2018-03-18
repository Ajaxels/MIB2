function varargout = mibRechopDatasetGUI(varargin)
% MIBRECHOPDATASETGUI MATLAB code for mibRechopDatasetGUI.fig
%      MIBRECHOPDATASETGUI, by itself, creates a new MIBRECHOPDATASETGUI or raises the existing
%      singleton*.
%
%      H = MIBRECHOPDATASETGUI returns the handle to a new MIBRECHOPDATASETGUI or the handle to
%      the existing singleton*.
%
%      MIBRECHOPDATASETGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MIBRECHOPDATASETGUI.M with the given input arguments.
%
%      MIBRECHOPDATASETGUI('Property','Value',...) creates a new MIBRECHOPDATASETGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibRechopDatasetGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibRechopDatasetGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (C) 18.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

% Last Modified by GUIDE v2.5 24-Mar-2017 09:19:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibRechopDatasetGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibRechopDatasetGUI_OutputFcn, ...
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


% --- Executes just before mibRechopDatasetGUI is made visible.
function mibRechopDatasetGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibRechopDatasetGUI (see VARARGIN)

% obtain controller
handles.winController = varargin{1};

% update font and size
global Font;
if ~isempty(Font)
    if handles.text1.FontSize ~= Font.FontSize ...
            || ~strcmp(handles.text1.FontName, Font.FontName)
        mibUpdateFontSize(handles.mibRechopDatasetGUI, Font);
    end
end

% rescale widgets for Mac and Linux
mibRescaleWidgets(handles.mibRechopDatasetGUI);

% Choose default command line output for mibChildGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibRechopDatasetGUI wait for user response (see UIRESUME)
% uiwait(handles.mibRechopDatasetGUI);
end


% --- Outputs from this function are returned to the command line.
function varargout = mibRechopDatasetGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes when user attempts to close mibRechopDatasetGUI.
function mibRechopDatasetGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibRechopDatasetGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.winController.closeWindow();
end

% --- Executes on button press in selectFilesBtn.
function selectFilesBtn_Callback(hObject, eventdata, handles)
handles.winController.selectFilesBtn_Callback();
end

% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
global mibPath;
web(fullfile(mibPath, 'techdoc/html/ug_gui_menu_file_chop.html'), '-helpbrowser');
end


% --- Executes on button press in combineBtn.
function combineBtn_Callback(hObject, eventdata, handles)
handles.winController.combineBtn_Callback();
end


% --- Executes when selected object is changed in modeRadioPanel.
function modeRadioPanel_SelectionChangedFcn(hObject, eventdata, handles)
switch hObject.Tag
    case 'newRadio'
        handles.xOffsetEdit.Enable = 'off';
        handles.yOffsetEdit.Enable = 'off';
        handles.zOffsetEdit.Enable = 'off';
    case 'fuseRadio'
        handles.xOffsetEdit.Enable = 'on';
        handles.yOffsetEdit.Enable = 'on';
        handles.zOffsetEdit.Enable = 'on';
end
end
