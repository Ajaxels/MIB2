function varargout = mibCropObjectsGUI(varargin)
% mibCropObjectsGUI MATLAB code for mibCropObjectsGUI.fig
%      mibCropObjectsGUI, by itself, creates a new mibCropObjectsGUI or raises the existing
%      singleton*.
%
%      H = mibCropObjectsGUI returns the handle to a new mibCropObjectsGUI or the handle to
%      the existing singleton*.
%
%      mibCropObjectsGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in mibCropObjectsGUI.M with the given input arguments.
%
%      mibCropObjectsGUI('Property','Value',...) creates a new mibCropObjectsGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mibCropObjectsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mibCropObjectsGUI_OpeningFcn via varargin.
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
% 07.03.2016, IB, updated for 4D datasets

% Last Modified by GUIDE v2.5 05-Dec-2016 17:21:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mibCropObjectsGUI_OpeningFcn, ...
    'gui_OutputFcn',  @mibCropObjectsGUI_OutputFcn, ...
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

% --- Executes just before mibCropObjectsGUI is made visible.
function mibCropObjectsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mibCropObjectsGUI (see VARARGIN)

handles.winController = varargin{1};

% radio button callbacks
handles.targetPanel.SelectionChangeFcn = @targetPanelRadio_Callback;

% % update font and size
global Font;
if ~isempty(Font)
    if handles.text1.FontSize ~= Font.FontSize ...
             || ~strcmp(handles.text1.FontName, Font.FontName)
         mibUpdateFontSize(handles.mibCropObjectsGUI, Font);
    end
end

% resize all elements x1.25 times for macOS
mibRescaleWidgets(handles.mibCropObjectsGUI);

% Choose default command line output for mibCropObjectsGUI
handles.output = hObject;

% move the window
hObject = moveWindowOutside(hObject, 'center', 'center');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mibCropObjectsGUI wait for user response (see UIRESUME)
% uiwait(handles.mibCropObjectsGUI);
end

% --- Executes on button press in distanceRadio.
function targetPanelRadio_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
hObject = eventdata.NewValue;
tagId = get(hObject, 'tag');

switch tagId
    case 'fileRadio'
        set(handles.formatPopup, 'enable','on');
        set(handles.selectDirBtn, 'enable','on');
        set(handles.dirEdit, 'enable','on');
    case 'matlabRadio'
        set(handles.formatPopup, 'enable','off');
        set(handles.selectDirBtn, 'enable','off');
        set(handles.dirEdit, 'enable','off');
end
cropMaskCheck_Callback(handles.cropMaskCheck, eventdata, handles);
cropModelCheck_Callback(handles.cropModelCheck, eventdata, handles)
end

% --- Outputs from this function are returned to the command line.
function varargout = mibCropObjectsGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.output;
end

% --- Executes when user attempts to close mibCropObjectsGUI.
function mibCropObjectsGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mibCropObjectsGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.winController.closeWindow();
end

% --- Executes on button press in cancelBtn.
function cancelBtn_Callback(hObject, eventdata, handles)
handles.winController.closeWindow();
end

% --- Executes on button press in selectDirBtn.
function selectDirBtn_Callback(hObject, eventdata, handles)
handles.winController.selectDirBtn_Callback();
end


function dirEdit_Callback(hObject, eventdata, handles)
handles.winController.dirEdit_Callback();
end

% --- Executes on button press in cropBtn.
function cropBtn_Callback(hObject, eventdata, handles)
handles.winController.cropBtn_Callback();
end


% --- Executes on button press in cropModelCheck.
function cropModelCheck_Callback(hObject, eventdata, handles)
if handles.cropModelCheck.Value == 1 && handles.fileRadio.Value == 1
    handles.modelFormatPopup.Enable = 'on';
else
    handles.modelFormatPopup.Enable = 'off';
end
end

% --- Executes on button press in cropMaskCheck.
function cropMaskCheck_Callback(hObject, eventdata, handles)
if handles.cropMaskCheck.Value == 1 && handles.fileRadio.Value == 1
    handles.maskFormatPopup.Enable = 'on';
else
    handles.maskFormatPopup.Enable = 'off';
end
end
